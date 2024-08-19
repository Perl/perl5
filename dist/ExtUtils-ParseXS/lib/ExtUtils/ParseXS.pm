package ExtUtils::ParseXS;
use strict;

# Note that the pod for this module is separate in ParseXS.pod.
#
# This module provides the guts for the xsubpp XS-to-C translator utility.
# By having it as a module separate from xsubpp, it makes it more efficient
# to be used for example by Module::Build without having to shell out to
# xsubpp. It also makes it easier to test the individual components.
#
# The bulk of this file is taken up with the process_file() method which
# does the whole job of reading in a .xs file and outputting a .c file.
# It in turn relies on fetch_para() to read chunks of lines from the
# input, and on a bunch of FOO_handler() methods which process each of the
# main XS FOO keywords when encountered.
#
# The remainder of this file mainly consists of helper functions for the
# handlers, and functions to help with outputting stuff.
#
# Of particular note is the Q() function, which is typically used to
# process escaped ("quoted") heredoc text of C code fragments to be
# output. It strips an initial '|' preceded by optional spaces, and
# converts [[ and ]] to { and }.  This allows unmatched braces to be
# included in the C fragments without confusing text editors.
#
# Some other tasks have been moved out to various .pm files under ParseXS:
#
#  ParseXS::CountLines  provides tied handle methods for automatically
#                       injecting '#line' directives into output.
#
#  ParseXS::Eval        provides methods for evalling typemaps within
#                       an environment where suitable vars like $var and
#                       $arg have been up, but with nothing else in scope.
#
# ParseXS::Constants    defines a few constants used here, such the regex
#                       patterns used to detect a new XS keyword.
#
# ParseXS::Utilities    provides various private utility methods for
#                       the use of ParseXS, such as analysing C
#                       pre-processor directives.
#
# Note: when making changes to this module (or to its children), you
# can make use of the author/mksnapshot.pl tool to capture before and
# after snapshots of all .c files generated from .xs files (e.g. all the
# ones generated when building the perl distribution), to make sure that
# the only the changes to have appeared are ones which you expected.

# 5.8.0 is required for "use fields"
# 5.8.3 is required for "use Exporter 'import'"
use 5.008003;

use Cwd;
use Config;
use Exporter 'import';
use File::Basename;
use File::Spec;
use Symbol;

our $VERSION;
BEGIN {
  $VERSION = '3.53';
  require ExtUtils::ParseXS::Constants; ExtUtils::ParseXS::Constants->VERSION($VERSION);
  require ExtUtils::ParseXS::CountLines; ExtUtils::ParseXS::CountLines->VERSION($VERSION);
  require ExtUtils::ParseXS::Utilities; ExtUtils::ParseXS::Utilities->VERSION($VERSION);
  require ExtUtils::ParseXS::Eval; ExtUtils::ParseXS::Eval->VERSION($VERSION);
}
$VERSION = eval $VERSION if $VERSION =~ /_/;

use ExtUtils::ParseXS::Utilities qw(
  standard_typemap_locations
  trim_whitespace
  C_string
  valid_proto_string
  process_typemaps
  map_type
  standard_XS_defs
  C_func_signature
  analyze_preprocessor_statement
  set_cond
  Warn
  WarnHint
  current_line_number
  blurt
  death
  check_conditional_preprocessor_statements
  escape_file_for_line_directive
  report_typemap_failure
);

our @EXPORT_OK = qw(
  process_file
  report_error_count
  errors
);

##############################
# A number of "constants"
our $DIE_ON_ERROR;

our $AUTHOR_WARNINGS;
$AUTHOR_WARNINGS = ($ENV{AUTHOR_WARNINGS} || 0)
    unless defined $AUTHOR_WARNINGS;

our ($C_group_rex, $C_arg);

# Group in C (no support for comments or literals)
#
# DAPM 2024: I'm not entirely clear what this is supposed to match.
# It appears to match balanced and possibly nested [], {} etc, with
# similar but possibly unbalanced punctuation within. But the balancing
# brackets don't have to correspond: so [} is just as valid as [] or {},
# as is [{{{{] or even [}}}}}

$C_group_rex = qr/ [({\[]
             (?: (?> [^()\[\]{}]+ ) | (??{ $C_group_rex }) )*
             [)}\]] /x;

# $C_arg: match a chunk in C without comma at toplevel (no comments),
# i.e. a single arg within an XS signature, such as
#   foo = ','
#
# DAPM 2024. This appears to match zero, one or more of:
#   a random collection of non-bracket/quote/comma chars (e.g, a word or
#        number or 'int *foo' etc), or
#   a balanced(ish) nested brackets, or
#   a "string literal", or
#   a 'c' char literal
# So (I guess), it captures the next item in a function signature

$C_arg = qr/ (?: (?> [^()\[\]{},"']+ )
       |   (??{ $C_group_rex })
       |   " (?: (?> [^\\"]+ )
         |   \\.
         )* "        # String literal
              |   ' (?: (?> [^\\']+ ) | \\. )* ' # Char literal
       )* /xs;

# "impossible" keyword (multiple newline)
my $END = "!End!\n\n";
# Match an XS Keyword
my $BLOCK_regexp = '\s*(' . $ExtUtils::ParseXS::Constants::XSKeywordsAlternation . "|$END)\\s*:";


# All the valid fields of an ExtUtils::ParseXS hash object. The 'use
# fields' enables compile-time or run-time errors if code attempts to
# use a key which isn't listed here.

my $USING_FIELDS;

BEGIN {
  my @fields = (

  # I/O:

  'dir',                # The directory component of the main input file:
                        # we will normally chdir() to this directory.

  'in_pathname',        # The full pathname of the current input file.
  'in_filename',        # The filename      of the current input file.
  'in_fh',              # The filehandle    of the current input file.

  'IncludedFiles',      # Bool hash of INCLUDEd filenames (plus main file).

  'line',               # Array of lines recently read in and being processed.
                        # Typically one XSUB's worth of lines.
  'line_no',            # Array of line nums corresponding to @{$self->{line}}.

  'lastline',           # The contents of the line most recently read in
                        # but not yet processed.
  'lastline_no',        # The line number of lastline.


  # File-scoped configuration state:

  'config_RetainCplusplusHierarchicalTypes', # Bool: "-hiertype" switch
                        # value: it stops the typemap code doing
                        # $type =~ tr/:/_/.

  'config_WantLineNumbers', # Bool: (default true): "-nolinenumbers"
                        # switch not present: causes '#line NNN' lines to
                        # be emitted.

  'config_die_on_error',# Bool: make death() call die() rather than exit().
                        # It is set initially from the die_on_error option
                        # or from the $ExtUtils::ParseXS::DIE_ON_ERROR global.

  'config_author_warnings', # Bool: enables some warnings only useful to
                        # ParseXS.pm's authors rather than module creators.
                        # Set from Options or $AUTHOR_WARNINGS env var.

  'config_strip_c_func_prefix', # The discouraged -strip=... switch.

  'config_allow_argtypes', # Bool: (default true): "-noargtypes" switch not
                        # present. Enables ANSI-like arg types to be
                        # included in the XSUB signature.

  'config_allow_inout', # Bool: (default true): "-noinout" switch not present.
                        # Enables processing of IN/OUT/etc arg modifiers.

  'config_allow_exceptions', # Bool: (default false): the '-except' switch
                        # present.

  'config_optimize',    # Bool: (default true): "-nooptimize" switch not
                        # present. Enables optimizations (currently just
                        # the TARG one).


  # File-scoped parsing state:

  'typemaps_object',    # An ExtUtils::Typemaps object: the result of
                        # reading in the standard (or other) typemap.

  'error_count',        # Num: count of number of errors seen so far.

  'XS_parse_stack',     # Array of hashes: nested INCLUDE and #if states.

  'XS_parse_stack_top_if_idx', # Index of the current top-most '#if' on the
                        # XS_parse_stack. Note that it's not necessarily
                        # the top element of the stack, since that also
                        # includes elements for each INCLUDE etc.

  'MODULE_cname',       # MODULE canonical name (i.e. after s/\W/_/g).
  'PACKAGE_name',       # PACKAGE name.
  'PACKAGE_C_name',     #             Ditto, but with tr/:/_/.
  'PACKAGE_class',      #             Ditto, but with '::' appended.
  'PREFIX_pattern',     # PREFIX value, but after quotemeta().

  'map_overloaded_package_to_C_package', # Hash: for every PACKAGE which
                        # has at least one overloaded XSUB, add a
                        # (package name => package C name) entry.

  'map_package_to_fallback_string', # Hash: for every package, maps it to
                        # the overload fallback state for that package (if
                        # specified). Each value is one of the strings
                        # "&PL_sv_yes", "&PL_sv_no", "&PL_sv_undef".

  'proto_behaviour_specified', # Bool: prototype behaviour has been
                        # specified by the -prototypes switch and/or
                        # PROTOTYPE(S) keywords, so no need to warn.

  'PROTOTYPES_value',   # Bool: most recent PROTOTYPES: value. Defaults to
                        # the value of the "-prototypes" switch.

  'VERSIONCHECK_value', # Bool: most recent VERSIONCHECK: value. Defaults
                        # to the value of the "-noversioncheck" switch.

  'seen_INTERFACE_or_MACRO', # Bool: at least one INTERFACE/INTERFACE_MACRO
                        # has been seen somewhere.


  # File-scoped code-emitting state:

  'bootcode_early',     # Array of code lines to emit early in boot XSUB:
                        # typically newXS() calls

  'bootcode_later',     # Array of code lines to emit later on in boot XSUB:
                        # typically lines from a BOOT: XS file section


  # Per-XSUB parsing state:

  'xsub_seen_NO_RETURN',       # Bool: XSUB declared as NO_RETURN

  'xsub_seen_extern_C',        # Bool: XSUB return type is 'extern "C" ...'

  'xsub_seen_static',          # Bool: XSUB return type is 'static ...'

  'xsub_seen_PPCODE',          # Bool: XSUB has PPCODE    (peek-ahead)

  'xsub_seen_CODE',            # Bool: XSUB has CODE      (peek-ahead)

  'xsub_seen_INTERFACE',       # Bool: XSUB has INTERFACE (peek-ahead)

  'xsub_seen_ellipsis',        # Bool: XSUB signature has (   ,...)

  'xsub_seen_PROTOTYPE',       # Bool: PROTOTYPE keyword seen (for dup warning)
  
  'xsub_seen_SCOPE',           # Bool: SCOPE keyword seen (for dup warning).
  
  'xsub_seen_ALIAS',           # Bool: ALIAS keyword seen in this XSUB.

  'xsub_seen_INTERFACE_or_MACRO',# Bool: INTERFACE or INTERFACE_MACRO
                               # seen in this XSUB.
  
  'xsub_interface_macro',      # Str: current interface extraction macro.
  
  'xsub_interface_macro_set',  # Str: current interface setting macro.
  
  'xsub_prototype',            # Str: is set to either the global PROTOTYPES
                               #  values (0 or 1), or to what's been
                               #  overridden for this XSUB with PROTOTYPE
                               #    "0": DISABLE
                               #    "1": ENABLE
                               #    "2": empty prototype
                               #    other: a specific prototype.

  'xsub_SCOPE_enabled',        # Bool: SCOPE ENABLEd

  'xsub_return_type',          # Return type of the XSUB (whitespace-tidied).

  'xsub_class',                # Bool: the class part of the XSUB's
                               # function name (if any). May include
                               # 'const' prefix.

  'xsub_signature',            # Bool: the XSUB's (...) signature


  'xsub_func_name',            # The name of this XSUB        eg 'f'
  'xsub_func_full_perl_name',  # its full Perl function name  eg. 'Foo::Bar::f'
  'xsub_func_full_C_name',     # its full C function name     eg 'Foo__Bar__f'

  'xsub_map_argname_to_idx',   # Hash: Map argument names to indexes.

  'xsub_map_argname_to_type',  # Hash: map argument names to types, such as
                               # 'int *'. Names include special ones like
                               # 'RETVAL'.

  'xsub_map_argname_to_default', # Hash: map argument names to default
                               # expressions (if any).
  
  'xsub_map_argname_to_seen_type', # Hash: of bools: indicates an argument
                               # has a type specified in the signature
                               # (for duplicate spotting).
  
  'xsub_map_argname_to_in_out',# Hash: map argument names to 'OUTLIST' etc.
                               # Includes generated argument names like
                               # 'XSauto_length_of_foo' for 'length(foo)'.
  
  'xsub_map_argname_to_islength', # Hash of bools: indicates whether
                               # argument was declared as 'length(foo)'.
  
  'xsub_map_arg_idx_to_proto', # Array: maps argument index to prototype
                               # (such as '$'). Always populated, even if
                               # prototypes aren't being used for this
                               # XSUB.
  
  'xsub_CASE_condition',       # Most recent CASE string.

  'xsub_CASE_condition_count', # number of CASE keywords encountered.
                               # Zero indicates none encountered yet.

  'xsub_C_auto_function_signature', # The args to pass to any wrapped
                               # library function.  Basically join(','
                               # @args) but with '&' prepended for any OUT
                               # args.

  'xsub_map_overload_name_to_seen', # Hash: maps each overload method name
                               # (such as '<=>') to a boolean indicating
                               # whether that method has been listed by
                               # OVERLOAD (for duplicate spotting).
   
  'xsub_map_interface_name_short_to_original', # Hash: for each INTERFACE
                               # name, map the short (PREFIX removed) name
                               # to the original name.

  'xsub_attributes',           # Array of strings: all ATTRIBUTE keywords
                               # (possibly multiple space-separated
                               # keywords per string).

  'xsub_seen_RETVAL_in_CODE',  # Have seen 'RETVAL' within a CODE block.

  'xsub_map_alias_name_to_value', # Hash: maps ALIAS name to value.

  'xsub_map_alias_value_to_name_seen_hash', # Hash of hash of bools:
                               # indicates which alias names have been
                               # used for each value.

  'xsub_alias_clash_hinted',   # Bool: an ALIAS warning-hint has been emitted.


  # Per-XSUB INPUT section parsing state:

  'xsub_map_varname_to_seen_in_INPUT', # Hash: map argument names to a
                               # 'seen in INPUT' boolean (for duplicate
                               # spotting).
  
  'xsub_seen_THIS_in_INPUT',   # Seen var called 'THIS' in an INPUT section.

  'xsub_seen_RETVAL_in_INPUT', # Seen var called 'RETVAL' in an INPUT section.


  # Per-XSUB OUTPUT section parsing state:

  'xsub_seen_OUTPUT',          # Bool: have seen an OUTPUT section.

  'xsub_SETMAGIC_state',       # Bool: most recent value of SETMAGIC in an
                               # OUTPUT section.

  'xsub_map_varname_to_seen_in_OUTPUT', # Hash of bools: indicates which
                               # var names have been seen in an OUTPUT
                               # section.

  'xsub_seen_RETVAL_in_OUTPUT',# Seen a var called 'RETVAL' in an OUTPUT
                               # section.

  'xsub_RETVAL_typemap_code',  # Deferred typemap code from an OUTPUT section
                               # "RETVAL output-code" line (deferred
                               # because RETVAL code is emitted after any
                               # arg update code).


  # Per-XSUB code-emitting state:

  'xsub_deferred_code_lines',  # A multi-line string containing lines of
                               # code to be emitted *after* all INPUT and
                               # PREINIT keywords have been processed.

  );

  # do 'use fields', except: fields needs Hash::Util which is XS, which
  # needs us. So only 'use fields' on systems where Hash::Util has already
  # been built.
  if (eval 'require Hash::Util; 1;') {
    require 'fields.pm';
    $USING_FIELDS = 1;
    fields->import(@fields);
  }
}


sub new {
  my ExtUtils::ParseXS $self = shift;
  unless (ref $self) {
      if ($USING_FIELDS) {
        $self = fields::new($self);
      }
      else {
        $self = bless {} => $self;
      }
  }
  return $self;
}

our $Singleton = __PACKAGE__->new;


# The big method which does all the input parsing and output generation

sub process_file {
  my ExtUtils::ParseXS $self;
  # Allow for $package->process_file(%hash), $obj->process_file, and process_file()
  if (@_ % 2) {
    my $invocant = shift;
    $self = ref($invocant) ? $invocant : $invocant->new;
  }
  else {
    $self = $Singleton;
  }

  my %Options;

  {
    my %opts = @_;
    $self->{proto_behaviour_specified} = exists $opts{prototypes};

    # Set defaults.
    %Options = (
      argtypes        => 1,
      csuffix         => '.c',
      except          => 0,
      hiertype        => 0,
      inout           => 1,
      linenumbers     => 1,
      optimize        => 1,
      output          => \*STDOUT,
      prototypes      => 0,
      typemap         => [],
      versioncheck    => 1,
      in_fh           => Symbol::gensym(),
      die_on_error    => $DIE_ON_ERROR, # if true we die() and not exit()
                                        # after errors
      author_warnings    => $AUTHOR_WARNINGS,
      %opts,
    );
  }

  # Global Constants

  my ($Is_VMS, $VMS_SymSet);

  if ($^O eq 'VMS') {
    $Is_VMS = 1;
    # Establish set of global symbols with max length 28, since xsubpp
    # will later add the 'XS_' prefix.
    require ExtUtils::XSSymSet;
    $VMS_SymSet = ExtUtils::XSSymSet->new(28);
  }

  # XS_parse_stack is an array of hashes. Each hash records the current
  # state when a new file is INCLUDEd, or when within a (possibly nested)
  # file-scoped #if / #ifdef.
  # The 'type' field of each hash is either 'file' for INCLUDE, or 'if'
  # for within an #if / #endif.
  @{ $self->{XS_parse_stack} } = ({type => 'none'});

  $self->{bootcode_early} = [];
  $self->{bootcode_later} = [];

  # hash of package name => package C name
  $self->{map_overloaded_package_to_C_package} = {};
  # hashref of package name => fallback setting
  $self->{map_package_to_fallback_string}     = {};
  $self->{error_count}  = 0; # count

  # Most of the 1500 lines below uses these globals.  We'll have to
  # clean this up sometime, probably.  For now, we just pull them out
  # of %Options.  -Ken

  $self->{config_RetainCplusplusHierarchicalTypes} = $Options{hiertype};
  $self->{PROTOTYPES_value} = $Options{prototypes};
  $self->{VERSIONCHECK_value} = $Options{versioncheck};
  $self->{config_WantLineNumbers} = $Options{linenumbers};
  $self->{IncludedFiles} = {};

  $self->{config_die_on_error} = $Options{die_on_error};
  $self->{config_author_warnings} = $Options{author_warnings};

  die "Missing required parameter 'filename'" unless $Options{filename};

  $self->{in_pathname} = $Options{filename};
  ($self->{dir}, $self->{in_filename}) =
    (dirname($Options{filename}), basename($Options{filename}));
  $self->{in_pathname} =~ s/\\/\\\\/g;
  $self->{IncludedFiles}->{$Options{filename}}++;

  # Open the output file if given as a string.  If they provide some
  # other kind of reference, trust them that we can print to it.
  if (not ref $Options{output}) {
    open my($fh), "> $Options{output}" or die "Can't create $Options{output}: $!";
    $Options{outfile} = $Options{output};
    $Options{output} = $fh;
  }

  # Really, we shouldn't have to chdir() or select() in the first
  # place.  For now, just save and restore.
  my $orig_cwd = cwd();
  my $orig_fh = select();

  chdir($self->{dir});
  my $pwd = cwd();

  if ($self->{config_WantLineNumbers}) {
    my $csuffix = $Options{csuffix};
    my $cfile;
    if ( $Options{outfile} ) {
      $cfile = $Options{outfile};
    }
    else {
      $cfile = $Options{filename};
      $cfile =~ s/\.xs$/$csuffix/i or $cfile .= $csuffix;
    }
    tie(*PSEUDO_STDOUT, 'ExtUtils::ParseXS::CountLines', $cfile, $Options{output});
    select PSEUDO_STDOUT;
  }
  else {
    select $Options{output};
  }

  $self->{typemaps_object} = process_typemaps( $Options{typemap}, $pwd );

  $self->{config_strip_c_func_prefix} = $Options{s};
  $self->{config_allow_argtypes}      = $Options{argtypes};
  $self->{config_allow_inout}         = $Options{inout};
  $self->{config_allow_exceptions}    = $Options{except};
  $self->{config_optimize}            = $Options{optimize};

  # Identify the version of xsubpp used
  print <<EOM;
/*
 * This file was generated automatically by ExtUtils::ParseXS version $VERSION from the
 * contents of $self->{in_filename}. Do not edit this file, edit $self->{in_filename} instead.
 *
 *    ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

EOM


  print("#line 1 \"" . escape_file_for_line_directive($self->{in_pathname}) . "\"\n")
    if $self->{config_WantLineNumbers};

  # Open the input file (using $self->{in_filename} which
  # is a basename'd $Options{filename} due to chdir above)
  open($self->{in_fh}, '<', $self->{in_filename})
      or die "cannot open $self->{in_filename}: $!\n";

  # ----------------------------------------------------------------
  # Process the first (C language) half of the XS file, up until the first
  # MODULE: line
  # ----------------------------------------------------------------

  FIRSTMODULE:
  while (readline($self->{in_fh})) {
    if (/^=/) {
      my $podstartline = $.;
      do {
        if (/^=cut\s*$/) {
          # We can't just write out a /* */ comment, as our embedded
          # POD might itself be in a comment. We can't put a /**/
          # comment inside #if 0, as the C standard says that the source
          # file is decomposed into preprocessing characters in the stage
          # before preprocessing commands are executed.
          # I don't want to leave the text as barewords, because the spec
          # isn't clear whether macros are expanded before or after
          # preprocessing commands are executed, and someone pathological
          # may just have defined one of the 3 words as a macro that does
          # something strange. Multiline strings are illegal in C, so
          # the "" we write must be a string literal. And they aren't
          # concatenated until 2 steps later, so we are safe.
          #     - Nicholas Clark
          print("#if 0\n  \"Skipped embedded POD.\"\n#endif\n");
          printf("#line %d \"%s\"\n", $. + 1, escape_file_for_line_directive($self->{in_pathname}))
            if $self->{config_WantLineNumbers};
          next FIRSTMODULE;
        }

      } while (readline($self->{in_fh}));

      # At this point $. is at end of file so die won't state the start
      # of the problem, and as we haven't yet read any lines &death won't
      # show the correct line in the message either.
      die ("Error: Unterminated pod in $self->{in_filename}, line $podstartline\n")
        unless $self->{lastline};
    }

    last if ($self->{PACKAGE_name}, $self->{PREFIX_pattern}) =
      /^MODULE\s*=\s*[\w:]+(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/;

    print $_;
  }

  unless (defined $_) {
    warn "Didn't find a 'MODULE ... PACKAGE ... PREFIX' line\n";
    exit 0; # Not a fatal error for the caller process
  }

  print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
    if $self->{config_WantLineNumbers};

  standard_XS_defs();

  print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
    if $self->{config_WantLineNumbers};

  $self->{lastline}    = $_;
  $self->{lastline_no} = $.;

  $self->{XS_parse_stack_top_if_idx} = 0;

  my $cpp_next_tmp_define = 'XSubPPtmpAAAA';


  # ----------------------------------------------------------------
  # Main loop: for each iteration, read in a paragraph's worth of XSUB
  # definition or XS/CPP directives into @{ $self->{line} }, then (over
  # the course of a thousand lines of code) try to interpret those lines.
  # ----------------------------------------------------------------

 PARAGRAPH:
  while ($self->fetch_para()) {
    # Process and emit any initial C-preprocessor lines and blank
    # lines.  Also, keep track of #if/#else/#endif nesting, updating:
    #    $self->{XS_parse_stack}
    #    $self->{XS_parse_stack_top_if_idx}
    #    $self->{bootcode_early}
    #    $self->{bootcode_later}

    while (@{ $self->{line} } && $self->{line}->[0] !~ /^[^\#]/) {
      my $ln = shift(@{ $self->{line} });
      print $ln, "\n";
      next unless $ln =~ /^\#\s*((if)(?:n?def)?|elsif|else|endif)\b/;
      my $statement = $+;
      # update global tracking of #if/#else etc
      $self->analyze_preprocessor_statement($statement);
    }

    next PARAGRAPH unless @{ $self->{line} };

    if (   $self->{XS_parse_stack_top_if_idx}
        && !$self->{XS_parse_stack}->[$self->{XS_parse_stack_top_if_idx}]{varname})
    {
      # We are inside an #if, but have not yet #defined its xsubpp variable.
      #
      # At the start of every '#if ...' which is external to an XSUB,
      # we emit '#define XSubPPtmpXXXX 1', for increasing XXXX.
      # Later, when emitting initialisation code in places like a boot
      # block, it can then be made conditional via, e.g.
      #    #if XSubPPtmpXXXX
      #        newXS(...);
      #    #endif
      # So that only the defined XSUBs get added to the symbol table.
      print "#define $cpp_next_tmp_define 1\n\n";
      push(@{ $self->{bootcode_early} }, "#if $cpp_next_tmp_define\n");
      push(@{ $self->{bootcode_later} }, "#if $cpp_next_tmp_define\n");
      $self->{XS_parse_stack}->[$self->{XS_parse_stack_top_if_idx}]{varname}
          = $cpp_next_tmp_define++;
    }

    # This will die on something like
    #
    #   |    CODE:
    #   |        foo();
    #   |
    #   |#define X
    #   |        bar();
    #
    # due to the define starting at column 1 and being preceded by a blank
    # line: so the define and bar() aren't parsed as part of the CODE
    # block.

    $self->death(
      "Code is not inside a function"
        ." (maybe last function was ended by a blank line "
        ." followed by a statement on column one?)")
      if $self->{line}->[0] =~ /^\s/;

    # Initialize some per-XSUB instance variables:

    foreach my $member (qw(xsub_map_argname_to_idx
                           xsub_map_argname_to_type
                           xsub_map_argname_to_default
                           xsub_map_varname_to_seen_in_INPUT
                           xsub_map_argname_to_seen_type
                           xsub_map_argname_to_in_out
                           xsub_map_argname_to_islength
                          ))
    {
      $self->{$member} = {};
    }

    $self->{xsub_map_arg_idx_to_proto} = [];
    $self->{xsub_seen_PROTOTYPE}       = 0;
    $self->{xsub_seen_SCOPE}           = 0;
    $self->{xsub_seen_INTERFACE_or_MACRO} = 0;
    $self->{xsub_interface_macro}      = 'XSINTERFACE_FUNC';
    $self->{xsub_interface_macro_set}  = 'XSINTERFACE_FUNC_SET';
    $self->{xsub_prototype}            = $self->{PROTOTYPES_value};
    $self->{xsub_SCOPE_enabled}        = 0;
    $self->{xsub_map_overload_name_to_seen} = {};
    $self->{xsub_seen_NO_RETURN}            = 0;
    $self->{xsub_seen_extern_C}             = 0;
    $self->{xsub_seen_static}               = 0;
    $self->{xsub_seen_PPCODE}               = 0;
    $self->{xsub_seen_CODE}                 = 0;
    $self->{xsub_seen_INTERFACE}            = 0;
    $self->{xsub_seen_ellipsis}             = 0;
    $self->{xsub_class}                     = undef;
    $self->{xsub_signature}                 = undef;

    # used for emitting XSRETURN($XSRETURN_count) if > 0, or XSRETURN_EMPTY
    my $XSRETURN_count = 0;


    # Process next line

    $_ = shift(@{ $self->{line} });

    # ----------------------------------------------------------------
    # Process file-scoped keywords
    # ----------------------------------------------------------------

    # Note that MODULE and TYPEMAP will already have been processed by
    # fetch_para().
    #
    # This loop repeatedly: skips any blank lines and then calls
    # $self->FOO_handler() if it finds any of the file-scoped keywords
    # in the passed pattern. $_ is updated and is available to the
    # handlers.
    #
    # Each of the handlers acts on just the current line, apart from the
    # INCLUDE ones, which open a new file and skip any leading blank
    # lines.

    while (my $kwd = $self->check_keyword("REQUIRE|PROTOTYPES|EXPORT_XSUB_SYMBOLS|FALLBACK|VERSIONCHECK|INCLUDE(?:_COMMAND)?|SCOPE")) {
      my $method = $kwd . "_handler";
      $self->$method($_);
      next PARAGRAPH unless @{ $self->{line} };
      $_ = shift(@{ $self->{line} });
    }

    if ($self->check_keyword("BOOT")) {
      $self->BOOT_handler();
      # BOOT: is a file-scoped keyword which consumes all the lines
      # following it in the current paragraph (as opposed to just until
      # the next keyword, like CODE: etc).
      next PARAGRAPH;
    }

    # ----------------------------------------------------------------
    # Process the presumed start of an XSUB
    # ----------------------------------------------------------------

    # Whitespace-tidy the line containing the return type plus possibly
    # the function name and arguments too (The latter was probably an
    # unintended side-effect of later allowing the return type and
    # function to be on the same line.)
    ($self->{xsub_return_type}) = ExtUtils::Typemaps::tidy_type($_);

    $self->{xsub_seen_NO_RETURN} = 1
      if $self->{xsub_return_type} =~ s/^NO_OUTPUT\s+//;

    # Allow one-line declarations. This splits a single line like:
    #    int foo(....)
    # into the two lines:
    #    int
    #    foo(...)
    # Note that this splits both K&R-style 'foo(a, b)' and ANSI-style
    # 'foo(int a, int b)'. I don't know whether the former was intentional.
    # As of 5.40.0, the docs don't suggest that a 1-line K&R is legal. Was
    # added by 11416672a16, first appeared in 5.6.0.
    #
    # NB: $self->{config_allow_argtypes} is false if xsubpp was invoked
    # with -noargtypes

    unshift @{ $self->{line} }, $2
      if $self->{config_allow_argtypes}
        and $self->{xsub_return_type} =~ s/^(.*?\w.*?)\s*\b(\w+\s*\(.*)/$1/s;

    # a function definition needs at least 2 lines
    $self->blurt("Error: Function definition too short '$self->{xsub_return_type}'"), next PARAGRAPH
      unless @{ $self->{line} };

    $self->{xsub_seen_extern_C} = 1
                          if $self->{xsub_return_type} =~ s/^extern "C"\s+//;
    $self->{xsub_seen_static}   = 1
                          if $self->{xsub_return_type} =~ s/^static\s+//;

    {
      my $func_header = shift(@{ $self->{line} });

      # Decompose the function declaration: match a line like
      #   Some::Class::foo_bar(  args  ) const ;
      #   -----------  -------   ----    ----- --
      #       $1        $2        $3      $4   $5
      #
      # where everything except $2 and $3 are optional and the 'const'
      # is for C++ functions.

      $self->blurt("Error: Cannot parse function definition from '$func_header'"), next PARAGRAPH
        unless $func_header =~ /^(?:([\w:]*)::)?(\w+)\s*\(\s*(.*?)\s*\)\s*(const)?\s*(;\s*)?$/s;

      ($self->{xsub_class}, $self->{xsub_func_name}, $self->{xsub_signature})
          = ($1, $2, $3);

      $self->{xsub_class} = "$4 $self->{xsub_class}" if $4;

      ($self->{xsub_func_full_perl_name} = $self->{xsub_func_name}) =~
          s/^($self->{PREFIX_pattern})?/$self->{PACKAGE_class}/;

      my $clean_func_name;
      ($clean_func_name = $self->{xsub_func_name}) =~ s/^$self->{PREFIX_pattern}//;
      $self->{xsub_func_full_C_name} = "$self->{PACKAGE_C_name}_$clean_func_name";
      if ($Is_VMS) {
        $self->{xsub_func_full_C_name} = $VMS_SymSet->addsym( $self->{xsub_func_full_C_name} );
      }

      # At this point, supposing that the input so far was:
      #
      #   MODULE = ... PACKAGE = BAR::BAZ PREFIX = foo_
      #   int
      #   Some::Class::foo_bar(  args  ) const ;
      #
      # we should have:
      #
      # $self->{xsub_class}               'const Some::Class'
      # $self->{xsub_signature}            'arg1, arg2, arg3'
      # $self->{xsub_func_name}           'foo_bar'
      # $self->{xsub_func_full_perl_name} 'BAR::BAZ::bar'
      # $self->{xsub_func_full_C_name}    'BAR__BAZ_bar';


      # Check for a duplicate function definition, but ignoring multiple
      # definitions within the branches of an #if/#else/#endif
      for my $tmp (@{ $self->{XS_parse_stack} }) {
        next unless defined $tmp->{functions}{ $self->{xsub_func_full_C_name} };
        Warn( $self, "Warning: duplicate function definition '$clean_func_name' detected");
        last;
      }
    }

    # mark C function name as used
    $self->{XS_parse_stack}->[$self->{XS_parse_stack_top_if_idx}]{functions}{ $self->{xsub_func_full_C_name} }++;

    # initialise more per-XSUB state
    delete $self->{xsub_map_alias_name_to_value};           # ALIAS: ...
    delete $self->{xsub_map_alias_value_to_name_seen_hash};
                                            # INTERFACE: foo bar
    %{ $self->{xsub_map_interface_name_short_to_original} } = ();
    @{ $self->{xsub_attributes} }  = ();    # ATTRS:     lvalue method
    $self->{xsub_SETMAGIC_state} = 1;       # SETMAGIC:  ENABLE


    # ----------------------------------------------------------------
    # Do initial processing of the XSUB's signature - $self->{xsub_signature}
    #
    # Split the signature on commas into @args while allowing for things
    # like (a = ",", b), and extract any IN/OUT/etc prefix.
    #
    # The final list of @args will have any surrounding white space and
    # any IN/OUT prefix stripped.
    #
    # Any ANSI-style types and/or length()s, e.g. (char *s, int length(s)),
    # won't be directly processed, but instead will be copied into the
    # arrays @fake_INPUT_pre and @fake_INPUT, later to be injected into
    # a fake "INPUT:" block following any real PREINIT: and/or INPUT:
    # blocks. So, from the rest of the parser's perspective, it thinks
    # that
    #
    #    int foo(char *s, int length(s))
    #       ....
    #
    # was actually written kind of like
    #
    #    int foo(s)
    #       ....
    #       INPUT:
    #        int length(s)
    #        char *s
    #
    # (Yes, this is an ugly hack.)
    #
    # ----------------------------------------------------------------
    #
    # Given a signature (i.e. $self->{xsub_signature}) like:
    #
    #    OUT     char *s,             \
    #            int   length(s),     \
    #    OUTLIST int   size     = 10)
    #
    # then this section will set various vars and object fields like the
    # following:
    #
    #  @args           = ('s',  'XSauto_length_of_s', 'size= 10');
    #
    #  @fake_INPUT_pre = ('int   length(s)');
    #  @fake_INPUT     = ('char *s',
    #                     'int   size');
    #
    # Vars which aren't passed from perl call args:
    #
    #  $only_C_inlist{XSauto_length_of_s} = 1; # because of length()
    #  $only_C_inlist{'size= 10'}         = 1; # because of OUTLIST
    #
    #  @OUTLIST_vars = ('size');              # OUTLIST vars
    #
    # Parameters which included a C type:
    #
    #  $self->{xsub_map_argname_to_seen_type}{s}++;
    #  $self->{xsub_map_argname_to_seen_type}{XSauto_length_of_s}++;
    #  $self->{xsub_map_argname_to_seen_type}{size}++;
    #
    #  # IN_OUT, OUT etc vars except IN
    #  $self->{xsub_map_argname_to_in_out}{s}    = 'OUT';
    #  $self->{xsub_map_argname_to_in_out}{size} = 'OUTLIST';
    #
    # XXX Note that 'length(s)' should only be used with a type prefix.
    # Otherwise it will probably be mishandled. We should really detect
    # this and warn/die for other cases.
    #
    # ----------------------------------------------------------------

    # remove line continuation chars (\)
    $self->{xsub_signature} =~ s/\\\s*/ /g;

    my @args;

    my (@fake_INPUT_pre);       # For length(var) generated variables
    my (@fake_INPUT);           # For normal parameters

    my %only_C_inlist;          # Not in the signature of Perl function
    my @OUTLIST_vars;           # list of vars declared as OUTLIST



    if ($self->{config_allow_argtypes} and $self->{xsub_signature} =~ /\S/) {
      # Process signatures of both ANSI and K&R forms, i.e. of the forms
      # foo(OUT a, b) and foo(OUT int a, int b)

      my $args = "$self->{xsub_signature} ,";
      use re 'eval';

      if ($args =~ /^( (??{ $C_arg }) , )* $ /x) {
        # If the arguments are capable of being split by using the fancy
        # regex, do so. This splits the args on commas, but can handle
        # things like foo(a = ",", b)
        @args = ($args =~ /\G ( (??{ $C_arg }) ) , /xg);

        no re 'eval';

        for ( @args ) {
          #  For each arg in @args, alias to $_ (and sometimes modify),
          #  then extract the components of the arg. An arg is of the
          #  general form:
          #
          #   pre var = default
          #
          # where:
          #   =default is optional,
          #   pre      is optional and is something like a C type and/or
          #            IN_OUT etc
          #   var      is required and is in one of two forms:
          #              foo
          #              length(foo)
          #            where the second is a fake arg, not passed from
          #            perl, but passed to the wrapped C function as the
          #            length of the named arg

          s/^\s+//;
          s/\s+$//;
          my ($arg, $default) = ($_ =~ m/ ( [^=]* ) ( (?: = .* )? ) /x);
          my ($pre, $name_or_lenname) = ($arg =~ /(.*?) \s*
                             \b ( \w+ | length\( \s*\w+\s* \) )
                             \s* $ /x);
          next unless defined($pre) && length($pre);

          # Process $pre: either a C type or IN_OUT etc (or both)

          my $out_type = '';
          if (    $self->{config_allow_inout}
              and s/^(IN|IN_OUTLIST|OUTLIST|OUT|IN_OUT)\b\s*//)
          {
            my $type = $1;
            $out_type = $type if $type ne 'IN';
            $arg =~ s/^(IN|IN_OUTLIST|OUTLIST|OUT|IN_OUT)\b\s*//;
            $pre =~ s/^(IN|IN_OUTLIST|OUTLIST|OUT|IN_OUT)\b\s*//;
          }

          my $is_length;

          if ($name_or_lenname =~ /^length\( \s* (\w+) \s* \)\z/x) {
            $name_or_lenname = "XSauto_length_of_$1";
            $is_length = 1;
            die "Default value on length() argument: '$_'"
              if length $default;
          }

          if (length $pre or $is_length) { # 'int foo' or 'length(foo)'
            if ($is_length) {
              push @fake_INPUT_pre, $arg;
            }
            else {
              push @fake_INPUT, $arg;
            }

            $self->{xsub_map_argname_to_seen_type}->{$name_or_lenname}++;
            $_ = "$name_or_lenname$default"; # Assigns to @args
          }

          $only_C_inlist{$_} = 1 if $out_type eq "OUTLIST" or $is_length;
          push @OUTLIST_vars, $name_or_lenname if $out_type =~ /OUTLIST$/;
          $self->{xsub_map_argname_to_in_out}->{$name_or_lenname}
              = $out_type if $out_type;
        }
      }
      else {
        no re 'eval';
        # This is the fallback argument-splitting path for when the $C_arg
        # regex doesn't work. This code path should ideally never be
        # reached, and indicates a design weakness in $C_arg.
        # It assumes there's nothing fancy like types or IN/OUT.
        @args = split(/\s*,\s*/, $self->{xsub_signature});
        Warn( $self, "Warning: cannot parse argument list '$self->{xsub_signature}', fallback to split");
      }
    }
    else {
      # Process empty args, or args in presence of -noargtypes.  The
      # latter means that only K&R form is recognised, e.g. foo(OUT a, b)
      # Only IN/OUT prefixes are processed.

      @args = split(/\s*,\s*/, $self->{xsub_signature});

      for (@args) {
        if (    $self->{config_allow_inout}
            and s/^(IN|IN_OUTLIST|OUTLIST|IN_OUT|OUT)\b\s*//)
        {
          my $out_type = $1;
          next if $out_type eq 'IN';
          $only_C_inlist{$_} = 1 if $out_type eq "OUTLIST";
          if ($out_type =~ /OUTLIST$/) {
              push @OUTLIST_vars, undef;
          }
          $self->{xsub_map_argname_to_in_out}->{$_} = $out_type;
        }
      }
    }

    # ----------------------------------------------------------------
    # Do post-processing of the sxub's signature parameters:
    # handle methods, '...', default values, mapping from param# to arg#.
    # ----------------------------------------------------------------

    # For C++ type methods, add fake method arg to beginning
    if (defined($self->{xsub_class})) {
      my $arg0 = (  ($self->{xsub_seen_static}
                  or $self->{xsub_func_name} eq 'new')
          ? "CLASS" : "THIS");
      unshift(@args, $arg0);
    }

    my $args_count = 0;
    my $report_args = ''; # the arg's description as used by croak()
    my $min_arg_count;

    {
      my $optional_args_count = 0;
      my @map_param_idx_to_arg_idx = ();

      foreach my $i (0 .. $#args) {

        # Handle trailing ellipsis, e.g. (foo, bar, ...)
        # XXX this code deletes any embedded '...' from any of the other args
        # too, which is almost certainly wrong.
        if ($args[$i] =~ s/\.\.\.//) {
          $self->{xsub_seen_ellipsis} = 1;
          if ($args[$i] eq '' && $i == $#args) {
            $report_args .= ", ...";
            pop(@args);
            last;
          }
        }

        # @map_param_idx_to_arg_idx maps param index to expected arg index,
        # with undef indicating a fake parameter that isn't assigned
        # to an arg
        if ($only_C_inlist{$args[$i]}) {
          push @map_param_idx_to_arg_idx, undef;
        }
        else {
          push @map_param_idx_to_arg_idx, ++$args_count;
            $report_args .= ", $args[$i]";
        }

        # process default values, e.g. (int foo = 1)
        if ($args[$i] =~ /^([^=]*[^\s=])\s*=\s*(.*)/s) {
          $optional_args_count++;
          $args[$i] = $1; # delete the '= ...' from $arg[$i]
          $self->{xsub_map_argname_to_default}->{$args[$i]} = $2;
          $self->{xsub_map_argname_to_default}->{$args[$i]} =~ s/"/\\"/g; # escape double quotes
        }

        $self->{xsub_map_arg_idx_to_proto}->[$i+1] = '$'
            unless $only_C_inlist{$args[$i]};

      } # end foreach $i


      $min_arg_count = $args_count - $optional_args_count;
      $report_args =~ s/"/\\"/g;
      $report_args =~ s/^,\s+//;

      # The args to pass to the wrapped library function. Basically
      # join(',' @args) but with '&' prepended for any *OUT* args.
      $self->{xsub_C_auto_function_signature} =
          $self->C_func_signature(\@args, $self->{xsub_class});

      # map argument names to indexes
      @{ $self->{xsub_map_argname_to_idx} }{@args} = @map_param_idx_to_arg_idx;
    }


    # ----------------------------------------------------------------
    # Peek ahead into the body of the XSUB looking for various conditions
    # that are needed to be known early.
    # ----------------------------------------------------------------

    $self->{xsub_seen_ALIAS}  = grep(/^\s*ALIAS\s*:/,  @{ $self->{line} });

    $self->{xsub_seen_PPCODE}   = !!grep(/^\s*PPCODE\s*:/,    @{$self->{line}});
    $self->{xsub_seen_CODE}     = !!grep(/^\s*CODE\s*:/,      @{$self->{line}});
    $self->{xsub_seen_INTERFACE}= !!grep(/^\s*INTERFACE\s*:/, @{$self->{line}});

    # Horrible 'void' return arg count hack.
    #
    # Until about 1996, xsubpp always emitted 'XSRETURN(1)', even for a
    # void XSUB. This was fixed for CODE-less void XSUBs simply by
    # actually honouring the 'void' type and emitting 'XSRETURN_EMPTY'
    # instead. However, for CODE blocks, the documentation had already
    # endorsed a coding style along the lines of
    #
    #    void
    #    foo(...)
    #       CODE:
    #          ST(0) = sv_newmortal();
    #
    # i.e. the XSUB returns an SV even when the return type is 'void'.
    # In 2024 there is still lots of code of this style out in the wild,
    # even in the distros bundled with perl.
    #
    # So honouring the void type here breaks lots of existing code. Thus
    # this hack specifically looks for: void XSUBs with a CODE block that
    # appears to put stuff on the stack via 'ST(n)=' or 'XST_m()', and if
    # so, emits 'XSRETURN(1)' rather than the 'XSRETURN_EMPTY' implied by
    # the 'void' return type.
    #
    # XXX this searches the whole XSUB, not just the CODE: section
    {
      my $EXPLICIT_RETURN = ($self->{xsub_seen_CODE} &&
            ("@{ $self->{line} }" =~ /(\bST\s*\([^;]*=) | (\bXST_m\w+\s*\()/x ));
      $XSRETURN_count = 1 if $EXPLICIT_RETURN;
    }


    # ----------------------------------------------------------------
    # Emit initial C code for the XSUB
    # ----------------------------------------------------------------

    {
      my $extern = $self->{xsub_seen_extern_C} ? qq[extern "C"] : "";

    # Emit function header
      print Q(<<"EOF");
        |$extern
        |XS_EUPXS(XS_$self->{xsub_func_full_C_name}); /* prototype to pass -Wmissing-prototypes */
        |XS_EUPXS(XS_$self->{xsub_func_full_C_name})
        |[[
        |    dVAR; dXSARGS;
EOF
    }

    print Q(<<"EOF") if $self->{xsub_seen_ALIAS};
      |    dXSI32;
EOF

    print Q(<<"EOF") if $self->{xsub_seen_INTERFACE};
      |    dXSFUNCTION($self->{xsub_return_type});
EOF


    {
      # the code to emit to determine whether the correct number of argument
      # have been passed
      my $condition_code =
        set_cond($self->{xsub_seen_ellipsis}, $min_arg_count, $args_count);

      print Q(<<"EOF") if $self->{config_allow_exceptions}; # "-except" cmd line switch
        |    char errbuf[1024];
        |    *errbuf = '\\0';
EOF

      if ($condition_code) {
        print Q(<<"EOF");
          |    if ($condition_code)
          |       croak_xs_usage(cv,  "$report_args");
EOF
      }
      else {
        # cv and items likely to be unused
        print Q(<<"EOF");
          |    PERL_UNUSED_VAR(cv); /* -W */
          |    PERL_UNUSED_VAR(items); /* -W */
EOF
      }
    }

    # gcc -Wall: if an XSUB has PPCODE, it is possible that none of ST,
    # XSRETURN or XSprePUSH macros are used.  Hence 'ax' (setup by
    # dXSARGS) is unused.
    # XXX: could breakup the dXSARGS; into dSP;dMARK;dITEMS
    # but such a move could break third-party extensions
    print Q(<<"EOF") if $self->{xsub_seen_PPCODE};
      |    PERL_UNUSED_VAR(ax); /* -Wall */
EOF

    print Q(<<"EOF") if $self->{xsub_seen_PPCODE};
      |    SP -= items;
EOF

    # ----------------------------------------------------------------
    # Now prepare to process the various keyword lines/blocks of an XSUB
    # body
    # ----------------------------------------------------------------

    # Initialise any CASE: state
    $self->{xsub_CASE_condition_count} = 0;
    $self->{xsub_CASE_condition} = ''; # last CASE: conditional

    # Append a fake EOF-keyword line
    push(@{ $self->{line} }, "$END:");
    push(@{ $self->{line_no} }, $self->{line_no}->[-1]);

    $_ = '';

    # Check all the @{ $self->{line}} lines for balance: all the
    # #if, #else, #endif etc within the XSUB should balance out.
    check_conditional_preprocessor_statements();

    # ----------------------------------------------------------------
    # Each iteration of this loop will process 1 optional CASE: line,
    # followed by all the other blocks. In the absence of a CASE: line,
    # this loop is only iterated once.
    # ----------------------------------------------------------------

    while (@{ $self->{line} }) {

      # For a 'CASE: foo' line, emit an 'else if (foo)' style line of C.
      # Note that each CASE: can precede multiple keyword blocks.
      $self->CASE_handler($_) if $self->check_keyword("CASE");

      # ----------------------------------------------------------------
      # Handle all the XSUB parts which generate declarations
      # ----------------------------------------------------------------

      # Emit opening brace. With cmd-line switch "-except", prefix it
      # with 'TRY'
      {
        my $try = $self->{config_allow_exceptions} ? ' TRY' : '';
        print Q(<<"EOF");
          |   $try [[
EOF
      }

      # First, initialize variables manipulated by INPUT_handler().
      $self->{xsub_seen_THIS_in_INPUT} = 0;    # seen a THIS var
      $self->{xsub_seen_RETVAL_in_INPUT} = 0;  # seen a RETVAL var
      $self->{xsub_deferred_code_lines} = "";  # lines to be emitted after
                                               # PREINIT/INPUT
                        #
                        # keep track of which vars have been seen
      %{ $self->{xsub_map_varname_to_seen_in_INPUT} } = ();
      $self->{xsub_seen_RETVAL_in_OUTPUT} = 0; # RETVAL seen in OUTPUT section

      # Process any implicit INPUT section.
      $self->INPUT_handler($_);

      # keywords which can appear anywhere in an XSUB
      my $generic_xsub_keys =
        $ExtUtils::ParseXS::Constants::generic_xsub_keywords_alt;

      # Process as many keyword lines/blocks as can be found which match
      # the pattern. At this stage it's looking for (possibly multiple)
      # INPUT and/or PREINIT blocks, plus any generic XSUB keywords.
      $self->process_keywords(
        "C_ARGS|INPUT|INTERFACE_MACRO|PREINIT|SCOPE|$generic_xsub_keys");

      print Q(<<"EOF") if $self->{xsub_SCOPE_enabled};
        |   ENTER;
        |   [[
EOF

      # Emit a 'char * CLASS' or 'Foo::Bar *THIS' declaration if needed

      if (!$self->{xsub_seen_THIS_in_INPUT} && defined($self->{xsub_class})) {
        if ($self->{xsub_seen_static} or $self->{xsub_func_name} eq 'new') {
          print "\tchar *";
          $self->{xsub_map_argname_to_type}->{"CLASS"} = "char *";
          $self->generate_init( {
            type          => "char *",
            num           => 1,
            var           => "CLASS",
            printed_name  => undef,
          } );
        }
        else {
          print "\t" . $self->map_type("self->{xsub_$}class *");
          $self->{xsub_map_argname_to_type}->{"THIS"} = "self->{xsub_$}class *";
          $self->generate_init( {
            type          => "$self->{xsub_class} *",
            num           => 1,
            var           => "THIS",
            printed_name  => undef,
          } );
        }
      }

      # These are set later if OUTPUT is found and/or CODE using RETVAL
      $self->{xsub_seen_OUTPUT} = $self->{xsub_seen_RETVAL_in_CODE} = 0;

      # $implicit_OUTPUT_RETVAL (bool) indicates that a bodiless XSUB has
      # a non-void return value, so needs to return RETVAL; or to put it
      # another way, it indicates an implicit "OUTPUT:\n\tRETVAL".
      my $implicit_OUTPUT_RETVAL;

      # do code
      if (/^\s*NOT_IMPLEMENTED_YET/) {
        print "\n\tPerl_croak(aTHX_ \"$self->{xsub_func_full_perl_name}: not implemented yet\");\n";
        $_ = '';
      }
      else {

        # Do any variable declarations associated with having a return value
        if ($self->{xsub_return_type} ne "void") {

          # Emit the RETVAL variable declaration.
          print "\t" . $self->map_type($self->{xsub_return_type}, 'RETVAL') . ";\n"
            if !$self->{xsub_seen_RETVAL_in_INPUT};
          $self->{xsub_map_argname_to_idx}->{"RETVAL"} = 0;
          $self->{xsub_map_argname_to_type}->{"RETVAL"} = $self->{xsub_return_type};

          # If it looks like the output typemap code can be hacked to
          # use a TARG to optimise returning the value (rather than
          # creating a mortal each time), declare the TARG. (dXSTARG
          # checks whether the ENTERSUB op has a TARG, and if not, creates
          # a mortal instead for TARG).
          my $outputmap = $self->{typemaps_object}->get_outputmap( ctype => $self->{xsub_return_type} );
          print "\tdXSTARG;\n"
            if $self->{config_optimize} and $outputmap and $outputmap->targetable;
        }

        # Process the synthetic INPUT lines generated earlier when
        # processing ANSI-ish parameters in the XSUB's signature (i.e.
        # those which have a type and/or /IN/OUT/etc).
        if (@fake_INPUT or @fake_INPUT_pre) {
          unshift @{ $self->{line} }, @fake_INPUT_pre, @fake_INPUT, $_;
          $_ = "";
          $self->INPUT_handler($_, 1); # 1 implies synthetic
        }

        # ----------------------------------------------------------------
        # All C variable declarations have now been emitted. It's now time
        # to emit any code which goes before the main body (i.e. the CODE:
        # etc or the implicit call to the wrapped function).
        # ----------------------------------------------------------------

        # Emit any code which has been deferred until all declarations
        # have been done. This is typically INPUT typemaps which don't
        # start with a simple '$var =' and so would not have been emitted
        # at the variable declaration stage.
        print $self->{xsub_deferred_code_lines};

        # Process as many keyword lines/blocks as can be found which match
        # the pattern. At this stage it's looking for (possibly multiple)
        # INIT blocks, plus any generic XSUB keywords.
        $self->process_keywords(
        "C_ARGS|INIT|INTERFACE|INTERFACE_MACRO|$generic_xsub_keys");

        # ----------------------------------------------------------------
        # Time to emit the main body of the XSUB. Either the real code
        # from a CODE: or PPCODE: block, or the implicit call to the
        # wrapped function
        # ----------------------------------------------------------------

        if ($self->check_keyword("PPCODE")) {
          # Handle PPCODE: just emit the code block and then code to do
          # PUTBACK and return. The user of PPCODE is supposed to have
          # done all the return stack manipulation themselves.
          # Note that PPCODE blocks often include a XSRETURN(1) or
          # similar, so any final code we emit after that is in danger of
          # triggering a "statement is unreachable" warning.

          $self->print_section();
          $self->death("PPCODE must be last thing") if @{ $self->{line} };

          print "\tLEAVE;\n" if $self->{xsub_SCOPE_enabled};

          # Suppress "statement is unreachable" warning on HPUX
          print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
                "#pragma diag_suppress 2111\n",
                "#endif\n"
            if $^O eq "hpux";

          print "\tPUTBACK;\n\treturn;\n";

          # Suppress "statement is unreachable" warning on HPUX
          print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
                "#pragma diag_default 2111\n",
                "#endif\n"
            if $^O eq "hpux";

        }
        elsif ($self->check_keyword("CODE")) {
          # Handle CODE: just emit the code block and check if it
          # includes "RETVAL". This check is for later use to warn if
          # RETVAL is used but no OUTPUT block is present.
          my $consumed_code = $self->print_section();
          if ($consumed_code =~ /\bRETVAL\b/) {
            $self->{xsub_seen_RETVAL_in_CODE} = 1;
          }

        }
        elsif (    defined($self->{xsub_class})
               and $self->{xsub_func_name} eq "DESTROY")
        {
          # Emit a default body for a C++ DESTROY method: "delete THIS;"
          print "\n\t";
          print "delete THIS;\n";

        }
        else {
          # Emit a default body: this will be a call to the function being
          # wrapped. Typically:
          #    RETVAL = foo(args);
          # with the function name being appropriately modified when it's
          # a C++ new() method etc.

          print "\n\t";

          if ($self->{xsub_return_type} ne "void") {
            print "RETVAL = ";
            $implicit_OUTPUT_RETVAL = 1;
          }

          if ($self->{xsub_seen_static}) {
            # it has a return type of 'static foo'
            if ($self->{xsub_func_name} eq 'new') {
              $self->{xsub_func_name} = "$self->{xsub_class}";
            }
            else {
              print "$self->{xsub_class}::";
            }
          }
          elsif (defined($self->{xsub_class})) {
            if ($self->{xsub_func_name} eq 'new') {
              $self->{xsub_func_name} .= " $self->{xsub_class}";
            }
            else {
              print "THIS->";
            }
          }

          # Handle "xsubpp -s=strip_prefix" hack
          my $strip = $self->{config_strip_c_func_prefix};
          $self->{xsub_func_name} =~ s/^\Q$strip//
            if defined $strip;

          $self->{xsub_func_name} = 'XSFUNCTION'
                    if $self->{xsub_seen_INTERFACE_or_MACRO};
          print "$self->{xsub_func_name}($self->{xsub_C_auto_function_signature});\n";

        } # End: PPCODE: or CODE: or a default body

      } # End: else NOT_IMPLEMENTED_YET

      # ----------------------------------------------------------------
      # Main body of function has now been emitted.
      # Next, process any POSTCALL or OUTPUT blocks,
      # plus some post-processing of OUTPUT.
      # ----------------------------------------------------------------

      # Initialise some state, which may be updated by calls to
      # OUTPUT_handler():
      $self->{xsub_seen_RETVAL_in_OUTPUT} = 0;  # bool: RETVAL seen in OUTPUT section;
      undef $self->{xsub_RETVAL_typemap_code} ; # code to set RETVAL (from
                                                # OUTPUT section);

      # If SXUB was declared as NO_OUTPUT, then:
      # - we don't need to return RETVAL to the caller, even if the
      #   auto-generated call to the library function indicates it was seen
      #   ($implicit_OUTPUT_RETVAL).
      # - Also from this point on, treat the (non-void) return type as void.
      ($implicit_OUTPUT_RETVAL, $self->{xsub_return_type}) =
                                  (0, 'void') if $self->{xsub_seen_NO_RETURN};

      # used by OUTPUT_handler() to detect duplicate OUTPUT var lines
      undef %{ $self->{xsub_map_varname_to_seen_in_OUTPUT} };

      # Process as many keyword lines/blocks as can be found which match
      # the pattern.
      # XXX POSTCALL is documented to precede OUTPUT, but here we allow
      # them in any order and multiplicity.
      $self->process_keywords("OUTPUT|POSTCALL|$generic_xsub_keys");

      # A CODE section using RETVAL must also have an OUTPUT entry
      if (        $self->{xsub_seen_RETVAL_in_CODE}
          and not $self->{xsub_seen_OUTPUT}
          and     $self->{xsub_return_type} ne 'void')
      {
        $self->Warn("Warning: Found a 'CODE' section which seems to be using 'RETVAL' but no 'OUTPUT' section.");
      }

      # Process any OUT vars: i.e. vars that are declared OUT in
      # the XSUB's signature rather than in an OUTPUT section.

      for my $var (grep $self->{xsub_map_argname_to_in_out}->{$_} =~ /OUT$/,
                            sort keys %{ $self->{xsub_map_argname_to_in_out} })
      {
        $self->generate_output( {
            type        => $self->{xsub_map_argname_to_type}->{$var},
            num         => $self->{xsub_map_argname_to_idx}->{$var},
            var         => $var,
            do_setmagic => $self->{xsub_SETMAGIC_state},
            do_push     => undef,
          }
        );
      }

      # If there are any OUTLIST vars to be pushed, first extend the
      # stack, to fit all OUTLIST vars + RETVAL
      my $outlist_count = @OUTLIST_vars;
      if ($outlist_count) {
        my $ext = $outlist_count;
        ++$ext if $self->{xsub_seen_RETVAL_in_OUTPUT} || $implicit_OUTPUT_RETVAL;
        print "\tXSprePUSH;";
        print "\tEXTEND(SP,$ext);\n";
      }

      # ----------------------------------------------------------------
      # All OUTPUT done; now handle an implicit or deferred RETVAL.
      # OUTPUT_handler() will have skipped any RETVAL line, just setting
      # $self->{xsub_seen_RETVAL_in_OUTPUT} to true and setting
      # $self->{xsub_RETVAL_typemap_code} to the
      # overridden typemap code on the RETVAL line, if any.
      # Also, $implicit_OUTPUT_RETVAL indicates that an implicit RETVAL
      # should be generated, due to a non-void CODE-less XSUB.
      # ----------------------------------------------------------------

      if (   $self->{xsub_seen_RETVAL_in_OUTPUT}
          && $self->{xsub_RETVAL_typemap_code})
      {
        # Deferred RETVAL with overridden typemap code. Just emit as-is.
        print "\t$self->{xsub_RETVAL_typemap_code}\n";
        print "\t++SP;\n" if $outlist_count;
      }
      elsif ($self->{xsub_seen_RETVAL_in_OUTPUT} || $implicit_OUTPUT_RETVAL) {
        # Deferred or implicit RETVAL with standard typemap

        # Examine the typemap entry to determine whether it's possible
        # to optimise the return code by using the OP_ENTERSUB's targ (if
        # any) rather than creating a new mortal each time.
        # The targetable() Typemap method looks at whether the typemap
        # is of the form sv_setX($arg, $val) or similar, for X in iv ,uv,
        # nv, pv, pvn.
        # Note that we did the same lookup earlier to determine whether to
        # emit dXSTARG, a macro which expands to something like:
        #
        #   SV * targ = (PL_op->op_private & OPpENTERSUB_HASTARG)
        #               ? PAD_SV(PL_op->op_targ) : sv_newmortal()

        my $outputmap = $self->{typemaps_object}->get_outputmap( ctype => $self->{xsub_return_type} );
        my $target = $self->{config_optimize} && $outputmap && $outputmap->targetable;
        my $var = 'RETVAL';
        my $type = $self->{xsub_return_type};

        if ($target) {
          # Emit targ optimisation: basically, emit a PUSHi() or whatever,
          # which will set TARG to the value and push it.

          # $target->{what} is something like '(IV)$var': the part of the
          # typemap which contains the value the TARG should be set to.
          # Expand it via eval.
          my $what = $self->eval_output_typemap_code(
            qq("$target->{what}"),
            {var => $var, type => $self->{xsub_return_type}}
          );

          if (not $target->{with_size} and $target->{type} eq 'p') {
              # Handle sv_setpv() manually. (sv_setpvn() is handled
              # by the generic code below, via PUSHp().)
              print "\tsv_setpv(TARG, $what);\n";
              print "\tXSprePUSH;\n" unless $outlist_count;
              print "\tPUSHTARG;\n";
          }
          else {
            # Emit PUSHx() for generic sv_set_xv()

            # $tsize is the third arg of the sv_setpvn() in the typemap
            # (or empty otherwise), including comma, e.g. ', sizeof($var)'.
            # Eval it so that the result can be passed as the 2nd arg to
            # PUSHp().
            # XXX this could be skipped if $tsize is empty
            my $tsize = $target->{what_size};
            $tsize = '' unless defined $tsize;
            $tsize = $self->eval_output_typemap_code(
              qq("$tsize"),
              {var => $var, type => $self->{xsub_return_type}}
            );

            print "\tXSprePUSH;\n" unless $outlist_count;
            print "\tPUSH$target->{type}($what$tsize);\n";
          }
        }
        else {
          # Emit a normal RETVAL
          $self->generate_output( {
            type        => $self->{xsub_return_type},
            num         => 0,
            var         => 'RETVAL',
            do_setmagic => 0,   # RETVAL almost never needs SvSETMAGIC()
            do_push     => undef,
          } );
          print "\t++SP;\n" if $outlist_count;
        }
      }

      $XSRETURN_count = 1 if $self->{xsub_return_type} ne "void";
      my $num = $XSRETURN_count;
      $XSRETURN_count += $outlist_count;

      # Now that RETVAL is on the stack, also push any OUTLIST vars too
      for my $var (@OUTLIST_vars) {
        $self->generate_output(
          {
            type        => $self->{xsub_map_argname_to_type}->{$var},
            num         => $num++,
            var         => $var,
            do_setmagic => 0,
            do_push     => 1,
          }
        );
      }


      # ----------------------------------------------------------------
      # All RETVAL processing has been done.
      # Next, process any CLEANUP blocks,
      # ----------------------------------------------------------------

      # Process as many keyword lines/blocks as can be found which match
      # the pattern.
      $self->process_keywords("CLEANUP|$generic_xsub_keys");

      # ----------------------------------------------------------------
      # Emit function trailers
      # ----------------------------------------------------------------

      print Q(<<"EOF") if $self->{xsub_SCOPE_enabled};
        |   ]]
EOF

      print Q(<<"EOF") if $self->{xsub_SCOPE_enabled} and not $self->{xsub_seen_PPCODE};
        |   LEAVE;
EOF

      print Q(<<"EOF");
        |    ]]
EOF

      print Q(<<"EOF") if $self->{config_allow_exceptions};
        |    BEGHANDLERS
        |    CATCHALL
        |    sprintf(errbuf, "%s: %s\\tpropagated", Xname, Xreason);
        |    ENDHANDLERS
EOF

      if ($self->check_keyword("CASE")) {
        $self->blurt("Error: No 'CASE:' at top of function")
          unless $self->{xsub_CASE_condition_count};
        $_ = "CASE: $_";    # Restore CASE: label
        next;
      }

      last if $_ eq "$END:";

      $self->death(/^$BLOCK_regexp/o ? "Misplaced '$1:'" : "Junk at end of function ($_)");

    } # end while (@{ $self->{line} })


    # ----------------------------------------------------------------
    # All of the body of the XSUB (including all CASE variants) has now
    # been processed. Now emit any XSRETURN or similar, plus any closing
    # bracket.
    # ----------------------------------------------------------------

    print Q(<<"EOF") if $self->{config_allow_exceptions};
        |    if (errbuf[0])
        |    Perl_croak(aTHX_ errbuf);
EOF

    # Emit XSRETURN(N) or XSRETURN_EMPTY. It's possible that the user's
    # CODE section rolled its own return, so this code may be
    # unreachable. So suppress any compiler warnings.
    # XXX Currently this is just for HP. Make more generic??

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
          "#pragma diag_suppress 2128\n",
          "#endif\n"
      if $^O eq "hpux";

    if ($XSRETURN_count) {
      print Q(<<"EOF") unless $self->{xsub_seen_PPCODE};
        |    XSRETURN($XSRETURN_count);
EOF
    }
    else {
      print Q(<<"EOF") unless $self->{xsub_seen_PPCODE};
        |    XSRETURN_EMPTY;
EOF
    }

    # Suppress "statement is unreachable" warning on HPUX
    print "#if defined(__HP_cc) || defined(__HP_aCC)\n",
          "#pragma diag_default 2128\n",
          "#endif\n"
      if $^O eq "hpux";

    # Emit final closing bracket for the XSUB.
    print Q(<<"EOF");
        |]]
        |
EOF

    # ----------------------------------------------------------------
    # Generate (but don't yet emit - push to $self->{bootcode_early}) the
    # boot code for the XSUB, including newXS() call(s) plus any
    # additional boot stuff like handling attributes or storing an alias
    # index in the XSUB's CV.
    # ----------------------------------------------------------------

    {
      # Depending on whether the XSUB has a prototype, work out how to
      # invoke one of the newXS() function variants. Set these:
      #
      my $newXS;     # the newXS() variant to be called in the boot section
      my $file_arg;  # an extra      ', file' arg to be passed to newXS call
      my $proto_arg; # an extra e.g. ', "$@"' arg to be passed to newXS call

      $proto_arg = "";

      unless($self->{xsub_prototype}) {
        # no prototype
        $newXS = "newXS_deffile";
        $file_arg = "";
      }
      else {
        # needs prototype
        $newXS = "newXSproto_portable";
        $file_arg = ", file";

        if ($self->{xsub_prototype} eq 2) {
          # User has specified an empty prototype
        }
        elsif ($self->{xsub_prototype} eq 1) {
          # Protoype enabled, but to be auto-generated by us
          my $s = ';';
          if ($min_arg_count < $args_count)  {
            $s = '';
            # $self->{xsub_map_arg_idx_to_proto} was populated during
            # argument / typemap processing.  Each element contains the
            # prototype for that arg, typically '$'.
            $self->{xsub_map_arg_idx_to_proto}->[$min_arg_count] .= ";";
          }
          push @{ $self->{xsub_map_arg_idx_to_proto} }, "$s\@"
            if $self->{xsub_seen_ellipsis}; # '...' was seen in XSUB signature

          $proto_arg = join ("",
                  grep defined, @{ $self->{xsub_map_arg_idx_to_proto} } );
        }
        else {
          # User has manually specified a prototype
          $proto_arg = $self->{xsub_prototype};
        }

        $proto_arg = qq{, "$proto_arg"};
      }

      # Now use those values to append suitable newXS() and other code
      # into @{ $self->{bootcode_early} }, for later insertion into the
      # boot sub.

      if (            $self->{xsub_map_alias_name_to_value}
          and keys %{ $self->{xsub_map_alias_name_to_value} })
      {
        # For the main XSUB and for each alias name, generate a newXS() call
        # and 'XSANY.any_i32 = ix' line.

        # Make the main name one of the aliases if it isn't already
        $self->{xsub_map_alias_name_to_value}->{ $self->{xsub_func_full_perl_name} } = 0
          unless defined $self->{xsub_map_alias_name_to_value}->{ $self->{xsub_func_full_perl_name} };

        foreach my $xname (sort keys %{ $self->{xsub_map_alias_name_to_value} }) {
          my $value = $self->{xsub_map_alias_name_to_value}{$xname};
          push(@{ $self->{bootcode_early} }, Q(<<"EOF"));
            |        cv = $newXS(\"$xname\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);
            |        XSANY.any_i32 = $value;
EOF
        }
      }
      elsif (@{ $self->{xsub_attributes} }) {
        # Generate a standard newXS() call, plus a single call to
        # apply_attrs_string() call with the string of attributes.
        push(@{ $self->{bootcode_early} }, Q(<<"EOF"));
          |        cv = $newXS(\"$self->{xsub_func_full_perl_name}\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);
          |        apply_attrs_string("$self->{PACKAGE_name}", cv, "@{ $self->{xsub_attributes} }", 0);
EOF
      }
      elsif ($self->{xsub_seen_INTERFACE_or_MACRO}) {
        # For each interface name, generate both a newXS() and
        # XSINTERFACE_FUNC_SET() call.
        foreach my $yname (sort keys
                    %{ $self->{xsub_map_interface_name_short_to_original} })
        {
          my $value = $self->{xsub_map_interface_name_short_to_original}{$yname};
          $yname = "$self->{PACKAGE_name}\::$yname" unless $yname =~ /::/;
          push(@{ $self->{bootcode_early} }, Q(<<"EOF"));
            |        cv = $newXS(\"$yname\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);
            |        $self->{xsub_interface_macro_set}(cv,$value);
EOF
        }
      }
      elsif ($newXS eq 'newXS_deffile'){
        # Modified default: generate a standard newXS() call; but
        # work around the CPAN 'P5NCI' distribution doing:
        #     #undef newXS
        #     #define newXS ;
        # by omitting the initial (void).
        # XXX DAPM 2024:
        # this branch was originally: "elsif ($newXS eq 'newXS')"
        # but when the standard name for the newXS variant changed in
        # xsubpp, it was changed here too. So this branch no longer actually
        # handles a workaround for '#define newXS ;'. I also don't
        # understand how just omitting the '(void)' fixed the problem.
        push(@{ $self->{bootcode_early} },
         "        $newXS(\"$self->{xsub_func_full_perl_name}\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);\n");
      }
      else {
        # Default: generate a standard newXS() call
        push(@{ $self->{bootcode_early} },
         "        (void)$newXS(\"$self->{xsub_func_full_perl_name}\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);\n");
      }

      # For every overload operator, generate an additional newXS()
      # call to add an alias such as "Foo::(<=>" for this XSUB.

      for my $operator (sort keys %{ $self->{xsub_map_overload_name_to_seen} })
      {
        $self->{map_overloaded_package_to_C_package}->{$self->{PACKAGE_name}}
          = $self->{PACKAGE_C_name};
        my $overload = "$self->{PACKAGE_name}\::($operator";
        push(@{ $self->{bootcode_early} },
          "        (void)$newXS(\"$overload\", XS_$self->{xsub_func_full_C_name}$file_arg$proto_arg);\n");
      }

    }

  } # END 'PARAGRAPH' 'while' loop


  # ----------------------------------------------------------------
  # End of main loop and at EOF: all paragraphs (and thus XSUBs) have now
  # been read in and processed.  Do any final post-processing.
  # ----------------------------------------------------------------

  # Process any overloading.
  #
  # For each package FOO which has had at least one overloaded method
  # specified:
  #   - create a stub XSUB in that package called nil;
  #   - generate code to be added to the boot XSUB which links that XSUB
  #     to the symbol table entry *{"FOO::()"}.  This mimics the action in
  #     overload::import() which creates the stub method as a quick way to
  #     check whether an object is overloaded (including via inheritance),
  #     by doing $self->can('()').
  #   - Further down, we add a ${"FOO:()"} scalar containing the value of
  #     'fallback' (or undef if not specified).
  #
  # XXX In 5.18.0, this arrangement was changed in overload.pm, but hasn't
  # been updated here. The *() glob was being used for two different
  # purposes: a sub to do a quick check of overloadability, and a scalar
  # to indicate what 'fallback' value was specified (even if it wasn't
  # specified). The commits:
  #   v5.16.0-87-g50853fa94f
  #   v5.16.0-190-g3866ea3be5
  #   v5.17.1-219-g79c9643d87
  # changed this so that overloadability is checked by &((, while fallback
  # is checked by $() (and not present unless specified by 'fallback'
  # as opposed to the always being present, but sometimes undef).
  # Except that, in the presence of fallback, &() is added too for
  # backcompat reasons (which I don't fully understand - DAPM).
  # See overload.pm's import() and OVERLOAD() methods for more detail.
  #
  # So this code needs updating to match.

  for my $package (sort keys %{ $self->{map_overloaded_package_to_C_package} })
  {
    # make them findable with fetchmethod
    my $packid = $self->{map_overloaded_package_to_C_package}->{$package};
    print Q(<<"EOF");
      |XS_EUPXS(XS_${packid}_nil); /* prototype to pass -Wmissing-prototypes */
      |XS_EUPXS(XS_${packid}_nil)
      |{
      |   dXSARGS;
      |   PERL_UNUSED_VAR(items);
      |   XSRETURN_EMPTY;
      |}
      |
EOF

    unshift(@{ $self->{bootcode_early} }, Q(<<"EOF"));
      |   /* Making a sub named "${package}::()" allows the package */
      |   /* to be findable via fetchmethod(), and causes */
      |   /* overload::Overloaded("$package") to return true. */
      |   (void)newXS_deffile("${package}::()", XS_${packid}_nil);
EOF
  }


  # ----------------------------------------------------------------
  # Emit the boot XSUB initialization routine
  # ----------------------------------------------------------------

  print Q(<<"EOF");
    |#ifdef __cplusplus
    |extern "C" [[
    |#endif
EOF

  print Q(<<"EOF");
    |XS_EXTERNAL(boot_$self->{MODULE_cname}); /* prototype to pass -Wmissing-prototypes */
    |XS_EXTERNAL(boot_$self->{MODULE_cname})
    |[[
    |#if PERL_VERSION_LE(5, 21, 5)
    |    dVAR; dXSARGS;
    |#else
    |    dVAR; ${\($self->{VERSIONCHECK_value} ? 'dXSBOOTARGSXSAPIVERCHK;' : 'dXSBOOTARGSAPIVERCHK;')}
    |#endif
EOF

  # Declare a 'file' var for passing to newXS() and variants.
  #
  # If there is no $self->{xsub_func_full_C_name} then there are no xsubs
  # in this .xs so 'file' is unused, so silence warnings.
  #
  # 'file' can also be unused in other circumstances: in particular,
  # newXS_deffile() doesn't take a file parameter. So suppress any
  # 'unused var' warning always.
  #
  # Give it the correct 'const'ness: Under 5.8.x and lower, newXS() is
  # declared in proto.h as expecting a non-const file name argument. If
  # the wrong qualifier is used, it causes breakage with C++ compilers and
  # warnings with recent gcc.

  print Q(<<"EOF") if $self->{xsub_func_full_C_name};
    |#if PERL_VERSION_LE(5, 8, 999) /* PERL_VERSION_LT is 5.33+ */
    |    char* file = __FILE__;
    |#else
    |    const char* file = __FILE__;
    |#endif
    |
    |    PERL_UNUSED_VAR(file);
EOF

  # Emit assorted declarations

  print Q(<<"EOF");
    |
    |    PERL_UNUSED_VAR(cv); /* -W */
    |    PERL_UNUSED_VAR(items); /* -W */
EOF

  if ($self->{VERSIONCHECK_value}) {
    print Q(<<"EOF") ;
    |#if PERL_VERSION_LE(5, 21, 5)
    |    XS_VERSION_BOOTCHECK;
    |#  ifdef XS_APIVERSION_BOOTCHECK
    |    XS_APIVERSION_BOOTCHECK;
    |#  endif
    |#endif
    |
EOF

  } else {
    print Q(<<"EOF") ;
      |#if PERL_VERSION_LE(5, 21, 5) && defined(XS_APIVERSION_BOOTCHECK)
      |  XS_APIVERSION_BOOTCHECK;
      |#endif
      |
EOF

  }

  # Declare a 'cv' var within a scope small enough to be visible just to
  # newXS() calls which need to do further processing of the cv: in
  # particular, when emitting one of:
  #      XSANY.any_i32 = $value;
  #      XSINTERFACE_FUNC_SET(cv, $value);

  if (   defined $self->{xsub_map_alias_name_to_value}
      or defined $self->{seen_INTERFACE_or_MACRO})
  {
    print Q(<<"EOF");
      |    [[
      |        CV * cv;
      |
EOF
  }

  # More overload stuff

  if (keys %{ $self->{map_overloaded_package_to_C_package} }) {
    # Emit just once if any overloads:
    # Before 5.10, PL_amagic_generation used to need setting to at least a
    # non-zero value to tell perl that any overloading was present.
    print Q(<<"EOF");
      |    /* register the overloading (type 'A') magic */
      |#if PERL_VERSION_LE(5, 8, 999) /* PERL_VERSION_LT is 5.33+ */
      |    PL_amagic_generation++;
      |#endif
EOF

    for my $package (sort keys %{ $self->{map_overloaded_package_to_C_package} }) {
      # Emit once for each package with overloads:
      # Set ${'Foo::()'} to the fallback value for each overloaded
      # package 'Foo' (or undef if not specified).
      # But see the 'XXX' comments above about fallback and $().
      my $fallback =     $self->{map_package_to_fallback_string}->{$package}
                     || "&PL_sv_undef";
      print Q(<<"EOF");
        |    /* The magic for overload gets a GV* via gv_fetchmeth as */
        |    /* mentioned above, and looks in the SV* slot of it for */
        |    /* the "fallback" status. */
        |    sv_setsv(
        |        get_sv( "${package}::()", TRUE ),
        |        $fallback
        |    );
EOF

    }
  }

  # Emit any boot code associated with newXS().

  print @{ $self->{bootcode_early} };

  # Emit closing scope for the 'CV *cv' declaration

  if (   defined $self->{xsub_map_alias_name_to_value}
      or defined $self->{seen_INTERFACE_or_MACRO})
  {
    print Q(<<"EOF");
      |    ]]
EOF
  }

  # Emit any lines derived from BOOT: sections. By putting the lines back
  # into  $self->{line} and passing them through print_section(),
  # a trailing '#line' may be emitted to effect the change back to the
  # current foo.c line from the foo.xs part where the BOOT: code was.

  if (@{ $self->{bootcode_later} }) {
    print "\n    /* Initialisation Section */\n\n";
    print @{$self->{bootcode_later}};
    print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
      if $self->{config_WantLineNumbers};
    print "\n    /* End of Initialisation Section */\n\n";
  }

  # Emit code to call any UNITCHECK blocks and return true. Since 5.22,
  # this is been put into a separate function.
  print Q(<<'EOF');
    |#if PERL_VERSION_LE(5, 21, 5)
    |#  if PERL_VERSION_GE(5, 9, 0)
    |    if (PL_unitcheckav)
    |        call_list(PL_scopestack_ix, PL_unitcheckav);
    |#  endif
    |    XSRETURN_YES;
    |#else
    |    Perl_xs_boot_epilog(aTHX_ ax);
    |#endif
    |]]
    |
    |#ifdef __cplusplus
    |]]
    |#endif
EOF

  warn("Please specify prototyping behavior for $self->{in_filename} (see perlxs manual)\n")
    unless $self->{proto_behaviour_specified};

  chdir($orig_cwd);
  select($orig_fh);
  untie *PSEUDO_STDOUT if tied *PSEUDO_STDOUT;
  close $self->{in_fh};

  return 1;
}


sub report_error_count {
  if (@_) {
    return $_[0]->{error_count}||0;
  }
  else {
    return $Singleton->{error_count}||0;
  }
}
*errors = \&report_error_count;


# $self->check_keyword("FOO|BAR")
#
# Return a keyword if the next non-blank line matches one of the passed
# keywords, or return undef otherwise.
#
# Expects $_ to be set to the current line. Skip any initial blank lines,
# (consuming @{$self->{line}} and updating $_).
#
# Then if it matches FOO: etc, strip the keyword and any comment from the
# line (leaving any argument in $_) and return the keyword. Return false
# otherwise.

sub check_keyword {
  my ExtUtils::ParseXS $self = shift;
  # skip blank lines
  $_ = shift(@{ $self->{line} }) while !/\S/ && @{ $self->{line} };

  s/^(\s*)($_[0])\s*:\s*(?:#.*)?/$1/s && $2;
}


# Emit, verbatim(ish), all the lines up till the next directive.
# Typically used for sections that have blocks of code, like CODE. Return
# a string which contains all the lines of code emitted except for the
# extra '#line' type stuff.

sub print_section {
  my ExtUtils::ParseXS $self = shift;

  # Strip leading blank lines. The "do" is required for the right semantics
  do { $_ = shift(@{ $self->{line} }) } while !/\S/ && @{ $self->{line} };

  my $consumed_code = '';

  # Add a '#line' if needed. The XSubPPtmp test is a bit of a hack - it
  # skips synthetic blocks added to boot etc which may not have line
  # numbers.
  print("#line ", $self->{line_no}->[@{ $self->{line_no} } - @{ $self->{line} } -1], " \"",
        escape_file_for_line_directive($self->{in_pathname}), "\"\n")
    if     $self->{config_WantLineNumbers}
        && !/^\s*#\s*line\b/ && !/^#if XSubPPtmp/;

  # Emit lines until the next directive
  for (;  defined($_) && !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    print "$_\n";
    $consumed_code .= "$_\n";
  }

  # Emit a "restoring" '#line'
  print 'ExtUtils::ParseXS::CountLines'->end_marker, "\n"
    if $self->{config_WantLineNumbers};

  return $consumed_code;
}


# Consume, concatenate and return (as a single string), all the lines up
# until the next directive (including $_ as the first line).

sub merge_section {
  my ExtUtils::ParseXS $self = shift;
  my $in = '';

  # skip blank lines
  while (!/\S/ && @{ $self->{line} }) {
    $_ = shift(@{ $self->{line} });
  }

  for (;  defined($_) && !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    $in .= "$_\n";
  }
  chomp $in;
  return $in;
}


# Process as many keyword lines/blocks as can be found which match the
# pattern, by calling the FOO_handler() method for each keyword.

sub process_keywords {
  my ExtUtils::ParseXS $self = shift;
  my ($pattern) = @_;

  while (my $kwd = $self->check_keyword($pattern)) {
    my $method = $kwd . "_handler";
    $self->$method($_); # $_ contains the rest of the line after KEYWORD:
  }
}


# Handle BOOT: keyword.
# Save all the remaining lines in the paragraph to the bootcode_later
# array, and prepend a '#line' if necessary.

sub BOOT_handler {
  my ExtUtils::ParseXS $self = shift;

  # Check all the @{ $self->{line}} lines for balance: all the
  # #if, #else, #endif etc within the BOOT should balance out.
  $self->check_conditional_preprocessor_statements();

  # prepend a '#line' directive if needed
  if (   $self->{config_WantLineNumbers}
      && $self->{line}->[0] !~ /^\s*#\s*line\b/)
  {
    push @{ $self->{bootcode_later} },
       sprintf "#line %d \"%s\"\n",
         $self->{line_no}->[@{ $self->{line_no} } - @{ $self->{line} }],
         escape_file_for_line_directive($self->{in_pathname});
  }

  # Save all the BOOT lines plus trailing empty line to be emitted later.
  push @{ $self->{bootcode_later} }, "$_\n" for @{ $self->{line} }, "";
}


# Handle CASE: keyword.
# Extract the condition on the CASE: line and emit a suitable
# 'else if (condition)' style line of C

sub CASE_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  $self->blurt("Error: 'CASE:' after unconditional 'CASE:'")
    if     $self->{xsub_CASE_condition_count}
        && $self->{xsub_CASE_condition} eq '';

  $self->{xsub_CASE_condition} = $_;
  trim_whitespace($self->{xsub_CASE_condition});
  print "   ",
        ($self->{xsub_CASE_condition_count}++ ? " else" : ""),
        ($self->{xsub_CASE_condition}
          ? " if ($self->{xsub_CASE_condition})\n"
          : "\n"
        );
  $_ = '';
}


# INPUT_handler(): handle an explicit INPUT: block, or any implicit INPUT
# block which can follow an xsub signature or CASE keyword.
#
# For a function signature with types and/or IN_OUT prefixes, it will also
# be called after all real PREINIT/INPUT blocks, to process a synthetic
# block of input lines generated by the signature-parsing code, that
# allows those types to be processed. In this case we are called with
# with an extra true arg.

sub INPUT_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  my $synthetic = shift; # have fake lines from signature types

  # In this loop: process each line until the next keyword or end of
  # paragraph.

  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    # treat NOT_IMPLEMENTED_YET as another block separator, in addition to
    # $BLOCK_regexp.
    last if /^\s*NOT_IMPLEMENTED_YET/;
    next unless /\S/;        # skip blank lines

    trim_whitespace($_);
    my $ln = $_; # keep original line for error messages

    # remove any trailing semicolon, except for initialisations
    s/\s*;$//g unless /[=;+].*\S/;

    # Process any length(foo) declarations.
    # Basically for something like foo(char *s, int length(s)),
    # create *two* local C vars: one with STRLEN type, and one with the
    # type specified in the signature. Eventually, generate code looking
    # something like:
    #   STRLEN  STRLEN_length_of_s;
    #   int     XSauto_length_of_s;
    #   char *s = (char *)SvPV(ST(0), STRLEN_length_of_s);
    #   XSauto_length_of_s = STRLEN_length_of_s;
    #   RETVAL = foo(s, XSauto_length_of_s);
    #
    # Note that the SvPV() code is generated later by overriding the
    # normal T_PV typemap (which uses PV_nolen()).
    # Substituting 'XSauto_length_of_foo=NO_INIT' for 'length(foo)' causes
    # the code further down to emit the 'int XSauto_length_of_foo'
    # declaration.

    # XXX this block should only be done when $synthetic is true
    if (s/^([^=]*)\blength\(\s*(\w+)\s*\)\s*$/$1 XSauto_length_of_$2=NO_INIT/x)
    {
      print "\tSTRLEN\tSTRLEN_length_of_$2;\n";
      $self->{xsub_map_argname_to_islength}->{$2} = 1;
      # defer this line until after all the other declarations
      $self->{xsub_deferred_code_lines} .= "\n\tXSauto_length_of_$2 = STRLEN_length_of_$2;\n";
    }

    # Extract optional initialisation code (which overrides the
    # normal typemap), such as 'int foo = ($type)SvIV($arg)'
    my $var_init = '';
    $var_init = $1 if s/\s*([=;+].*)$//s;
    $var_init =~ s/"/\\"/g;

    # *sigh* It's valid to supply explicit input typemaps in the argument list.
    # XXX this doesn't allow '= NO_INIT', nor '= foo()'
    my $is_overridden_typemap = $var_init =~ /ST\s*\(|\$arg\b/;

    s/\s+/ /g;

    # Split 'char * &foo'  into  ('char *', '&', 'foo')
    # skip to next INPUT line if not valid.
    my ($var_type, $var_addr, $var_name) = /^(.*?[^&\s])\s*(\&?)\s*\b(\w+)$/s
      or $self->blurt("Error: invalid argument declaration '$ln'"), next;

    # Check for duplicate definitions of a particular parameter name.
    # Either the name has appeared in more than one INPUT line (including
    # the synthetic INPUT lines generated by typed signature parameters),
    # or has appeared as both a typed param and in a real INPUT entry.
    # XXX the second branch of the 'or' appears redundant

    $self->blurt("Error: duplicate definition of argument '$var_name' ignored"), next
      if   $self->{xsub_map_varname_to_seen_in_INPUT}->{$var_name}++
        or defined $self->{xsub_map_argname_to_seen_type}->{$var_name}
           and not $synthetic;

    # flag 'THIS' and 'RETVAL' as having been seen
    $self->{xsub_seen_THIS_in_INPUT}   |= $var_name eq "THIS";
    $self->{xsub_seen_RETVAL_in_INPUT} |= $var_name eq "RETVAL";

    $self->{xsub_map_argname_to_type}->{$var_name} = $var_type;

    # Emit the variable's type.
    #
    # Includes special handling for function pointer types. An INPUT line
    # always has the C type followed by the variable name. The C code
    # which is emitted normally follows the same pattern. However for
    # function pointers, the code is different: the variable name has to
    # be embedded *within* the type. For example, these two INPUT lines:
    #
    #    char *        s
    #    int (*)(int)  fn_ptr
    #
    # cause the following lines of C to be emitted;
    #
    #    char *              s = [something from a typemap]
    #    int (* fn_ptr)(int)   = [something from a typemap]
    #
    # So handle specially the specific case of a type containing '(*)'
    # and make a note that the variable name doesn't have to be emitted
    # out again.
    #
    # XXX $printed_name is just a temporary workaround until
    # generate_init() can handle this directly ("temporary" being defined
    # as 25 years so far and counting).

    my $printed_name;
    if ($var_type =~ / \( \s* \* \s* \) /x) {
      # Function pointers are not yet supported with output_init()!
      print "\t" . $self->map_type($var_type, $var_name);
      $printed_name = 1;
    }
    else {
      print "\t" . $self->map_type($var_type, undef);
      $printed_name = 0;
    }

    # The index number of the parameter. The counting starts at 1 and skips
    # fake parameters like 'length(s))' (zero is used for RETVAL).
    my $var_num = $self->{xsub_map_argname_to_idx}->{$var_name};

    # Get the prototype character, if any, associated with the typemap
    # entry for this var's type; defaults to '$'
    if ($var_num) {
      my $typemap = $self->{typemaps_object}->get_typemap(ctype => $var_type);
      $self->report_typemap_failure($self->{typemaps_object}, $var_type, "death")
        if not $typemap and not $is_overridden_typemap;

      $self->{xsub_map_arg_idx_to_proto}->[$var_num]
         = ($typemap && $typemap->proto) || "\$";
    }

    # Prepend a '&' to this arg's name for the args to pass to the
    # wrapped function (if any) called in the absence of a CODE: section.
    $self->{xsub_C_auto_function_signature} =~ s/\b($var_name)\b/&$1/
      if $var_addr;

    # Process the initialisation part of the INPUT line (if any) and/or
    # apply the standard typemap entry. Typically emits "var = ..."
    # (the type having already been emitted above).

    if (   $var_init =~ /^[=;]\s*NO_INIT\s*;?\s*$/
        or
                $self->{xsub_map_argname_to_in_out}->{$var_name}
            and $self->{xsub_map_argname_to_in_out}->{$var_name} =~ /^OUT/
            and $var_init !~ /\S/
       )
    {
      # NO_INIT or OUT* class; skip initialisation
      if ($printed_name) {
        print ";\n";
      }
      else {
        print "\t$var_name;\n";
      }
    }
    elsif ($var_init =~ /\S/) {
      # Emit var and init code based on overridden $var_init
      $self->output_init( {
        type          => $var_type,
        num           => $var_num,
        var           => $var_name,
        init          => $var_init,
        printed_name  => $printed_name,
      } );
    }
    elsif ($var_num) {
      # Emit var and init code based on typemap entry
      $self->generate_init( {
        type          => $var_type,
        num           => $var_num,
        var           => $var_name,
        printed_name  => $printed_name,
      } );
    }
    else {
      # Fake var like 'length(s)'. Don't emit anything.
      print ";\n";
    }

  } # foreach line in INPUT block
}


# Process the lines following the OUTPUT: keyword.

sub OUTPUT_handler {
  my ExtUtils::ParseXS $self = shift;
  $self->{xsub_seen_OUTPUT} = 1;

  $_ = shift;

  # In this loop: process each line until the next keyword or end of
  # paragraph

  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    next unless /\S/;        # skip blank lines

    if (/^\s*SETMAGIC\s*:\s*(ENABLE|DISABLE)\s*/) {
      $self->{xsub_SETMAGIC_state} = ($1 eq "ENABLE" ? 1 : 0);
      next;
    }

    # Expect lines of the two forms
    #    SomeVar
    #    SomeVar   sv_setsv(....);
    #
    my ($outarg, $outcode) = /^\s*(\S+)\s*(.*?)\s*$/s;

    $self->blurt("Error: duplicate OUTPUT argument '$outarg' ignored"), next
      if $self->{xsub_map_varname_to_seen_in_OUTPUT}->{$outarg}++;

    if (!$self->{xsub_seen_RETVAL_in_OUTPUT} and $outarg eq 'RETVAL') {
      # Postpone processing the RETVAL line to last (it's left to the
      # caller to finish).
      # XXX The !$self->{xsub_seen_RETVAL_in_OUTPUT} test means that if
      # there are
      # Duplicate RETVAL lines, then as well as blurt()ing above, the
      # subsequent lines are processed as normal vars too. This
      # doesn't seem useful.
      $self->{xsub_RETVAL_typemap_code} = $outcode;
      $self->{xsub_seen_RETVAL_in_OUTPUT} = 1;
      next;
    }

    $self->blurt("Error: OUTPUT $outarg not an argument"), next
      unless defined($self->{xsub_map_argname_to_idx}->{$outarg});

    $self->blurt("Error: No input definition for OUTPUT argument '$outarg' - ignored"), next
      unless defined $self->{xsub_map_argname_to_type}->{$outarg};

    my $var_num = $self->{xsub_map_argname_to_idx}->{$outarg};

    # Emit the custom var-setter code if present; else use the one from
    # the OUTPUT typemap.

    if ($outcode) {
      print "\t$outcode\n";
      print "\tSvSETMAGIC(ST(" , $var_num - 1 , "));\n"
        if $self->{xsub_SETMAGIC_state};
    }
    else {
      $self->generate_output( {
        type        => $self->{xsub_map_argname_to_type}->{$outarg},
        num         => $var_num,
        var         => $outarg,
        do_setmagic => $self->{xsub_SETMAGIC_state},
        do_push     => undef,
      } );
    }

    # No need to auto-OUTPUT
    delete $self->{xsub_map_argname_to_in_out}->{$outarg}
      if     exists $self->{xsub_map_argname_to_in_out}->{$outarg}
         and $self->{xsub_map_argname_to_in_out}->{$outarg} =~ /OUT$/;

  } # foreach line in OUTPUT block
}


# Set $self->{xsub_C_auto_function_signature} to the concatenation of all
# the following lines (including $_).

sub C_ARGS_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  my $in = $self->merge_section();

  trim_whitespace($in);
  $self->{xsub_C_auto_function_signature} = $in;
}


# Concatenate the following lines (including $_), then split into
# one or two macros names.

sub INTERFACE_MACRO_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  my $in = $self->merge_section();

  trim_whitespace($in);
  if ($in =~ /\s/) {        # two
    ($self->{xsub_interface_macro}, $self->{xsub_interface_macro_set})
          = split ' ', $in;
  }
  else {
    $self->{xsub_interface_macro} = $in;
    $self->{xsub_interface_macro_set} = 'UNKNOWN_CVT'; # catch later
  }
  $self->{xsub_seen_INTERFACE_or_MACRO} = 1;  # local
  $self->{seen_INTERFACE_or_MACRO} = 1;       # global
}


sub INTERFACE_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  my $in = $self->merge_section();

  trim_whitespace($in);

  foreach (split /[\s,]+/, $in) {
    my $iface_name = $_;
    $iface_name =~ s/^$self->{PREFIX_pattern}//;
    $self->{xsub_map_interface_name_short_to_original}->{$iface_name} = $_;
  }
  print Q(<<"EOF");
    |    XSFUNCTION = $self->{xsub_interface_macro}($self->{xsub_return_type},cv,XSANY.any_dptr);
EOF
  $self->{xsub_seen_INTERFACE_or_MACRO} = 1;  # local
  $self->{seen_INTERFACE_or_MACRO} = 1;       # global
}


sub CLEANUP_handler {
  my ExtUtils::ParseXS $self = shift;
  $self->print_section();
}


sub PREINIT_handler {
  my ExtUtils::ParseXS $self = shift;
  $self->print_section();
}


sub POSTCALL_handler {
  my ExtUtils::ParseXS $self = shift;
  $self->print_section();
}


sub INIT_handler {
  my ExtUtils::ParseXS $self = shift;
  $self->print_section();
}


# Process a line from an ALIAS: block
#
# Each line can have zero or more definitions, separated by white space.
# Each definition is of one of the forms:
#
#      name = value
#      name => other_name
#
#  where 'value' is a positive integer (or C macro) and the names are
#  simple or qualified perl function names. E.g.
#
#     foo = 1   Bar::foo = 2   Bar::baz => Bar::foo
#
# Updates:
#   $self->{xsub_map_alias_name_to_value}->{$alias} = $value;
#   $self->{xsub_map_alias_value_to_name_seen_hash}->{$value}{$alias}++;

sub get_aliases {
  my ExtUtils::ParseXS $self = shift;
  my ($line) = @_;
  my ($orig) = $line;

  # we use this later for symbolic aliases
  my $fname = $self->{PACKAGE_class} . $self->{xsub_func_name};

  while ($line =~ s/^\s*([\w:]+)\s*=(>?)\s*([\w:]+)\s*//) {
    my ($alias, $is_symbolic, $value) = ($1, $2, $3);
    my $orig_alias = $alias;

    blurt( $self, "Error: In alias definition for '$alias' the value may not"
                  . " contain ':' unless it is symbolic.")
        if !$is_symbolic and $value=~/:/;

    # check for optional package definition in the alias
    $alias = $self->{PACKAGE_class} . $alias if $alias !~ /::/;

    if ($is_symbolic) {
      my $orig_value = $value;
      $value = $self->{PACKAGE_class} . $value if $value !~ /::/;
      if (defined $self->{xsub_map_alias_name_to_value}->{$value}) {
        $value = $self->{xsub_map_alias_name_to_value}->{$value};
      } elsif ($value eq $fname) {
        $value = 0;
      } else {
        blurt( $self, "Error: Unknown alias '$value' in symbolic definition for '$orig_alias'");
      }
    }

    # check for duplicate alias name & duplicate value
    my $prev_value = $self->{xsub_map_alias_name_to_value}->{$alias};
    if (defined $prev_value) {
      if ($prev_value eq $value) {
        Warn( $self, "Warning: Ignoring duplicate alias '$orig_alias'")
      } else {
        Warn( $self, "Warning: Conflicting duplicate alias '$orig_alias'"
                     . " changes definition from '$prev_value' to '$value'");
        delete $self->{xsub_map_alias_value_to_name_seen_hash}->{$prev_value}{$alias};
      }
    }

    # Check and see if this alias results in two aliases having the same
    # value, we only check non-symbolic definitions as the whole point of
    # symbolic definitions is to say we want to duplicate the value and
    # it is NOT a mistake.
    unless ($is_symbolic) {
      my @keys= sort keys %{$self->{xsub_map_alias_value_to_name_seen_hash}->{$value}||{}};
      # deal with an alias of 0, which might not be in the aliases
      # dataset yet as 0 is the default for the base function ($fname)
      push @keys, $fname
        if $value eq "0" and !defined $self->{xsub_map_alias_name_to_value}{$fname};
      if (@keys and $self->{config_author_warnings}) {
        # We do not warn about value collisions unless author_warnings
        # are enabled. They aren't helpful to a module consumer, only
        # the module author.
        @keys= map { "'$_'" }
               map { my $copy= $_;
                     $copy=~s/^$self->{PACKAGE_class}//;
                     $copy
                   } @keys;
        WarnHint( $self,
                  "Warning: Aliases '$orig_alias' and "
                  . join(", ", @keys)
                  . " have identical values of $value"
                  . ( $value eq "0"
                      ? " - the base function"
                      : "" ),
                  !$self->{xsub_alias_clash_hinted}++
                  ? "If this is deliberate use a symbolic alias instead."
                  : undef
        );
      }
    }

    $self->{xsub_map_alias_name_to_value}->{$alias} = $value;
    $self->{xsub_map_alias_value_to_name_seen_hash}->{$value}{$alias}++;
  }

  blurt( $self, "Error: Cannot parse ALIAS definitions from '$orig'")
    if $line;
}


# Read each lines's worth of attributes into a string that is pushed
# to the {xsub_attributes} array. Note that it doesn't matter that multiple
# space-separated attributes on the same line are stored as a single
# string; later, all the attribute lines are joined together into a single
# string to pass to apply_attrs_string().

sub ATTRS_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;

  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    next unless /\S/;
    trim_whitespace($_);
    push @{ $self->{xsub_attributes} }, $_;
  }
}


# Process the line(s) following the ALIAS: keyword

sub ALIAS_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;

  # Consume and process alias lines until the next  directive.
  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    next unless /\S/;
    trim_whitespace($_);
    $self->get_aliases($_) if $_;
  }
}


# Add all overload method names, like 'cmp', '<=>', etc, (possibly
# multiple ones per line) until the next keyword line, as 'seen' keys to
# the $self->{xsub_map_overload_name_to_seen} hash.

sub OVERLOAD_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;

  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    next unless /\S/;
    trim_whitespace($_);
    while ( s/^\s*([\w:"\\)\+\-\*\/\%\<\>\.\&\|\^\!\~\{\}\=]+)\s*//) {
      $self->{xsub_map_overload_name_to_seen}->{$1} = 1;
    }
  }
}


sub FALLBACK_handler {
  my ExtUtils::ParseXS $self = shift;
  my ($setting) = @_;

  # the rest of the current line should contain either TRUE,
  # FALSE or UNDEF

  trim_whitespace($setting);
  $setting = uc($setting);

  my %map = (
    TRUE => "&PL_sv_yes", 1 => "&PL_sv_yes",
    FALSE => "&PL_sv_no", 0 => "&PL_sv_no",
    UNDEF => "&PL_sv_undef",
  );

  # check for valid FALLBACK value
  $self->death("Error: FALLBACK: TRUE/FALSE/UNDEF") unless exists $map{$setting};

  $self->{map_package_to_fallback_string}->{$self->{PACKAGE_name}}
      = $map{$setting};
}


sub REQUIRE_handler {
  my ExtUtils::ParseXS $self = shift;
  # the rest of the current line should contain a version number
  my ($ver) = @_;

  trim_whitespace($ver);

  $self->death("Error: REQUIRE expects a version number")
    unless $ver;

  # check that the version number is of the form n.n
  $self->death("Error: REQUIRE: expected a number, got '$ver'")
    unless $ver =~ /^\d+(\.\d*)?/;

  $self->death("Error: xsubpp $ver (or better) required--this is only $VERSION.")
    unless $VERSION >= $ver;
}


sub VERSIONCHECK_handler {
  my ExtUtils::ParseXS $self = shift;
  # the rest of the current line should contain either ENABLE or
  # DISABLE
  my ($setting) = @_;

  trim_whitespace($setting);

  # check for ENABLE/DISABLE
  $self->death("Error: VERSIONCHECK: ENABLE/DISABLE")
    unless $setting =~ /^(ENABLE|DISABLE)/i;

  $self->{VERSIONCHECK_value} = 1 if $1 eq 'ENABLE';
  $self->{VERSIONCHECK_value} = 0 if $1 eq 'DISABLE';

}


# PROTOTYPE: Process one or more lines of the form
#    DISABLE
#    ENABLE
#    $$@      # a literal prototype
#    <blank>
#
# It's probably a design flaw that more than one entry can be processed.

sub PROTOTYPE_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;

  my $specified;

  $self->death("Error: Only 1 PROTOTYPE definition allowed per xsub")
    if $self->{xsub_seen_PROTOTYPE}++;

  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
    next unless /\S/;
    $specified = 1;
    trim_whitespace($_);
    if ($_ eq 'DISABLE') {
      $self->{xsub_prototype} = 0;
    }
    elsif ($_ eq 'ENABLE') {
      $self->{xsub_prototype} = 1;
    }
    else {
      # remove any whitespace
      s/\s+//g;
      $self->death("Error: Invalid prototype '$_'")
        unless valid_proto_string($_);
      $self->{xsub_prototype} = C_string($_);
    }
  }

  # If no prototype specified, then assume empty prototype ""
  $self->{xsub_prototype} = 2 unless $specified;

  $self->{proto_behaviour_specified} = 1;
}


# Set $self->{xsub_SCOPE_enabled} to a boolean value based on DISABLE/ENABLE.

sub SCOPE_handler {
  my ExtUtils::ParseXS $self = shift;
  # Rest of line should be either ENABLE or DISABLE
  my ($setting) = @_;

  $self->death("Error: Only 1 SCOPE declaration allowed per xsub")
    if $self->{xsub_seen_SCOPE}++;

  trim_whitespace($setting);
  $self->death("Error: SCOPE: ENABLE/DISABLE")
      unless $setting =~ /^(ENABLE|DISABLE)\b/i;
  $self->{xsub_SCOPE_enabled} = ( uc($1) eq 'ENABLE' );
}


sub PROTOTYPES_handler {
  my ExtUtils::ParseXS $self = shift;
  # the rest of the current line should contain either ENABLE or
  # DISABLE
  my ($setting) = @_;

  trim_whitespace($setting);

  # check for ENABLE/DISABLE
  $self->death("Error: PROTOTYPES: ENABLE/DISABLE")
    unless $setting =~ /^(ENABLE|DISABLE)/i;

  $self->{PROTOTYPES_value} = 1 if $1 eq 'ENABLE';
  $self->{PROTOTYPES_value} = 0 if $1 eq 'DISABLE';
  $self->{proto_behaviour_specified} = 1;
}


sub EXPORT_XSUB_SYMBOLS_handler {
  my ExtUtils::ParseXS $self = shift;
  # the rest of the current line should contain either ENABLE or
  # DISABLE
  my ($setting) = @_;

  trim_whitespace($setting);

  # check for ENABLE/DISABLE
  $self->death("Error: EXPORT_XSUB_SYMBOLS: ENABLE/DISABLE")
    unless $setting =~ /^(ENABLE|DISABLE)/i;

  my $xs_impl = $1 eq 'ENABLE' ? 'XS_EXTERNAL' : 'XS_INTERNAL';

  print Q(<<"EOF");
    |#undef XS_EUPXS
    |#if defined(PERL_EUPXS_ALWAYS_EXPORT)
    |#  define XS_EUPXS(name) XS_EXTERNAL(name)
    |#elif defined(PERL_EUPXS_NEVER_EXPORT)
    |#  define XS_EUPXS(name) XS_INTERNAL(name)
    |#else
    |#  define XS_EUPXS(name) $xs_impl(name)
    |#endif
EOF
}


# Push an entry on the @{ $self->{XS_parse_stack} } array containing the
# current file state, in preparation for INCLUDEing a new file. (Note that
# it doesn't handle type => 'if' style entries, only file entries.)

sub push_parse_stack {
  my ExtUtils::ParseXS $self = shift;
  my %args = @_;
  # Save the current file context.
  push(@{ $self->{XS_parse_stack} }, {
          type            => 'file',
          LastLine        => $self->{lastline},
          LastLineNo      => $self->{lastline_no},
          Line            => $self->{line},
          LineNo          => $self->{line_no},
          Filename        => $self->{in_filename},
          Filepathname    => $self->{in_pathname},
          Handle          => $self->{in_fh},
          IsPipe          => scalar($self->{in_filename} =~ /\|\s*$/),
          %args,
         });

}


sub INCLUDE_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  # the rest of the current line should contain a valid filename

  trim_whitespace($_);

  $self->death("INCLUDE: filename missing")
    unless $_;

  $self->death("INCLUDE: output pipe is illegal")
    if /^\s*\|/;

  # simple minded recursion detector
  $self->death("INCLUDE loop detected")
    if $self->{IncludedFiles}->{$_};

  ++$self->{IncludedFiles}->{$_} unless /\|\s*$/;

  if (/\|\s*$/ && /^\s*perl\s/) {
    Warn( $self, "The INCLUDE directive with a command is discouraged." .
          " Use INCLUDE_COMMAND instead! In particular using 'perl'" .
          " in an 'INCLUDE: ... |' directive is not guaranteed to pick" .
          " up the correct perl. The INCLUDE_COMMAND directive allows" .
          " the use of \$^X as the currently running perl, see" .
          " 'perldoc perlxs' for details.");
  }

  $self->push_parse_stack();

  $self->{in_fh} = Symbol::gensym();

  # open the new file
  open($self->{in_fh}, $_) or $self->death("Cannot open '$_': $!");

  print Q(<<"EOF");
    |
    |/* INCLUDE:  Including '$_' from '$self->{in_filename}' */
    |
EOF

  $self->{in_filename} = $_;
  $self->{in_pathname} = ( $^O =~ /^mswin/i )
                            # See CPAN RT #61908: gcc doesn't like
                            # backslashes on win32?
                          ? qq($self->{dir}/$self->{in_filename})
                          : File::Spec->catfile($self->{dir}, $self->{in_filename});

  # Prime the pump by reading the first
  # non-blank line

  # skip leading blank lines
  while (readline($self->{in_fh})) {
    last unless /^\s*$/;
  }

  $self->{lastline} = $_;
  $self->{lastline_no} = $.;
}


# Quote a command-line to be suitable for VMS

sub QuoteArgs {
  my $cmd = shift;
  my @args = split /\s+/, $cmd;
  $cmd = shift @args;
  for (@args) {
    $_ = q(").$_.q(") if !/^\"/ && length($_) > 0;
  }
  return join (' ', ($cmd, @args));
}


# _safe_quote(): quote an executable pathname which includes spaces.
#
# This code was copied from CPAN::HandleConfig::safe_quote:
# that has doc saying leave if start/finish with same quote, but no code
# given text, will conditionally quote it to protect from shell

{
  my ($quote, $use_quote) = $^O eq 'MSWin32'
      ? (q{"}, q{"})
      : (q{"'}, q{'});
  sub _safe_quote {
      my ($self, $command) = @_;
      # Set up quote/default quote
      if (defined($command)
          and $command =~ /\s/
          and $command !~ /[$quote]/) {
          return qq{$use_quote$command$use_quote}
      }
      return $command;
  }
}


sub INCLUDE_COMMAND_handler {
  my ExtUtils::ParseXS $self = shift;
  $_ = shift;
  # the rest of the current line should contain a valid command

  trim_whitespace($_);

  $_ = QuoteArgs($_) if $^O eq 'VMS';

  $self->death("INCLUDE_COMMAND: command missing")
    unless $_;

  $self->death("INCLUDE_COMMAND: pipes are illegal")
    if /^\s*\|/ or /\|\s*$/;

  $self->push_parse_stack( IsPipe => 1 );

  $self->{in_fh} = Symbol::gensym();

  # If $^X is used in INCLUDE_COMMAND, we know it's supposed to be
  # the same perl interpreter as we're currently running
  my $X = $self->_safe_quote($^X); # quotes if has spaces
  s/^\s*\$\^X/$X/;

  # open the new file
  open ($self->{in_fh}, "-|", $_)
    or $self->death( $self, "Cannot run command '$_' to include its output: $!");

  print Q(<<"EOF");
    |
    |/* INCLUDE_COMMAND:  Including output of '$_' from '$self->{in_filename}' */
    |
EOF

  $self->{in_filename} = $_;
  $self->{in_pathname} = $self->{in_filename};
  #$self->{in_pathname} =~ s/\"/\\"/g; # Fails? See CPAN RT #53938: MinGW Broken after 2.21
  $self->{in_pathname} =~ s/\\/\\\\/g; # Works according to reporter of #53938

  # Prime the pump by reading the first
  # non-blank line

  # skip leading blank lines
  while (readline($self->{in_fh})) {
    last unless /^\s*$/;
  }

  $self->{lastline} = $_;
  $self->{lastline_no} = $.;
}


# Pop the type => 'file' entry off the top of the @{ $self->{XS_parse_stack} }
# array following the end of processing an INCLUDEd file, and restore the
# former state.

sub PopFile {
  my ExtUtils::ParseXS $self = shift;

  return 0 unless $self->{XS_parse_stack}->[-1]{type} eq 'file';

  my $data     = pop @{ $self->{XS_parse_stack} };
  my $ThisFile = $self->{in_filename};
  my $isPipe   = $data->{IsPipe};

  --$self->{IncludedFiles}->{$self->{in_filename}}
    unless $isPipe;

  close $self->{in_fh};

  $self->{in_fh}         = $data->{Handle};
  # $in_filename is the leafname, which for some reason is used for diagnostic
  # messages, whereas $in_pathname is the full pathname, and is used for
  # #line directives.
  $self->{in_filename}   = $data->{Filename};
  $self->{in_pathname} = $data->{Filepathname};
  $self->{lastline}   = $data->{LastLine};
  $self->{lastline_no} = $data->{LastLineNo};
  @{ $self->{line} }       = @{ $data->{Line} };
  @{ $self->{line_no} }    = @{ $data->{LineNo} };

  if ($isPipe and $? ) {
    --$self->{lastline_no};
    print STDERR "Error reading from pipe '$ThisFile': $! in $self->{in_filename}, line $self->{lastline_no}\n" ;
    exit 1;
  }

  print Q(<<"EOF");
    |
    |/* INCLUDE: Returning to '$self->{in_filename}' from '$ThisFile' */
    |
EOF

  return 1;
}


# Unescape a string (typically a heredoc):
#   - strip leading '    |' (any number of leading spaces)
#   - and replace [[ and ]]
#         with    {  and }
# so that text editors don't see a bare { or } when bouncing around doing
# brace level matching.

sub Q {
  my ($text) = @_;
  my @lines = split /^/, $text;
  my $first;
  for (@lines) {
    unless (s/^(\s*)\|//) {
      die "Internal error: no leading '|' in Q() string:\n$_\n";
    }
    my $pre = $1;
    die "Internal error: leading tab char in Q() string:\n$_\n"
      if $pre =~ /\t/;

    if (defined $first) {
      die "Internal error: leading indents in Q() string don't match:\n$_\n"
        if $pre ne $first;
    }
    else {
      $first = $pre;
    }
  }
  $text = join "", @lines;

  $text =~ s/\[\[/{/g;
  $text =~ s/\]\]/}/g;
  $text;
}


# Process "MODULE = Foo ..." lines and update global state accordingly

sub _process_module_xs_line {
  my ExtUtils::ParseXS $self = shift;
  my ($module, $pkg, $prefix) = @_;

  ($self->{MODULE_cname} = $module) =~ s/\W/_/g;

  $self->{PACKAGE_name} = defined($pkg) ? $pkg : '';
  $self->{PREFIX_pattern} = quotemeta( defined($prefix) ? $prefix : '' );

  ($self->{PACKAGE_C_name} = $self->{PACKAGE_name}) =~ tr/:/_/;

  $self->{PACKAGE_class} = $self->{PACKAGE_name};
  $self->{PACKAGE_class} .= "::" if $self->{PACKAGE_class} ne "";

  $self->{lastline} = "";
}


# Skip any embedded POD sections, reading in lines from {in_fh} as necessary.

sub _maybe_skip_pod {
  my ExtUtils::ParseXS $self = shift;

  while ($self->{lastline} =~ /^=/) {
    while ($self->{lastline} = readline($self->{in_fh})) {
      last if ($self->{lastline} =~ /^=cut\s*$/);
    }
    $self->death("Error: Unterminated pod") unless defined $self->{lastline};
    $self->{lastline} = readline($self->{in_fh});
    chomp $self->{lastline};
    $self->{lastline} =~ s/^\s+$//;
  }
}


# Strip out and parse embedded TYPEMAP blocks (which use a HEREdoc-alike
# block syntax).

sub _maybe_parse_typemap_block {
  my ExtUtils::ParseXS $self = shift;

  # This is special cased from the usual paragraph-handler logic
  # due to the HEREdoc-ish syntax.
  if ($self->{lastline} =~ /^TYPEMAP\s*:\s*<<\s*(?:(["'])(.+?)\1|([^\s'"]+?))\s*;?\s*$/)
  {
    my $end_marker = quotemeta(defined($1) ? $2 : $3);

    # Scan until we find $end_marker alone on a line.
    my @tmaplines;
    while (1) {
      $self->{lastline} = readline($self->{in_fh});
      $self->death("Error: Unterminated TYPEMAP section") if not defined $self->{lastline};
      last if $self->{lastline} =~ /^$end_marker\s*$/;
      push @tmaplines, $self->{lastline};
    }

    my $tmap = ExtUtils::Typemaps->new(
      string        => join("", @tmaplines),
      lineno_offset => 1 + ($self->current_line_number() || 0),
      fake_filename => $self->{in_filename},
    );
    $self->{typemaps_object}->merge(typemap => $tmap, replace => 1);

    $self->{lastline} = "";
  }
}


# fetch_para(): private helper method for process_file().
#
# Read in all the lines associated with the next XSUB, or associated with
# the next contiguous block of file-scoped XS or CPP directives.
#
# More precisely, read lines (and their line numbers) up to (but not
# including) the start of the next XSUB or similar, into:
#
#   @{ $self->{line}    }
#   @{ $self->{line_no} }
#
# It assumes that $self->{lastline} contains the next line to process,
# and that further lines can be read from $self->{in_fh} as necessary.
#
# Multiple lines which are read in that end in '\' are concatenated
# together into a single line, whose line number is set to
# their first line. The two characters '\' and '\n' are kept in the
# concatenated string.
#
# On return, it leaves the first unprocessed line in $self->{lastline}:
# typically the first line of the next XSUB. At EOF, lastline will be
# left undef.
#
# In general, it stops just before the first line which matches /^\S/ and
# which was preceded by a blank line. This line is often the start of the
# next XSUB (but there is no guarantee of that).
#
# For example, given these lines:
#
#    |    ....
#    |    stuff
#    |                    [blank line]
#    |PROTOTYPES: ENABLED
#    |#define FOO 1
#    |SCOPE: ENABLE
#    |#define BAR 1
#    |                    [blank line]
#    |int
#    |foo(...)
#    |    ....
#
# then the first call will return everything up to 'stuff' inclusive
# (perhaps it's the last line of an XSUB). The next call will return four
# lines containing the XS directives and CPP definitions. The directives
# are not interpreted or processed by this function; they're just returned
# as unprocessed text for the caller to interpret. A third call will read
# in the XSUB starting at 'int'.
#
# Note that fetch_para() knows almost nothing about C or XS syntax and
# keywords, and just blindly reads in lines until it finds a suitable
# place to break. It generally relies on the caller to handle most of the
# syntax and semantics and error reporting. For example, the block of four
# lines above from 'PROTOTYPES' onwards isn't valid XS, but is blindly
# returned by fetch_para().
#
# It often returns zero lines - the caller will have to handle this.
#
# There are a few exceptions where certain lines starting in column 1
# *are* interpreted by this function (and conversely where /\\$/ *isn't*
# processed):
#     
# POD:        Discard all lines between /^='/../^=cut/, then continue.
#
# MODULE:     If this appears as the first line, it is processed and
#             discarded, then line reading continues.
#
# TYPEMAP:    Process a 'heredoc' typemap, discard all processed lines,
#             then continue.
#
# /^\s*#/     Discard such lines unless they look like a CPP directive,
#             on the assumption that they are code comments. Then, in
#             particular:
#
# #if etc:    For anything which is part of a CPP conditional: if it
#             is external to the current chunk of code (e.g. an #endif
#             which isn't matched by an earlier #if/ifdef/ifndef within
#             the current chunk) then processing stops before that line.
#
#             Nested if/elsif/else's etc within the chunk are passed
#             through and processing continues. An #if/ifdef/ifdef on the
#             first line is treated as external and is returned as a
#             single line.
#
#             It is assumed the caller will handle any processing or
#             nesting of external conditionals.
#
#             CPP directives (like #define) which aren't concerned with
#             conditions are just passed through.
#
# It removes any trailing blank lines from the list of returned lines.


sub fetch_para {
  my ExtUtils::ParseXS $self = shift;

  # unmatched #if at EOF
  $self->death("Error: Unterminated '#if/#ifdef/#ifndef'")
    if !defined $self->{lastline} && $self->{XS_parse_stack}->[-1]{type} eq 'if';

  @{ $self->{line} } = ();
  @{ $self->{line_no} } = ();
  return $self->PopFile() if not defined $self->{lastline}; # EOF

  if ($self->{lastline} =~
      /^MODULE\s*=\s*([\w:]+)(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/)
  {
    $self->_process_module_xs_line($1, $2, $3);
  }

  # count how many #ifdef levels we see in this paragraph
  # decrementing when we see an endif. if we see an elsif
  # or endif without a corresponding #ifdef then we don't
  # consider it part of this paragraph.
  my $if_level = 0;

  for (;;) {
    $self->_maybe_skip_pod;

    $self->_maybe_parse_typemap_block;

    my $final;

    # Process this line unless it looks like a '#', comment

    if ($self->{lastline} !~ /^\s*#/ # not a CPP directive
           # CPP directives:
           #   ANSI:    if ifdef ifndef elif else endif define undef
           #              line error pragma
           #   gcc:    warning include_next
           #   obj-c:  import
           #   others: ident (gcc notes that some cpps have this one)
        || $self->{lastline} =~ /^\#[ \t]*
                                  (?:
                                        (?:if|ifn?def|elif|else|endif|elifn?def|
                                           define|undef|pragma|error|
                                           warning|line\s+\d+|ident)
                                        \b
                                      | (?:include(?:_next)?|import)
                                        \s* ["<] .* [>"]
                                 )
                                /x
    )
    {
      # Blank line followed by char in column 1. Start of next XSUB?
      last if    $self->{lastline} =~ /^\S/
              && @{ $self->{line} }
              && $self->{line}->[-1] eq "";

      # processes CPP conditionals
      if ($self->{lastline}
            =~/^#[ \t]*(if|ifn?def|elif|else|endif|elifn?def)\b/)
      {
        my $type = $1;
        if ($type =~ /^if/) {  # if, ifdef, ifndef
          if (@{$self->{line}}) {
            # increment level
            $if_level++;
          } else {
            $final = 1;
          }
        } elsif ($type eq "endif") {
          if ($if_level) { # are we in an if that was started in this paragraph?
            $if_level--;   # yep- so decrement to end this if block
          } else {
            $final = 1;
          }
        } elsif (!$if_level) {
          # not in an #ifdef from this paragraph, thus
          # this directive should not be part of this paragraph.
          $final = 1;
        }
      }

      if ($final and @{$self->{line}}) {
        return 1;
      }

      push(@{ $self->{line} }, $self->{lastline});
      push(@{ $self->{line_no} }, $self->{lastline_no});
    } # end of processing non-comment lines

    # Read next line and continuation lines
    last unless defined($self->{lastline} = readline($self->{in_fh}));
    $self->{lastline_no} = $.;
    my $tmp_line;
    $self->{lastline} .= $tmp_line
      while ($self->{lastline} =~ /\\$/ && defined($tmp_line = readline($self->{in_fh})));

    chomp $self->{lastline};
    $self->{lastline} =~ s/^\s+$//;
    if ($final) {
      last;
    }
  } # end for (;;)

  # Nuke trailing "line" entries until there's one that's not empty
  pop(@{ $self->{line} }), pop(@{ $self->{line_no} })
    while @{ $self->{line} } && $self->{line}->[-1] eq "";

  return 1;
}


# $self->output_init({ key = value, ... })
#   type: 'char *' etc
#   num:  the parameter number, corresponds to in ST(num-1)
#   var:  the parameter name
#   init: the initialiser, e.g. '= SvPV($arg)'
#   printed_name: the parameter name has already been printed
#
# Emit "var = initialisation code" based on the value of $init (which
# contains everything following the variable name on the INPUT line).
# It assumes that $init starts with /[=;+]/.
#
# See also generate_init() below, which provides a similar role for when
# $init is empty.

sub output_init {
  my ExtUtils::ParseXS $self = shift;
  my $argsref = shift;

  my ($type, $num, $var, $init, $printed_name)
    = @{$argsref}{qw(type num var init printed_name)};

  # local assign for efficiently passing in to eval_input_typemap_code
  local $argsref->{arg} = $num
                          ? "ST(" . ($num-1) . ")"
                          : "/* not a parameter */";

  if ( $init =~ /^=/ ) {
    # overridden typemap, such as '= ($type)SvUV($arg)'
    if ($printed_name) {
      $self->eval_input_typemap_code(qq/print " $init\\n"/, $argsref);
    }
    else {
      $self->eval_input_typemap_code(qq/print "\\t$var $init\\n"/, $argsref);
    }
  }
  else {
    # "; extra code" or "+ extra code" :
    # append the extra code (after passing through eval) after all the
    # INPUT and PREINIT blocks have been processed, using the
    # $self->{xsub_deferred_code_lines} mechanism.
    # In addition, for '+', also generate the normal initialisation code
    # from the standard typemap.

    if (  $init =~ s/^\+//  &&  $num  ) {
      # "+ extra code"
      $self->generate_init( {
        type          => $type,
        num           => $num,
        var           => $var,
        printed_name  => $printed_name,
      } );
    }
    # "; extra code"
    elsif ($printed_name) {
      print ";\n";
      $init =~ s/^;//;
    }
    else {
      $self->eval_input_typemap_code(qq/print "\\t$var;\\n"/, $argsref);
      $init =~ s/^;//;
    }

    # defer outputting the "extra code"
    $self->{xsub_deferred_code_lines}
      .= $self->eval_input_typemap_code(qq/"\\n\\t$init\\n"/, $argsref);
  }
}


# $self->generate_init({ key = value, ... })
#   type         'char *' etc
#   num          the parameter number, corresponds to ST(num-1)
#   var          the parameter name
#   printed_name if true, the parameter name has already been printed
#
# This function emits code like "var = initialisation code", based on the
# typemap INPUT entry associated with $type, passing the typemap code
# through a double-quoted context eval first, to expand variables such as
# $type.

sub generate_init {
  my ExtUtils::ParseXS $self = shift;
  my $argsref = shift;

  my ($type, $num, $var, $printed_name)
    = @{$argsref}{qw(type num var printed_name)};

  my $argoff = $num - 1;
  my $arg = "ST($argoff)";

  my $typemaps = $self->{typemaps_object};

  # whitespace-tidy the type
  $type = ExtUtils::Typemaps::tidy_type($type);

  if (not $typemaps->get_typemap(ctype => $type)) {
    $self->report_typemap_failure($typemaps, $type);
    return;
  }

  # Normalised type ('Foo *' becomes 'FooPtr): one of the valid vars
  # which can appear within a typemap template.
  (my $ntype = $type) =~ s/\s*\*/Ptr/g;

  # $subtype is really just for the T_ARRAY / DO_ARRAY_ELEM code below,
  # where it's the type of each array element. But it's also passed to
  # the typemap template (although undocumented and virtually unused).
  (my $subtype = $ntype) =~ s/(?:Array)?(?:Ptr)?$//;

  # look up the TYPEMAP entry for this C type and grab the corresponding
  # XS type name (e.g. $type of 'char *'  gives $xstype of 'T_PV'
  my $typem = $typemaps->get_typemap(ctype => $type);
  my $xstype = $typem->xstype;

  # An optimisation: for the typemaps which check that the dereferenced
  # item is blessed into the right class, skip the test for DESTROY()
  # methods, as more or less by definition, DESTROY() will be called on an
  # object of the right class. Basically, for T_foo_OBJ, use T_foo_REF
  # instead. T_REF_IV_PTR was added in v5.22.0.
  $xstype =~ s/OBJ$/REF/ || $xstype =~ s/^T_REF_IV_PTR$/T_PTRREF/
    if $self->{xsub_func_name} =~ /DESTROY$/;

  # In the presence of length(foo), override the normal typedef - which
  # would emit SvPV_nolen(...) - and instead, emit
  # SvPV(..., STRLEN_length_of_foo)
  if (    $xstype eq 'T_PV'
      and $self->{xsub_map_argname_to_islength}->{$var})
  {
    print "\t$var" unless $printed_name;
    print " = ($type)SvPV($arg, STRLEN_length_of_$var);\n";
    die "default value not supported with length(NAME) supplied"
      if defined $self->{xsub_map_argname_to_default}->{$var};
    return;
  }

  # The type looked up in the eval is Foo__Bar rather than Foo::Bar
  $type =~ tr/:/_/ unless $self->{config_RetainCplusplusHierarchicalTypes};

  # Get the ExtUtils::Typemaps::InputMap object associated with the
  # xstype. This contains the template of the code to be embedded,
  # e.g. 'SvPV_nolen($arg)'
  my $inputmap = $typemaps->get_inputmap(xstype => $xstype);
  if (not defined $inputmap) {
    $self->blurt("Error: No INPUT definition for type '$type', typekind '$xstype' found");
    return;
  }

  # Get the text of the template, with a few transformations to make it
  # work better with fussy C compilers. In particular, strip trailing
  # semicolons and remove any leading white space before a '#'.
  my $expr = $inputmap->cleaned_code;

  # Process DO_ARRAY_ELEM. This is an undocumented hack that makes the
  # horrible T_ARRAY typemap work. "DO_ARRAY_ELEM" appears as a token
  # in the INPUT and OUTPUT code for for T_ARRAY, within a "for each
  # element" loop, and the purpose of this branch is to substitute the
  # token for some real code which will process each element, based on the
  # type of the array elements (the $subtype).
  #
  # Note: This gruesome bit either needs heavy rethinking or
  # documentation. I vote for the former. --Steffen, 2011
  # Seconded, DAPM 2024.
  if ($expr =~ /DO_ARRAY_ELEM/) {
    my $subtypemap  = $typemaps->get_typemap(ctype => $subtype);
    if (not $subtypemap) {
      $self->report_typemap_failure($typemaps, $subtype);
      return;
    }

    my $subinputmap = $typemaps->get_inputmap(xstype => $subtypemap->xstype);
    if (not $subinputmap) {
      $self->blurt("Error: No INPUT definition for type '$subtype', typekind '" . $subtypemap->xstype . "' found");
      return;
    }

    my $subexpr = $subinputmap->cleaned_code;
    $subexpr =~ s/\$type/\$subtype/g;
    $subexpr =~ s/ntype/subtype/g;
    $subexpr =~ s/\$arg/ST(ix_$var)/g;
    $subexpr =~ s/\n\t/\n\t\t/g;
    $subexpr =~ s/is not of (.*\")/[arg %d] is not of $1, ix_$var + 1/g;
    $subexpr =~ s/\$var/${var}\[ix_$var - $argoff]/;
    $expr =~ s/DO_ARRAY_ELEM/$subexpr/;
  }

  if ($expr =~ m#/\*.*scope.*\*/#i) {  # "scope" in C comments
    $self->{xsub_SCOPE_enabled} = 1;
  }

  # Specify the environment for when the typemap template is evalled.
  my $eval_vars = {
    var           => $var,
    printed_name  => $printed_name,
    type          => $type,
    ntype         => $ntype,
    subtype       => $subtype,
    num           => $num,
    arg           => $arg,
    argoff        => $argoff,
  };

  # Now, finally, emit the actual variable declaration and
  # initialisation line(s). (The variable type will already have been
  # emitted).

  if (defined($self->{xsub_map_argname_to_default}->{$var})) {
    # Has a default value. Emit just the variable declaration, and
    # defer the initialisation.

    $expr =~ s/(\t+)/$1    /g;
    $expr =~ s/        /\t/g;

    # Emit the var name
    if ($printed_name) {
      print ";\n";
    }
    else {
      $self->eval_input_typemap_code(qq/print "\\t$var;\\n"/, $eval_vars);
    }

    if ($self->{xsub_map_argname_to_default}->{$var} eq 'NO_INIT') {
      # for foo(a, b = NO_INIT), add code to initialise later only if
      # an arg was supplied.
      $self->{xsub_deferred_code_lines} .= $self->eval_input_typemap_code(
        qq/qq\a\\n\\tif (items >= $num) {\\n$expr;\\n\\t}\\n\a/,
        $eval_vars
      );
    }
    else {
      # for foo(a, b = default), add code to initialise later to either
      # the arg or default value
      $self->{xsub_deferred_code_lines} .= $self->eval_input_typemap_code(
        qq/qq\a\\n\\tif (items < $num)\\n\\t    $var = $self->{xsub_map_argname_to_default}->{$var};\\n\\telse {\\n$expr;\\n\\t}\\n\a/,
        $eval_vars
      );
    }
  }
  elsif ($self->{xsub_SCOPE_enabled} or $expr !~ /^\s*\$var =/) {
    # The template is likely a full block rather than a
    # '$var = ...' expression. Emit just the var now, and
    # defer the initialisation
    if ($printed_name) {
      print ";\n";
    }
    else {
      $self->eval_input_typemap_code(qq/print qq\a\\t$var;\\n\a/, $eval_vars);
    }

    $self->{xsub_deferred_code_lines}
      .= $self->eval_input_typemap_code(qq/qq\a\\n$expr;\\n\a/, $eval_vars);
  }
  else {
    # The template starts with '$var = ...', so no need to emit
    # the variable name, just the expr.

    # For function pointers, the variable name has already been emitted.
    # If we emit $expr, we end up with nonsense like
    #   int (*var)(int) var = INT2PTR(SvIV(ST(0)))
    #  where var gets emitted twice.  Abort for now.
    die "panic: do not know how to handle this branch for function pointers"
      if $printed_name;

    $self->eval_input_typemap_code(qq/print qq\a$expr;\\n\a/, $eval_vars);
  }
}


# $self->generate_output({ key = value, ... })
#
#   type        'char *' etc
#   num         the parameter number, corresponds to ST(num-1)
#   var         the parameter name, such as 'RETVAL'
#   do_setmagic whether to call set magic after assignment
#   do_push     whether to push a new mortal onto the stack
#
# Emit code to: possibly create, then set the value of, and possibly
# push, an output SV.
#
# This function emits code such as "sv_setiv(ST(0), (IV)foo)", based on the
# typemap OUTPUT entry associated with $type, passing the typemap code
# through a double-quotish context eval first to expand variables such as
# $arg, $var.
#
# It recognises that output typemaps fall into two basic categories,
# exemplified by:
#
#     sv_setFoo($arg, (Foo)$var));
#     $arg = newFoo($var);
#
# When $var is 'RETVAL':
#     for the first category, it creates a new mortal, then uses the
#     typemap to set its value, then stores that SV at ST(0);
#     for the second, it stores the SV created by the typemap and mortalises
#     it.
# For other OUTPUT vars, it just uses the typemap to update the arg's
# value and doesn't distinguish between the two categories.
#
# Some typemaps evaluate to different code depending on whether the var is
# RETVAL, e.g T_BOOL is currently defined as:
#
#    ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);" : \"sv_setsv($arg, boolSV($var));"}
#
# So we examine the typemap *after* evaluation to determine whether it's
# of the form '$arg = ' or not.
#
# Finally, note that do_push is true when processing an OUTLIST arg.
#
# This function sometimes emits a C variable called RETVALSV. This is
# private and shouldn't be referenced within XS code or typemaps.

sub generate_output {
  my ExtUtils::ParseXS $self = shift;
  my $argsref = shift;
  my ($type, $num, $var, $do_setmagic, $do_push)
    = @{$argsref}{qw(type num var do_setmagic do_push)};

  my $arg = "ST(" . ($num - ($num != 0)) . ")";

  my $typemaps = $self->{typemaps_object};

  # whitespace-tidy the type
  $type = ExtUtils::Typemaps::tidy_type($type);

  # XXX not sure why this is needed. We pass $type rather than local
  # $argsref->{type} to the eval anyway.
  local $argsref->{type} = $type;

  if ($type =~ /^array\(([^,]*),(.*)\)/) {
    # Handle the implicit array return type, "array(type, nlelem)"
    # specially. It returns a mortal string which is a copy of $var,
    # which it assumes is a C array of type 'type' with 'nelem' elements.
    print "\t$arg = sv_newmortal();\n";
    print "\tsv_setpvn($arg, (char *)$var, $2 * sizeof($1));\n";
    print "\tSvSETMAGIC($arg);\n" if $do_setmagic;
  }
  else {
    # Handle a normal return type via a typemap.

    # Get the output map entry for this type; complain if not found.
    my $typemap = $typemaps->get_typemap(ctype => $type);
    if (not $typemap) {
      $self->report_typemap_failure($typemaps, $type);
      return;
    }

    my $outputmap = $typemaps->get_outputmap(xstype => $typemap->xstype);
    if (not $outputmap) {
      $self->blurt("Error: No OUTPUT definition for type '$type', typekind '"
                   . $typemap->xstype . "' found");
      return;
    }

    # $ntype: normalised type ('Foo *' becomes 'FooPtr' etc): one of the
    # valid vars which can appear within a typemap template.
    (my $ntype = $type) =~ s/\s*\*/Ptr/g;
    $ntype =~ s/\(\)//g;

    # $subtype is really just for the T_ARRAY / DO_ARRAY_ELEM code below,
    # where it's the type of each array element. But it's also passed to
    # the typemap template (although undocumented and virtually unused).
    (my $subtype = $ntype) =~ s/(?:Array)?(?:Ptr)?$//;

    # The type looked up in the eval is Foo__Bar rather than Foo::Bar
    $type =~ tr/:/_/ unless $self->{config_RetainCplusplusHierarchicalTypes};

    # Specify the environment for when the typemap template is evalled.
    my $eval_vars = {%$argsref, subtype => $subtype,
                      ntype => $ntype, arg => $arg, type => $type };

    # Get the text of the typemap template, with a few transformations to
    # make it work better with fussy C compilers. In particular, strip
    # trailing semicolons and remove any leading white space before a '#'.
    my $expr = $outputmap->cleaned_code;

    # In the four branches of this big if/else, handle the four types of
    # var:
    #   the T_ARRAY / DO_ARRAY_ELEM hack
    #   RETVAL
    #   OUTLIST argname
    #   argname

    if ($expr =~ /DO_ARRAY_ELEM/) {
      # See the comments in generate_init() that explain the similar code
      # for the DO_ARRAY_ELEM hack there.
      my $subtypemap = $typemaps->get_typemap(ctype => $subtype);
      if (not $subtypemap) {
        $self->report_typemap_failure($typemaps, $subtype);
        return;
      }

      my $suboutputmap = $typemaps->get_outputmap(xstype => $subtypemap->xstype);
      if (not $suboutputmap) {
        $self->blurt("Error: No OUTPUT definition for type '$subtype', typekind '" . $subtypemap->xstype . "' found");
        return;
      }

      my $subexpr = $suboutputmap->cleaned_code;
      $subexpr =~ s/ntype/subtype/g;
      $subexpr =~ s/\$arg/ST(ix_$var)/g;
      $subexpr =~ s/\$var/${var}\[ix_$var]/g;
      $subexpr =~ s/\n\t/\n\t\t/g;
      $expr =~ s/DO_ARRAY_ELEM\n/$subexpr/;
      $self->eval_output_typemap_code("print qq\a$expr\a", $eval_vars);
      print "\t\tSvSETMAGIC(ST(ix_$var));\n" if $do_setmagic;
    }
    elsif ($var eq 'RETVAL') {
      # If the var is called RETVAL, then we return its value on the
      # stack
      my $orig_arg = $arg;
      my $indent;
      my $use_RETVALSV = 1;
      my $do_mortal = 0;
      my $do_copy_tmp = 1;
      my $pre_expr;

      # Evaluate the typemap, expanding any vars like $var and $arg.
      # So for example,
      #
      #     $arg = Foo($var);
      #
      # normally gets expanded to:
      #
      #     ST(0) = Foo(RETVAL);
      #
      # However, this is often then followed by a few more emitted lines
      # such as:
      #
      #     sv_2mortal(ST(0));
      #     SvSETMAGIC(ST(0));
      #
      # which involve inefficient multiple accesses to get the ST(0)
      # pointer.  So in this branch, as an optimisation, we declare a
      # temporary variable RETVALSV; then we use it rather than 'ST(0)'
      # for the value of $arg in the evalled typemap and in any other
      # emitted code, only storing to ST(0) finally. So our example code
      # above will be emitted as:
      #
      #     SV *RETVALSV;
      #     RETVALSV = Foo(RETVAL);
      #     RETVALSV = sv_2mortal(RETVALSV);
      #     SvSETMAGIC(RETVALSV);
      #     ST(0) = RETVALSV;
      #
      # Note that RETVALSV is set again from the return value of
      # sv_2mortal(), which means that the compiler doesn't have to save
      # the value of RETVALSV across the function call.
      #
      # There is a further special optimisation for the T_SV case,
      # where RETVAL is already of type SV* (i.e. $ntype eq 'SVPtr').
      # In the case where the typemap of of the form '$arg = Foo($var)',
      # (as opposed to 'sv_setFOO($arg, $var)'), then we don't declare
      # RETVALSV and just use RETVAL directly.
      #
      # Note that we evaluate the typemap early here, so that the various
      # regexes below such as /^\s*\Q$arg\E\s*=/ can be matched against
      # the *evalled* result of typemap entries such as
      #
      # ${ "$var" eq "RETVAL" ? \"$arg = $var;" : \"sv_setsv_mg($arg, $var);" }
      #
      # which may eval to something like "RETVALSV = RETVAL" and
      # subsequently match /^\s*\Q$arg\E =/ (where $arg is "RETVAL"), but
      # couldn't have matched against the original typemap.

      local $eval_vars->{arg} = $arg = 'RETVALSV';
      my $evalexpr = $self->eval_output_typemap_code("qq\a$expr\a", $eval_vars);

      if ($expr =~ /^\t\Q$arg\E = new/) {
        # XXX this branch is broken and is never taken.
        # But it doesn't matter, because the \Q$arg\E\s*= branch further
        # below will handle whatever is needed.
        #
        # Historically, the /\$arg = / branch was split into two by
        # perl-5.003_05-110-ga2baab1cc6. The normal branch emitted some C
        # code to say "if the SV is immortal, skip the mortalising".  But
        # if the value being assigned is the return value from a newRV()
        # call or similar, then we know it can't be immortal, so it
        # skipped emitting the extra test in the second branch.
        #
        # Later with perl-5.004_03-1569-gd689ffdd6d, the "emit C test for
        # immortal" code was removed, so the two branches became
        # functionally equivalent (and could have been merged into a
        # single branch at that point, but weren't).
        #
        # Then with v5.19.1-126-gfc5771079a, the regexes were changed to
        # match against $evalexpr rather than $expr, to better match code
        # patterns. But in this branch it still tries to match against
        # $expr, so now always fails. But it doesn't matter, because that
        # commit also added a different "don't mortalise if immortal"
        # test, seen in the /boolSV/ branch below, which will handle this
        # ok.
        $do_mortal = 1;
      }

      elsif ($evalexpr =~ /^\t\Q$arg\E\s*=\s*(boolSV\(|(&PL_sv_yes|&PL_sv_no|&PL_sv_undef)\s*;)/) {
        # An optimisation: in cases where the return value is an SV and
        # the style of the typemap indicates that the SV will be one of
        # the immortals, skip mortalizing it. This code doesn't detect all
        # possible immortal values; for example, it won't detect a
        # function or expression that only returns immortals. But since
        # its only an optimisation, it doesn't matter if some cases aren't
        # spotted.
        #
        # This RE must be tried before next elsif, as is it effectively a
        # special-case of the more general /\$arg =/ pattern.

        $do_copy_tmp = 0; #$arg will be a ST(X), no SV* RETVAL, no RETVALSV
        $use_RETVALSV = 0;
      }
      elsif ($evalexpr =~ /^\s*\Q$arg\E\s*=/) {
        # This is the more general case of the previous branch.
        # Detect a typemap that assigns an SV to the arg, rather than than
        # updating an SV; e.g.:
        #     $arg = newRV($var);
        # as opposed to
        #     sv_setiv($arg, (IV)$arg);
        # and if so, we just mortalise the SV rather than creating a
        # new temp and copying.

        # See comment above about the SVPtr optimisation
        $use_RETVALSV = 0 if $ntype eq "SVPtr";
        $do_mortal = 1;
      }
      else {
        # This is the opposite case to a '$arg = ' style typemap.
        # We assume it's something like  sv_setiv($arg, (IV)$arg); where
        # we need to create a new mortal for the typemap to update.
        $pre_expr = "RETVALSV = sv_newmortal();\n";
        # new mortals don't have set magic
        $do_setmagic = 0;
      }

      # if using RETVALSV, start a new block then declare it.
      if ($use_RETVALSV) {
        print "\t{\n\t    SV * RETVALSV;\n";
        $indent = "\t    ";
      } else {
        $indent = "\t";
      }

      # (typically) initialise RETVALSV
      print $indent.$pre_expr if $pre_expr;

      if ($use_RETVALSV) {
        # Indent the typemap code 1 level deeper.
        $evalexpr =~ s/^(\t|        )/$indent/gm;
        #"\t    \t" doesn't draw right in some IDEs
        #break down all \t into spaces
        $evalexpr =~ s/\t/        /g;
        #rebuild back into \t'es, \t==8 spaces, indent==4 spaces
        $evalexpr =~ s/        /\t/g;
      }
      else {
        # we want the typemap to look like one of these three cases:
        #
        #   RETVALSV = ...;    if $use_RETVALSV; else
        #   RETVAL = ...;      if the SVPtr optimisation is in place to
        #                         use RETVAL rather than RETVALSV, and
        #                         further use of the var is expected;
        #   ST(0) = ...;       otherwise.
        #
        # So for the last two forms revert 'RETVALSV' back.
        if ($do_mortal || $do_setmagic) {
          # $do_mortal or $do_setmagic imply further use of the variable
          $evalexpr =~ s/RETVALSV/RETVAL/g;
        }
        else {
          $evalexpr =~ s/RETVALSV/$orig_arg/g;
        }
      }

      # Emit the typemap, unless it's of the trivial "RETVAL = RETVAL"
      # form, which is sometimes generated for the SVPtr optimisation.
      print $evalexpr if $evalexpr !~ /^\s*RETVAL = RETVAL;$/;

      # Emit mortalisation and set magic code on the result SV if need be

      print $indent.'RETVAL'.($use_RETVALSV ? 'SV':'')
            .' = sv_2mortal(RETVAL'.($use_RETVALSV ? 'SV':'').");\n" if $do_mortal;
      print $indent.'SvSETMAGIC(RETVAL'.($use_RETVALSV ? 'SV':'').");\n" if $do_setmagic;

      # Emit the final 'ST(0) = RETVAL' or similar, unless ST(0)
      # was already assigned to earlier directly by the typemap.
      # The $do_copy_tmp condition (always true except for immortals)
      # means that this is usually done. But for immortals we only do
      # it if extra code has been emitted, i.e. mortalisation or set magic.
      print $indent."$orig_arg = RETVAL".($use_RETVALSV ? 'SV':'').";\n"
        if $do_mortal || $do_setmagic || $do_copy_tmp;
      print "\t}\n" if $use_RETVALSV;
    }

    elsif ($do_push) {
      # $do_push indicates that this is an OUTLIST value, so an SV with
      # the value should be pushed onto the stack
      print "\tPUSHs(sv_newmortal());\n";
      local $eval_vars->{arg} = "ST($num)";
      $self->eval_output_typemap_code("print qq\a$expr\a", $eval_vars);
      print "\tSvSETMAGIC($arg);\n" if $do_setmagic;
    }

    elsif ($arg =~ /^ST\(\d+\)$/) {
      # This is a normal OUTPUT var - i.e. a named parameter whose
      # corresponding arg on the stack should be updated with the
      # parameter's current value by using the code contained in the
      # output typemap.
      #
      # Note that for non-RETVAL args being *updated* (as opposed to
      # replaced), this branch relies on the typemap to Do The Right
      # Thing. For example, T_BOOL currently has this typemap entry:
      #
      # ${"$var" eq "RETVAL" ? \"$arg = boolSV($var);" : \"sv_setsv($arg, boolSV($var));"}
      #
      #  which means that if we hit this branch, $evalexpr will have been
      #  expanded to something like sv_setsv(ST(2), boolSV(foo))
      $self->eval_output_typemap_code("print qq\a$expr\a", $eval_vars);
      print "\tSvSETMAGIC($arg);\n" if $do_setmagic;
    }
  }
}


# These two subs just delegate to a method in a clean package, where there
# are as few lexical variables in scope as possible and the ones which are
# accessible (such as $arg) are the ones documented to be available when
# eval()ing (in double-quoted context) the initialiser on an INPUT or
# OUTPUT line such as 'int foo = SvIV($arg)'

sub eval_output_typemap_code {
  my ExtUtils::ParseXS $self = shift;
  my ($code, $other) = @_;
  return ExtUtils::ParseXS::Eval::eval_output_typemap_code($self, $code, $other);
}

sub eval_input_typemap_code {
  my ExtUtils::ParseXS $self = shift;
  my ($code, $other) = @_;
  return ExtUtils::ParseXS::Eval::eval_input_typemap_code($self, $code, $other);
}

1;

# vim: ts=2 sw=2 et:
