/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MacPerl.r		-	User interface related resources
Authors	:	Matthias Neeracher & Tim Endres

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MacPerl.r,v $
Revision 1.10  2001/10/03 19:23:16  pudge
Sync with perforce maint-5.6/macperl

Revision 1.9  2001/09/26 21:51:15  pudge
Sync with perforce maint-5.6/macperl/macos/macperl

Revision 1.8  2001/09/24 04:31:55  neeri
Include cursors in build (MacPerl Bug #432129)

Revision 1.7  2001/09/02 00:41:01  pudge
Sync with perforce

Revision 1.6  2001/04/17 03:59:58  pudge
Minor version/config changes

Revision 1.5  2001/03/30 21:58:05  pudge
Update for new About box

Revision 1.4  2001/03/22 04:29:04  pudge
Update version

Revision 1.3  2001/02/23 23:33:06  pudge
Update versions

Revision 1.2  2001/01/30 05:16:53  pudge
Update versions

Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.7  1999/01/24 05:14:01  neeri
Various tweaks made in 1998

Revision 1.6  1998/04/21 22:27:02  neeri
MacPerl 5.2.0r4

Revision 1.5  1998/04/14 19:46:44  neeri
MacPerl 5.2.0r4b2

Revision 1.4  1998/04/07 01:46:50  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:54:00  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:58:12  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:11:12  neeri
Checked into CVS

Revision 1.1  1994/03/22  00:08:05  neeri
Initial revision

Revision 0.17  1994/01/16  00:00:00  neeri
4.1.2

Revision 0.16  1994/01/12  00:00:00  neeri
4.1.1

Revision 0.15  1993/12/28  00:00:00  neeri
4.1.1b3

Revision 0.14  1993/12/20  00:00:00  neeri
4.1.1b2

Revision 0.13  1993/12/15  00:00:00  neeri
4.1.1b1

Revision 0.12  1993/10/24  00:00:00  neeri
4.1.0

Revision 0.11  1993/10/18  00:00:00  neeri
b6

Revision 0.10  1993/10/13  00:00:00  neeri
b5

Revision 0.9  1993/10/11  00:00:00  neeri
b4

Revision 0.8  1993/09/19  00:00:00  neeri
Runtime

Revision 0.7  1993/09/08  00:00:00  neeri
b3

Revision 0.6  1993/08/27  00:00:00  neeri
Format…

Revision 0.5  1993/08/17  00:00:00  neeri
Preferences…

Revision 0.4  1993/08/15  00:00:00  neeri
Credits

Revision 0.3  1993/07/13  00:00:00  neeri
Options dialog

Revision 0.2  1993/05/31  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

#define SystemSevenOrLater 1

#include "Types.r"
#include "SysTypes.r"
#include "BalloonTypes.r"
#include "AEUserTermTypes.r"
#include "AERegistry.r"
#include "AEObjects.r"

#include "MPRsrc.h"

include "MercutioMDEF.rsrc";

include ":Obj:FontLDEF.rsrc";

include "MacPerl.rsrc" 'BNDL'(128);
include "MacPerl.rsrc" 'McPL'(0);
include "MacPerl.rsrc" 'ICN#'(128);
include "MacPerl.rsrc" 'icl4'(128);
include "MacPerl.rsrc" 'icl8'(128);
include "MacPerl.rsrc" 'ics#'(128);
include "MacPerl.rsrc" 'ics4'(128);
include "MacPerl.rsrc" 'ics8'(128);
include "MacPerl.rsrc" 'BNDL'(129) 	as 'MrPB'(128);
include "MacPerl.rsrc" 'MrPL'(0);
include "MacPerl.rsrc" 'ICN#'(132) 	as 'MrPI'(128);
include "MacPerl.rsrc" 'icl4'(132) 	as 'MrP4'(128);
include "MacPerl.rsrc" 'icl8'(132) 	as 'MrP8'(128);
include "MacPerl.rsrc" 'ics#'(132) 	as 'MrP#'(128);
include "MacPerl.rsrc" 'ics4'(132) 	as 'MrP3'(128);
include "MacPerl.rsrc" 'ics8'(132) 	as 'MrP7'(128);
include "MacPerl.rsrc" 'ICN#'(134);
include "MacPerl.rsrc" 'icl4'(134);
include "MacPerl.rsrc" 'icl8'(134);
include "MacPerl.rsrc" 'DITL'(258);
include "MacPerl.rsrc" 'DLOG'(258);
include "MacPerl.rsrc" 'DITL'(259);
include "MacPerl.rsrc" 'DLOG'(259);
include "MacPerl.rsrc" 'DITL'(352);
include "MacPerl.rsrc" 'DLOG'(352);
include "MacPerl.rsrc" 'FREF'(128);
include "MacPerl.rsrc" 'FREF'(129);
include "MacPerl.rsrc" 'FREF'(130);
include "MacPerl.rsrc" 'FREF'(131);
include "MacPerl.rsrc" 'FREF'(132);
include "MacPerl.rsrc" 'FREF'(133);
include "MacPerl.rsrc" 'FREF'(134);
include "MacPerl.rsrc" 'FREF'(135);
include "MacPerl.rsrc" 'FREF'(136);
include "MacPerl.rsrc" 'ICN#'(129);
include "MacPerl.rsrc" 'ICN#'(130);
include "MacPerl.rsrc" 'ICN#'(131);
include "MacPerl.rsrc" 'ICN#'(385);
include "MacPerl.rsrc" 'ICN#'(386);
include "MacPerl.rsrc" 'ICN#'(387);
include "MacPerl.rsrc" 'ICN#'(388);
include "MacPerl.rsrc" 'ICN#'(389);
include "MacPerl.rsrc" 'PICT'(128);
include "MacPerl.rsrc" 'PICT'(129);
include "MacPerl.rsrc" 'PICT'(130);
include "MacPerl.rsrc" 'PICT'(131);
include "MacPerl.rsrc" 'snd '(128);
include "MacPerl.rsrc" 'snd '(129);
include "MacPerl.rsrc" 'icl4'(129);
include "MacPerl.rsrc" 'icl4'(130);
include "MacPerl.rsrc" 'icl4'(131);
include "MacPerl.rsrc" 'icl4'(385);
include "MacPerl.rsrc" 'icl4'(386);
include "MacPerl.rsrc" 'icl4'(387);
include "MacPerl.rsrc" 'icl4'(388);
include "MacPerl.rsrc" 'icl4'(389);
include "MacPerl.rsrc" 'icl8'(129);
include "MacPerl.rsrc" 'icl8'(130);
include "MacPerl.rsrc" 'icl8'(131);
include "MacPerl.rsrc" 'icl8'(385);
include "MacPerl.rsrc" 'icl8'(386);
include "MacPerl.rsrc" 'icl8'(387);
include "MacPerl.rsrc" 'icl8'(388);
include "MacPerl.rsrc" 'icl8'(389);
include "MacPerl.rsrc" 'icm#'(256);
include "MacPerl.rsrc" 'icm#'(257);
include "MacPerl.rsrc" 'icm#'(264);
include "MacPerl.rsrc" 'icm#'(265);
include "MacPerl.rsrc" 'icm#'(266);

include "Perl.rsrc" 'CURS' (146);
include "Perl.rsrc" 'CURS' (144);
include "Perl.rsrc" 'CURS' (145);
include "Perl.rsrc" 'CURS' (147);
include "Perl.rsrc" 'CURS' (148);
include "Perl.rsrc" 'CURS' (160);
include "Perl.rsrc" 'CURS' (161);
include "Perl.rsrc" 'CURS' (162);
include "Perl.rsrc" 'CURS' (163);
include "Perl.rsrc" 'acur' (0);
include "Perl.rsrc" 'acur' (128);

#define MPAppName "MacPerl"
#include "MPVersion.r";

resource 'STR#' (CreditID) {
	{
		"Kenneth Albanowski",	"Charles Albrecht",	"Larry Allen-Tonar",
		"Kevin Altis",		"Frank Alvani",		"Phil Ames",				
		"Roberto Avanzi",
		"Peter Van Avermaet",	"Charles Bailey",	"Stonewall Ballard",
		"Joaquim Baptista",	"Berardino Baratta",	"Joe Bearly",
		"Benjamin Beberness",	"Devin Ben-Hur",	"Paddy Benson",
		"William Birkett",	"David Blank-Edelman",	"Steve Bollinger",
		"Vicki Brown",		"Jason Buberel",	"James Burgess",
		"Sean Burke",
		"Alun Carr",		"Sam Choukri",		"Jürgen Christoffel",
		"Henry Churchyard",	"Robert Coie",
		"Scott Collins",	"Jim Correia",
		"Brad Cox",		"Peter Creath",		"Kevin Cutts",
		"Robert Decker",	"Christian Dippel", 	"Steve Dorner",			
		"John Draper",
		"Paul DuBois",		"Paul Duda",
		"Torsten Ekedahl",	"Tim Endres",		"Gus Fernandez",
		"Glenn Fleishman",	"brian d foy",		"David Friedlander",
		"Alan Fry",		"Greg Galanos",
		"Scott R. Godin",	"Steve Goodwin",
		"Guy Greenbaum",	"Janis Greenberg",	"Michael Greenspon",
		"Sal Gurnani",		"David Hansen",		"Steve Hampson",
		"Brad Hanson",		"Toni Harbaugh",	"Tom Harrington",
		"Martin Heller",	"Dan Herron",		"Jarkko Hietaniemi",
		"Kee Hinckley",		"Todd Hivnor",		"C. Joe Holmes",
		"Stewart Holt",		"Tom Holub",
		"Elton Hughes",		"David Huggins-Daines",
		"Christian Huldt",	"Nat Irons",
		"Jeff Johnson",		"John Kamp",
		"Dick Karpinski",	"Jim Kateley",		"Pete Keleher",
		"Thomas Kimpton",	"Andreas König",	"Manfred Lauer",
		"Gary LaVoy",		"Xah Lee",		"Thomas Lenggenhager",
		"Kevin Lenzo",		"Peter Lewis",		"John Liberty",
		"Ron Liechty",		"Jann Linder",		"Roger Linder",
		"Brian Matthews",	"Angus McIntyre",	"Mike Meckler",
		"Will Merrill",		"William Middleton",	"Peter Möller",
		"Richard Moe",		"Bill Moore",		"Rich Morin",
		"Chris Myers",		"Jennifer Nandor",	"Asa Packer",
		"Paul Patton",		"Mark Pease",		"James \"Kibo\" Parry",
		"Lasse Petersen",
		"John Peterson",	"Brad Pickering",	"Marco Piovanelli",
		"Tom Pollard",		"Simon Poole",		"Malcolm Pradhan",
		"Quinn",		"Tim Rand",		"Alasdair Rawsthorne",
		"Kevin Reid",		"Charlie Reiman",	"King Rhoton",
		"Marcel Riechert",	"Axel Rose",
		"Diller Ryan",		"Gurusamy Sarathy",
		"Paul Schinder",	"Matthias Schmitt",	"Adam Schneider",
		"David Schooley",
		"Shimizu Shu",		"Sandra Silcot",	"Paul Snively",
		"Stephan Somogyi",	"Omar Souka",		"Jon Stevens",
		"Dan Strnad",		"Ken Stuart",		"Man Wei Tam",
		"Danny Thomas",		"Chris Thorman",	"James Tisdall",
		"Werner Uhrig",		"Maki Watanabe",
		"Scott Weaver",		"Thomas Wegner",
		"Mike West",		"Peter Whaite",		"Forrest Whitcher",
		"Hal Wine",		"Dave Wodelet",		"Barry Wolman",
		"Michael Wu",		"Yuemo Zeng",
		"… and many others.",
	}
};

resource 'SIZE' (-1) {
	dontSaveScreen,
	acceptSuspendResumeEvents,
	enableOptionSwitch,
	canBackground,
	multiFinderAware,
	backgroundAndForeground,
	dontGetFrontClicks,
	ignoreChildDiedEvents,
	is32BitCompatible,
	isHighLevelEventAware,
	localAndRemoteHLEvents,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
/*	3840 * 1024,
	1536 * 1024 */
	15 * 1024 * 1024,
	2  * 1024 * 1024
};

type 'MrPS' as 'SIZE';

resource 'MrPS' (-1) {
	dontSaveScreen,
	acceptSuspendResumeEvents,
	enableOptionSwitch,
	canBackground,
	multiFinderAware,
	backgroundAndForeground,
	dontGetFrontClicks,
	ignoreChildDiedEvents,
	is32BitCompatible,
	isHighLevelEventAware,
	localAndRemoteHLEvents,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	65536,
	65536
};

/************************** Window templates **************************/

resource 'WIND' (WindowTemplates, "", purgeable) {
	{18, 48, 312, 488},
	zoomDocProc,
	invisible,
	goAway,
	0x0,
	Untitled, 
	noAutoCenter
};

resource 'WIND' (WindowTemplates+1, "", purgeable) {
	{18, 48, 312, 488},
	zoomDocProc,
	invisible,
	goAway,
	0x0,
	"MacPerl",
	noAutoCenter
};

resource 'WIND' (WindowTemplates+2, "", purgeable) {
	{18, 48, 312, 488},
	zoomDocProc,
	invisible,
	goAway,
	0x0,
	Untitled,
	noAutoCenter
};

/************************** MacPerl'Answer Dialog **************************/

resource 'DLOG' (2001)	{
	{  0,   0, 150, 400},
	dBoxProc,
	invisible,
	noGoAway,
	0,
	2001,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2001)	{
	{
		{119,  307, 137,  387}, Button 		{ enabled, "^1"},
		{119, 8406, 137, 8486}, Button 		{ enabled, "^2"},
		{119, 8313, 137, 8393}, Button 		{ enabled, "^3"},
		{ 13,   23,  45,   55}, Icon			{disabled, 0	},
		{ 13,   78, 103,  387}, StaticText	{disabled, "^0"}
	}
};


resource 'DLOG' (2002)	{
	{  0,   0, 150, 400},
	dBoxProc,
	invisible,
	noGoAway,
	0,
	2002,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2002)	{
	{
		{119,  307, 137,  387}, Button 		{ enabled, "^1"},
		{119,  214, 137,  294}, Button 		{ enabled, "^2"},
		{119, 8313, 137, 8393}, Button 		{ enabled, "^3"},
		{ 13,   23,  45,   55}, Icon			{disabled, 2	},
		{ 13,   78, 103,  387}, StaticText	{disabled, "^0"}
	}
};

resource 'DLOG' (2003)	{
	{  0,   0, 150, 400},
	dBoxProc,
	invisible,
	noGoAway,
	0,
	2003,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2003)	{
	{
		{119, 307, 137, 387}, Button 		{ enabled, "B1"},
		{119, 214, 137, 294}, Button 		{ enabled, "B2"},
		{119, 121, 137, 201}, Button 		{ enabled, "B3"},
		{ 13,  23,  45,  55}, Icon			{disabled, 2	},
		{ 13,  78, 103, 387}, StaticText	{disabled, "Prompt"}
	}
};

/************************** MacPerl'Ask Dialogs **************************/

resource 'DLOG' (2010) {
	{0, 0, 104, 400},
	dBoxProc,
	invisible,
	noGoAway,
	'tmDI',
	2010,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2010, "Ask", purgeable) {
	{
		{73, 307, 91, 387}, Button 			{ enabled, "OK"},
		{73, 214, 91, 294},	Button 			{ enabled, "Cancel"},
		{13,  13, 31, 387},	StaticText 		{disabled, "^0"},
		{44,  15, 60, 385}, EditText 			{disabled, ""}
	}
};

/************************** MacPerl'Pick Dialog **************************/

resource 'DLOG' (2020) {
	{38, 80, 245, 427},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2020,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2020) {
	{
		{178,  30, 198,  88},	Button 		{ enabled, "OK"},
		{178, 258, 198, 316},	Button 		{ enabled, "Cancel"},
		{  2,   2,  19, 373},	StaticText 	{disabled, "Prompt"},
		{ 19,   2, 168, 345},	UserItem 	{disabled}
	}
};

/************************** Error Dialog **************************/

resource 'ALRT' (ErrorAlert, "", purgeable) {
	{82, 104, 212, 426},
	ErrorAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionMainScreen
};

resource 'DITL' (ErrorAlert, "", purgeable) {
	{	{ 98, 240, 118, 300}, Button {enabled, "OK"},
		{  9,  57,  86, 300}, StaticText {enabled, "^0^1^2^3"},
		{  9,   7,  41,  39}, Icon {enabled, 1}
	}
};

/************************** Save Changes Dialog **************************/

resource 'ALRT' (SaveAlert, "", purgeable) {
	{86, 60, 190, 432},
	SaveAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (SaveAlert) {
	{	{ 74, 303,  94, 362}, Button 		{ enabled, "Save"},
		{ 74, 231,  94, 290}, Button 		{ enabled, "Cancel"},
		{ 74,  65,  94, 150}, Button 		{ enabled, "Don’t Save"},
		{ 10,  65,  59, 363}, StaticText {disabled, "Save changes to “^0”?"},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2},
		{  0,   0,   0,   0}, HelpItem 	{disabled, HMScanhdlg { SaveAlert } },
	}
};

/************************** Revert Dialog **************************/

resource 'ALRT' (RevertAlert, "", purgeable) {
	{86, 60, 190, 432},
	RevertAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (RevertAlert) {
	{	{ 74, 303,  94, 362}, Button 		{ enabled, "Revert"},
		{ 74, 231,  94, 290}, Button 		{ enabled, "Cancel"},
		{ 10,  65,  59, 363}, StaticText {disabled, "Revert to the last saved version of “^0”?"},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2},
		{  0,   0,   0,   0}, HelpItem 	{disabled, HMScanhdlg { RevertAlert } },
	}
};

/************************** Helper Dialog **************************/

resource 'ALRT' (HelperAlert, "", purgeable) {
	{86, 60, 222, 432},
	HelperAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (HelperAlert) {
	{	{106, 193, 126, 362}, Button 	{ enabled, "Launch Internet Config"},
		{106, 121, 126, 180}, Button 	{ enabled, "Cancel"},
		{ 10,  65,  91, 363}, StaticText{disabled, 
			"Could not find helper for “^0”. Do you want to create one?\n"
			"For “http”, you should specify a WWW browser as the helper, "
			"for “pod”, you should specify “Shuck”."
										},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2},
		{  0,   0,   0,   0}, HelpItem 	{disabled, HMScanhdlg { HelperAlert } },
	}
};

/************************** Abort Dialog **************************/

resource 'ALRT' (AbortAlert, "", purgeable) {
	{86, 60, 190, 432},
	AbortAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (AbortAlert) {
	{	{ 74, 303,  94, 362}, Button 		{ enabled, "Quit"},
		{ 74, 231,  94, 290}, Button 		{ enabled, "Cancel"},
		{ 10,  65,  59, 363}, StaticText {disabled, "Quit (and abort current Perl script)?"},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2},
		{  0,   0,   0,   0}, HelpItem 	{disabled, HMScanhdlg { AbortAlert } },
	}
};

/************************** Format Dialog **************************/

resource 'DLOG' (FormatDialog, "", purgeable) {
	{68, 52, 245, 435},
	movableDBoxProc,
	invisible,
	goAway,
	0x0,
	FormatDialog,
	"Format",
	alertPositionParentWindow
};

resource 'DITL' (FormatDialog, purgeable) {
	{	{104, 268, 124, 341},	Button 		{ enabled, "OK"				},
		{135, 268, 156, 341},	Button 		{ enabled, "Cancel"			},
		{ 28,  11, 156, 170},	UserItem 	{ enabled						},
		{ 60, 181, 156, 219},	UserItem 	{ enabled						},
		{ 28, 233, 156, 234},	UserItem 	{disabled						},
		{104, 268, 124, 341},	UserItem 	{disabled						},
		{ 30, 183,  46, 217},	EditText 	{disabled, ""					},
		{ 42, 245,  62, 372},	CheckBox 	{ enabled, "Make Default"	},
		{  7,  15,  25,  53},	StaticText	{disabled, "Font"				},
		{  7, 184,  25, 217},	StaticText 	{disabled, "Size"				},
		{  0,   0,   0,   0}, 	HelpItem 	{ disabled, HMScanhdlg { FormatDialog } },
	}
};

/************************** Preferences Dialog **************************/

resource 'DLOG' (PrefDialog, "", purgeable) {
	{0, 0, 300, 450},
	movableDBoxProc,
	invisible,
	goAway,
	'tmDI',
	PrefDialog,
	"Preferences",
	alertPositionMainScreen
};

resource 'DITL' (PrefDialog, "", purgeable) {
	{	{  0,  28,  32,  60}, UserItem { enabled },
		{  0,  93,  32, 125}, UserItem { enabled },
		{  0, 158,  32, 190}, UserItem { enabled },
		{  0, 223,  32, 255}, UserItem { enabled },
		{  0, 288,  32, 320}, UserItem { enabled },
		{ 53,   0,  54, 450}, UserItem { disabled },
		{  0,   0,   0,   0}, HelpItem { disabled, HMScanhdlg { PrefDialog } },
		{ 20, 380,  40, 430}, Button   { enabled, "Done"},
		{ 20, 380,  40, 430}, UserItem { disabled }
	}
};

resource 'dctb' (PrefDialog, "", purgeable) {
	{
	}
};

resource 'STR#' (PrefDialog) {
	{	"Libraries",
		"Environment",
		"Scripts",
		"Input",
		"Others",
		"Change Path:",
		"Add Path:"
	}
};

resource 'DITL' (PrefLibID, "", purgeable) {
	{	{ 80,  30, 195, 425}, UserItem   { disabled },
		{275,  35, 295, 175}, Button	 { enabled, "Remove Path(s)" 	},
		{275, 260, 295, 400}, Button	 { enabled, "Add Path…"			},
		{220,  30, 270, 425}, StaticText { disabled, "lib\nsite_perl\n:"},
		{ 60,  10,  78, 425}, StaticText { disabled, 
			"Paths to search for library modules:" 						},
		{200,  10, 218, 425}, StaticText { disabled, 
			"Always searched (after the above):" 						}
	}
};

resource 'ALRT' (PrefLibDelID, "", purgeable) {
	{108, 158, 238, 476},
	PrefLibDelID,
	{	Cancel, visible, sound1,
		Cancel, visible, sound1,
		Cancel, visible, sound1,
		Cancel, visible, sound1
	},
	alertPositionParentWindow
};

resource 'DITL' (PrefLibDelID, "", purgeable) {
	{	{ 98, 227, 119, 292}, Button { enabled, "Delete"},
		{ 98,  27, 119,  92}, Button { enabled, "Cancel"},
		{  9,  63,  89, 294}, StaticText {disabled, "Are you sure you want to delete the selected paths ?"},
		{ 10,  11,  42,  43}, Icon { disabled, 1 }
	}
};

resource 'DITL' (PrefEnvID, "", purgeable) {
	{	{ 60,  10, 270, 425}, UserItem { disabled },
		{275,  35, 295, 175}, Button	 { enabled, "Remove Variable(s)" 	},
		{275, 260, 295, 400}, Button	 { enabled, "Add Variable…"			}
	}
};

resource 'ALRT' (PrefEnvDelID, "", purgeable) {
	{108, 158, 238, 476},
	PrefEnvDelID,
	{	Cancel, visible, sound1,
		Cancel, visible, sound1,
		Cancel, visible, sound1,
		Cancel, visible, sound1
	},
	alertPositionParentWindow
};

resource 'DITL' (PrefEnvDelID, "", purgeable) {
	{	{ 98, 227, 119, 292}, Button { enabled, "Delete"},
		{ 98,  27, 119,  92}, Button { enabled, "Cancel"},
		{  9,  63,  89, 294}, StaticText {disabled, "Are you sure you want to delete the selected variables ?"},
		{ 10,  11,  42,  43}, Icon { disabled, 1 }
	}
};

resource 'DLOG' (PrefEnvAddID, "", purgeable) {
	{0, 0, 172, 352},
	movableDBoxProc,
	invisible,
	noGoAway,
	'tmDI',
	PrefEnvAddID,
	"Edit Environment Variable",
	alertPositionParentWindow
};

resource 'DITL' (PrefEnvAddID, "", purgeable) {
	{	{145, 275, 165, 345}, Button     { enabled, "OK"      },
		{145, 190, 165, 260}, Button     { enabled, "Cancel"  },
		{ 55, 190,  75, 265}, Button     { enabled, "File…"   },
		{ 55, 275,  75, 345}, Button     { enabled, "Folder…" },
		{ 30,   9,  46, 145}, EditText   { disabled, ""       },
		{ 79,   9, 127, 345}, EditText   { disabled, ""       },
		{  7,   7,  25,  80}, StaticText { disabled, "Name"   },
		{ 56,   7,  74,  80}, StaticText { disabled, "Value"  },
	}
};

resource 'DITL' (PrefScriptID, "", purgeable) {
	{	{ 80,  25, 100,  80}, RadioButton { enabled, "Edit" 	},
		{100,  25, 120,  80}, RadioButton { enabled, "Run" 	},
		{140,  25, 160, 375}, CheckBox	 { enabled, "Check for #! line"},
		{ 93,  80, 113, 375}, StaticText  {disabled, "Scripts opened from Finder"}
	}
};

resource 'DITL' (PrefInputID, "", purgeable) {
	{	{ 80,  25, 100, 200}, CheckBox { enabled, "Enable inline input" 	},
	}
};

resource 'DITL' (PrefConfigID, "", purgeable) {
	{	{ 80,  25, 100, 200}, Button { enabled, "Launch Internet Config" 	},
	}
};

/************************** General Error Dialog **************************/

resource 'ALRT' (300, "Error Alert", purgeable) {
	{108, 158, 238, 476},
	300,
	{	/* array: 4 elements */
		/* [1] */
		OK, visible, sound1,
		/* [2] */
		OK, visible, sound1,
		/* [3] */
		OK, visible, sound1,
		/* [4] */
		OK, visible, sound1
	},
	alertPositionMainScreen
};

resource 'DITL' (300, "", purgeable) {
	{	/* array DITLarray: 3 elements */
		/* [1] */
		{98, 227, 119, 292},
		Button {
			enabled,
			"Oh well"
		},
		/* [2] */
		{9, 63, 89, 294},
		StaticText {
			enabled,
			"Sorry an error has occured in the area o"
			"f ^0. \nThe error code = ^1\n(^2)"
		},
		/* [3] */
		{10, 11, 42, 43},
		Icon {
			enabled,
			0
		}
	}
};

/************************** Printing Progress Dialog **************************/

resource 'DLOG' (1005, "printing…", purgeable) {
	{148, 157, 185, 354},
	dBoxProc,
	visible,
	noGoAway,
	0x0,
	1005,
	"printing…",
	alertPositionParentWindow
};

resource 'DITL' (1005, "printing…", purgeable) {
	{	/* array DITLarray: 1 elements */
		/* [1] */
		{10, 10, 27, 235},
		StaticText {
			disabled,
			"Type \0x11. to cancel printing"
		}
	}
};

/************************** 7.0 only alert **************************/

resource 'ALRT' (302, "7.0 Only Alert") {
	{50, 60, 192, 350},
	302,
	{	/* array: 4 elements */
		/* [1] */
		OK, visible, sound1,
		/* [2] */
		OK, visible, sound1,
		/* [3] */
		OK, visible, sound1,
		/* [4] */
		OK, visible, sound1
	},
	noAutoCenter
};

resource 'DITL' (302) {
	{	/* array DITLarray: 3 elements */
		/* [1] */
		{108, 213, 128, 273},
		Button {
			enabled,
			"OK"
		},
		/* [2] */
		{11, 63, 79, 278},
		StaticText {
			disabled,
			"MacPerl requires System 7.0 or later to run."
		},
		/* [3] */
		{11, 12, 43, 44},
		Icon {
			enabled,
			0
		}
	}
};

/************************** Save Dialog **************************/

resource 'DLOG' (SaveScriptDialog, purgeable) {
	{30, 8, 260, 352},
	dBoxProc,
	invisible,
	noGoAway,
	'tmDI',
	SaveScriptDialog,
	"Put File",
	noAutoCenter 
};

resource 'DITL' (SaveScriptDialog, purgeable) {
	{	{161, 252, 181, 332}, Button 		{ enabled, "Save" 				},
		{130, 252, 150, 332}, Button 		{ enabled, "Cancel" 				},
		{  0,   0,   0,   0}, HelpItem 	{ disabled, HMScanhdlg {-6043}},
		{  8, 235,  24, 337}, UserItem 	{ enabled 							},
		{ 32, 252,  52, 332}, Button 		{ enabled, "Eject" 				},
		{ 60, 252,  80, 332}, Button 		{ enabled, "Desktop" 			},
		{ 29,  12, 127, 230}, UserItem 	{ enabled 							},
		{  6,  12,  25, 230}, UserItem 	{ enabled 							},
		{119, 250, 120, 334}, Picture 	{ disabled, 11						},
		{157,  15, 173, 227}, EditText 	{ enabled, "" 						},
		{136,  15, 152, 227}, StaticText { disabled, "Save as:" 			},
		{ 88, 252, 108, 332}, UserItem 	{ disabled 							},
		{187,  17, 206, 283}, Control 	{ enabled, SaveScriptDialog	},
	}
};

resource 'CNTL' (SaveScriptDialog, preload, purgeable) {
	{187,  17, 206, 283},		/*enclosing rectangle of control*/
	popupTitleLeftJust, 			/*title position*/
	visible, 						/*make control visible*/ 
	50, 								/*pixel width of title*/
	SaveScriptDialog, 			/*'MENU' resource ID*/
	popupMenuCDEFProc,			/*pop-up control definition ID*/ 
	0, 								/*reference value*/
	"Type:"							/*control title*/
};

resource 'MENU' (SaveScriptDialog) {
	SaveScriptDialog,
	textMenuProc,
	0x7FFFFFFF,
	enabled,
	"Type",
	{	"Plain Text", 				noIcon, noKey, noMark, plain,
		"Runtime Version", 		noIcon, noKey, noMark, plain
	}
};

/************************** No Perl Script Dialog **************************/

resource 'ALRT' (NoPerlAlert, "", purgeable) {
	{86, 40, 230, 472},
	NoPerlAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (NoPerlAlert) {
	{	{114, 323, 134, 402}, Button 		{ enabled, "Proceed"},
		{114, 231, 134, 310}, Button 		{ enabled, "Abort"},
		{ 10,  65,  99, 403}, StaticText {disabled, 
			"I'm not sure “^0” is really a Perl script (the #! line is missing). "
			"Still want to proceed with trying to execute this script?"
													},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2}
	}
};

/************************** File too bulky to open Dialog **************************/

resource 'ALRT' (ElvisAlert, "", purgeable) {
	{86, 40, 210, 452},
	ElvisAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (ElvisAlert) {
	{	{ 94, 323, 114, 402}, Button 		{ enabled, "Save"},
		{ 94, 231, 114, 310}, Button 		{ enabled, "Cancel"},
		{ 10,  65,  79, 403}, StaticText {disabled, 
			"This file is too big to be edited in MacPerl. "
			"You may, however, save it as a MacPerl script or runtime."
													},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2}
	}
};

resource 'ALRT' (ElvisEditAlert, "", purgeable) {
	{86, 40, 210, 452},
	ElvisEditAlert,
	{	OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent,
		OK, visible, silent
	},
	alertPositionParentWindow
};

resource 'DITL' (ElvisEditAlert) {
	{	{ 94, 323, 114, 402}, Button 		{ enabled, "Save"},
		{ 94,  21, 114, 100}, Button 		{ enabled, "Cancel"},
		{ 94, 231, 114, 310}, Button 		{ enabled, "Edit"},
		{ 10,  65,  79, 403}, StaticText {disabled, 
			"This file is too big to be edited in MacPerl. "
			"You may, however, either save it as a MacPerl "
			"script or runtime or edit it with your external editor."
													},
		{ 10,  20,  42,  52}, Icon 		{disabled, 2}
	}
};

/************************** Menus **************************/

resource 'MENU' (appleID) {
	appleID,
	19999,
	0x7FFFFFFD,
	enabled,
	apple,
	{	/* array: 2 elements */
		/* [1] */
		"About MacPerl…", noIcon, noKey, noMark, plain,
		/* [2] */
		"-", noIcon, noKey, noMark, plain
	}
};

resource 'MENU' (fileID) {
	fileID,
	19999,
	0b10001101111011,
	enabled,
	"File",
	{	"New", 			noIcon, "N", 	noMark, plain,
		"Open…", 		noIcon, "O", 	noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Close", 		noIcon, "W", 	noMark, plain,
		"Save", 			noIcon, "S", 	noMark, plain,
		"Save As…", 	noIcon, "S", 	noMark, extend,
		"Revert", 		noIcon, noKey, noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Page Setup…", noIcon, noKey, noMark, plain,
		"Print…", 		noIcon, "P", 	noMark, plain,
		"-", 				noIcon, noKey,	noMark, plain,
		"Stop Script",	noIcon, ".", 	noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Quit", 			noIcon, "Q", 	noMark, plain
	}
};

resource 'MENU' (editID) {
	editID,
	19999,
	0b101011101111101,
	enabled,
	"Edit",
	{	"Undo", 			noIcon, "Z", 	noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Cut", 			noIcon, "X", 	noMark, plain,
		"Copy", 			noIcon, "C", 	noMark, plain,
		"Paste", 		noIcon, "V", 	noMark, plain,
		"Clear", 		noIcon, noKey, noMark, plain,
		"Select All", 	noIcon, "A", 	noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Find…",			noIcon, "F",	noMark, plain,
		"Find Same",	noIcon, "G", 	noMark, plain,
		"Jump to…", 	noIcon, "J", 	noMark, plain,		
		"-", 				noIcon, noKey, noMark, plain,
		"Format…", 		noIcon, "Y", 	noMark, plain,
		"-", 				noIcon, noKey, noMark, plain,
		"Preferences…",noIcon, noKey, noMark, plain,
	}
};

resource 'MENU' (windowID, preload) {
	windowID,
	19999,
	allEnabled,
	enabled,
	"Window",
	{
	}
};

resource 'MENU' (perlID, preload) {
	perlID,
	19999,
	0b11111111111111111111111111101111,
	enabled,
	"Script",
	{	"Run Script…", 			noIcon, "R", 	noMark, plain,
		"Run Front Window", 	noIcon, "R", 	noMark, extend,
		"Syntax Check…",		noIcon, "K", 	noMark, plain,
		"Check Front Window",	noIcon, "K", 	noMark, extend,
		"-", 					noIcon, noKey,	noMark, plain,
		"Compiler Warnings",	noIcon, noKey,	noMark, plain,
		"Perl Debugger",		noIcon, noKey,	noMark, plain,
		"Taint Checks",			noIcon, noKey,	noMark, plain
	}
};

resource 'MENU' (editorID) {
	editorID,
	19999,
	0b1011,
	enabled,
	"Editor",
	{	"Edit…", 				noIcon, "E", 	noMark,  plain,
		"Edit Front Window", 	noIcon, "E", 	noMark, extend,
		"-", 					noIcon, noKey, 	noMark, plain,
		"Update…", 				noIcon, "U", 	noMark, plain,
		"Update", 				noIcon, "U", 	noMark, extend
	}
};

resource 'STR ' (helpID) {
	"Perl Help/H"
};


resource 'STR#' (256) {
	{
		"Indicates that this window is a modifiable text document.",
		"Indicates that this window is a read-only text document.",
		"Indicates that this window is a console window that is currently expecting input.",
		"Indicates that this window is a read-only console window.",
		"Indicates that this window is a console window that is not currently expecting input.",
	}
};

#include "MPTerminology.r"
#include "MPBalloons.r"
