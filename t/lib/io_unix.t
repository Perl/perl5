
#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
        chdir 't' if -d 't';
        @INC = '../lib' if -d '../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        if ( ($Config{'extensions'} !~ /\bSocket\b/ ||
              $Config{'extensions'} !~ /\bIO\b/)    &&
              !(($^O eq 'VMS') && $Config{d_socket})) {
            print "1..0\n";
            exit 0;
        }
    }
}

$PATH = "/tmp/sock-$$";

# Test if we can create the file within the tmp directory
if (-e $PATH or not open(TEST, ">$PATH")) {
    print "1..0\n";
    exit 0;
}
close(TEST);
unlink($PATH) or die "Can't unlink $PATH: $!";

# Start testing
$| = 1;
print "1..5\n";

use IO::Socket;

$listen = IO::Socket::UNIX->new(Local=>$PATH, Listen=>0) || die "$!";
print "ok 1\n";

if($pid = fork()) {

    $sock = $listen->accept();
    print "ok 2\n";

    print $sock->getline();

    print $sock "ok 4\n";

    $sock->close;

    waitpid($pid,0);
    unlink($PATH) || warn "Can't unlink $PATH: $!";

    print "ok 5\n";

} elsif(defined $pid) {

    $sock = IO::Socket::UNIX->new(Peer => $PATH) or die "$!";

    print $sock "ok 3\n";

    print $sock->getline();

    $sock->close;

    exit;
} else {
 die;
}
