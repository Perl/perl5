=head1 NAME

Mac::QuickTimeVR - Macintosh Toolbox Interface to QuickTime VR

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::QuickTimeVR;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		kQTVRAPIMajorVersion
		kQTVRAPIMinorVersion
		notAQTVRMovieErr
		constraintReachedErr
		callNotSupportedByNodeErr
		selectorNotSupportedByNodeErr
		invalidNodeIDErr
		invalidViewStateErr
		timeNotInViewErr
		propertyNotSupportedByNodeErr
		settingNotSupportedByNodeErr
		limitReachedErr
		invalidNodeFormatErr
		invalidHotSpotIDErr
		noMemoryNodeFailedInitialize
		gestaltQTVRMgrAttr
		gestaltQTVRMgrVers
		gestaltQTVRMgrPresent
		gestaltQTVRObjMoviesPresent
		gestaltQTVRCylinderPanosPresent
		kQTVRControllerSubType
		kQTVRQTVRType
		kQTVRPanoramaType
		kQTVRObjectType
		kQTVROldPanoType
		kQTVROldObjectType
		kQTVRHotSpotLinkType
		kQTVRHotSpotURLType
		kQTVRHotSpotUndefinedType
		kQTVRCurrentNode
		kQTVRPreviousNode
		kQTVRDefaultNode
		kQTVRNoCorrection
		kQTVRPartialCorrection
		kQTVRFullCorrection
		kQTVRStatic
		kQTVRMotion
		kQTVRCurrentMode
		kQTVRAllModes
		kQTVRImagingCorrection
		kQTVRImagingQuality
		kQTVRImagingDirectDraw
		kQTVRImagingCurrentMode
		kImagingDefaultValue
		kQTVRTransitionSwing
		kQTVRTransitionSpeed
		kQTVRTransitionDirection
		kQTVRUnconstrained
		kQTVRCantPanLeft
		kQTVRCantPanRight
		kQTVRCantPanUp
		kQTVRCantPanDown
		kQTVRCantZoomIn
		kQTVRCantZoomOut
		kQTVRCantTranslateLeft
		kQTVRCantTranslateRight
		kQTVRCantTranslateUp
		kQTVRCantTranslateDown
		kQTVRInteractionMouseClickHysteresis
		kQTVRInteractionMouseClickTimeout
		kQTVRInteractionPanTiltSpeed
		kQTVRInteractionZoomSpeed
		kQTVRInteractionTranslateOnMouseDown
		kQTVRInteractionMouseMotionScale
		kQTVRInteractionDefaultValue
		kQTVRDefaultRes
		kQTVRFullRes
		kQTVRHalfRes
		kQTVRQuarterRes
		kQTVRMinimumCache
		kQTVRSuggestedCache
		kQTVRFullCache
		kQTVRUseMovieDepth
		kQTVRDepth16
		kQTVRDepth32
		kQTVRDegrees
		kQTVRRadians
		kQTVRHotSpotID
		kQTVRHotSpotType
		kQTVRAllHotSpots
		kQTVRPan
		kQTVRTilt
		kQTVRFieldOfView
		kQTVRViewCenterH
		kQTVRViewCenterV
		kQTVRPalindromeViewFrames
		kQTVRStartFirstViewFrame
		kQTVRDontLoopViewFrames
		kQTVRSyncViewToFrameRate
		kQTVRPalindromeViews
		kQTVRWrapPan
		kQTVRWrapTilt
		kQTVRCanZoom
		kQTVRReverseHControl
		kQTVRReverseVControl
		kQTVRSwapHVControl
		kQTVRTranslation
		kQTVRDefault
		kQTVRCurrent
		kQTVRMouseDown
		kQTVRRight
		kQTVRUpRight
		kQTVRUp
		kQTVRUpLeft
		kQTVRLeft
		kQTVRDownLeft
		kQTVRDown
		kQTVRDownRight
		mcFlagQTVRSuppressBackBtn
		mcFlagQTVRSuppressZoomBtns
		mcFlagQTVRSuppressHotSpotBtn
		mcFlagQTVRSuppressTranslateBtn
		mcFlagQTVRSuppressHelpText
		mcFlagQTVRSuppressHotSpotNames
		mcFlagQTVRExplicitFlagSet
		kQTVRUseDefaultCursor
		kQTVRStdCursorType
		kQTVRColorCursorType
		kQTVRHotSpotEnter
		kQTVRHotSpotWithin
		kQTVRHotSpotLeave
		kQTVRBackBufferEveryUpdate
		kQTVRBackBufferEveryIdle
		kQTVRBackBufferAlwaysRefresh
		kQTVRBackBufferHorizontal
		kQTVRBackBufferRectVisible
		kQTVRBackBufferWasRefreshed
		kQTVRBackBufferFlagDidDraw
		kQTVRBackBufferFlagLastFlag
		kQTVRSetPanAngleSelector
		kQTVRSetTiltAngleSelector
		kQTVRSetFieldOfViewSelector
		kQTVRSetViewCenterSelector
		kQTVRMouseEnterSelector
		kQTVRMouseWithinSelector
		kQTVRMouseLeaveSelector
		kQTVRMouseDownSelector
		kQTVRMouseStillDownSelector
		kQTVRMouseUpSelector
		kQTVRTriggerHotSpotSelector
		
		QTVRGetQTVRTrack
		QTVRGetQTVRInstance
		QTVRSetPanAngle
		QTVRGetPanAngle
		QTVRSetTiltAngle
		QTVRGetTiltAngle
		QTVRSetFieldOfView
		QTVRGetFieldOfView
		QTVRShowDefaultView
		QTVRSetViewCenter
		QTVRGetViewCenter
		QTVRNudge
		QTVRGetVRWorld
		QTVRGoToNodeID
		QTVRGetCurrentNodeID
		QTVRGetNodeType
		QTVRPtToHotSpotID
		QTVRGetNodeInfo
		QTVRTriggerHotSpot
		QTVREnableHotSpot
		QTVRGetVisibleHotSpots
		QTVRGetHotSpotRegion
		QTVRSetMouseOverTracking
		QTVRGetMouseOverTracking
		QTVRSetMouseDownTracking
		QTVRGetMouseDownTracking
		QTVRMouseEnter
		QTVRMouseWithin
		QTVRMouseLeave
		QTVRMouseDown
		QTVRMouseStillDown
		QTVRMouseUp
		QTVRInstallInterceptProc
		QTVRCallInterceptedProc
		QTVRSetFrameRate
		QTVRGetFrameRate
		QTVRSetViewRate
		QTVRGetViewRate
		QTVRSetViewCurrentTime
		QTVRGetViewCurrentTime
		QTVRGetCurrentViewDuration
		QTVRSetViewState
		QTVRGetViewState
		QTVRGetViewStateCount
		QTVRSetAnimationSetting
		QTVRGetAnimationSetting
		QTVRSetControlSetting
		QTVRGetControlSetting
		QTVREnableFrameAnimation
		QTVRGetFrameAnimation
		QTVREnableViewAnimation
		QTVRGetViewAnimation
		QTVRSetVisible
		QTVRGetVisible
		QTVRSetImagingProperty
		QTVRGetImagingProperty
		QTVRUpdate
		QTVRBeginUpdateStream
		QTVREndUpdateStream
		QTVRSetTransitionProperty
		QTVREnableTransition
		QTVRSetAngularUnits
		QTVRGetAngularUnits
		QTVRPtToAngles
		QTVRCoordToAngles
		QTVRAnglesToCoord
		QTVRPanToColumn
		QTVRColumnToPan
		QTVRTiltToRow
		QTVRRowToTilt
		QTVRWrapAndConstrain
		QTVRSetInteractionProperty
		QTVRGetInteractionProperty
		QTVRReplaceCursor
		QTVRGetViewingLimits
		QTVRGetConstraintStatus
		QTVRGetConstraints
		QTVRSetConstraints
		QTVRGetAvailableResolutions
		QTVRGetCacheMemInfo
		QTVRGetCacheSettings
		QTVRSetCachePrefs
		QTVRRefreshBackBuffer
	);
}

bootstrap Mac::QuickTimeVR;

=head2 Constants

=over 4

=item kQTVRAPIMajorVersion

=item kQTVRAPIMinorVersion

=cut
sub kQTVRAPIMajorVersion ()        {        (2); }
sub kQTVRAPIMinorVersion ()        {        (0); }


=item notAQTVRMovieErr

=item constraintReachedErr

=item callNotSupportedByNodeErr

=item selectorNotSupportedByNodeErr

=item invalidNodeIDErr

=item invalidViewStateErr

=item timeNotInViewErr

=item propertyNotSupportedByNodeErr

=item settingNotSupportedByNodeErr

=item limitReachedErr

=item invalidNodeFormatErr

=item invalidHotSpotIDErr

=item noMemoryNodeFailedInitialize

=cut
sub notAQTVRMovieErr ()            {     -30540; }
sub constraintReachedErr ()        {     -30541; }
sub callNotSupportedByNodeErr ()   {     -30542; }
sub selectorNotSupportedByNodeErr () {     -30543; }
sub invalidNodeIDErr ()            {     -30544; }
sub invalidViewStateErr ()         {     -30545; }
sub timeNotInViewErr ()            {     -30546; }
sub propertyNotSupportedByNodeErr () {     -30547; }
sub settingNotSupportedByNodeErr () {     -30548; }
sub limitReachedErr ()             {     -30549; }
sub invalidNodeFormatErr ()        {     -30550; }
sub invalidHotSpotIDErr ()         {     -30551; }
sub noMemoryNodeFailedInitialize () {     -30552; }


=item gestaltQTVRMgrAttr

=item gestaltQTVRMgrVers

=item gestaltQTVRMgrPresent

=item gestaltQTVRObjMoviesPresent

=item gestaltQTVRCylinderPanosPresent

=cut
sub gestaltQTVRMgrAttr ()          {     'qtvr'; }
sub gestaltQTVRMgrVers ()          {     'qtvv'; }
sub gestaltQTVRMgrPresent ()       {          0; }
sub gestaltQTVRObjMoviesPresent () {          1; }
sub gestaltQTVRCylinderPanosPresent () {          2; }


=item kQTVRControllerSubType

=item kQTVRQTVRType

=item kQTVRPanoramaType

=item kQTVRObjectType

=item kQTVROldPanoType

=item kQTVROldObjectType

=item kQTVRHotSpotLinkType

=item kQTVRHotSpotURLType

=item kQTVRHotSpotUndefinedType

=cut
sub kQTVRControllerSubType ()      {     'ctyp'; }
sub kQTVRQTVRType ()               {     'qtvr'; }
sub kQTVRPanoramaType ()           {     'pano'; }
sub kQTVRObjectType ()             {     'obje'; }
sub kQTVROldPanoType ()            {     'STpn'; }
sub kQTVROldObjectType ()          {     'stna'; }
sub kQTVRHotSpotLinkType ()        {     'link'; }
sub kQTVRHotSpotURLType ()         {     'url '; }
sub kQTVRHotSpotUndefinedType ()   {     'undf'; }


=item kQTVRCurrentNode

=item kQTVRPreviousNode

=item kQTVRDefaultNode

=cut
sub kQTVRCurrentNode ()            {          0; }
sub kQTVRPreviousNode ()           { 0x80000000; }
sub kQTVRDefaultNode ()            { 0x80000001; }


=item kQTVRNoCorrection

=item kQTVRPartialCorrection

=item kQTVRFullCorrection

=cut
sub kQTVRNoCorrection ()           {          0; }
sub kQTVRPartialCorrection ()      {          1; }
sub kQTVRFullCorrection ()         {          2; }


=item kQTVRStatic

=item kQTVRMotion

=item kQTVRCurrentMode

=item kQTVRAllModes

=cut
sub kQTVRStatic ()                 {          1; }
sub kQTVRMotion ()                 {          2; }
sub kQTVRCurrentMode ()            {          0; }
sub kQTVRAllModes ()               {        100; }


=item kQTVRImagingCorrection

=item kQTVRImagingQuality

=item kQTVRImagingDirectDraw

=item kQTVRImagingCurrentMode

=item kImagingDefaultValue

=cut
sub kQTVRImagingCorrection ()      {          1; }
sub kQTVRImagingQuality ()         {          2; }
sub kQTVRImagingDirectDraw ()      {          3; }
sub kQTVRImagingCurrentMode ()     {        100; }
sub kImagingDefaultValue ()        { 0x80000000; }


=item kQTVRTransitionSwing

=item kQTVRTransitionSpeed

=item kQTVRTransitionDirection

=cut
sub kQTVRTransitionSwing ()        {          1; }
sub kQTVRTransitionSpeed ()        {          1; }
sub kQTVRTransitionDirection ()    {          2; }


=item kQTVRUnconstrained

=item kQTVRCantPanLeft

=item kQTVRCantPanRight

=item kQTVRCantPanUp

=item kQTVRCantPanDown

=item kQTVRCantZoomIn

=item kQTVRCantZoomOut

=item kQTVRCantTranslateLeft

=item kQTVRCantTranslateRight

=item kQTVRCantTranslateUp

=item kQTVRCantTranslateDown

=cut
sub kQTVRUnconstrained ()          {          0; }
sub kQTVRCantPanLeft ()            {     1 << 0; }
sub kQTVRCantPanRight ()           {     1 << 1; }
sub kQTVRCantPanUp ()              {     1 << 2; }
sub kQTVRCantPanDown ()            {     1 << 3; }
sub kQTVRCantZoomIn ()             {     1 << 4; }
sub kQTVRCantZoomOut ()            {     1 << 5; }
sub kQTVRCantTranslateLeft ()      {     1 << 6; }
sub kQTVRCantTranslateRight ()     {     1 << 7; }
sub kQTVRCantTranslateUp ()        {     1 << 8; }
sub kQTVRCantTranslateDown ()      {     1 << 9; }


=item kQTVRInteractionMouseClickHysteresis

=item kQTVRInteractionMouseClickTimeout

=item kQTVRInteractionPanTiltSpeed

=item kQTVRInteractionZoomSpeed

=item kQTVRInteractionTranslateOnMouseDown

=item kQTVRInteractionMouseMotionScale

=item kQTVRInteractionDefaultValue

=cut
sub kQTVRInteractionMouseClickHysteresis () {          1; }
sub kQTVRInteractionMouseClickTimeout () {          2; }
sub kQTVRInteractionPanTiltSpeed () {          3; }
sub kQTVRInteractionZoomSpeed ()   {          4; }
sub kQTVRInteractionTranslateOnMouseDown () {        101; }
sub kQTVRInteractionMouseMotionScale () {        102; }
sub kQTVRInteractionDefaultValue () { 0x80000000; }


=item kQTVRDefaultRes

=item kQTVRFullRes

=item kQTVRHalfRes

=item kQTVRQuarterRes

=cut
sub kQTVRDefaultRes ()             {          0; }
sub kQTVRFullRes ()                {     1 << 0; }
sub kQTVRHalfRes ()                {     1 << 1; }
sub kQTVRQuarterRes ()             {     1 << 2; }


=item kQTVRMinimumCache

=item kQTVRSuggestedCache

=item kQTVRFullCache

=cut
sub kQTVRMinimumCache ()           {         -1; }
sub kQTVRSuggestedCache ()         {          0; }
sub kQTVRFullCache ()              {          1; }


=item kQTVRUseMovieDepth

=item kQTVRDepth16

=item kQTVRDepth32

=cut
sub kQTVRUseMovieDepth ()          {          0; }
sub kQTVRDepth16 ()                {         16; }
sub kQTVRDepth32 ()                {         32; }


=item kQTVRDegrees

=item kQTVRRadians

=cut
sub kQTVRDegrees ()                {          0; }
sub kQTVRRadians ()                {          1; }


=item kQTVRHotSpotID

=item kQTVRHotSpotType

=item kQTVRAllHotSpots

=cut
sub kQTVRHotSpotID ()              {          0; }
sub kQTVRHotSpotType ()            {          1; }
sub kQTVRAllHotSpots ()            {          2; }


=item kQTVRPan

=item kQTVRTilt

=item kQTVRFieldOfView

=item kQTVRViewCenterH

=item kQTVRViewCenterV

=cut
sub kQTVRPan ()                    {          0; }
sub kQTVRTilt ()                   {          1; }
sub kQTVRFieldOfView ()            {          2; }
sub kQTVRViewCenterH ()            {          4; }
sub kQTVRViewCenterV ()            {          5; }


=item kQTVRPalindromeViewFrames

=item kQTVRStartFirstViewFrame

=item kQTVRDontLoopViewFrames

=item kQTVRSyncViewToFrameRate

=item kQTVRPalindromeViews

=cut
sub kQTVRPalindromeViewFrames ()   {          1; }
sub kQTVRStartFirstViewFrame ()    {          2; }
sub kQTVRDontLoopViewFrames ()     {          3; }
sub kQTVRSyncViewToFrameRate ()    {         16; }
sub kQTVRPalindromeViews ()        {         17; }


=item kQTVRWrapPan

=item kQTVRWrapTilt

=item kQTVRCanZoom

=item kQTVRReverseHControl

=item kQTVRReverseVControl

=item kQTVRSwapHVControl

=item kQTVRTranslation

=cut
sub kQTVRWrapPan ()                {          1; }
sub kQTVRWrapTilt ()               {          2; }
sub kQTVRCanZoom ()                {          3; }
sub kQTVRReverseHControl ()        {          4; }
sub kQTVRReverseVControl ()        {          5; }
sub kQTVRSwapHVControl ()          {          6; }
sub kQTVRTranslation ()            {          7; }


=item kQTVRDefault

=item kQTVRCurrent

=item kQTVRMouseDown

=item kQTVRRight

=item kQTVRUpRight

=item kQTVRUp

=item kQTVRUpLeft

=item kQTVRLeft

=item kQTVRDownLeft

=item kQTVRDown

=item kQTVRDownRight

=cut
sub kQTVRDefault ()                {          0; }
sub kQTVRCurrent ()                {          2; }
sub kQTVRMouseDown ()              {          3; }
sub kQTVRRight ()                  {          0; }
sub kQTVRUpRight ()                {         45; }
sub kQTVRUp ()                     {         90; }
sub kQTVRUpLeft ()                 {        135; }
sub kQTVRLeft ()                   {        180; }
sub kQTVRDownLeft ()               {        225; }
sub kQTVRDown ()                   {        270; }
sub kQTVRDownRight ()              {        315; }


=item mcFlagQTVRSuppressBackBtn

=item mcFlagQTVRSuppressZoomBtns

=item mcFlagQTVRSuppressHotSpotBtn

=item mcFlagQTVRSuppressTranslateBtn

=item mcFlagQTVRSuppressHelpText

=item mcFlagQTVRSuppressHotSpotNames

=item mcFlagQTVRExplicitFlagSet

=cut
sub mcFlagQTVRSuppressBackBtn ()   {    1 << 16; }
sub mcFlagQTVRSuppressZoomBtns ()  {    1 << 17; }
sub mcFlagQTVRSuppressHotSpotBtn () {    1 << 18; }
sub mcFlagQTVRSuppressTranslateBtn () {    1 << 19; }
sub mcFlagQTVRSuppressHelpText ()  {    1 << 20; }
sub mcFlagQTVRSuppressHotSpotNames () {    1 << 21; }
sub mcFlagQTVRExplicitFlagSet ()   {    1 << 31; }


=item kQTVRUseDefaultCursor

=item kQTVRStdCursorType

=item kQTVRColorCursorType

=cut
sub kQTVRUseDefaultCursor ()       {          0; }
sub kQTVRStdCursorType ()          {          1; }
sub kQTVRColorCursorType ()        {          2; }


=item kQTVRHotSpotEnter

=item kQTVRHotSpotWithin

=item kQTVRHotSpotLeave

=cut
sub kQTVRHotSpotEnter ()           {          0; }
sub kQTVRHotSpotWithin ()          {          1; }
sub kQTVRHotSpotLeave ()           {          2; }


=item kQTVRBackBufferEveryUpdate

=item kQTVRBackBufferEveryIdle

=item kQTVRBackBufferAlwaysRefresh

=item kQTVRBackBufferHorizontal

=item kQTVRBackBufferRectVisible

=item kQTVRBackBufferWasRefreshed

=cut
sub kQTVRBackBufferEveryUpdate ()  {     1 << 0; }
sub kQTVRBackBufferEveryIdle ()    {     1 << 1; }
sub kQTVRBackBufferAlwaysRefresh () {     1 << 2; }
sub kQTVRBackBufferHorizontal ()   {     1 << 3; }
sub kQTVRBackBufferRectVisible ()  {     1 << 0; }
sub kQTVRBackBufferWasRefreshed () {     1 << 1; }


=item kQTVRBackBufferFlagDidDraw

=item kQTVRBackBufferFlagLastFlag

=cut
sub kQTVRBackBufferFlagDidDraw ()  {     1 << 0; }
sub kQTVRBackBufferFlagLastFlag () {    1 << 31; }

sub kQTVRSetPanAngleSelector ()    {     0x2000; }
sub kQTVRSetTiltAngleSelector ()   {     0x2001; }
sub kQTVRSetFieldOfViewSelector () {     0x2002; }
sub kQTVRSetViewCenterSelector ()  {     0x2003; }
sub kQTVRMouseEnterSelector ()     {     0x2004; }
sub kQTVRMouseWithinSelector ()    {     0x2005; }
sub kQTVRMouseLeaveSelector ()     {     0x2006; }
sub kQTVRMouseDownSelector ()      {     0x2007; }
sub kQTVRMouseStillDownSelector () {     0x2008; }
sub kQTVRMouseUpSelector ()        {     0x2009; }
sub kQTVRTriggerHotSpotSelector () {     0x200A; }

=back

=include QuickTimeVR.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
