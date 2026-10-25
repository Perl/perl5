use strict;
use warnings;

# A hub file that was not fully written must be reported as such, both when
# the write fails and when drop_hub later finds the file empty, instead of
# surfacing as "A hub file can only be closed by the process that started it".

use Errno qw/ENOSPC/;

use Test2::Tools::Tiny;
use Test2::Util qw/ipc_separator/;

# Make close() fail on demand inside Test2::IPC::Driver::Files only. The
# override is in place only while that file compiles, so nothing else (such as
# Storable's bareword handles) is affected. Its dependencies load first for the
# same reason, and it is required rather than used so that loading it does not
# turn on IPC for this test.
our $FAIL_CLOSE = 0;
BEGIN {
    require Storable;
    require File::Temp;
    require File::Spec;
    require POSIX;
    require Scalar::Util;
    require Test2::IPC::Driver;
    require Test2::Util::Sig;

    no warnings 'once';
    *CORE::GLOBAL::close = sub (*) {
        my $ok = CORE::close($_[0]);
        return $ok unless $FAIL_CLOSE;
        $! = ENOSPC;
        return 0;
    };
    require Test2::IPC::Driver::Files;

    # The calls compiled above keep their reference to the override.
    delete $CORE::GLOBAL::{close};
}

{
    no warnings 'redefine';
    *Test2::IPC::Driver::abort = sub {
        my $self = shift;
        my ($msg) = @_;
        chomp($msg);
        die "IPC abort: $msg\n";
    };
}

my $hid = join ipc_separator, qw"12345 1 1 1";

my $ipc = Test2::IPC::Driver::Files->new();

my ($added, $err);
{
    local $FAIL_CLOSE = 1;
    $added = eval { $ipc->add_hub($hid); 1 };
    $err = $@;
}
ok(!$added, "add_hub aborts when the hub file cannot be written");
like($err, qr/Could not write hub file '\Q$hid\E'/, "says the hub file could not be written");
my $enospc = do { local $! = ENOSPC; "$!" };
like($err, qr/\Q$enospc\E/, "includes the OS error");

my $hfile = $ipc->hub_file($hid);
open(my $fh, '>', $hfile) or die "Could not truncate '$hfile': $!";
close($fh) or die "Could not close '$hfile': $!";

ok(!eval { $ipc->drop_hub($hid); 1 }, "drop_hub aborts on an empty hub file");
like($@, qr/File for hub '\Q$hid\E' is empty or truncated/, "says the hub file is empty or truncated");
unlike($@, qr/can only be closed by the process/, "does not blame the wrong process");

unlink($hfile);
$ipc = undef;

done_testing;
