# -lucb has been reported to be fatal for perl7 on Solaris.
# Thus we deliberately don't include it here.
$self->{LIBS} = ["-lndbm", "-ldbm"];
