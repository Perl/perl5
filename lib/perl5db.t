#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;
use Config;

BEGIN {
    if (! -c "/dev/null") {
        print "1..0 # Skip: no /dev/null\n";
        exit 0;
    }

    my $dev_tty = '/dev/tty';
    $dev_tty = 'TT:' if ($^O eq 'VMS');
    if (! -c $dev_tty) {
        print "1..0 # Skip: no $dev_tty\n";
        exit 0;
    }
    if ($ENV{PERL5DB}) {
        print "1..0 # Skip: \$ENV{PERL5DB} is already set to '$ENV{PERL5DB}'\n";
        exit 0;
    }
}

plan(30);

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
        runperl(switches => [ '-d' ], progfile => $target);
    }
}

like(_out_contents(), qr/sub factorial/,
    'The ${main::_<filename} variable in the debugger was not destroyed'
);

{
    my $target = '../lib/perl5db/t/eval-line-bug';

    rc(
        <<"EOF",
    &parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

    sub afterinit {
        push(\@DB::typeahead,
            'b 23',
            'c',
            '\$new_var = "Foo"',
            'x "new_var = <\$new_var>\\n";',
            'q',
        );
    }
EOF
    );

    {
        local $ENV{PERLDB_OPTS} = "ReadLine=0";
        runperl(switches => [ '-d' ], progfile => $target);
    }
}

like(_out_contents(), qr/new_var = <Foo>/,
    "no strict 'vars' in evaluated lines.",
);

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0";
    my $output = runperl(switches => [ '-d' ], progfile => '../lib/perl5db/t/lvalue-bug');
    like($output, qr/foo is defined/, 'lvalue subs work in the debugger');
}

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    my $output = runperl(switches => [ '-d' ], progfile => '../lib/perl5db/t/symbol-table-bug');
    like($output, qr/Undefined symbols 0/, 'there are no undefined values in the symbol table');
}

SKIP: {
    if ( $Config{usethreads} ) {
        skip('This perl has threads, skipping non-threaded debugger tests');
    } else {
        my $error = 'This Perl not built to support threads';
        my $output = runperl( switches => [ '-dt' ], stderr => 1 );
        like($output, qr/$error/, 'Perl debugger correctly complains that it was not built with threads');
    }

}
SKIP: {
    if ( $Config{usethreads} ) {
        local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
        my $output = runperl(switches => [ '-dt' ], progfile => '../lib/perl5db/t/symbol-table-bug');
        like($output, qr/Undefined symbols 0/, 'there are no undefined values in the symbol table when running with thread support');
    } else {
        skip("This perl is not threaded, skipping threaded debugger tests");
    }
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

    my $output = runperl(switches => [ '-d' ], stderr => 1, progfile => '../lib/perl5db/t/rt-61222');
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

    my $output = runperl(switches => [ '-d' ], stderr => 1, progfile => '../lib/perl5db/t/proxy-constants');
    is($output, "", "proxy constant subroutines");
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

    my $output = runperl(switches => [ '-d', '-I', '../lib/perl5db/t', ], stderr => 1, progfile => '../lib/perl5db/t/filename-line-breakpoint');

    like($output, qr/
        ^Var=Bar$
            .*
        ^In\ MyModule\.$
            .*
        ^In\ Main\ File\.$
            .*
        /msx,
        "Can set breakpoint in a line in the middle of the file.");
}


# [perl #66110] Call a subroutine inside a regex
{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    my $output = runperl(switches => [ '-d' ], stderr => 1, progfile => '../lib/perl5db/t/rt-66110');
    like($output, "All tests successful.", "[perl #66110]");
}

# [perl 104168] level option for tracing
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    't 2',
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d' ], stderr => 1, progfile => '../lib/perl5db/t/rt-104168');
    my $contents;
    {
        local $/;
        open I, "<", 'db.out' or die $!;
        $contents = <I>;
        close(I);
    }
    like($contents, qr/level 2/, "[perl #104168]");
    unlike($contents, qr/baz/, "[perl #104168]");
}

# taint tests

{
    local $ENV{PERLDB_OPTS} = "ReadLine=0 NonStop=1";
    my $output = runperl(switches => [ '-d', '-T' ], stderr => 1,
        progfile => '../lib/perl5db/t/taint');
    chomp $output if $^O eq 'VMS'; # newline guaranteed at EOF
    is($output, '[$^X][done]', "taint");
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

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/breakpoint-bug');

    like($output, qr/
        X=\{Two\}
        /msx,
        "Can set breakpoint in a line.");
}


# Testing that we can disable a breakpoint at a numeric line.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 7',
    'b 11',
    'disable 7',
    'c',
    q/print "X={$x}\n";/,
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-1'); +
    like($output, qr/
        X=\{SecondVal\}
        /msx,
        "Can set breakpoint in a line.");
}

# Testing that we can re-enable a breakpoint at a numeric line.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 8',
    'b 24',
    'disable 24',
    'c',
    'enable 24',
    'c',
    q/print "X={$x}\n";/,
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-2'); 
    like($output, qr/
        X=\{SecondValOneHundred\}
        /msx,
        "Can set breakpoint in a line.");
}
# clean up.

# Disable and enable for breakpoints on outer files.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 10',
    'b ../lib/perl5db/t/EnableModule.pm:14',
    'disable ../lib/perl5db/t/EnableModule.pm:14',
    'c',
    'enable ../lib/perl5db/t/EnableModule.pm:14',
    'c',
    q/print "X={$x}\n";/,
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', '-I', '../lib/perl5db/t', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-3'); +
    like($output, qr/
        X=\{SecondValTwoHundred\}
        /msx,
        "Can set breakpoint in a line.");
}

# Testing that the prompt with the information appears.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-1');

    like(_out_contents(), qr/
        ^main::\([^\)]*\bdisable-breakpoints-1:2\):\n
        2:\s+my\ \$x\ =\ "One";\n
        /msx,
        "Prompt should display the first line of code.");
}

# Testing that R (restart) and "B *" work.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 13',
    'c',
    'B *',
    'b 9',
    'R',
    'c',
    q/print "X={$x};dummy={$dummy}\n";/,
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-1');
    like($output, qr/
        X=\{FirstVal\};dummy=\{1\}
        /msx,
        "Restart and delete all breakpoints work properly.");
}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'c 15',
    q/print "X={$x}\n";/,
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-1'); +
    like($output, qr/
        X=\{ThirdVal\}
        /msx,
        "'c line_num' is working properly.");
}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'n',
    'n',
    'b . $exp > 200',
    'c',
    q/print "Exp={$exp}\n";/,
    'q',
    );
}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/break-on-dot'); +
    like($output, qr/
        Exp=\{256\}
        /msx,
        "'b .' is working correctly.");
}

# Testing that the prompt with the information appears inside a subroutine call.
# See https://rt.perl.org/rt3/Ticket/Display.html?id=104820
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'c back',
    'q',
    );
}
EOF
    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/with-subroutine');

    like(_out_contents(), 
        qr/
        ^main::back\([^\)\n]*\bwith-subroutine:15\):[\ \t]*\n
        ^15:\s*print\ "hello\ back\\n";
        /msx,
        "Prompt should display the line of code inside a subroutine.");
}

# Checking that the p command works.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'p "<<<" . (4*6) . ">>>"',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/with-subroutine');

    like(_out_contents(), 
        qr/<<<24>>>/,
        "p command works.");
}

# Tests for x.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    q/x {500 => 600}/,
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/with-subroutine');

    like(_out_contents(), 
        # qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/,
        qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/ms,
        "x command test."
    );
}

# Tests for "T" (stack trace).
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'c baz',
    'T',
    'q',
    );

}
EOF

    my $prog_fn = '../lib/perl5db/t/rt-104168';
    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => $prog_fn,);

    my $re_text = join('',
        map {
        sprintf(
            "%s = %s\\(\\) called from file " .
            "'" . quotemeta($prog_fn) . "' line %s\\n",
            (map { quotemeta($_) } @$_)
            )
        } 
        (
            ['.', 'main::baz', 14,],
            ['.', 'main::bar', 9,],
            ['.', 'main::foo', 6]
        )
    );
    like(_out_contents(), 
        # qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/,
        qr/^$re_text/ms,
        "T command test."
    );
}

# Test for s.
{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'b 9',
    'c',
    's',
    q/print "X={$x};dummy={$dummy}\n";/,
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/disable-breakpoints-1');
    like($output, qr/
        X=\{SecondVal\};dummy=\{1\}
        /msx,
        'test for s - single step',
    );
}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'n',
    'n',
    'b . $exp > 200',
    'c',
    q/print "Exp={$exp}\n";/,
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/break-on-dot'); +
    like($output, qr/
        Exp=\{256\}
        /msx,
        "'b .' is working correctly.");
}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    's',
    'q',
    );

}
EOF

    my $prog_fn = '../lib/perl5db/t/rt-104168';
    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => $prog_fn,);

    like(_out_contents(),
        qr/
        ^main::foo\([^\)\n]*\brt-104168:9\):[\ \t]*\n
        ^9:\s*bar\(\);
        /msx,
        'Test for the s command.',
    );
}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    's uncalled_subroutine()',
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/uncalled-subroutine');

    like ($output, 
        qr/<1,2,3,4,5>\n/,
        'uncalled_subroutine was called after s EXPR()',
        );

}

{
    rc(<<'EOF');
&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");

sub afterinit {
    push (@DB::typeahead,
    'n uncalled_subroutine()',
    'c',
    'q',
    );

}
EOF

    my $output = runperl(switches => [ '-d', ], stderr => 1, progfile => '../lib/perl5db/t/uncalled-subroutine');

    like ($output, 
        qr/<1,2,3,4,5>\n/,
        'uncalled_subroutine was called after n EXPR()',
        );

}

END {
    1 while unlink ($rc_filename, $out_fn);
}
