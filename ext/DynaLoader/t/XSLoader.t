#!/usr/bin/perl -w

BEGIN {
    chdir 't';
#    @INC = '../lib';
}

use Test;
plan tests => 4;

use XSLoader;
ok(1);
ok( ref XSLoader->can('load') );

eval { XSLoader::load(); };
ok( $@ =~ /^XSLoader::load\('Your::Module', \$Your::Module::VERSION\)/ );

package SDBM_File;
XSLoader::load('SDBM_File');
::ok( ref SDBM_File->can('TIEHASH') );
