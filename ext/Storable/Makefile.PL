# $Id: Makefile.PL,v 0.7 2000/08/03 22:04:44 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# $Log: Makefile.PL,v $
# Revision 0.7  2000/08/03 22:04:44  ram
# Baseline for second beta release.
#

use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME'			=> 'Storable',
    'DISTNAME'		=> "Storable",
    'VERSION_FROM'	=> 'Storable.pm',
    'dist'			=> { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
    'clean'			=> {'FILES' => '*%'},
);

