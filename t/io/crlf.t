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

if (find PerlIO::Layer 'perlio') {
 plan(tests => 8);
 ok(open(FOO,">:crlf",$file));
 ok(print FOO 'a'.((('a' x 14).qq{\n}) x 2000) || close(FOO));
 ok(open(FOO,"<:crlf",$file));

 my $text;
 { local $/; $text = <FOO> }
 is(count_chars($text, "\015\012"), 0);
 is(count_chars($text, "\n"), 2000);

 binmode(FOO);
 seek(FOO,0,0);
 { local $/; $text = <FOO> }
 is(count_chars($text, "\015\012"), 2000);

 SKIP:
 {
  eval 'use PerlIO::scalar';
  skip(q/miniperl cannnot load PerlIO::scalar/)
      if $@ =~ /dynamic loading not available/;
  my $fcontents = join "", map {"$_\015\012"} "a".."zzz";
  open my $fh, "<:crlf", \$fcontents;
  local $/ = "xxx";
  local $_ = <$fh>;
  my $pos = tell $fh; # pos must be behind "xxx", before "\nyyy\n"
  seek $fh, $pos, 0;
  $/ = "\n";
  $s = <$fh>.<$fh>;
  ok($s eq "\nxxy\n");
 }

 ok(close(FOO));
}
else {
 skip_all("No perlio, so no :crlf");
}

sub count_chars {
  my($text, $chars) = @_;
  my $seen = 0;
  $seen++ while $text =~ /$chars/g;
  return $seen;
}
