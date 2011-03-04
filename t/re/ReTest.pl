#!./perl
#
# This is the test subs used for regex testing. 
# This used to be part of re/pat.t
use warnings;
use strict;
use 5.010;
use base qw/Exporter/;
use Carp;
use vars qw(
    $EXPECTED_TESTS 
    $TODO
    $running_as_thread
    $IS_ASCII
    $IS_EBCDIC
    $ordA
);

$| = 1;

our $ordA = ord ('A');  # This defines ASCII/UTF-8 vs EBCDIC/UTF-EBCDIC
# This defined the platform.
our $IS_ASCII  = $ordA ==  65;
our $IS_EBCDIC = $ordA == 193;

use vars '%Config';
eval 'use Config';          #  Defaults assumed if this fails

my $test = 0;
my $done_plan;
sub plan {
    my (undef,$tests)= @_;
    if (defined $tests) {
        die "Number of tests already defined! ($EXPECTED_TESTS)"
            if $EXPECTED_TESTS;
        $EXPECTED_TESTS= $tests;
    }
    if ($EXPECTED_TESTS) {
        print "1..$EXPECTED_TESTS\n" if !$done_plan++;
    } else {
        print "Number of tests not declared!";
    }
}

sub pretty {
    my ($mess) = @_;
    return unless defined $mess;
    $mess =~ s/\n/\\n/g;
    $mess =~ s/\r/\\r/g;
    $mess =~ s/\t/\\t/g;
    $mess =~ s/([\00-\37\177])/sprintf '\%03o', ord $1/eg;
    $mess =~ s/#/\\#/g;
    $mess;
}

sub safe_globals {
    defined($_) and s/#/\\#/g for $TODO;
}

sub _ok {
    my ($ok, $mess, $error) = @_;
    plan();
    safe_globals();
    $mess    = defined $mess ? pretty ($mess) : 'Noname test';
    $mess   .= " # TODO $TODO"     if defined $TODO;

    my $line_nr = (caller(1)) [2];

    printf "%sok %d - %s\n",
              ($ok ? "" : "not "),
              ++ $test,
              "$mess\tLine $line_nr";

    unless ($ok) {
        print "# Failed test at line $line_nr\n" unless defined $TODO;
        if ($error) {
            no warnings 'utf8';
            chomp $error;
            $error = join "\n#", map {pretty $_} split /\n\h*#/ => $error;
            $error = "# $error" unless $error =~ /^\h*#/;
            print $error, "\n";
        }
    }

    return $ok;
}

# Force scalar context on the pattern match
sub  ok ($;$$) {_ok  $_ [0], $_ [1], $_ [2]}
sub nok ($;$$) {_ok !$_ [0], "Failed: " . $_ [1], $_ [2]}


sub skip {
    my $why = shift;
    safe_globals();
    $why =~ s/\n.*//s;
    my $ok;
    if (defined $TODO) {
	$why = "TODO & SKIP $why $TODO";
	$ok = "not ok";
    } else {
	$why = "SKIP $why";
	$ok = "ok";
    }

    my $n = shift // 1;
    my $line_nr = (caller(0)) [2];
    for (1 .. $n) {
        ++ $test;
        print "$ok $test # $why\tLine $line_nr\n";
    }
    no warnings "exiting";
    last SKIP;
}

sub iseq ($$;$) { 
    my ($got, $expected, $name) = @_;

    my $pass;
    if(!defined $got || !defined $expected) {
        # undef only matches undef
        $pass = !defined $got && !defined $expected;
    }
    else {
        $pass = $got eq $expected;
    }

    $_ = defined ($_) ? "'$_'" : "undef" for $got, $expected;

    my $error = "# expected: $expected\n" .
                "#   result: $got";

    _ok $pass, $name, $error;
}   

sub isneq ($$;$) { 
    my ($got, $isnt, $name) = @_;

    my $pass;
    if(!defined $got || !defined $isnt) {
        # undef only matches undef
        $pass = defined $got || defined $isnt;
    }
    else {
        $pass = $got ne $isnt;
    }

    $got = defined $got ? "'$got'" : "undef";
    my $error = "# results are equal ($got)";

    _ok $pass, $name, $error;
}   

*is = \&iseq;
*isnt = \&isneq;

sub like ($$$) {
    my (undef, $expected, $name) = @_;
    my ($pass, $error);
    $pass = $_[0] =~ /$expected/;
    unless ($pass) {
	$error = "#      got '$_[0]'\n# expected /$expected/";
    }
    _ok($pass, $name, $error);
}

sub unlike ($$$) {
    my (undef, $expected, $name) = @_;
    my ($pass, $error);
    $pass = $_[0] !~ /$expected/;
    unless ($pass) {
	$error = "#      got '$_[0]'\n# expected !~ /$expected/";
    }
    _ok($pass, $name, $error);
}

sub eval_ok ($;$) {
    my ($code, $name) = @_;
    local $@;
    if (ref $code) {
        _ok eval {&$code} && !$@, $name;
    }
    else {
        _ok eval  ($code) && !$@, $name;
    }
}

sub must_die {
    my ($code, $pattern, $name) = @_;
    Carp::confess("Bad pattern") unless $pattern;
    undef $@;
    ref $code ? &$code : eval $code;
    my  $r = $@ && $@ =~ /$pattern/;
    _ok $r, $name // "\$\@ =~ /$pattern/";
}

sub must_warn {
    my ($code, $pattern, $name) = @_;
    Carp::confess("Bad pattern") unless $pattern;
    my $w;
    local $SIG {__WARN__} = sub {$w .= join "" => @_};
    use warnings 'all';
    ref $code ? &$code : eval $code;
    my $r = $w && $w =~ /$pattern/;
    $w //= "UNDEF";
    _ok $r, $name // "Got warning /$pattern/",
            "# expected: /$pattern/\n" .
            "#   result: $w";
}

sub may_not_warn {
    my ($code, $name) = @_;
    my $w;
    local $SIG {__WARN__} = sub {$w .= join "" => @_};
    use warnings 'all';
    ref $code ? &$code : eval $code;
    _ok !$w, $name, "Got warning '$w'";
}

1;
