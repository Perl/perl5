#!/usr/bin/perl -w
#
# Unconditionally regenerate:
#
#    pod/perlintern.pod
#    pod/perlapi.pod
#
# from information stored in
#
#    embed.fnc
#    plus all the .c and .h files listed in MANIFEST
#
# Has an optional arg, which is the directory to chdir to before reading
# MANIFEST and *.[ch].
#
# This script is invoked as part of 'make all'
#
# '=head1' are the only headings looked for.  If the first non-blank line after
# the heading begins with a word character, it is considered to be the first 
# line of documentation that applies to the heading itself.  That is, it is 
# output immediately after the heading, before the first function, and not 
# indented. The next input line that is a pod directive terminates this 
# heading-level documentation.

# The meanings of the flags fields in embed.fnc and the source code is
# documented at the top of embed.fnc.

use strict;
use warnings;

if (@ARGV) {
    my $workdir = shift;
    chdir $workdir
        or die "Couldn't chdir to '$workdir': $!";
}
require './regen/regen_lib.pl';
require './regen/embed_lib.pl';

my %described_elsewhere;

#
# See database of global and static function prototypes in embed.fnc
# This is used to generate prototype headers under various configurations,
# export symbols lists for different platforms, and macros to provide an
# implicit interpreter context argument.
#

my %docs;
my %seen;
my %funcflags;
my %missing;

my $section = "Unknown section";
# Somewhat loose match for an apidoc line so we can catch minor typos.
# Parentheses are used to capture portions so that below we verify
# that things are the actual correct syntax.
my $apidoc_re = qr/ ^ (\s*)            # $1
                      (=?)             # $2
                      (\s*)            # $3
                      for (\s*)        # $4
                      apidoc (_item)?  # $5
                      (\s*)            # $6
                      (.*?)            # $7
                      \s* \n /x;

sub check_api_doc_line ($$) {
    my ($file, $in) = @_;

    return unless $in =~ $apidoc_re;

    my $is_item = defined $5;
    my $is_in_proper_form = length $1 == 0
                         && length $2 > 0
                         && length $3 == 0
                         && length $4 > 0
                         && length $6 > 0
                         && length $7 > 0;
    my $proto_in_file = $7;
    my $proto = $proto_in_file;
    $proto = "||$proto" if $proto !~ /\|/;
    my ($flags, $ret_type, $name, @args) = split /\s*\|\s*/, $proto;

    $name && $is_in_proper_form or die <<EOS;
Bad apidoc at $file line $.:
  $in
Expected:
  =for apidoc flags|returntype|name|arg|arg|...
  =for apidoc flags|returntype|name
  =for apidoc name
(or 'apidoc_item')
EOS

    return ($name, $flags, $ret_type, $is_item, $proto_in_file, @args);
}

sub autodoc ($$) { # parse a file and extract documentation info
    my($fh,$file) = @_;
    my($in, $line_num, $header);

    my $file_is_C = $file =~ / \. [ch] $ /x;

    # Count lines easier
    my $get_next_line = sub { $line_num++; return <$fh> };

FUNC:
    while (defined($in = $get_next_line->())) {

        if ($in=~ /^=for apidoc_section\s*(.*)/) {
            $section = $1;
            next FUNC;
        }
        elsif ($file_is_C && $in=~ /^=head1 (.*)/) {
            # =head1 lines only have effect in C files

            $section = $1;

            # If the next non-space line begins with a word char, then it is
            # the start of heading-level documentation.
            if (defined($in = $get_next_line->())) {
                # Skip over empty lines
                while ($in =~ /^\s+$/) {
                    if (! defined($in = $get_next_line->())) {
                        next FUNC;
                    }
                }

                if ($in !~ /^\w/) {
                    redo FUNC;
                }
                $header = $in;

                # Continue getting the heading-level documentation until read
                # in any pod directive (or as a fail-safe, find a closing
                # comment to this pod in a C language file
HDR_DOC:
                while (defined($in = $get_next_line->())) {
                    if ($in =~ /^=\w/) {
                        redo FUNC;
                    }

                    if ($file_is_C && $in =~ m:^\s*\*/$:) {
                        warn "=cut missing? $file:$line_num:$in";;
                        last HDR_DOC;
                    }
                    $header .= $in;
                }
            }
            next FUNC;
        }

        if ($in =~ /^=for comment/) {
            $in = $get_next_line->();
            if ($in =~ /skip apidoc/) {   # Skips the next apidoc-like line
                while (defined($in = $get_next_line->())) {
                    last if $in =~ $apidoc_re;
                }
            }
            next FUNC;
        }

        my ($element_name, $flags, $ret_type, $is_item, $proto_in_file, @args)
                                            = check_api_doc_line($file, $in);
        next unless defined $element_name;
        die "Unexpected apidoc_item '$in' in $file near line $." if $is_item;

        # If the entry is also in embed.fnc, it should be defined completely
        # there, but not here
        my $embed_docref = delete $funcflags{$element_name};
        if ($embed_docref and %$embed_docref) {
            warn "embed.fnc entry overrides redundant information in"
                . " '$proto_in_file' in $file" if $flags || $ret_type || @args;
            $flags = $embed_docref->{'flags'};
            warn "embed.fnc entry '$element_name' missing 'd' flag"
                                                        unless $flags =~ /d/;
            $ret_type = $embed_docref->{'ret_type'};
            @args = @{$embed_docref->{args}};
        } elsif ($flags !~ /m/)  { # Not in embed.fnc, is missing if not a
                                    # macro
            $missing{$element_name} = $file;
        }

        die "flag $1 is not legal (for function $element_name (from $file))"
                    if $flags =~ / ( [^AabCDdEeFfhiMmNnTOoPpRrSsUuWXx] ) /x;


        die "'u' flag must also have 'm' flag' for $element_name" if $flags =~ /u/ && $flags !~ /m/;
        warn ("'$element_name' not \\w+ in '$proto_in_file' in $file")
                    if $flags !~ /N/ && $element_name !~ / ^ [_[:alpha:]] \w* $ /x;

        if (exists $seen{$element_name} && $flags !~ /h/) {
            # Temporarily ignore
            #die ("'$element_name' in $file was already documented in $seen{$element_name}");
        }
        else {
            $seen{$element_name} = $file;
        }

        my $docs = "";
        my $is_link_only = ($flags =~ /h/);
        if ($is_link_only) {    # Don't put meat of entry in perlapi
            next FUNC if $file_is_C;    # Don't put anything if C source

            # Here, is an 'h' flag in pod.  We add a reference to the pod (and
            # nothing else) to perlapi/intern.  (It would be better to add a
            # reference to the correct =item,=header, but something that makes
            # it harder is that it that might be a duplicate, like '=item *';
            # so that is a future enhancement XXX.  Another complication is
            # there might be more than one deserving candidates.)
            undef $header;
            my $podname = $file =~ s!.*/!!r;    # Rmv directory name(s)
            $podname =~ s/\.pod//;
            $docs .= "Described in L<$podname>.\n\n";

            # Keep track of all the pod files that we refer to.
            push $described_elsewhere{$podname}->@*, $podname;
        }
        else {
            DOC:
            while (defined($in = $get_next_line->())) {

                # Other pod commands are considered part of the current
                # function's docs, so can have lists, etc.
                last DOC if $in =~ /^=(cut|for\s+apidoc|head)/;
                if ($in =~ m:^\*/$:) {
                    warn "=cut missing? $file:$line_num:$in";;
                    last DOC;
                }
                $docs .= $in;
            }
        }
        $docs = "\n$docs" if $docs and $docs !~ /^\n/;

        my $inline_where = $flags =~ /A/ ? 'api' : 'guts';

        if (exists $docs{$inline_where}{$section}{$element_name}) {
            warn "$0: duplicate API entry for '$element_name' in $inline_where/$section\n";
            next;
        }
        $docs{$inline_where}{$section}{$element_name}
            = [$flags, $docs, $ret_type, $file, @args];

        # Create a special entry with an empty-string name for the
        # heading-level documentation.
        if (defined $header) {
            $docs{$inline_where}{$section}{""} = $header;
            undef $header;
        }

        if (defined $in) {
            if ($in =~ /^=(?:for|head)/) {
                redo FUNC;
            }
        } elsif (! $is_link_only) {
            warn "No doc for $file:$line_num:$in";
        }
    }
}

sub docout ($$$) { # output the docs for one function
    my($fh, $element_name, $docref) = @_;
    my($flags, $docs, $ret_type, $file, @args) = @$docref;
    $element_name =~ s/\s*$//;

    warn("Empty pod for $element_name (from $file)") unless $docs =~ /\S/;

    if ($flags =~ /D/) {
        my $function = $flags =~ /n/ ? 'definition' : 'function';
        $docs = "\n\nDEPRECATED!  It is planned to remove this $function from a
future release of Perl.  Do not use it for new code; remove it from
existing code.\n\n$docs";
    }
    else {
        $docs = "\n\nNOTE: this function is experimental and may change or be
removed without notice.\n\n$docs" if $flags =~ /x/;
    }

    # Is Perl_, but no #define foo # Perl_foo
    my $p = (($flags =~ /p/ && $flags =~ /o/ && $flags !~ /M/)
          || ($flags =~ /f/ && $flags !~ /T/));  # Can't handle threaded varargs

    $docs .= "NOTE: the C<perl_> form of this function is deprecated.\n\n"
         if $flags =~ /O/;
    if ($p) {
        $docs .= "NOTE: this function must be explicitly called as C<Perl_$element_name>";
        $docs .= " with an C<aTHX_> parameter" if $flags !~ /T/;
        $docs .= ".\n\n"
    }

    print $fh "=item $element_name\n";

    # If we're printing only a link to an element, this isn't the major entry,
    # so no X<> here.
    print $fh "X<$element_name>\n" unless $flags =~ /h/;

    print $fh $docs;

    if ($flags =~ /U/) { # no usage
        warn("U and s flags are incompatible") if $flags =~ /s/;
        # nothing
    } else {
        if ($flags =~ /n/) { # no args
            warn("$file: $element_name: n flag without m") unless $flags =~ /m/;
            warn("$file: $element_name: n flag but apparently has args") if @args;
            print $fh "\t$ret_type\t$element_name";
        } else { # full usage
            my $n            = "Perl_"x$p . $element_name;
            my $large_ret    = length $ret_type > 7;
            my $indent_size  = 7+8 # nroff: 7 under =head + 8 under =item
                            +8+($large_ret ? 1 + length $ret_type : 8)
                            +length($n) + 1;
            my $indent;
            print $fh "\t$ret_type" . ($large_ret ? ' ' : "\t") . "$n(";
            my $long_args;
            for (@args) {
                if ($indent_size + 2 + length > 79) {
                    $long_args=1;
                    $indent_size -= length($n) - 3;
                    last;
                }
            }
            my $args = '';
            if ($flags !~ /T/ && ($p || ($flags =~ /m/ && $element_name =~ /^Perl_/))) {
                $args = @args ? "pTHX_ " : "pTHX";
                if ($long_args) { print $fh $args; $args = '' }
            }
            $long_args and print $fh "\n";
            my $first = !$long_args;
            while () {
                if (!@args or
                    length $args
                    && $indent_size + 3 + length($args[0]) + length $args > 79
                ) {
                    print $fh
                    $first ? '' : (
                        $indent //=
                        "\t".($large_ret ? " " x (1+length $ret_type) : "\t")
                        ." "x($long_args ? 4 : 1 + length $n)
                    ),
                    $args, (","x($args ne 'pTHX_ ') . "\n")x!!@args;
                    $args = $first = '';
                }
                @args or last;
                $args .= ", "x!!(length $args && $args ne 'pTHX_ ')
                    . shift @args;
            }
            if ($long_args) { print $fh "\n", substr $indent, 0, -4 }
            print $fh ")";
        }
        print $fh ";" if $flags =~ /s/; # semicolon "dTHR;"
        print $fh "\n\n";
    }
    print $fh "=for hackers\nFound in file $file\n\n";
}

sub sort_helper {
    # Do a case-insensitive dictionary sort, with only alphabetics
    # significant, falling back to using everything for determinancy
    return (uc($a =~ s/[[:^alpha:]]//r) cmp uc($b =~ s/[[:^alpha:]]//r))
           || uc($a) cmp uc($b)
           || $a cmp $b;
}

sub output {
    my ($podname, $header, $dochash, $missing, $footer) = @_;
    #
    # strip leading '|' from each line which had been used to hide
    # pod from pod checkers.
    s/^\|//gm for $header, $footer;

    my $fh = open_new("pod/$podname.pod", undef,
                      {by => "$0 extracting documentation",
                       from => 'the C source files'}, 1);

    print $fh $header;

    my $key;
    for $key (sort sort_helper keys %$dochash) {
        my $section = $dochash->{$key};
        next unless keys %$section;     # Skip empty
        print $fh "\n=head1 $key\n\n";

        # Output any heading-level documentation and delete so won't get in
        # the way later
        if (exists $section->{""}) {
            print $fh $section->{""} . "\n";
            delete $section->{""};
        }
        next unless keys %$section;     # Skip empty
        print $fh "=over 8\n\n";

        for my $key (sort sort_helper keys %$section) {
            docout($fh, $key, $section->{$key});
        }
        print $fh "\n=back\n";
    }

    if (@$missing) {
        print $fh "\n=head1 Undocumented functions\n\n";
    print $fh $podname eq 'perlapi' ? <<'_EOB_' : <<'_EOB_';
The following functions have been flagged as part of the public API,
but are currently undocumented.  Use them at your own risk, as the
interfaces are subject to change.  Functions that are not listed in this
document are not intended for public use, and should NOT be used under any
circumstances.

If you feel you need to use one of these functions, first send email to
L<perl5-porters@perl.org|mailto:perl5-porters@perl.org>.  It may be
that there is a good reason for the function not being documented, and it
should be removed from this list; or it may just be that no one has gotten
around to documenting it.  In the latter case, you will be asked to submit a
patch to document the function.  Once your patch is accepted, it will indicate
that the interface is stable (unless it is explicitly marked otherwise) and
usable by you.
_EOB_
The following functions are currently undocumented.  If you use one of
them, you may wish to consider creating and submitting documentation for
it.
_EOB_
    print $fh "\n=over\n\n";

    for my $missing (sort sort_helper @$missing) {
        print $fh "=item C<$missing>\nX<$missing>\n\n";
    }
    print $fh "=back\n\n";
}
    print $fh $footer, "=cut\n";

    read_only_bottom_close_and_rename($fh);
}

foreach (@{(setup_embed())[0]}) {
    next if @$_ < 2;
    my ($flags, $ret_type, $func, @args) = @$_;
    s/\b(?:NN|NULLOK)\b\s+//g for @args;

    $funcflags{$func} = {
                         flags => $flags,
                         ret_type => $ret_type,
                         args => \@args,
                        };
}

# glob() picks up docs from extra .c or .h files that may be in unclean
# development trees.
open my $fh, '<', 'MANIFEST'
    or die "Can't open MANIFEST: $!";
while (my $line = <$fh>) {
    next unless my ($file) = $line =~ /^(\S+\.(?:[ch]|pod))\t/;

    # Don't pick up pods from these.  (We may pick up generated stuff from
    # /lib though)
    next if $file =~ m! ^ ( cpan | dist | ext ) / !x;

    open F, '<', $file or die "Cannot open $file for docs: $!\n";
    $section = "Functions in file $file\n";
    autodoc(\*F,$file);
    close F or die "Error closing $file: $!\n";
}
close $fh or die "Error whilst reading MANIFEST: $!";

for (sort keys %funcflags) {
    next unless $funcflags{$_}{flags} =~ /d/;
    next if $funcflags{$_}{flags} =~ /h/;
    warn "no docs for $_\n"
}

foreach (sort keys %missing) {
    warn "Function '$_', documented in $missing{$_}, not listed in embed.fnc";
}

# walk table providing an array of components in each line to
# subroutine, printing the result

# List of funcs in the public API that aren't also marked as core-only,
# experimental nor deprecated.
my @missing_api = grep $funcflags{$_}{flags} =~ /A/
                    && $funcflags{$_}{flags} !~ /[xD]/
                    && !$docs{api}{$_}, keys %funcflags;

my $other_places = join ", ", map { "L<$_>" } sort sort_helper qw( perlclib perlxs),
                                                               keys %described_elsewhere;

output('perlapi', <<"_EOB_", $docs{api}, \@missing_api, <<"_EOE_");
|=encoding UTF-8
|
|=head1 NAME
|
|perlapi - autogenerated documentation for the perl public API
|
|=head1 DESCRIPTION
|X<Perl API> X<API> X<api>
|
|This file contains most of the documentation of the perl public API, as
|generated by F<embed.pl>.  Specifically, it is a listing of functions,
|macros, flags, and variables that may be used by extension writers.  Besides
|L<perlintern> and F<config.h>, some items are listed here as being actually
|documented in another pod.
|
|L<At the end|/Undocumented functions> is a list of functions which have yet
|to be documented.  Patches welcome!  The interfaces of these are subject to
|change without notice.
|
|Anything not listed here or in the other mentioned pods is not part of the
|public API, and should not be used by extension writers at all.  For these
|reasons, blindly using functions listed in F<proto.h> is to be avoided when
|writing extensions.
|
|In Perl, unlike C, a string of characters may generally contain embedded
|C<NUL> characters.  Sometimes in the documentation a Perl string is referred
|to as a "buffer" to distinguish it from a C string, but sometimes they are
|both just referred to as strings.
|
|Note that all Perl API global variables must be referenced with the C<PL_>
|prefix.  Again, those not listed here are not to be used by extension writers,
|and can be changed or removed without notice; same with macros.
|Some macros are provided for compatibility with the older,
|unadorned names, but this support may be disabled in a future release.
|
|Perl was originally written to handle US-ASCII only (that is characters
|whose ordinal numbers are in the range 0 - 127).
|And documentation and comments may still use the term ASCII, when
|sometimes in fact the entire range from 0 - 255 is meant.
|
|The non-ASCII characters below 256 can have various meanings, depending on
|various things.  (See, most notably, L<perllocale>.)  But usually the whole
|range can be referred to as ISO-8859-1.  Often, the term "Latin-1" (or
|"Latin1") is used as an equivalent for ISO-8859-1.  But some people treat
|"Latin1" as referring just to the characters in the range 128 through 255, or
|sometimes from 160 through 255.
|This documentation uses "Latin1" and "Latin-1" to refer to all 256 characters.
|
|Note that Perl can be compiled and run under either ASCII or EBCDIC (See
|L<perlebcdic>).  Most of the documentation (and even comments in the code)
|ignore the EBCDIC possibility.
|For almost all purposes the differences are transparent.
|As an example, under EBCDIC,
|instead of UTF-8, UTF-EBCDIC is used to encode Unicode strings, and so
|whenever this documentation refers to C<utf8>
|(and variants of that name, including in function names),
|it also (essentially transparently) means C<UTF-EBCDIC>.
|But the ordinals of characters differ between ASCII, EBCDIC, and
|the UTF- encodings, and a string encoded in UTF-EBCDIC may occupy a different
|number of bytes than in UTF-8.
|
|The listing below is alphabetical, case insensitive.
|
_EOB_
|
|=head1 AUTHORS
|
|Until May 1997, this document was maintained by Jeff Okamoto
|<okamoto\@corp.hp.com>.  It is now maintained as part of Perl itself.
|
|With lots of help and suggestions from Dean Roehrich, Malcolm Beattie,
|Andreas Koenig, Paul Hudson, Ilya Zakharevich, Paul Marquess, Neil
|Bowers, Matthew Green, Tim Bunce, Spider Boardman, Ulrich Pfeifer,
|Stephen McCamant, and Gurusamy Sarathy.
|
|API Listing originally by Dean Roehrich <roehrich\@cray.com>.
|
|Updated to be autogenerated from comments in the source by Benjamin Stuhl.
|
|=head1 SEE ALSO
|
|F<config.h>, L<perlintern>, $other_places
_EOE_

# List of non-static internal functions
my @missing_guts =
 grep $funcflags{$_}{flags} !~ /[AS]/ && !$docs{guts}{$_}, keys %funcflags;

output('perlintern', <<'_EOB_', $docs{guts}, \@missing_guts, <<"_EOE_");
|=head1 NAME
|
|perlintern - autogenerated documentation of purely B<internal>
|Perl functions
|
|=head1 DESCRIPTION
|X<internal Perl functions> X<interpreter functions>
|
|This file is the autogenerated documentation of functions in the
|Perl interpreter that are documented using Perl's internal documentation
|format but are not marked as part of the Perl API.  In other words,
|B<they are not for use in extensions>!
|
_EOB_
|
|=head1 AUTHORS
|
|The autodocumentation system was originally added to the Perl core by
|Benjamin Stuhl.  Documentation is by whoever was kind enough to
|document their functions.
|
|=head1 SEE ALSO
|
|F<config.h>, L<perlapi>, $other_places
_EOE_
