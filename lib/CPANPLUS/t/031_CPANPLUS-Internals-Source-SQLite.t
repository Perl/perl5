### make sure we can find our conf.pl file
BEGIN { 
    use FindBin; 
    require "$FindBin::Bin/inc/conf.pl";
}

use strict;

use Module::Load;
use Test::More eval { load 'CPANPLUS::Internals::Source::SQLite'; 1 }
            ? 'no_plan'
            : (skip_all => "SQLite engine not available");

use Data::Dumper;
use File::Basename qw[dirname];
use CPANPLUS::Error;
use CPANPLUS::Backend;
use CPANPLUS::Internals::Constants;

my $conf = gimme_conf();

### make sure we use the SQLite engine
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::SQLite' );

my $cb   = CPANPLUS::Backend->new( $conf );
my $mod  = TEST_CONF_MODULE;
my $auth = TEST_CONF_AUTHOR;

ok( $cb->reload_indices( update_source => 1 ),                 
                                "Building trees" );
ok( $cb->__sqlite_dbh,          "   Got a DBH " );
ok( $cb->__sqlite_file,         "   Got a DB file" );


### make sure we have trees and they're hashes
{   ok( $cb->author_tree,       "Got author tree" );
    isa_ok( $cb->author_tree,   "HASH" );

    ok( $cb->module_tree,       "Got module tree" );
    isa_ok( $cb->module_tree,   "HASH" );
}

### save state, shouldn't work
{   CPANPLUS::Error->flush;
    my $rv = $cb->save_state;
    
    ok( !$rv,                   "Saving state not implemented" );
    like( CPANPLUS::Error->stack_as_string, qr/not implemented/i,
                                "   Diagnostics confirmed" );
}

### test look ups
{   my %map = (
        $auth   => 'author_tree',
        $mod    => 'module_tree',
    );
    
    while( my($str, $meth) = each %map ) {
    
        ok( $str,               "Trying to retrieve $str" );
        ok( $cb->$meth( $str ), "   Got $str object via ->$meth" );
        ok( $cb->$meth->{$str}, "   Got author object via ->{ $str }" );
        ok( exists $cb->$meth->{ $str },
                                "       Testing exists() " );   
        ok( not(exists( $cb->$meth->{ $$ } )),
                                "           And non-exists() " );
        cmp_ok( scalar(keys(%{ $cb->$meth })), ">", 1,
                                "   Got keys()" );
                                
        cmp_ok( scalar(keys(%{ $cb->$meth })), '==', scalar(keys(%{ $cb->$meth })),
                                "   Keys == Values" );

        while( my($key,$val) = each %{ $cb->$meth } ) {
            ok( $key,           "   Retrieved $key via each()" );
            ok( $val,           "       And value" );
            ok( ref $val,       "           Value is a ref: $val" );
            can_ok( $val,       '_id' );
        }            
    }
}    
