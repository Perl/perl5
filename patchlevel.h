#ifndef __PATCHLEVEL_H_INCLUDED__

/* do not adjust the whitespace! Configure expects the numbers to be
 * exactly on the third column */

#define PERL_REVISION	5		/* age */
#define PERL_VERSION	5		/* epoch */
#define PERL_SUBVERSION	60		/* generation */

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
static	char	*local_patches[] = {
	NULL
	,NULL
};

/* Initial space prevents this variable from being inserted in config.sh  */
#  define	LOCAL_PATCH_COUNT	\
	(sizeof(local_patches)/sizeof(local_patches[0])-2)

#  define __PATCHLEVEL_H_INCLUDED__
#endif

/* the old terms of reference, add them only when explicitly included */
#if !defined(PERL_PATCHLEVEL_H_IMPLICIT) && !defined(PATCHLEVEL)
#define PATCHLEVEL		PERL_VERSION
#undef  SUBVERSION		/* OS/390 has a SUBVERSION in a system header */
#define SUBVERSION		PERL_SUBVERSION
#endif

