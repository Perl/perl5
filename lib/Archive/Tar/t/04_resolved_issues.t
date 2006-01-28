BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/Archive/Tar' if -d '../lib/Archive/Tar';
    }       
    use lib '../../..';
}

BEGIN { chdir 't' if -d 't' }

use Test::More 'no_plan';
use strict;
use lib '../lib';

my $NO_UNLINK   = @ARGV ? 1 : 0;

my $Class       = 'Archive::Tar';

use_ok( $Class );

### bug #13636
### tests for @longlink behaviour on files that have a / at the end
### of their shortened path, making them appear to be directories
{   ### dont use the prefix, otherwise A::T will not use @longlink
    ### encoding style
    local $Archive::Tar::DO_NOT_USE_PREFIX = 1;
    local $Archive::Tar::DO_NOT_USE_PREFIX = 1;
    
    my $dir =   'Catalyst-Helper-Controller-Scaffold-HTML-Template-0_03/' . 
                'lib/Catalyst/Helper/Controller/Scaffold/HTML/';
    my $file =  'Template.pm';
    my $out =   $$ . '.tar';
    
    ### first create the file
    {   my $tar = $Class->new;
        
        isa_ok( $tar,           $Class );
        ok( $tar->add_data( $dir.$file => $$ ),
                                "   Added long file" );
        
        ok( $tar->write($out),  "   File written to $out" );
    }
    
    ### then read it back in
    {   my $tar = $Class->new;
        isa_ok( $tar,           $Class );
        ok( $tar->read( $out ), "   Read in $out again" );
        
        my @files = $tar->get_files;
        is( scalar(@files), 1,  "   Only 1 entry found" );
        
        my $entry = shift @files;
        ok( $entry->is_file,    "   Entry is a file" );
        is( $entry->name, $dir.$file,
                                "   With the proper name" );
    }                                
    
    ### remove the file
    unless( $NO_UNLINK ) { 1 while unlink $out }
}    

### bug #14922
### There's a bug in Archive::Tar that causes a file like: foo/foo.txt 
### to be stored in the tar file as: foo/.txt
### XXX could not be reproduced in 1.26 -- leave test to be sure
{   my $dir     = $$ . '/';
    my $file    = $$ . '.txt';
    my $out     = $$ . '.tar';
    
    ### first create the file
    {   my $tar = $Class->new;
        
        isa_ok( $tar,           $Class );
        ok( $tar->add_data( $dir.$file => $$ ),
                                "   Added long file" );
        
        ok( $tar->write($out),  "   File written to $out" );
    }

    ### then read it back in
    {   my $tar = $Class->new;
        isa_ok( $tar,           $Class );
        ok( $tar->read( $out ), "   Read in $out again" );
        
        my @files = $tar->get_files;
        is( scalar(@files), 1,  "   Only 1 entry found" );
        
        my $entry = shift @files;
        ok( $entry->is_file,    "   Entry is a file" );
        is( $entry->full_path, $dir.$file,
                                "   With the proper name" );
    }                                
    
    ### remove the file
    unless( $NO_UNLINK ) { 1 while unlink $out }
}    
    
    
    
    
