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
#include <QuickTimeVR.h>

#define QTVRInterceptRecord	QTVRInterceptPtr

static pascal void PerlIntercept(
	QTVRInstance qtvr, QTVRInterceptRecord msg, SV * proc, Boolean * cancel)
{
	dSP;
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XS_XPUSH(QTVRInstance, qtvr);
	XS_XPUSH(QTVRInterceptRecord, msg);
	PUTBACK;
	
	perl_call_sv(proc, G_SCALAR);
	
	SPAGAIN;
	
	XS_POP(Boolean, *cancel);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
}

#if GENERATINGCFM
RoutineDescriptor sPerlIntercept = 
	BUILD_ROUTINE_DESCRIPTOR(uppQTVRInterceptProcInfo, PerlIntercept);
#else
#define sPerlIntercept *NewQTVRInterceptProc(PerlIntercept)
#endif

MODULE = Mac::QuickTimeVR	PACKAGE = QTVRFloatPoint

=head2 Types

=over 4

=cut

STRUCT QTVRFloatPoint
	float	x;
	float	y;

MODULE = Mac::QuickTimeVR	PACKAGE = QTVRCursorRecord

STRUCT QTVRCursorRecord
	U16		theType;
	short	rsrcID;
	Handle	handle;

MODULE = Mac::QuickTimeVR	PACKAGE = QTVRInterceptRecord

STRUCT * QTVRInterceptRecord
	long 			selector
	long 			paramCount
	float			angle
		ALIAS		*(float *)STRUCT->parameter[0]
	QTVRFloatPoint	viewCenter
		ALIAS		*(QTVRFloatPoint *)STRUCT->parameter[0]
	Point			where
		ALIAS		*(Point *)STRUCT->parameter
	U32				hotSpotID
		ALIAS		*(U32 *)STRUCT->parameter[1]
	U32				when
		ALIAS		*(U32 *)(STRUCT->parameter+1)
	U16				modifiers
		ALIAS		*(U32 *)(STRUCT->parameter+2)
	U32				mDownHotSpotID
		ALIAS		*(U32 *)STRUCT->parameter[3]
	U32				triggerHotSpotID
		ALIAS		*(U32 *)STRUCT->parameter[0]
	QTAtomContainer	nodeInfo
		ALIAS		*(QTAtomContainer *)(STRUCT->parameter+1)
	QTAtom			selectedAtom
		ALIAS		*(QTAtom *)(STRUCT->parameter+2)

MODULE = Mac::QuickTimeVR	PACKAGE = Mac::QuickTimeVR

=back

=head2 Functions

=over 4

=cut


=item QTVRGetQTVRTrack THEMOVIE, INDEX 

=cut
Track
QTVRGetQTVRTrack(theMovie, index)
	Movie	theMovie
	long	index


=item QTVRGetQTVRInstance QTVRTRACK, MC 

=cut
QTVRInstance
QTVRGetQTVRInstance(qtvrTrack, mc)
	Track			qtvrTrack
	ComponentInstance	mc
	CODE:
	if (gMacPerl_OSErr = QTVRGetQTVRInstance(&RETVAL, qtvrTrack, mc)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRSetPanAngle QTVR, PANANGLE 

=cut
MacOSRet
QTVRSetPanAngle(qtvr, panAngle)
	QTVRInstance	qtvr
	float			panAngle


=item QTVRGetPanAngle QTVR 

=cut
float
QTVRGetPanAngle(qtvr)
	QTVRInstance	qtvr


=item QTVRSetTiltAngle QTVR, TILTANGLE 

=cut
MacOSRet
QTVRSetTiltAngle(qtvr, tiltAngle)
	QTVRInstance	qtvr
	float			tiltAngle


=item QTVRGetTiltAngle QTVR 

=cut
float
QTVRGetTiltAngle(qtvr)
	QTVRInstance	qtvr


=item QTVRSetFieldOfView QTVR, FIELDOFVIEW 

=cut
MacOSRet
QTVRSetFieldOfView(qtvr, fieldOfView)
	QTVRInstance	qtvr
	float			fieldOfView


=item QTVRGetFieldOfView QTVR 

=cut
float
QTVRGetFieldOfView(qtvr)
	QTVRInstance	qtvr


=item QTVRShowDefaultView QTVR 

=cut
MacOSRet
QTVRShowDefaultView(qtvr)
	QTVRInstance	qtvr


=item QTVRSetViewCenter QTVR, VIEWCENTER 

=cut
MacOSRet
QTVRSetViewCenter(qtvr, viewCenter)
	QTVRInstance	qtvr
	QTVRFloatPoint	   &viewCenter


=item QTVRGetViewCenter QTVR 

=cut
QTVRFloatPoint
QTVRGetViewCenter(qtvr)
	QTVRInstance	qtvr
	CODE:
	if (gMacPerl_OSErr = QTVRGetViewCenter(qtvr, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRNudge QTVR, DIRECTION 

=cut
MacOSRet
QTVRNudge(qtvr, direction)
	QTVRInstance		qtvr
	QTVRNudgeControl	direction


=item QTVRGetVRWorld QTVR 

=cut
QTAtomContainer
QTVRGetVRWorld(qtvr)
	QTVRInstance	qtvr
	CODE:
	if (gMacPerl_OSErr = QTVRGetVRWorld(qtvr, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRGoToNodeID QTVR, NODEID 

=cut
MacOSRet
QTVRGoToNodeID(qtvr, nodeID)
	QTVRInstance	qtvr
	U32				nodeID


=item QTVRGetCurrentNodeID QTVR 

=cut
U32
QTVRGetCurrentNodeID(qtvr)
	QTVRInstance	qtvr


=item QTVRGetNodeType QTVR, NODEID 

=cut
OSType
QTVRGetNodeType(qtvr, nodeID)
	QTVRInstance	qtvr
	U32				nodeID


=item QTVRPtToHotSpotID QTVR, PT 

=cut
U32
QTVRPtToHotSpotID(qtvr, pt)
	QTVRInstance	qtvr
	Point			pt
	CODE:
	if (gMacPerl_OSErr = QTVRPtToHotSpotID(qtvr, pt, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRGetNodeInfo QTVR, NODEID 

=cut
QTAtomContainer
QTVRGetNodeInfo(qtvr, nodeID)
	QTVRInstance	qtvr
	U32				nodeID
	CODE:
	if (gMacPerl_OSErr = QTVRGetNodeInfo(qtvr, nodeID, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRTriggerHotSpot QTVR, HOTSPOTID, NODEINFO, SELECTEDATOM 

=cut
MacOSRet
QTVRTriggerHotSpot(qtvr, hotSpotID, nodeInfo, selectedAtom)
	QTVRInstance	qtvr
	U32			hotSpotID
	QTAtomContainer	nodeInfo
	QTAtom			selectedAtom

=begin ignore

MacOSRet
QTVRSetMouseOverHotSpotProc(qtvr, mouseOverHotSpotProc, refCon, flags)
	QTVRInstance	qtvr
	MouseOverHotSpotUPP	mouseOverHotSpotProc
	long	refCon
	U32	flags

=end ignore

=cut


=item QTVREnableHotSpot QTVR, ENABLEFLAG, HOTSPOTVALUE, ENABLE 

=cut
MacOSRet
QTVREnableHotSpot(qtvr, enableFlag, hotSpotValue, enable)
	QTVRInstance	qtvr
	U32				enableFlag
	U32				hotSpotValue
	Boolean			enable


=item QTVRGetVisibleHotSpots QTVR, HOTSPOTS 

=cut
U32
QTVRGetVisibleHotSpots(qtvr, hotSpots)
	QTVRInstance	qtvr
	Handle			hotSpots


=item QTVRGetHotSpotRegion QTVR, HOTSPOTID, HOTSPOTREGION 

=cut
MacOSRet
QTVRGetHotSpotRegion(qtvr, hotSpotID, hotSpotRegion)
	QTVRInstance	qtvr
	U32				hotSpotID
	RgnHandle		hotSpotRegion


=item QTVRSetMouseOverTracking QTVR, ENABLE 

=cut
MacOSRet
QTVRSetMouseOverTracking(qtvr, enable)
	QTVRInstance	qtvr
	Boolean			enable


=item QTVRGetMouseOverTracking QTVR 

=cut
Boolean
QTVRGetMouseOverTracking(qtvr)
	QTVRInstance	qtvr


=item QTVRSetMouseDownTracking QTVR, ENABLE 

=cut
MacOSRet
QTVRSetMouseDownTracking(qtvr, enable)
	QTVRInstance	qtvr
	Boolean			enable


=item QTVRGetMouseDownTracking QTVR 

=cut
Boolean
QTVRGetMouseDownTracking(qtvr)
	QTVRInstance	qtvr


=item QTVRMouseEnter QTVR, PT, W 

=cut
U32
QTVRMouseEnter(qtvr, pt, w)
	QTVRInstance	qtvr
	Point			pt
	GrafPtr			w
	CODE:
	if (gMacPerl_OSErr = QTVRMouseEnter(qtvr, pt, &RETVAL, w)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRMouseWithin QTVR, PT, W 

=cut
U32
QTVRMouseWithin(qtvr, pt, w)
	QTVRInstance	qtvr
	Point	pt
	GrafPtr	w
	CODE:
	if (gMacPerl_OSErr = QTVRMouseWithin(qtvr, pt, &RETVAL, w)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRMouseLeave QTVR, PT, W 

=cut
MacOSRet
QTVRMouseLeave(qtvr, pt, w)
	QTVRInstance	qtvr
	Point	pt
	GrafPtr	w


=item QTVRMouseDown QTVR, PT, WHEN, MODIFIERS, W 

=cut
U32
QTVRMouseDown(qtvr, pt, when, modifiers, w)
	QTVRInstance	qtvr
	Point	pt
	U32	when
	U16	modifiers
	GrafPtr	w
	CODE:
	if (gMacPerl_OSErr = QTVRMouseDown(qtvr, pt, when, modifiers, &RETVAL, w)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRMouseStillDown QTVR, PT, W 

=cut
U32
QTVRMouseStillDown(qtvr, pt, w)
	QTVRInstance	qtvr
	Point	pt
	GrafPtr	w
	CODE:
	if (gMacPerl_OSErr = QTVRMouseStillDown(qtvr, pt, &RETVAL, w)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRMouseUp QTVR, PT, W 

=cut
U32
QTVRMouseUp(qtvr, pt, w)
	QTVRInstance	qtvr
	Point	pt
	GrafPtr	w
	CODE:
	if (gMacPerl_OSErr = QTVRMouseUp(qtvr, pt, &RETVAL, w)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=item QTVRInstallInterceptProc QTVR, SELECTOR, PROC, FLAGS 

=cut
MacOSRet
QTVRInstallInterceptProc(qtvr, selector, interceptProc, flags=0)
	QTVRInstance		qtvr
	U32					selector
	SV*					interceptProc
	U32					flags
	CODE:
	RETVAL = 
		QTVRInstallInterceptProc(
			qtvr, selector, &sPerlIntercept, (long)newSVsv(interceptProc), flags);
	OUTPUT:
	RETVAL

=item QTVRCallInterceptedProc QTVR, MSG 

=cut
MacOSRet
QTVRCallInterceptedProc(qtvr, qtvrMsg)
	QTVRInstance		 qtvr
	QTVRInterceptRecord  qtvrMsg

=item QTVRSetFrameRate QTVR, RATE 

=cut
MacOSRet
QTVRSetFrameRate(qtvr, rate)
	QTVRInstance	qtvr
	float	rate


=item QTVRGetFrameRate QTVR 

=cut
float
QTVRGetFrameRate(qtvr)
	QTVRInstance	qtvr


=item QTVRSetViewRate QTVR, RATE 

=cut
MacOSRet
QTVRSetViewRate(qtvr, rate)
	QTVRInstance	qtvr
	float	rate


=item QTVRGetViewRate QTVR 

=cut
float
QTVRGetViewRate(qtvr)
	QTVRInstance	qtvr


=item QTVRSetViewCurrentTime QTVR, TIME 

=cut
MacOSRet
QTVRSetViewCurrentTime(qtvr, time)
	QTVRInstance	qtvr
	long	time


=item QTVRGetViewCurrentTime QTVR 

=cut
long
QTVRGetViewCurrentTime(qtvr)
	QTVRInstance	qtvr


=item QTVRGetCurrentViewDuration QTVR 

=cut
long
QTVRGetCurrentViewDuration(qtvr)
	QTVRInstance	qtvr


=item QTVRSetViewState QTVR, VIEWSTATETYPE, STATE 

=cut
MacOSRet
QTVRSetViewState(qtvr, viewStateType, state)
	QTVRInstance	qtvr
	QTVRViewStateType	viewStateType
	U16	state


=item QTVRGetViewState QTVR, VIEWSTATETYPE 

=cut
U16
QTVRGetViewState(qtvr, viewStateType)
	QTVRInstance	qtvr
	QTVRViewStateType	viewStateType
	CODE:
	if (gMacPerl_OSErr = QTVRGetViewState(qtvr, viewStateType, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRGetViewStateCount QTVR 

=cut
U16
QTVRGetViewStateCount(qtvr)
	QTVRInstance	qtvr


=item QTVRSetAnimationSetting QTVR, SETTING, ENABLE 

=cut
MacOSRet
QTVRSetAnimationSetting(qtvr, setting, enable)
	QTVRInstance	qtvr
	QTVRObjectAnimationSetting	setting
	Boolean	enable


=item QTVRGetAnimationSetting QTVR, SETTING 

=cut
Boolean
QTVRGetAnimationSetting(qtvr, setting)
	QTVRInstance	qtvr
	QTVRObjectAnimationSetting	setting
	CODE:
	if (gMacPerl_OSErr = QTVRGetAnimationSetting(qtvr, setting, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRSetControlSetting QTVR, SETTING, ENABLE 

=cut
MacOSRet
QTVRSetControlSetting(qtvr, setting, enable)
	QTVRInstance	qtvr
	QTVRControlSetting	setting
	Boolean	enable


=item QTVRGetControlSetting QTVR, SETTING, ENABLE 

=cut
Boolean
QTVRGetControlSetting(qtvr, setting)
	QTVRInstance	qtvr
	QTVRControlSetting	setting
	CODE:
	if (gMacPerl_OSErr = QTVRGetControlSetting(qtvr, setting, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVREnableFrameAnimation QTVR, ENABLE 

=cut
MacOSRet
QTVREnableFrameAnimation(qtvr, enable)
	QTVRInstance	qtvr
	Boolean	enable


=item QTVRGetFrameAnimation QTVR 

=cut
Boolean
QTVRGetFrameAnimation(qtvr)
	QTVRInstance	qtvr


=item QTVREnableViewAnimation QTVR, ENABLE 

=cut
MacOSRet
QTVREnableViewAnimation(qtvr, enable)
	QTVRInstance	qtvr
	Boolean	enable


=item QTVRGetViewAnimation QTVR 

=cut
Boolean
QTVRGetViewAnimation(qtvr)
	QTVRInstance	qtvr


=item QTVRSetVisible QTVR, VISIBLE 

=cut
MacOSRet
QTVRSetVisible(qtvr, visible)
	QTVRInstance	qtvr
	Boolean	visible


=item QTVRGetVisible QTVR 

=cut
Boolean
QTVRGetVisible(qtvr)
	QTVRInstance	qtvr


=item QTVRSetImagingProperty QTVR, IMAGINGMODE, IMAGINGPROPERTY, PROPERTYVALUE 

=cut
MacOSRet
QTVRSetImagingProperty(qtvr, imagingMode, imagingProperty, propertyValue)
	QTVRInstance	qtvr
	QTVRImagingMode	imagingMode
	U32	imagingProperty
	long	propertyValue


=item QTVRGetImagingProperty QTVR, IMAGINGMODE, IMAGINGPROPERTY 

=cut
I32
QTVRGetImagingProperty(qtvr, imagingMode, imagingProperty)
	QTVRInstance	qtvr
	QTVRImagingMode	imagingMode
	U32	imagingProperty
	CODE:
	if (gMacPerl_OSErr = QTVRGetImagingProperty(qtvr, imagingMode, imagingProperty, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRUpdate QTVR, IMAGINGMODE 

=cut
MacOSRet
QTVRUpdate(qtvr, imagingMode)
	QTVRInstance	qtvr
	QTVRImagingMode	imagingMode


=item QTVRBeginUpdateStream QTVR, IMAGINGMODE 

=cut
MacOSRet
QTVRBeginUpdateStream(qtvr, imagingMode)
	QTVRInstance	qtvr
	QTVRImagingMode	imagingMode


=item QTVREndUpdateStream QTVR 

=cut
MacOSRet
QTVREndUpdateStream(qtvr)
	QTVRInstance	qtvr


=item QTVRSetTransitionProperty QTVR, TRANSITIONTYPE, TRANSITIONPROPERTY, TRANSITIONVALUE 

=cut
MacOSRet
QTVRSetTransitionProperty(qtvr, transitionType, transitionProperty, transitionValue)
	QTVRInstance	qtvr
	U32	transitionType
	U32	transitionProperty
	long	transitionValue


=item QTVREnableTransition QTVR, TRANSITIONTYPE, ENABLE 

=cut
MacOSRet
QTVREnableTransition(qtvr, transitionType, enable)
	QTVRInstance	qtvr
	U32	transitionType
	Boolean	enable


=item QTVRSetAngularUnits QTVR, UNITS 

=cut
MacOSRet
QTVRSetAngularUnits(qtvr, units)
	QTVRInstance	qtvr
	QTVRAngularUnits	units


=item QTVRGetAngularUnits QTVR 

=cut
QTVRAngularUnits
QTVRGetAngularUnits(qtvr)
	QTVRInstance	qtvr


=item QTVRPtToAngles QTVR, PT 

	($panAngle, $tiltAngle) = QTVRPtToAngles($qtvr, $pt);

=cut
void
QTVRPtToAngles(qtvr, pt)
	QTVRInstance	qtvr
	Point	pt
	PPCODE:
	{
		float panAngle;
		float tiltAngle;
		
		if (gMacPerl_OSErr = QTVRPtToAngles(qtvr, pt, &panAngle, &tiltAngle)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(float, panAngle);
		XS_XPUSH(float, tiltAngle);
	}


=item QTVRCoordToAngles QTVR, COORD 

	($panAngle, $tiltAngle) = QTVRCoordToAngles($qtvr, $coord);

=cut
void
QTVRCoordToAngles(qtvr, coord)
	QTVRInstance	qtvr
	QTVRFloatPoint 		coord
	PPCODE:
	{
		float panAngle;
		float tiltAngle;
		
		if (gMacPerl_OSErr = QTVRCoordToAngles(qtvr, &coord, &panAngle, &tiltAngle)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(float, panAngle);
		XS_XPUSH(float, tiltAngle);
	}


=item QTVRAnglesToCoord QTVR, PANANGLE, TILTANGLE 

=cut
QTVRFloatPoint
QTVRAnglesToCoord(qtvr, panAngle, tiltAngle)
	QTVRInstance	qtvr
	float	panAngle
	float	tiltAngle
	CODE:
	if (gMacPerl_OSErr = QTVRAnglesToCoord(qtvr, panAngle, tiltAngle, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRPanToColumn QTVR, PANANGLE 

=cut
short
QTVRPanToColumn(qtvr, panAngle)
	QTVRInstance	qtvr
	float	panAngle


=item QTVRColumnToPan QTVR, COLUMN 

=cut
float
QTVRColumnToPan(qtvr, column)
	QTVRInstance	qtvr
	short	column


=item QTVRTiltToRow QTVR, TILTANGLE 

=cut
short
QTVRTiltToRow(qtvr, tiltAngle)
	QTVRInstance	qtvr
	float	tiltAngle


=item QTVRRowToTilt QTVR, ROW 

=cut
float
QTVRRowToTilt(qtvr, row)
	QTVRInstance	qtvr
	short	row


=item QTVRWrapAndConstrain QTVR, KIND, VALUE 

=cut
float
QTVRWrapAndConstrain(qtvr, kind, value)
	QTVRInstance	qtvr
	short	kind
	float	value
	CODE:
	if (gMacPerl_OSErr = QTVRWrapAndConstrain(qtvr, kind, value, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=begin ignore

MacOSRet
QTVRSetEnteringNodeProc(qtvr, enteringNodeProc, refCon, flags)
	QTVRInstance	qtvr
	EnteringNodeUPP	enteringNodeProc
	long	refCon
	U32	flags

MacOSRet
QTVRSetLeavingNodeProc(qtvr, leavingNodeProc, refCon, flags)
	QTVRInstance	qtvr
	LeavingNodeUPP	leavingNodeProc
	long	refCon
	U32	flags

=end ignore

=cut


=item QTVRSetInteractionProperty QTVR, PROPERTY, VALUE 

=cut
MacOSRet
QTVRSetInteractionProperty(qtvr, property, ...)
	QTVRInstance	qtvr
	U32	property
	CODE:
	{
		void *	val;
		U16		v_u16;
		U32		v_u32;
		Boolean	v_b;
		float	v_f;
		
		switch (property & 0x7FFFFFFF) {
		case kQTVRInteractionMouseClickHysteresis:
			XS_INPUT(U16, v_u16, ST(2));
			val = (void *) v_u16;
			break;
		case kQTVRInteractionMouseClickTimeout:
		case kQTVRInteractionPanTiltSpeed:
		case kQTVRInteractionZoomSpeed:
			XS_INPUT(U32, v_u32, ST(2));
			val = (void *) v_u32;
			break;
		case kQTVRInteractionTranslateOnMouseDown:
			XS_INPUT(Boolean, v_b, ST(2));
			val = (void *) v_b;
			break;
		case kQTVRInteractionMouseMotionScale:
			XS_INPUT(float, v_f, ST(2));
			val = &v_f;
			break;
		}
		RETVAL = QTVRSetInteractionProperty(qtvr, property, val);
	}


=item QTVRGetInteractionProperty QTVR, PROPERTY 

=cut
void
QTVRGetInteractionProperty(qtvr, property)
	QTVRInstance	qtvr
	U32	property
	PPCODE:
	{
		union v {
			U16		v_u16;
			U32		v_u32;
			Boolean	v_b;
			float	v_f;
		}		val;
		
		if (gMacPerl_OSErr = QTVRGetInteractionProperty(qtvr, property, &val)) {
			XSRETURN_UNDEF;
		}
		switch (property & 0x7FFFFFFF) {
		case kQTVRInteractionMouseClickHysteresis:
			XS_XPUSH(U16, val.v_u16);
			break;
		case kQTVRInteractionMouseClickTimeout:
		case kQTVRInteractionPanTiltSpeed:
		case kQTVRInteractionZoomSpeed:
			XS_XPUSH(U32, val.v_u32);
			break;
		case kQTVRInteractionTranslateOnMouseDown:
			XS_XPUSH(Boolean, val.v_b);
			break;
		case kQTVRInteractionMouseMotionScale:
			XS_XPUSH(float, val.v_f);
			break;
		}
	}


=item QTVRReplaceCursor QTVR, CURSRECORD 

=cut
MacOSRet
QTVRReplaceCursor(qtvr, cursRecord)
	QTVRInstance	qtvr
	QTVRCursorRecord 	&cursRecord


=item QTVRGetViewingLimits QTVR, KIND 

	($minValue, $maxValue) = QTVRGetViewingLimits($qtvr, $kind);

=cut
void
QTVRGetViewingLimits(qtvr, kind)
	QTVRInstance	qtvr
	U16	kind
	PPCODE:
	{
		float minValue;
		float maxValue;
		
		if (gMacPerl_OSErr = QTVRGetViewingLimits(qtvr, kind, &minValue, &maxValue)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(float, minValue);
		XS_XPUSH(float, maxValue);
	}


=item QTVRGetConstraintStatus QTVR 

=cut
U32
QTVRGetConstraintStatus(qtvr)
	QTVRInstance	qtvr


=item QTVRGetConstraints QTVR, KIND 

	($minValue, $maxValue) = QTVRGetConstraints($qtvr, $kind);

=cut
void
QTVRGetConstraints(qtvr, kind)
	QTVRInstance	qtvr
	U16	kind
	PPCODE:
	{
		float minValue;
		float maxValue;
		
		if (gMacPerl_OSErr = QTVRGetConstraints(qtvr, kind, &minValue, &maxValue)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(float, minValue);
		XS_XPUSH(float, maxValue);
	}


=item QTVRSetConstraints QTVR, KIND, MINVALUE, MAXVALUE 

=cut
MacOSRet
QTVRSetConstraints(qtvr, kind, minValue, maxValue)
	QTVRInstance	qtvr
	U16	kind
	float	minValue
	float	maxValue


=item QTVRGetAvailableResolutions QTVR 

=cut
U16
QTVRGetAvailableResolutions(qtvr)
	QTVRInstance	qtvr
	CODE:
	if (gMacPerl_OSErr = QTVRGetAvailableResolutions(qtvr, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL


=item QTVRGetCacheMemInfo QTVR, RESOLUTION, CACHEDEPTH 

	($minCache, $suggestedCache, $maxCache) = QTVRGetCacheMemInfo($qtvr, $res, $depth);

=cut
void
QTVRGetCacheMemInfo(qtvr, resolution, cacheDepth)
	QTVRInstance	qtvr
	U16				resolution
	short			cacheDepth
	PPCODE:
	{
		long	minCacheBytes;
		long	suggestedCacheBytes;
		long	fullCacheBytes;
		
		if (gMacPerl_OSErr = QTVRGetCacheMemInfo(qtvr, resolution, cacheDepth, &minCacheBytes, &suggestedCacheBytes, &fullCacheBytes)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(long, minCacheBytes);
		XS_XPUSH(long, suggestedCacheBytes);
		XS_XPUSH(long, fullCacheBytes);
	}


=item QTVRGetCacheSettings QTVR

	($resolution, $cacheDepth, $cacheSize) = QTVRGetCacheSettings($qtvr);

=cut
void
QTVRGetCacheSettings(qtvr)
	QTVRInstance	qtvr
	PPCODE:
	{
		U16		resolution;
		short	cacheDepth;
		short	cacheSize;
		
		if (gMacPerl_OSErr = QTVRGetCacheSettings(qtvr, &resolution, &cacheDepth, &cacheSize)) {
			XSRETURN_EMPTY;
		}
		XS_XPUSH(U16, resolution);
		XS_XPUSH(short, cacheDepth);
		XS_XPUSH(short, cacheSize);
	}


=item QTVRSetCachePrefs QTVR, RESOLUTION, CACHEDEPTH, CACHESIZE 

=cut
MacOSRet
QTVRSetCachePrefs(qtvr, resolution, cacheDepth, cacheSize)
	QTVRInstance	qtvr
	U16	resolution
	short	cacheDepth
	short	cacheSize

=begin ignore

MacOSRet
QTVRSetPrescreenImagingCompleteProc(qtvr, imagingCompleteProc, refCon, flags)
	QTVRInstance	qtvr
	ImagingCompleteUPP	imagingCompleteProc
	long	refCon
	U32	flags

MacOSRet
QTVRSetBackBufferImagingProc(qtvr, backBufferImagingProc, numAreas, areasOfInterest, refCon)
	QTVRInstance	qtvr
	BackBufferImagingUPP	backBufferImagingProc
	U16	numAreas
	AreaOfInterest *	areasOfInterest
	long	refCon

=end ignore

=cut


=item QTVRRefreshBackBuffer QTVR, FLAGS 

=cut
MacOSRet
QTVRRefreshBackBuffer(qtvr, flags)
	QTVRInstance	qtvr
	U32	flags

=back

=cut
