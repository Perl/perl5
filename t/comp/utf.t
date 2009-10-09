#!./perl

BEGIN { require "./test.pl"; }

plan(tests => 18);

my %templates = (
		 utf8 => 'C0U',
		 utf16be => 'n',
		 utf16le => 'v',
		);

sub bytes_to_utf {
    my ($enc, $content, $do_bom) = @_;
    my $template = $templates{$enc};
    die "Unsupported encoding $enc" unless $template;
    return pack "$template*", ($do_bom ? 0xFEFF : ()), unpack "C*", $content;
}

sub test {
    my ($enc, $tag, $bom) = @_;
    open my $fh, ">", "utf$$.pl" or die "utf.pl: $!";
    binmode $fh;
    print $fh bytes_to_utf($enc, "$tag\n", $bom);
    close $fh or die $!;
    my $got = do "./utf$$.pl";
    is($got, $tag);
}

for my $bom (0, 1) {
    for my $enc (qw(utf16le utf16be utf8)) {
	for my $value (123, 1234, 12345) {
	    test($enc, $value, $bom);
	}
    }
}

END {
    1 while unlink "utf$$.pl";
}
