#!/usr/bin/perl
#
# Check SPLICE function's return value
# (04_splice.t checks its effect on the file)
#

my $file = "tf$$.txt";
my $data = "rec0blahrec1blahrec2blah";

print "1..45\n";

my $N = 1;
use Tie::File;
print "ok $N\n"; $N++;  # partial credit just for showing up

my $o = tie @a, 'Tie::File', $file, recsep => 'blah';
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

my $n;

# (3-12) splicing at the beginning
init_file($data);

@r = splice(@a, 0, 0, "rec4");
check_result();
@r = splice(@a, 0, 1, "rec5");       # same length
check_result("rec4");
@r = splice(@a, 0, 1, "record5");    # longer
check_result("rec5");

@r = splice(@a, 0, 1, "r5");         # shorter
check_result("record5");
@r = splice(@a, 0, 1);               # removal
check_result("r5");
@r = splice(@a, 0, 0);               # no-op
check_result();
@r = splice(@a, 0, 0, 'r7', 'rec8'); # insert more than one
check_result();
@r = splice(@a, 0, 2, 'rec7', 'record8', 'rec9'); # insert more than delete
check_result('r7', 'rec8');

@r = splice(@a, 0, 3, 'record9', 'rec10'); # delete more than insert
check_result('rec7', 'record8', 'rec9');
@r = splice(@a, 0, 2);               # delete more than one
check_result('record9', 'rec10');


# (13-22) splicing in the middle
@r = splice(@a, 1, 0, "rec4");
check_result();
@r = splice(@a, 1, 1, "rec5");       # same length
check_result('rec4');
@r = splice(@a, 1, 1, "record5");    # longer
check_result('rec5');

@r = splice(@a, 1, 1, "r5");         # shorter
check_result("record5");
@r = splice(@a, 1, 1);               # removal
check_result("r5");
@r = splice(@a, 1, 0);               # no-op
check_result();
@r = splice(@a, 1, 0, 'r7', 'rec8'); # insert more than one
check_result();
@r = splice(@a, 1, 2, 'rec7', 'record8', 'rec9'); # insert more than delete
check_result('r7', 'rec8');

@r = splice(@a, 1, 3, 'record9', 'rec10'); # delete more than insert
check_result('rec7', 'record8', 'rec9');
@r = splice(@a, 1, 2);               # delete more than one
check_result('record9','rec10');

# (23-32) splicing at the end
@r = splice(@a, 3, 0, "rec4");
check_result();
@r = splice(@a, 3, 1, "rec5");       # same length
check_result('rec4');
@r = splice(@a, 3, 1, "record5");    # longer
check_result('rec5');

@r = splice(@a, 3, 1, "r5");         # shorter
check_result('record5');
@r = splice(@a, 3, 1);               # removal
check_result('r5');
@r = splice(@a, 3, 0);               # no-op
check_result();
@r = splice(@a, 3, 0, 'r7', 'rec8'); # insert more than one
check_result();
@r = splice(@a, 3, 2, 'rec7', 'record8', 'rec9'); # insert more than delete
check_result('r7', 'rec8');

@r = splice(@a, 3, 3, 'record9', 'rec10'); # delete more than insert
check_result('rec7', 'record8', 'rec9');
@r = splice(@a, 3, 2);               # delete more than one
check_result('record9', 'rec10');

# (33-42) splicing with negative subscript
@r = splice(@a, -1, 0, "rec4");
check_result();
@r = splice(@a, -1, 1, "rec5");       # same length
check_result('rec2');
@r = splice(@a, -1, 1, "record5");    # longer
check_result("rec5");

@r = splice(@a, -1, 1, "r5");         # shorter
check_result("record5");
@r = splice(@a, -1, 1);               # removal
check_result("r5");
@r = splice(@a, -1, 0);               # no-op  
check_result();
@r = splice(@a, -1, 0, 'r7', 'rec8'); # insert more than one
check_result();
@r = splice(@a, -1, 2, 'rec7', 'record8', 'rec9'); # insert more than delete
check_result('rec4');

@r = splice(@a, -3, 3, 'record9', 'rec10'); # delete more than insert
check_result('rec7', 'record8', 'rec9');
@r = splice(@a, -4, 3);               # delete more than one
check_result('r7', 'rec8', 'record9');

# (43) scrub it all out
@r = splice(@a, 0, 3);
check_result('rec0', 'rec1', 'rec10');

# (44) put some back in
@r = splice(@a, 0, 0, "rec0", "rec1");
check_result();

# (45) what if we remove too many records?
@r = splice(@a, 0, 17);
check_result('rec0', 'rec1');

sub init_file {
  my $data = shift;
  open F, "> $file" or die $!;
  print F $data;
  close F;
}

# actual results are in @r.
# expected results are in @_
sub check_result {
  my @x = @_;
  s/blah$// for @r;
  my $good = 1;
  $good = 0 unless @r == @x;
  for my $i (0 .. $#r) {
    $good = 0 unless $r[$i] eq $x[$i];
  }
  print $good ? "ok $N\n" : "not ok $N \# was (@r); should be (@x)\n";
  $N++;
}

END {
  1 while unlink $file;
}

