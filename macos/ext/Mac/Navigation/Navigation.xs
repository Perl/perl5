/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 * MacPerl 5.1.5
 * 
 * Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Navigation.h>
#include <GUSIFileSpec.h>

typedef struct {
	Boolean                         locked;             /* file is locked */
	Boolean                         resourceOpen;       /* resource fork is opened */
	Boolean                         dataOpen;           /* data fork is opened */
	Boolean                         reserved1;
	UInt32                          dataSize;           /* size of the data fork */
	UInt32                          resourceSize;       /* size of the resource fork */
	FInfo                           finderInfo;         /* more file info: */
	FXInfo                          finderXInfo;
}                                 NavFileInfo;
typedef struct {
	Boolean                         shareable;
	Boolean                         sharePoint;
	Boolean                         mounted;
	Boolean                         readable;
	Boolean                         writeable;
	Boolean                         reserved2;
	UInt32                          numberOfFiles;
	DInfo                           finderDInfo;
	DXInfo                          finderDXInfo;
	OSType                          folderType;
	OSType                          folderCreator;
	char                            reserved3[206];
}                                 NavFolderInfo;

typedef struct {
	SV *	eventProc;
	SV *	previewProc;
	SV *	filterProc;
} NavHooks;

typedef struct {
	AEDescList				files;
	FileTranslationSpec	**	translation;
} _NavReplySelection;


static NavReplyRecord * NewReply()
{
	return (NavReplyRecord *)NewPtr(sizeof(NavReplyRecord));
}

static OSErr Path2AEDesc(const char * path, AEDesc * desc)
{
	OSErr	err;
	FSSpec 	spec;
	
	if (err = GUSIPath2FSp(path, &spec))
		return err;
	else
		return AECreateDesc(typeFSS, &spec, sizeof(FSSpec), desc);
}

#define NavCBRec			NavCBRecPtr
#define NavFileInfo			NavFileInfo *
#define NavFolderInfo		NavFolderInfo *
#define NavFileOrFolderInfo	NavFileOrFolderInfo *
#define NavReplyRecord		NavReplyRecord *

static pascal void PerlEventProc(short msg, NavCBRec params, NavHooks * hooks)
{
	dSP;
	
	PUSHMARK(sp);
	XS_XPUSH(short, 	msg);
	XS_XPUSH(NavCBRec, 	params);
	PUTBACK;
	
	perl_call_sv(hooks->eventProc, G_DISCARD);
}

static pascal Boolean PerlPreviewProc(NavCBRec params, NavHooks * hooks)
{
	Boolean	res;
	
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(NavCBRec, params);
	PUTBACK;
	
	perl_call_sv(hooks->previewProc, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(Boolean, res);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

static pascal Boolean PerlFilterProc(AEDesc * item, NavFileOrFolderInfo info, NavHooks * hooks, short filterMode)
{
	Boolean	res;
	
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(AEDesc, 				*item);
	XS_XPUSH(NavFileOrFolderInfo,	info);
	XS_XPUSH(short,					filterMode);
	PUTBACK;
	
	perl_call_sv(hooks->filterProc, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(Boolean, res);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	return res;
}

#if TARGET_RT_MAC_CFM
static RoutineDescriptor	uPerlEventProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppNavEventProcInfo, PerlEventProc);
static RoutineDescriptor	uPerlPreviewProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppNavPreviewProcInfo, PerlPreviewProc);
static RoutineDescriptor	uPerlFilterProc = 
		BUILD_ROUTINE_DESCRIPTOR(uppNavObjectFilterProcInfo, PerlFilterProc);
#else
#define uPerlEventProc 		*(NavEventUPP)&PerlEventProc
#define uPerlPreviewProc 	*(NavPreviewUPP)&PerlPreviewProc
#define uPerlFilterProc 	*(NavObjectFilterUPP)&PerlFilterProc
#endif

MODULE = Mac::Navigation	PACKAGE = Mac::Navigation

=item NavFileOrFolderInfo

The file information passed to your filter functions. All fields are readonly.

    U16              version;
    Boolean          isFolder;
    Boolean          visible;
    U32              creationDate;
    U32              modificationDate;
    NavFileInfo      fileInfo;
    NavFolderInfo    folderInfo;

=cut
STRUCT * NavFileOrFolderInfo
	U16 		version;
		READ_ONLY
	Boolean 	isFolder;
		READ_ONLY
	Boolean 	visible;
		READ_ONLY
	U32 		creationDate;
		READ_ONLY
	U32 		modificationDate;
		READ_ONLY
	NavFileInfo		fileInfo;
		READ_ONLY
		ALIAS (NavFileInfo) &STRUCT->fileAndFolder.fileInfo
	NavFolderInfo	folderInfo;
		READ_ONLY
		ALIAS (NavFolderInfo) &STRUCT->fileAndFolder.folderInfo

=item NavFileInfo

The file specific part of the above structure. All fields are readonly.

    Boolean    locked;         /* file is locked */
    Boolean    resourceOpen;   /* resource fork is opened */
    Boolean    dataOpen;       /* data fork is opened */
    U32        dataSize;       /* size of the data fork */
    U32        resourceSize;   /* size of the resource fork */
    FInfo      finderInfo;     /* more file info: */
    FXInfo     moreFinderInfo;

=cut
STRUCT * NavFileInfo 
	Boolean 	locked;						/* file is locked */
		READ_ONLY
	Boolean 	resourceOpen;				/* resource fork is opened */
		READ_ONLY
	Boolean 	dataOpen;					/* data fork is opened */
		READ_ONLY
	U32 		dataSize;					/* size of the data fork */
		READ_ONLY
	U32 		resourceSize;				/* size of the resource fork */
		READ_ONLY
	FInfo 		finderInfo;					/* more file info: */
		READ_ONLY
	FXInfo		finderXInfo
		READ_ONLY
	FXInfo 		moreFinderInfo;
		READ_ONLY
		ALIAS STRUCT->finderXInfo

=item NavFolderInfo

The folder specific part of the above structure. All fields are readonly.

    Boolean    shareable;
    Boolean    sharePoint;
    Boolean    mounted;
    Boolean    readable;
    Boolean    writeable;
    U32        numberOfFiles;
    DInfo      finderInfo;
    DXInfo     moreFinderInfo;

=cut
STRUCT * NavFolderInfo 
	Boolean 	shareable;
		READ_ONLY
	Boolean 	sharePoint;
		READ_ONLY
	Boolean 	mounted;
		READ_ONLY
	Boolean 	readable;
		READ_ONLY
	Boolean 	writeable;
		READ_ONLY
	U32 		numberOfFiles;
		READ_ONLY
	DInfo 		finderDInfo;
		READ_ONLY
	DXInfo 		finderDXInfo;
		READ_ONLY
	DInfo 		finderInfo;
		READ_ONLY
		ALIAS	STRUCT->finderDInfo
	DXInfo 		moreFinderInfo;
		READ_ONLY
		ALIAS 	STRUCT->finderDXInfo

=item NavCBRec

The structure passed to your event procedure. Fields are

    U16            version;
    U32            context;     /* used by customization code to call Nav. Services */
    GrafPtr        window;      /* the dialog */
    Rect           customRect;  /* local coordinate rectangle of customization area */
    Rect           previewRect; /* local coordinate rectangle of the preview area */
    EventRecord    event;

=cut

#if UNIVERSAL_INTERFACES_VERSION >= 0x0340

STRUCT * NavCBRec
	U16 			version;
	NavDialogRef	context;					/* used by customization code to call Navigation Services */
	GrafPtr 		window;						/* the dialog */
	Rect 			customRect;					/* local coordinate rectangle of customization area */
	Rect 			previewRect;				/* local coordinate rectangle of the preview area */
	EventRecord 	event;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(ToolboxEvent, &STRUCT->eventData.eventDataParms.event, $arg);

#else

STRUCT * NavCBRec
	U16 			version;
	U32		 		context;					/* used by customization code to call Navigation Services */
	GrafPtr 		window;						/* the dialog */
	Rect 			customRect;					/* local coordinate rectangle of customization area */
	Rect 			previewRect;				/* local coordinate rectangle of the preview area */
	EventRecord 	event;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(ToolboxEvent, &STRUCT->eventData.eventDataParms.event, $arg);

#endif

=item NavDialogOptions

Options for a Navigation dialog. Fields are:

    U16       version;
    U32       dialogOptionFlags; /* option flags for affecting the dialog's behavior */
    Point     location;          /* top-left location of the dialog, or {-1,-1} for 
                                    default position */
    Str255    clientName;
    Str255    windowTitle;
    Str255    actionButtonLabel; /* label of the default button (or null string for 
                                    default) */
    Str255    cancelButtonLabel; /* label of the cancel button (or null string for 
                                    default) */
    Str255    savedFileName;     /* default name for text box in NavPutFile (or null 
                                    string for default) */
    Str255    message;           /* custom message prompt (or null string for default) */
    U32       preferenceKey;     /* a key for to managing preferences for using multiple 
                                    utility dialogs */

=cut
STRUCT NavDialogOptions
	U16 			version;
	U32	 			dialogOptionFlags;			/* option flags for affecting the dialog's behavior */
	Point 			location;					/* top-left location of the dialog, or {-1,-1} for default position */
	Str255 			clientName;
	Str255 			windowTitle;
	Str255 			actionButtonLabel;			/* label of the default button (or null string for default) */
	Str255 			cancelButtonLabel;			/* label of the cancel button (or null string for default) */
	Str255 			savedFileName;				/* default name for text box in NavPutFile (or null string for default) */
	Str255 			message;					/* custom message prompt (or null string for default) */
	U32 			preferenceKey;				/* a key for to managing preferences for using multiple utility dialogs */

MODULE = Mac::QuickDraw	PACKAGE = NavReplyRecord

=item NavReplyRecord

The reply from a navigation dialog. Fields are:

    U16        version;
    Boolean    validRecord;       /* open/save: true if the user confirmed a selection, 
                                     false on cancel */
    Boolean    replacing;         /* save: true if the user is overwriting an existing 
                                     object for save */
    Boolean    isStationery;      /* save: true if the user wants to save an object as 
                                     stationery */
    Boolean    translationNeeded; /* save: translation is 'needed', open: translation 
                                     'has taken place' */
    U16        keyScript;         /* open/save: script in which the name of each item in 
                                     'selection' is to be displayed */

=cut
STRUCT * NavReplyRecord
	U16 					version;
		READ_ONLY
	Boolean 				validRecord;				/* open/save: true if the user confirmed a selection, false on cancel */
		READ_ONLY
	Boolean 				replacing;					/* save: true if the user is overwriting an existing object for save */
		READ_ONLY
	Boolean 				isStationery;				/* save: true if the user wants to save an object as stationery */
		READ_ONLY
	Boolean 				translationNeeded;			/* save: translation is 'needed', open: translation 'has taken place' */
		READ_ONLY
	U16		 				keyScript;					/* open/save: script in which the name of each item in 'selection' is to be displayed */
		READ_ONLY

void
DESTROY(reply)
	NavReplyRecord	reply
	CODE:
	DisposePtr((Ptr)reply);

=over 4

=item count

Counts the number of objects chosen.

    $count = $reply->count;

=cut
long
count(reply)
	NavReplyRecord	reply
	CODE:
	if (gMacPerl_OSErr = AECountItems(&reply->selection, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item file INDEX

Returns the path of the INDEXth (1 to count) object chosen.

=cut
FSSpec
file(reply, index)
	NavReplyRecord	reply
	long			index
	CODE:
	{
		AEKeyword	kw;
		DescType	type;
		Size		sz;
		
		if (gMacPerl_OSErr = 
			AEGetNthPtr(
				&reply->selection, index, typeFSS, 
				&kw, &type, &RETVAL, sizeof(FSSpec), &sz)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

=item object INDEX

Returns an C<AEDesc> for the INDEXth (1 to count) object chosen.

=cut
AEDesc
object(reply, index)
	NavReplyRecord	reply
	long			index
	CODE:
	{
		AEKeyword	kw;
		
		if (gMacPerl_OSErr = 
			AEGetNthDesc(&reply->selection, index, typeWildCard, &kw, &RETVAL)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

=item translation INDEX

Returns a FileTranslationSpec for the INDEXth (1 to count) object chosen.

=cut
FileTranslationSpec
translation(reply, index)
	NavReplyRecord	reply
	long			index
	CODE:
	RETVAL = reply->fileTranslation[0][index-1];
	OUTPUT:
	RETVAL

=back

=cut
MODULE = Mac::Navigation	PACKAGE = Mac::Navigation
	
=back

=head2 Functions

=over 4

=item NavLoad 

=cut
MacOSRet
NavLoad()

=item NavUnload 

=cut
MacOSRet
NavUnload()

=item NavLibraryVersion 

=cut
U32
NavLibraryVersion()

=item OPT = NavGetDefaultDialogOptions 

=cut
NavDialogOptions
NavGetDefaultDialogOptions()
	CODE:
	if (gMacPerl_OSErr = NavGetDefaultDialogOptions(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item REPLY = NavGetFile DEFAULTLOCATION, DIALOGOPTIONS, TYPELIST [, EVENTPROC [, PREVIEWPROC [, FILTERPROC ]]]

=cut
NavReplyRecord
NavGetFile(defaultLocation, dialogOptions, typeList, eventProc=0, previewProc=0, filterProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	NavTypeListHandle	typeList
	SV *				eventProc
	SV *				previewProc
	SV *				filterProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		hooks.previewProc	= previewProc;
		hooks.filterProc	= filterProc;
		
		gMacPerl_OSErr = NavGetFile(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			(previewProc && SvTRUE(previewProc) ? &uPerlPreviewProc	: nil),
			(filterProc	 && SvTRUE(filterProc) ? &uPerlFilterProc  : nil),
			typeList, (NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavPutFile DEFAULTLOCATION, DIALOGOPTIONS, FILETYPE, FILECREATOR [, EVENTPROC ]

=cut
NavReplyRecord
NavPutFile(defaultLocation, dialogOptions, fileType, fileCreator, eventProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	OSType				fileType
	OSType				fileCreator
	SV *				eventProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		
		gMacPerl_OSErr = NavPutFile(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			fileType, fileCreator, (NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item RES = NavAskSaveChanges DIALOGOPTIONS, ACTION [, EVENTPROC ]

=cut
U32
NavAskSaveChanges(dialogOptions, action, eventProc=0)
	NavDialogOptions	dialogOptions
	U32					action
	SV *				eventProc
	CODE:
	{
		NavHooks	hooks;
	
		hooks.eventProc 	= eventProc;
		
		if (gMacPerl_OSErr = NavAskSaveChanges(&dialogOptions, action, &RETVAL,
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			(NavCallBackUserData)&hooks)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item RES = NavCustomAskSaveChanges DIALOGOPTIONS, EVENTPROC 

=cut
U32
NavCustomAskSaveChanges(dialogOptions, eventProc)
	NavDialogOptions 	dialogOptions
	SV *				eventProc
	CODE:
	{
		NavHooks	hooks;
	
		hooks.eventProc 	= eventProc;
		
		if (gMacPerl_OSErr = NavCustomAskSaveChanges(&dialogOptions, &RETVAL,
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			(NavCallBackUserData)&hooks)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item RES = NavAskDiscardChanges DIALOGOPTIONS, EVENTPROC 

=cut
U32
NavAskDiscardChanges(dialogOptions, eventProc)
	NavDialogOptions	dialogOptions
	SV *				eventProc
	CODE:
	{
		NavHooks	hooks;
	
		hooks.eventProc 	= eventProc;
		
		if (gMacPerl_OSErr = NavAskDiscardChanges(&dialogOptions, &RETVAL,
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			(NavCallBackUserData)&hooks)
		) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavChooseFile DEFAULTLOCATION, DIALOGOPTIONS, TYPELIST [, EVENTPROC [, PREVIEWPROC [, FILTERPROC ]]]

=cut
NavReplyRecord
NavChooseFile(defaultLocation, dialogOptions, typeList, eventProc=0, previewProc=0, filterProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	NavTypeListHandle	typeList
	SV *				eventProc
	SV *				previewProc
	SV *				filterProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		hooks.previewProc	= previewProc;
		hooks.filterProc	= filterProc;
		
		gMacPerl_OSErr = NavChooseFile(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	&& SvTRUE(eventProc)	? &uPerlEventProc 	: nil),
			(previewProc&& SvTRUE(previewProc) ? &uPerlPreviewProc	: nil),
			(filterProc	&& SvTRUE(filterProc) ? &uPerlFilterProc  : nil),
			typeList, (NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavChooseFolder DEFAULTLOCATION, DIALOGOPTIONS [, EVENTPROC [, FILTERPROC ]]

=cut
NavReplyRecord
NavChooseFolder(defaultLocation, dialogOptions, eventProc=0, filterProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	SV *				eventProc
	SV *				filterProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		hooks.filterProc	= filterProc;
		
		gMacPerl_OSErr = NavChooseFolder(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	 && SvTRUE(eventProc) ? &uPerlEventProc 	: nil),
			(filterProc	 && SvTRUE(filterProc) ? &uPerlFilterProc  : nil),
			(NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavChooseVolume DEFAULTLOCATION, DIALOGOPTIONS [, EVENTPROC [, FILTERPROC ]]

=cut
NavReplyRecord
NavChooseVolume(defaultLocation, dialogOptions, eventProc=0, filterProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	SV *				eventProc
	SV *				filterProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		hooks.filterProc	= filterProc;
		
		gMacPerl_OSErr = NavChooseVolume(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	&& SvTRUE(eventProc)  ? &uPerlEventProc 	: nil),
			(filterProc && SvTRUE(filterProc) ? &uPerlFilterProc  : nil),
			(NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavChooseObject DEFAULTLOCATION, DIALOGOPTIONS [, EVENTPROC [, FILTERPROC ]]

=cut
NavReplyRecord
NavChooseObject(defaultLocation, dialogOptions, eventProc=0, filterProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	SV *				eventProc
	SV *				filterProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
	
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		hooks.filterProc	= filterProc;
		
		gMacPerl_OSErr = NavChooseObject(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc	&& SvTRUE(eventProc)  ? &uPerlEventProc 	: nil),
			(filterProc && SvTRUE(filterProc) ? &uPerlFilterProc  : nil),
			(NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item REPLY = NavNewFolder DEFAULTLOCATION, DIALOGOPTIONS [, EVENTPROC ]

=cut
NavReplyRecord
NavNewFolder(defaultLocation, dialogOptions, eventProc=0)
	char *				defaultLocation
	NavDialogOptions	dialogOptions
	SV *				eventProc
	CODE:
	{
		AEDesc		loc, *l;
		NavHooks	hooks;
		
		if (*defaultLocation && !Path2AEDesc(defaultLocation, &loc))
			l = &loc;
		else
			l = nil;
		hooks.eventProc 	= eventProc;
		
		gMacPerl_OSErr = NavNewFolder(l, RETVAL=NewReply(), &dialogOptions, 
			(eventProc  && SvTRUE(eventProc)	? &uPerlEventProc 	: nil),
			(NavCallBackUserData)&hooks);
		
		if (l)
			AEDisposeDesc(l);
			
		if (gMacPerl_OSErr) {
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL


=item NavTranslateFile REPLY, HOWTOTRANSLATE 

=cut
MacOSRet
NavTranslateFile(reply, howToTranslate)
	NavReplyRecord  reply
	U32				howToTranslate


=item NavCompleteSave REPLY, HOWTOTRANSLATE 

=cut
MacOSRet
NavCompleteSave(reply, howToTranslate)
	NavReplyRecord  reply
	U32				howToTranslate

=begin ignore

MacOSRet
NavCustomControl(context, selector, parms)
	NavContext	context
	NavCustomControlMessage	selector
	void *	parms

=end ignore

=cut


=item NavDisposeReply REPLY 

=cut
MacOSRet
NavDisposeReply(reply)
	NavReplyRecord reply


=item CANIT = NavServicesCanRun 

=cut
Boolean
NavServicesCanRun()


=item AVAIL = NavServicesAvailable 

=cut
Boolean
NavServicesAvailable()

=back

=cut
