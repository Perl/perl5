#############################################################################
# Pod/Checker.pm -- check pod documents for syntax errors
#
# Copyright (C) 1994-1999 by Bradford Appleton. All rights reserved.
# This file is part of "PodParser". PodParser is free software;
# you can redistribute it and/or modify it under the same terms
# as Perl itself.
#############################################################################

package Pod::Checker;

use vars qw($VERSION);
$VERSION = 1.090;  ## Current version of this package
require  5.004;    ## requires this Perl version or later

=head1 NAME

Pod::Checker, podchecker() - check pod documents for syntax errors

=head1 SYNOPSIS

  use Pod::Checker;

  $syntax_okay = podchecker($filepath, $outputpath, %options);

=head1 OPTIONS/ARGUMENTS

C<$filepath> is the input POD to read and C<$outputpath> is
where to write POD syntax error messages. Either argument may be a scalar
indcating a file-path, or else a reference to an open filehandle.
If unspecified, the input-file it defaults to C<\*STDIN>, and
the output-file defaults to C<\*STDERR>.

=head2 Options

=over 4

=item B<-warnings> =E<gt> I<val>

Turn warnings on/off. See L<"Warnings">.

=back

=head1 DESCRIPTION

B<podchecker> will perform syntax checking of Perl5 POD format documentation.

I<NOTE THAT THIS MODULE IS CURRENTLY IN THE INITIAL DEVELOPMENT STAGE!>
As of this writing, all it does is check for unknown '=xxxx' commands,
unknown 'X<...>' interior-sequences, and unterminated interior sequences.

It is hoped that curious/ambitious user will help flesh out and add the
additional features they wish to see in B<Pod::Checker> and B<podchecker>.

The following additional checks are preformed:

=over 4

=item *

Check for proper balancing of C<=begin> and C<=end>.

=item *

Check for proper nesting and balancing of C<=over>, C<=item> and C<=back>.

=item *

Check for same nested interior-sequences (e.g. C<LE<lt>...LE<lt>...E<gt>...E<gt>>).

=item *

Check for malformed entities.

=item *

Check for correct syntax of hyperlinks C<LE<lt>E<gt>>. See L<perlpod> for 
details.

=item *

Check for unresolved document-internal links.

=back

=head2 Warnings

The following warnings are printed. These may not necessarily cause trouble,
but indicate mediocre style.

=over 4

=item *

Spurious characters after C<=back> and C<=end>.

=item *

Unescaped C<E<lt>> and C<E<gt>> in the text.

=item *

Missing arguments for C<=begin> and C<=over>.

=item *

Empty C<=over> / C<=back> list.

=item *

Hyperlinks: leading/trailing whitespace, brackets C<()> in the page name.

=back

=head1 DIAGNOSTICS

I<[T.B.D.]>

=head1 RETURN VALUE

B<podchecker> returns the number of POD syntax errors found or -1 if
there were no POD commands at all found in the file.

=head1 EXAMPLES

I<[T.B.D.]>

=head1 AUTHOR

Brad Appleton E<lt>bradapp@enteract.comE<gt> (initial version),
Marek Rouchal E<lt>marek@saftsack.fs.uni-bayreuth.deE<gt>

Based on code for B<Pod::Text::pod2text()> written by
Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

=cut

#############################################################################

use strict;
#use diagnostics;
use Carp;
use Exporter;
use Pod::Parser;

use vars qw(@ISA @EXPORT);
@ISA = qw(Pod::Parser);
@EXPORT = qw(&podchecker);

use vars qw(%VALID_COMMANDS %VALID_SEQUENCES);

my %VALID_COMMANDS = (
    'pod'    =>  1,
    'cut'    =>  1,
    'head1'  =>  1,
    'head2'  =>  1,
    'over'   =>  1,
    'back'   =>  1,
    'item'   =>  1,
    'for'    =>  1,
    'begin'  =>  1,
    'end'    =>  1,
);

my %VALID_SEQUENCES = (
    'I'  =>  1,
    'B'  =>  1,
    'S'  =>  1,
    'C'  =>  1,
    'L'  =>  1,
    'F'  =>  1,
    'X'  =>  1,
    'Z'  =>  1,
    'E'  =>  1,
);

##---------------------------------------------------------------------------

##---------------------------------
## Function definitions begin here
##---------------------------------

sub podchecker( $ ; $ % ) {
    my ($infile, $outfile, %options) = @_;
    local $_;

    ## Set defaults
    $infile  ||= \*STDIN;
    $outfile ||= \*STDERR;

    ## Now create a pod checker
    my $checker = new Pod::Checker(%options);

    ## Now check the pod document for errors
    $checker->parse_from_file($infile, $outfile);
    
    ## Return the number of errors found
    return $checker->num_errors();
}

##---------------------------------------------------------------------------

##-------------------------------
## Method definitions begin here
##-------------------------------

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %params = @_;
    my $self = {%params};
    bless $self, $class;
    $self->initialize();
    return $self;
}

sub initialize {
    my $self = shift;
    ## Initialize number of errors, and setup an error function to
    ## increment this number and then print to the designated output.
    $self->{_NUM_ERRORS} = 0;
    $self->errorsub('poderror');
    $self->{_commands} = 0; # total number of POD commands encountered
    $self->{_list_stack} = []; # stack for nested lists
    $self->{_have_begin} = ''; # stores =begin
    $self->{_links} = []; # stack for internal hyperlinks
    $self->{_nodes} = []; # stack for =head/=item nodes
    $self->{-warnings} = 1 unless(defined $self->{-warnings});
}

## Invoked as $self->poderror( @args ), or $self->poderror( {%opts}, @args )
sub poderror {
    my $self = shift;
    my %opts = (ref $_[0]) ? %{shift()} : ();

    ## Retrieve options
    chomp( my $msg  = ($opts{-msg} || "")."@_" );
    my $line = (exists $opts{-line}) ? " at line $opts{-line}" : "";
    my $file = (exists $opts{-file}) ? " in file $opts{-file}" : "";
    my $severity = (exists $opts{-severity}) ? "*** $opts{-severity}: " : "";

    ## Increment error count and print message "
    ++($self->{_NUM_ERRORS}) 
        if(!%opts || ($opts{-severity} && $opts{-severity} eq 'ERROR'));
    my $out_fh = $self->output_handle();
    print $out_fh ($severity, $msg, $line, $file, "\n");
}

sub num_errors {
   return (@_ > 1) ? ($_[0]->{_NUM_ERRORS} = $_[1]) : $_[0]->{_NUM_ERRORS};
}

## overrides for Pod::Parser

sub end_pod {
   ## Do some final checks and
   ## print the number of errors found
   my $self   = shift;
   my $infile = $self->input_file();
   my $out_fh = $self->output_handle();

   if(@{$self->{_list_stack}}) {
       # _TODO_ display, but don't count them for now
       my $list;
       while($list = shift(@{$self->{_list_stack}})) {
           $self->poderror({ -line => 'EOF', -file => $infile,
               -severity => 'ERROR', -msg => "=over on line " .
               $list->start() . " without closing =back" }); #"
       }
   }

   # check validity of document internal hyperlinks
   # first build the node names from the paragraph text
   my %nodes;
   foreach($self->node()) {
       #print "Have node: +$_+\n";
       $nodes{$_} = 1;
       if(/^(\S+)\s+/) {
           # we have more than one word. Use the first as a node, too.
           # This is used heavily in perlfunc.pod
           $nodes{$1} ||= 2; # derived node
       }
   }
   foreach($self->hyperlink()) {
       #print "Seek node: +$_+\n";
       my $line = '';
       s/^(\d+):// && ($line = $1);
       if($_ && !$nodes{$_}) {
           $self->poderror({ -line => $line, -file => $infile,
               -severity => 'ERROR',
               -msg => "unresolved internal link `$_'"});
       }
   }

   ## Print the number of errors found
   my $num_errors = $self->num_errors();
   if ($num_errors > 0) {
      printf $out_fh ("$infile has $num_errors pod syntax %s.\n",
                      ($num_errors == 1) ? "error" : "errors");
   }
   elsif($self->{_commands} == 0) {
      print $out_fh "$infile does not contain any pod commands.\n";
      $self->num_errors(-1);
   }
   else {
      print $out_fh "$infile pod syntax OK.\n";
   }
}

sub command { 
    my ($self, $cmd, $paragraph, $line_num, $pod_para) = @_;
    my ($file, $line) = $pod_para->file_line;
    ## Check the command syntax
    my $arg; # this will hold the command argument
    if (! $VALID_COMMANDS{$cmd}) {
       $self->poderror({ -line => $line, -file => $file, -severity => 'ERROR',
                         -msg => "Unknown command \"$cmd\"" });
    }
    else {
        $self->{_commands}++; # found a valid command
        ## check syntax of particular command
        if($cmd eq 'over') {
            # start a new list
            unshift(@{$self->{_list_stack}}, 
                Pod::List->new(
                    -indent => $paragraph,
                    -start => $line,
                    -file => $file));
        }
        elsif($cmd eq 'item') {
            unless(@{$self->{_list_stack}}) {
                $self->poderror({ -line => $line, -file => $file,
                     -severity => 'ERROR', 
                     -msg => "=item without previous =over" });
            }
            else {
                # check for argument
                $arg = $self->_interpolate_and_check($paragraph, $line, $file);
                unless($arg && $arg =~ /(\S+)/) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'WARNING', 
                         -msg => "No argument for =item" });
                }
                # add this item
                $self->{_list_stack}[0]->item($arg || '');
                # remember this node
                $self->node($arg) if($arg);
            }
        }
        elsif($cmd eq 'back') {
            # check if we have an open list
            unless(@{$self->{_list_stack}}) {
                $self->poderror({ -line => $line, -file => $file,
                         -severity => 'ERROR', 
                         -msg => "=back without previous =over" });
            }
            else {
                # check for spurious characters
                $arg = $self->_interpolate_and_check($paragraph, $line,$file);
                if($arg && $arg =~ /\S/) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'WARNING', 
                         -msg => "Spurious character(s) after =back" });
                }
                # close list
                my $list = shift @{$self->{_list_stack}};
                # check for empty lists
                if(!$list->item() && $self->{-warnings}) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'WARNING', 
                         -msg => "No items in =over (at line " .
                         $list->start() . ") / =back list"}); #"
                }
            }
        }
        elsif($cmd =~ /^head/) {
            # check if there is an open list
            if(@{$self->{_list_stack}}) {
                my $list;
                while($list = shift(@{$self->{_list_stack}})) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'ERROR', 
                         -msg => "unclosed =over (line ". $list->start() .
                         ") at $cmd" });
                }
            }
            # remember this node
            $arg = $self->_interpolate_and_check($paragraph, $line,$file);
            $self->node($arg) if($arg);
        }
        elsif($cmd eq 'begin') {
            if($self->{_have_begin}) {
                # already have a begin
                $self->poderror({ -line => $line, -file => $file,
                     -severity => 'ERROR', 
                     -msg => "Nested =begin's (first at line " .
                     $self->{_have_begin} . ")"});
            }
            else {
                # check for argument
                $arg = $self->_interpolate_and_check($paragraph, $line,$file);
                unless($arg && $arg =~ /(\S+)/) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'WARNING', 
                         -msg => "No argument for =begin"});
                }
                # remember the =begin
                $self->{_have_begin} = "$line:$1";
            }
        }
        elsif($cmd eq 'end') {
            if($self->{_have_begin}) {
                # close the existing =begin
                $self->{_have_begin} = '';
                # check for spurious characters
                $arg = $self->_interpolate_and_check($paragraph, $line,$file);
                if($arg && $arg =~ /\S/) {
                    $self->poderror({ -line => $line, -file => $file,
                         -severity => 'WARNING', 
                         -msg => "Spurious character(s) after =end" });
                }
            }
            else {
                # don't have a matching =begin
                $self->poderror({ -line => $line, -file => $file,
                     -severity => 'WARNING', 
                     -msg => "=end without =begin" });
            }
        }
    }
    ## Check the interior sequences in the command-text
    $self->_interpolate_and_check($paragraph, $line,$file)
        unless(defined $arg);
}

sub _interpolate_and_check {
    my ($self, $paragraph, $line, $file) = @_;
    ## Check the interior sequences in the command-text
    # and return the text
    $self->_check_ptree(
        $self->parse_text($paragraph,$line), $line, $file, '');
}

sub _check_ptree {
    my ($self,$ptree,$line,$file,$nestlist) = @_;
    local($_);
    my $text = '';
    # process each node in the parse tree
    foreach(@$ptree) {
        # regular text chunk
        unless(ref) {
            my $count;
            # count the unescaped angle brackets
            my $i = $_;
            if($count = $i =~ s/[<>]/$self->expand_unescaped_bracket($&)/ge) {
                $self->poderror({ -line => $line, -file => $file,
                     -severity => 'WARNING', 
                     -msg => "$count unescaped <>" });
            }
            $text .= $i;
            next;
        }
        # have an interior sequence
        my $cmd = $_->cmd_name();
        my $contents = $_->parse_tree();
        ($file,$line) = $_->file_line();
        # check for valid tag
        if (! $VALID_SEQUENCES{$cmd}) {
            $self->poderror({ -line => $line, -file => $file,
                 -severity => 'ERROR', 
                 -msg => qq(Unknown interior-sequence "$cmd")});
            # expand it anyway
            $text .= $self->_check_ptree($contents, $line, $file, "$nestlist$cmd");
            next;
        }
        if($nestlist =~ /$cmd/) {
            $self->poderror({ -line => $line, -file => $file,
                 -severity => 'ERROR', 
                 -msg => "nested commands $cmd<...$cmd<...>...>"});
            # _TODO_ should we add the contents anyway?
            # expand it anyway, see below
        }
        if($cmd eq 'E') {
            # preserve entities
            if(@$contents > 1 || ref $$contents[0] || $$contents[0] !~ /^\w+$/) {
                $self->poderror({ -line => $line, -file => $file,
                    -severity => 'ERROR', 
                    -msg => "garbled entity " . $_->raw_text()});
                next;
            }
            $text .= $self->expand_entity($$contents[0]);
        }
        elsif($cmd eq 'L') {
            # try to parse the hyperlink
            my $link = Pod::Hyperlink->new($contents->raw_text());
            unless(defined $link) {
                $self->poderror({ -line => $line, -file => $file,
                    -severity => 'ERROR', 
                    -msg => "malformed link L<>: $@"});
                next;
            }
            $link->line($line); # remember line
            if($self->{-warnings}) {
                foreach my $w ($link->warning()) {
                    $self->poderror({ -line => $line, -file => $file,
                        -severity => 'WARNING', 
                        -msg => $w });
                }
            }
            # check the link text
            $text .= $self->_check_ptree($self->parse_text($link->text(),
                $line), $line, $file, "$nestlist$cmd");
            my $node = '';
            $node = $self->_check_ptree($self->parse_text($link->node(),
                $line), $line, $file, "$nestlist$cmd")
                if($link->node());
            # store internal link
            # _TODO_ what if there is a link to the page itself by the name,
            # e.g. Tk::Pod : L<Tk::Pod/"DESCRIPTION">
            $self->hyperlink("$line:$node") if($node && !$link->page());
        }
        elsif($cmd =~ /[BCFIS]/) {
            # add the guts
            $text .= $self->_check_ptree($contents, $line, $file, "$nestlist$cmd");
        }
        else {
            # check, but add nothing to $text (X<>, Z<>)
            $self->_check_ptree($contents, $line, $file, "$nestlist$cmd");
        }
    }
    $text;
}

# default method - just return it
sub expand_unescaped_bracket {
    my ($self,$bracket) = @_;
    $bracket;
}

# keep the entities
sub expand_entity {
    my ($self,$entity) = @_;
    "E<$entity>";
}

# _TODO_ overloadable methods for BC..Z<...> expansion

sub verbatim { 
    ## Nothing to check
    ## my ($self, $paragraph, $line_num, $pod_para) = @_;
}

sub textblock { 
    my ($self, $paragraph, $line_num, $pod_para) = @_;
    my ($file, $line) = $pod_para->file_line;
    $self->_interpolate_and_check($paragraph, $line,$file);
}

# set/return nodes of the current POD
sub node {
    my ($self,$text) = @_;
    if(defined $text) {
        $text =~ s/[\s\n]+$//; # strip trailing whitespace
        # add node
        push(@{$self->{_nodes}}, $text);
        return $text;
    }
    @{$self->{_nodes}};
}

# set/return hyperlinks of the current POD
sub hyperlink {
    my $self = shift;
    if($_[0]) {
        push(@{$self->{_links}}, $_[0]);
        return $_[0];
    }
    @{$self->{_links}};
}

#-----------------------------------------------------------------------------
# Pod::List
#
# class to hold POD list info (=over, =item, =back)
#-----------------------------------------------------------------------------

package Pod::List;

use Carp;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %params = @_;
    my $self = {%params};
    bless $self, $class;
    $self->initialize();
    return $self;
}

sub initialize {
    my $self = shift;
    $self->{-file} ||= 'unknown';
    $self->{-start} ||= 'unknown';
    $self->{-indent} ||= 4; # perlpod: "should be the default"
    $self->{_items} = [];
}

# The POD file name the list appears in
sub file {
   return (@_ > 1) ? ($_[0]->{-file} = $_[1]) : $_[0]->{-file};
}

# The line in the file the node appears
sub start {
   return (@_ > 1) ? ($_[0]->{-start} = $_[1]) : $_[0]->{-start};
}

# indent level
sub indent {
   return (@_ > 1) ? ($_[0]->{-indent} = $_[1]) : $_[0]->{-indent};
}

# The individual =items of this list
sub item {
    my ($self,$item) = @_;
    if(defined $item) {
        push(@{$self->{_items}}, $item);
        return $item;
    }
    else {
        return @{$self->{_items}};
    }
}

#-----------------------------------------------------------------------------
# Pod::Hyperlink
#
# class to hold hyperlinks (L<>)
#-----------------------------------------------------------------------------

package Pod::Hyperlink;

=head1 NAME

Pod::Hyperlink - class for manipulation of POD hyperlinks

=head1 SYNOPSIS

    my $link = Pod::Hyperlink->new('alternative text|page/"section in page"');

=head1 DESCRIPTION

The B<Pod::Hyperlink> class is mainly designed to parse the contents of the
C<LE<lt>...E<gt>> sequence, providing a simple interface for accessing the
different parts of a POD hyperlink.

=head1 METHODS

=over 4

=item new()

The B<new()> method can either be passed a set of key/value pairs or a single
scalar value, namely the contents of a C<LE<lt>...E<gt>> sequence. An object
of the class C<Pod::Hyperlink> is returned. The value C<undef> indicates a
failure, the error message is stored in C<$@>.

=item parse()

This method can be used to (re)parse a (new) hyperlink. The result is stored
in the current object.

=item markup($on,$off,$pageon,$pageoff)

The result of this method is a string the represents the textual value of the
link, but with included arbitrary markers that highlight the active portion
of the link. This will mainly be used by POD translators and saves the
effort of determining which words have to be highlighted. Examples: Depending
on the type of link, the following text will be returned, the C<*> represent
the places where the section/item specific on/off markers will be placed
(link to a specific node) and C<+> for the pageon/pageoff markers (link to the
top of the page).

  the +perl+ manpage
  the *$|* entry in the +perlvar+ manpage
  the section on *OPTIONS* in the +perldoc+ manpage
  the section on *DESCRIPTION* elsewhere in this document

This method is read-only.

=item text()

This method returns the textual representation of the hyperlink as above,
but without markers (read only).

=item warning()

After parsing, this method returns any warnings ecountered during the
parsing process.

=item page()

This method sets or returns the POD page this link points to.

=item node()

As above, but the destination node text of the link.

=item type()

The node type, either C<section> or C<item>.

=item alttext()

Sets or returns an alternative text specified in the link.

=item line(), file()

Just simple slots for storing information about the line and the file
the link was incountered in. Has to be filled in manually.

=back

=head1 AUTHOR

Marek Rouchal E<lt>marek@saftsack.fs.uni-bayreuth.deE<gt>, borrowing
a lot of things from L<pod2man> and L<pod2roff>.

=cut

use Carp;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = +{};
    bless $self, $class;
    $self->initialize();
    if(defined $_[0]) {
        if(ref($_[0])) {
            # called with a list of parameters
            %$self = %{$_[0]};
        }
        else {
            # called with L<> contents
            return undef unless($self->parse($_[0]));
        }
    }
    return $self;
}

sub initialize {
    my $self = shift;
    $self->{-line} ||= 'undef';
    $self->{-file} ||= 'undef';
    $self->{-page} ||= '';
    $self->{-node} ||= '';
    $self->{-alttext} ||= '';
    $self->{-type} ||= 'undef';
    $self->{_warnings} = [];
    $self->_construct_text();
}

sub parse {
    my $self = shift;
    local($_) = $_[0];
    # syntax check the link and extract destination
    my ($alttext,$page,$section,$item) = ('','','','');

    # strip leading/trailing whitespace
    if(s/^[\s\n]+//) {
        $self->warning("ignoring leading whitespace in link");
    }
    if(s/[\s\n]+$//) {
        $self->warning("ignoring trailing whitespace in link");
    }

    # collapse newlines with whitespace
    s/\s*\n\s*/ /g;

    # extract alternative text
    if(s!^([^|/"\n]*)[|]!!) {
        $alttext = $1;
    }
    # extract page
    if(s!^([^|/"\s]*)(?=/|$)!!) {
        $page = $1;
    }
    # extract section
    if(s!^/?"([^"\n]+)"$!!) { # e.g. L</"blah blah">
        $section = $1;
    }
    # extact item
    if(s!^/(.*)$!!) {
        $item = $1;
    }
    # last chance here
    if(s!^([^|"\s\n/][^"\n/]*)$!!) { # e.g. L<lah di dah>
        $section = $1;
    }
    # now there should be nothing left
    if(length) {
        _invalid_link("garbled entry (spurious characters `$_')");
        return undef;
    }
    elsif(!(length($page) || length($section) || length($item))) {
        _invalid_link("empty link");
        return undef;
    }
    elsif($alttext =~ /[<>]/) {
        _invalid_link("alternative text contains < or >");
        return undef;
    }
    else { # no errors so far
        if($page =~ /[(]\d\w*[)]$/) {
             $self->warning("brackets in `$page'");
             $page = $`; # strip that extension
        }
        if($page =~ /^(\s*)(\S+)(\s*)/ && (length($1) || length($3))) {
             $self->warning("whitespace in `$page'");
             $page = $2; # strip that extension
        }
    }
    $self->page($page);
    $self->node($section || $item); # _TODO_ do not distinguish for now
    $self->alttext($alttext);
    $self->type($item ? 'item' : 'section');
    1;
}

sub _construct_text {
    my $self = shift;
    my $alttext = $self->alttext();
    my $type = $self->type();
    my $section = $self->node();
    my $page = $self->page();
    $self->{_text} =
        $alttext ? $alttext : (
        !$section       ? '' :
        $type eq 'item' ? 'the ' . $section . ' entry' :
                          'the section on ' . $section ) .
        ($page ? ($section ? ' in ':''). 'the ' . $page . ' manpage' :
                'elsewhere in this document');
    # for being marked up later
    $self->{_markup} =
        $alttext ? '<SECTON>' . $alttext . '<SECTOFF>' : (
        !$section      ? '' : 
        $type eq 'item' ? 'the <SECTON>' . $section . '<SECTOFF> entry' :
                          'the section on <SECTON>' . $section . '<SECTOFF>' ) .
        ($page ? ($section ? ' in ':'') . 'the <PAGEON>' .
            $page . '<PAGEOFF> manpage' :
        ' elsewhere in this document');
}

# include markup
sub markup {
    my ($self,$on,$off,$pageon,$pageoff) = @_;
    $on ||= '';
    $off ||= '';
    $pageon ||= '';
    $pageoff ||= '';
    $_[0]->_construct_text;
    my $str = $self->{_markup};
    $str =~ s/<SECTON>/$on/;
    $str =~ s/<SECTOFF>/$off/;
    $str =~ s/<PAGEON>/$pageon/;
    $str =~ s/<PAGEOFF>/$pageoff/;
    return $str;
}

# The complete link's text
sub text {
    $_[0]->_construct_text();
    $_[0]->{_text};
}

# The POD page the link appears on
sub warning {
   my $self = shift;
   if(@_) {
       push(@{$self->{_warnings}}, @_);
       return @_;
   }
   return @{$self->{_warnings}};
}

# The POD file name the link appears in
sub file {
   return (@_ > 1) ? ($_[0]->{-file} = $_[1]) : $_[0]->{-file};
}

# The line in the file the link appears
sub line {
   return (@_ > 1) ? ($_[0]->{-line} = $_[1]) : $_[0]->{-line};
}

# The POD page the link appears on
sub page {
   return (@_ > 1) ? ($_[0]->{-page} = $_[1]) : $_[0]->{-page};
}

# The link destination
sub node {
   return (@_ > 1) ? ($_[0]->{-node} = $_[1]) : $_[0]->{-node};
}

# Potential alternative text
sub alttext {
   return (@_ > 1) ? ($_[0]->{-alttext} = $_[1]) : $_[0]->{-alttext};
}

# The type
sub type {
   return (@_ > 1) ? ($_[0]->{-type} = $_[1]) : $_[0]->{-type};
}

sub _invalid_link {
    my ($msg) = @_;
    # this sets @_
    #eval { die "$msg\n" };
    #chomp $@;
    $@ = $msg; # this seems to work, too!
    undef;
}

1;
