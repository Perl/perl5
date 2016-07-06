# tests for heredocs besides what is tested in base/lex.t

BEGIN {
   chdir 't' if -d 't';
   @INC = '../lib';
   require './test.pl';
}

use strict;
plan(tests => 50);


# heredoc without newline (#65838)
{
    my $string = <<'HEREDOC';
testing for 65838
HEREDOC

    my $code = "<<'HEREDOC';\n${string}HEREDOC";  # HD w/o newline, in eval-string
    my $hd = eval $code or warn "$@ ---";
    is($hd, $string, "no terminating newline in string-eval");
}


# here-doc edge cases
{
    my $string = "testing for 65838";

    fresh_perl_is(
        "print <<'HEREDOC';\n${string}\nHEREDOC",
        $string,
        {},
        "heredoc at EOF without trailing newline"
    );

    fresh_perl_is(
        "print <<;\n$string\n",
        $string,
        { switches => ['-X'] },
        "blank-terminated heredoc at EOF"
    );
    fresh_perl_is(
        "print <<\n$string\n",
        $string,
        { switches => ['-X'] },
        "blank-terminated heredoc at EOF and no semicolon"
    );
    fresh_perl_is(
        "print <<foo\r\nick and queasy\r\nfoo\r\n",
        'ick and queasy',
        { switches => ['-X'] },
        "crlf-terminated heredoc"
    );
    fresh_perl_is(
        "print qq|\${\\<<foo}|\nick and queasy\nfoo\n",
        'ick and queasy',
        { switches => ['-w'], stderr => 1 },
        'no warning for qq|${\<<foo}| in file'
    );
}


# here-doc parse failures
{
    fresh_perl_like(
        "print <<HEREDOC;\nwibble\n HEREDOC",
        qr/find string terminator/,
        {},
        "string terminator must start at newline"
    );

    # Loop over various lengths to try to force at least one to cause a
    # reallocation in S_scan_heredoc()
    # Timing on a modern machine suggests that this loop executes in less than
    # 0.1s, so it's a very small cost for the default build. The benefit is
    # that building with ASAN will reveal the bug and any related regressions.
    for (1..31) {
        fresh_perl_like(
            "print <<;\n" . "x" x $_,
            qr/find string terminator/,
            { switches => ['-X'] },
            "empty string terminator still needs a newline (length $_)"
        );
    }

    fresh_perl_like(
        "print <<ThisTerminatorIsLongerThanTheData;\nno more newlines",
        qr/find string terminator/,
        {},
        "long terminator fails correctly"
    );

    # this would read freed memory
    fresh_perl_like(
        qq(0<<<<""0\n\n),
        # valgrind and asan reports an error between these two lines
        qr/^Number found where operator expected at - line 1, near "<<""0"\s+\(Missing operator/,
        {},
        "don't use an invalid oldoldbufptr"
    );

    # [perl #125540] this asserted or crashed
    fresh_perl_like(
	q(map d$#<<<<),
	qr/Can't find string terminator "" anywhere before EOF at - line 1\./,
	{},
	"Don't assert parsing a here-doc if we hit EOF early"
    );
}

# indented heredocs
{
    my $string = 'some data';

    fresh_perl_is(
        "print <<~HEREDOC;\n  ${string}\nHEREDOC\n",
        "  $string",
        { switches => ['-w'], stderr => 1 },
        "indented heredoc with no actual indentation"
    );

    fresh_perl_is(
        "print <<~HEREDOC;\n  ${string}\n  HEREDOC\n",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented heredoc"
    );

    fresh_perl_is(
        "print <<~'HEREDOC';\n  ${string}\n  HEREDOC\n",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented 'heredoc'"
    );

    fresh_perl_is(
        "print <<~\"HEREDOC\";\n  ${string}\n  HEREDOC\n",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented \"heredoc\""
    );

    fresh_perl_is(
        "print <<~\\HEREDOC;\n  ${string}\n  HEREDOC\n",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented \\heredoc"
    );

    fresh_perl_is(
        "print <<~HEREDOC;\n\t \t${string}\n\t \tHEREDOC\n",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented heredoc with tabs and spaces"
    );

    fresh_perl_is(
        "print <<~HEREDOC;\n\t \t${string}\n\t \tHEREDOC",
        $string,
        { switches => ['-w'], stderr => 1 },
        "indented heredoc at EOF"
    );

    fresh_perl_is(
        "print <<~HEREDOC;\n\t \t${string}\n\t \tTHEREDOC",
        "Can't find string terminator \"HEREDOC\" anywhere before EOF at - line 1.",
        { switches => ['-w'], stderr => 1 },
	"indented heredoc missing terminator error is correct"
    );

    fresh_perl_is(
        "print <<~HEREDOC;\n ${string}\n$string\n   $string\n $string\n   HEREDOC",
        "Indentation on line 1 of heredoc doesn't match delimiter at - line 1.\n" .
        "Indentation on line 2 of heredoc doesn't match delimiter at - line 1.\n" .
        "Indentation on line 4 of heredoc doesn\'t match delimiter at - line 1.\n" .
        " some data\nsome data\nsome data\n some data",
        { switches => ['-w'], stderr => 1 },
        "indented heredoc with bad indentation"
    );
}
