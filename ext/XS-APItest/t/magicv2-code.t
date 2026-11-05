use strict;
use warnings;
use Test::More;

use XS::APItest;

# Code magics with 'pre_newcv' / 'post_newcv' function
{
    # pre/post_newcv are invoked during compiletime so we have to use a BEGIN
    # block to apply this magic early enough
    our $MG_LOG;

    sub testfunc {
        BEGIN {
            sv_magicv2_add(&{PL_compcv()}, 'log_on_newcv', \"A");
            sv_magicv2_add(&{PL_compcv()}, 'log_on_newcv', \"B");
        }
    }

    is $MG_LOG, join( ",", qw(
            pre_newcv(<A>:cv=PL_compcv)
            pre_newcv(<B>:cv=PL_compcv)
            post_newcv(<B>:compcv=PL_compcv)
            post_newcv(<A>:compcv=PL_compcv) ) ),
        'magic triggers invoked in correct order';
}

# Code magic 'pre_newcv' can alter optree
{#
    sub ten {
        BEGIN {
            sv_magicv2_add(&{PL_compcv()}, 'add_one_to_expr', undef);
        }
        9;
    }

    is ten(), 10,
        'magic pre_newcv trigger can alter optree';
}

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
