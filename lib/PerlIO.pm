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
