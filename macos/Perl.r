/*
 *    Copyright (c) 1995 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Perl.r,v $
 * Revision 1.7  2001/10/03 19:31:55  pudge
 * Sync with perforce maint-5.6/macperl
 *
 * Revision 1.6  2001/04/17 03:59:23  pudge
 * Minor version/config changes, plus sync with maint-5.6/perl
 *
 * Revision 1.5  2001/04/17 03:53:44  pudge
 * Minor version/config changes, plus sync with maint-5.6/perl
 *
 * Revision 1.4  2001/03/22 04:29:31  pudge
 * Update version
 *
 * Revision 1.3  2001/02/23 23:34:04  pudge
 * Add xsubpp.patch; update versions; fix missing fp.h for SC/MrC
 *
 * Revision 1.2  2001/01/30 05:26:09  pudge
 * Update versions
 *
 * Revision 1.1  2000/08/14 01:48:17  neeri
 * Checked into Sourceforge
 *
 * Revision 1.1  1999/12/13 01:28:35  neeri
 * Added to new MacPerl build
 *
 * Revision 1.7  1999/01/24 05:14:02  neeri
 * Various tweaks made in 1998
 *
 * Revision 1.6  1998/04/21 22:27:08  neeri
 * MacPerl 5.2.0r4
 *
 * Revision 1.5  1998/04/14 19:46:48  neeri
 * MacPerl 5.2.0r4b2
 *
 * Revision 1.4  1998/04/07 01:47:01  neeri
 * MacPerl 5.2.0r4b1
 *
 * Revision 1.3  1997/11/18 00:51:43  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.2  1997/08/08 16:38:46  neeri
 * MacPerl 5.1.4b1 + time() fix
 *
 * Revision 1.1  1997/04/07 20:46:26  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define SystemSevenOrLater 1

#include "SysTypes.r"		/* To get system types */
#include "Types.r"		/* To get general types */
#include "Cmdo.r"		/* For commando interface */

include "Perl.rsrc";
#define MPAppName "perl"
#include "MPVersion.r";

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
		{119,  307, 137,  387}, Button 		{ enabled, "B1"},
		{119, 8406, 137, 8486}, Button 		{ enabled, "B2"},
		{119, 8313, 137, 8393}, Button 		{ enabled, "B3"},
		{ 13,   23,  45,   55}, Icon		{disabled, 0	},
		{ 13,   78, 103,  387}, StaticText	{disabled, "Prompt"}
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
		{119,  307, 137,  387}, Button 		{ enabled, "B1"},
		{119,  214, 137,  294}, Button 		{ enabled, "B2"},
		{119, 8313, 137, 8393}, Button 		{ enabled, "B3"},
		{ 13,   23,  45,   55}, Icon			{disabled, 2	},
		{ 13,   78, 103,  387}, StaticText	{disabled, "Prompt"}
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

resource 'DLOG' (2010) {
	{0, 0, 104, 400},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2010,
	"",
	alertPositionMainScreen
};

resource 'DITL' (2010, "Ask", purgeable) {
	{	
		{73, 307, 91, 387}, Button 			{ enabled, "OK"},
		{73, 214, 91, 294},	Button 			{ enabled, "Cancel"},
		{13,  13, 31, 387},	StaticText 		{disabled, "^0"},
		{44,  15, 60, 385}, EditText 		{disabled, ""}
	}
};

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

resource 'cmdo' (128) {
	{
		295,			/* Height of dialog */
		"Perl -- Practical Extraction and Report Language\n"
		"by Larry Wall",
		{
			Or {{-2}}, Files {
				InputFile,
				OptionalFile {
					{ 17,  10,  33, 115},
					{ 15, 117,  35, 195},
					"Program File:",
					"", "", "",
					"Select program file. If no files are specified and no program "
					"is given on the command line, standard input will be used.",
					dim,
					"Read Standard Input",
					"Select a script to execute…",
					"",
				},
				Additional {
					"",
					".pl",
					"Files ending with .pl",
					"All text files",
					{text}
				}
			},
			Or {{-1}}, RegularEntry {
				"Program:",
				{ 42,  10,  58, 115},
				{ 42, 120,  58, 465},
				"",
				keepCase,
				"-e",
				"Program to execute."
			},
			notDependent {}, MultiFiles {
				"Input File(s)…",
				"Select input files.  If no files are specified, Perl reads from standard input.",
				{ 15, 300, 35, 465},
				"Input files:",
				"",
				MultiInputFiles {
					{TEXT},
					FilterTypes,
					"Only text files",
					"All files",
				}
			},
			notDependent {}, Redirection {
				StandardInput,
				{ 75,  20}
			},
			notDependent {}, Redirection {
				StandardOutput,
				{110,  20}
			},
			notDependent {}, Redirection {
				DiagnosticOutput,
				{145,  20}
			},
			notDependent {}, TextBox {
				gray,
				{ 70,  10, 185, 240},
				"Redirection"
			},
			notDependent {}, CheckOption 	{
				NotSet, { 75, 270,  91, 465}, "Print Version", "-v", 
				"Print version information to standard output.",
			},
			notDependent {}, CheckOption 	{
				NotSet, { 92, 270, 108, 465}, "Syntax Check Only", "-c", 
				"Exit after syntax checking.",
			},
			notDependent {}, CheckOption 	{
				NotSet, {109, 270, 125, 465}, "Print warnings", "-w", 
				"Print warnings about lots of likely errors.",
			},
			notDependent {}, CheckOption 	{
				NotSet, {126, 270, 142, 465}, "Debug", "-d", 
				"Run Perl debugger at start.",
			},
			notDependent {}, CheckOption 	{
				NotSet, {143, 270, 159, 465}, "Inplace processing", "-i.bak", 
				"Make backup and replace file.",
			},
			notDependent {}, NestedDialog	{
				2,
				{165, 270, 185, 440},
				"More Options…",
				"Lots of switches to configure the behaviour of Perl."
			},
			notDependent {}, VersionDialog {
				VersionString {
					MPVersionStr
				},
				"Perl by Larry Wall <larry@wall.org>\n"
				"MPW port by Matthias Neeracher <neeracher@mac.com>,\n"
				"Maintained by Chris Nandor <pudge@pobox.com>\n",
				0
			},
		},
		270,
		"",
		{
			notDependent {}, RadioButtons {
				{
					{ 36,  20,  51, 220}, "Newline", "", set, 
					"Records are terminated with newlines.",
					{ 53,  20,  68, 220}, "Null Character", "-0", notset, 
					"Records are terminated with null characters",
					{ 70,  20,  85, 220}, "Paragraph", "-00", notset, 
					"Records are terminated with two consecutive newlines"
				}
			},
			Or {{-3}}, CheckOption {
				NotSet, { 36, 240,  52, 465}, "Automatic Loop", "-n", 
				"Iterate script once for each input line."
			},
			Or {{-2}}, CheckOption {
				NotSet, { 53, 240,  69, 465}, "Automatic Printing Loop", "-p", 
				"Iterate script once for each input line, printing the line by default."
			},
			notDependent {}, CheckOption {
				NotSet, { 70, 240,  86, 465}, "Autosplit mode", "-a", 
				"Split input line before processing."
			},
			notDependent {}, CheckOption {
				NotSet, { 87, 240, 103, 465}, "Automatic Line End Processing", "-l", 
				"Chop input line and append newline on printing."
			},
			notDependent {}, CheckOption {
				NotSet, {115,  20, 131, 220}, "Run through C Preprocessor", "-P", 
				"Run the script through the C preprocessor first."
			},
			notDependent {}, CheckOption {
				NotSet, {132,  20, 148, 220}, "Switch parsing", "-s", 
				"Enables some rudimentary switch parsing."
			},
			notDependent {}, CheckOption {
				NotSet, {115, 240, 131, 465}, "Skip leading garbage.", "-x", 
				"Skip lines to the first #!perl line. Great for shell scripts."
			},
			notDependent {}, TextBox {
				gray,
				{ 25,  10, 108, 225},
				"Record Separator"
			},
			notDependent {}, TextBox {
				gray,
				{ 25, 235, 108, 470},
				"Useful for One Liners"
			},
		}
	},
};
