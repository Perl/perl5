use strict;
use warnings;
use Test::More;

use XS::APItest;

# Code magics with 'clone_cv' function
{
    my sub lexsub { }
    BEGIN {
        ## arranging to get code magic on a protosub early enough that we
        ## get to run the clone_cv operation at all is nontrivial.
        sv_magicv2_add(&{ find_lexical_protosub('&lexsub') },
            copy_clonecv => \"this-is-protosub");
    }

    my $cv = \&lexsub;
    is ${ MgAUXSV(&{$cv}, 'copy_clonecv') }, "this-is-clone",
        'MgAUXSV is copied by clone_cv and incremented';
}

done_testing;
