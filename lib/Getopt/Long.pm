package Getopt::Long;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(GetOptions);


# newgetopt.pl -- new options parsing

# SCCS Status     : @(#)@ newgetopt.pl	1.14
# Author          : Johan Vromans
# Created On      : Tue Sep 11 15:00:12 1990
# Last Modified By: Johan Vromans
# Last Modified On: Sat Feb 12 18:24:02 1994
# Update Count    : 138
# Status          : Okay

################ Introduction ################
#
# This package implements an extended getopt function. This function adheres
# to the new syntax (long option names, no bundling).
# It tries to implement the better functionality of traditional, GNU and
# POSIX getopt functions.
# 
# This program is Copyright 1990,1994 by Johan Vromans.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.

################ Description ################
#
# Usage:
# 
#    require "newgetopt.pl";
#    ...change configuration values, if needed...
#    $result = &NGetOpt (...option-descriptions...);
# 
# Each description should designate a valid perl identifier, optionally
# followed by an argument specifier.
# 
# Values for argument specifiers are:
# 
#   <none>   option does not take an argument
#   !        option does not take an argument and may be negated
#   =s :s    option takes a mandatory (=) or optional (:) string argument
#   =i :i    option takes a mandatory (=) or optional (:) integer argument
#   =f :f    option takes a mandatory (=) or optional (:) real number argument
# 
# If option "name" is set, it will cause the perl variable $opt_name to
# be set to the specified value. The calling program can use this
# variable to detect whether the option has been set. Options that do
# not take an argument will be set to 1 (one).
# 
# Options that take an optional argument will be defined, but set to ''
# if no actual argument has been supplied.
# 
# If an "@" sign is appended to the argument specifier, the option is
# treated as an array. Value(s) are not set, but pushed into array
# @opt_name.
# 
# Options that do not take a value may have an "!" argument spacifier to
# indicate that they may be negated. E.g. "foo!" will allow -foo (which
# sets $opt_foo to 1) and -nofoo (which will set $opt_foo to 0).
# 
# The option name may actually be a list of option names, separated by
# '|'s, e.g. "foo|bar|blech=s". In this example, options 'bar' and
# 'blech' will set $opt_foo instead.
# 
# Option names may be abbreviated to uniqueness, depending on
# configuration variable $autoabbrev.
# 
# Dashes in option names are allowed (e.g. pcc-struct-return) and will
# be translated to underscores in the corresponding perl variable (e.g.
# $opt_pcc_struct_return).  Note that a lone dash "-" is considered an
# option, corresponding perl identifier is $opt_ .
# 
# A double dash "--" signals end of the options list.
# 
# If the first option of the list consists of non-alphanumeric
# characters only, it is interpreted as a generic option starter.
# Everything starting with one of the characters from the starter will
# be considered an option.
# 
# The default values for the option starters are "-" (traditional), "--"
# (POSIX) and "+" (GNU, being phased out).
# 
# Options that start with "--" may have an argument appended, separated
# with an "=", e.g. "--foo=bar".
# 
# If configuration varaible $getopt_compat is set to a non-zero value,
# options that start with "+" may also include their arguments,
# e.g. "+foo=bar".
# 
# A return status of 0 (false) indicates that the function detected
# one or more errors.
#
################ Some examples ################
# 
# If option "one:i" (i.e. takes an optional integer argument), then
# the following situations are handled:
# 
#    -one -two		-> $opt_one = '', -two is next option
#    -one -2		-> $opt_one = -2
# 
# Also, assume "foo=s" and "bar:s" :
# 
#    -bar -xxx		-> $opt_bar = '', '-xxx' is next option
#    -foo -bar		-> $opt_foo = '-bar'
#    -foo --		-> $opt_foo = '--'
# 
# In GNU or POSIX format, option names and values can be combined:
# 
#    +foo=blech		-> $opt_foo = 'blech'
#    --bar=		-> $opt_bar = ''
#    --bar=--		-> $opt_bar = '--'
# 
################ Configuration values ################
# 
#   $autoabbrev      Allow option names to be abbreviated to uniqueness.
#                    Default is 1 unless environment variable
#                    POSIXLY_CORRECT has been set.
# 
#   $getopt_compat   Allow '+' to start options.
#                    Default is 1 unless environment variable
#                    POSIXLY_CORRECT has been set.
# 
#   $option_start    Regexp with option starters.
#                    Default is (--|-) if environment variable
#                    POSIXLY_CORRECT has been set, (--|-|\+) otherwise.
# 
#   $order           Whether non-options are allowed to be mixed with
#                    options.
#                    Default is $REQUIRE_ORDER if environment variable
#                    POSIXLY_CORRECT has been set, $PERMUTE otherwise.
# 
#   $ignorecase      Ignore case when matching options. Default is 1.
# 
#   $debug           Enable debugging output. Default is 0.

################ History ################
# 
# 12-Feb-1994		Johan Vromans	
#    Added "!" for negation.
#    Released to the net.
#
# 26-Aug-1992		Johan Vromans	
#    More POSIX/GNU compliance.
#    Lone dash and double-dash are now independent of the option prefix
#      that is used.
#    Make errors in NGetOpt parameters fatal.
#    Allow options to be mixed with arguments.
#      Check $ENV{"POSIXLY_CORRECT"} to suppress this.
#    Allow --foo=bar and +foo=bar (but not -foo=bar).
#    Allow options to be abbreviated to minimum needed for uniqueness.
#      (Controlled by configuration variable $autoabbrev.)
#    Allow alias names for options (e.g. "foo|bar=s").
#    Allow "-" in option names (e.g. --pcc-struct-return). Dashes are
#      translated to "_" to form valid perl identifiers
#      (e.g. $opt_pcc_struct_return). 
#
# 2-Jun-1992		Johan Vromans	
#    Do not use //o to allow multiple NGetOpt calls with different delimeters.
#    Prevent typeless option from using previous $array state.
#    Prevent empty option from being eaten as a (negative) number.
#
# 25-May-1992		Johan Vromans	
#    Add array options. "foo=s@" will return an array @opt_foo that
#    contains all values that were supplied. E.g. "-foo one -foo -two" will
#    return @opt_foo = ("one", "-two");
#    Correct bug in handling options that allow for a argument when followed
#    by another option.
#
# 4-May-1992		Johan Vromans	
#    Add $ignorecase to match options in either case.
#    Allow '' option.
#
# 19-Mar-1992		Johan Vromans	
#    Allow require from packages.
#    NGetOpt is now defined in the package that requires it.
#    @ARGV and $opt_... are taken from the package that calls it.
#    Use standard (?) option prefixes: -, -- and +.
#
# 20-Sep-1990		Johan Vromans	
#    Set options w/o argument to 1.
#    Correct the dreadful semicolon/require bug.

################ Configuration Section ################

{ 

    # Values for $order. See GNU getopt.c for details.
    $REQUIRE_ORDER = 0;
    $PERMUTE = 1;
    $RETURN_IN_ORDER = 2;
    $RETURN_IN_ORDER = 2; # avoid typo warning with -w

    # Handle POSIX compliancy.
    if ( defined $ENV{"POSIXLY_CORRECT"} ) {
	$autoabbrev = 0;	# no automatic abbrev of options (???)
	$getopt_compat = 0;	# disallow '+' to start options
	$option_start = "(--|-)";
	$order = $REQUIRE_ORDER;
    }
    else {
	$autoabbrev = 1;	# automatic abbrev of options
	$getopt_compat = 1;	# allow '+' to start options
	$option_start = "(--|-|\\+)";
	$order = $PERMUTE;
    }

    # Other configurable settings.
    $debug = 0;			# for debugging
    $ignorecase = 1;		# ignore case when matching options
    $argv_end = "--";		# don't change this!
}

################ Subroutines ################

sub GetOptions {

    @optionlist = @_;	#';

    local ($[) = 0;
    local ($genprefix) = $option_start;
    local ($argend) = $argv_end;
    local ($error) = 0;
    local ($opt, $arg, $type, $mand, %opctl);
    local ($pkg) = (caller)[0];
    local ($optarg);
    local (%aliases);
    local (@ret) = ();

    print STDERR "NGetOpt 1.14 -- called from $pkg\n" if $debug;

    # See if the first element of the optionlist contains option
    # starter characters.
    if ( $optionlist[0] =~ /^\W+$/ ) {
	$genprefix = shift (@optionlist);
	# Turn into regexp.
	$genprefix =~ s/(\W)/\\$1/g;
	$genprefix = "[" . $genprefix . "]";
    }

    # Verify correctness of optionlist.
    %opctl = ();
    foreach $opt ( @optionlist ) {
	$opt =~ tr/A-Z/a-z/ if $ignorecase;
	if ( $opt !~ /^(\w+[-\w|]*)?(!|[=:][infse]@?)?$/ ) {
	    die ("Error in option spec: \"", $opt, "\"\n");
	    $error++;
	    next;
	}
	local ($o, $c, $a) = ($1, $2);

	if ( ! defined $o ) {
	    $opctl{''} = defined $c ? $c : '';
	}
	else {
	    # Handle alias names
	    foreach ( split (/\|/, $o)) {
		if ( defined $c && $c eq '!' ) {
		    $opctl{"no$_"} = $c;
		    $c = '';
		}
		$opctl{$_} = defined $c ? $c : '';
		if ( defined $a ) {
		    # Note alias.
		    $aliases{$_} = $a;
		}
		else {
		    # Set primary name.
		    $a = $_;
		}
	    }
	}
    }
    @opctl = sort(keys (%opctl)) if $autoabbrev;

    return 0 if $error;

    if ( $debug ) {
	local ($arrow, $k, $v);
	$arrow = "=> ";
	while ( ($k,$v) = each(%opctl) ) {
	    print STDERR ($arrow, "\$opctl{\"$k\"} = \"$v\"\n");
	    $arrow = "   ";
	}
    }

    # Process argument list

    while ( $#ARGV >= 0 ) {

	# >>> See also the continue block <<<

	#### Get next argument ####

	$opt = shift (@ARGV);
	print STDERR ("=> option \"", $opt, "\"\n") if $debug;
	$arg = undef;
	$optarg = undef;
	$array = 0;

	#### Determine what we have ####

	# Double dash is option list terminator.
	if ( $opt eq $argend ) {
	    unshift (@ret, @ARGV) if $order == $PERMUTE;
	    return ($error == 0);
	}
	elsif ( $opt =~ /^$genprefix/ ) {
	    # Looks like an option.
	    $opt = $';		# option name (w/o prefix)
	    # If it is a long opt, it may include the value.
	    if (($+ eq "--" || ($getopt_compat && $+ eq "+")) && 
		$opt =~ /^([^=]+)=/ ) {
		$opt = $1;
		$optarg = $';
		print STDERR ("=> option \"", $opt, 
			      "\", optarg = \"$optarg\"\n")
		    if $debug;
	    }

	}
	# Not an option. Save it if we may permute...
	elsif ( $order == $PERMUTE ) {
	    push (@ret, $opt);
	    next;
	}
	# ...otherwise, terminate.
	else {
	    # Push back and exit.
	    unshift (@ARGV, $opt);
	    return ($error == 0);
	}

	#### Look it up ###

	$opt =~ tr/A-Z/a-z/ if $ignorecase;

	local ($tryopt) = $opt;
	if ( $autoabbrev ) {
	    local ($pat, @hits);

	    # Turn option name into pattern.
	    ($pat = $opt) =~ s/(\W)/\\$1/g;
	    # Look up in option names.
	    @hits = grep (/^$pat/, @opctl);
	    print STDERR ("=> ", 0+@hits, " hits (@hits) with \"$pat\" ",
			  "out of ", 0+@opctl, "\n")
		if $debug;

	    # Check for ambiguous results.
	    unless ( (@hits <= 1) || (grep ($_ eq $opt, @hits) == 1) ) {
		print STDERR ("Option ", $opt, " is ambiguous (",
			      join(", ", @hits), ")\n");
		$error++;
		next;
	    }

	    # Complete the option name, if appropriate.
	    if ( @hits == 1 && $hits[0] ne $opt ) {
		$tryopt = $hits[0];
		print STDERR ("=> option \"$opt\" -> \"$tryopt\"\n")
		    if $debug;
	    }
	}

	unless  ( defined ( $type = $opctl{$tryopt} ) ) {
	    print STDERR ("Unknown option: ", $opt, "\n");
	    $error++;
	    next;
	}
	$opt = $tryopt;
	print STDERR ("=> found \"$type\" for ", $opt, "\n") if $debug;

	#### Determine argument status ####

	# If it is an option w/o argument, we're almost finished with it.
	if ( $type eq '' || $type eq '!' ) {
	    if ( defined $optarg ) {
		print STDERR ("Option ", $opt, " does not take an argument\n");
		$error++;
	    }
	    elsif ( $type eq '' ) {
		$arg = 1;		# supply explicit value
	    }
	    else {
		substr ($opt, 0, 2) = ''; # strip NO prefix
		$arg = 0;		# supply explicit value
	    }
	    next;
	}

	# Get mandatory status and type info.
	($mand, $type, $array) = $type =~ /^(.)(.)(@?)$/;

	# Check if there is an option argument available.
	if ( defined $optarg ? ($optarg eq '') : ($#ARGV < 0) ) {

	    # Complain if this option needs an argument.
	    if ( $mand eq "=" ) {
		print STDERR ("Option ", $opt, " requires an argument\n");
		$error++;
	    }
	    if ( $mand eq ":" ) {
		$arg = $type eq "s" ? '' : 0;
	    }
	    next;
	}

	# Get (possibly optional) argument.
	$arg = defined $optarg ? $optarg : shift (@ARGV);

	#### Check if the argument is valid for this option ####

	if ( $type eq "s" ) {	# string
	    # A mandatory string takes anything. 
	    next if $mand eq "=";

	    # An optional string takes almost anything. 
	    next if defined $optarg;
	    next if $arg eq "-";

	    # Check for option or option list terminator.
	    if ($arg eq $argend ||
		$arg =~ /^$genprefix.+/) {
		# Push back.
		unshift (@ARGV, $arg);
		# Supply empty value.
		$arg = '';
	    }
	    next;
	}

	if ( $type eq "n" || $type eq "i" ) { # numeric/integer
	    if ( $arg !~ /^-?[0-9]+$/ ) {
		if ( defined $optarg || $mand eq "=" ) {
		    print STDERR ("Value \"", $arg, "\" invalid for option ",
				  $opt, " (number expected)\n");
		    $error++;
		    undef $arg;	# don't assign it
		}
		else {
		    # Push back.
		    unshift (@ARGV, $arg);
		    # Supply default value.
		    $arg = 0;
		}
	    }
	    next;
	}

	if ( $type eq "f" ) { # fixed real number, int is also ok
	    if ( $arg !~ /^-?[0-9.]+$/ ) {
		if ( defined $optarg || $mand eq "=" ) {
		    print STDERR ("Value \"", $arg, "\" invalid for option ",
				  $opt, " (real number expected)\n");
		    $error++;
		    undef $arg;	# don't assign it
		}
		else {
		    # Push back.
		    unshift (@ARGV, $arg);
		    # Supply default value.
		    $arg = 0.0;
		}
	    }
	    next;
	}

	die ("NGetOpt internal error (Can't happen)\n");
    }

    continue {
	if ( defined $arg ) {
	    $opt = $aliases{$opt} if defined $aliases{$opt};
	    # Make sure a valid perl identifier results.
	    $opt =~ s/\W/_/g;
	    if ( $array ) {
		print STDERR ('=> push (@', $pkg, '\'opt_', $opt, ", \"$arg\")\n")
		    if $debug;
	        eval ('push(@' . $pkg . '\'opt_' . $opt . ", \$arg);");
	    }
	    else {
		print STDERR ('=> $', $pkg, '\'opt_', $opt, " = \"$arg\"\n")
		    if $debug;
	        eval ('$' . $pkg . '\'opt_' . $opt . " = \$arg;");
	    }
	}
    }

    if ( $order == $PERMUTE && @ret > 0 ) {
	unshift (@ARGV, @ret);
    }
    return ($error == 0);
}

################ Package return ################

1;


