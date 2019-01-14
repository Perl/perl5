#!perl
use strict;
use Test::More;
use XS::APItest;
use Devel::Peek;

require "./t/utf8_setup.pl";

++$|;

sub _c {
    my ($s, $c) = @_;
    utf8::encode($s);
    substr($s, $c) = "" if $c;
    $s
}

$::UTF8_QUIET_ON_ERROR = 0x0;
$::UTF8_FAIL_ON_ERROR = 0x40000000;
$::UTF8_WARN_ON_ERROR = 0x80000000;
$::UTF8_CROAK_ON_ERROR = 0xC0000000;
$::UTF8_ONERROR_MASK = 0xC0000000;

sub _warn_flags {
    my $flags = shift;
    $flags |= $::UTF8_WARN_ON_ERROR;
    $flags |= ($flags & ($::UTF8_DISALLOW_SUPER | $::UTF8_DISALLOW_SURROGATE | $::UTF8_DISALLOW_NON_CHAR | $::UTF8_DISALLOW_PERL_EXTENDED)) << 1;
    $flags;
}

sub _croak_flags {
    my $flags = shift;
    $flags |= $::UTF8_CROAK_ON_ERROR;
    $flags |= ($flags & ($::UTF8_DISALLOW_SUPER | $::UTF8_DISALLOW_SURROGATE | $::UTF8_DISALLOW_NON_CHAR | $::UTF8_DISALLOW_PERL_EXTENDED)) << 1;
    $flags;
}

sub _fail_flags {
    my ($flags) = shift;
    $flags | $::UTF8_FAIL_ON_ERROR;
}

{
    my @tests =
      (
       # name - name of the test (required)
       # in - input text (required)
       # outsize - output buffer size (required)
       # flags - conversion/validation flags
       # result - expected string
       # consumed - consumed bytes
       # eof - true if no more data is expected
       # ascii - true for an ASCII (vs EBCIDIC) only test
       # message - warning/croak message when run with CROAK or WARN flags
       # failout - result with fail flags
       # failconsumed - consumed with fail flags
       # failerror - failure error flags
       {
        name => "simple ascii",
        in => "AAAAA",
        outsize => 4,
        flags => 0,
        result => "AAAA",
        consumed => 4,
       },
       {
        name => "simple ascii, input shorter than output",
        in => "A",
        outsize => 4,
        flags => 0,
        result => "A",
        consumed => 1,
       },
       {
        in => _c("A\x{100}", 2),
        outsize => 2,
        flags => 0,
        result => "A",
        consumed => 1,
        name => "short encoding, short out buffer",
       },
       {
        in => _c("A\x{100}", 2),
        outsize => 10,
        flags => 0,
        result => "A\x{FFFD}",
        consumed => 2,
        name => "short encoding",
        message => qr/too short/,
        eof => 1,
        failout => "A",
        failconsumed => 1,
        failerror => $::UTF8_GOT_SHORT,
       },
       {
        in => _c("A\x{100}", 2),
        outsize => 10,
        flags => $::UTF8_ALLOW_SHORT,
        result => "A",
        consumed => 1,
        name => "short encoding, short allowed",
       },
       {
        in => _c("A\x{100}", 2),
        outsize => 10,
        flags => 0,
        eof => 1,
        result => "A\x{FFFD}",
        consumed => length(_c("A\x{100}", 2)),
        name => "short encoding, short allowed",
        message => qr/too short/,
        failout => "A",
        failconsumed => 1,
        failerror => $::UTF8_GOT_SHORT
       },
       {
        in => "\xBFA\xBF",
        outsize => 10,
        flags => 0,
        result => "\x{FFFD}A\x{FFFD}",
        consumed => 3,
        name => "continuation",
        ascii => 1,
        message => qr/unexpected continuation byte/,
        failout => "",
        failconsumed => 0,
        failerror => $::UTF8_GOT_CONTINUATION,
       },
       {
        in => _c("A\x{D800}B"),
        outsize => 10,
        flags => 0,
        result => "A\x{D800}B",
        consumed => length(_c("A\x{D800}B")),
        name => "permitted surrogate",
       },
       {
        in => _c("A\x{D800}B"),
        outsize => 10,
        flags => $::UTF8_DISALLOW_SURROGATE | $::UTF8_WARN_SURROGATE,
        result => "A\x{FFFD}B",
        consumed => length(_c("A\x{D800}B")),
        name => "disallowed surrogate (low)",
        message => qr/UTF-16 surrogate/,
        failout => "A",
        failconsumed => 1,
        failerror => $::UTF8_GOT_SURROGATE,
       },
       {
        in =>_c("A\x{DFFF}B"),
        outsize => 10,
        flags => 0,
        result => "A\x{DFFF}B",
        consumed => length(_c("A\x{DFFF}B")),
        name => "permitted surrogate (high)",
       },
       {
        in =>_c("A\x{DFFF}B"),
        outsize => 10,
        flags => $::UTF8_DISALLOW_SURROGATE,
        result => "A\x{FFFD}B",
        consumed => length(_c("A\x{DFFF}B")),
        name => "disallowed surrogate (high)",
        message => qr/surrogate/,
        failout => "A",
        failconsumed => 1,
        failerror => $::UTF8_GOT_SURROGATE,
       },
       {
        in => "\xF0\x82\x82\xAC",
        outsize => 10,
        flags => 0,
        result => "\x{FFFD}",
        consumed => 4,
        name => "overlong",
        ascii => 1,
        message => qr/overlong/,
        failout => "",
        failconsumed => 0,
        failerror => $::UTF8_GOT_LONG,
       },
       {
        in => _c("A\x{110000}B"),
        outsize => 20,
        flags => 0,
        result => "A\x{110000}B",
        consumed => length _c("A\x{110000}B"),
        name => "allowed out of range",
       },
       {
        in => _c("A\x{110000}B"),
        outsize => 20,
        flags => $::UTF8_DISALLOW_SUPER,
        result => "A\x{FFFD}B",
        consumed => length _c("A\x{110000}B"),
        name => "disallowed out of range",
        message => qr/is not Unicode/,
        failout => "A",
        failconsumed => 1,
        failerror => $::UTF8_GOT_SUPER,
       },
      );
  SKIP:
    for my $test (@tests) {
        my @warn;
        use Data::Dumper;
        note Dumper($test);
        my $name = $test->{name};
        my $flags = $test->{flags};
        my $eout = $test->{result};
        utf8::encode($eout);
        skip("$name: ascii only", 3)
          if $test->{ascii} && ord("A") != 65;
        my ($out, $con, $errors, $msgs);
        {
            local $SIG{__WARN__} = sub { push @warn, "@_"; local $| = 1; print @_; };
            ($out, $con, $errors, $msgs) = test_utf8_validate_and_fix($test->{in}, $flags, $test->{outsize}, $test->{eof} || 0);
        }

        is($out, $eout, "$name: output")
          or _clean(got => $out, expected => $eout);
        is($con, $test->{consumed}, "$name: consumed");
        ok(!$msgs || !@$msgs, "should be no messages");
        is(@warn, 0, "$name: no warnings")
          or do { diag $_ for @warn };
        @warn = ();
        {
            local $SIG{__WARN__} = sub { push @warn, "@_"; };
            ($out, $con, $errors, $msgs) = test_utf8_validate_and_fix($test->{in}, _warn_flags($flags) , $test->{outsize}, $test->{eof} || 0);
        }
        is($out, $eout, "$name: output (with warn flags)");
        is($con, $test->{consumed}, "$name: consumed (with warn flags)");
        is(@warn, 0, "$name: should not warn");
        if ($test->{message}) {
            if (ref $msgs) {
                my $text = join "\n", map $_->{text}, @$msgs;
                #use Data::Dumper;
                #note Dumper($msgs);
                like($text, $test->{message}, "$name: messages matched");
            }
            else {
                fail("$name: messages matched (but none produced)");
            }
        }
        else {
            ok(!$msgs || !@$msgs, "$name: no messages with warn flags");
        }

        if (exists $test->{failout}) {
            my $out = "";
            my $fconsumed = 0;
            my $ferror = 0;
            my $in = $test->{in};
            my $loops = 0;
            while (my ($tout, $consumed, $error, $msgs) = test_utf8_validate_and_fix(substr($in,  $fconsumed), _fail_flags($flags), $test->{outsize} - length($out), $test->{eof})) {
                $out .= $tout;
                $fconsumed += $consumed;
                $ferror |= $error;
                last if $ferror;
                ++$loops > 5
                  and die "$name: had to abort loop";
            }
            utf8::encode($out);
            is($out, $test->{failout}, "$name: fail output");
            is($fconsumed, $test->{failconsumed}, "$name: fail consumed");
            is($ferror, $test->{failerror}, "$name: fail error");
        }
        else {
            # otherwise it doesn't fail
            diag "$name: checking it doesn't fail";
            my $out = "";
            my $fconsumed = 0;
            my $in = $test->{in};
            my $loops = 0;
            my ($tout, $consumed, $error);
            while ($fconsumed < length($in)
                   && $test->{outsize} > length($tout)
                   && (($tout, $consumed, $error) = test_utf8_validate_and_fix(substr($in,  $fconsumed), _fail_flags($flags), $test->{outsize} - length($tout), $test->{eof}))
                   && length($tout) > 0
                   && !$error) {
                diag "$name: tout '$tout' con $consumed outsize ".($test->{outsize} - length($tout));
                $out .= $tout;
                $fconsumed += $consumed;
            }
            utf8::decode($out);
            is($out, $test->{result}, "$name: output (fail flags)");
            is($fconsumed, $test->{consumed}, "$name: consumed (fail flags)");
            #die;
        }
    }
}

done_testing();

sub _clean {
    while (@_) {
        my ($name, $val) = splice @_, 0, 2;
        # not technically correct, but I'm mostly worried about non-visible
        # and (extended) Unicode that may not print properly
        $val =~ s/([^[:print:]])/sprintf(ord $1 > 255 ? "\\x{%x}" : "\\x%02x", ord $1) /ge;
        printf STDERR "# %10s: %s\n", $name, $val;
    }
}
