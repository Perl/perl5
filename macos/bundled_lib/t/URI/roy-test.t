print "1..102\n";

if (-d "t") {
   chdir("t") || die "Can't chdir 't': $!";
   # fix all relative library locations
   foreach (@INC) {
      $_ = "../$_" unless m,^/,;
   }
}

use URI;
$no = 1;

for $i (1..5) {
   my $file = "roytest$i.html";

   open(FILE, $file) || die "Can't open $file: $!";
   print "# $file\n";
   $base = undef;
   while (<FILE>) {
       if (/^<BASE href="([^"]+)">/) {
           $base = URI->new($1);
       } elsif (/^<a href="([^"]*)">.*<\/a>\s*=\s*(\S+)/) {
           die "Missing base at line $." unless $base;	    
           $link = $1;
           $exp  = $2;
           $exp = $base if $exp =~ /current/;  # special case test 22
           $abs  = URI->new($link)->abs($base);
           unless ($abs eq $exp) {
              print "$file:$.:  Expected: $exp\n";
              print qq(  abs("$link","$base") ==> "$abs"\n);
              print "not ";
           }
           print "ok $no\n";
           $no++;
       }
   }
}
