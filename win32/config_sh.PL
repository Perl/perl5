my %opt;
while (@ARGV && $ARGV[0] =~ /^([\w_]+)=(.*)$/)
 {
  $opt{$1}=$2;
  shift(@ARGV);
 }
while (<>)
 {
  s/~([\w_]+)~/$opt{$1}/g;
  $_ = "$1='$opt{$1}'\n" if (/^([\w_]+)=/ && exists($opt{$1}));
  print;
 }

