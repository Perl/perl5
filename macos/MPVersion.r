/*
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MPVersion.r,v $
 * Revision 1.8  2001/10/03 19:31:55  pudge
 * Sync with perforce maint-5.6/macperl
 *
 * Revision 1.7  2001/09/26 21:50:13  pudge
 * Sync with perforce maint-5.6/macperl
 *
 * Revision 1.6  2001/09/02 00:38:40  pudge
 * Sync with perforce
 *
 * Revision 1.5  2001/07/20 23:54:49  pudge
 * Sync with perforce changes 11420,11424.
 *
 * Revision 1.4  2001/07/08 05:07:14  pudge
 * Version update 5.6.1a3
 *
 * Revision 1.3  2001/05/05 20:32:41  pudge
 * Prepare for 5.6.1a2, mostly updates to tests, and File::Find, and latest changes from main repository
 *
 * Revision 1.2  2001/04/25 04:32:42  pudge
 * Update modules versions
 *
 * Revision 1.1  2001/04/17 03:59:23  pudge
 * Minor version/config changes, plus sync with maint-5.6/perl
 *
 *
 */

#define MPVersionStr	"5.6.1b1"
#define MPDate		$$Format("%4.4d-%2.2d-%2.2d", $$Year,  $$Month, $$Day)
#define MPRevision	0x05
#define MPVersion	0x61
#define MPBuild		0x01
#define MPState		beta
#define MPCopyright	"ported by Matthias Neeracher, maintained by Chris Nandor"

resource 'vers' (1) {
	MPRevision, MPVersion, MPState, MPBuild, verUS,
	MPVersionStr,
	MPVersionStr ", " MPCopyright
	};

resource 'vers' (2) {
	0x01, 0x00, release, 0x00, verUS,
	"1.0",
	"MacPerl " MPVersionStr " (" MPDate ")"
	};
