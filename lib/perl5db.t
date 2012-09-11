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

plan(73);

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
    local $ENV{PERLDB_OPTS};
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
    my $contents = _out_contents();
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

package DebugWrap;

sub new {
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _cmds {
    my $self = shift;

    if (@_) {
        $self->{_cmds} = shift;
    }

    return $self->{_cmds};
}

sub _prog {
    my $self = shift;

    if (@_) {
        $self->{_prog} = shift;
    }

    return $self->{_prog};
}

sub _output {
    my $self = shift;

    if (@_) {
        $self->{_output} = shift;
    }

    return $self->{_output};
}

sub _include_t
{
    my $self = shift;

    if (@_)
    {
        $self->{_include_t} = shift;
    }

    return $self->{_include_t};
}

sub _contents
{
    my $self = shift;

    if (@_)
    {
        $self->{_contents} = shift;
    }

    return $self->{_contents};
}

sub _init
{
    my ($self, $args) = @_;

    my $cmds = $args->{cmds};

    if (ref($cmds) ne 'ARRAY') {
        die "cmds must be an array of commands.";
    }

    $self->_cmds($cmds);

    my $prog = $args->{prog};

    if (ref($prog) ne '' or !defined($prog)) {
        die "prog should be a path to a program file.";
    }

    $self->_prog($prog);

    $self->_include_t($args->{include_t} ? 1 : 0);

    $self->_run();

    return;
}

sub _quote
{
    my ($self, $str) = @_;

    $str =~ s/(["\@\$\\])/\\$1/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;

    return qq{"$str"};
}

sub _run {
    my $self = shift;

    my $rc = qq{&parse_options("NonStop=0 TTY=db.out LineInfo=db.out");\n};

    $rc .= join('',
        map { "$_\n"}
        (q#sub afterinit {#,
         q#push (@DB::typeahead,#,
         (map { $self->_quote($_) . "," } @{$self->_cmds()}),
         q#);#,
         q#}#,
        )
    );

    # I guess two objects like that cannot be used at the same time.
    # Oh well.
    ::rc($rc);

    my $output =
        ::runperl(
            switches =>
            [
                '-d',
                ($self->_include_t ? ('-I', '../lib/perl5db/t') : ())
            ],
            stderr => 1,
            progfile => $self->_prog()
        );

    $self->_output($output);

    $self->_contents(::_out_contents());

    return;
}

sub output_like {
    my ($self, $re, $msg) = @_;

    local $::Level = $::Level + 1;
    ::like($self->_output(), $re, $msg);
}

sub output_unlike {
    my ($self, $re, $msg) = @_;

    local $::Level = $::Level + 1;
    ::unlike($self->_output(), $re, $msg);
}

sub contents_like {
    my ($self, $re, $msg) = @_;

    local $::Level = $::Level + 1;
    ::like($self->_contents(), $re, $msg);
}

sub contents_unlike {
    my ($self, $re, $msg) = @_;

    local $::Level = $::Level + 1;
    ::unlike($self->_contents(), $re, $msg);
}

package main;

# Testing that we can set a line in the middle of the file.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b ../lib/perl5db/t/MyModule.pm:12',
                'c',
                q/do { use IO::Handle; STDOUT->autoflush(1); print "Var=$var\n"; }/,
                'c',
                'q',
            ],
            include_t => 1,
            prog => '../lib/perl5db/t/filename-line-breakpoint'
        }
    );

    $wrapper->output_like(qr/
        ^Var=Bar$
            .*
        ^In\ MyModule\.$
            .*
        ^In\ Main\ File\.$
            .*
        /msx,
        "Can set breakpoint in a line in the middle of the file.");
}

# Testing that we can set a breakpoint
{
    my $wrapper = DebugWrap->new(
        {
            prog => '../lib/perl5db/t/breakpoint-bug',
            cmds =>
            [
                'b 6',
                'c',
                q/do { use IO::Handle; STDOUT->autoflush(1); print "X={$x}\n"; }/,
                'c',
                'q',
            ],
        },
    );

    $wrapper->output_like(
        qr/X=\{Two\}/msx,
        "Can set breakpoint in a line."
    );
}

# Testing that we can disable a breakpoint at a numeric line.
{
    my $wrapper = DebugWrap->new(
        {
            prog =>  '../lib/perl5db/t/disable-breakpoints-1',
            cmds =>
            [
                'b 7',
                'b 11',
                'disable 7',
                'c',
                q/print "X={$x}\n";/,
                'c',
                'q',
            ],
        }
    );

    $wrapper->output_like(qr/X=\{SecondVal\}/ms,
        "Can set breakpoint in a line.");
}

# Testing that we can re-enable a breakpoint at a numeric line.
{
    my $wrapper = DebugWrap->new(
        {
            prog =>  '../lib/perl5db/t/disable-breakpoints-2',
            cmds =>
            [
                'b 8',
                'b 24',
                'disable 24',
                'c',
                'enable 24',
                'c',
                q/print "X={$x}\n";/,
                'c',
                'q',
            ],
        },
    );

    $wrapper->output_like(
        qr/
        X=\{SecondValOneHundred\}
        /msx,
        "Can set breakpoint in a line."
    );
}
# clean up.

# Disable and enable for breakpoints on outer files.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 10',
                'b ../lib/perl5db/t/EnableModule.pm:14',
                'disable ../lib/perl5db/t/EnableModule.pm:14',
                'c',
                'enable ../lib/perl5db/t/EnableModule.pm:14',
                'c',
                q/print "X={$x}\n";/,
                'c',
                'q',
            ],
            prog =>  '../lib/perl5db/t/disable-breakpoints-3',
            include_t => 1,
        }
    );

    $wrapper->output_like(qr/
        X=\{SecondValTwoHundred\}
        /msx,
        "Can set breakpoint in a line.");
}

# Testing that the prompt with the information appears.
{
    my $wrapper = DebugWrap->new(
        {
            cmds => ['q'],
            prog => '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->contents_like(qr/
        ^main::\([^\)]*\bdisable-breakpoints-1:2\):\n
        2:\s+my\ \$x\ =\ "One";\n
        /msx,
        "Prompt should display the first line of code.");
}

# Testing that R (restart) and "B *" work.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 13',
                'c',
                'B *',
                'b 9',
                'R',
                'c',
                q/print "X={$x};dummy={$dummy}\n";/,
                'q',
            ],
            prog =>  '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->output_like(qr/
        X=\{FirstVal\};dummy=\{1\}
        /msx,
        "Restart and delete all breakpoints work properly.");
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'c 15',
                q/print "X={$x}\n";/,
                'c',
                'q',
            ],
            prog =>  '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->output_like(qr/
        X=\{ThirdVal\}
        /msx,
        "'c line_num' is working properly.");
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n',
                'n',
                'b . $exp > 200',
                'c',
                q/print "Exp={$exp}\n";/,
                'q',
            ],
            prog => '../lib/perl5db/t/break-on-dot',
        }
    );

    $wrapper->output_like(qr/
        Exp=\{256\}
        /msx,
        "'b .' is working correctly.");
}

# Testing that the prompt with the information appears inside a subroutine call.
# See https://rt.perl.org/rt3/Ticket/Display.html?id=104820
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'c back',
                'q',
            ],
            prog => '../lib/perl5db/t/with-subroutine',
        }
    );

    $wrapper->contents_like(
        qr/
        ^main::back\([^\)\n]*\bwith-subroutine:15\):[\ \t]*\n
        ^15:\s*print\ "hello\ back\\n";
        /msx,
        "Prompt should display the line of code inside a subroutine.");
}

# Checking that the p command works.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'p "<<<" . (4*6) . ">>>"',
                'q',
            ],
            prog => '../lib/perl5db/t/with-subroutine',
        }
    );

    $wrapper->contents_like(
        qr/<<<24>>>/,
        "p command works.");
}

# Tests for x.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                q/x {500 => 600}/,
                'q',
            ],
            prog => '../lib/perl5db/t/with-subroutine',
        }
    );

    $wrapper->contents_like(
        # qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/,
        qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/ms,
        "x command test."
    );
}

# Tests for "T" (stack trace).
{
    my $prog_fn = '../lib/perl5db/t/rt-104168';
    my $wrapper = DebugWrap->new(
        {
            prog => $prog_fn,
            cmds =>
            [
                'c baz',
                'T',
                'q',
            ],
        }
    );
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
            ['.', 'main::foo', 6],
        )
    );
    $wrapper->contents_like(
        # qr/^0\s+HASH\([^\)]+\)\n\s+500 => 600\n/,
        qr/^$re_text/ms,
        "T command test."
    );
}

# Test for s.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 9',
                'c',
                's',
                q/print "X={$x};dummy={$dummy}\n";/,
                'q',
            ],
            prog => '../lib/perl5db/t/disable-breakpoints-1'
        }
    );

    $wrapper->output_like(qr/
        X=\{SecondVal\};dummy=\{1\}
        /msx,
        'test for s - single step',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n',
                'n',
                'b . $exp > 200',
                'c',
                q/print "Exp={$exp}\n";/,
                'q',
            ],
            prog => '../lib/perl5db/t/break-on-dot'
        }
    );

    $wrapper->output_like(qr/
        Exp=\{256\}
        /msx,
        "'b .' is working correctly.");
}

{
    my $prog_fn = '../lib/perl5db/t/rt-104168';
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                's',
                'q',
            ],
            prog => $prog_fn,
        }
    );

    $wrapper->contents_like(
        qr/
        ^main::foo\([^\)\n]*\brt-104168:9\):[\ \t]*\n
        ^9:\s*bar\(\);
        /msx,
        'Test for the s command.',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                's uncalled_subroutine()',
                'c',
                'q',
            ],

            prog => '../lib/perl5db/t/uncalled-subroutine'}
    );

    $wrapper->output_like(
        qr/<1,2,3,4,5>\n/,
        'uncalled_subroutine was called after s EXPR()',
        );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n uncalled_subroutine()',
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/uncalled-subroutine',
        }
    );

    $wrapper->output_like(
        qr/<1,2,3,4,5>\n/,
        'uncalled_subroutine was called after n EXPR()',
        );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b fact',
                'c',
                'c',
                'c',
                'n',
                'print "<$n>"',
                'q',
            ],
            prog => '../lib/perl5db/t/fact',
        }
    );

    $wrapper->output_like(
        qr/<3>/,
        'b subroutine works fine',
    );
}

# Test for 'M' (module list).
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'M',
                'q',
            ],
            prog => '../lib/perl5db/t/load-modules'
        }
    );

    $wrapper->contents_like(
        qr[Scalar/Util\.pm],
        'M (module list) works fine',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 14',
                'c',
                '$flag = 1;',
                'r',
                'print "Var=$var\n";',
                'q',
            ],
            prog => '../lib/perl5db/t/test-r-statement',
        }
    );

    $wrapper->output_like(
        qr/
            ^Foo$
                .*?
            ^Bar$
                .*?
            ^Var=Test$
        /msx,
        'r statement is working properly.',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'l',
                'q',
            ],
            prog => '../lib/perl5db/t/test-l-statement-1',
        }
    );

    $wrapper->contents_like(
        qr/
            ^1==>\s+\$x\ =\ 1;\n
            2:\s+print\ "1\\n";\n
            3\s*\n
            4:\s+\$x\ =\ 2;\n
            5:\s+print\ "2\\n";\n
        /msx,
        'l statement is working properly (test No. 1).',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'l',
                q/# After l 1/,
                'l',
                q/# After l 2/,
                '-',
                q/# After -/,
                'q',
            ],
            prog => '../lib/perl5db/t/test-l-statement-1',
        }
    );

    my $first_l_out = qr/
        1==>\s+\$x\ =\ 1;\n
        2:\s+print\ "1\\n";\n
        3\s*\n
        4:\s+\$x\ =\ 2;\n
        5:\s+print\ "2\\n";\n
        6\s*\n
        7:\s+\$x\ =\ 3;\n
        8:\s+print\ "3\\n";\n
        9\s*\n
        10:\s+\$x\ =\ 4;\n
    /msx;

    my $second_l_out = qr/
        11:\s+print\ "4\\n";\n
        12\s*\n
        13:\s+\$x\ =\ 5;\n
        14:\s+print\ "5\\n";\n
        15\s*\n
        16:\s+\$x\ =\ 6;\n
        17:\s+print\ "6\\n";\n
        18\s*\n
        19:\s+\$x\ =\ 7;\n
        20:\s+print\ "7\\n";\n
    /msx;
    $wrapper->contents_like(
        qr/
            ^$first_l_out
            [^\n]*?DB<\d+>\ \#\ After\ l\ 1\n
            [\ \t]*\n
            [^\n]*?DB<\d+>\ l\s*\n
            $second_l_out
            [^\n]*?DB<\d+>\ \#\ After\ l\ 2\n
            [\ \t]*\n
            [^\n]*?DB<\d+>\ -\s*\n
            $first_l_out
            [^\n]*?DB<\d+>\ \#\ After\ -\n
        /msx,
        'l followed by l and then followed by -',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'l fact',
                'q',
            ],
            prog => '../lib/perl5db/t/test-l-statement-2',
        }
    );

    my $first_l_out = qr/
        6\s+sub\ fact\ \{\n
        7:\s+my\ \$n\ =\ shift;\n
        8:\s+if\ \(\$n\ >\ 1\)\ \{\n
        9:\s+return\ \$n\ \*\ fact\(\$n\ -\ 1\);
    /msx;

    $wrapper->contents_like(
        qr/
            DB<1>\s+l\ fact\n
            $first_l_out
        /msx,
        'l subroutine_name',
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b fact',
                'c',
                # Repeat several times to avoid @typeahead problems.
                '.',
                '.',
                '.',
                '.',
                'q',
            ],
            prog => '../lib/perl5db/t/test-l-statement-2',
        }
    );

    my $line_out = qr /
        ^main::fact\([^\n]*?:7\):\n
        ^7:\s+my\ \$n\ =\ shift;\n
    /msx;

    $wrapper->contents_like(
        qr/
            $line_out
            $line_out
        /msx,
        'Test the "." command',
    );
}

# Testing that the f command works.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'f ../lib/perl5db/t/MyModule.pm',
                'b 12',
                'c',
                q/do { use IO::Handle; STDOUT->autoflush(1); print "Var=$var\n"; }/,
                'c',
                'q',
            ],
            include_t => 1,
            prog => '../lib/perl5db/t/filename-line-breakpoint'
        }
    );

    $wrapper->output_like(qr/
        ^Var=Bar$
            .*
        ^In\ MyModule\.$
            .*
        ^In\ Main\ File\.$
            .*
        /msx,
        "f command is working.",
    );
}

# We broke the /pattern/ command because apparently the CORE::eval-s inside
# lib/perl5db.pl cannot handle lexical variable properly. So we now fix this
# bug.
#
# TODO :
#
# 1. Go over the rest of the "eval"s in lib/perl5db.t and see if they cause
# problems.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                '/for/',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr/12: \s* for\ my\ \$q\ \(1\ \.\.\ 10\)\ \{/msx,
        "/pat/ command is working and found a match.",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 22',
                'c',
                '?for?',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr/12: \s* for\ my\ \$q\ \(1\ \.\.\ 10\)\ \{/msx,
        "?pat? command is working and found a match.",
    );
}

# Test the L command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 6',
                'b 13 ($q == 5)',
                'L',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr#
        ^\S*?eval-line-bug:\n
        \s*6:\s*my\ \$i\ =\ 5;\n
        \s*break\ if\ \(1\)\n
        \s*13:\s*\$i\ \+=\ \$q;\n
        \s*break\ if\ \(\(\$q\ ==\ 5\)\)\n
        #msx,
        "L command is listing breakpoints",
    );
}

# Test the L command for watch expressions.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'w (5+6)',
                'L',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr#
        ^Watch-expressions:\n
        \s*\(5\+6\)\n
        #msx,
        "L command is listing watch expressions",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'w (5+6)',
                'w (11*23)',
                'W (5+6)',
                'L',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr#
        ^Watch-expressions:\n
        \s*\(11\*23\)\n
        ^auto\(
        #msx,
        "L command is not listing deleted watch expressions",
    );
}

# Test the L command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'b 6',
                'a 13 print $i',
                'L',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->contents_like(
        qr#
        ^\S*?eval-line-bug:\n
        \s*6:\s*my\ \$i\ =\ 5;\n
        \s*break\ if\ \(1\)\n
        \s*13:\s*\$i\ \+=\ \$q;\n
        \s*action:\s+print\ \$i\n
        #msx,
        "L command is listing actions and breakpoints",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'S',
                'q',
            ],
            prog =>  '../lib/perl5db/t/rt-104168',
        }
    );

    $wrapper->contents_like(
        qr#
        ^main::bar\n
        main::baz\n
        main::foo\n
        #msx,
        "S command - 1",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'S ^main::ba',
                'q',
            ],
            prog =>  '../lib/perl5db/t/rt-104168',
        }
    );

    $wrapper->contents_like(
        qr#
        ^main::bar\n
        main::baz\n
        auto\(
        #msx,
        "S command with regex",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'S !^main::ba',
                'q',
            ],
            prog =>  '../lib/perl5db/t/rt-104168',
        }
    );

    $wrapper->contents_unlike(
        qr#
        ^main::ba
        #msx,
        "S command with negative regex",
    );

    $wrapper->contents_like(
        qr#
        ^main::foo\n
        #msx,
        "S command with negative regex - what it still matches",
    );
}

# Test the a command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'a 13 print "\nVar<Q>=$q\n"',
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->output_like(qr#
        \nVar<Q>=1\n
        \nVar<Q>=2\n
        \nVar<Q>=3\n
        #msx,
        "a command is working",
    );
}

# Test the 'A' command
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'a 13 print "\nVar<Q>=$q\n"',
                'A 13',
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->output_like(
        qr#\A\z#msx, # The empty string.
        "A command (for removing actions) is working",
    );
}

# Test the 'A *' command
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'a 6 print "\nFail!\n"',
                'a 13 print "\nVar<Q>=$q\n"',
                'A *',
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/eval-line-bug',
        }
    );

    $wrapper->output_like(
        qr#\A\z#msx, # The empty string.
        "'A *' command (for removing all actions) is working",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n',
                'w $foo',
                'c',
                'print "\nIDX=<$idx>\n"',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );


    $wrapper->contents_like(qr#
        \$foo\ changed:\n
        \s+old\ value:\s+'1'\n
        \s+new\ value:\s+'2'\n
        #msx,
        'w command - watchpoint changed',
    );
    $wrapper->output_like(qr#
        \nIDX=<20>\n
        #msx,
        "w command - correct output from IDX",
    );
}

{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n',
                'w $foo',
                'W $foo',
                'c',
                'print "\nIDX=<$idx>\n"',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );

    $wrapper->contents_unlike(qr#
        \$foo\ changed:
        #msx,
        'W command - watchpoint was deleted',
    );

    $wrapper->output_like(qr#
        \nIDX=<>\n
        #msx,
        "W command - stopped at end.",
    );
}

# Test the W * command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'n',
                'w $foo',
                'w ($foo*$foo)',
                'W *',
                'c',
                'print "\nIDX=<$idx>\n"',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );

    $wrapper->contents_unlike(qr#
        \$foo\ changed:
        #msx,
        '"W *" command - watchpoint was deleted',
    );

    $wrapper->output_like(qr#
        \nIDX=<>\n
        #msx,
        '"W *" command - stopped at end.',
    );
}

# Test the 'o' command (without further arguments).
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'o',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );

    $wrapper->contents_like(qr#
        ^\s*warnLevel\ =\ '1'\n
        #msx,
        q#"o" command (without arguments) displays warnLevel#,
    );

    $wrapper->contents_like(qr#
        ^\s*signalLevel\ =\ '1'\n
        #msx,
        q#"o" command (without arguments) displays signalLevel#,
    );

    $wrapper->contents_like(qr#
        ^\s*dieLevel\ =\ '1'\n
        #msx,
        q#"o" command (without arguments) displays dieLevel#,
    );

    $wrapper->contents_like(qr#
        ^\s*hashDepth\ =\ 'N/A'\n
        #msx,
        q#"o" command (without arguments) displays hashDepth#,
    );
}

# Test the 'o' query command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'o hashDepth? signalLevel?',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );

    $wrapper->contents_unlike(qr#warnLevel#,
        q#"o" query command does not display warnLevel#,
    );

    $wrapper->contents_like(qr#
        ^\s*signalLevel\ =\ '1'\n
        #msx,
        q#"o" query command displays signalLevel#,
    );

    $wrapper->contents_unlike(qr#dieLevel#,
        q#"o" query command does not display dieLevel#,
    );

    $wrapper->contents_like(qr#
        ^\s*hashDepth\ =\ 'N/A'\n
        #msx,
        q#"o" query command displays hashDepth#,
    );
}

# Test the 'o' set command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                'o signalLevel=0',
                'o',
                'q',
            ],
            prog => '../lib/perl5db/t/test-w-statement-1',
        }
    );

    $wrapper->contents_like(qr/
        ^\s*(signalLevel\ =\ '0'\n)
        .*?
        ^\s*\1
        /msx,
        q#o set command works#,
    );

    $wrapper->contents_like(qr#
        ^\s*hashDepth\ =\ 'N/A'\n
        #msx,
        q#o set command - hashDepth#,
    );
}

# Test the '<' and "< ?" commands.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                q/< print "\nX=<$x>\n"/,
                q/b 7/,
                q/< ?/,
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->contents_like(qr/
        ^pre-perl\ commands:\n
        \s*<\ --\ print\ "\\nX=<\$x>\\n"\n
        /msx,
        q#Test < and < ? commands - contents.#,
    );

    $wrapper->output_like(qr#
        ^X=<FirstVal>\n
        #msx,
        q#Test < and < ? commands - output.#,
    );
}

# Test the '< *' command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                q/< print "\nX=<$x>\n"/,
                q/b 7/,
                q/< */,
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->output_unlike(qr/FirstVal/,
        q#Test the '< *' command.#,
    );
}

# Test the '>' and "> ?" commands.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                q/$::foo = 500;/,
                q/> print "\nFOO=<$::foo>\n"/,
                q/b 7/,
                q/> ?/,
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->contents_like(qr/
        ^post-perl\ commands:\n
        \s*>\ --\ print\ "\\nFOO=<\$::foo>\\n"\n
        /msx,
        q#Test > and > ? commands - contents.#,
    );

    $wrapper->output_like(qr#
        ^FOO=<500>\n
        #msx,
        q#Test > and > ? commands - output.#,
    );
}

# Test the '> *' command.
{
    my $wrapper = DebugWrap->new(
        {
            cmds =>
            [
                q/> print "\nFOO=<$::foo>\n"/,
                q/b 7/,
                q/> */,
                'c',
                'q',
            ],
            prog => '../lib/perl5db/t/disable-breakpoints-1',
        }
    );

    $wrapper->output_unlike(qr/FOO=/,
        q#Test the '> *' command.#,
    );
}

END {
    1 while unlink ($rc_filename, $out_fn);
}
