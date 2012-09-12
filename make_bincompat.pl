#!perl

use strict;
use warnings;
use Config 'bincompat_options';

my $opts = join q{ } => bincompat_options;

print <<"EOH";
#ifndef __BINCOMPAT_H__
#define __BINCOMPAT_H__

#define PERL_BINCOMPAT_OPTIONS "$opts"

#endif
EOH
