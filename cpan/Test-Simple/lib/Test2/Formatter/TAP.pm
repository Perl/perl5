package Test2::Formatter::TAP;
use strict;
use warnings;
require PerlIO;

our $VERSION = '1.302073';

use Test2::Util::HashBase qw{
    no_numbers handles _encoding
};

sub OUT_STD() { 0 }
sub OUT_ERR() { 1 }

use Carp qw/croak/;

BEGIN { require Test2::Formatter; our @ISA = qw(Test2::Formatter) }

my %CONVERTERS = (
    'Test2::Event::Ok'           => 'event_ok',
    'Test2::Event::Skip'         => 'event_skip',
    'Test2::Event::Note'         => 'event_note',
    'Test2::Event::Diag'         => 'event_diag',
    'Test2::Event::Bail'         => 'event_bail',
    'Test2::Event::Exception'    => 'event_exception',
    'Test2::Event::Subtest'      => 'event_subtest',
    'Test2::Event::Plan'         => 'event_plan',
    'Test2::Event::TAP::Version' => 'event_version',
);

# Initial list of converters are safe for direct hash access cause we control them.
my %SAFE_TO_ACCESS_HASH = %CONVERTERS;

sub register_event {
    my $class = shift;
    my ($type, $convert) = @_;
    croak "Event type is a required argument" unless $type;
    croak "Event type '$type' already registered" if $CONVERTERS{$type};
    croak "The second argument to register_event() must be a code reference or method name"
        unless $convert && (ref($convert) eq 'CODE' || $class->can($convert));
    $CONVERTERS{$type} = $convert;
}

_autoflush(\*STDOUT);
_autoflush(\*STDERR);

sub init {
    my $self = shift;

    $self->{+HANDLES} ||= $self->_open_handles;
    if(my $enc = delete $self->{encoding}) {
        $self->encoding($enc);
    }
}

sub hide_buffered { 1 }

sub encoding {
    my $self = shift;

    if (@_) {
        my ($enc) = @_;
        my $handles = $self->{+HANDLES};

        # https://rt.perl.org/Public/Bug/Display.html?id=31923
        # If utf8 is requested we use ':utf8' instead of ':encoding(utf8)' in
        # order to avoid the thread segfault.
        if ($enc =~ m/^utf-?8$/i) {
            binmode($_, ":utf8") for @$handles;
        }
        else {
            binmode($_, ":encoding($enc)") for @$handles;
        }
        $self->{+_ENCODING} = $enc;
    }

    return $self->{+_ENCODING};
}

if ($^C) {
    no warnings 'redefine';
    *write = sub {};
}
sub write {
    my ($self, $e, $num) = @_;

    my $type = ref($e);

    my $converter = $CONVERTERS{$type} || 'event_other';
    my @tap = $self->$converter($e, $self->{+NO_NUMBERS} ? undef : $num) or return;

    my $handles = $self->{+HANDLES};
    my $nesting = ($SAFE_TO_ACCESS_HASH{$type} ? $e->{nested} : $e->nested) || 0;
    my $indent = '    ' x $nesting;

    # Local is expensive! Only do it if we really need to.
    local($\, $,) = (undef, '') if $\ || $,;
    for my $set (@tap) {
        no warnings 'uninitialized';
        my ($hid, $msg) = @$set;
        next unless $msg;
        my $io = $handles->[$hid] or next;

        $msg =~ s/^/$indent/mg if $nesting;
        print $io $msg;
    }
}

sub _open_handles {
    my $self = shift;

    my %seen;
    open(my $out, '>&', STDOUT) or die "Can't dup STDOUT:  $!";
    binmode($out, join(":", "", "raw", grep { $_ ne 'unix' and !$seen{$_}++ } PerlIO::get_layers(STDOUT)));

    %seen = ();
    open(my $err, '>&', STDERR) or die "Can't dup STDERR:  $!";
    binmode($err, join(":", "", "raw", grep { $_ ne 'unix' and !$seen{$_}++ } PerlIO::get_layers(STDERR)));

    _autoflush($out);
    _autoflush($err);

    return [$out, $err];
}

sub _autoflush {
    my($fh) = pop;
    my $old_fh = select $fh;
    $| = 1;
    select $old_fh;
}

sub event_tap {
    my $self = shift;
    my ($e, $num) = @_;

    my $converter = $CONVERTERS{ref($e)} or return;

    $num = undef if $self->{+NO_NUMBERS};

    return $self->$converter($e, $num);
}

sub event_ok {
    my $self = shift;
    my ($e, $num) = @_;

    # We use direct hash access for performance. OK events are so common we
    # need this to be fast.
    my ($name, $todo) = @{$e}{qw/name todo/};
    my $in_todo = defined($todo);

    my $out = "";
    $out .= "not " unless $e->{pass};
    $out .= "ok";
    $out .= " $num" if defined($num);

    # The regex form is ~250ms, the index form is ~50ms
    my @extra;
    defined($name) && (
        (index($name, "\n") != -1 && (($name, @extra) = split(/\n\r?/, $name, -1))),
        ((index($name, "#" ) != -1  || substr($name, -1) eq '\\') && (($name =~ s|\\|\\\\|g), ($name =~ s|#|\\#|g)))
    );

    my $space = @extra ? ' ' x (length($out) + 2) : '';

    $out .= " - $name" if defined $name;
    $out .= " # TODO" if $in_todo;
    $out .= " $todo" if defined($todo) && length($todo);

    # The primary line of TAP, if the test passed this is all we need.
    return([OUT_STD, "$out\n"]) unless @extra;

    return $self->event_ok_multiline($out, $space, @extra);
}

sub event_ok_multiline {
    my $self = shift;
    my ($out, $space, @extra) = @_;

    return(
        [OUT_STD, "$out\n"],
        map {[OUT_STD, "#${space}$_\n"]} @extra,
    );
}

sub event_skip {
    my $self = shift;
    my ($e, $num) = @_;

    my $name   = $e->name;
    my $reason = $e->reason;
    my $todo   = $e->todo;

    my $out = "";
    $out .= "not " unless $e->{pass};
    $out .= "ok";
    $out .= " $num" if defined $num;
    $out .= " - $name" if $name;
    if (defined($todo)) {
        $out .= " # TODO & SKIP"
    }
    else {
        $out .= " # skip";
    }
    $out .= " $reason" if defined($reason) && length($reason);

    return([OUT_STD, "$out\n"]);
}

sub event_note {
    my $self = shift;
    my ($e, $num) = @_;

    chomp(my $msg = $e->message);
    $msg =~ s/^/# /;
    $msg =~ s/\n/\n# /g;

    return [OUT_STD, "$msg\n"];
}

sub event_diag {
    my $self = shift;
    my ($e, $num) = @_;

    chomp(my $msg = $e->message);
    $msg =~ s/^/# /;
    $msg =~ s/\n/\n# /g;

    return [OUT_ERR, "$msg\n"];
}

sub event_bail {
    my $self = shift;
    my ($e, $num) = @_;

    return if $e->nested;

    return [
        OUT_STD,
        "Bail out!  " . $e->reason . "\n",
    ];
}

sub event_exception {
    my $self = shift;
    my ($e, $num) = @_;
    return [ OUT_ERR, $e->error ];
}

sub event_subtest {
    my $self = shift;
    my ($e, $num) = @_;

    # A 'subtest' is a subclass of 'ok'. Let the code that renders 'ok' render
    # this event.
    my ($ok, @diag) = $self->event_ok($e, $num);

    # If the subtest is not buffered then the sub-events have already been
    # rendered, we can go ahead and return.
    return ($ok, @diag) unless $e->buffered;

    # In a verbose harness we indent the diagnostics from the 'Ok' event since
    # they will appear inside the subtest braces. This helps readability. In a
    # non-verbose harness we do not do this because it is less readable.
    if ($ENV{HARNESS_IS_VERBOSE}) {
        # index 0 is the filehandle, index 1 is the message we want to indent.
        $_->[1] =~ s/^(.*\S.*)$/    $1/mg for @diag;
    }

    # Add the trailing ' {' to the 'ok' line of TAP output.
    $ok->[1] =~ s/\n/ {\n/;

    # Render the sub-events, we use our own counter for these.
    my $count = 0;
    my @subs = map {
        # Bump the count for any event that should bump it.
        $count++ if $_->increments_count;

        # This indents all output lines generated for the sub-events.
        # index 0 is the filehandle, index 1 is the message we want to indent.
        map { $_->[1] =~ s/^(.*\S.*)$/    $1/mg; $_ } $self->event_tap($_, $count);
    } @{$e->subevents};

    return (
        $ok,                # opening ok - name {
        @diag,              #   diagnostics if the subtest failed
        @subs,              #   All the inner-event lines
        [OUT_STD(), "}\n"], # } (closing brace)
    );
}

sub event_plan {
    my $self = shift;
    my ($e, $num) = @_;

    my $directive = $e->directive;
    return if $directive && $directive eq 'NO PLAN';

    my $reason = $e->reason;
    $reason =~ s/\n/\n# /g if $reason;

    my $plan = "1.." . $e->max;
    if ($directive) {
        $plan .= " # $directive";
        $plan .= " $reason" if defined $reason;
    }

    return [OUT_STD, "$plan\n"];
}

sub event_version {
    my $self = shift;
    my ($e, $num) = @_;

    my $version = $e->version;

    return [OUT_STD, "TAP version $version\n"];
}

sub event_other {
    my $self = shift;
    my ($e, $num) = @_;
    return if $e->no_display;

    my @out;

    if (my ($max, $directive, $reason) = $e->sets_plan) {
        my $plan = "1..$max";
        $plan .= " # $directive" if $directive;
        $plan .= " $reason" if defined $reason;
        push @out => [OUT_STD, "$plan\n"];
    }

    if ($e->increments_count) {
        my $ok = "";
        $ok .= "not " if $e->causes_fail;
        $ok .= "ok";
        $ok .= " $num" if defined($num);
        $ok .= " - " . $e->summary if $e->summary;

        push @out => [OUT_STD, "$ok\n"];
    }
    else { # Comment
        my $handle =  ($e->causes_fail || $e->diagnostics) ? OUT_ERR : OUT_STD;
        my $summary = $e->summary || ref($e);
        chomp($summary);
        $summary =~ s/^/# /smg;
        push @out => [$handle, "$summary\n"];
    }

    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Formatter::TAP - Standard TAP formatter

=head1 DESCRIPTION

This is what takes events and turns them into TAP.

=head1 SYNOPSIS

    use Test2::Formatter::TAP;
    my $tap = Test2::Formatter::TAP->new();

    # Switch to utf8
    $tap->encoding('utf8');

    $tap->write($event, $number); # Output an event

=head1 METHODS

=over 4

=item $bool = $tap->no_numbers

=item $tap->set_no_numbers($bool)

Use to turn numbers on and off.

=item $arrayref = $tap->handles

=item $tap->set_handles(\@handles);

Can be used to get/set the filehandles. Indexes are identified by the
C<OUT_STD> and C<OUT_ERR> constants.

=item $encoding = $tap->encoding

=item $tap->encoding($encoding)

Get or set the encoding. By default no encoding is set, the original settings
of STDOUT and STDERR are used.

This directly modifies the stored filehandles, it does not create new ones.

=item $tap->write($e, $num)

Write an event to the console.

=item Test2::Formatter::TAP->register_event($pkg, sub { ... });

In general custom events are not supported. There are however occasions where
you might want to write a custom event type that results in TAP output. In
order to do this you use the C<register_event()> class method.

    package My::Event;
    use Test2::Formatter::TAP;

    use base 'Test2::Event';
    use Test2::Util::HashBase qw/pass name diag note/;

    Test2::Formatter::TAP->register_event(
        __PACKAGE__,
        sub {
            my $self = shift;
            my ($e, $num) = @_;
            return (
                [Test2::Formatter::TAP::OUT_STD, "ok $num - " . $e->name . "\n"],
                [Test2::Formatter::TAP::OUT_ERR, "# " . $e->name . " " . $e->diag . "\n"],
                [Test2::Formatter::TAP::OUT_STD, "# " . $e->name . " " . $e->note . "\n"],
            );
        }
    );

    1;

=back

=head2 EVENT METHODS

All these methods require the event itself. Optionally they can all except a
test number.

All methods return a list of array-refs. Each array-ref will have 2 items, the
first is an integer identifying an output handle, the second is a string that
should be written to the handle.

=over 4

=item @out = $TAP->event_ok($e)

=item @out = $TAP->event_ok($e, $num)

Process an L<Test2::Event::Ok> event.

=item @out = $TAP->event_plan($e)

=item @out = $TAP->event_plan($e, $num)

Process an L<Test2::Event::Plan> event.

=item @out = $TAP->event_note($e)

=item @out = $TAP->event_note($e, $num)

Process an L<Test2::Event::Note> event.

=item @out = $TAP->event_diag($e)

=item @out = $TAP->event_diag($e, $num)

Process an L<Test2::Event::Diag> event.

=item @out = $TAP->event_bail($e)

=item @out = $TAP->event_bail($e, $num)

Process an L<Test2::Event::Bail> event.

=item @out = $TAP->event_exception($e)

=item @out = $TAP->event_exception($e, $num)

Process an L<Test2::Event::Exception> event.

=item @out = $TAP->event_skip($e)

=item @out = $TAP->event_skip($e, $num)

Process an L<Test2::Event::Skip> event.

=item @out = $TAP->event_subtest($e)

=item @out = $TAP->event_subtest($e, $num)

Process an L<Test2::Event::Subtest> event.

=item @out = $TAP->event_other($e, $num)

Fallback for unregistered event types. It uses the L<Test2::Event> API to
convert the event to TAP.

=back

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Kent Fredric E<lt>kentnl@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
