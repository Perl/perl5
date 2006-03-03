BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;
use bytes;

use Test::More ; 
use CompTestUtils;

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 29 + $extra ;


    use_ok('IO::Compress::Base::Common');

    #use_ok('Compress::Zlib::ParseParameters');

}


# Compress::Zlib::Common;

sub My::testParseParameters()
{
    eval { ParseParameters(1, {}, 1) ; };
    like $@, mkErr(': Expected even number of parameters, got 1'), 
            "Trap odd number of params";

    eval { ParseParameters(1, {}, undef) ; };
    like $@, mkErr(': Expected even number of parameters, got 1'), 
            "Trap odd number of params";

    eval { ParseParameters(1, {}, []) ; };
    like $@, mkErr(': Expected even number of parameters, got 1'), 
            "Trap odd number of params";

    eval { ParseParameters(1, {'Fred' => [1, 1, Parse_boolean, 0]}, Fred => 'joe') ; };
    like $@, mkErr("Parameter 'Fred' must be an int, got 'joe'"), 
            "wanted unsigned, got undef";

    eval { ParseParameters(1, {'Fred' => [1, 1, Parse_unsigned, 0]}, Fred => undef) ; };
    like $@, mkErr("Parameter 'Fred' must be an unsigned int, got 'undef'"), 
            "wanted unsigned, got undef";

    eval { ParseParameters(1, {'Fred' => [1, 1, Parse_signed, 0]}, Fred => undef) ; };
    like $@, mkErr("Parameter 'Fred' must be a signed int, got 'undef'"), 
            "wanted signed, got undef";

    eval { ParseParameters(1, {'Fred' => [1, 1, Parse_signed, 0]}, Fred => 'abc') ; };
    like $@, mkErr("Parameter 'Fred' must be a signed int, got 'abc'"), 
            "wanted signed, got 'abc'";

    my $got = ParseParameters(1, {'Fred' => [1, 1, Parse_store_ref, 0]}, Fred => 'abc') ;
    is ${ $got->value('Fred') }, "abc", "Parse_store_ref" ;

    $got = ParseParameters(1, {'Fred' => [1, 1, 0x1000000, 0]}, Fred => 'abc') ;
    is $got->value('Fred'), "abc", "other" ;

}

My::testParseParameters();


{
    title "isaFilename" ;
    ok   isaFilename("abc"), "'abc' isaFilename";

    ok ! isaFilename(undef), "undef ! isaFilename";
    ok ! isaFilename([]),    "[] ! isaFilename";
    $main::X = 1; $main::X = $main::X ;
    ok ! isaFilename(*X),    "glob ! isaFilename";
}

{
    title "whatIsInput" ;

    my $lex = new LexFile my $out_file ;
    open FH, ">$out_file" ;
    is whatIsInput(*FH), 'handle', "Match filehandle" ;
    close FH ;

    my $stdin = '-';
    is whatIsInput($stdin),       'handle',   "Match '-' as stdin";
    #is $stdin,                    \*STDIN,    "'-' changed to *STDIN";
    #isa_ok $stdin,                'IO::File',    "'-' changed to IO::File";
    is whatIsInput("abc"),        'filename', "Match filename";
    is whatIsInput(\"abc"),       'buffer',   "Match buffer";
    is whatIsInput(sub { 1 }, 1), 'code',     "Match code";
    is whatIsInput(sub { 1 }),    ''   ,      "Don't match code";

}

{
    title "whatIsOutput" ;

    my $lex = new LexFile my $out_file ;
    open FH, ">$out_file" ;
    is whatIsOutput(*FH), 'handle', "Match filehandle" ;
    close FH ;

    my $stdout = '-';
    is whatIsOutput($stdout),     'handle',   "Match '-' as stdout";
    #is $stdout,                   \*STDOUT,   "'-' changed to *STDOUT";
    #isa_ok $stdout,               'IO::File',    "'-' changed to IO::File";
    is whatIsOutput("abc"),        'filename', "Match filename";
    is whatIsOutput(\"abc"),       'buffer',   "Match buffer";
    is whatIsOutput(sub { 1 }, 1), 'code',     "Match code";
    is whatIsOutput(sub { 1 }),    ''   ,      "Don't match code";

}
