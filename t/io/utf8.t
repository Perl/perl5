#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require './charset_tools.pl';
}
skip_all_without_perlio();

no utf8; # needed for use utf8 not griping about the raw octets
use Fcntl qw(:seek);
use strict;

$| = 1;

my $a_file = tempfile();

open(F,"+>:utf8",$a_file);
print F chr(0x100).'£';
cmp_ok( tell(F), '==', 4, tell(F) );
print F "\n";
cmp_ok( tell(F), '>=', 5, tell(F) );
seek(F,0,0);
is( getc(F), chr(0x100) );
is( getc(F), "£" );
is( getc(F), "\n" );
seek(F,0,0);
binmode(F,":bytes");

# Byte representation of these characters
my $U_100 = byte_utf8a_to_utf8n("\xc4\x80");
my $POUND_SIGN = byte_utf8a_to_utf8n("\xc2\xa3");

my $chr = substr($U_100, 0, 1);
is( getc(F), $chr );
$chr = substr($U_100, 1, 1);
is( getc(F), $chr );
$chr = substr($POUND_SIGN, 0, 1);
is( getc(F), $chr );
$chr = substr($POUND_SIGN, 1, 1);
is( getc(F), $chr );
is( getc(F), "\n" );
seek(F,0,0);
binmode(F,":utf8");
is( scalar(<F>), "\x{100}£\n" );
seek(F,0,0);
my $buf = chr(0x200);
my $count = read(F,$buf,2,1);
cmp_ok( $count, '==', 2 );
is( $buf, "\x{200}\x{100}£" );
close(F);

{
    $a = chr(300); # This *is* UTF-encoded
    $b = chr(130); # This is not.

    open F, ">:utf8", $a_file or die $!;
    print F $a,"\n";
    close F;

    open F, "<:utf8", $a_file or die $!;
    my $x = <F>;
    chomp($x);
    is( $x, chr(300) );

    open F, $a_file or die $!; # Not UTF
    binmode(F, ":bytes");
    $x = <F>;
    chomp($x);
    $chr = byte_utf8a_to_utf8n(chr(196).chr(172));
    is( $x, $chr );
    close F;

    open F, ">:utf8", $a_file or die $!;
    binmode(F);  # we write a "\n" and then tell() - avoid CRLF issues.
    binmode(F,":utf8"); # turn UTF-8-ness back on
    print F $a;
    my $y;
    { my $x = tell(F);
      { use bytes; $y = length($a);}
      cmp_ok( $x, '==', $y );
  }

    { # Check byte length of $b
	use bytes; my $y = length($b);
	cmp_ok( $y, '==', 1 );
    }

    print F $b,"\n"; # Don't upgrade $b

    { # Check byte length of $b
	use bytes; my $y = length($b);
	cmp_ok( $y, '==', 1 );
    }

    {
	my $x = tell(F);
	{ use bytes; if ($::IS_EBCDIC){$y += 2;}else{$y += 3;}} # EBCDIC ASCII
	cmp_ok( $x, '==', $y );
    }

    close F;

    open F, $a_file or die $!; # Not UTF
    binmode(F, ":bytes");
    $x = <F>;
    chomp($x);
    $chr = v196.172.194.130;
    if ($::IS_EBCDIC) { $chr = v141.83.130; } # EBCDIC
    is( $x, $chr, sprintf('(%vd)', $x) );

    open F, "<:utf8", $a_file or die $!;
    $x = <F>;
    chomp($x);
    close F;
    is( $x, chr(300).chr(130), sprintf('(%vd)', $x) );

    open F, ">", $a_file or die $!;
    binmode(F, ":bytes:");

    # Now let's make it suffer.
    my $w;
    {
	use warnings 'utf8';
	local $SIG{__WARN__} = sub { $w = $_[0] };
	print F $a;
        ok( (!$@));
        like($w, qr/Wide character in print/i,
             "check wide character message");
    }
}

# Hm. Time to get more evil.
open F, ">:utf8", $a_file or die $!;
print F $a;
binmode(F, ":bytes");
print F chr(130)."\n";
close F;

open F, "<", $a_file or die $!;
binmode(F, ":bytes");
my $x = <F>; chomp $x;
$chr = v196.172.130;
if ($::IS_EBCDIC) { $chr = v141.83.130; } # EBCDIC
is( $x, $chr );

# Right.
open F, ">:utf8", $a_file or die $!;
print F $a;
close F;
open F, ">>", $a_file or die $!;
binmode(F, ":bytes");
print F chr(130)."\n";
close F;

open F, "<", $a_file or die $!;
binmode(F, ":bytes");
$x = <F>; chomp $x;
is( $x, $chr );

# Now we have a deformed file.

SKIP: {
    if ($::IS_EBCDIC) {
	skip("EBCDIC The file isn't deformed in UTF-EBCDIC", 2);
    } else {
	open F, "<:utf8", $a_file or die $!;
        eval { $x = <F>; chomp $x; };
        like ($@, qr/^Malformed UTF-8 character: \\x82 \(unexpected continuation byte 0x82, with no preceding start byte\)/);
    }
}

close F;
unlink($a_file);

open F, ">:utf8", $a_file;
my @a = map { chr(1 << ($_ << 2)) } 0..5; # 0x1, 0x10, .., 0x100000
unshift @a, chr(0); # ... and a null byte in front just for fun
print F @a;
close F;

my $c;

# read() should work on characters, not bytes
open F, "<:utf8", $a_file;
$a = 0;
my $failed;
for (@a) {
    unless (($c = read(F, $b, 1) == 1)  &&
            length($b)           == 1  &&
            ord($b)              == ord($_) &&
            tell(F)              == ($a += bytes::length($b))) {
        print '# ord($_)           == ', ord($_), "\n";
        print '# ord($b)           == ', ord($b), "\n";
        print '# length($b)        == ', length($b), "\n";
        print '# bytes::length($b) == ', bytes::length($b), "\n";
        print '# tell(F)           == ', tell(F), "\n";
        print '# $a                == ', $a, "\n";
        print '# $c                == ', $c, "\n";
	$failed++;
        last;
    }
}
close F;
is($failed, undef);

{
    # Check that warnings are on on I/O, and that they can be muffled.

    local $SIG{__WARN__} = sub { $@ = shift };

    undef $@;
    open F, ">$a_file";
    binmode(F, ":bytes");
    print F chr(0x100);
    close(F);

    like( $@, qr/Wide character in print/ );

    undef $@;
    open F, ">:utf8", $a_file;
    print F chr(0x100);
    close(F);

    isnt( defined $@, !0 );

    undef $@;
    open F, ">$a_file";
    binmode(F, ":utf8");
    print F chr(0x100);
    close(F);

    isnt( defined $@, !0 );

    no warnings 'utf8';

    undef $@;
    open F, ">$a_file";
    print F chr(0x100);
    close(F);

    isnt( defined $@, !0 );

    use warnings 'utf8';

    undef $@;
    open F, ">$a_file";
    binmode(F, ":bytes");
    print F chr(0x100);
    close(F);

    like( $@, qr/Wide character in print/ );
}

{
    open F, ">:bytes",$a_file; print F "\xde"; close F;

    open F, "<:bytes", $a_file;
    my $b = chr 0x100;
    $b .= <F>;
    is( $b, chr(0x100).chr(0xde), "21395 '.= <>' utf8 vs. bytes" );
    close F;
}

{
    open F, ">:utf8",$a_file; print F chr 0x100; close F;

    open F, "<:utf8", $a_file;
    my $b = "\xde";
    $b .= <F>;
    is( $b, chr(0xde).chr(0x100), "21395 '.= <>' bytes vs. utf8" );
    close F;
}

{
    my @a = ( [ 0x007F, "bytes" ],
	      [ 0x0080, "bytes" ],
	      [ 0x0080, "utf8"  ],
	      [ 0x0100, "utf8"  ] );
    my $t = 34;
    for my $u (@a) {
	for my $v (@a) {
	    # print "# @$u - @$v\n";
	    open F, ">$a_file";
	    binmode(F, ":" . $u->[1]);
	    print F chr($u->[0]);
	    close F;

	    open F, "<$a_file";
	    binmode(F, ":" . $u->[1]);

	    my $s = chr($v->[0]);
	    utf8::upgrade($s) if $v->[1] eq "utf8";

	    $s .= <F>;
	    is( $s, chr($v->[0]) . chr($u->[0]), 'rcatline utf8' );
	    close F;
	    $t++;
	}
    }
    # last test here 49
}

{
    # [perl #23428] Somethings rotten in unicode semantics
    open F, ">$a_file";
    binmode F;
    $a = "A";
    utf8::upgrade($a);
    syswrite(F, $a);
    close F;
    ok(utf8::is_utf8($a), '23428 syswrite should not downgrade scalar' );
}

{
    # <FH> on a :utf8 stream should complain immediately with -w
    # if it finds bad UTF-8 (:encoding(utf8) works this way)
    use warnings 'utf8';
    undef $@;
    open F, ">$a_file";
    binmode F;
    my ($chrE4, $chrF6) = (chr(0xE4), chr(0xF6));
    if ($::IS_EBCDIC)	# EBCDIC
    { ($chrE4, $chrF6) = (chr(0x43), chr(0xEC)); }
    print F "foo", $chrE4, "\n";
    print F "foo", $chrF6, "\n";
    close F;
    open F, "<:utf8", $a_file;
    undef $@;
    eval {
        my $line = <F>;
    };
    my ($chrE4, $chrF6) = ("e4", "f6");
    if ($::IS_EBCDIC) { ($chrE4, $chrF6) = ("43", "ec"); } # EBCDIC
    my $chr0A = sprintf("%02x", ord("\n"));
    my $chr66 = sprintf("%02x", ord("f"));
    like( $@, qr/^Malformed UTF-8 character: \\x$chrE4\\x$chr0A\\x$chr66 \(unexpected non-continuation byte 0x$chr0A, immediately after start byte 0x$chrE4; need 3 bytes, got 1\)/,
      "<:utf8 readline must warn about bad utf8");
    undef $@;
    ok(*F->error, "stream should be in error");
}

{
    # fixed record reads
    open F, ">:utf8", $a_file;
    print F "foo\xE4";
    print F "bar\xFE";
    print F "\xC0\xC8\xCC\xD2";
    print F "a\xE4ab";
    print F "a\xE4a";
    close F;
    open F, "<:utf8", $a_file;
    local $/ = \4;
    my $line = <F>;
    is($line, "foo\xE4", "readline with \$/ = \\4");
    $line .= <F>;
    is($line, "foo\xE4bar\xFE", "rcatline with \$/ = \\4");
    $line = <F>;
    is($line, "\xC0\xC8\xCC\xD2", "readline with several encoded characters");
    $line = <F>;
    is($line, "a\xE4ab", "readline with another boundary condition");
    $line = <F>;
    is($line, "a\xE4a", "readline with boundary condition");
    close F;

    # badly encoded at EOF
    open F, ">:raw", $a_file;
    print F "foo\xEF\xAC"; # truncated \x{FB04} small ligature ffl
    close F;

    use warnings 'utf8';
    open F, "<:utf8", $a_file;
    undef $@;
    local $SIG{__WARN__} = sub { $@ = shift };
    $line = eval { <F> };

    like( $@, qr/Malformed UTF-8 character: \\xef\\xac \(too short; 2 bytes available, need 3\) at end of file/, "check error message");
    close F;
}

# getc should reset the utf8 flag and not be affected by previous
# return values
SKIP: {
    skip "no PerlIO::scalar on miniperl", 2, if is_miniperl();
    open my $fh, "<:raw",  \($buf = chr 255);
    my $uuf;
    open my $uh, "<:utf8", \($uuf = $U_100);
    for([$uh,chr 256], [$fh,chr 255]) {
	is getc $$_[0], $$_[1],
	  'getc returning non-utf8 after utf8';
    }
}

{
    # needs to encode to at least 3 bytes
    my $extra = "\x{7FFFFFFF}";
    my $data = "a" x 8190 . $extra;
    utf8::encode($data);
    open my $fh, ">", $a_file
      or die;
    binmode $fh;
    print $fh $data;
    close $fh or die;
    open $fh, "<:utf8(loose)", $a_file
      or die;
    my $buf;
    read($fh, $buf, 8190);
    is(tell($fh), 8190, "check tell is properly adjusted");
    ok(seek($fh, 8190, SEEK_SET), "do a seek");
    is(read($fh, $buf, 1), 1, "read that extra character");
    is($buf, $extra, "check we read it back");
}

my @srctypes =
  (
   "file", "fileraw", "scalar",
  );

{
    # test each allow-* option
    my @tests =
      (
          # name, input (as characters), expected message, replaced result
          [ "surrogates", "A\x{D800}\x{D801}\x{DFFE}\x{DFFF}B",
            qr/UTF-16 surrogate/, "A\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}" ],
          [ "noncharacters", "A\x{FDD0}\x{FDEF}\x{FFFE}\x{FFFF}B",
            qr/Unicode non-character/, "A\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}" ],
          [ "super", "A\x{110000}\x{7FFFFFFF}B",
            qr/Code point 0x[0-9a-fA-F]+ is not Unicode/,
            "A\x{FFFD}\x{FFFD}" ],
         );
    for my $test (@tests) {
        for my $src (@srctypes) {
            my ($key, $str, $message, $replaced) = @$test;
            utf8::encode(my $bytes = $str);

            $bytes .= "a" x 8192;

            # make sure it fails with the default strict
            my $fh = open_source($src, ":utf8", $bytes);
            my $out;
            ok(!eval { read($fh, $out, length $str); 1 },
               "can't read from data with $key");
            my $error = $@;
            close $fh;
            like($error, $message, "$src: check message matches for $key");
            $fh = open_source($src, ":utf8(allow_$key)", $bytes);
            undef $out;
            ok(eval { read($fh, $out, length $str) },
               "$src: read from data with $key with allow_$key");
            is($out, $str, "$src: make sure source matches result for $key");
            close $fh;

            # check with failwarn
            {
                use warnings;
                $fh = open_source($src, ":utf8(error=failwarn)", $bytes);
                my @warn;
                local $SIG{__WARN__} = sub { push @warn, "@_" };
                undef $out;
                ok(eval { read($fh, $out, length $str); 1 },
                   "$src: shouldn't croak with error=failwarn for $key");
                ok($fh->error, "$src: and stream is in error for $key");
                like("@warn", $message, "$src: check warning sane for $key");
            }

            # check with failquiet
            {
                use warnings;
                $fh = open_source($src, ":utf8(error=failquiet)", $bytes);
                my @warn;
                local $SIG{__WARN__} = sub { push @warn, "@_" };
                undef $out;
                ok(eval { read($fh, $out, length $str); 1 },
                   "$src: shouldn't croak with error=failquiet for $key");
                ok($fh->error, "$src: and stream is in error for $key");
                is(@warn, 0, "$src: check no warning for $key");
            }

            # check with replacewarn
            {
                use warnings;
                $fh = open_source($src, ":utf8(error=replacewarn)", $bytes);
                my @warn;
                local $SIG{__WARN__} = sub { push @warn, "@_" };
                undef $out;
                ok(eval { read($fh, $out, length $replaced); 1 },
                   "$src: shouldn't croak with error=replacewarn for $key");
                like("@warn", $message, "$src: check replacewarn warning sane for $key");
                is($out, $replaced, "$src:check result for $key");
            }
        }
    }
}

SKIP:
{
    # test invalid encodings
    skip "The encodings tests are ASCII-type UTF-8 specific", 1
      unless ord("A") == 65;
    my @tests =
      (
          # name/allow, input (as bytes), message, replaced result, fail result
          [ "nonshortest", "A\xC0\x80B",
            qr/Malformed UTF-8 character:.*\(overlong/,
            "A\x{FFFD}B", "A" ],
          [ "continuation", "A\x80B",
            qr/Malformed UTF-8 character:.*\(unexpected continuation/,
            "A\x{FFFD}B", "A" ],
          [ "noncontinuation", "A\xCF\xCFB",
            qr/Malformed UTF-8 character:.*\(unexpected non-continuation/,
            "A\x{FFFD}\x{FFFD}B", "A" ],
          [ "short", "A\xF0\x9F\x80",
            qr/Malformed UTF-8 character:.*\(too short; 3 bytes available, need 4\)/,
            "A\x{FFFD}", "A" ],
         );

    for my $test (@tests) {
        my ($key, $in, $message, $replaced, $failed) = @$test;

        my $prefix = "a" x 8192;
        $in = $prefix . $in;
        $replaced = $prefix . $replaced;
        $failed = $prefix . $failed;

        # make sure it fails with the default strict
        my $bytes = $in;
        open my $fh, "<:utf8", \$bytes
          or die;
        my $out;
        ok(!eval { read($fh, $out, length $replaced); 1 },
           "can't read from data with $key");
        my $error = $@;
        close $fh;
        like($error, $message, "check message matches for $key");
        open my $fh, "<:utf8(allow_$key)", \$bytes
          or die;
        undef $out;
        ok(eval { read($fh, $out, length $replaced) },
           "read from data with $key with allow_$key")
          or diag $@;
        is($out, $replaced, "make sure source matches result for $key");
        close $fh;

        # check with croak
        {
            use warnings;
            open $fh, "<:utf8(error=croak)", \$bytes
              or die;
            my @warn;
            local $SIG{__WARN__} = sub { push @warn, "@_" };
            undef $out;
            ok(!eval { read($fh, $out, length $failed); 1 },
               "$key: should croak with error=croak");
            ok($fh->error, "$key: and stream is in error");
            like($@, $message, "$key: check error sane");
        }

        # check with failwarn
        {
            use warnings;
            open $fh, "<:utf8(error=failwarn)", \$bytes
              or die;
            my @warn;
            local $SIG{__WARN__} = sub { push @warn, "@_" };
            undef $out;
            ok(eval { read($fh, $out, length $failed); 1 },
               "$key: shouldn't croak with error=failwarn");
            is($out, $failed, "$key: check expected for failwarn");
            ok($fh->error, "$key: and stream is in error");
            like("@warn", $message, "$key: check warning sane");
        }

        # check with failquiet
        {
            use warnings;
            open $fh, "<:utf8(error=failquiet)", \$bytes
              or die;
            my @warn;
            local $SIG{__WARN__} = sub { push @warn, "@_" };
            undef $out;
            ok(eval { read($fh, $out, length $failed); 1 },
               "$key: shouldn't croak with error=failquiet");
            ok($fh->error, "$key: and stream is in error");
            is(@warn, 0, "$key: check no warning");
        }

        # check with replacewarn
        {
            use warnings;
            open $fh, "<:utf8(error=replacewarn)", \$bytes
              or die;
            my @warn;
            local $SIG{__WARN__} = sub { push @warn, "@_" };
            undef $out;
            ok(eval { read($fh, $out, length $replaced); 1 },
               "$key: shouldn't croak with error=replacewarn");
            like("@warn", $message, "$key: check replacewarn warning sane");
            is($out, $replaced, "$key: check result");
        }

        # check with replacequiet
        {
            use warnings;
            open $fh, "<:utf8(error=replacequiet)", \$bytes
              or die;
            my @warn;
            local $SIG{__WARN__} = sub { push @warn, "@_" };
            undef $out;
            ok(eval { read($fh, $out, length $replaced); 1 },
               "$key: shouldn't croak with error=replacequiet");
            is(0+@warn, 0, "$key: check replacequiet doesn't warn");
            is($out, $replaced, "$key: check result");
        }
    }
}

{
    utf8::encode(my $sur = "\x{D800}");
    my $bytes = "A\xC0\x80B${sur}C";
    open my $fh, "<:utf8(error=replacequiet,allow_nonshortest)", \$bytes
      or die;
    my $data;
    ok(read($fh, $data, 1000), "read content with mixed errors (and error handling)");
    close $fh;
    is($data, "A\x{fffd}B\x{fffd}C", "overlongs allowed but not surrogates");
}

{
    # at one point the condition on whether to preserve messages was incorrect
    my $cont = chr(0xA0);
    open my $fh, "<:utf8(strict,allow_nonshortest,error=croak)", \$cont
      or die;
    my $data;
    ok(!eval { read($fh, $data, 1) },
       "ensure we error on one case when others are permitted");
}

SKIP:
{
    # at one point the warning flags were set even for errors that don't
    # involve warning flags (and have inverted error flags anyway)
    my $cont = "\xC2\xC2A";
    open my $fh, "<:utf8(strict,allow_continuation,error=croak)", \$cont
      or die;
    my $data;
    ok(!eval { read($fh, $data, 1); 1 },
       "enabling continuations with messages shouldn't allow start bytes");
    close $fh;
}

done_testing();

sub open_source {
    my ($source, $mode, $content) = @_;

    if ($source eq "file" || $source eq "fileraw") {
        open my $f, ">", $a_file
          or die "Cannot create $a_file: $!";
        binmode $f;
        print $f $content;
        close $f or die "Cannot close $a_file: $!";
        open $f, "<", $a_file
          or die "Cannot open $a_file: $!";
        binmode $f; # disable crlf on win32
        if ($source eq "fileraw") {
            # pop perlio
            binmode $f, ":pop$mode"
              or die "Can't binmode :pop:$mode filehandle: $!";
        }
        else {
            binmode $f, $mode
              or die "Can't binmode $mode filehandle: $!";
        }
        return $f;
    }
    elsif ($source eq "scalar") {
        open my $f, "<$mode", \$content
          or die "Cannot open scalar with mode $mode: $!";

        return $f;
    }
    else {
        die "Unknown source type $source";
    }
}
