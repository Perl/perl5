#!perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
    skip_all_without_config('d_fork');
}
use strict;

my $perl = which_perl();
watchdog(60);
$^F = 65536;

$SIG{PIPE} = sub {
    print "# Ignoring a SIGPIPE\n";
};
	      
sub one_pipe {
    my ($stdin, @args) = @_;
    pipe my $r, my $w or die "pipe: $!";

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    unless ($pid) {
	# child
	open STDIN, '<&', $r or die "reopen: $!";
	# Has to be a die, as we're in the child:
	my $fileno = fileno STDIN;
	die "fileno STDIN is $fileno" unless defined $fileno && $fileno == 0;
	close $w or die "close: $!";
	exec $perl, @args;
	die "exec: $!";
    }

    close $r or die "close: $!";
    print $w $stdin;
    close $w or die "close: $!";

    waitpid $pid, 0;
}

one_pipe(qq{print "ok 1 - simple OK\\n"});
one_pipe(qq{print "not ok 2 - should not read stdin\\n"},
	 '-eprint "ok 2 - -e is honoured\n"');
one_pipe(qq{print "ok 3 - fd open\\n"}, '/dev/fd/0');
# This one exploits knowledge of the implementation to be sure which code is
# being run. I don't think that we should rely on it being atoi() internally.
one_pipe(qq{print "ok 4 - *our* fd open\\n"}, '/dev/fd/00');
one_pipe(<<'EOP', '-x', '/dev/fd/00');
print "not ok 5 - -x didn't work\n";
die;
#!perl
print "ok 5 - -x worked\n";
EOP

{
    pipe my $r, my $w or die "pipe: $!";
    pipe my $r2, my $w2 or die "pipe: $!";

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    unless ($pid) {
	# child
	open STDIN, '<&', $r or die "reopen: $!";
	# Has to be a die, as we're in the child:
	my $fileno = fileno STDIN;
	die "fileno STDIN is $fileno" unless defined $fileno && $fileno == 0;
	$fileno = fileno $r2;
	die "fileno \$r2 is $fileno" unless defined $fileno;
	close $w or die "close: $!";
	close $w2 or die "close: $!";
	exec $perl, "/dev/fd/$fileno";
	die "exec: $!";
    }

    close $r or die "close: $!";
    close $r2 or die "close: $!";
    print $w qq{print "not ok 6 - you shouldn't see this\n"};
    close $w or die "close: $!";
    print $w2 qq{print "ok 6 - read from the correct file descriptor\\n"};
    close $w2 or die "close: $!";

    waitpid $pid, 0;
}

{
    my $pathname = 'whamm/glipp/klonk';
    one_pipe(qq{print \$0 eq '$pathname' ? "ok 7 - pathname set\\n" : "not ok 7 - pathname was '$0'\n"},
	     "/dev/fd/0/$pathname");
}

curr_test(8);

like(runperl(progfile => '/dev/fd/-1', stderr => 1),
     qr!^Can't open perl script "/dev/fd/-1": !,
     "Can't open a negative file handle");

like(runperl(progfile => '/dev/fd/0/', stderr => 1),
     qr/\AMissing \(suid\) fd script name\r?\n/,
     "Missing suid script name error");

like(runperl(progfile => '/dev/fd/0swoosh', stderr => 1),
     qr/\AWrong syntax \(suid\) fd script name "swoosh"\r?\n/,
     "Wrong suid script name error");

like(runperl(progfile => '/dev/fd/0/a', stderr => 1, switches => ['-x']),
     qr/\ANo -x allowed with \(suid\) fdscript\.\r?\n/,
     'No -x allowed with suid fdscript');

done_testing();
