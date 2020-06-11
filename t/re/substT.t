#!perl -wT

for my $file ('re/subst.t', 't/re/subst.t', ':re:subst.t') {
  if (-r $file) {
    do "./$file";
    exit;
  }
}
die "Cannot find re/subst.t or t/re/subst.t\n";
