/*********************************************************************
Project	:	MacPerl		-	Real Perl Application
File		:	MPRsrc.h		-	Resources
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPRsrc.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.4  1998/04/14 19:46:44  neeri
MacPerl 5.2.0r4b2

Revision 1.3  1997/11/18 00:53:56  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:05  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:57  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:53:49  neeri
Inline Input.

Revision 1.1  1994/02/27  23:04:07  neeri
Initial revision

Revision 0.3  1993/11/07  00:00:00  neeri
Further work on preference dialog

Revision 0.2  1993/08/27  00:00:00  neeri
Format

Revision 0.1  1993/08/17  00:00:00  neeri
Protect against multiple inclusion

*********************************************************************/

#ifndef __MPRSRC__
#define __MPRSRC__

#define  MPAppSig 'McPL'
#define	MPRtSig	'MrPL'

/* Window templates */

#define	WindowTemplates   128

/* Dialogs & Alerts */

#define  ErrorAlert   		256
#define  SaveAlert   		257

#define	AboutDialog			258

#define	ad_PatchLevel		1
#define	ad_Credits			2
#define	ad_Version			3

#define	RevertAlert			262
#define	HelperAlert			263
#define	AbortAlert			266
#define	NoPerlAlert			270
#define	ElvisAlert			274
#define	ElvisEditAlert		275

#define	FormatDialog		320

#define	fd_OK					1
#define	fd_Cancel			2
#define	fd_FontList			3
#define	fd_SizeList			4
#define	fd_Separator		5
#define	fd_Outline			6
#define	fd_SizeEdit			7
#define	fd_MakeDefault		8

#define 	FindDialog			352

#define	fi_OK					1
#define	fi_Cancel			2
#define	fi_Subject			3

#define	PrefDialog			384

#define	pd_LibIcon			1
#define	pd_EnvIcon			2
#define	pd_ScriptIcon		3
#define	pd_InputIcon		4
#define	pd_ConfigIcon		5
#define	pd_Boundary			6
#define	pd_Done				8
#define	pd_Outline			9

#define	pd_LibStr			1
#define	pd_EnvStr			1
#define	pd_ScriptStr		3
#define	pd_InputStr			4
#define	pd_ChangePath		5
#define	pd_AddPath			6

#define	PrefLibID			385

#define	pld_List 			pd_Outline+1
#define	pld_Remove			pd_Outline+2
#define	pld_Add				pd_Outline+3
#define pld_Defaults		pd_Outline+4

#define	PrefLibDelID		3850

#define	PrefEnvID			386

#define	ped_List 			pd_Outline+1
#define	ped_Remove			pd_Outline+2
#define	ped_Add				pd_Outline+3

#define	PrefEnvDelID		3860

#define	PrefEnvAddID		3861

#define	pead_OK				1
#define  pead_Cancel			2
#define  pead_File   		3
#define  pead_Folder  		4
#define  pead_Name			5
#define  pead_Value			6

#define	PrefScriptID		387

#define	psd_Edit				pd_Outline+1
#define	psd_Run				pd_Outline+2
#define	psd_Check			pd_Outline+3

#define	PrefInputID			388

#define	pid_Inline			pd_Outline+1

#define	PrefConfigID		389

#define	pcd_Launch			pd_Outline+1

#define	SaveScriptDialog	192
#define 	ssd_Type				13
#define	ssd_Predef			2
/* 
	Small Icons
*/

#define 	ConsoleSICNID	256
#define 	DocumentSICNID	257
#define 	EnabledSICNID	264
#define 	ReadOnlySICNID	265
#define 	BlockedSICNID	266

/* 
	Credits font and strings
*/

#define CreditID	32268

/* 
	Sounds
*/

#define AlertSoundID	128

/*
	Menu Resources
*/

#define  appleID	128
#define  fileID	129
#define  editID	130
#define	windowID	131
#define 	perlID	132
#define  editorID	133
#define  helpID	134

#define  kLastID	helpID

#define	kHierHelpMenu	200

#endif