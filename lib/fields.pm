package fields;

=head1 NAME

fields - compile-time class fields

=head1 SYNOPSIS

    {
        package Foo;
        use fields qw(foo bar _private);
    }
    ...
    my Foo $var = new Foo;
    $var->{foo} = 42;

    # This will generate a compile-time error.
    $var->{zap} = 42;

    {
        package Bar;
        use base 'Foo';
        use fields 'bar';             # hides Foo->{bar}
        use fields qw(baz _private);  # not shared with Foo
    }

=head1 DESCRIPTION

The C<fields> pragma enables compile-time verified class fields.  It
does so by updating the %FIELDS hash in the calling package.

If a typed lexical variable holding a reference is used to access a
hash element and the %FIELDS hash of the given type exists, then the
operation is turned into an array access at compile time.  The %FIELDS
hash maps from hash element names to the array indices.  If the hash
element is not present in the %FIELDS hash, then a compile-time error
is signaled.

Since the %FIELDS hash is used at compile-time, it must be set up at
compile-time too.  This is made easier with the help of the 'fields'
and the 'base' pragma modules.  The 'base' pragma will copy fields
from base classes and the 'fields' pragma adds new fields.  Field
names that start with an underscore character are made private to a
class and are not visible to subclasses.  Inherited fields can be
overridden but will generate a warning if used together with the C<-w>
switch.

The effect of all this is that you can have objects with named fields
which are as compact and as fast arrays to access.  This only works
as long as the objects are accessed through properly typed variables.
For untyped access to work you have to make sure that a reference to
the proper %FIELDS hash is assigned to the 0'th element of the array
object (so that the objects can be treated like an pseudo-hash).  A
constructor like this does the job:

  sub new
  {
      my $class = shift;
      no strict 'refs';
      my $self = bless [\%{"$class\::FIELDS"}], $class;
      $self;
  }


=head1 SEE ALSO

L<base>,
L<perlref/Pseudo-hashes: Using an array as a hash>

=cut

use 5.005_64;
use strict;
no strict 'refs';
our(%attr, $VERSION);

$VERSION = "1.01";

# some constants
sub _PUBLIC    () { 1 }
sub _PRIVATE   () { 2 }

# The %attr hash holds the attributes of the currently assigned fields
# per class.  The hash is indexed by class names and the hash value is
# an array reference.  The first element in the array is the lowest field
# number not belonging to a base class.  The remaining elements' indices
# are the field numbers.  The values are integer bit masks, or undef
# in the case of base class private fields (which occupy a slot but are
# otherwise irrelevant to the class).

sub import {
    my $class = shift;
    return unless @_;
    my $package = caller(0);
    my $fields = \%{"$package\::FIELDS"};
    my $fattr = ($attr{$package} ||= [1]);
    my $next = @$fattr;

    if ($next > $fattr->[0]
	and ($fields->{$_[0]} || 0) >= $fattr->[0])
    {
	# There are already fields not belonging to base classes.
	# Looks like a possible module reload...
	$next = $fattr->[0];
    }
    foreach my $f (@_) {
	my $fno = $fields->{$f};

	# Allow the module to be reloaded so long as field positions
	# have not changed.
	if ($fno and $fno != $next) {
	    require Carp;
            if ($fno < $fattr->[0]) {
                Carp::carp("Hides field '$f' in base class") if $^W;
            } else {
                Carp::croak("Field name '$f' already in use");
            }
	}
	$fields->{$f} = $next;
        $fattr->[$next] = ($f =~ /^_/) ? _PRIVATE : _PUBLIC;
	$next += 1;
    }
    if (@$fattr > $next) {
	# Well, we gave them the benefit of the doubt by guessing the
	# module was reloaded, but they appear to be declaring fields
	# in more than one place.  We can't be sure (without some extra
	# bookkeeping) that the rest of the fields will be declared or
	# have the same positions, so punt.
	require Carp;
	Carp::croak ("Reloaded module must declare all fields at once");
    }
}

sub inherit  # called by base.pm when $base_fields is nonempty
{
    my($derived, $base) = @_;
    my $base_attr = $attr{$base};
    my $derived_attr = $attr{$derived} ||= [];
    my $base_fields    = \%{"$base\::FIELDS"};
    my $derived_fields = \%{"$derived\::FIELDS"};

    $derived_attr->[0] = $base_attr ? scalar(@$base_attr) : 1;
    while (my($k,$v) = each %$base_fields) {
	my($fno);
	if ($fno = $derived_fields->{$k} and $fno != $v) {
	    require Carp;
	    Carp::croak ("Inherited %FIELDS can't override existing %FIELDS");
	}
	if ($base_attr->[$v] & _PRIVATE) {
	    $derived_attr->[$v] = undef;
	} else {
	    $derived_attr->[$v] = $base_attr->[$v];
	    $derived_fields->{$k} = $v;
	}
     }
}

sub _dump  # sometimes useful for debugging
{
   for my $pkg (sort keys %attr) {
      print "\n$pkg";
      if (@{"$pkg\::ISA"}) {
         print " (", join(", ", @{"$pkg\::ISA"}), ")";
      }
      print "\n";
      my $fields = \%{"$pkg\::FIELDS"};
      for my $f (sort {$fields->{$a} <=> $fields->{$b}} keys %$fields) {
         my $no = $fields->{$f};
         print "   $no: $f";
         my $fattr = $attr{$pkg}[$no];
         if (defined $fattr) {
            my @a;
	    push(@a, "public")    if $fattr & _PUBLIC;
            push(@a, "private")   if $fattr & _PRIVATE;
            push(@a, "inherited") if $no < $attr{$pkg}[0];
            print "\t(", join(", ", @a), ")";
         }
         print "\n";
      }
   }
}

1;
