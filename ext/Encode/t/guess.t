BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    $| = 1;
}

use strict;
use File::Basename;
use File::Spec;
use Encode qw(decode encode find_encoding _utf8_off);

#use Test::More qw(no_plan);
use Test::More tests => 11;
use_ok("Encode::Guess");
{
    no warnings;
    $Encode::Guess::DEBUG = shift || 0;
}

my $ascii  = join('' => map {chr($_)}(0x21..0x7e));
my $latin1 = join('' => map {chr($_)}(0xa1..0xfe));
my $utf8on  = join('' => map {chr($_)}(0x3000..0x30fe));
my $utf8off = $utf8on; _utf8_off($utf8off);

is(Encode::Guess->guess($ascii)->name, 'ascii');

eval { Encode::Guess->guess($latin1) } ;
like($@, qr/No appropriate encoding/io);

Encode::Guess->import(qw(latin1));

is(Encode::Guess->guess($latin1)->name, 'iso-8859-1');
is(Encode::Guess->guess($utf8on)->name, 'utf8');

eval { Encode::Guess->guess($utf8off) };
like($@, qr/ambiguous/io);

my $jisx0201 = File::Spec->catfile(dirname(__FILE__), 'jisx0201.utf');
my $jisx0208 = File::Spec->catfile(dirname(__FILE__), 'jisx0208.utf');
my $jisx0212 = File::Spec->catfile(dirname(__FILE__), 'jisx0212.utf');

open my $fh, $jisx0208 or die "$jisx0208: $!";
$utf8off = join('' => <$fh>);
close $fh;
$utf8on = decode('utf8', $utf8off);
my @jp = qw(7bit-jis shiftjis euc-jp);

Encode::Guess->import(@jp);

for my $jp (@jp){
    my $test = encode($jp, $utf8on);
    is(Encode::Guess->guess($test)->name, $jp, $jp);
}
is (decode('Guess', encode('euc-jp', $utf8on)), $utf8on, "decode('Guess')");
eval{ encode('Guess', $utf8on) };
like($@, qr/lazy/io, "no encode()");
__END__;
