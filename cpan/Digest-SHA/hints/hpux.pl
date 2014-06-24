# With +O2 this HP-UX cc compiler creates code which coredumps (Bus error)
# when running t/woodbury.t, but dropping to +O1 seems to dodge that.
# Also gcc seems to have similar issues, so drop the opt also there.
# Modern HP-UX cc:s understand -On, so our task is easier.
#
# This was reported also at:
# https://rt.cpan.org/Ticket/Display.html?id=96498
# but the ticket was rejected since MSHELOR thinks Digest::SHA
# is doing nothing wrong.
if (defined $self->{OPTIMIZE}) {
  # This will turn -O0 to -O1, but we will burn that bridge when we cross it.
  $self->{OPTIMIZE} =~ s/[\+\-]O[0-9]*/-O1/;
  $self->{OPTIMIZE} =~ s/NO_OPT/-O0/;
  $self->{OPTIMIZE} =~ s/ \+Onolimit//;
} else {
  $self->{OPTIMIZE} = '-O1';
}
