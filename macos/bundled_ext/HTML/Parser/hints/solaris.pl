if ($Config{gccversion}) {
  print "Turning off optimizations to avoid compiler bug\n";
  $self->{OPTIMIZE} = " ";
}
