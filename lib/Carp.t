BEGIN {
	chdir 't' if -d 't';
	@INC = '../lib';
}

use Carp qw(carp cluck croak confess);

print "1..19\n";

print "ok 1\n";

$SIG{__WARN__} = sub {
    print "ok $1\n"
	if $_[0] =~ m!ok (\d+)\n at.+\b(?i:carp\.t) line \d+$! };

carp  "ok 2\n";

$SIG{__WARN__} = sub {
    print "ok $1\n"
	if $_[0] =~ m!(\d+) at.+\b(?i:carp\.t) line \d+$! };

carp 3;

sub sub_4 {

$SIG{__WARN__} = sub {
    print "ok $1\n"
	if $_[0] =~ m!^(\d+) at.+\b(?i:carp\.t) line \d+\n\tmain::sub_4\(\) called at.+\b(?i:carp\.t) line \d+$! };

cluck 4;

}

sub_4;

$SIG{__DIE__} = sub {
    print "ok $1\n"
	if $_[0] =~ m!^(\d+) at.+\b(?i:carp\.t) line \d+\n\teval \Q{...}\E called at.+\b(?i:carp\.t) line \d+$! };

eval { croak 5 };

sub sub_6 {
    $SIG{__DIE__} = sub {
	print "ok $1\n"
	    if $_[0] =~ m!^(\d+) at.+\b(?i:carp\.t) line \d+\n\teval \Q{...}\E called at.+\b(?i:carp\.t) line \d+\n\tmain::sub_6\(\) called at.+\b(?i:carp\.t) line \d+$! };

    eval { confess 6 };
}

sub_6;

print "ok 7\n";

# test for caller_info API
my $eval = "use Carp::Heavy; return Carp::caller_info(0);";
my %info = eval($eval);
print "not " if ($info{sub_name} ne "eval '$eval'");
print "ok 8\n";

# test for '...::CARP_NOT used only once' warning from Carp::Heavy
my $warning;
eval {
    BEGIN {
	$^W = 1;
	$SIG{__WARN__} =
	    sub { if( defined $^S ){ warn $_[0] } else { $warning = $_[0] } }
    }
    package Z;
    BEGIN { eval { Carp::croak() } }
};
print $warning ? "not ok 9\n#$warning" : "ok 9\n";


# tests for global variables
sub x { carp @_ }
sub w { cluck @_ }

# $Carp::Verbose;
{   my $aref = [
        qr/t at \S*Carp.t line \d+/,
        qr/t at \S*Carp.t line \d+\n\s*main::x\('t'\) called at \S*Carp.t line \d+/
    ];
    my $test_num = 10; my $i = 0;

    for my $re (@$aref) {
        local $Carp::Verbose = $i++;
        local $SIG{__WARN__} = sub {
	    print "not " unless $_[0] =~ $re;
	    print "ok ".$test_num++." - Verbose\n";
	};
        package Z;
        main::x('t');
    }
}

# $Carp::MaxEvalLen
{   my $test_num = 12;
    for(0,4) {
        my $txt = "Carp::cluck($test_num)";
        local $Carp::MaxEvalLen = $_;
        local $SIG{__WARN__} = sub {
	    "@_"=~/'(.+?)(?:\n|')/s;
	    print "not " unless length $1 eq length $_?substr($txt,0,$_):substr($txt,0);
	    print "ok $test_num - MaxEvalLen\n";
	};
        eval "$txt"; $test_num++;
    }
}

# $Carp::MaxArgLen
{   my $test_num = 14;
    for(0,4) {
        my $arg = 'testtest';
        local $Carp::MaxArgLen = $_;
        local $SIG{__WARN__} = sub {
	    "@_"=~/'(.+?)'/;
	    print "not " unless length $1 eq length $_?substr($arg,0,$_):substr($arg,0);
	    print "ok ".$test_num++." - MaxArgLen\n";
	};

        package Z;
        main::w($arg);
    }
}

# $Carp::MaxArgNums
{   my $test_num = 16; my $i = 0;
    my $aref = [
        qr/1234 at \S*Carp.t line \d+\n\s*main::w\(1, 2, 3, 4\) called at \S*Carp.t line \d+/,
        qr/1234 at \S*Carp.t line \d+\n\s*main::w\(1, 2, \.\.\.\) called at \S*Carp.t line \d+/,
    ];

    for(@$aref) {
        local $Carp::MaxArgNums = $i++;
        local $SIG{__WARN__} = sub {
	    print "not " unless "@_"=~$_;
	    print "ok ".$test_num++." - MaxArgNums\n";
	};

        package Z;
        main::w(1..4);
    }
}

# $Carp::CarpLevel
{   my $test_num = 18; my $i = 0;
    my $aref = [
        qr/1 at \S*Carp.t line \d+\n\s*main::w\(1\) called at \S*Carp.t line \d+/,
        qr/1 at \S*Carp.t line \d+$/,
    ];

    for (@$aref) {
        local $Carp::CarpLevel = $i++;
        local $SIG{__WARN__} = sub {
	    print "not " unless "@_"=~$_;
	    print "ok ".$test_num++." - CarpLevel\n";
	};

        package Z;
        main::w(1);
    }
}
