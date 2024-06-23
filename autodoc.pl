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
#    plus all the core .c, .h, and .pod files listed in MANIFEST
#    plus %extra_input_pods

my %extra_input_pods = ( 'dist/ExtUtils-ParseXS/lib/perlxs.pod' => 1 );

# Has an optional arg, which is the directory to chdir to before reading
# MANIFEST and the files
#
# This script is invoked as part of 'make all'
#
# The generated pod consists of sections of related elements, functions,
# macros, and variables.  The keys of %valid_sections give the current legal
# ones.  Just add a new key to add a section.
#
# Throughout the files read by this script are lines like
#
# =for apidoc_section Section Name
# =for apidoc_section $section_name_variable
#
# "Section Name" (after having been stripped of leading space) must be one of
# the legal section names, or an error is thrown.  $section_name_variable must
# be one of the legal section name variables defined below; these expand to
# legal section names.  This form is used so that minor wording changes in
# these titles can be confined to this file.  All the names of the variables
# end in '_scn'; this suffix is optional in the apidoc_section lines.
#
# All API elements defined between this line and the next 'apidoc_section'
# line will go into the section "Section Name" (or $section_name_variable),
# sorted by dictionary order within it.  perlintern and perlapi are parallel
# documents, each potentially with a section "Section Name".  Each element is
# marked as to which document it goes into.  If there are none for a
# particular section in perlapi, that section is omitted.
#
# Also, in .[ch] files, there may be
#
# =head1 Section Name
#
# lines in comments.  These are also used by this program to switch to section
# "Section Name".  The difference is that if there are any lines after the
# =head1, inside the same comment, and before any =for apidoc-ish lines, they
# are used as a heading for section "Section Name" (in both perlintern and
# perlapi).  This includes any =head[2-5].  If more than one '=head1 Section
# Name' line has content, they appear in the generated pod in an undefined
# order.  Note that you can't use a $section_name_variable in =head1 lines
#
# The next =head1, =for apidoc_section, or file end terminates what goes into
# the current section
#
# The %valid_sections hash below also can have header content, which will
# appear before any =head1 content.  The hash can also have footer content
# content, which will appear at the end of the section, after all the
# elements.
#
# The lines that define the actual functions, etc are documented in embed.fnc,
# because they have flags which must be kept in sync with that file.

use strict;
use warnings;

my $config_h = 'config.h';
if (@ARGV >= 2 && $ARGV[0] eq "-c") {
    shift;
    $config_h = shift;
}

my $nroff_min_indent = 4;   # for non-heading lines
# 80 column terminal - 2 for pager using 2 columns for itself;
my $max_width = 80 - 2 - $nroff_min_indent;
my $standard_indent = 4;  # Any additional indentations

# In the usage (signature) section of entries, how many spaces should separate
# the return type from the name of the function.
my $usage_ret_name_sep_len = 2;

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
my %elements;
my %deferreds;  # Elements whose usage hasn't been found by the time they are
                # parsed
my %missing;
my %missing_macros;

my $link_text = "Described in";

my $description_indent = 4;
my $usage_indent = 3;   # + initial blank yields 4 total

my $AV_scn = 'AV Handling';
my $callback_scn = 'Callback Functions';
my $casting_scn = 'Casting';
my $casing_scn = 'Character case changing';
my $classification_scn = 'Character classification';
my $names_scn = 'Character names';
my $scope_scn = 'Compile-time scope hooks';
my $compiler_scn = 'Compiler and Preprocessor information';
my $directives_scn = 'Compiler directives';
my $concurrency_scn = 'Concurrency';
my $COP_scn = 'COPs and Hint Hashes';
my $CV_scn = 'CV Handling';
my $custom_scn = 'Custom Operators';
my $debugging_scn = 'Debugging';
my $display_scn = 'Display functions';
my $embedding_scn = 'Embedding, Threads, and Interpreter Cloning';
my $errno_scn = 'Errno';
my $exceptions_scn = 'Exception Handling (simple) Macros';
my $filesystem_scn = 'Filesystem configuration values';
my $filters_scn = 'Source Filters';
my $floating_scn = 'Floating point';
my $genconfig_scn = 'General Configuration';
my $globals_scn = 'Global Variables';
my $GV_scn = 'GV Handling and Stashes';
my $hook_scn = 'Hook manipulation';
my $HV_scn = 'HV Handling';
my $io_scn = 'Input/Output';
my $io_formats_scn = 'I/O Formats';
my $integer_scn = 'Integer';
my $lexer_scn = 'Lexer interface';
my $locale_scn = 'Locales';
my $magic_scn = 'Magic';
my $memory_scn = 'Memory Management';
my $MRO_scn = 'MRO';
my $multicall_scn = 'Multicall Functions';
my $numeric_scn = 'Numeric Functions';
my $rpp_scn = 'Reference-counted stack manipulation';

# Now combined, as unclear which functions go where, but separate names kept
# to avoid 1) other code changes; 2) in case it seems better to split again
my $optrees_scn = 'Optrees';
my $optree_construction_scn = $optrees_scn; # Was 'Optree construction';
my $optree_manipulation_scn = $optrees_scn; # Was 'Optree Manipulation Functions'
my $pack_scn = 'Pack and Unpack';
my $pad_scn = 'Pad Data Structures';
my $password_scn = 'Password and Group access';
my $reports_scn = 'Reports and Formats';
my $paths_scn = 'Paths to system commands';
my $prototypes_scn = 'Prototype information';
my $regexp_scn = 'REGEXP Functions';
my $signals_scn = 'Signals';
my $site_scn = 'Site configuration';
my $sockets_scn = 'Sockets configuration values';
my $stack_scn = 'Stack Manipulation Macros';
my $string_scn = 'String Handling';
my $SV_flags_scn = 'SV Flags';
my $SV_scn = 'SV Handling';
my $tainting_scn = 'Tainting';
my $time_scn = 'Time';
my $typedefs_scn = 'Typedef names';
my $unicode_scn = 'Unicode Support';
my $utility_scn = 'Utility Functions';
my $versioning_scn = 'Versioning';
my $warning_scn = 'Warning and Dieing';
my $XS_scn = 'XS';

# Kept separate at end
my $undocumented_scn = 'Undocumented elements';

my %valid_sections = (
    $AV_scn => {},
    $callback_scn => {},
    $casting_scn => {},
    $casing_scn => {},
    $classification_scn => {},
    $scope_scn => {},
    $compiler_scn => {},
    $directives_scn => {},
    $concurrency_scn => {},
    $COP_scn => {},
    $CV_scn => {
        header => <<~'EOT',
            This section documents functions to manipulate CVs which are
            code-values, meaning subroutines.  For more information, see
            L<perlguts>.
            EOT
    },

    $custom_scn => {},
    $debugging_scn => {},
    $display_scn => {},
    $embedding_scn => {},
    $errno_scn => {},
    $exceptions_scn => {},
    $filesystem_scn => {
        header => <<~'EOT',
            Also see L</List of capability HAS_foo symbols>.
            EOT
        },
    $filters_scn => {},
    $floating_scn => {
        header => <<~'EOT',
            Also L</List of capability HAS_foo symbols> lists capabilities
            that arent in this section.  For example C<HAS_ASINH>, for the
            hyperbolic sine function.
            EOT
        },
    $genconfig_scn => {
        header => <<~'EOT',
            This section contains configuration information not otherwise
            found in the more specialized sections of this document.  At the
            end is a list of C<#defines> whose name should be enough to tell
            you what they do, and a list of #defines which tell you if you
            need to C<#include> files to get the corresponding functionality.
            EOT

        footer => <<~EOT,

            =head2 List of capability C<HAS_I<foo>> symbols

            This is a list of those symbols that dont appear elsewhere in ths
            document that indicate if the current platform has a certain
            capability.  Their names all begin with C<HAS_>.  Only those
            symbols whose capability is directly derived from the name are
            listed here.  All others have their meaning expanded out elsewhere
            in this document.  This (relatively) compact list is because we
            think that the expansion would add little or no value and take up
            a lot of space (because there are so many).  If you think certain
            ones should be expanded, send email to
            L<perl5-porters\@perl.org|mailto:perl5-porters\@perl.org>.

            Each symbol here will be C<#define>d if and only if the platform
            has the capability.  If you need more detail, see the
            corresponding entry in F<config.h>.  For convenience, the list is
            split so that the ones that indicate there is a reentrant version
            of a capability are listed separately

            __HAS_LIST__

            And, the reentrant capabilities:

            __HAS_R_LIST__

            Example usage:

            =over $standard_indent

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

            =over $standard_indent

             #ifdef I_WCHAR
               #include <wchar.h>
             #endif

            =back
            EOT
      },
    $globals_scn => {},
    $GV_scn => {},
    $hook_scn => {},
    $HV_scn => {},
    $io_scn => {},
    $io_formats_scn => {
        header => <<~'EOT',
            These are used for formatting the corresponding type For example,
            instead of saying

             Perl_newSVpvf(pTHX_ "Create an SV with a %d in it\n", iv);

            use

             Perl_newSVpvf(pTHX_ "Create an SV with a " IVdf " in it\n", iv);

            This keeps you from having to know if, say an IV, needs to be
            printed as C<%d>, C<%ld>, or something else.
            EOT
      },
    $integer_scn => {},
    $lexer_scn => {},
    $locale_scn => {},
    $magic_scn => {},
    $memory_scn => {},
    $MRO_scn => {},
    $multicall_scn => {},
    $numeric_scn => {},
    $optrees_scn => {},
    $optree_construction_scn => {},
    $optree_manipulation_scn => {},
    $pack_scn => {},
    $pad_scn => {},
    $password_scn => {},
    $paths_scn => {},
    $prototypes_scn => {},
    $regexp_scn => {},
    $reports_scn => {
        header => <<~"EOT",
            These are used in the simple report generation feature of Perl.
            See L<perlform>.
            EOT
      },
    $rpp_scn => {
        header => <<~'EOT',
            Functions for pushing and pulling items on the stack when the
            stack is reference counted. They are intended as replacements
            for the old PUSHs, POPi, EXTEND etc pp macros within pp
            functions.
            EOT
      },
    $signals_scn => {},
    $site_scn => {
        header => <<~'EOT',
            These variables give details as to where various libraries,
            installation destinations, I<etc.>, go, as well as what various
            installation options were selected
            EOT
      },
    $sockets_scn => {},
    $stack_scn => {},
    $string_scn => {
        header => <<~EOT,
            See also C<L</$unicode_scn>>.
            EOT
      },
    $SV_flags_scn => {},
    $SV_scn => {},
    $tainting_scn => {},
    $time_scn => {},
    $typedefs_scn => {},
    $unicode_scn => {
        header => <<~EOT,
            L<perlguts/Unicode Support> has an introduction to this API.

            See also C<L</$classification_scn>>,
            C<L</$casing_scn>>,
            and C<L</$string_scn>>.
            Various functions outside this section also work specially with
            Unicode.  Search for the string "utf8" in this document.
            EOT
      },
    $utility_scn => {},
    $versioning_scn => {},
    $warning_scn => {},
    $XS_scn => {},
);

# Somewhat loose match for an apidoc line so we can catch minor typos.
# Parentheses are used to capture portions so that below we verify
# that things are the actual correct syntax.
my $apidoc_re = qr/ ^ (\s*)            # $1
                      (=?)             # $2
                      (\s*)            # $3
                      for (\s*)        # $4
                      apidoc (_item | _defn )?  # $5
                      (\s*)            # $6
                      (.*?)            # $7
                      \s* \n /x;
# Only certain flags, dealing with display, are acceptable for apidoc_item
my $display_flags = "fFnDopTx;";

sub check_api_doc_line ($$$) {
    my ($file, $line_num, $in) = @_;

    return unless $in =~ $apidoc_re;

    my $is_item = defined $5 && $5 eq "_item";
    my $is_in_proper_form = length $1 == 0
                         && length $2 > 0
                         && length $3 == 0
                         && length $4 > 0
                         && length $7 > 0
                         && (    length $6 > 0
                             || ($is_item && substr($7, 0, 1) eq '|'));
    my $proto_in_file = $7;
    my $proto = $proto_in_file;
    $proto = "||$proto" if $proto !~ /\|/;
    my ($flags, $ret_type, $name, @args) = split /\s*\|\s*/, $proto;

    $name && $is_in_proper_form or die <<EOS;
Bad apidoc at $file line $line_num:
  $in
Expected:
  =for apidoc flags|returntype|name|arg|arg|...
  =for apidoc flags|returntype|name
  =for apidoc name
(or 'apidoc_item' or any of the above instead with 'apidoc_defn')
EOS

    die "Only [$display_flags] allowed in apidoc_item:\n$in"
                            if $is_item && $flags =~ /[^$display_flags]/;

    return ($name, $flags, $ret_type, $is_item, $proto_in_file, @args);
}

sub embed_override($) {
    my ($element_name) = shift;

    # If the entry is also in embed.fnc, it should be defined
    # completely there, but not here
    my $embed_docref = delete $elements{$element_name};

    return unless $embed_docref and %$embed_docref;

    my $flags = $embed_docref->{'flags'};
    warn "embed.fnc entry '$element_name' missing 'd' flag"
                                            unless $flags =~ /d/;

    return ($flags, $embed_docref->{'ret_type'}, $embed_docref->{args}->@*);
}

# The section that is in effect at the beginning of the given file.  If not
# listed here, an apidoc_section line must precede any apidoc lines.
# This allows the files listed here that generally are single-purpose, to not
# have to worry about the autodoc section
my %initial_file_section = (
                            'av.c' => $AV_scn,
                            'av.h' => $AV_scn,
                            'cv.h' => $CV_scn,
                            'deb.c' => $debugging_scn,
                            'dist/ExtUtils-ParseXS/lib/perlxs.pod' => $XS_scn,
                            'doio.c' => $io_scn,
                            'gv.c' => $GV_scn,
                            'gv.h' => $GV_scn,
                            'hv.h' => $HV_scn,
                            'locale.c' => $locale_scn,
                            'malloc.c' => $memory_scn,
                            'numeric.c' => $numeric_scn,
                            'opnames.h' => $optree_construction_scn,
                            'pad.h'=> $pad_scn,
                            'patchlevel.h' => $versioning_scn,
                            'perlio.h' => $io_scn,
                            'pod/perlapio.pod' => $io_scn,
                            'pod/perlcall.pod' => $callback_scn,
                            'pod/perlembed.pod' => $embedding_scn,
                            'pod/perlfilter.pod' => $filters_scn,
                            'pod/perliol.pod' => $io_scn,
                            'pod/perlmroapi.pod' => $MRO_scn,
                            'pod/perlreguts.pod' => $regexp_scn,
                            'pp_pack.c' => $pack_scn,
                            'pp_sort.c' => $SV_scn,
                            'regcomp.c' => $regexp_scn,
                            'regexp.h' => $regexp_scn,
                            'sv.h' => $SV_scn,
                            'sv.c' => $SV_scn,
                            'sv_inline.h' => $SV_scn,
                            'taint.c' => $tainting_scn,
                            'unicode_constants.h' => $unicode_scn,
                            'utf8.c' => $unicode_scn,
                            'utf8.h' => $unicode_scn,
                            'vutil.c' => $versioning_scn,
                           );

sub output_file ($) {
    my $flags = shift;
    return $flags =~ /A/ ? 'api' : 'intern';
}

sub autodoc ($$) { # parse a file and extract documentation info
    my($fh,$file) = @_;
    my($in, $line_num, $header, $section);

    $section = $initial_file_section{$file}
                                    if defined $initial_file_section{$file};

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

        my ($text, $element_name, $ret_type, $is_item, $proto_in_file);
        my (@args, @items);
        my $group_is_deferred = 0;
        my $flags = "";

        # If the line starts a new section ...
        if ($in=~ /^ = (?: for [ ]+ apidoc_section | head1 ) [ ]+ (.*) /x) {

            $section = $1;
            if ($section =~ / ^ \$ /x) {
                $section .= '_scn' unless $section =~ / _scn $ /x;
                $section = eval "$section";
                die "Unknown \$section variable '$section' in $file: $@" if $@;
            }
            die "Unknown section name '$section' in $file near line $line_num\n"
                                    unless defined $valid_sections{$section};
        }
        elsif ($in !~ /^ =for [ ]+ ( apidoc (?: _defn)? ) \b /x) {
            die "Unknown apidoc-type line '$in'"
                                               unless $in=~ /^=for apidoc_item/;
            die "apidoc_item doesn't immediately follow an apidoc entry: '$in'";
        }
        else {
            my $line_type = $1;
            ($element_name, $flags, $ret_type, $is_item, $proto_in_file, @args)
                                          = check_api_doc_line($file, $line_num,
                                                               $in);

            # Handle apidoc_defn line
            if ($line_type eq "apidoc_defn") {
                if (defined $elements{$element_name}) {
                    warn "Using embed.fnc entry for $element_name";
                }
                else {
                    # We expect this line to furnish the information to a
                    # corresponding apidoc line elsewhere in the source.
                    # Hence, we can say that this macro is documented.  (A
                    # warning will be raised if the mate line is missing.)
                    add_defn($element_name, $file, $line_num, $flags . "d",
                             $ret_type, \@args);
                }
                next;
            }

            # Here, is plain apidoc.  Override this line with any info in
            # embed.fnc
            my ($embed_flags, $embed_ret_type, @embed_args)
                                                = embed_override($element_name);
            if ($embed_ret_type) {
                warn "embed.fnc entry overrides redundant information in"
                    . " '$proto_in_file' in $file"
                                               if $flags || $ret_type || @args;
                $flags = $embed_flags;
                $ret_type = $embed_ret_type;
                @args = @embed_args;
            }
            elsif ($flags =~ /[my]/)  {

                # Macros and typedefs are allowed to not be in embed.fnc.
            }
            elsif ($flags eq "")  {

                # No flags at all here means this item's definition isn't yet
                # known.  Defer it to later.
                $group_is_deferred = 1;
            }
            else {

                # Not in embed.fnc, and is not a macro nor typedef, so the
                # actual definition is missing.
                $missing{$element_name} = $file;
            }

            die "flag '$1' is not legal (for function $element_name"
              . " (from $file))"
                  if $flags =~ / ( [^AabCDdEeFfGhiIMmNnTOoPpRrSsUuvWXxy;#] ) /x;

            die "'u' flag must also have 'm' or 'y' flags' for $element_name"
                                           if $flags =~ /u/ && $flags !~ /[my]/;
            warn ("'$element_name' not \\w+ in '$proto_in_file' in $file")
                   if $flags !~ /N/
                   && $element_name !~ / ^ (?:struct\s+)? [_[:alpha:]] \w* $ /x;

            if ($flags =~ /#/) {
                die "Return type must be empty for '$element_name'"
                                                                   if $ret_type;
                $ret_type = '#ifdef';
            }

            if (exists $seen{$element_name} && $flags !~ /h/) {
                die ("'$element_name' in $file was already documented in"
                   . " $seen{$element_name}");
            }
            else {
                $seen{$element_name} = $file;
            }

            # For uniformity of handling, this element is set to be
            # just the first of any remaining ones in the group.  Setting the
            # flags for this item are deferred because further processing may
            # modify them
            push @items, { name     => $element_name,
                           ret_type => $ret_type,
                           args     => [ @args ],
                         };
        }

        # Here we have processed the initial line in the heading text or API
        # element, and in the latter case, have saved the important
        # information from it into $items[0].
        #
        # Defer placing the group if no information found for it so far;
        # otherwise calculate the output pod.
        my $where = ($group_is_deferred) ? 'unknown' : output_file($flags);

        # Now accumulate the text that applies to it up to a terminating line,
        # which is one of:
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
            last if $in !~ / ^ =for [ ]+ apidoc_item /x;

            my ($item_name, $item_flags, $item_ret_type, $is_item,
                $item_proto, @item_args) = check_api_doc_line($file, $line_num,
                                                              $in);
            last unless $is_item;

            # Here, is an apidoc_item_line; They can only come within apidoc
            # paragraphs.
            die "Unexpected api_doc_item line '$item_proto'"
                                                        unless $element_name;

            # We accept blank lines between these, but nothing else;
            die "apidoc_item lines must immediately follow apidoc lines for "
              . " '$element_name' in $file"
                                                            if $text =~ /\S/;
            # Override this line with any info in embed.fnc
            my ($embed_flags, $embed_ret_type, @embed_args)
                                                = embed_override($item_name);
            if ($embed_ret_type) {
                warn "embed.fnc entry overrides redundant information in"
                    . " '$item_proto' in $file"
                                if $item_flags || $item_ret_type || @item_args;

                $item_flags = $embed_flags;
                $item_ret_type = $embed_ret_type;
                @item_args = @embed_args;
            }

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

            # If we have no information about this item, it is because its
            # definition has yet to be encountered.  Add it to the list of
            # such, with a bread crumb trail so that later we can easily find
            # where it all fits
            if ("$item_ret_type$item_flags@item_args" eq "") {
                push $deferreds{$element_name}->@*,
                     {
                        name => $item_name,
                        section => $section,
                        pod     => $where,
                        file    => $file,   # Just for any error message
                     };
            }

            # This line shows that this element is documented.
            delete $elements{$item_name};
        }

        # Here, are done accumulating the text for this item.  Trim it
        $text =~ s/ ^ \s* //x;
        $text =~ s/ \s* $ //x;
        $text .= "\n" if $text ne "";

        # And treat all-spaces as nothing at all
        undef $text unless $text =~ /\S/;

        if ($element_name) {

            # Here, we have accumulated into $text, the pod for $element_name

            die "No =for apidoc_section nor =head1 in $file for"
              . "'$element_name'\n" unless defined $section;
            my $is_link_only = ($flags =~ /h/);
            if (   ! $is_link_only
                && exists $docs{$where}{$section}{$element_name})
            {
                warn "$0: duplicate API entry for '$element_name' in"
                    . " $where/$section\n";
                next;
            }

            # Override the text with just a link if the flags call for that
            if ($is_link_only) {
                if ($file_is_C) {
                    die "Can't currently handle link with items to it:\n$in"
                                                                if @items > 1;
                    $docs{$where}{$section}{X_tags}{$element_name} = $file;
                    redo;    # Don't put anything if C source
                }

                # Here, is an 'h' flag in pod.  We add a reference to the pod
                # (and nothing else) to perlapi/intern.  (It would be better
                # to add a reference to the correct =item,=header, but
                # something that makes it harder is that it that might be a
                # duplicate, like '=item *'; so that is a future enhancement
                # XXX.  Another complication is there might be more than one
                # deserving candidates.)
                my $podname = $file =~ s!.*/!!r;    # Rmv directory name(s)
                $podname =~ s/\.pod//;
                $text = "Described in L<$podname>.\n";

                # Don't output a usage example for linked to documentation if
                # it is trivial (has no arguments) and we aren't to add a
                # semicolon
                $flags .= 'U' if $flags =~ /n/ && $flags !~ /[U;]/;

                # Keep track of all the pod files that we refer to.
                push $described_elsewhere{$podname}->@*, $podname;
            }

            $docs{$where}{$section}{$element_name}{pod} = $text;
            $docs{$where}{$section}{$element_name}{file} = $file;
            $items[0]{flags} = $flags;
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
    use re '/aa';   # Everything is ASCII in this file

    # Process config.h
    die "Can't find $config_h" unless -e $config_h;
    open my $fh, '<', $config_h or die "Can't open $config_h: $!";
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

                    # The first verbatim line in a run of them is separated by
                    # an empty line from the flowing lines above it
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
                  (?: / \s* \* \* / )?          # Optional trailing /**/
                                                # or / **/
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
                        . "The '$section' section contained\n'$was'";
                }
                $docs{'api'}{$section}{$name}->{pod} = $configs{$name}{pod};
                $configs{$name}{section} = $section;
                last;
            }
            elsif (exists $docs{'intern'}{$section}{$name}) {
                die "'$name' is in 'config.h' meaning it is part of the API,\n"
                  . " but it is also in 'perlintern', meaning it isn't API\n";
            }
        }

        my $handled = 0;    # Haven't handled this yet

        if (defined $configs{$name}{'section'}) {
            # This has been taken care of elsewhere.
            $handled = 1;
        }
        else {
            my $flags = "";
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
            # This is the default section for macros with a definition but
            # no arguments, meaning it is replaced unconditionally
            #
            my $sb = qr/ _ | \b /x; # segment boundary
            my $dash_or_spaces = qr/ - | \s+ /x;
            my $pod = $configs{$name}{pod};
            if ($name =~ / ^ USE_ /x) {
                $configs{$name}{'section'} = $site_scn;
            }
            elsif ($name =~ / SLEEP | (*nlb:SYS_) TIME | TZ | $sb TM $sb /x)
            {
                $configs{$name}{'section'} = $time_scn;
            }
            elsif (   $name =~ / ^ [[:alpha:]]+ f $ /x
                   && $configs{$name}{pod} =~ m/ \b format \b /ix)
            {
                $configs{$name}{'section'} = $io_formats_scn;
            }
            elsif ($name =~ /  DOUBLE | FLOAT | LONGDBL | LDBL | ^ NV
                            | $sb CASTFLAGS $sb
                            | QUADMATH
                            | $sb (?: IS )? NAN
                            | $sb (?: IS )? FINITE
                            /x)
            {
                $configs{$name}{'section'} =
                                    $floating_scn;
            }
            elsif ($name =~ / (?: POS | OFF | DIR ) 64 /x) {
                $configs{$name}{'section'} = $filesystem_scn;
            }
            elsif (   $name =~ / $sb (?: BUILTIN | CPP ) $sb | ^ CPP /x
                   || $configs{$name}{pod} =~ m/ \b align /x)
            {
                $configs{$name}{'section'} = $compiler_scn;
            }
            elsif ($name =~ / ^ [IU] [ \d V ]
                            | ^ INT | SHORT | LONG | QUAD | 64 | 32 /xx)
            {
                $configs{$name}{'section'} = $integer_scn;
            }
            elsif ($name =~ / $sb t $sb /x) {
                $configs{$name}{'section'} = $typedefs_scn;
                $flags .= 'y';
            }
            elsif (   $name =~ / ^ PERL_ ( PRI | SCN ) | $sb FORMAT $sb /x
                    && $configs{$name}{pod} =~ m/ \b format \b /ix)
            {
                $configs{$name}{'section'} = $io_formats_scn;
            }
            elsif ($name =~ / BACKTRACE /x) {
                $configs{$name}{'section'} = $debugging_scn;
            }
            elsif ($name =~ / ALLOC $sb /x) {
                $configs{$name}{'section'} = $memory_scn;
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
                $configs{$name}{'section'} = $filesystem_scn;
            }
            elsif ($name =~ / ^ SIG | SIGINFO | signal /ix) {
                $configs{$name}{'section'} = $signals_scn;
            }
            elsif ($name =~ / $sb ( PROTO (?: TYPE)? S? ) $sb /x) {
                $configs{$name}{'section'} = $prototypes_scn;
            }
            elsif (   $name =~ / ^ LOC_ /x
                    || $configs{$name}{pod} =~ /full path/i)
            {
                $configs{$name}{'section'} = $paths_scn;
            }
            elsif ($name =~ / $sb LC_ | LOCALE | langinfo /xi) {
                $configs{$name}{'section'} = $locale_scn;
            }
            elsif ($configs{$name}{pod} =~ /  GCC | C99 | C\+\+ /xi) {
                $configs{$name}{'section'} = $compiler_scn;
            }
            elsif ($name =~ / PASSW (OR)? D | ^ PW | ( PW | GR ) ENT /x)
            {
                $configs{$name}{'section'} = $password_scn;
            }
            elsif ($name =~ /  SOCKET | $sb SOCK /x) {
                $configs{$name}{'section'} = $sockets_scn;
            }
            elsif (   $name =~ / THREAD | MULTIPLICITY /x
                    || $configs{$name}{pod} =~ m/ \b pthread /ix)
            {
                $configs{$name}{'section'} = $concurrency_scn;
            }
            elsif ($name =~ /  PERL | ^ PRIV | SITE | ARCH | BIN
                                | VENDOR | ^ USE
                            /x)
            {
                $configs{$name}{'section'} = $site_scn;
            }
            elsif (   $pod =~ / \b floating $dash_or_spaces point \b /ix
                   || $pod =~ / \b (double | single) $dash_or_spaces
                                precision \b /ix
                   || $pod =~ / \b doubles \b /ix
                   || $pod =~ / \b (?: a | the | long ) \s+
                                (?: double | NV ) \b /ix)
            {
                $configs{$name}{'section'} =
                                    $floating_scn;
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
                # and unlikely the description adds significant value, so just
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

                $configs{$name}{'section'} = $genconfig_scn;
            }

            my $section = $configs{$name}{'section'};
            die "Internal error: '$section' not in \%valid_sections"
                            unless grep { $_ eq $section } keys %valid_sections;
            $flags .= 'AdmnT';
            $flags .= 'U' unless defined $configs{$name}{usage};

            # All the information has been gathered; save it
            $docs{'api'}{$section}{$name}{items}[0]->{flags} = $flags;
            $docs{'api'}{$section}{$name}{items}[0]->{name} = $name;
            $docs{'api'}{$section}{$name}{pod} = $configs{$name}{pod};
            $docs{'api'}{$section}{$name}{items}[0]{ret_type} = "";
            $docs{'api'}{$section}{$name}{file} = 'config.h';
            $docs{'api'}{$section}{$name}{usage}
                = $configs{$name}{usage} if defined $configs{$name}{usage};
            push $docs{'api'}{$section}{$name}{items}[0]{args}->@*, ();
        }
    }
}

sub format_pod_indexes($) {
    my $entries_ref = shift;

    # Output the X<> references to the names, packed since they don't get
    # displayed, but not too many per line so that when someone is editing the
    # file, it doesn't run on

    my $text ="";
    my $line_length = 0;
    for my $name (sort dictionary_order $entries_ref->@*) {
        my $entry = "X<$name>";
        my $entry_length = length $entry;

        # Don't loop forever if we have a verrry long name, and don't go too
        # far to the right.
        if ($line_length > 0 && $line_length + $entry_length > $max_width) {
            $text .= "\n";
            $line_length = 0;
        }

        $text .= $entry;
        $line_length += $entry_length;
    }

    return $text;
}

sub docout ($$$) { # output the docs for one function group
    my($fh, $element_name, $docref) = @_;

    # Trim trailing space
    $element_name =~ s/\s*$//;

    my $pod = $docref->{pod} // "";
    my $file = $docref->{file};

    my @items = $docref->{items}->@*;
    my $flags = $items[0]{flags};

    warn("Empty pod for $element_name (from $file)") unless $pod =~ /\S/;

    print $fh "\n=over $description_indent\n";
    print $fh "\n=item C<$_->{name}>\n" for @items;

    # If we're printing only a link to an element, this isn't the major entry,
    # so no X<> here.
    if ($flags !~ /h/) {
        print $fh "X<$_->{name}>" for @items;
        print $fh "\n";
    }

    my @deprecated;
    my @experimental;
    for my $item (@items) {
        push @deprecated,   "C<$item->{name}>" if $item->{flags} =~ /D/;
        push @experimental, "C<$item->{name}>" if $item->{flags} =~ /x/;
    }

    for my $which (\@deprecated, \@experimental) {
        if ($which->@*) {
            my $is;
            my $it;
            my $list;

            if ($which->@* == 1) {
                $is = 'is';
                $it = 'it';
                $list = $which->[0];
            }
            elsif ($which->@* == @items) {
                $is = 'are';
                $it = 'them';
                $list = (@items == 2)
                         ? "both forms"
                         : "all these forms";
            }
            else {
                $is = 'are';
                $it = 'them';
                my $final = pop $which->@*;
                $list = "the " . join ", ", $which->@*;
                $list .= "," if $which->@* > 1;
                $list .= " and $final forms";
            }

            if ($which == \@deprecated) {
                print $fh <<~"EOT";

                    C<B<DEPRECATED!>>  It is planned to remove $list
                    from a future release of Perl.  Do not use $it for
                    new code; remove $it from existing code.
                    EOT
            }
            else {
                print $fh <<~"EOT";

                    NOTE: $list $is B<experimental> and may change or be
                    removed without notice.
                    EOT
            }
        }
    }

    chomp $pod;     # Make sure prints pod with a single trailing \n
    print $fh "\n", $pod, "\n";

    # Accumulate the usage section of the entry into this array.  Output below
    # only when non-empty
    my @usage;
    if (defined $docref->{usage}) {

        # A complete override of the usage section.  Note that the check for
        # the O flag isn't checked for, as that usage is never output in this
        # case
        push @usage, ($docref->{usage} =~ s/^/ /mrg), "\n";
    }
    else {
        my @outputs;    # The items actually to output, annotated

        # Look through all the items in this entry.  Find the longest of
        # certain fields, so that if multiple items are shown, they can be
        # nicely vertically aligned.
        my $max_name_len = 0;
        my $max_retlen = 0;

        for my $item (@items) {
            my $name = $item->{name};
            my $flags = $item->{flags};
            my $has_U_flag = $flags =~ /U/;

            warn("'U' and ';' flags are incompatible") if $has_U_flag
                                                       && $flags =~ /;/;

            print $fh "\nNOTE: the C<perl_$name()> form is",
                      " B<deprecated>.\n" if $flags =~ /O/;

            # U means to not display the prototype; and there really isn't a
            # single good canonical signature for a typedef, so they aren't
            # displayed
            next if $has_U_flag || $flags =~ /y/;

            my $has_semicolon = $flags =~ /;/;
            my $has_args = $flags !~ /n/;
            my $ret = $item->{ret_type} // "";

            # If none of these exist, the prototype will be trivial, just
            # the name of the item, so don't display it.
            next unless $ret|| $has_semicolon || $has_args;

            if (! $has_args) {
                warn("$file: $name: n flag without m") unless $flags =~ /m/;

                if ($item->{args} && $item->{args}->@*) {
                    warn("$file: $name: n flag but apparently has args");
                    $flags =~ s/n//g;
                    $has_args = 1;
                }
            }

            my @args;
            my $this_has_pTHX = 0;
            if ($has_args) {
                @args = $item->{args}->@*;

                # If only the Perl_foo form is to be displayed, change the
                # name of this item to be that.  This happens for either of
                # two reasons:
                #   1) The flags say we want "Perl_", but also to not create
                #      an entry in embed.h to #define a short name for it.
                my $needs_Perl_entry = (   $flags =~ /p/
                                        && $flags =~ /o/
                                        && $flags !~ /M/);

                #   2) The function takes a format string and a thread context
                #      parameter.  We can't cope with that because our macros
                #      expect both the thread context and the format to be the
                #      first parameter to the function; and only one can be in
                #      that position.
                my $cant_use_short_name = (   $flags =~ /f/
                                           && $flags !~ /T/
                                           && $name !~ /strftime/);
                if ($needs_Perl_entry || $cant_use_short_name) {
                    my $short_name = $name;
                    $name = "Perl_$short_name";

                    print $fh <<~"EOT";

                        NOTE: C<$short_name> must be explicitly called as
                        C<$name>
                        EOT

                    # We can't hide the existence of any thread context
                    # parameter when using the "Perl_" long form.  So it must
                    # be the first parameter to the function.
                    if ($flags !~ /T/) {
                        print $fh "with an C<aTHX_> parameter";
                        $this_has_pTHX = 1;
                        unshift @args, "pTHX";
                    }

                    print $fh ".\n";
                }
            }

            my $retlen = length $ret;
            $max_retlen = $retlen if $retlen > $max_retlen;

            my $name_len = length $name;
            $max_name_len = $name_len if $name_len > $max_name_len;

            # Start creating this item's hash to guide its output
            push @outputs, {
                            ret => $ret, retlen => $retlen,
                            name => $name, name_len => $name_len,
                            has_pTHX => $this_has_pTHX,
                           };

            $outputs[-1]->{args}->@* = @args if $has_args;
            $outputs[-1]->{semicolon} = ";" if $has_semicolon;
        }

        my $indent = 1; # Minimum space to get a verbatim block.

        # Above, we went through all the items in the group, discarding the
        # ones with trivial usage/prototype lines.  Now go through the
        # remaining ones, and add them to the list of output text.
        if (@outputs) {

            # We have available to us the remaining portion of the line after
            # subtracting all the indents this text is subject to.
            my $usage_max_width = $max_width
                                - $description_indent
                                - $usage_indent
                                - $indent;

            # Basically, there are three columns.  The first column is always
            # a blank to make this a verbatim block, and the return type
            # starts in the column after that.  The name column follows a
            # little to the right of the widest return type entry.
            my $name_column = $indent + $max_retlen + $usage_ret_name_sep_len;

            # And the arguments column follows immediately to the right of the
            # widest name entry.
            my $args_column = $name_column + $max_name_len;

            for my $element (@outputs) {

                # $running_length keeps track of which column we are currently
                # at.
                push @usage, " " x $indent;
                my $running_length = $indent;

                # Output the return type, followed by enough blanks to get us
                # to the beginning of the name
                push @usage, $element->{ret} if $element->{retlen};
                $running_length += $element->{retlen};
                push @usage, " " x ($name_column - $running_length);

                # Then output the name
                push @usage, $element->{name};
                $running_length = $name_column + $element->{name_len};

                # If there aren't any arguments, we are done, except for maybe
                # a semi-colon.
                if (! defined $element->{args}) {
                    push @usage, $element->{semicolon} // "";
                }
                else {

                    # Otherwise get to the first arguments column and output
                    # the left parenthesis
                    push @usage, " " x ($args_column - $running_length);
                    push @usage, "(";
                    $running_length = $args_column + 1;

                    # We know the final ending text.
                    my $tail = ")" . ($element->{semicolon} // "");

                    # Now ready to output the arguments.  It's quite possible
                    # that not all will fit on the remainder of the line, so
                    # will have to be wrapped onto subsequent line(s) with a
                    # hanging indent to make them into an aligned block.  It
                    # also does happen that one single argument can be so wide
                    # that it won't fit in the remainder of the line by
                    # itself.  In this case, we outdent the entire block by
                    # the excess width; this retains vertical alignment, like
                    # so:
                    #                   void  function_name(pTHX_ short1,
                    #                                    short2,
                    #                                    very_long_argument,
                    #                                    short3)
                    #
                    # First we have to find the width of the widest argument.
                    my $max_arg_len = 0;
                    for my $arg ($element->{args}->@*) {

                        # +1 because of attached comma or right paren
                        my $arg_len = 1 + length $arg;

                        $max_arg_len = $arg_len if $arg_len > $max_arg_len;
                    }

                    # Set the hanging indent to get to the '(' column.  All
                    # arguments but the first are output with a space
                    # separating them from the previous argument.  This is
                    # done even when not all arguments fit on the first line,
                    # so there is a second (etc.) line.  The first argument on
                    # those lines will have a leading space which causes those
                    # lines to automatically align to the next column after
                    # the '(', without us having to consider it further than
                    # the +1 in the excess width calculation
                    my $hanging_indent = $args_column;

                    # See if there is an argument too wide to fit
                    my $excess_width = $hanging_indent
                                     + 1  # To space past the '('
                                     + $max_arg_len
                                     - $usage_max_width;

                    # Outdent if necessary
                    $hanging_indent -= $excess_width if $excess_width > 0;

                    # Go through the argument list.  Calculate how much space
                    # each takes, and start a new line if this won't fit on
                    # the current one.
                    for (my $i = 0; $i < $element->{args}->@*; $i++) {
                        my $arg = $element->{args}[$i];
                        my $is_final = $i == $element->{args}->@* - 1;

                        # +1 for the comma or right paren afterwards
                        my $this_length = 1 + length $arg;

                        # All but the first one have a blank separating them
                        # from the previous argument.
                        $this_length += 1 if $i != 0;

                        # With an extra +1 for the final one if needs a
                        # semicolon
                        $this_length += 1 if defined $element->{semicolon}
                                          && $is_final;

                        # If this argument doesn't fit on the line, start a
                        # new line, with the appropriate indentation.  Note
                        # that this value has been calculated above so that
                        # the argument will definitely fit on this new line.
                        if ($running_length + $this_length > $usage_max_width) {
                            push @usage, "\n", " " x $hanging_indent;
                            $running_length = $hanging_indent;
                        }

                        # Ready to output; first a blank separator for all but
                        # the first item
                        push @usage, " " if $i != 0;

                        push @usage, $arg;

                        # A comma-equivalent character for all but the final
                        # one indicates there is more to come; "pTHX" has an
                        # underscore, not a comma
                        if (! $is_final) {
                            push @usage, ($i == 0 && $element->{has_pTHX})
                                         ? "_"
                                         : ",";
                        }

                        $running_length += $this_length;
                    }

                    push @usage, $tail;
                }

                push @usage, "\n";
            }
        }
    }

    if (grep { /\S/ } @usage) {
        print $fh "\n=over $usage_indent\n\n";
        print $fh join "", @usage;
        print $fh "\n=back\n";
    }

    print $fh "\n=back\n";
    print $fh "\n=for hackers\nFound in file $file\n";
}

sub construct_missings_section {
    my ($missings_hdr, $missings_ref) = @_;
    my $text = "";

    $text .= "$missings_hdr\n" . format_pod_indexes($missings_ref);

    if ($missings_ref->@* == 0) {
        return $text . "\nThere are currently no items of this type\n";
    }

    # Sort the elements.
    my @missings = sort dictionary_order $missings_ref->@*;

    # Make a table of the missings in columns.  Give the subroutine a width
    # one less than you might expect, as we indent each line by one, to mark
    # it as verbatim.
    my $table .= columnarize_list(\@missings, $max_width - 1);
    $table =~ s/^/ /gm;

    return $text . "\n\n" . $table;
}

sub dictionary_order {
    # Do a case-insensitive dictionary sort, falling back in stages to using
    # everything for determinancy.  The initial comparison ignores
    # all non-word characters and non-trailing underscores and digits, with
    # trailing ones collating to after any other characters.  This collation
    # order continues in case tie breakers are needed; sequences of digits
    # that do get looked at always compare numerically.  The first tie
    # breaker takes all digits and underscores into account.  The next tie
    # breaker uses a caseless character-by-character comparison of everything
    # (including non-word characters).  Finally is a cased comparison.
    #
    # This gives intuitive results, but obviously could be tweaked.

    no warnings 'non_unicode';

    local $a = $a;
    local $b = $b;

    # Convert all digit sequences to same length with leading zeros, so for
    # example, 8 will compare less than 16 (using a fill length value that
    # should be longer than any sequence in the input).
    $a =~ s/(\d+)/sprintf "%06d", $1/ge;
    $b =~ s/(\d+)/sprintf "%06d", $1/ge;

    # Translate any underscores and digits so they compare after all Unicode
    # characters
    $a =~ tr[_0-9]/\x{110000}-\x{11000A}/;
    $b =~ tr[_0-9]/\x{110000}-\x{11000A}/;

    use feature 'state';
    # Modify \w, \W to reflect the changes.
    state $ud = '\x{110000}-\x{11000A}';    # xlated underscore, digits
    state $w = "\\w$ud";                    # new \w string
    state $mod_w = qr/[$w]/;
    state $mod_W = qr/[^$w]/;

    # Only \w for initial comparison
    my $a_only_word = uc($a =~ s/$mod_W//gr);
    my $b_only_word = uc($b =~ s/$mod_W//gr);

    # And not initial nor interior underscores nor digits (by squeezing them
    # out)
    my $a_stripped = $a_only_word =~ s/ (*atomic:[$ud]+) (*pla: $mod_w ) //grxx;
    my $b_stripped = $b_only_word =~ s/ (*atomic:[$ud]+) (*pla: $mod_w ) //grxx;

    # If the stripped versions differ, use that as the comparison.
    my $cmp = $a_stripped cmp $b_stripped;
    return $cmp if $cmp;

    # For the first tie breaker, repeat, but consider initial and interior
    # underscores and digits, again having those compare after all Unicode
    # characters
    $cmp = $a_only_word cmp $b_only_word;
    return $cmp if $cmp;

    # Next tie breaker is just a caseless comparison
    $cmp = uc($a) cmp uc($b);
    return $cmp if $cmp;

    # Finally a straight comparison
    return $a cmp $b;
}

sub output($) {
    my $where = shift;
    my $podname = $where->{podname};
    my $dochash = $where->{docs};

    # strip leading '|' from each line which had been used to hide pod from
    # pod checkers.
    s/^\|//gm for $where->{hdr}, $where->{footer};

    my $fh = open_new("pod/$podname.pod", undef,
                      {by => "$0 extracting documentation",
                       from => 'the C source files'}, 1);

    print $fh $where->{hdr}, "\n";

    for my $section_name (sort dictionary_order keys %valid_sections) {
        my $section_info = $dochash->{$section_name};

        # We allow empty sections in perlintern.
        if (! $section_info && $podname eq 'perlapi') {
            warn "Empty section '$section_name' for $podname; skipped";
            next;
        }

        print $fh "\n=head1 $section_name\n";

        if ($section_info->{X_tags}) {
            print $fh "X<$_>" for sort keys $section_info->{X_tags}->%*;
            print $fh "\n";
            delete $section_info->{X_tags};
        }

        if ($podname eq 'perlapi') {
            print $fh "\n", $valid_sections{$section_name}{header}, "\n"
                 if defined $valid_sections{$section_name}{header};

            # Output any heading-level documentation and delete so won't get in
            # the way later
            if (exists $section_info->{""}) {
                print $fh "\n", $section_info->{""}, "\n";
                delete $section_info->{""};
            }
        }

        if ($section_info && keys $section_info->%*) {
            for my $function_name (sort dictionary_order keys %$section_info) {
                docout($fh, $function_name, $section_info->{$function_name});
            }
        }
        else {
            my $pod_type = ($podname eq 'api') ? "public" : "internal";
            print $fh "\nThere are currently no $pod_type API items in ",
                      $section_name, "\n";
        }

        print $fh "\n", $valid_sections{$section_name}{footer}, "\n"
                            if $podname eq 'perlapi'
                            && defined $valid_sections{$section_name}{footer};
    }

    print $fh <<~EOT;

        =head1 $undocumented_scn

        EOT

    # The missings section has multiple subsections, described by an array.
    # The first two items in the array give first the name of the variable
    # containing the text for the heading for the first subsection to output,
    # and the second is a reference to a list of names of items in that
    # subsection.
    #
    # The next two items are for the next output subsection, and so forth.
    while ($where->{missings}->@*) {
        my $hdr_name = shift $where->{missings}->@*;
        my $hdr = $where->{$hdr_name};

        # strip leading '|' from each line which had been used to hide pod
        # from pod checkers.
        $hdr =~  s/^\|//gm;

        my $ref = shift $where->{missings}->@*;

        print $fh construct_missings_section($hdr, $ref);
    }

    print $fh "\n$where->{footer}\n=cut\n";

    read_only_bottom_close_and_rename($fh);
}

sub add_defn  {
    my ($func, $file, $line_num, $flags, $ret_type, $args_ref) = @_;

    my @munged_args= $args_ref->@*;
    s/\b(?:NN|NULLOK)\b\s+//g for @munged_args;

    $elements{$func} = {
                        flags => $flags,
                        ret_type => $ret_type,
                        args => \@munged_args,
                        file => $file,
                        line_num => $line_num // 0,
                       };
}

foreach (@{(setup_embed())[0]}) {
    my $embed= $_->{embed}
        or next;
    my $file = $_->{source};
    my ($flags, $ret_type, $func, $args) =
                                 @{$embed}{qw(flags return_type name args)};
    add_defn($func, $file,
             undef,     # Unknown line number in embed.fnc
             $flags, $ret_type, $args);
}

# glob() picks up docs from extra .c or .h files that may be in unclean
# development trees.
my @headers;
my @non_headers;
open my $fh, '<', 'MANIFEST'
    or die "Can't open MANIFEST: $!";
while (my $line = <$fh>) {
    next unless my ($file) = $line =~ /^(\S+\.(?:[ch]|pod))\t/;

    # Don't pick up pods from these.
    next if $file =~ m! ^ ( cpan | dist | ext ) / !x
         && ! defined $extra_input_pods{$file};

    if ($file =~ /\.h/) {
        push @headers, $file;
    }
    else {
        push @non_headers, $file;
    }
}
close $fh or die "Error whilst reading MANIFEST: $!";

for my $file (@headers, @non_headers) {
    open my $fh, '<', $file or die "Cannot open $file for docs: $!\n";
    autodoc($fh, $file);
    close $fh or die "Error closing $file: $!\n";
}

parse_config_h();

# Any apidoc group whose leader element's documentation wasn't known by the
# time it was parsed has been placed in 'unknown' member of %docs.  We should
# now be able to figure out which real pod file to place it in, and its usage.
my $unknown = $docs{unknown};
foreach my $section_name (keys $unknown->%*) {
    foreach my $group_name (keys $unknown->{$section_name}->%*) {

        # The leader is always the 0th element in the 'items' array.
        my $item_name = $unknown->{$section_name}{$group_name}{items}[0]{name};

        # We should have a usage definition by now.
        my $corrected = delete $elements{$item_name};
        if (! defined $corrected) {
            die "=for apidoc line without any usage definition $item_name in"
              . " $unknown->{$section_name}{$group_name}{file}";
        }

        my $where = output_file($corrected->{flags});

        # $where now gives the correct pod for this group.  Prepare to move it
        # to there
        die "$where unexpectedly has an entry in $section_name for $group_name"
                          if defined $docs{$where}{$section_name}{$group_name};
        $docs{$where}{$section_name}{$group_name} =
                                 delete $unknown->{$section_name}{$group_name};

        # And fill in the leader item with the saved values
        my $new = $docs{$where}{$section_name}{$group_name}{items}[0];
        $new->{name} = $item_name;
        $new->{args} = $corrected->{args};
        $new->{flags} = $corrected->{flags};
        $new->{ret_type} = $corrected->{ret_type};
    }
}

# Now that any leaders have been filled in, we can do the same for all the
# deferred non-leaders
for my $group_name (keys %deferreds) {
    my $group = delete $deferreds{$group_name};
    foreach my $item ($group->@*) {
        my $item_name = $item->{name};

        # We should have a usage definition by now.
        my $corrected = delete $elements{$item_name};
        if (! $corrected) {
            die "=for apidoc line without any usage definition $item_name in"
              . " $item->{file}";
        }

        my $section = $item->{section};
        my $flags = $corrected->{flags};

        my $where = output_file($flags);

        # We know where this element is that needs to be updated.  It better
        # exist, or something is badly wrong
        my $dest = $docs{$where}{$section}{$group_name};
        if (! defined $dest) {
            die "Unexpectedly didn't find an entry for"
              . " $where->$section->$group_name";
        }

        # Look through the item list for this one, and correct it.
        my $found = 0;
        for my $dest_item ($dest->{items}->@*) {
            next unless $dest_item->{name} eq $item_name;
            $dest_item->{args} = $corrected->{args};
            $dest_item->{flags} = $corrected->{flags};
            $dest_item->{ret_type} = $corrected->{ret_type};
            $found = 1;
        }

        if (! $found) {
            die "Unexpectedly didn't find an entry for"
              . " $where->$section->$group_name->$item_name";
        }
    }
}

for (sort keys %elements) {
    next unless $elements{$_}{flags} =~ /d/;
    next if $elements{$_}{flags} =~ /h/;
    warn "no docs for $_\n";
}


foreach (sort keys %missing) {
    warn "Function '$_', documented in $missing{$_}, not listed in embed.fnc"
       . " nor in the source";
}

my %api    = ( podname => 'perlapi',    docs => $docs{'api'} );
my %intern = ( podname => 'perlintern', docs => $docs{'intern'} );

# List of funcs in the public API that aren't also marked as core-only,
# experimental nor deprecated.
my @undocumented_api =    grep {        $elements{$_}{flags} =~ /A/
                                   && ! $docs{api}{$_}
                               } keys %elements;
# Same for perlintern
my @undocumented_intern = grep {        $elements{$_}{flags} !~ /[AS]/
                                   && ! $docs{intern}{$_}
                               } keys %elements;

unshift $api{missings}->@*,
 (deprecated_hdr => [ grep { $elements{$_}{flags} =~ /[D]/ } @undocumented_api]);
unshift $intern{missings}->@*,
 (deprecated_hdr => [ grep { $elements{$_}{flags} =~ /[D]/ } @undocumented_intern]);

unshift $api{missings}->@*,
 (experimental_hdr => [ grep { $elements{$_}{flags} =~ /[x]/ } @undocumented_api]);
unshift $intern{missings}->@*,
(experimental_hdr => [ grep { $elements{$_}{flags} =~ /[x]/ } @undocumented_intern]);

unshift $api{missings}->@*,
 (missings_hdr => [ grep { $elements{$_}{flags} !~ /[xD]/ } @undocumented_api]);
push $api{missings}[1]->@*, keys %missing_macros;

unshift $intern{missings}->@*,
 (missings_hdr => [ grep { $elements{$_}{flags} !~ /[xD]/ } @undocumented_intern]);

my @other_places = ( qw(perlclib ), keys %described_elsewhere );
my $places_other_than_intern = join ", ",
            map { "L<$_>" } sort dictionary_order 'perlapi', @other_places;
my $places_other_than_api = join ", ",
            map { "L<$_>" } sort dictionary_order 'perlintern', @other_places;

# The S< > makes things less densely packed, hence more readable
my $has_defs_text .= join ",S< > ", map { "C<$_>" }
                                             sort dictionary_order @has_defs;
my $has_r_defs_text .= join ",S< > ", map { "C<$_>" }
                                             sort dictionary_order @has_r_defs;
$valid_sections{$genconfig_scn}{footer} =~ s/__HAS_LIST__/$has_defs_text/;
$valid_sections{$genconfig_scn}{footer} =~ s/__HAS_R_LIST__/$has_r_defs_text/;

my $include_defs_text .= join ",S< > ", map { "C<$_>" }
                                            sort dictionary_order @include_defs;
$valid_sections{$genconfig_scn}{footer}
                                      =~ s/__INCLUDE_LIST__/$include_defs_text/;

my $section_list = join "\n\n", map { "=item L</$_>" }
                                sort(dictionary_order keys %valid_sections),
                                $undocumented_scn;  # Keep last

# Leading '|' is to hide these lines from pod checkers.  khw is unsure if this
# is still needed.
$api{hdr} = <<"_EOB_";
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
|L<At the end|/$undocumented_scn> is a list of functions which have yet
|to be documented.  Patches welcome!  The interfaces of these are subject to
|change without notice.
|
|Some of the functions documented here are consolidated so that a single entry
|serves for multiple functions which all do basically the same thing, but have
|some slight differences.  For example, one form might process magic, while
|another doesn't.  The name of each variation is listed at the top of the
|single entry.
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
|and may be changed or removed without notice; same with macros.
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
|The organization of this document is tentative and subject to change.
|Suggestions and patches welcome
|L<perl5-porters\@perl.org|mailto:perl5-porters\@perl.org>.
|
|The sections in this document currently are
|
|=over $standard_indent

|$section_list
|
|=back
|
|The listing below is alphabetical, case insensitive.
_EOB_

$api{footer} = <<"_EOE_";
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
|F<config.h>, $places_other_than_api
_EOE_

$api{missings_hdr} = <<'_EOT_';
|The following functions have been flagged as part of the public
|API, but are currently undocumented.  Use them at your own risk,
|as the interfaces are subject to change.  Functions that are not
|listed in this document are not intended for public use, and
|should NOT be used under any circumstances.
|
|If you feel you need to use one of these functions, first send
|email to L<perl5-porters@perl.org|mailto:perl5-porters@perl.org>.
|It may be that there is a good reason for the function not being
|documented, and it should be removed from this list; or it may
|just be that no one has gotten around to documenting it.  In the
|latter case, you will be asked to submit a patch to document the
|function.  Once your patch is accepted, it will indicate that the
|interface is stable (unless it is explicitly marked otherwise) and
|usable by you.
_EOT_

$api{experimental_hdr} = <<"_EOT_";
|
|Next are the API-flagged elements that are considered experimental.  Using one
|of these is even more risky than plain undocumented ones.  They are listed
|here because they should be listed somewhere (so their existence doesn't get
|lost) and this is the best place for them.
_EOT_

$api{deprecated_hdr} = <<"_EOT_";
|
|Finally are deprecated undocumented API elements.
|Do not use any for new code; remove all occurrences of all of these from
|existing code.
_EOT_
output(\%api);

$intern{hdr} = <<"_EOB_";
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

|It has the same sections as L<perlapi>, though some may be empty.
|
_EOB_

$intern{footer} = <<"_EOE_";
|
|=head1 AUTHORS
|
|The autodocumentation system was originally added to the Perl core by
|Benjamin Stuhl.  Documentation is by whoever was kind enough to
|document their functions.
|
|=head1 SEE ALSO
|
|F<config.h>, $places_other_than_intern
_EOE_

$intern{missings_hdr} = <<"_EOT_";
|
|This section lists the elements that are otherwise undocumented.  If you use
|any of them, please consider creating and submitting documentation for it.
|
|Experimental and deprecated undocumented elements are listed separately at the
|end.
|
_EOT_

$intern{experimental_hdr} = <<"_EOT_";
|
|Next are the experimental undocumented elements
|
_EOT_

$intern{deprecated_hdr} = <<"_EOT_";
|
|Finally are the deprecated undocumented elements.
|Do not use any for new code; remove all occurrences of all of these from
|existing code.
|
_EOT_

output(\%intern);
