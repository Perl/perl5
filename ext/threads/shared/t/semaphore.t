use warnings;

BEGIN {
    chdir 't' if -d 't';
    push @INC ,'../lib';
    require Config; import Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no threads\n";
        exit 0;
    }
}

print "1..1\n";
use threads;
use threads::shared::semaphore;
print "ok 1\n";

