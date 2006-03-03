
use lib 't';
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

    plan tests => 190 + $extra ;

    use_ok('IO::Uncompress::AnyUncompress', qw($AnyUncompressError)) ;

}

sub run
{

    my $CompressClass   = identify();
    my $UncompressClass = getInverse($CompressClass);
    my $Error           = getErrorRef($CompressClass);
    my $UnError         = getErrorRef($UncompressClass);




    my @buffers ;
    push @buffers, <<EOM ;
hello world
this is a test
some more stuff on this line
ad finally...
EOM

    push @buffers, <<EOM ;
some more stuff
EOM

    push @buffers, <<EOM ;
even more stuff
EOM

    {
        my $cc ;
        my $gz ;
        my $hsize ;
        my %headers = () ;
        

        foreach my $fb ( qw( file filehandle buffer ) )
        {

            foreach my $i (1 .. @buffers) {

                title "Testing $CompressClass with $i streams to $fb";

                my @buffs = @buffers[0..$i -1] ;

                if ($CompressClass eq 'IO::Compress::Gzip') {
                    %headers = (
                                  Strict     => 1,
                                  Comment    => "this is a comment",
                                  ExtraField => ["so" => "me extra"],
                                  HeaderCRC  => 1); 

                }

                my $lex = new LexFile my $name ;
                my $output ;
                if ($fb eq 'buffer')
                {
                    my $compressed = '';
                    $output = \$compressed;
                }
                elsif ($fb eq 'filehandle')
                {
                    $output = new IO::File ">$name" ;
                }
                else
                {
                    $output = $name ;
                }

                my $x = new $CompressClass($output, AutoClose => 1, %headers);
                isa_ok $x, $CompressClass, '  $x' ;

                foreach my $buffer (@buffs) {
                    ok $x->write($buffer), "    Write OK" ;
                    # this will add an extra "empty" stream
                    ok $x->newStream(), "    newStream OK" ;
                }
                ok $x->close, "  Close ok" ;

                #hexDump($compressed) ;

                foreach my $unc ($UncompressClass, 'IO::Uncompress::AnyUncompress') {
                    title "  Testing $CompressClass with $unc and $i streams, from $fb";
                    $cc = $output ;
                    if ($fb eq 'filehandle')
                    {
                        $cc = new IO::File "<$name" ;
                    }
                    my $gz = new $unc($cc,
                                   Strict      => 1,
                                   AutoClose   => 1,
                                   Append      => 1,
                                   MultiStream => 1,
                                   Transparent => 0)
                        or diag $$UnError;
                    isa_ok $gz, $UncompressClass, '    $gz' ;

                    my $un = '';
                    1 while $gz->read($un) > 0 ;
                    #print "[[$un]]\n" while $gz->read($un) > 0 ;
                    ok ! $gz->error(), "      ! error()"
                        or diag "Error is " . $gz->error() ;
                    ok $gz->eof(), "      eof()";
                    ok $gz->close(), "    close() ok"
                        or diag "errno $!\n" ;

                    is $gz->streamCount(), $i +1, "    streamCount ok"
                        or diag "Stream count is " . $gz->streamCount();
                    ok $un eq join('', @buffs), "    expected output" ;

                }
            }
        }
    }
}


# corrupt one of the streams - all previous should be ok
# trailing stuff
# need a way to skip to the start of the next stream.
# check that "tell" works ok

1;
