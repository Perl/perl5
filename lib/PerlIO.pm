package PerlIO;

# Map layer name to package that defines it
my %alias = (encoding => 'Encode');

sub import
{
 my $class = shift;
 while (@_)
  {
   my $layer = shift;
   if (exists $alias{$layer})
    {
     $layer = $alias{$layer}
    }
   else
    {
     $layer = "${class}::$layer";
    }
   eval "require $layer";
   warn $@ if $@;
  }
}

1;
__END__

=head1 NAME

PerlIO - On demand loader for PerlIO::* name space

=head1 SYNOPSIS

  open($fh,">:foo",...)

=head1 DESCRIPTION

When an undefined layer 'foo' is encountered in an C<open> or C<binmode> layer
specification then C code performs the equivalent of:

  use PerlIO 'foo';

The perl code in PerlIO.pm then attempts to locate a layer by doing

  require PerlIO::foo;

Otherwise the C<PerlIO> package is a place holder for additional PerLIO related
functions.


=cut


