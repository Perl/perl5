#!./perl -w

print "1..36\n";
my $test = 0;

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
    my ($enc, $tag, $bom, $nl) = @_;
    open my $fh, ">", "utf$$.pl" or die "utf.pl: $!";
    binmode $fh;
    print $fh bytes_to_utf($enc, $tag . ($nl ? "\n" : ''), $bom);
    close $fh or die $!;
    my $got = do "./utf$$.pl";
    $test = $test + 1;
    if (!defined $got) {
	print "not ok $test # $enc $tag $bom $nl; got undef\n";
    } elsif ($got ne $tag) {
	print "not ok $test # $enc $tag $bom $nl; got '$got'\n";
    } else {
	print "ok $test # $enc $tag $bom $nl\n";
    }
}

for my $bom (0, 1) {
    for my $enc (qw(utf16le utf16be utf8)) {
	for my $value (123, 1234, 12345) {
	    for my $nl (1, 0) {
		test($enc, $value, $bom, $nl);
	    }
	}
    }
}

END {
    1 while unlink "utf$$.pl";
}
