#!./perl
BEGIN {
   chdir 't' if -d 't';
   unshift @INC, './pod', '../lib';
   require "testp2pt.pl";
   import TestPodIncPlainText;
}

my %options = map { $_ => 1 } @ARGV;  ## convert cmdline to options-hash
my $passed  = testpodplaintext \%options, $0;
exit( ($passed == 1) ? 0 : -1 )  unless $ENV{HARNESS_ACTIVE};


__END__


=pod

This is a test to see if I can do not only C<$self> and C<method()>, but
also C<$self->method()> and C<$self->{FIELDNAME}> and C<{FOO=>BAR}> without
resorting to escape sequences.

Now for the grand finale of C<$self->method()->{FIELDNAME} = {FOO=>BAR}>.

Of course I should still be able to do all this I<with> escape sequences
too: C<$self-E<gt>method()> and C<$self-E<gt>{FIELDNAME}> and C<{FOO=E<gt>BAR}>.

Dont forget C<$self-E<gt>method()-E<gt>{FIELDNAME} = {FOO=E<gt>BAR}>.

And make sure that C<0> works too!

=cut
