#ifndef __PATCHLEVEL_H_INCLUDED__

/* do not adjust the whitespace! Configure expects the numbers to be
 * exactly on the third column */

#define PERL_REVISION	5		/* age */
#define PERL_VERSION	5		/* epoch */
#define PERL_SUBVERSION	63		/* generation */

/* Compatibility across versions:  MakeMaker will install add-on
   modules in a directory with the PERL_APIVERSION version number.  
   Normally this should not change across maintenance releases.
   perl.c:incpush() and lib/lib.pm will automatically search older 
   directories across major versions back to to PERL_XS_APIVERSION
   for XS modules and back to PERL_PM_APIVERSION for pure PERL modules.
   (Since the versioned directory layout didn't start until 5.005,
   that's the earliest these can go back.

   See INSTALL for how this works.
*/
#define PERL_APIVERSION 5.00563		/* Adjust manually as needed.  */

#define __PATCHLEVEL_H_INCLUDED__
#endif

/*
	local_patches -- list of locally applied less-than-subversion patches.
	If you're distributing such a patch, please give it a name and a
	one-line description, placed just before the last NULL in the array
	below.  If your patch fixes a bug in the perlbug database, please
	mention the bugid.  If your patch *IS* dependent on a prior patch,
	please place your applied patch line after its dependencies. This
	will help tracking of patch dependencies.

	Please edit the hunk of diff which adds your patch to this list,
	to remove context lines which would give patch problems.  For instance,
	if the original context diff is
	   *** patchlevel.h.orig	<date here>
	   --- patchlevel.h	<date here>
	   *** 38,43 ***
	   --- 38,44 ---
	     	,"FOO1235 - some patch"
	     	,"BAR3141 - another patch"
	     	,"BAZ2718 - and another patch"
	   + 	,"MINE001 - my new patch"
	     	,NULL
	     };
	
	please change it to 
	   *** patchlevel.h.orig	<date here>
	   --- patchlevel.h	<date here>
	   *** 41,43 ***
	   --- 41,44 ---
	   + 	,"MINE001 - my new patch"
	     };
	
	(Note changes to line numbers as well as removal of context lines.)
	This will prevent patch from choking if someone has previously
	applied different patches than you.
 */
#if !defined(PERL_PATCHLEVEL_H_IMPLICIT) && !defined(LOCAL_PATCH_COUNT)
static	char	*local_patches[] = {
	NULL
	,NULL
};

/* Initial space prevents this variable from being inserted in config.sh  */
#  define	LOCAL_PATCH_COUNT	\
	(sizeof(local_patches)/sizeof(local_patches[0])-2)

/* the old terms of reference, add them only when explicitly included */
#define PATCHLEVEL		PERL_VERSION
#undef  SUBVERSION		/* OS/390 has a SUBVERSION in a system header */
#define SUBVERSION		PERL_SUBVERSION
#endif
