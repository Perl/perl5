package autouse;
#use strict;			# debugging only
use 5.003_90;			# ->can

$autouse::VERSION = '0.02';

my $debug = 0;

my %disable_w;

sub croak {
  require Carp;
  Carp::croak(@_);
}

sub import {
  shift;
  my $module = shift;
  if (exists $INC{"$module.pm"}) {
    unless (exists $INC{"Exporter.pm"}) {
      croak("use autouse with a module which has its own import()")
	if $module->can('import');
      return;			# Ignore import
    }
    croak("use autouse with a module which has its own import()")
      unless $module->can('import') == \&Exporter::import;
    local $Exporter::ExportLevel = $Exporter::ExportLevel;
    $Exporter::ExportLevel++;
    # $Exporter::Verbose = 1;
    my @args = @_;
    my $f;
    foreach $f (@args) {
      next unless $f =~ s/\((.*)\)$//;
      my $proto = $1;
      my $sub = index($f, "::") != -1 ? $f : "$module" . "::$f";
      croak("Prototype mismatch on `$sub' when autousing `$module':\n",
	    "\t`$proto' specified, the real one `", 
	    prototype($sub), "'")
	unless prototype($sub) eq $proto;
    }
    return $module->import(@args);
  }
  # It is not loaded: need to do real work.
  my $callpkg = caller(0);
  print "called from `$callpkg'.\n" if $debug;
  
  my ($func, $index);
  foreach $func (@_) {
    my $proto;
    $proto = $1 if $func =~ s/\((.*)\)$//;
    my $closure_import_func = $func; # Full name
    my $closure_func = $func;	# Name inside package
    $index = index($func, '::');
    
    if ($index == -1) {
      $closure_import_func = $callpkg . "::$func";
    } else {
      $closure_func = substr $func, $index + 2;
      croak("Trying to autouse into a different package") 
	unless substr($func, 0, $index) eq $module;
      $disable_w{$module} = 1;
    }
    my $load_sub = sub {
      {
	local $^W = exists $disable_w{$module};		# Redefinition
	eval "require $module";
	die $@ if $@;
	croak("Prototype mismatch on `$closure_import_func' ",
	      "after loading `$module':\n",
	      "\t`$proto' specified when autousing, the real one `", 
	      prototype($closure_import_func), "'")
	  if defined $proto 
	    and prototype($closure_import_func) ne $proto;
	local $^W = 0;		# Redefinition
	*$closure_import_func = \&{$module . "::$closure_func"}
	  unless \&$closure_import_func == \&{$module . "::$closure_func"};
      }
      print "In loader for `$module: $closure_import_func => $closure_func'.\n"
	if $debug;
      goto &$closure_import_func;
    };
    if (defined $proto) {
      *$closure_import_func = eval "sub ($proto) {&\$load_sub}";
    } else {
      *$closure_import_func = $load_sub;
    }
  }
}

1;

__END__

=head1 NAME

autouse - postpone load of modules until a function is used

=head1 SYNOPSIS

  use autouse 'Carp' => qw(carp croak);
  carp "this carp was predeclared and autoused ";


=head1 DESCRIPTION

If the module C<Module> is already loaded, then the declaration

  use autouse 'Module' => qw(func1 func2($;$) Module::func3);

is equivalent to

  use Module qw(func1 func2);

if C<Module> defines func2() with prototype C<($;$)>, and func1() and
func3() have no prototypes. (At least if C<Module> uses C<Exporter>'s
C<import>, otherwise it is a fatal error.)

If the module C<Module> is not loaded yet, then the above declaration
declares functions func1() and func2() in the current package, and
declares a function Module::func3(). When these functions are called,
they load the package C<Module> if needed, and substitute themselves
with the correct definitions.

=head1 WARNING

Using C<autouse> will move important steps of your program's execution
from compile time to runtime. This can

=over

=item *

Break the execution of your program if the module you C<autouse>d has
some initialization which it expects to be done early.

=item *

hide bugs in your code since important checks (like correctness of
prototypes) is moved from compile time to runtime. In particular, if
the prototype you specified on C<autouse> line is wrong, you will not
find it out until the corresponding function is executed. This will be
very unfortunate for functions which are not always called (note that
for such functions C<autouse>ing gives biggest win, for a workaround
see below).

=back

To alleviate the second problem (partially) it is advised to write
your scripts like this:

  use Module;
  use autouse Module => qw(carp($) croak(&$));
  carp "this carp was predeclared and autoused ";

The first line ensures that the errors in your argument specification
are found early.  When you ship your application you should comment
out the first line, since it makes the second one useless.

=head1 BUGS

If Module::func3() is autoused, and the module is loaded between the
C<autouse> directive and a call to Module::func3(), warnings about
redefinition would appear if warnings are enabled.

If Module::func3() is autoused, warnings are disabled when loading the
module via autoused functions.

=head1 AUTHOR

Ilya Zakharevich (ilya@math.ohio-state.edu)

=head1 SEE ALSO

perl(1).

=cut
