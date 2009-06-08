package MakeMaker::Test::NoXS;

# Disable all XS loading.

use Carp;

require DynaLoader;
require XSLoader;

no warnings 'redefine';
*DynaLoader::bootstrap = sub { confess "Tried to load XS for @_"; };
*XSLoader::load        = sub { confess "Tried to load XS for @_"; };

1;
