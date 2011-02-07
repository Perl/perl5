#!./perl

use strict;
use warnings;

use Test::More;
use Test::PerlRun;
use Config;

BEGIN {
    plan(skip_all => 'no /dev/null') unless -c '/dev/null';

    my $dev_tty = $^O eq 'VMS' ? 'TT:' : '/dev/tty';
    plan(skip_all => "no $dev_tty") unless -c $dev_tty;
    plan(skip_all => "\$ENV{PERL5DB} is already set to '$ENV{PERL5DB}'")
        if $ENV{PERL5DB};
}

plan(tests => 13);

my $rc_filename = '.perldb';

sub rc {
    open my $rc_fh, '>', $rc_filename
        or die $!;
    print {$rc_fh} @_;
    close ($rc_fh);

    # overly permissive perms gives "Must not source insecure rcfile"
    # and hangs at the DB(1> prompt
    chmod 0644, $rc_filename;
}

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

my $out_fn = 'db.out';

sub _out_contents
{
    return _slurp($out_fn);
}

{
    my $target = '../lib/perl5db/t/eval-line-bug';

    rc(
        <<"EOF",
    &parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

    sub afterinit {
        push(\@DB::typeahead,
            'b 23',
            'n',
            'n',
            'n',
            'c', # line 23
            'n',
            "p \\\@{'main::_<$target'}",
            'q',
        );
    }
EOF
    );

    {
        local $ENV{PERLDB_OPTS} = "ReadLine=0";
        perlrun_stdout_is({switches => [ '-d' ], file => $target}, '');
    }
}

like(_out_contents(), qr/sub factorial/,
    'The ${main::_<filename} variable in the debugger was not destroyed'
);

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0";
    perlrun_stdout_like({switches => [ '-d' ],
			 file => '../lib/perl5db/t/lvalue-bug'},
			qr/foo is defined/,
			'lvalue subs work in the debugger');
}

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    perlrun_stdout_like({switches => [ '-d' ],
			 file => '../lib/perl5db/t/symbol-table-bug'},
			qr/Undefined symbols 0/,
			'there are no undefined values in the symbol table');
}

SKIP: {
    skip('This perl has threads, skipping non-threaded debugger tests', 1)
	if $Config{usethreads};
    perlrun_stderr_like({switches => '-dt', code => 0},
			qr/This Perl not built to support threads/,
			'Perl debugger correctly complains that it was not built with threads');
}

SKIP: {
    skip('This perl is not threaded, skipping threaded debugger tests', 1)
	unless $Config{usethreads};
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    perlrun_stdout_like({switches => '-dt',
			 file => '../lib/perl5db/t/symbol-table-bug'},
			 qr/Undefined symbols 0/,
			 'there are no undefined values in the symbol table when running with thread support');
}


# Test [perl #61222]
{
    rc(
        <<'EOF',
        &parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

        sub afterinit {
            push(@DB::typeahead,
                'm Pie',
                'q',
            );
        }
EOF
    );

    perlrun_exit_status_is({switches => '-d',
			    file => '../lib/perl5db/t/rt-61222'},
			   0, 'Program exits cleanly');
    unlike(_out_contents(), qr/INCORRECT/, "[perl #61222]");
}



# Test for Proxy constants
{
    rc(
        <<'EOF',

&parse_options("NonStop=0 ReadLine=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push(@DB::typeahead,
        'm main->s1',
        'q',
    );
}

EOF
    );

    perlrun_stderr_is({switches => '-d',
		      file => '../lib/perl5db/t/proxy-constants'},
		      '', 'proxy constant subroutines');
}

# Testing that we can set a line in the middle of the file.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b ../lib/perl5db/t/MyModule.pm:12',
    'c',
    q/do { use IO::Handle; STDOUT->autoflush(1); print "Var=$var\n"; }/,
    'c',
    'q',
    );

}
EOF

    perlrun_stdout_like({switches => ['-d', '-I', '../lib/perl5db/t'],
			 file => '../lib/perl5db/t/filename-line-breakpoint'},
			qr/
        ^Var=Bar$
            .*
        ^In\ MyModule\.$
            .*
        ^In\ Main\ File\.$
            .*
        /msx,
			'Can set breakpoint in a line in the middle of the file.');
}


# [perl #66110] Call a subroutine inside a regex
{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    perlrun_stdout_like({switches => '-d',
			 file => '../lib/perl5db/t/rt-66110'},
			qr/All tests successful/, '[perl #66110]');
}

# taint tests

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    perlrun_stdout_like({switches => [ '-d', '-T', '-I../lib' ],
			 file => '../lib/perl5db/t/taint'},
			qr/^\[\$\^X]\[done]$/, "taint");
}

# Testing that we can set a breakpoint
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 6',
    'c',
    q/do { use IO::Handle; STDOUT->autoflush(1); print "X={$x}\n"; }/,
    'c',
    'q',
    );

}
EOF

    perlrun_stdout_like({switches => '-d',
			file => '../lib/perl5db/t/breakpoint-bug'},
			qr/
        X=\{Two\}
        /msx,
			'Can set breakpoint in a line.');
}



# clean up.

END {
    1 while unlink ($rc_filename, $out_fn);
}
