#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
}

use Config;

require "test.pl";

my $file = "crlf$$.dat";
END {
 unlink($file);
}

if ($Config{useperlio}) {
 plan(tests => 6);
 ok(open(FOO,">:crlf",$file));
 ok(print FOO 'a'.((('a' x 14).qq{\n}) x 2000) || close(FOO));
 ok(open(FOO,"<:crlf",$file));
 my $seen = 0;
 while (<FOO>)
  {
   $seen++ if (/\r/);
  }
 is($seen,0);
 binmode(FOO);
 seek(FOO,0,0);
 $seen = 0;
 while (<FOO>)
  {
   $seen++ if (/\r/);
  }
 is($seen,2000);
 ok(close(FOO));
}
else {
 skip_all("No perlio, so no :crlf");
}


