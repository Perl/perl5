#!./perl -w

use Config;
BEGIN {
    require Test::More;
    if (!$Config{'d_fork'}
       # open2/3 supported on win32 (but not Borland due to CRT bugs)
       && (($^O ne 'MSWin32' && $^O ne 'NetWare') || $Config{'cc'} =~ /^bcc/i))
    {
	Test::More->import(skip_all => 'open2/3 not available with MSWin32+Netware+cc=bcc');
	exit 0;
    }
    # make warnings fatal
    $SIG{__WARN__} = sub { die @_ };
}

use strict;
use IPC::Open2;
use Test::More tests => 7;

my $perl = $^X;

sub cmd_line {
	if ($^O eq 'MSWin32' || $^O eq 'NetWare') {
		return qq/"$_[0]"/;
	}
	else {
		return $_[0];
	}
}

STDOUT->autoflush;
STDERR->autoflush;

my $pid = open2('READ', 'WRITE', $perl, '-e', cmd_line('print scalar <STDIN>'));
cmp_ok($pid, '>', 1, 'got a sane process ID');
ok(print WRITE "hi kid\n");
like(<READ>, qr/^hi kid\r?\n$/);
ok(close(WRITE), "closing WRITE: $!");
ok(close(READ), "closing READ: $!");
my $reaped_pid = waitpid $pid, 0;
is($reaped_pid, $pid, "Reaped PID matches");
is($?, 0, '$? should be zero');
