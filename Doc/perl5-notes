#!/usr/local/bin/perl5
# perl5 -x notes 2> expected > actual ; diff expected actual
open(EVAL, "| perl5 -x") || die "Can't pipe to perl5\n";
while (<DATA>) {
    m/prints ``(.*)''$/ && print STDERR $1,"\n";
    print EVAL $_;
}
__END__
#!/usr/local/bin/perl5
#
# Perl5a6 notes: Patchlevel 3
#
# This document is in the public domain.
#
# Written by Tony Sanders <sanders@bsdi.com>
#
# Quick examples of the new Perl5 features as of alpha6.  Look in the
# file Changes, the man page, and in the test suite (esp t/op/ref.t)
# for more information.  There are also a number of files in the alpha6
# release (e.g., tie*) that show how to use various features.  Also, there
# are a number of package modules in lib/*.pm that are of interest.
#
# Thanks to the following for their input:
#     Johan.Vromans@NL.net
#     Daniel Faken <absinthe@viva.chem.washington.edu>
#     Tom Christiansen <tchrist@wraeththu.cs.colorado.edu>
#     Dean Roehrich <roehrich@ferrari.cray.com>
#     Larry Wall <lwall@netlabs.com>
#     Lionel Cons <Lionel.Cons@cern.ch>
#

# BEGIN { }
	# executed at load time
	print "doody\n";
	BEGIN { print "howdy\n"; }		# prints ``howdy''
						# then prints ``doody''
# END { }
	# executed at exit time in reverse order of definition
	END { print "blue sky\n"; }		# will print ``blue sky''
	END { print "goodbye\n"; }		# will print ``goodbye''

# (expr?lval:lval) = value;
	# The (?:) operator can be used as an lvalue.
	$a = 1; $b = 2;
	(defined $b ? $a : $b) = 10;
	print "$a:$b\n";			# prints ``10:2''

# new functions: abs, chr, uc, ucfirst, lc, lcfirst
	print abs(-10), "\n";			# prints ``10''
	print chr(64), "\n";			# prints ``@''
	print uc("the"), "\n";			# prints ``THE''
	print ucfirst("the"), "\n";		# prints ``The''
	print lc("THE"), "\n";			# prints ``the''
	print lcfirst("THE"), "\n";		# prints ``tHE''

# references
	# references
	$thing1 = "testing";
	$ref = \$thing1;			# \ creates a reference
	print $$ref,"\n" if ${$ref} eq $$ref;	# deref, prints ``testing''

	# symbolic references
	sub bat { "baz"; }
	sub baz { print "foobar\n" };
	&{&bat};				# prints ``foobar''

# symbol table assignment: *foo = \&func;
	# replaces an item in the symbol table (function, scalar, array, hash)
	# *foo = \$bar		replaces the scalar
	# *foo = \%bar		replaces the hash table
	# *foo = \@bar		replaces the array
	# *foo = \&bar		replaces the function
	# *foo = *bar		all of the above (including FILEHANDLE!)
	# XXX: can't do just filehandles (yet)
	#
	# This can be used to import and rename a symbol from another package:
	#     *myfunc = \&otherpack::otherfunc;

# AUTOLOAD { ...; }
	# called if method not found, passed function name in $AUTOLOAD
	# @_ are the arguments to the function.
# goto &func;
	# goto's a function, used by AUTOLOAD to jump to the function
# qw/arg list/;   qw(arg list);
	# quoted words, yields a list; works like split(' ', 'arg list')
	# not a function, more like q//;
	{
	    package AutoLoader;
	    AUTOLOAD {
		eval "sub $AUTOLOAD" . '{ print "@_\n"}';
		goto &$AUTOLOAD }
	    package JAPH;
	    @ISA = (AutoLoader);
	    sub foo2 { &bar }
	    foo2 qw(Just another Perl hacker,);
	    # prints ``Just another Perl hacker,''
	}
# Larry notes:
# You might point out that there's a canned Autoloader base class in the
# library.  Another subtlety is that $AUTOLOAD is always in the same
# package as the AUTOLOAD routine, so if you call another package's
# AUTOLOAD explicitly you have to set $AUTOLOAD in that package first.

# my
	# lexical scoping
	sub samp1 { print $z,"\n" }
	sub samp2 { my($z) = "world"; &samp1 }
	$z = "hello";
	&samp2;				# prints ``hello''

# package;
	# empty package; for catching non-local variable references
	sub samp3 {
	    my $x = shift;		# local() would work also
	    package;			# empty package
	    $main::count += $x;		# this is ok.
	    # $y = 1;			# would be a compile time error
	}

# =>
	# works like comma (,); use for key/value pairs
        # sometimes used to disambiguate the final expression in a block
	# might someday supply warnings if you get out of sync
	%foo = ( abc => foo );
	print $foo{abc},"\n";		# prints ``foo''

# ::
	# works like tick (') (use of ' is deprecated in perl5)
        print $main::foo{abc},"\n";	# prints ``foo''

# bless ref;
	# Bless takes a reference and returns an "object"
	$oref = bless \$scalar;

# ->
	# dereferences an "object"
	$x = { def => bar };		# $x is ref to anonymous hash
	print $x->{def},"\n";		# prints ``bar''

	# method derefs must be bless'ed
	{
	    # initial cap is encouraged to avoid naming conflicts
	    package Sample;
	    sub samp4 { my($this) = shift; print $this->{def},"\n"; }
	    sub samp5 { print "samp5: ", $_[1], "\n"; }
	    $main::y = bless $main::x;	# $x is ref, $y is "object"
	}
	$y->samp4();			# prints ``bar''

	# indirect object calls (same as $y->samp5(arglist))
	samp5 $y arglist;		# prints ``samp5: arglist''

	# static method calls (often used for constructors, see below)
	samp5 Sample arglist;		# prints ``samp5: arglist''

# function calls without &
	sub samp6 { print "look ma\n"; }
	samp6;				# prints ``look ma''

	# "forward" decl
	sub samp7;
	samp7;                          # prints ``look pa''
	sub samp7 { print "look pa\n"; }

	# no decl requires ()'s or initial &
	&samp8;				# prints ``look da''
	samp8();			# prints ``look da''
	sub samp8 { print "look da\n"; }

# ref
	# returns "object" type
	{
	    package OBJ1;
	    $x = bless \$y;		# returns "object" $x in "class" OBJ1
	    print ref $x,"\n";		# prints ``OBJ1''
	}

	# and non-references return undef.
	$z = 1;
	print "non-ref\n" unless ref $z;	# prints ``non-ref''

	# ref's to "builtins" return type
	print ref \$ascalar,"\n";		# prints ``SCALAR''
	print ref \@array,"\n";			# prints ``ARRAY''
	print ref \%hash,"\n";			# prints ``HASH''
	sub func { print shift,"\n"; }
	print ref \&func,"\n";			# prints ``CODE''
	print ref \\$scalar,"\n";		# prints ``REF''

# tie
	# bind a variable to a package with magic functions:
        #     new, DESTROY, fetch, store, delete, firstkey, nextkey
	# The exact function list varies with the variable type,
	# see the man page and tie* for more details.
	# Usage: tie variable, PackageName, ARGLIST
	{
	    package TIEPACK;
	    sub new { print "NEW: @_\n"; local($x) = $_[1]; bless \$x }
	    sub fetch { print "fetch ", ref $_[0], "\n"; ${$_[0]} }
	    sub store { print "store $_[1]\n"; ${$_[0]} = $_[1] }
	    DESTROY { print "DESTROY ", ref $_[0], "\n" }
	}
	tie $h, TIEPACK, "black_tie";	# prints ``NEW: TIEPACK black_tie''
	print $h, "\n";			# prints ``fetch TIEPACK''
					# prints ``black_tie''
	$h = 'bar';			# prints ``store bar''
	untie $h;			# prints ``DESTROY SCALAR''

# References
	$sref = \$scalar;		# $$sref is scalar
	$aref = \@array;		# @$aref is array
	$href = \%hash;			# %$href is hash table
	$fref = \&func;			# &$fref is function
	$refref = \$fref;		# ref to ref to function
	&$$refref("call the function");	# prints ``call the function''

# Anonymous data-structures
	%hash = ( abc => foo );		# hash in perl4 (works in perl5 also)
	print $hash{abc},"\n";		# prints ``foo''
	$ref = { abc => bar };		# reference to anon hash
	print $ref->{abc},"\n";		# prints ``bar''

	@ary = ( 0, 1, 2 );		# array in perl4 (works in perl5 also)
	print $ary[1],"\n";		# prints ``1''
	$ref = [ 3, 4, 5 ];		# reference to anon array
	print $ref->[1],"\n";		# prints ``4''

# Nested data-structures
	@foo = ( 0, { name => foobar }, 2, 3 );		# $#foo == 3
	$aref = [ 0, { name => foobar }, 2, 3 ];	# ref to anon array
	$href = {					# ref to hash of arrays
	    John => [ Mary, Pat, Blanch ],
	    Paul => [ Sally, Jill, Jane ],
	    Mark => [ Ann, Bob, Dawn ],
	};
	print $href->{Paul}->[0], "\n";	# prints ``Sally''
	print $href->{Paul}[0],"\n";	# shorthand version, prints ``Sally''
	print @{$href->{Mark}},"\n";	# prints ``AnnBobDawn''

# @ISA
	# Multiple Inheritance (get rich quick)
	{
	    package OBJ2; sub abc { print "abc\n"; }
	    package OBJ3; sub def { print "def\n"; }
	    package OBJ4; @ISA = ("OBJ2", "OBJ3");
	    $x = bless { foo => bar };
	    $x->abc;					# prints ``abc''
	    $x->def;					# prints ``def''
	}

# Packages, Classes, Objects, Methods, Constructors, Destructors, etc.
    	# XXX: need more explinations and samples
	{
	    package OBJ5;
	    sub new { print "NEW: @_\n"; my($x) = "empty"; bless \$x }
	    sub output { my($this) = shift; print "value = $$this\n"; }
	    DESTROY { print "OBJ5 DESTROY\n" }
	}
	# Constructors are often written as static method calls:
	$x = new OBJ5;		# prints ``NEW: OBJ5''
	$x->output;		# prints ``value = empty''
	# The destructor is responsible for calling any base class destructors.
	undef $x;		# prints ``OBJ5 DESTROY''

# require Package;
	# same as:  BEGIN { require 'Package.pm'; }
# require <float>;
	# checks against the perl version number
	require 5.000;		# requires perl 5.0 or better

# Package Modules
# ===============
# Yes, these are all very sketchy.  See the .pm file for details.

# DynamicLoader (builtin)
	# Public: &bootstrap
	# Load a shared library package on systems that support it
	# This incomplete example was extracted from lib/POSIX.pm
	#
	# package POSIX;
	# requires Exporter; require AutoLoader;
	# @ISA = (Exporter, AutoLoader, DynamicLoader);
	# @EXPORT = qw(closedir, opendir, [..., lots of functions]);
	# bootstrap POSIX;

# Larry notes:
# The gist of it is that DynamicLoader::bootstrap is only called if main.c
# didn't already define MYPACKAGE::bootstrap.  So the .pm file doesn't know
# (or care) whether the module is statically or dynamically loaded.

# AutoLoader.pm
	# Public: &AUTOLOAD
	# Causes functions from .../lib/perl/auto/PACKAGE/*.al to autoload
	# when used but not defined.

# Config.pm
	# Exports: %Config
	# The data from the Configure script for perl programs (yeah)

# English.pm
	# Exports: (lots of verbose variables)
	# The "english" versions of things like $_ $| $=

# Exporter.pm
	# Public: &import
	# import PACKAGE [@symbols]
	# requires PACKAGE to define @EXPORT
	{
	    package FOOBAR;  
	    require Exporter;
	    @ISA = (Exporter);
	    @EXPORT = (foo, bar);
	    sub foo { print "FOO\n" };
	    sub bar { print "BAR\n" };
	    1;
	    package BAT;
	    # require FOOBAR;	# not in this example
	    import FOOBAR;
	    @ISA = ();
	    &foo;			# prints ``FOO''
	}

# FileHandle.pm
	# Exports: (lots of filehandle functions)
	# English versions of various filehandle operations

# Hostname.pm
	# Exports: &hostname
	# Routine to get hostname
	# {
	#    require Hostname; import Hostname;
	#    print &hostname,"\n";	# prints your hostname
	# }

# POSIX.pm
	# Exports: (posix functions and defines)
	# POSIX.1 bindings

# SDBM_File.pm
	# SDBM interfaces (use with `tie')
	# Other DBM interfaces work the same way

# when the script exits the END section gets executed and prints ``goodbye''
# ENDs are executed in reverse order of definition. prints ``blue sky''
__END__
