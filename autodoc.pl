#!/usr/bin/perl -w

use Text::Tabs;
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
my %missing_macros;

my $link_text = "Described in";

my %valid_sections = (
    'Floating point configuration values' => {
        header => <<~'EOT',
            There are a few symbols defined in this section that tell you if a
            given mathematical library function is available on this platform.
            But there are many more that are mentioned in
            L</List of capability C<HAS_I<foo>> symbols>.  For example
            C<HAS_ASINH>, for the hyperbolic sine function.
            EOT
      },
    'General Configuration' => {
        header => <<~'EOT',
            This section contains configuration information not otherwise
            found in the more specialized sections of this document.  At the
            end is a list of C<#defines> whose name should be enough to tell
            you what they do, and a list of #defines which tell you if you
            need to C<#include> files to get the corresponding functionality.
            EOT

        footer => <<~'EOT',

            =head2 List of capability C<HAS_I<foo>> symbols

            This is a list of those symbols that indicate if the current
            platform has a certain capability.  Their names all begin with
            C<HAS_>.  Only those symbols whose capability is directly derived
            from the name are listed here.  All others have their meaning
            expanded out elsewhere in this document.  This (relatively)
            compact list is because the expansion would add little or no value
            and take up a lot of space (because there are so many).  Some
            symbols with easy to derive meanings are instead in the specialized
            sections of this document to which they belong.

            Each symbol here will be C<#define>d if and only if the platform
            has the capability.  If you need more detail, see the
            corresponding entry in F<config.h>.

            __HAS_LIST__

            Example usage:

            =over

             #ifdef HAS_STRNLEN
               use strnlen()
             #else
               use an alternative implementation
             #endif

            =back

            =head2 List of C<#include> needed symbols

            This list contains symbols that indicate if certain C<#include>
            files are present on the platform.  If your code accesses the
            functionality that one of these is for, you will need to
            C<#include> it if the symbol on this list is C<#define>d.  For
            more detail, see the corresponding entry in F<config.h>.

            __INCLUDE_LIST__

            Example usage:

            =over

             #ifdef I_WCHAR
               #include <wchar.h>
             #endif

            =back
            EOT
      },
);

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
# Only certain flags, dealing with display, are acceptable for apidoc_item
my $display_flags = "fFnDopsT";

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
    my($in, $line_num, $header, $section);

    my $file_is_C = $file =~ / \. [ch] $ /x;

    # Count lines easier
    my $get_next_line = sub { $line_num++; return <$fh> };

    # Read the file
    while ($in = $get_next_line->()) {
        last unless defined $in;

        next unless (    $in =~ / ^ =for [ ]+ apidoc /x
                                      # =head1 lines only have effect in C files
                     || ($file_is_C && $in =~ /^=head1/));

        # Here, the line introduces a portion of the input that we care about.
        # Either it is for an API element, or heading text which we expect
        # will be used for elements later in the file

        my ($text, $element_name, $flags, $ret_type, $is_item, $proto_in_file);
        my (@args, @items);

        # If the line starts a new section ...
        if ($in=~ /^ = (?: for [ ]+ apidoc_section | head1 ) [ ]+ (.*) /x) {

            $section = $1;
        }
        elsif ($in=~ /^ =for [ ]+ apidoc \B /x) {   # Otherwise better be a
                                                    # plain apidoc line
            die "Unkown apidoc-type line '$in'" unless $in=~ /^=for apidoc_item/;
            die "apidoc_item doesn't immediately follow an apidoc entry: '$in'";
        }
        else {  # Plain apidoc

            ($element_name, $flags, $ret_type, $is_item, $proto_in_file, @args)
                                                = check_api_doc_line($file, $in);
            # Do some checking
            # If the entry is also in embed.fnc, it should be defined
            # completely there, but not here
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

            die "'u' flag must also have 'm' flag' for $element_name"
                                            if $flags =~ /u/ && $flags !~ /m/;
            warn ("'$element_name' not \\w+ in '$proto_in_file' in $file")
                        if $flags !~ /N/ && $element_name !~ / ^ [_[:alpha:]] \w* $ /x;

            if (exists $seen{$element_name} && $flags !~ /h/) {
                die ("'$element_name' in $file was already documented in $seen{$element_name}");
            }
            else {
                $seen{$element_name} = $file;
            }
        }

        # Here we have processed the initial line in the heading text or API
        # element, and have saved the important information from it into the
        # corresponding variables.  Now accumulate the text that applies to it
        # up to a terminating line, which is one of:
        # 1) =cut
        # 2) =head (in a C file only =head1)
        # 3) an end comment line in a C file: m:^\s*\*/:
        # 4) =for apidoc... (except apidoc_item lines)
        $text = "";
        my $head_ender_num = ($file_is_C) ? 1 : "";
        while (defined($in = $get_next_line->())) {

            last if $in =~ /^=cut/x;
            last if $in =~ /^=head$head_ender_num/;

            if ($file_is_C && $in =~ m: ^ \s* \* / $ :x) {

                # End of comment line in C files is a fall-back terminator,
                # but warn only if there actually is some accumulated text
                warn "=cut missing? $file:$line_num:$in" if $text =~ /\S/;
                last;
            }

            if ($in !~ / ^ =for [ ]+ apidoc /x) {
                $text .= $in;
                next;
            }

            # Here, the line is an apidoc line.  All but apidoc_item terminate
            # the text being accumulated.
            last if $in =~ / ^ =for [ ]+ apidoc_section /x;

            my ($item_name, $item_flags, $item_ret_type, $is_item,
                            undef, @item_args) = check_api_doc_line($file, $in);
            last unless $is_item;

            # Here, is an apidoc_item_line; They can only come within apidoc
            # paragraphs.
            die "Unexpected api_doc_item line '$in'" unless $element_name;

            # We accept blank lines between these, but nothing else;
            die "apidoc_item lines must immediately follow apidoc lines"
                                                            if $text =~ /\S/;

            # Use the base entry flags if none for this item; otherwise add in
            # any non-display base entry flags.
            if ($item_flags) {
                $item_flags .= $flags =~ s/[$display_flags]//rg;
            }
            else {
                $item_flags = $flags;
            }
            $item_ret_type = $ret_type unless $item_ret_type;
            @item_args = @args unless @item_args;
            push @items, { name     => $item_name,
                           ret_type => $item_ret_type,
                           flags    => $item_flags,
                           args     => [ @item_args ],
                         };

            # This line shows that this element is documented.
            delete $funcflags{$item_name};
        }

        # Here, are done accumulating the text for this item.  Trim it
        $text =~ s/ ^ \s* //x;
        $text =~ s/ \s* $ //x;
        $text .= "\n" if $text ne "";

        # And treat all-spaces as nothing at all
        undef $text unless $text =~ /\S/;

        if ($element_name) {

            # Here, we have accumulated into $text, the pod for $element_name
            my $where = $flags =~ /A/ ? 'api' : 'guts';

            $section = "Functions in file $file" unless defined $section;
            die "No =for apidoc_section nor =head1 in $file for '$element_name'\n"
                                                    unless defined $section;
            if (exists $docs{$where}{$section}{$element_name}) {
                warn "$0: duplicate API entry for '$element_name' in"
                    . " $where/$section\n";
                next;
            }

            # Override the text with just a link if the flags call for that
            my $is_link_only = ($flags =~ /h/);
            if ($is_link_only) {
                if ($file_is_C) {
                    die "Can't currently handle link with items to it" if @items;
                    redo;    # Don't put anything if C source
                }

                # Here, is an 'h' flag in pod.  We add a reference to the pod (and
                # nothing else) to perlapi/intern.  (It would be better to add a
                # reference to the correct =item,=header, but something that makes
                # it harder is that it that might be a duplicate, like '=item *';
                # so that is a future enhancement XXX.  Another complication is
                # there might be more than one deserving candidates.)
                my $podname = $file =~ s!.*/!!r;    # Rmv directory name(s)
                $podname =~ s/\.pod//;
                $text = "Described in L<$podname>.\n";

                # Don't output a usage example for linked to documentation if
                # it is trivial (has no arguments) and we aren't to add a
                # semicolon
                $flags .= 'U' if $flags =~ /n/ && $flags !~ /[Us]/;

                # Keep track of all the pod files that we refer to.
                push $described_elsewhere{$podname}->@*, $podname;
            }

            $docs{$where}{$section}{$element_name}{flags} = $flags;
            $docs{$where}{$section}{$element_name}{pod} = $text;
            $docs{$where}{$section}{$element_name}{file} = $file;
            $docs{$where}{$section}{$element_name}{ret_type} = $ret_type;
            push $docs{$where}{$section}{$element_name}{args}->@*, @args;
            push $docs{$where}{$section}{$element_name}{items}->@*, @items;
        }
        elsif ($text) {
            $valid_sections{$section}{header} = "" unless
                                    defined $valid_sections{$section}{header};
            $valid_sections{$section}{header} .= "\n$text";
        }

        # We already have the first line of what's to come in $in
        redo;

    } # End of loop through input
}

my %configs;
my @has_defs;
my @has_r_defs;     # Reentrant symbols
my @include_defs;
sub parse_config_h {
    use re '/aa';   # Everthing is ASCII in this file

    # Process config.h
    open my $fh, '<', 'config.h' or die "Can't open config.h: $!";
    while (<$fh>) {

        # Look for lines like /* FOO_BAR:
        # By convention all config.h descriptions begin like that
        if (m[ ^ /\* [ ] ( [[:alpha:]] \w+ ) : \s* $ ]ax) {
            my $name = $1;

            # Here we are starting the description for $name in config.h.  We
            # accumulate the entire description for it into @description.
            # Flowing text from one input line to another is appended into the
            # same array element to make a single flowing line element, but
            # verbatim lines are kept as separate elements in @description.
            # This will facilitate later doing pattern matching without regard
            # to line boundaries on non-verbatim text.

            die "Multiple config.h entries for '$name'"
                                        if defined $configs{$name}{description};

            # Get first line of description
            $_ = <$fh>;

            # Each line in the description begins with blanks followed by '/*'
            # and some spaces.
            die "Unexpected config.h initial line for $name: '$_'"
                                            unless s/ ^ ( \s* \* \s* ) //x;
            my $initial_text = $1;

            # Initialize the description with this first line (after having
            # stripped the prefix text)
            my @description = $_;

            # The first line is used as a template for how much indentation
            # each normal succeeding line has.  Lines indented further
            # will be considered as intended to be verbatim.  But, empty lines
            # likely won't have trailing blanks, so just strip the whole thing
            # for them.
            my $strip_initial_qr = qr!   \s* \* \s* $
                                    | \Q$initial_text\E
                                    !x;
            $configs{$name}{verbatim} = 0;

            # Read in the remainder of the description
            while (<$fh>) {
                last if s| ^ \s* \* / ||x;  # A '*/' ends it

                die "Unexpected config.h description line for $name: '$_'"
                                                unless s/$strip_initial_qr//;

                # Fix up the few flawed lines in config.h wherein a new
                # sentence begins with a tab (and maybe a space after that).
                # Although none of them currently do, let it recognize
                # something like
                #
                #   "... text").  The next sentence ...
                #
                s/ ( \w "? \)? \. ) \t \s* ( [[:alpha:]] ) /$1  $2/xg;

                # If this line has extra indentation or looks to have columns,
                # it should be treated as verbatim.  Columns are indicated by
                # use of interior: tabs, 3 spaces in a row, or even 2 spaces
                # not preceded by punctuation.
                if ($_ !~ m/  ^ \s
                              | \S (?:                    \t
                                    |                     \s{3}
                                    |  (*nlb:[[:punct:]]) \s{2}
                                   )
                           /x)
                {
                    # But here, is not a verbatim line.  Add an empty line if
                    # this is the first non-verbatim after a run of verbatims
                    if ($description[-1] =~ /^\s/) {
                        push @description, "\n", $_;
                    }
                    else {  # Otherwise, append this flowing line to the
                            # current flowing line
                        $description[-1] .= $_;
                    }
                }
                else {
                    $configs{$name}{verbatim} = 1;

                    # The first verbatim line in a run of them is separated by an
                    # empty line from the flowing lines above it
                    push @description, "\n" if $description[-1] =~ /^\S/;

                    $_ = Text::Tabs::expand($_);

                    # Only a single space so less likely to wrap
                    s/ ^ \s* / /x;

                    push @description, $_;
                }
            }

            push $configs{$name}{description}->@*, @description

        }   # Not a description; see if it is a macro definition.
        elsif (m! ^
                  (?: / \* )?                   # Optional commented-out
                                                # indication
                      \# \s* define \s+ ( \w+ ) # $1 is the name
                  (   \s* )                     # $2 indicates if args or not
                  (   .*? )                     # $3 is any definition
                  (?: / \s* \* \* / )?          # Optional trailing /**/ or / **/
                  $
                !x)
        {
            my $name = $1;

            # There can be multiple definitions for a name.  We want to know
            # if any of them has arguments, and if any has a body.
            $configs{$name}{has_args} //= $2 eq "";
            $configs{$name}{has_args} ||= $2 eq "";
            $configs{$name}{has_defn} //= $3 ne "";
            $configs{$name}{has_defn} ||= $3 ne "";
        }
    }

    # We now have stored the description and information about every #define
    # in the file.  The description is in a form convenient to operate on to
    # convert to pod.  Do that now.
    foreach my $name (keys %configs) {
        next unless defined $configs{$name}{description};

        # All adjacent non-verbatim lines of the description are appended
        # together in a single element in the array.  This allows the patterns
        # to work across input line boundaries.

        my $pod = "";
        while (defined ($_ = shift $configs{$name}{description}->@*)) {
            chomp;

            if (/ ^ \S /x) {  # Don't edit verbatim lines

                # Enclose known file/path names not already so enclosed
                # with <...>.  (Some entries in config.h are already
                # '<path/to/file>')
                my $file_name_qr = qr! [ \w / ]+ \.
                                    (?: c | h | xs | p [lm] | pmc | PL
                                        | sh | SH | exe ) \b
                                    !xx;
                my $path_name_qr = qr! (?: / \w+ )+ !x;
                for my $re ($file_name_qr, $path_name_qr) {
                    s! (*nlb:[ < \w / ]) ( $re ) !<$1>!gxx;
                }

                # Enclose <... file/path names with F<...> (but no double
                # angle brackets)
                for my $re ($file_name_qr, $path_name_qr) {
                    s! < ( $re ) > !F<$1>!gxx;
                }

                # Explain metaconfig units
                s/ ( \w+ \. U \b ) /$1 (part of metaconfig)/gx;

                # Convert "See foo" to "See C<L</foo>>" if foo is described in
                # this file.  Also create a link to the known file INSTALL.
                # And, to be more general, handle "See also foo and bar", and
                # "See also foo, bar, and baz"
                while (m/ \b [Ss]ee \s+
                         (?: also \s+ )?    ( \w+ )
                         (?: ,  \s+         ( \w+ ) )?
                         (?: ,? \s+ and \s+ ( \w+ ) )? /xg) {
                    my @links = $1;
                    push @links, $2 if defined $2;
                    push @links, $3 if defined $3;
                    foreach my $link (@links) {
                        if ($link eq 'INSTALL') {
                            s/ \b INSTALL \b /C<L<INSTALL>>/xg;
                        }
                        elsif (grep { $link =~ / \b $_ \b /x } keys %configs) {
                            s| \b $link \b |C<L</$link>>|xg;
                            $configs{$link}{linked} = 1;
                            $configs{$name}{linked} = 1;
                        }
                    }
                }

                # Enclose what we think are symbols with C<...>.
                no warnings 'experimental::vlb';
                s/ (*nlb:<)
                   (
                        # Any word followed immediately with parens or
                        # brackets
                        \b \w+ (?: \( [^)]* \)    # parameter list
                                 | \[ [^]]* \]    # or array reference
                               )
                    | (*plb: ^ | \s ) -D \w+    # Also -Dsymbols.
                    | \b (?: struct | union ) \s \w+

                        # Words that contain underscores (which are
                        # definitely not text) or three uppercase letters in
                        # a row.  Length two ones, like IV, aren't enclosed,
                        # because they often don't look as nice.
                    | \b \w* (?: _ | [[:upper:]]{3,} ) \w* \b
                   )
                    (*nla:>)
                 /C<$1>/xg;

                # These include foo when the name is HAS_foo.  This is a
                # heuristic which works in most cases.
                if ($name =~ / ^ HAS_ (.*) /x) {
                    my $symbol = lc $1;

                    # Don't include path components, nor things already in
                    # <>, or with trailing '(', '['
                    s! \b (*nlb:[/<]) $symbol (*nla:[[/>(]) \b !C<$symbol>!xg;
                }
            }

            $pod .=  "$_\n";
        }
        delete $configs{$name}{description};

        $configs{$name}{pod} = $pod;
    }

    # Now have converted the description to pod.  We also now have enough
    # information that we can do cross checking to find definitions without
    # corresponding pod, and see if they are mentioned in some description;
    # otherwise they aren't documented.
  NAME:
    foreach my $name (keys %configs) {

        # A definition without pod
        if (! defined $configs{$name}{pod}) {

            # Leading/trailing underscore means internal to config.h, e.g.,
            # _GNU_SOURCE
            next if $name =~ / ^ _ /x;
            next if $name =~ / _ $ /x;

            # MiXeD case names are internal to config.h; the first 4
            # characters are sufficient to determine this
            next if $name =~ / ^ [[:upper:]] [[:lower:]]
                                 [[:upper:]] [[:lower:]]
                            /x;

            # Here, not internal to config.h.  Look to see if this symbol is
            # mentioned in the pod of some other.  If so, assume it is
            # documented.
            foreach my $check_name (keys %configs) {
                my $this_element = $configs{$check_name};
                my $this_pod = $this_element->{pod};
                if (defined $this_pod) {
                    next NAME if $this_pod =~ / \b $name \b /x;
                }
            }

            warn "$name has no documentation\n";
            $missing_macros{$name} = 'config.h';

            next;
        }

        my $has_defn = $configs{$name}{has_defn};
        my $has_args = $configs{$name}{has_args};

        # Check if any section already has an entry for this element.
        # If so, it better be a placeholder, in which case we replace it
        # with this entry.
        foreach my $section (keys $docs{'api'}->%*) {
            if (exists $docs{'api'}{$section}{$name}) {
                my $was = $docs{'api'}{$section}{$name}->{pod};
                $was = "" unless $was;
                chomp $was;
                if ($was ne "" && $was !~ m/$link_text/) {
                    die "Multiple descriptions for $name\n"
                        . "$section contained '$was'";
                }
                $docs{'api'}{$section}{$name}->{pod} = $configs{$name}{pod};
                $configs{$name}{section} = $section;
                last;
            }
        }

        my $handled = 0;    # Haven't handled this yet

        if (defined $configs{$name}{'section'}) {
            # This has been taken care of elsewhere.
            $handled = 1;
        }
        else {
            if ($has_defn && ! $has_args) {
                $configs{$name}{args} = 1;
            }

            # Symbols of the form I_FOO are for #include files.  They have
            # special usage information
            if ($name =~ / ^ I_ ( .* ) /x) {
                my $file = lc $1 . '.h';
                $configs{$name}{usage} = <<~"EOT";
                    #ifdef $name
                        #include <$file>
                    #endif
                    EOT
            }

            # Compute what section this variable should go into.  This
            # heuristic was determined by manually inspecting the current
            # things in config.h, and should be adjusted as necessary as
            # deficiencies are found.
            #
            # This is the default section for macros with a definiton but
            # no arguments, meaning it is replaced unconditionally
            #
            my $sb = qr/ _ | \b /x; # segment boundary
            my $dash_or_spaces = qr/ - | \s+ /x;
            my $pod = $configs{$name}{pod};
            if ($name =~ / ^ USE_ /x) {
                $configs{$name}{'section'} = 'Site configuration';
            }
            elsif ($name =~ / SLEEP | (*nlb:SYS_) TIME | TZ | $sb TM $sb /x)
            {
                $configs{$name}{'section'} = 'Time';
            }
            elsif ($name =~ /  DOUBLE | FLOAT | LONGDBL | LDBL | ^ NV
                            | $sb CASTFLAGS $sb
                            | QUADMATH
                            | $sb (?: IS )? NAN
                            | $sb (?: IS )? FINITE
                            /x)
            {
                $configs{$name}{'section'} =
                                    'Floating point configuration values';
            }
            elsif ($name =~ / (?: POS | OFF | DIR ) 64 /x) {
                $configs{$name}{'section'} = 'Filesystem configuration values';
            }
            elsif (   $name =~ / $sb (?: BUILTIN | CPP ) $sb | ^ CPP /x
                   || $configs{$name}{pod} =~ m/ \b align /x)
            {
                $configs{$name}{'section'} = 'Compiler and Preprocessor information';
            }
            elsif ($name =~ / ^ [IU] [ \d V ]
                            | ^ INT | SHORT | LONG | QUAD | 64 | 32 /xx)
            {
                $configs{$name}{'section'} = 'Integer configuration values';
            }
            elsif ($name =~ / $sb t $sb /x) {
                $configs{$name}{'section'} = 'Typedef names';
            }
            elsif (   $name =~ / ^ PERL_ ( PRI | SCN ) | $sb FORMAT $sb /x
                    && $configs{$name}{pod} =~ m/ \b format \b /ix)
            {
                $configs{$name}{'section'} = 'Formats';
            }
            elsif ($name =~ / BACKTRACE /x) {
                $configs{$name}{'section'} = 'Display and Dump functions';
            }
            elsif ($name =~ / ALLOC $sb /x) {
                $configs{$name}{'section'} = 'Memory Management';
            }
            elsif (   $name =~ /   STDIO | FCNTL | EOF | FFLUSH
                                | $sb FILE $sb
                                | $sb DIR $sb
                                | $sb LSEEK
                                | $sb INO $sb
                                | $sb OPEN
                                | $sb CLOSE
                                | ^ DIR
                                | ^ INO $sb
                                | DIR $
                                | FILENAMES
                                /x
                    || $configs{$name}{pod} =~ m!  I/O | stdio
                                                | file \s+ descriptor
                                                | file \s* system
                                                | statfs
                                                !x)
            {
                $configs{$name}{'section'} = 'Filesystem configuration values';
            }
            elsif ($name =~ / ^ SIG | SIGINFO | signal /ix) {
                $configs{$name}{'section'} = 'Signals';
            }
            elsif ($name =~ / $sb ( PROTO (?: TYPE)? S? ) $sb /x) {
                $configs{$name}{'section'} = 'Prototype information';
            }
            elsif (   $name =~ / ^ LOC_ /x
                    || $configs{$name}{pod} =~ /full path/i)
            {
                $configs{$name}{'section'} = 'Paths to system commands';
            }
            elsif ($name =~ / $sb LC_ | LOCALE | langinfo /xi) {
                $configs{$name}{'section'} = 'Locales';
            }
            elsif ($configs{$name}{pod} =~ /  GCC | C99 | C\+\+ /xi) {
                $configs{$name}{'section'} = 'Compiler and Preprocessor information';
            }
            elsif ($name =~ / PASSW (OR)? D | ^ PW | ( PW | GR ) ENT /x)
            {
                $configs{$name}{'section'} = 'Password and Group access';
            }
            elsif ($name =~ /  SOCKET | $sb SOCK /x) {
                $configs{$name}{'section'} = 'Sockets configuration values';
            }
            elsif (   $name =~ / THREAD | MULTIPLICITY /x
                    || $configs{$name}{pod} =~ m/ \b pthread /ix)
            {
                $configs{$name}{'section'} = 'Concurrency';
            }
            elsif ($name =~ /  PERL | ^ PRIV | SITE | ARCH | BIN
                                | VENDOR | ^ USE
                            /x)
            {
                $configs{$name}{'section'} = 'Site configuration';
            }
            elsif (   $pod =~ / \b floating $dash_or_spaces point \b /ix
                    || $pod =~ / \b (double | single) $dash_or_spaces precision \b /ix
                    || $pod =~ / \b doubles \b /ix
                    || $pod =~ / \b (?: a | the | long ) \s+ (?: double | NV ) \b /ix)
            {
                $configs{$name}{'section'} =
                                    'Floating point configuration values';
            }
            else {
                # Above are the specific sections.  The rest go into a
                # grab-bag of general configuration values.  However, we put
                # two classes of them into lists of their names, without their
                # descriptions, when we think that the description doesn't add
                # any real value.  One list contains the #include variables:
                # the description is basically boiler plate for each of these.
                # The other list contains the very many things that are of the
                # form HAS_foo, and \bfoo\b is contained in its description,
                # and there is no verbatim text in the pod or links to/from it
                # (which would add value).  That means that it is likely the
                # intent of the variable can be gleaned from just its name,
                # and unlikely the description adds signficant value, so just
                # listing them suffices.  Giving their descriptions would
                # expand this pod significantly with little added value.
                if (   ! $has_defn
                    && ! $configs{$name}{verbatim}
                    && ! $configs{$name}{linked})
                {
                    if ($name =~ / ^ I_ ( .* ) /x) {
                        push @include_defs, $name;
                        next;
                    }
                    elsif ($name =~ / ^ HAS_ ( .* ) /x) {
                        my $canonical_name = $1;
                        $canonical_name =~ s/_//g;

                        my $canonical_pod = $configs{$name}{pod};
                        $canonical_pod =~ s/_//g;

                        if ($canonical_pod =~ / \b $canonical_name \b /xi) {
                            if ($name =~ / $sb R $sb /x) {
                                push @has_r_defs, $name;
                            }
                            else {
                                push @has_defs, $name;
                            }
                            next;
                        }
                    }
                }

                $configs{$name}{'section'} = 'General Configuration';
            }

            my $section = $configs{$name}{'section'};
            #die "Internal error: '$section' not in \%valid_sections"
                            #unless grep { $_ eq $section } keys %valid_sections;
            my $flags = 'AdmnT';
            $flags .= 'U' unless defined $configs{$name}{usage};
            $docs{'api'}{$section}{$name}{flags} = $flags;
            $docs{'api'}{$section}{$name}{pod} = $configs{$name}{pod};
            $docs{'api'}{$section}{$name}{ret_type} = "";
            $docs{'api'}{$section}{$name}{file} = 'config.h';
            $docs{'api'}{$section}{$name}{usage}
                = $configs{$name}{usage} if defined $configs{$name}{usage};
            push $docs{'api'}{$section}{$name}{args}->@*, ();
            push $docs{'api'}{$section}{$name}{items}->@*, ();
        }
    }
}

sub docout ($$$) { # output the docs for one function
    my($fh, $element_name, $docref) = @_;

    my $flags = $docref->{flags};
    my $pod = $docref->{pod} // "";
    my $ret_type = $docref->{ret_type};
    my $file = $docref->{file};
    my @args = $docref->{args}->@*;
    my @items = $docref->{items}->@*;

    $element_name =~ s/\s*$//;

    warn("Empty pod for $element_name (from $file)") unless $pod =~ /\S/;

    if ($flags =~ /D/) {
        my $function = $flags =~ /n/ ? 'definition' : 'function';
        $pod = <<~"EOT";
            C<B<DEPRECATED!>>  It is planned to remove this $function from a
            future release of Perl.  Do not use it for new code; remove it from
            existing code.

            $pod
            EOT
    }
    elsif ($flags =~ /x/) {
        $pod = <<~"EOT";
            NOTE: this function is B<experimental> and may change or be
            removed without notice.

            $pod
            EOT
    }

    # Is Perl_, but no #define foo # Perl_foo
    my $p = (($flags =~ /p/ && $flags =~ /o/ && $flags !~ /M/)
          || ($flags =~ /f/ && $flags !~ /T/));  # Can't handle threaded varargs

    $pod .= "\nNOTE: the C<perl_> form of this function is B<deprecated>.\n"
         if $flags =~ /O/;
    if ($p) {
        $pod .= "\nNOTE: this function must be explicitly called as C<Perl_$element_name>\n";
        $pod .= "with an C<aTHX_> parameter.\n" if $flags !~ /T/;
    }

    for my $item ($element_name, @items) {
        print $fh "\n=item C<$item>\n";

        # If we're printing only a link to an element, this isn't the major entry,
        # so no X<> here.
        print $fh "X<$element_name>\n" unless $flags =~ /h/;
    }

    chomp $pod;     # Make sure prints pod with a single trailing \n
    print $fh "\n$pod\n";

    if ($flags =~ /U/) { # no usage
        warn("U and s flags are incompatible") if $flags =~ /s/;
        # nothing
    } else {
        if (defined $docref->{usage}) {     # An override of the usage section
            print $fh "\n", ($docref->{usage} =~ s/^/ /mrg), "\n";
        }
        elsif ($flags =~ /n/) { # no args
            warn("$file: $element_name: n flag without m") unless $flags =~ /m/;
            warn("$file: $element_name: n flag but apparently has args") if @args;
            print $fh "\n\t$ret_type\t$element_name";
        } else { # full usage
            my $n            = "Perl_"x$p . $element_name;
            my $large_ret    = length $ret_type > 7;
            my $indent_size  = 7+8 # nroff: 7 under =head + 8 under =item
                            +8+($large_ret ? 1 + length $ret_type : 8)
                            +length($n) + 1;
            my $indent;
            print $fh "\n\t$ret_type" . ($large_ret ? ' ' : "\t") . "$n(";
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
        print $fh "\n";
    }
    print $fh "\n=for hackers\nFound in file $file\n";
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

    print $fh $header, "\n";

    for my $section_name (sort sort_helper keys %$dochash) {
        my $section_info = $dochash->{$section_name};
        next unless keys %$section_info;     # Skip empty
        print $fh "\n=head1 $section_name\n";

        print $fh "\n", $valid_sections{$section_name}{header}, "\n"
                            if $podname eq 'perlapi'
                            && defined $valid_sections{$section_name}{header};

        # Output any heading-level documentation and delete so won't get in
        # the way later
        if (exists $section_info->{""}) {
            print $fh "\n", $section_info->{""}, "\n";
            delete $section_info->{""};
        }
        next unless keys %$section_info;     # Skip empty
        print $fh "\n=over 8\n";

        for my $function_name (sort sort_helper keys %$section_info) {
            docout($fh, $function_name, $section_info->{$function_name});
        }
        print $fh "\n=back\n";

        print $fh "\n", $valid_sections{$section_name}{footer}, "\n"
                            if defined $valid_sections{$section_name}{footer};
    }

    if (@$missing) {
        print $fh "\n=head1 Undocumented functions\n";
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
        print $fh "\n=over\n";

        for my $missing (sort sort_helper @$missing) {
            print $fh "\n=item C<$missing>\nX<$missing>\n";
        }
        print $fh "\n=back\n";
    }

    print $fh "\n$footer\n=cut\n";

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
    autodoc(\*F,$file);
    close F or die "Error closing $file: $!\n";
}
close $fh or die "Error whilst reading MANIFEST: $!";

parse_config_h();

for (sort keys %funcflags) {
    next unless $funcflags{$_}{flags} =~ /d/;
    next if $funcflags{$_}{flags} =~ /h/;
    warn "no docs for $_\n"
}

foreach (sort keys %missing) {
    warn "Function '$_', documented in $missing{$_}, not listed in embed.fnc";
}

# List of funcs in the public API that aren't also marked as core-only,
# experimental nor deprecated.
my @missing_api = grep $funcflags{$_}{flags} =~ /A/
                    && $funcflags{$_}{flags} !~ /[xD]/
                    && !$docs{api}{$_}, keys %funcflags;
push @missing_api, keys %missing_macros;

my $other_places = join ", ", map { "L<$_>" } sort sort_helper qw( perlclib perlxs),
                                                               keys %described_elsewhere;

# The S< > makes things less densely packed, hence more readable
my $has_defs_text .= join ",S< > ", map { "C<$_>" } sort sort_helper @has_defs;
my $has_r_defs_text .= join ",S< > ", map { "C<$_>" } sort sort_helper @has_r_defs;
$valid_sections{'General Configuration'}{footer} =~ s/__HAS_LIST__/$has_defs_text/;
$valid_sections{'General Configuration'}{footer} =~ s/__HAS_R_LIST__/$has_r_defs_text/;

my $include_defs_text .= join ",S< > ", map { "C<$_>" } sort sort_helper @include_defs;
$valid_sections{'General Configuration'}{footer} =~ s/__INCLUDE_LIST__/$include_defs_text/;

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
_EOB_
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
