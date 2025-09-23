# An empty class file to test GH#23758; namely, that ending on an ADJUST
# phaser block does not break the `module_true` feature.

use v5.38; # enables feature 'module_true'
use experimental 'class';

class EndsWithADJUST;

ADJUST { }

# nothing further
