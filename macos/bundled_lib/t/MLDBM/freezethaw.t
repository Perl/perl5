#!/usr/bin/perl -w
use Fcntl;
use MLDBM qw(SDBM_File FreezeThaw);
use Data::Dumper;
eval { require FreezeThaw };
if ($@) {
	print "1..0\n";
	exit 0;
}
tie %o, MLDBM, 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
print "1..4\n";

$c = [\'c'];
$b = {};
$a = [1, $b, $c];
$b->{a} = $a;
$b->{b} = $a->[1];
$b->{c} = $a->[2];
@o{qw(a b c)} = ($a, $b, $c);
$o{d} = "{once upon a time}";
$o{e} = 1024;
$o{f} = 1024.1024;
$first = Data::Dumper->new([@o{qw(a b c)}], [qw(a b c)])->Quotekeys(0)->Dump;
$second = <<'EOT';
$a = [
       1,
       {
         a => $a,
         b => $a->[1],
         c => [
                \'c'
              ]
       },
       $a->[1]{c}
     ];
$b = {
       a => [
              1,
              $b,
              [
                \'c'
              ]
            ],
       b => $b,
       c => $b->{a}[2]
     };
$c = [
       \'c'
     ];
EOT
if ($first eq $second) { print "ok 1\n" }
else { print "|$first|\n--vs--\n|$second|\nnot ok 1\n" }
print ($o{d} eq "{once upon a time}" ? "ok 2\n" : "# |$o{d}|\nnot ok 2\n");
print ($o{e} == 1024 ? "ok 3\n" : "# |$o{e}|\nnot ok 3\n");
print ($o{f} eq 1024.1024 ? "ok 4\n" : "# |$o{f}|\nnot ok 4\n");
