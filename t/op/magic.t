#!./perl

# $RCSfile: magic.t,v $$Revision: 4.1 $$Date: 92/08/07 18:28:05 $

BEGIN {
    $^W = 1;
    $| = 1;
    chdir 't' if -d 't';
    @INC = '../lib';
    $SIG{__WARN__} = sub { die @_ };
}

sub ok {
    my ($n, $result, $info) = @_;
    if ($result) {
	print "ok $n\n";
    }
    else {
    	print "not ok $n\n";
	print "# $info\n" if $info;
    }
}

print "1..28\n";

eval '$ENV{"foo"} = "hi there";';	# check that ENV is inited inside eval
ok 1, `echo \$foo` eq "hi there\n";

unlink 'ajslkdfpqjsjfk';
$! = 0;
open(FOO,'ajslkdfpqjsjfk');
ok 2, $!, $!;
close FOO; # just mention it, squelch used-only-once

# the next tests are embedded inside system simply because sh spits out
# a newline onto stderr when a child process kills itself with SIGINT.

system './perl', '-e', <<'END';

    $| = 1;		# command buffering

    $SIG{"INT"} = "ok3"; kill "INT",$$;
    $SIG{"INT"} = "IGNORE"; kill 2,$$; print "ok 4\n";
    $SIG{"INT"} = "DEFAULT"; kill 2,$$; print "not ok\n";

    sub ok3 {
	if (($x = pop(@_)) eq "INT") {
	    print "ok 3\n";
	}
	else {
	    print "not ok 3 ($x @_)\n";
	}
    }

END

@val1 = @ENV{keys(%ENV)};	# can we slice ENV?
@val2 = values(%ENV);
ok 5, join(':',@val1) eq join(':',@val2);
ok 6, @val1 > 1;

# regex vars
'foobarbaz' =~ /b(a)r/;
ok 7, $` eq 'foo', $`;
ok 8, $& eq 'bar', $&;
ok 9, $' eq 'baz', $';
ok 10, $+ eq 'a', $+;

# $"
@a = qw(foo bar baz);
ok 11, "@a" eq "foo bar baz", "@a";
{
    local $" = ',';
    ok 12, "@a" eq "foo,bar,baz", "@a";
}

# $;
%h = ();
$h{'foo', 'bar'} = 1;
ok 13, (keys %h)[0] eq "foo\034bar", (keys %h)[0];
{
    local $; = 'x';
    %h = ();
    $h{'foo', 'bar'} = 1;
    ok 14, (keys %h)[0] eq 'fooxbar', (keys %h)[0];
}

# $?, $@, $$
system 'true';
ok 15, $? == 0, $?;
system 'false';
ok 16, $? != 0, $?;

eval { die "foo\n" };
ok 17, $@ eq "foo\n", $@;

ok 18, $$ > 0, $$;

# $^X and $0
$script = './show-shebang';
ok 19, open(SCRIPT, ">$script"), $!;
ok 20, print(SCRIPT <<'EOF'), $!;
#!./perl
print "\$^X is $^X, \$0 is $0\n";
EOF
ok 21, close(SCRIPT), $!;
ok 22, chmod(0755, $script), $!;
$s = "\$^X is ./perl, \$0 is $script\n";
$_ = `$script`;
ok 23, $_ eq $s, ":$_:";
$_ = `./perl $script`;
ok 24, $_ eq $s, ":$_:";
ok 25, unlink($script), $!;

# $], $^O, $^T
ok 26, $] >= 5.00319, $];
ok 27, $^O;
ok 28, $^T > 850000000, $^T;
