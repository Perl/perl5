# $Id: Makefile.PL,v 1.0.1.1 2001/01/03 09:38:39 ram Exp $
#
#  Copyright (c) 1995-2000, Raphael Manfredi
#  
#  You may redistribute only under the same terms as Perl 5, as specified
#  in the README file that comes with the distribution.
#
# $Log: Makefile.PL,v $
# Revision 1.0.1.1  2001/01/03 09:38:39  ram
# patch7: removed spurious 'clean' entry
#
# Revision 1.0  2000/09/01 19:40:41  ram
# Baseline for first official release.
#

use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME'			=> 'Storable',
    'DISTNAME'		=> "Storable",
	'MAN3PODS'		=> {},
    'VERSION_FROM'	=> 'Storable.pm',
    'dist'			=> { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
);

