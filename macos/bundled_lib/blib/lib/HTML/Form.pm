package HTML::Form;

use strict;
use URI;
use Carp ();

use vars qw($VERSION);
$VERSION='0.03';

my %form_tags = map {$_ => 1} qw(input textarea button select option);

my %type2class = (
 text     => "TextInput",
 password => "TextInput",
 file     => "TextInput",
 hidden   => "TextInput",
 textarea => "TextInput",

 button   => "IgnoreInput",
 "reset"  => "IgnoreInput",

 radio    => "ListInput",
 checkbox => "ListInput",
 option   => "ListInput",

 submit   => "SubmitInput",
 image    => "ImageInput",
);

=head1 NAME

HTML::Form - Class that represents HTML forms

=head1 SYNOPSIS

 use HTML::Form;
 $form = HTML::Form->parse($html, $base_uri);
 $form->value(query => "Perl");

 use LWP;
 LWP::UserAgent->new->request($form->click);

=head1 DESCRIPTION

Objects of the C<HTML::Form> class represents a single HTML <form>
... </form> instance.  A form consist of a sequence of inputs that
usually have names, and which can take on various values.

The following methods are available:

=over 4

=item $form = HTML::Form->new($method, $action_uri, [[$enctype], $input,...])

The constructor takes a $method and a $uri as argument.  The $enctype
and and initial inputs are optional.  You will normally use
HTML::Form->parse() to create new HTML::Form objects.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{method} = uc(shift  || "GET");
    $self->{action} = shift  || Carp::croak("No action defined");
    $self->{enctype} = shift || "application/x-www-form-urlencoded";
    $self->{inputs} = [@_];
    $self;
}


=item @forms = HTML::Form->parse($html_document, $base_uri)

The parse() class method will parse an HTML document and build up
C<HTML::Form> objects for each <form> found.  If called in scalar
context only returns the first <form>.  Returns an empty list if there
are no forms to be found.

The $base_uri is (usually) the URI used to access the $html_document.
It is needed to resolve relative action URIs.  For LWP this parameter
is obtained from the $response->base() method.

=cut

sub parse
{
    my($class, $html, $base_uri) = @_;
    require HTML::TokeParser;
    my $p = HTML::TokeParser->new(\$html);
    eval {
	# optimization
	$p->report_tags(qw(form input textarea select optgroup option));
    };

    my @forms;
    my $f;  # current form

    while (my $t = $p->get_tag) {
	my($tag,$attr) = @$t;
	if ($tag eq "form") {
	    my $action = delete $attr->{'action'};
	    $action = "" unless defined $action;
	    $action = URI->new_abs($action, $base_uri);
	    $f = $class->new(delete $attr->{'method'},
			     $action,
			     delete $attr->{'enctype'});
	    $f->{extra_attr} = $attr;
	    push(@forms, $f);
	    while (my $t = $p->get_tag) {
		my($tag, $attr) = @$t;
		last if $tag eq "/form";
		if ($tag eq "input") {
		    my $type = delete $attr->{type} || "text";
		    $f->push_input($type, $attr);
		} elsif ($tag eq "textarea") {
		    $attr->{textarea_value} = $attr->{value}
		        if exists $attr->{value};
		    my $text = $p->get_text("/textarea");
		    $attr->{value} = $text;
		    $f->push_input("textarea", $attr);
		} elsif ($tag eq "select") {
		    $attr->{select_value} = $attr->{value}
		        if exists $attr->{value};
		    while ($t = $p->get_tag) {
			my $tag = shift @$t;
			last if $tag eq "/select";
			next if $tag =~ m,/?optgroup,;
			next if $tag eq "/option";
			if ($tag eq "option") {
			    my %a = (%$attr, %{$t->[0]});
			    $a{value} = $p->get_trimmed_text
				unless defined $a{value};
			    $f->push_input("option", \%a);
			} else {
			    Carp::carp("Bad <select> tag '$tag'") if $^W;
			}
		    }
		}
	    }
	} elsif ($form_tags{$tag}) {
	    Carp::carp("<$tag> outside <form>") if $^W;
	}
    }
    for (@forms) {
	$_->fixup;
    }

    wantarray ? @forms : $forms[0];
}

=item $form->push_input($type, \%attr)

Adds a new input to the form.

=cut

sub push_input
{
    my($self, $type, $attr) = @_;
    $type = lc $type;
    my $class = $type2class{$type};
    unless ($class) {
	Carp::carp("Unknown input type '$type'") if $^W;
	$class = "IgnoreInput";
    }
    $class = "IgnoreInput" if exists $attr->{disabled};
    $class = "HTML::Form::$class";

    my $input = $class->new(type => $type, %$attr);
    $input->add_to_form($self);
}


=item $form->method( [$new] )

=item $form->action( [$new] )

=item $form->enctype( [$new] )

These method can be used to get/set the corresponding attribute of the
form.

=cut

BEGIN {
    # Set up some accesor
    for (qw(method action enctype)) {
	my $m = $_;
	no strict 'refs';
	*{$m} = sub {
	    my $self = shift;
	    my $old = $self->{$m};
	    $self->{$m} = shift if @_;
	    $old;
	};
    }
    *uri = \&action;  # alias
}


=item $form->inputs

This method returns the list of inputs in the form.

=cut

sub inputs
{
    my $self = shift;
    @{$self->{'inputs'}};
}


=item $form->find_input($name, $type, $no)

This method is used to locate some specific input within the form.  At
least one of the arguments must be defined.  If no matching input is
found, C<undef> is returned.

If $name is specified, then the input must have the indicated name.
If $type is specified then the input must have the specified type.  In
addition to the types possible for <input> HTML tags, we also have
"textarea" and "option".  The $no is the sequence number of the input
with the indicated $name and/or $type (where 1 is the first).

=cut

sub find_input
{
    my($self, $name, $type, $no) = @_;
    $no ||= 1;
    for (@{$self->{'inputs'}}) {
	if (defined $name) {
	    next unless exists $_->{name};
	    next if $name ne $_->{name};
	}
	next if $type && $type ne $_->{type};
	next if --$no;
	return $_;
    }
    return;
}

sub fixup
{
    my $self = shift;
    for (@{$self->{'inputs'}}) {
	$_->fixup;
    }
}


=item $form->value($name, [$value])

The value() method can be used to get/set the value of some input.  If
no input have the indicated name, then this method will croak.

=cut

sub value
{
    my $self = shift;
    my $key  = shift;
    my $input = $self->find_input($key);
    Carp::croak("No such field '$key'") unless $input;
    local $Carp::CarpLevel = 1;
    $input->value(@_);
}


=item $form->try_others(\&callback)

This method will iterate over all permutations of unvisited enumerated
values (<select>, <radio>, <checkbox>) and invoke the callback for
each.  The callback is passed the $form as argument.

=cut

sub try_others
{
    my($self, $cb) = @_;
    my @try;
    for (@{$self->{'inputs'}}) {
	my @not_tried_yet = $_->other_possible_values;
	next unless @not_tried_yet;
	push(@try, [\@not_tried_yet, $_]);
    }
    return unless @try;
    $self->_try($cb, \@try, 0);
}

sub _try
{
    my($self, $cb, $try, $i) = @_;
    for (@{$try->[$i][0]}) {
	$try->[$i][1]->value($_);
	&$cb($self);
	$self->_try($cb, $try, $i+1) if $i+1 < @$try;
    }
}


=item $form->make_request

Will return a HTTP::Request object that reflects the current setting
of the form.  You might want to use the click method instead.

=cut

sub make_request
{
    my $self = shift;
    my $method  = uc $self->{'method'};
    my $uri     = $self->{'action'};
    my $enctype = $self->{'enctype'};
    my @form    = $self->form;

    if ($method eq "GET") {
	require HTTP::Request;
	$uri = URI->new($uri, "http");
	$uri->query_form(@form);
	return HTTP::Request->new(GET => $uri);
    } elsif ($method eq "POST") {
	require HTTP::Request::Common;
	return HTTP::Request::Common::POST($uri, \@form,
					   Content_Type => $enctype);
    } else {
	Carp::croak("Unknown method '$method'");
    }
}


=item $form->click([$name], [$x, $y])

Will click on the first clickable input (C<input/submit> or
C<input/image>), with the indicated $name, if specified.  You can
optinally specify a coordinate clicked, which only makes a difference
if you clicked on an image.  The default coordinate is (1,1).

=cut

sub click
{
    my $self = shift;
    my $name;
    $name = shift if (@_ % 2) == 1;  # odd number of arguments

    # try to find first submit button to activate
    for (@{$self->{'inputs'}}) {
        next unless $_->can("click");
        next if $name && $_->name ne $name;
	return $_->click($self, @_);
    }
    Carp::croak("No clickable input with name $name") if $name;
    $self->make_request;
}


=item $form->form

Returns the current setting as a sequence of key/value pairs.

=cut

sub form
{
    my $self = shift;
    map {$_->form_name_value} @{$self->{'inputs'}};
}


=item $form->dump

Returns a textual representation of the form.  Mainly useful for
debugging.  If called in void context, then the dump is printed on
STDERR.

=cut

sub dump
{
    my $self = shift;
    my $method  = $self->{'method'};
    my $uri     = $self->{'action'};
    my $enctype = $self->{'enctype'};
    my $dump = "$method $uri";
    $dump .= " ($enctype)"
	if $enctype eq "application/xxx-www-form-urlencoded";
    $dump .= "\n";
    for ($self->inputs) {
	$dump .= "  " . $_->dump . "\n";
    }
    print STDERR $dump unless defined wantarray;
    $dump;
}


#---------------------------------------------------
package HTML::Form::Input;

=back

=head1 INPUTS

An C<HTML::Form> contains a sequence of inputs.  References to the
inputs can be obtained with the $form->inputs or $form->find_input
methods.  Once you have such a reference, then one of the following
methods can be used on it:

=over 4

=cut

sub new
{
    my $class = shift;
    my $self = bless {@_}, $class;
    $self;
}

sub add_to_form
{
    my($self, $form) = @_;
    push(@{$form->{'inputs'}}, $self);
    $self;
}

sub fixup {}


=item $input->type

Returns the type of this input.  Types are stuff like "text",
"password", "hidden", "textarea", "image", "submit", "radio",
"checkbox", "option"...

=cut

sub type
{
    shift->{type};
}

=item $input->name([$new])

=item $input->value([$new])

These methods can be used to set/get the current name or value of an
input.  If the input only can take an enumerated list of values, then
it is an error to try to set it to something else and the method will
croak if you try.

=cut

sub name
{
    my $self = shift;
    my $old = $self->{name};
    $self->{name} = shift if @_;
    $old;
}

sub value
{
    my $self = shift;
    my $old = $self->{value};
    $self->{value} = shift if @_;
    $old;
}

=item $input->possible_values

Returns a list of all values that and input can take.  For inputs that
does not have discrete values this returns an empty list.

=cut

sub possible_values
{
    return;
}

=item $input->other_possible_values

Returns a list of all values not tried yet.

=cut

sub other_possible_values
{
    return;
}

=item $input->form_name_value

Returns a (possible empty) list of key/value pairs that should be
incorporated in the form value from this input.

=cut

sub form_name_value
{
    my $self = shift;
    my $name = $self->{'name'};
    return unless defined $name;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}

sub dump
{
    my $self = shift;
    my $name = $self->name;
    $name = "<NONAME>" unless defined $name;
    my $value = $self->value;
    $value = "<UNDEF>" unless defined $value;
    my $dump = "$name=$value";

    my $type = $self->type;
    return $dump if $type eq "text";

    $type = ($type eq "text") ? "" : " ($type)";
    my $menu = $self->{menu} || "";
    if ($menu) {
	my @menu;
	for (0 .. @$menu-1) {
	    my $opt = $menu->[$_];
	    $opt = "<UNDEF>" unless defined $opt;
	    substr($opt,0,0) = "*" if $self->{seen}[$_];
	    push(@menu, $opt);
	}
	$menu = "[" . join("|", @menu) . "]";
    }
    sprintf "%-30s %-10s %s", $dump, $type, $menu;
}


#---------------------------------------------------
package HTML::Form::TextInput;
@HTML::Form::TextInput::ISA=qw(HTML::Form::Input);

#input/text
#input/password
#input/file
#input/hidden
#textarea

sub value
{
    my $self = shift;
    if (@_) {
	if (exists($self->{readonly}) || $self->{type} eq "hidden") {
	    Carp::carp("Input '$self->{name}' is readonly") if $^W;
	}
    }
    $self->SUPER::value(@_);
}

#---------------------------------------------------
package HTML::Form::IgnoreInput;
@HTML::Form::IgnoreInput::ISA=qw(HTML::Form::Input);

#input/button
#input/reset

sub value { return }


#---------------------------------------------------
package HTML::Form::ListInput;
@HTML::Form::ListInput::ISA=qw(HTML::Form::Input);

#select/option   (val1, val2, ....)
#input/radio     (undef, val1, val2,...)
#input/checkbox  (undef, value)

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if ($self->type eq "checkbox") {
	my $value = delete $self->{value};
	$value = "on" unless defined $value;
	$self->{menu} = [undef, $value];
	$self->{current} = (exists $self->{checked}) ? 1 : 0;
	delete $self->{checked};
    } else {
	$self->{menu} = [delete $self->{value}];
	my $checked = exists $self->{checked} || exists $self->{selected};
	delete $self->{checked};
	delete $self->{selected};
	if (exists $self->{multiple}) {
	    unshift(@{$self->{menu}}, undef);
	    $self->{current} = $checked ? 1 : 0;
	} else {
	    $self->{current} = 0 if $checked;
	}
    }
    $self;
}

sub add_to_form
{
    my($self, $form) = @_;
    my $type = $self->type;
    return $self->SUPER::add_to_form($form)
	if $type eq "checkbox" ||
	   ($type eq "option" && exists $self->{multiple});

    my $prev = $form->find_input($self->{name}, $self->{type});
    return $self->SUPER::add_to_form($form) unless $prev;

    # merge menues
    push(@{$prev->{menu}}, @{$self->{menu}});
    $prev->{current} = @{$prev->{menu}} - 1 if exists $self->{current};
}

sub fixup
{
    my $self = shift;
    if ($self->{type} eq "option" && !(exists $self->{current})) {
	$self->{current} = 0;
    }
    $self->{seen} = [(0) x @{$self->{menu}}];
    $self->{seen}[$self->{current}] = 1 if exists $self->{current};
}

sub value
{
    my $self = shift;
    my $old;
    $old = $self->{menu}[$self->{current}] if exists $self->{current};
    if (@_) {
	my $i = 0;
	my $val = shift;
	my $cur;
	for (@{$self->{menu}}) {
	    if ((defined($val) && defined($_) && $val eq $_) ||
		(!defined($val) && !defined($_))
	       )
	    {
		$cur = $i;
		last;
	    }
	    $i++;
	}
	Carp::croak("Illegal value '$val'") unless defined $cur;
	$self->{current} = $cur;
	$self->{seen}[$cur] = 1;
    }
    $old;
}

sub possible_values
{
    my $self = shift;
    @{$self->{menu}};
}

sub other_possible_values
{
    my $self = shift;
    map { $self->{menu}[$_] }
        grep {!$self->{seen}[$_]}
             0 .. (@{$self->{seen}} - 1);
}


#---------------------------------------------------
package HTML::Form::SubmitInput;
@HTML::Form::SubmitInput::ISA=qw(HTML::Form::Input);

#input/image
#input/submit

=item $input->click($form, $x, $y)

Some input types (currently "sumbit" buttons and "images") can be
clicked to submit the form.  The click() method returns the
corrsponding C<HTTP::Request> object.

=cut

sub click
{
    my($self,$form,$x,$y) = @_;
    for ($x, $y) { $_ = 1 unless defined; }
    local($self->{clicked}) = [$x,$y];
    return $form->make_request;
}

sub form_name_value
{
    my $self = shift;
    return unless $self->{clicked};
    return $self->SUPER::form_name_value(@_);
}


#---------------------------------------------------
package HTML::Form::ImageInput;
@HTML::Form::ImageInput::ISA=qw(HTML::Form::SubmitInput);

sub form_name_value
{
    my $self = shift;
    my $clicked = $self->{clicked};
    return unless $clicked;
    my $name = $self->{name};
    return unless defined $name;
    return ("$name.x" => $clicked->[0],
	    "$name.y" => $clicked->[1]
	   );
}

1;

__END__

=back

=head1 SEE ALSO

L<LWP>, L<HTML::Parser>, L<webchatpp>

=head1 COPYRIGHT

Copyright 1998-2000 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
