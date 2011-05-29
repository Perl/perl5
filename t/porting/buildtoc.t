#!./perl

BEGIN {
    chdir '..' unless -d 't';
    unshift @INC, 'lib';
}

use strict;
require 't/test.pl';

my $result = runperl(switches => ['-f', '-Ilib'], 
                     progfile => 'pod/buildtoc', 
                     args     => ['--build-toc', '-q', '--test', '--build-all']);

print $result;
