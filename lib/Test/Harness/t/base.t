print "1..1\n";

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

unless (eval 'require Test::Harness') {
  print "not ok 1\n";
} else {
  print "ok 1\n";
}
