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

print "1..14\n";

my $test = 1;

sub ok { print "ok $test\n"; $test++ }


use B::Deparse;
my $deparse = B::Deparse->new() or print "not ";
ok;

# Tell B::Deparse about our ambient pragmas
{ my ($hint_bits, $warning_bits);
 BEGIN {($hint_bits, $warning_bits) = ($^H, ${^WARNING_BITS})}
 $deparse->ambient_pragmas (
     hint_bits    => $hint_bits,
     warning_bits => $warning_bits,
     '$['         => 0 + $[
 );
}

print "not " if "{\n    1;\n}" ne $deparse->coderef2text(sub {1});
ok;

print "not " if "{\n    '???';\n    2;\n}" ne
                    $deparse->coderef2text(sub {1;2});
ok;

print "not " if "{\n    \$test /= 2 if ++\$test;\n}" ne
                    $deparse->coderef2text(sub {++$test and $test/=2;});
ok;

print "not " if "{\n    -((1, 2) x 2);\n}" ne
                    $deparse->coderef2text(sub {-((1,2)x2)});
ok;

{
my $a = <<'EOF';
{
    $test = sub : lvalue {
        my $x;
    }
    ;
}
EOF
chomp $a;
print "not " if $deparse->coderef2text(sub{$test = sub : lvalue{my $x}}) ne $a;
ok;

$a =~ s/lvalue/method/;
print "not " if $deparse->coderef2text(sub{$test = sub : method{my $x}}) ne $a;
ok;

$a =~ s/method/locked method/;
print "not " if $deparse->coderef2text(sub{$test = sub : method locked {my $x}})
                                     ne $a;
ok;
}

print "not " if (eval "sub ".$deparse->coderef2text(sub () { 42 }))->() != 42;
ok;

use constant 'c', 'stuff';
print "not " if (eval "sub ".$deparse->coderef2text(\&c))->() ne 'stuff';
ok;

$a = 0;
print "not " if "{\n    (-1) ** \$a;\n}"
		ne $deparse->coderef2text(sub{(-1) ** $a });
ok;

# XXX ToDo - constsub that returns a reference
#use constant cr => ['hello'];
#my $string = "sub " . $deparse->coderef2text(\&cr);
#my $val = (eval $string)->();
#print "not " if ref($val) ne 'ARRAY' || $val->[0] ne 'hello';
#ok;

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
    @F = split(" ", $_, 0);
    '???';
}

EOF
print "# [$a]\n\# vs expected\n# [$b]\nnot " if $a ne $b;
ok;


# Bug 20001204.07
{
my $foo = $deparse->coderef2text(sub { { 234; }});
# Constants don't get optimised here.
print "not " unless $foo =~ /{.*{.*234;.*}.*}/sm;
ok;
$foo = $deparse->coderef2text(sub { { 234; } continue { 123; } });
unless ($foo =~ /{\s*{\s*do\s*{\s*234;\s*};\s*}\s*continue\s*{\s*123;\s*}\s*}/sm) {
  print "# [$foo]\n\# vs expected\n# [{ { do { 234; }; } continue { 123; } }]\n";
  print "not ";
}
ok;
}
