#!./perl

BEGIN {
    chdir 't' if -d 't';
    if ($^O eq 'MacOS') {
	@INC = qw(: ::lib ::macos:lib);
    } else {
	@INC = '.';
	push @INC, '../lib';
    }
}

$|  = 1;
use warnings;
use strict;
use Config;

print "1..15\n";

use B::Deparse;
my $deparse = B::Deparse->new() or print "not ";
my $i=1;
print "ok " . $i++ . "\n";


# Tell B::Deparse about our ambient pragmas
{ my ($hint_bits, $warning_bits);
 BEGIN {($hint_bits, $warning_bits) = ($^H, ${^WARNING_BITS})}
 $deparse->ambient_pragmas (
     hint_bits    => $hint_bits,
     warning_bits => $warning_bits,
     '$['         => 0 + $[
 );
}

$/ = "\n####\n";
while (<DATA>) {
    chomp;
    s/#.*$//mg;

    my ($input, $expected);
    if (/(.*)\n>>>>\n(.*)/s) {
	($input, $expected) = ($1, $2);
    }
    else {
	($input, $expected) = ($_, $_);
    }

    my $coderef = eval "sub {$input}";

    if ($@) {
	print "not ok " . $i++ . "\n";
	print "# $@";
    }
    else {
	my $deparsed = $deparse->coderef2text( $coderef );
	my $regex = quotemeta($expected);
	do {
	    no warnings 'misc';
	    $regex =~ s/\s+/\s+/g;
	};

	my $ok = ($deparsed =~ /^\{\s*$regex\s*\}$/);
	print (($ok ? "ok " : "not ok ") . $i++ . "\n");
	if (!$ok) {
	    print "# EXPECTED:\n";
	    $regex =~ s/^/# /mg;
	    print "$regex\n";

	    print "\n# GOT: \n";
	    $deparsed =~ s/^/# /mg;
	    print "$deparsed\n";
	}
    }
}

use constant 'c', 'stuff';
print "not " if (eval "sub ".$deparse->coderef2text(\&c))->() ne 'stuff';
print "ok " . $i++ . "\n";

$a = 0;
print "not " if "{\n    (-1) ** \$a;\n}"
		ne $deparse->coderef2text(sub{(-1) ** $a });
print "ok " . $i++ . "\n";

# XXX ToDo - constsub that returns a reference
#use constant cr => ['hello'];
#my $string = "sub " . $deparse->coderef2text(\&cr);
#my $val = (eval $string)->();
#print "not " if ref($val) ne 'ARRAY' || $val->[0] ne 'hello';
#print "ok " . $i++ . "\n";

my $a;
my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

my $path = join " ", map { qq["-I$_"] } @INC;
my $redir = $Is_MacOS ? "" : "2>&1";

$a = `$^X $path "-MO=Deparse" -anle 1 $redir`;
$a =~ s/-e syntax OK\n//g;
$a =~ s{\\340\\242}{\\s} if (ord("\\") == 224); # EBCDIC, cp 1047 or 037
$a =~ s{\\274\\242}{\\s} if (ord("\\") == 188); # $^O eq 'posix-bc'
$b = <<'EOF';
LINE: while (defined($_ = <ARGV>)) {
    chomp $_;
    our(@F) = split(" ", $_, 0);
    '???';
}
EOF
print "# [$a]\n\# vs expected\n# [$b]\nnot " if $a ne $b;
print "ok " . $i++ . "\n";

__DATA__
# 2
1;
####
# 3
{
    no warnings;
    '???';
    2;
}
####
# 4
my $test;
++$test and $test /= 2;
>>>>
my $test;
$test /= 2 if ++$test;
####
# 5
-((1, 2) x 2);
####
# 6
{
    my $test = sub : lvalue {
	my $x;
    }
    ;
}
####
# 7
{
    my $test = sub : method {
	my $x;
    }
    ;
}
####
# 8
{
    my $test = sub : locked method {
	my $x;
    }
    ;
}
####
# 9
{
    234;
}
continue {
    123;
}
####
# 10
my $x;
print $main::x;
####
# 11
my @x;
print $main::x[1];
####
# 12
my %x;
$x{warn()};
