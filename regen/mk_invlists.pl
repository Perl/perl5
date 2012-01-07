#!perl -w
use 5.015;
use strict;
use warnings;
use Unicode::UCD "prop_invlist";
require 'regen/regen_lib.pl';

# This program outputs charclass_invlists.h, which contains various inversion
# lists in the form of C arrays that are to be used as-is for inversion lists.
# Thus, the lists it contains are essentially pre-compiled, and need only a
# light-weight fast wrapper to make them usable at run-time.

# As such, this code knows about the internal structure of these lists, and
# any change made to that has to be done here as well.  A random number stored
# in the headers is used to minimize the possibility of things getting
# out-of-sync, or the wrong data structure being passed.  Currently that
# random number is:
my $VERSION_DATA_STRUCTURE_TYPE = 1064334010;

my $out_fh = open_new('charclass_invlists.h', '>',
		      {style => '*', by => $0,
                      from => "Unicode::UCD"});

print $out_fh "/* See the generating file for comments */\n\n";

sub output_invlist ($$) {
    my $name = shift;
    my $invlist = shift;     # Reference to inversion list array

    # Output the inversion list $invlist using the name $name for it.
    # It is output in the exact internal form for inversion lists.

    my $zero_or_one;    # Is the last element of the header 0, or 1 ?

    # If the first element is 0, it goes in the header, instead of the body
    if ($invlist->[0] == 0) {
        shift @$invlist;

        $zero_or_one = 0;

        # Add a dummy 0 at the end so that the length is constant.  inversion
        # lists are always stored with enough room so that if they change from
        # beginning with 0, they don't have to grow.
        push @$invlist, 0;
    }
    else {
        $zero_or_one = 1;
    }

    print $out_fh "\nUV ${name}_invlist[] = {\n";

    print $out_fh "\t", scalar @$invlist, ",\t/* Number of elements */\n";
    print $out_fh "\t0,\t/* Current iteration position */\n";
    print $out_fh "\t$VERSION_DATA_STRUCTURE_TYPE, /* Version and data structure type */\n";
    print $out_fh "\t", $zero_or_one,
                  ",\t/* 0 if this is the first element of the list proper;",
                  "\n\t\t   1 if the next element is the first */\n";

    # The main body are the UVs passed in to this routine.  Do the final
    # element separately
    for my $i (0 .. @$invlist - 1 - 1) {
        print $out_fh "\t$invlist->[$i],\n";
    }

    # The final element does not have a trailing comma, as C can't handle it.
    print $out_fh "\t$invlist->[-1]\n";

    print $out_fh "};\n";
}

output_invlist("Latin1", [ 0, 256 ]);
output_invlist("AboveLatin1", [ 256 ]);

for my $prop (qw(
                ASCII
    )
) {

    my @invlist = prop_invlist($prop);
    output_invlist($prop, \@invlist);
}

read_only_bottom_close_and_rename($out_fh)
