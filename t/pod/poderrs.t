BEGIN {
   use File::Basename;
   my $THISDIR = dirname $0;
   unshift @INC, $THISDIR;
   require "testpchk.pl";
   import TestPodChecker;
}

my %options = map { $_ => 1 } @ARGV;  ## convert cmdline to options-hash
my $passed  = testpodchecker \%options, $0;
exit( ($passed == 1) ? 0 : -1 )  unless $ENV{HARNESS_ACTIVE};


__END__


=head1 NAME

poderrors.t - test Pod::Checker on some pod syntax errors

=unknown1 this is an unknown command with two N<unknownA>
and D<unknownB> interior sequences.

This is some paragraph text with some unknown interior sequences,
such as Q<unknown2>,
A<unknown3>,
and Y<unknown4 V<unknown5>>.

Now try some unterminated sequences like
I<hello mudda!
B<hello fadda!

Here I am at C<camp granada!

Camps is very,
entertaining.
And they say we'll have some fun if it stops raining!

=cut
