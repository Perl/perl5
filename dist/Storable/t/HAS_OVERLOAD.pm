package HAS_OVERLOAD;

use overload
	'""'	=> sub { ${$_[0]} }, fallback => 1;

sub make {
  my $package = shift;
  my $value = shift;
  bless \$value, $package;
}
our $loaded_count;
++$loaded_count;

1;
