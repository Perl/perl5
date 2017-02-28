#!./perl
# Test permissive read of LF-delimited files on Win32 with encoding
# layers (see #120797).
# This file should contain only ASCII and be stored LF-delimited to
# exhibit the potential problems.
my @encodings;

BEGIN {
    require strict; import strict;
    @encodings = (":crlf:encoding(UTF-8)", ":crlf:encoding(iso-8859-1)");
}

use Test;

BEGIN { plan tests => 2*@encodings }

use IO::File;

my $File = __FILE__;
my @lines = do {
    open(my $f, "<", $File) or die $!;
    <$f>;
};

sub test {
    my ($encoding, $tell, $actualref) = @_;
    study;
    my $io = IO::File->new($File, "<$encoding") or die $!;
    $$actualref = join ":", q{}, PerlIO::get_layers($io);
    my $cnt = 0;
    while (defined (my $line = $io->getline)) {
        $line eq $lines[$cnt]
            or return "line $cnt, expected '$lines[$cnt]', got '$line'";
        if ($tell) {
            () = tell $io;
        }
        ++$cnt;
    }
    return "OK";
}

for my $tell (1, 0) {
    for my $encoding (@encodings) {
        my $actual;
        ok(test($encoding, $tell, \$actual), "OK", "encoding = $encoding, actual = $actual, tell = $tell");
    }
}
#a0a1a2a3a4a5a6a7a8a9
#b0b1b2b3b4b5b6b7b8b9
