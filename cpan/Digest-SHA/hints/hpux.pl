# With +O2 this HP-UX cc compiler creates code which coredumps (Bus error)
# when running t/woodbury.t, but dropping to +O1 seems to dodge that.
#
# This might turn out to be temporary, see:
# https://rt.cpan.org/Ticket/Display.html?id=96498
if ($Config{cc} eq 'cc' &&
    $Config{archname} eq 'PA-RISC2.0' &&
    $Config{ccversion} =~ /^B\.11\.11\./) {
  if (defined $self->{OPTIMIZE}) {
    $self->{OPTIMIZE} =~ s/\+O[2-9]/+O1/;
    $self->{OPTIMIZE} =~ s/ \+Onolimit//;
  } else {
    $self->{OPTIMIZE} = '+O1';
  }
}
