/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPDroplet.r		-	Resources for droplets
Authors	:	Matthias Neeracher & Tim Endres
Language	:	MPW C

$Log: MPDroplet.r,v $
Revision 1.3  2001/10/03 19:23:16  pudge
Sync with perforce maint-5.6/macperl

Revision 1.2  2001/01/23 05:31:47  neeri
Make Droplet and Font LDEF buildable with SC (Tasks 24870, 24872)

Revision 1.1  1997/06/23 17:10:38  neeri
Checked into CVS

*********************************************************************/

#define SystemSevenOrLater 1

#include "Types.r"
#include "SysTypes.r"

#include "MPExtension.r"

#ifdef MWC
include "MPDroplet.code.68K" 'CODE' as 'MrPC';
include "MPDroplet.code.68K" 'DATA' as 'MrPD';
#else
include "MPDroplet.code.SC" 'CODE' as 'MrPC';
#endif

include "MPExtension.rsrc" 'BNDL'(128) as 'MrPB'(128);
include "MPExtension.rsrc" 'MrPL'(0);
include "MPExtension.rsrc" 'ICN#'(128);
include "MPExtension.rsrc" 'icl4'(128);
include "MPExtension.rsrc" 'icl8'(128);
include "MPExtension.rsrc" 'ics#'(128);
include "MPExtension.rsrc" 'ics4'(128);
include "MPExtension.rsrc" 'ics8'(128);
include "MPExtension.rsrc" 'ALRT'(4096);
include "MPExtension.rsrc" 'DITL'(4096);
include "MPExtension.rsrc" 'FREF'(128);
include "MPExtension.rsrc" 'FREF'(129);
include "MPExtension.rsrc" 'FREF'(130);
include "MPExtension.rsrc" 'FREF'(131);
include "MPExtension.rsrc" 'FREF'(132);

resource 'STR ' (SERsrcBase) {
	"Droplet"
};

resource 'McPp' (SERsrcBase) {
	'SCPT', 'APPL', 'MrPL', wantsBundle, noCustomIcon
};

resource 'McPs' (SERsrcBase) {
	{
		'MrPC', 'CODE',    0,    0,
		'MrPC', 'CODE',    1,    1,
#ifdef MWC
		'MrPD', 'DATA',    0,    0,
#else
		'MrPC', 'CODE',    2,    2,
		'MrPC', 'CODE',    3,    3,
#endif
		'MrPB', 'BNDL',  128,  128,
		'MrPL', 'MrPL',    0,    0,
		'SIZE', 'SIZE',  128,   -1,
		'ICN#', 'ICN#',  128,  128,
		'icl4', 'icl4',  128,  128,
		'icl8', 'icl8',  128,  128,
		'ics#', 'ics#',  128,  128,
		'ics4', 'ics4',  128,  128,
		'ics8', 'ics8',  128,  128,
		'ALRT', 'ALRT', 4096, 4096,
		'DITL', 'DITL', 4096, 4096,
		'FREF', 'FREF',  128,  128,
		'FREF', 'FREF',  129,  129,
		'FREF', 'FREF',  130,  130,
		'FREF', 'FREF',  131,  131,
		'FREF', 'FREF',  132,  132,
		    0,      0,     0,    0
	}
};

resource 'SIZE' (128) {
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
