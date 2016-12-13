#!./perl

BEGIN {
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # No perlio\n";
	exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    unless ( eval { require Encode } ) {
	print "1..0 # Skip: No Encode\n";
	exit 0;
    }
    import Encode qw(:fallback_all);
}

use Test::More tests => 17;

# $PerlIO::encoding = 0; # WARN_ON_ERR|PERLQQ;

my $file = "fallback$$.txt";

{
    my $message = '';
    local $SIG{__WARN__} = sub { $message = $_[0] };
    $PerlIO::encoding::fallback = Encode::PERLQQ;
    ok(open(my $fh,">encoding(iso-8859-1)",$file),"opened iso-8859-1 file");
    my $str = "\x{20AC}";
    print $fh $str,"0.02\n";
    close($fh);
    like($message, qr/does not map to iso-8859-1/o, "FB_WARN message");
}

open($fh,$file) || die "File cannot be re-opened";
my $line = <$fh>;
is($line,"\\x{20ac}0.02\n","perlqq escapes");
close($fh);

$PerlIO::encoding::fallback = Encode::HTMLCREF;

ok(open(my $fh,">encoding(iso-8859-1)",$file),"opened iso-8859-1 file");
my $str = "\x{20AC}";
print $fh $str,"0.02\n";
close($fh);

open($fh,$file) || die "File cannot be re-opened";
my $line = <$fh>;
is($line,"&#8364;0.02\n","HTML escapes");
close($fh);

{
    no utf8;
    open($fh,">$file") || die "File cannot be re-opened";
    binmode($fh);
    print $fh "\xA30.02\n";
    close($fh);
}

ok(open($fh,"<encoding(US-ASCII)",$file),"Opened as ASCII");
my $line = <$fh>;
printf "# %x\n",ord($line);
is($line,"\\xA30.02\n","Escaped non-mapped char");
close($fh);

{
    my $message = '';
    local $SIG{__WARN__} = sub { $message = $_[0] };

    $PerlIO::encoding::fallback = Encode::WARN_ON_ERR;

    ok(open($fh,"<encoding(US-ASCII)",$file),"Opened as ASCII");
    my $line = <$fh>;
    printf "# %x\n",ord($line);
    is($line,"\x{FFFD}0.02\n","Unicode replacement char");
    close($fh);

    like($message, qr/does not map to Unicode/o, "FB_WARN message");
}

{
    # Make sure partials are handled correctly when reading, particularly at eof
    #
    # Use a moderately large file to ensure the first read doesn't hit eof,
    # so we see both partials on buffering boundaries and at eof
    #
    # "\x{1e19}" encodes to 3 octets, so assuming some power-of-two buffer size
    # we should get partials across buffering boundaries
    my $data = "\x{1e19}" x 1_000_000;
    utf8::encode($data);
    substr($data, -1) = ""; # make the last character a partial
    ok(open($fh, ">:raw", $file), "create test file as raw");
    ok((print $fh $data), "write pre-encoded data (with partial)");
    ok(close($fh), "closed successfully");
    for my $test ([ Encode::PERLQQ, "PERLQQ" ], [ Encode::HTMLCREF, "HTMLCREF" ]) {
        my ($fb, $fbname) = @$test;
        local $PerlIO::encoding::fallback = $fb;
        my $expected = Encode::decode("UTF-8", $data, $fb);
        ok(open($fh, "<:encoding(UTF-8)", $file), "open file with fallback $fbname");
        # avoid reading the whole file at once to ensure we get both non-eof and
        # eof decodes
        my $indata = "";
        my $buf;
        while (read($fh, $buf, 2048)) {
            $indata .= $buf;
        }
        close $fh;
        if (length $indata > 999_980 && length $expected > 999_980) {
            # make mismatch reporting a little easier
            substr($indata, 0, 999_980) = "";
            substr($expected, 0, 999_980) = "";
        }
        is($indata, $expected, "check data matches between Encode::decode and :encoding for fb $fbname");
    }
}

END {
    1 while unlink($file);
}
