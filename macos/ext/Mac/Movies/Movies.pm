=head1 NAME

Mac::Movies - Macintosh Toolbox Interface to QuickTime.

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Movies;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT %ActionFilter);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		EnterMovies
		ExitMovies
		GetMoviesError
		ClearMoviesStickyError
		GetMoviesStickyError
		MoviesTask
		PrerollMovie
		LoadMovieIntoRam
		LoadTrackIntoRam
		LoadMediaIntoRam
		SetMovieActive
		GetMovieActive
		StartMovie
		StopMovie
		GoToBeginningOfMovie
		GoToEndOfMovie
		IsMovieDone
		GetMoviePreviewMode
		SetMoviePreviewMode
		ShowMoviePoster
		PlayMoviePreview
		GetMovieTimeBase
		SetMovieMasterTimeBase
		SetMovieMasterClock
		GetMovieGWorld
		SetMovieGWorld
		GetMovieNaturalBoundsRect
		GetNextTrackForCompositing
		GetPrevTrackForCompositing
		GetMoviePict
		GetTrackPict
		GetMoviePosterPict
		UpdateMovie
		GetMovieBox
		SetMovieBox
		GetMovieDisplayClipRgn
		SetMovieDisplayClipRgn
		GetMovieClipRgn
		SetMovieClipRgn
		GetTrackClipRgn
		SetTrackClipRgn
		GetMovieDisplayBoundsRgn
		GetTrackDisplayBoundsRgn
		GetMovieBoundsRgn
		GetTrackMovieBoundsRgn
		GetTrackBoundsRgn
		GetTrackMatte
		SetTrackMatte
		DisposeMatte
		NewMovie
		PutMovieIntoHandle
		DisposeMovie
		GetMovieCreationTime
		GetMovieModificationTime
		GetMovieTimeScale
		SetMovieTimeScale
		GetMovieDuration
		GetMovieRate
		SetMovieRate
		GetMoviePreferredRate
		SetMoviePreferredRate
		GetMoviePreferredVolume
		SetMoviePreferredVolume
		GetMovieVolume
		SetMovieVolume
		GetMovieMatrix
		SetMovieMatrix
		GetMoviePreviewTime
		SetMoviePreviewTime
		GetMoviePosterTime
		SetMoviePosterTime
		GetMovieSelection
		SetMovieSelection
		SetMovieActiveSegment
		GetMovieActiveSegment
		GetMovieTime
		SetMovieTime
		SetMovieTimeValue
		GetMovieUserData
		GetMovieTrackCount
		GetMovieTrack
		GetMovieIndTrack
		GetMovieIndTrackType
		GetTrackID
		GetTrackMovie
		NewMovieTrack
		DisposeMovieTrack
		GetTrackCreationTime
		GetTrackModificationTime
		GetTrackEnabled
		SetTrackEnabled
		GetTrackUsage
		SetTrackUsage
		GetTrackDuration
		GetTrackOffset
		SetTrackOffset
		GetTrackLayer
		SetTrackLayer
		GetTrackAlternate
		SetTrackAlternate
		SetAutoTrackAlternatesEnabled
		SelectMovieAlternates
		GetTrackVolume
		SetTrackVolume
		GetTrackMatrix
		SetTrackMatrix
		GetTrackDimensions
		SetTrackDimensions
		GetTrackUserData
		NewTrackMedia
		DisposeTrackMedia
		GetTrackMedia
		GetMediaTrack
		GetMediaCreationTime
		GetMediaModificationTime
		GetMediaTimeScale
		SetMediaTimeScale
		GetMediaDuration
		GetMediaLanguage
		SetMediaLanguage
		GetMediaQuality
		SetMediaQuality
		GetMediaHandlerDescription
		GetMediaUserData
		BeginMediaEdits
		EndMediaEdits
		SetMediaDefaultDataRefIndex
		GetMediaDataHandlerDescription
		GetMediaSampleDescriptionCount
		GetMediaSampleDescription
		SetMediaSampleDescription
		GetMediaSampleCount
		SampleNumToMediaTime
		MediaTimeToSampleNum
		AddMediaSample
		AddMediaSampleReference
		CutMovieSelection
		CopyMovieSelection
		PasteMovieSelection
		AddMovieSelection
		ClearMovieSelection
		PasteHandleIntoMovie
		PutMovieIntoTypedHandle
		IsScrapMovie
		CopyTrackSettings
		CopyMovieSettings
		AddEmptyTrackToMovie
		NewMovieEditState
		UseMovieEditState
		DisposeMovieEditState
		NewTrackEditState
		UseTrackEditState
		DisposeTrackEditState
		AddTrackReference
		DeleteTrackReference
		SetTrackReference
		GetTrackReference
		GetNextTrackReferenceType
		GetTrackReferenceCount
		ConvertFileToMovieFile
		ConvertMovieToFile
		TrackTimeToMediaTime
		GetTrackEditRate
		GetMovieDataSize
		GetTrackDataSize
		GetMediaDataSize
		PtInMovie
		PtInTrack
		SetMovieLanguage
		GetUserData
		AddUserData
		RemoveUserData
		CountUserDataType
		GetNextUserDataType
		AddUserDataText
		GetUserDataText
		RemoveUserDataText
		NewUserData
		DisposeUserData
		NewUserDataFromHandle
		PutUserDataIntoHandle
		GetMediaNextInterestingTime
		GetTrackNextInterestingTime
		GetMovieNextInterestingTime
		CreateMovieFile
		OpenMovieFile
		CloseMovieFile
		DeleteMovieFile
		NewMovieFromFile
		NewMovieFromHandle
		NewMovieFromDataFork
		AddMovieResource
		UpdateMovieResource
		RemoveMovieResource
		HasMovieChanged
		ClearMovieChanged
		FlattenMovie
		FlattenMovieData
		GetPosterBox
		SetPosterBox
		GetMovieSegmentDisplayBoundsRgn
		GetTrackSegmentDisplayBoundsRgn
		GetTrackStatus
		GetMovieStatus
		NewMovieController
		DisposeMovieController
		PutMovieOnScrap
		NewMovieFromScrap
		SetMoviePlayHints
		SetMediaPlayHints
		SetTrackLoadSettings
		GetTrackLoadSettings
		NewTimeBase
		DisposeTimeBase
		GetTimeBaseTime
		SetTimeBaseTime
		SetTimeBaseValue
		GetTimeBaseRate
		SetTimeBaseRate
		GetTimeBaseStartTime
		SetTimeBaseStartTime
		GetTimeBaseStopTime
		SetTimeBaseStopTime
		GetTimeBaseFlags
		SetTimeBaseFlags
		SetTimeBaseMasterTimeBase
		GetTimeBaseMasterTimeBase
		SetTimeBaseMasterClock
		GetTimeBaseMasterClock
		ConvertTime
		ConvertTimeScale
		AddTime
		SubtractTime
		GetTimeBaseStatus
		SetTimeBaseZero
		GetTimeBaseEffectiveRate
		MCSetMovie
		MCGetMovie
		MCGetIndMovie
		MCRemoveMovie
		MCIsPlayerEvent
		MCDoAction
		MCSetControllerAttached
		MCIsControllerAttached
		MCSetControllerPort
		MCGetControllerPort
		MCSetVisible
		MCGetVisible
		MCGetControllerBoundsRect
		MCSetControllerBoundsRect
		MCGetControllerBoundsRgn
		MCGetWindowRgn
		MCMovieChanged
		MCSetDuration
		MCGetCurrentTime
		MCNewAttachedController
		MCDraw
		MCActivate
		MCIdle
		MCKey
		MCClick
		MCEnableEditing
		MCIsEditingEnabled
		MCCopy
		MCCut
		MCPaste
		MCClear
		MCUndo
		MCPositionController
		MCGetControllerInfo
		MCSetClip
		MCGetClip
		MCDrawBadge
		MCSetUpEditMenu
		MCGetMenuString
		MCSetActionFilter
		MCPtInController
		MCInvalidate
	
		MovieFileType
		MediaHandlerType
		DataHandlerType
		VideoMediaType
		SoundMediaType
		TextMediaType
		BaseMediaType
		MPEGMediaType
		MusicMediaType
		TimeCodeMediaType
		SpriteMediaType
		TweenMediaType
		ThreeDeeMediaType
		HandleDataHandlerSubType
		ResourceDataHandlerSubType
		VisualMediaCharacteristic
		AudioMediaCharacteristic
		kCharacteristicCanSendVideo
		DoTheRightThing
		kMusicFlagDontPlay2Soft
		dfDontDisplay
		dfDontAutoScale
		dfClipToTextBox
		dfUseMovieBGColor
		dfShrinkTextBoxToFit
		dfScrollIn
		dfScrollOut
		dfHorizScroll
		dfReverseScroll
		dfContinuousScroll
		dfFlowHoriz
		dfContinuousKaraoke
		dfDropShadow
		dfAntiAlias
		dfKeyedText
		dfInverseHilite
		dfTextColorHilite
		searchTextDontGoToFoundTime
		searchTextDontHiliteFoundText
		searchTextOneTrackOnly
		searchTextEnabledTracksOnly
		k3DMediaRendererEntry
		k3DMediaRendererName
		k3DMediaRendererCode
		movieProgressOpen
		movieProgressUpdatePercent
		movieProgressClose
		progressOpFlatten
		progressOpInsertTrackSegment
		progressOpInsertMovieSegment
		progressOpPaste
		progressOpAddMovieSelection
		progressOpCopy
		progressOpCut
		progressOpLoadMovieIntoRam
		progressOpLoadTrackIntoRam
		progressOpLoadMediaIntoRam
		progressOpImportMovie
		progressOpExportMovie
		mediaQualityDraft
		mediaQualityNormal
		mediaQualityBetter
		mediaQualityBest
		loopTimeBase
		palindromeLoopTimeBase
		maintainTimeBaseZero
		triggerTimeFwd
		triggerTimeBwd
		triggerTimeEither
		triggerRateLT
		triggerRateGT
		triggerRateEqual
		triggerRateLTE
		triggerRateGTE
		triggerRateNotEqual
		triggerRateChange
		triggerAtStart
		triggerAtStop
		timeBaseBeforeStartTime
		timeBaseAfterStopTime
		callBackAtTime
		callBackAtRate
		callBackAtTimeJump
		callBackAtExtremes
		callBackAtInterrupt
		callBackAtDeferredTask
		qtcbNeedsRateChanges
		qtcbNeedsTimeChanges
		qtcbNeedsStartStopChanges
		keepInRam
		unkeepInRam
		flushFromRam
		loadForwardTrackEdits
		loadBackwardTrackEdits
		newMovieActive
		newMovieDontResolveDataRefs
		newMovieDontAskUnresolvedDataRefs
		newMovieDontAutoAlternates
		newMovieDontUpdateForeBackPointers
		trackUsageInMovie
		trackUsageInPreview
		trackUsageInPoster
		mediaSampleNotSync
		mediaSampleShadowSync
		pasteInParallel
		showUserSettingsDialog
		movieToFileOnlyExport
		movieFileSpecValid
		nextTimeMediaSample
		nextTimeMediaEdit
		nextTimeTrackEdit
		nextTimeSyncSample
		nextTimeStep
		nextTimeEdgeOK
		nextTimeIgnoreActiveSegment
		createMovieFileDeleteCurFile
		createMovieFileDontCreateMovie
		createMovieFileDontOpenFile
		flattenAddMovieToDataFork
		flattenActiveTracksOnly
		flattenDontInterleaveFlatten
		flattenFSSpecPtrIsDataRefRecordPtr
		movieInDataForkResID
		mcTopLeftMovie
		mcScaleMovieToFit
		mcWithBadge
		mcNotVisible
		mcWithFrame
		movieScrapDontZeroScrap
		movieScrapOnlyPutMovie
		dataRefSelfReference
		dataRefWasNotResolved
		hintsScrubMode
		hintsLoop
		hintsDontPurge
		hintsUseScreenBuffer
		hintsAllowInterlace
		hintsUseSoundInterp
		hintsHighQuality
		hintsPalindrome
		hintsInactive
		mediaHandlerFlagBaseClient
		movieTrackMediaType
		movieTrackCharacteristic
		movieTrackEnabledOnly
		movieDrawingCallWhenChanged
		movieDrawingCallAlways
		preloadAlways
		preloadOnlyIfEnabled
		fullScreenHideCursor
		fullScreenAllowEvents
		fullScreenDontChangeMenuBar
		fullScreenPreflightSize
		kBackgroundSpriteLayerNum
		kSpritePropertyMatrix
		kSpritePropertyImageDescription
		kSpritePropertyImageDataPtr
		kSpritePropertyVisible
		kSpritePropertyLayer
		kSpritePropertyGraphicsMode
		kSpritePropertyImageIndex
		kSpriteTrackPropertyBackgroundColor
		kSpriteTrackPropertyOffscreenBitDepth
		kSpriteTrackPropertySampleFormat
		kOnlyDrawToSpriteWorld
		kSpriteWorldPreflight
		kSpriteWorldDidDraw
		kSpriteWorldNeedsToDraw
		kKeyFrameAndSingleOverride
		kKeyFrameAndAllOverrides
		kParentAtomIsContainer
		kITextRemoveEverythingBut
		kITextRemoveLeaveSuggestedAlternate
		kITextAtomType
		kITextStringAtomType
		kTrackModifierInput
		kTrackModifierType
		kTrackModifierReference
		kTrackModifierObjectID
		kTrackModifierInputName
		kInputMapSubInputID
		kTrackModifierTypeMatrix
		kTrackModifierTypeClip
		kTrackModifierTypeGraphicsMode
		kTrackModifierTypeVolume
		kTrackModifierTypeBalance
		kTrackModifierTypeSpriteImage
		kTrackModifierObjectMatrix
		kTrackModifierObjectGraphicsMode
		kTrackModifierType3d4x4Matrix
		kTrackModifierCameraData
		kTrackModifierSoundLocalizationData
		kTweenTypeShort
		kTweenTypeLong
		kTweenTypeFixed
		kTweenTypePoint
		kTweenTypeQDRect
		kTweenTypeQDRegion
		kTweenTypeMatrix
		kTweenTypeRGBColor
		kTweenTypeGraphicsModeWithRGBColor
		kTweenType3dScale
		kTweenType3dTranslate
		kTweenType3dRotate
		kTweenType3dRotateAboutPoint
		kTweenType3dRotateAboutAxis
		kTweenType3dQuaternion
		kTweenType3dMatrix
		kTweenType3dCameraData
		kTweenType3dSoundLocalizationData
		kTweenEntry
		kTweenData
		kTweenType
		kTweenStartOffset
		kTweenDuration
		kTween3dInitialCondition
		kTweenInterpolationStyle
		kTweenRegionData
		kTweenPictureData
		internalComponentErr
		notImplementedMusicOSErr
		cantSendToSynthesizerOSErr
		cantReceiveFromSynthesizerOSErr
		illegalVoiceAllocationOSErr
		illegalPartOSErr
		illegalChannelOSErr
		illegalKnobOSErr
		illegalKnobValueOSErr
		illegalInstrumentOSErr
		illegalControllerOSErr
		midiManagerAbsentOSErr
		synthesizerNotRespondingOSErr
		synthesizerOSErr
		illegalNoteChannelOSErr
		noteChannelNotAllocatedOSErr
		tunePlayerFullOSErr
		tuneParseOSErr
		videoFlagDontLeanAhead
		txtProcDefaultDisplay
		txtProcDontDisplay
		txtProcDoDisplay
		findTextEdgeOK
		findTextCaseSensitive
		findTextReverseSearch
		findTextWrapAround
		findTextUseOffset
		dropShadowOffsetType
		dropShadowTranslucencyType
		spriteHitTestBounds
		spriteHitTestImage
		kSpriteAtomType
		kSpriteImagesContainerAtomType
		kSpriteImageAtomType
		kSpriteImageDataAtomType
		kSpriteSharedDataAtomType
		kSpriteNameAtomType
		MovieControllerComponentType
		mcActionIdle
		mcActionDraw
		mcActionActivate
		mcActionDeactivate
		mcActionMouseDown
		mcActionKey
		mcActionPlay
		mcActionGoToTime
		mcActionSetVolume
		mcActionGetVolume
		mcActionStep
		mcActionSetLooping
		mcActionGetLooping
		mcActionSetLoopIsPalindrome
		mcActionGetLoopIsPalindrome
		mcActionSetGrowBoxBounds
		mcActionControllerSizeChanged
		mcActionSetSelectionBegin
		mcActionSetSelectionDuration
		mcActionSetKeysEnabled
		mcActionGetKeysEnabled
		mcActionSetPlaySelection
		mcActionGetPlaySelection
		mcActionSetUseBadge
		mcActionGetUseBadge
		mcActionSetFlags
		mcActionGetFlags
		mcActionSetPlayEveryFrame
		mcActionGetPlayEveryFrame
		mcActionGetPlayRate
		mcActionShowBalloon
		mcActionBadgeClick
		mcActionMovieClick
		mcActionSuspend
		mcActionResume
		mcActionSetControllerKeysEnabled
		mcActionGetTimeSliderRect
		mcActionMovieEdited
		mcActionGetDragEnabled
		mcActionSetDragEnabled
		mcActionGetSelectionBegin
		mcActionGetSelectionDuration
		mcActionPrerollAndPlay
		mcActionGetCursorSettingEnabled
		mcActionSetCursorSettingEnabled
		mcActionSetColorTable
		mcFlagSuppressMovieFrame
		mcFlagSuppressStepButtons
		mcFlagSuppressSpeakerButton
		mcFlagsUseWindowPalette
		mcFlagsDontInvalidate
		mcPositionDontInvalidate
		mcInfoUndoAvailable
		mcInfoCutAvailable
		mcInfoCopyAvailable
		mcInfoPasteAvailable
		mcInfoClearAvailable
		mcInfoHasSound
		mcInfoIsPlaying
		mcInfoIsLooping
		mcInfoIsInPalindrome
		mcInfoEditingEnabled
		mcInfoMovieIsInteractive
		mcMenuUndo
		mcMenuCut
		mcMenuCopy
		mcMenuPaste
		mcMenuClear
	);
}

bootstrap Mac::Movies;

=head2 Constants

=over 4

=item MovieFileType

=item MediaHandlerType

=item DataHandlerType

=item VideoMediaType

=item SoundMediaType

=item TextMediaType

=item BaseMediaType

=item MPEGMediaType

=item MusicMediaType

=item TimeCodeMediaType

=item SpriteMediaType

=item TweenMediaType

=item ThreeDeeMediaType

=item HandleDataHandlerSubType

=item ResourceDataHandlerSubType

=item VisualMediaCharacteristic

=item AudioMediaCharacteristic

=item kCharacteristicCanSendVideo

=cut
sub MovieFileType ()               {     'MooV'; }
sub MediaHandlerType ()            {     'mhlr'; }
sub DataHandlerType ()             {     'dhlr'; }
sub VideoMediaType ()              {     'vide'; }
sub SoundMediaType ()              {     'soun'; }
sub TextMediaType ()               {     'text'; }
sub BaseMediaType ()               {     'gnrc'; }
sub MPEGMediaType ()               {     'MPEG'; }
sub MusicMediaType ()              {     'musi'; }
sub TimeCodeMediaType ()           {     'tmcd'; }
sub SpriteMediaType ()             {     'sprt'; }
sub TweenMediaType ()              {     'twen'; }
sub ThreeDeeMediaType ()           {     'qd3d'; }
sub HandleDataHandlerSubType ()    {     'hndl'; }
sub ResourceDataHandlerSubType ()  {     'rsrc'; }
sub VisualMediaCharacteristic ()   {     'eyes'; }
sub AudioMediaCharacteristic ()    {     'ears'; }
sub kCharacteristicCanSendVideo () {     'vsnd'; }


=item DoTheRightThing

=item kMusicFlagDontPlay2Soft

=cut
sub DoTheRightThing ()             {          0; }
sub kMusicFlagDontPlay2Soft ()     {    1 << 0; }


=item dfDontDisplay

=item dfDontAutoScale

=item dfClipToTextBox

=item dfUseMovieBGColor

=item dfShrinkTextBoxToFit

=item dfScrollIn

=item dfScrollOut

=item dfHorizScroll

=item dfReverseScroll

=item dfContinuousScroll

=item dfFlowHoriz

=item dfContinuousKaraoke

=item dfDropShadow

=item dfAntiAlias

=item dfKeyedText

=item dfInverseHilite

=item dfTextColorHilite

=cut
sub dfDontDisplay ()               {     1 << 0; }
sub dfDontAutoScale ()             {     1 << 1; }
sub dfClipToTextBox ()             {     1 << 2; }
sub dfUseMovieBGColor ()           {     1 << 3; }
sub dfShrinkTextBoxToFit ()        {     1 << 4; }
sub dfScrollIn ()                  {     1 << 5; }
sub dfScrollOut ()                 {     1 << 6; }
sub dfHorizScroll ()               {     1 << 7; }
sub dfReverseScroll ()             {     1 << 8; }
sub dfContinuousScroll ()          {     1 << 9; }
sub dfFlowHoriz ()                 {    1 << 10; }
sub dfContinuousKaraoke ()         {    1 << 11; }
sub dfDropShadow ()                {    1 << 12; }
sub dfAntiAlias ()                 {    1 << 13; }
sub dfKeyedText ()                 {    1 << 14; }
sub dfInverseHilite ()             {    1 << 15; }
sub dfTextColorHilite ()           {    1 << 16; }


=item searchTextDontGoToFoundTime

=item searchTextDontHiliteFoundText

=item searchTextOneTrackOnly

=item searchTextEnabledTracksOnly

=cut
sub searchTextDontGoToFoundTime () {   1 << 16; }
sub searchTextDontHiliteFoundText () {   1 << 17; }
sub searchTextOneTrackOnly ()      {   1 << 18; }
sub searchTextEnabledTracksOnly () {   1 << 19; }


=item k3DMediaRendererEntry

=item k3DMediaRendererName

=item k3DMediaRendererCode

=cut
sub k3DMediaRendererEntry ()       {     'rend'; }
sub k3DMediaRendererName ()        {     'name'; }
sub k3DMediaRendererCode ()        {     'rcod'; }


=item movieProgressOpen

=item movieProgressUpdatePercent

=item movieProgressClose

=item progressOpFlatten

=item progressOpInsertTrackSegment

=item progressOpInsertMovieSegment

=item progressOpPaste

=item progressOpAddMovieSelection

=item progressOpCopy

=item progressOpCut

=item progressOpLoadMovieIntoRam

=item progressOpLoadTrackIntoRam

=item progressOpLoadMediaIntoRam

=item progressOpImportMovie

=item progressOpExportMovie

=cut
sub movieProgressOpen ()           {          0; }
sub movieProgressUpdatePercent ()  {          1; }
sub movieProgressClose ()          {          2; }
sub progressOpFlatten ()           {          1; }
sub progressOpInsertTrackSegment () {          2; }
sub progressOpInsertMovieSegment () {          3; }
sub progressOpPaste ()             {          4; }
sub progressOpAddMovieSelection () {          5; }
sub progressOpCopy ()              {          6; }
sub progressOpCut ()               {          7; }
sub progressOpLoadMovieIntoRam ()  {          8; }
sub progressOpLoadTrackIntoRam ()  {          9; }
sub progressOpLoadMediaIntoRam ()  {         10; }
sub progressOpImportMovie ()       {         11; }
sub progressOpExportMovie ()       {         12; }


=item mediaQualityDraft

=item mediaQualityNormal

=item mediaQualityBetter

=item mediaQualityBest

=cut
sub mediaQualityDraft ()           {     0x0000; }
sub mediaQualityNormal ()          {     0x0040; }
sub mediaQualityBetter ()          {     0x0080; }
sub mediaQualityBest ()            {     0x00C0; }


=item loopTimeBase

=item palindromeLoopTimeBase

=item maintainTimeBaseZero

=cut
sub loopTimeBase ()                {          1; }
sub palindromeLoopTimeBase ()      {          2; }
sub maintainTimeBaseZero ()        {          4; }


=item triggerTimeFwd

=item triggerTimeBwd

=item triggerTimeEither

=item triggerRateLT

=item triggerRateGT

=item triggerRateEqual

=item triggerRateLTE

=item triggerRateGTE

=item triggerRateNotEqual

=item triggerRateChange

=item triggerAtStart

=item triggerAtStop

=cut
sub triggerTimeFwd ()              {     0x0001; }
sub triggerTimeBwd ()              {     0x0002; }
sub triggerTimeEither ()           {     0x0003; }
sub triggerRateLT ()               {     0x0004; }
sub triggerRateGT ()               {     0x0008; }
sub triggerRateEqual ()            {     0x0010; }
sub triggerRateLTE ()              { triggerRateLT | triggerRateEqual; }
sub triggerRateGTE ()              { triggerRateGT | triggerRateEqual; }
sub triggerRateNotEqual ()         { triggerRateGT | triggerRateEqual | triggerRateLT; }
sub triggerRateChange ()           {          0; }
sub triggerAtStart ()              {     0x0001; }
sub triggerAtStop ()               {     0x0002; }


=item timeBaseBeforeStartTime

=item timeBaseAfterStopTime

=cut
sub timeBaseBeforeStartTime ()     {          1; }
sub timeBaseAfterStopTime ()       {          2; }


=item callBackAtTime

=item callBackAtRate

=item callBackAtTimeJump

=item callBackAtExtremes

=item callBackAtInterrupt

=item callBackAtDeferredTask

=cut
sub callBackAtTime ()              {          1; }
sub callBackAtRate ()              {          2; }
sub callBackAtTimeJump ()          {          3; }
sub callBackAtExtremes ()          {          4; }
sub callBackAtInterrupt ()         {     0x8000; }
sub callBackAtDeferredTask ()      {     0x4000; }


=item qtcbNeedsRateChanges

=item qtcbNeedsTimeChanges

=item qtcbNeedsStartStopChanges

=cut
sub qtcbNeedsRateChanges ()        {          1; }
sub qtcbNeedsTimeChanges ()        {          2; }
sub qtcbNeedsStartStopChanges ()   {          4; }


=item keepInRam

=item unkeepInRam

=item flushFromRam

=item loadForwardTrackEdits

=item loadBackwardTrackEdits

=cut
sub keepInRam ()                   {     1 << 0; }
sub unkeepInRam ()                 {     1 << 1; }
sub flushFromRam ()                {     1 << 2; }
sub loadForwardTrackEdits ()       {     1 << 3; }
sub loadBackwardTrackEdits ()      {     1 << 4; }


=item newMovieActive

=item newMovieDontResolveDataRefs

=item newMovieDontAskUnresolvedDataRefs

=item newMovieDontAutoAlternates

=item newMovieDontUpdateForeBackPointers

=cut
sub newMovieActive ()              {     1 << 0; }
sub newMovieDontResolveDataRefs () {     1 << 1; }
sub newMovieDontAskUnresolvedDataRefs () {     1 << 2; }
sub newMovieDontAutoAlternates ()  {     1 << 3; }
sub newMovieDontUpdateForeBackPointers () {     1 << 4; }


=item trackUsageInMovie

=item trackUsageInPreview

=item trackUsageInPoster

=cut
sub trackUsageInMovie ()           {     1 << 1; }
sub trackUsageInPreview ()         {     1 << 2; }
sub trackUsageInPoster ()          {     1 << 3; }


=item mediaSampleNotSync

=item mediaSampleShadowSync

=cut
sub mediaSampleNotSync ()          {     1 << 0; }
sub mediaSampleShadowSync ()       {     1 << 1; }


=item pasteInParallel

=item showUserSettingsDialog

=item movieToFileOnlyExport

=item movieFileSpecValid

=cut
sub pasteInParallel ()             {     1 << 0; }
sub showUserSettingsDialog ()      {     1 << 1; }
sub movieToFileOnlyExport ()       {     1 << 2; }
sub movieFileSpecValid ()          {     1 << 3; }


=item nextTimeMediaSample

=item nextTimeMediaEdit

=item nextTimeTrackEdit

=item nextTimeSyncSample

=item nextTimeStep

=item nextTimeEdgeOK

=item nextTimeIgnoreActiveSegment

=cut
sub nextTimeMediaSample ()         {     1 << 0; }
sub nextTimeMediaEdit ()           {     1 << 1; }
sub nextTimeTrackEdit ()           {     1 << 2; }
sub nextTimeSyncSample ()          {     1 << 3; }
sub nextTimeStep ()                {     1 << 4; }
sub nextTimeEdgeOK ()              {    1 << 14; }
sub nextTimeIgnoreActiveSegment () {    1 << 15; }


=item createMovieFileDeleteCurFile

=item createMovieFileDontCreateMovie

=item createMovieFileDontOpenFile

=cut
sub createMovieFileDeleteCurFile () {   1 << 31; }
sub createMovieFileDontCreateMovie () {   1 << 30; }
sub createMovieFileDontOpenFile () {   1 << 29; }


=item flattenAddMovieToDataFork

=item flattenActiveTracksOnly

=item flattenDontInterleaveFlatten

=item flattenFSSpecPtrIsDataRefRecordPtr

=cut
sub flattenAddMovieToDataFork ()   {    1 << 0; }
sub flattenActiveTracksOnly ()     {    1 << 2; }
sub flattenDontInterleaveFlatten () {    1 << 3; }
sub flattenFSSpecPtrIsDataRefRecordPtr () {    1 << 4; }


=item movieInDataForkResID

=cut
sub movieInDataForkResID ()        {         -1; }


=item mcTopLeftMovie

=item mcScaleMovieToFit

=item mcWithBadge

=item mcNotVisible

=item mcWithFrame

=cut
sub mcTopLeftMovie ()              {     1 << 0; }
sub mcScaleMovieToFit ()           {     1 << 1; }
sub mcWithBadge ()                 {     1 << 2; }
sub mcNotVisible ()                {     1 << 3; }
sub mcWithFrame ()                 {     1 << 4; }


=item movieScrapDontZeroScrap

=item movieScrapOnlyPutMovie

=cut
sub movieScrapDontZeroScrap ()     {     1 << 0; }
sub movieScrapOnlyPutMovie ()      {     1 << 1; }


=item dataRefSelfReference

=item dataRefWasNotResolved

=cut
sub dataRefSelfReference ()        {     1 << 0; }
sub dataRefWasNotResolved ()       {     1 << 1; }


=item hintsScrubMode

=item hintsLoop

=item hintsDontPurge

=item hintsUseScreenBuffer

=item hintsAllowInterlace

=item hintsUseSoundInterp

=item hintsHighQuality

=item hintsPalindrome

=item hintsInactive

=cut
sub hintsScrubMode ()              {     1 << 0; }
sub hintsLoop ()                   {     1 << 1; }
sub hintsDontPurge ()              {     1 << 2; }
sub hintsUseScreenBuffer ()        {     1 << 5; }
sub hintsAllowInterlace ()         {     1 << 6; }
sub hintsUseSoundInterp ()         {     1 << 7; }
sub hintsHighQuality ()            {     1 << 8; }
sub hintsPalindrome ()             {     1 << 9; }
sub hintsInactive ()               {    1 << 11; }


=item mediaHandlerFlagBaseClient

=cut
sub mediaHandlerFlagBaseClient ()  {          1; }


=item movieTrackMediaType

=item movieTrackCharacteristic

=item movieTrackEnabledOnly

=cut
sub movieTrackMediaType ()         {     1 << 0; }
sub movieTrackCharacteristic ()    {     1 << 1; }
sub movieTrackEnabledOnly ()       {     1 << 2; }


=item movieDrawingCallWhenChanged

=item movieDrawingCallAlways

=cut
sub movieDrawingCallWhenChanged () {          0; }
sub movieDrawingCallAlways ()      {          1; }


=item preloadAlways

=item preloadOnlyIfEnabled

=cut
sub preloadAlways ()               {    1 << 0; }
sub preloadOnlyIfEnabled ()        {    1 << 1; }


=item fullScreenHideCursor

=item fullScreenAllowEvents

=item fullScreenDontChangeMenuBar

=item fullScreenPreflightSize

=cut
sub fullScreenHideCursor ()        {    1 << 0; }
sub fullScreenAllowEvents ()       {    1 << 1; }
sub fullScreenDontChangeMenuBar () {    1 << 2; }
sub fullScreenPreflightSize ()     {    1 << 3; }


=item kBackgroundSpriteLayerNum

=item kSpritePropertyMatrix

=item kSpritePropertyImageDescription

=item kSpritePropertyImageDataPtr

=item kSpritePropertyVisible

=item kSpritePropertyLayer

=item kSpritePropertyGraphicsMode

=item kSpritePropertyImageIndex

=item kSpriteTrackPropertyBackgroundColor

=item kSpriteTrackPropertyOffscreenBitDepth

=item kSpriteTrackPropertySampleFormat

=item kOnlyDrawToSpriteWorld

=item kSpriteWorldPreflight

=item kSpriteWorldDidDraw

=item kSpriteWorldNeedsToDraw

=item kKeyFrameAndSingleOverride

=item kKeyFrameAndAllOverrides

=item kParentAtomIsContainer

=item kITextRemoveEverythingBut

=item kITextRemoveLeaveSuggestedAlternate

=item kITextAtomType

=item kITextStringAtomType

=item kTrackModifierInput

=item kTrackModifierType

=item kTrackModifierReference

=item kTrackModifierObjectID

=item kTrackModifierInputName

=item kInputMapSubInputID

=item kTrackModifierTypeMatrix

=item kTrackModifierTypeClip

=item kTrackModifierTypeGraphicsMode

=item kTrackModifierTypeVolume

=item kTrackModifierTypeBalance

=item kTrackModifierTypeSpriteImage

=item kTrackModifierObjectMatrix

=item kTrackModifierObjectGraphicsMode

=item kTrackModifierType3d4x4Matrix

=item kTrackModifierCameraData

=item kTrackModifierSoundLocalizationData

=item kTweenTypeShort

=item kTweenTypeLong

=item kTweenTypeFixed

=item kTweenTypePoint

=item kTweenTypeQDRect

=item kTweenTypeQDRegion

=item kTweenTypeMatrix

=item kTweenTypeRGBColor

=item kTweenTypeGraphicsModeWithRGBColor

=item kTweenType3dScale

=item kTweenType3dTranslate

=item kTweenType3dRotate

=item kTweenType3dRotateAboutPoint

=item kTweenType3dRotateAboutAxis

=item kTweenType3dQuaternion

=item kTweenType3dMatrix

=item kTweenType3dCameraData

=item kTweenType3dSoundLocalizationData

=item kTweenEntry

=item kTweenData

=item kTweenType

=item kTweenStartOffset

=item kTweenDuration

=item kTween3dInitialCondition

=item kTweenInterpolationStyle

=item kTweenRegionData

=item kTweenPictureData

=item internalComponentErr

=item notImplementedMusicOSErr

=item cantSendToSynthesizerOSErr

=item cantReceiveFromSynthesizerOSErr

=item illegalVoiceAllocationOSErr

=item illegalPartOSErr

=item illegalChannelOSErr

=item illegalKnobOSErr

=item illegalKnobValueOSErr

=item illegalInstrumentOSErr

=item illegalControllerOSErr

=item midiManagerAbsentOSErr

=item synthesizerNotRespondingOSErr

=item synthesizerOSErr

=item illegalNoteChannelOSErr

=item noteChannelNotAllocatedOSErr

=item tunePlayerFullOSErr

=item tuneParseOSErr

=item videoFlagDontLeanAhead

=item txtProcDefaultDisplay

=item txtProcDontDisplay

=item txtProcDoDisplay

=item findTextEdgeOK

=item findTextCaseSensitive

=item findTextReverseSearch

=item findTextWrapAround

=item findTextUseOffset

=item dropShadowOffsetType

=item dropShadowTranslucencyType

=item spriteHitTestBounds

=item spriteHitTestImage

=item kSpriteAtomType

=item kSpriteImagesContainerAtomType

=item kSpriteImageAtomType

=item kSpriteImageDataAtomType

=item kSpriteSharedDataAtomType

=item kSpriteNameAtomType

=item MovieControllerComponentType

=cut
sub kBackgroundSpriteLayerNum ()   {      32767; }
sub kSpritePropertyMatrix ()       {          1; }
sub kSpritePropertyImageDescription () {          2; }
sub kSpritePropertyImageDataPtr () {          3; }
sub kSpritePropertyVisible ()      {          4; }
sub kSpritePropertyLayer ()        {          5; }
sub kSpritePropertyGraphicsMode () {          6; }
sub kSpritePropertyImageIndex ()   {        100; }
sub kSpriteTrackPropertyBackgroundColor () {        101; }
sub kSpriteTrackPropertyOffscreenBitDepth () {        102; }
sub kSpriteTrackPropertySampleFormat () {        103; }
sub kOnlyDrawToSpriteWorld ()      {    1 << 0; }
sub kSpriteWorldPreflight ()       {    1 << 1; }
sub kSpriteWorldDidDraw ()         {    1 << 0; }
sub kSpriteWorldNeedsToDraw ()     {    1 << 1; }
sub kKeyFrameAndSingleOverride ()  {    1 << 1; }
sub kKeyFrameAndAllOverrides ()    {    1 << 2; }
sub kParentAtomIsContainer ()      {          0; }
sub kITextRemoveEverythingBut ()   {     0 << 1; }
sub kITextRemoveLeaveSuggestedAlternate () {     1 << 1; }
sub kITextAtomType ()              {     'itxt'; }
sub kITextStringAtomType ()        {     'text'; }
sub kTrackModifierInput ()         {     0x696E; }
sub kTrackModifierType ()          {     0x7479; }
sub kTrackModifierReference ()     {     'ssrc'; }
sub kTrackModifierObjectID ()      {     'obid'; }
sub kTrackModifierInputName ()     {     'name'; }
sub kInputMapSubInputID ()         {     'subi'; }
sub kTrackModifierTypeMatrix ()    {          1; }
sub kTrackModifierTypeClip ()      {          2; }
sub kTrackModifierTypeGraphicsMode () {          5; }
sub kTrackModifierTypeVolume ()    {          3; }
sub kTrackModifierTypeBalance ()   {          4; }
sub kTrackModifierTypeSpriteImage () {     'vide'; }
sub kTrackModifierObjectMatrix ()  {          6; }
sub kTrackModifierObjectGraphicsMode () {          7; }
sub kTrackModifierType3d4x4Matrix () {          8; }
sub kTrackModifierCameraData ()    {          9; }
sub kTrackModifierSoundLocalizationData () {         10; }
sub kTweenTypeShort ()             {          1; }
sub kTweenTypeLong ()              {          2; }
sub kTweenTypeFixed ()             {          3; }
sub kTweenTypePoint ()             {          4; }
sub kTweenTypeQDRect ()            {          5; }
sub kTweenTypeQDRegion ()          {          6; }
sub kTweenTypeMatrix ()            {          7; }
sub kTweenTypeRGBColor ()          {          8; }
sub kTweenTypeGraphicsModeWithRGBColor () {          9; }
sub kTweenType3dScale ()           {     '3sca'; }
sub kTweenType3dTranslate ()       {     '3tra'; }
sub kTweenType3dRotate ()          {     '3rot'; }
sub kTweenType3dRotateAboutPoint () {     '3rap'; }
sub kTweenType3dRotateAboutAxis () {     '3rax'; }
sub kTweenType3dQuaternion ()      {     '3qua'; }
sub kTweenType3dMatrix ()          {     '3mat'; }
sub kTweenType3dCameraData ()      {     '3cam'; }
sub kTweenType3dSoundLocalizationData () {     '3slc'; }
sub kTweenEntry ()                 {     'twen'; }
sub kTweenData ()                  {     'data'; }
sub kTweenType ()                  {     'twnt'; }
sub kTweenStartOffset ()           {     'twst'; }
sub kTweenDuration ()              {     'twdu'; }
sub kTween3dInitialCondition ()    {     'icnd'; }
sub kTweenInterpolationStyle ()    {     'isty'; }
sub kTweenRegionData ()            {     'qdrg'; }
sub kTweenPictureData ()           {     'PICT'; }
sub internalComponentErr ()        {      -2070; }
sub notImplementedMusicOSErr ()    {      -2071; }
sub cantSendToSynthesizerOSErr ()  {      -2072; }
sub cantReceiveFromSynthesizerOSErr () {      -2073; }
sub illegalVoiceAllocationOSErr () {      -2074; }
sub illegalPartOSErr ()            {      -2075; }
sub illegalChannelOSErr ()         {      -2076; }
sub illegalKnobOSErr ()            {      -2077; }
sub illegalKnobValueOSErr ()       {      -2078; }
sub illegalInstrumentOSErr ()      {      -2079; }
sub illegalControllerOSErr ()      {      -2080; }
sub midiManagerAbsentOSErr ()      {      -2081; }
sub synthesizerNotRespondingOSErr () {      -2082; }
sub synthesizerOSErr ()            {      -2083; }
sub illegalNoteChannelOSErr ()     {      -2084; }
sub noteChannelNotAllocatedOSErr () {      -2085; }
sub tunePlayerFullOSErr ()         {      -2086; }
sub tuneParseOSErr ()              {      -2087; }
sub videoFlagDontLeanAhead ()      {    1 << 0; }
sub txtProcDefaultDisplay ()       {          0; }
sub txtProcDontDisplay ()          {          1; }
sub txtProcDoDisplay ()            {          2; }
sub findTextEdgeOK ()              {     1 << 0; }
sub findTextCaseSensitive ()       {     1 << 1; }
sub findTextReverseSearch ()       {     1 << 2; }
sub findTextWrapAround ()          {     1 << 3; }
sub findTextUseOffset ()           {     1 << 4; }
sub dropShadowOffsetType ()        {     'drpo'; }
sub dropShadowTranslucencyType ()  {     'drpt'; }
sub spriteHitTestBounds ()         {    1 << 0; }
sub spriteHitTestImage ()          {    1 << 1; }
sub kSpriteAtomType ()             {     'sprt'; }
sub kSpriteImagesContainerAtomType () {     'imct'; }
sub kSpriteImageAtomType ()        {     'imag'; }
sub kSpriteImageDataAtomType ()    {     'imda'; }
sub kSpriteSharedDataAtomType ()   {     'dflt'; }
sub kSpriteNameAtomType ()         {     'name'; }
sub MovieControllerComponentType () {     'play'; }


=item mcActionIdle

=item mcActionDraw

=item mcActionActivate

=item mcActionDeactivate

=item mcActionMouseDown

=item mcActionKey

=item mcActionPlay

=item mcActionGoToTime

=item mcActionSetVolume

=item mcActionGetVolume

=item mcActionStep

=item mcActionSetLooping

=item mcActionGetLooping

=item mcActionSetLoopIsPalindrome

=item mcActionGetLoopIsPalindrome

=item mcActionSetGrowBoxBounds

=item mcActionControllerSizeChanged

=item mcActionSetSelectionBegin

=item mcActionSetSelectionDuration

=item mcActionSetKeysEnabled

=item mcActionGetKeysEnabled

=item mcActionSetPlaySelection

=item mcActionGetPlaySelection

=item mcActionSetUseBadge

=item mcActionGetUseBadge

=item mcActionSetFlags

=item mcActionGetFlags

=item mcActionSetPlayEveryFrame

=item mcActionGetPlayEveryFrame

=item mcActionGetPlayRate

=item mcActionShowBalloon

=item mcActionBadgeClick

=item mcActionMovieClick

=item mcActionSuspend

=item mcActionResume

=item mcActionSetControllerKeysEnabled

=item mcActionGetTimeSliderRect

=item mcActionMovieEdited

=item mcActionGetDragEnabled

=item mcActionSetDragEnabled

=item mcActionGetSelectionBegin

=item mcActionGetSelectionDuration

=item mcActionPrerollAndPlay

=item mcActionGetCursorSettingEnabled

=item mcActionSetCursorSettingEnabled

=item mcActionSetColorTable

=cut
sub mcActionIdle ()                {          1; }
sub mcActionDraw ()                {          2; }
sub mcActionActivate ()            {          3; }
sub mcActionDeactivate ()          {          4; }
sub mcActionMouseDown ()           {          5; }
sub mcActionKey ()                 {          6; }
sub mcActionPlay ()                {          8; }
sub mcActionGoToTime ()            {         12; }
sub mcActionSetVolume ()           {         14; }
sub mcActionGetVolume ()           {         15; }
sub mcActionStep ()                {         18; }
sub mcActionSetLooping ()          {         21; }
sub mcActionGetLooping ()          {         22; }
sub mcActionSetLoopIsPalindrome () {         23; }
sub mcActionGetLoopIsPalindrome () {         24; }
sub mcActionSetGrowBoxBounds ()    {         25; }
sub mcActionControllerSizeChanged () {         26; }
sub mcActionSetSelectionBegin ()   {         29; }
sub mcActionSetSelectionDuration () {         30; }
sub mcActionSetKeysEnabled ()      {         32; }
sub mcActionGetKeysEnabled ()      {         33; }
sub mcActionSetPlaySelection ()    {         34; }
sub mcActionGetPlaySelection ()    {         35; }
sub mcActionSetUseBadge ()         {         36; }
sub mcActionGetUseBadge ()         {         37; }
sub mcActionSetFlags ()            {         38; }
sub mcActionGetFlags ()            {         39; }
sub mcActionSetPlayEveryFrame ()   {         40; }
sub mcActionGetPlayEveryFrame ()   {         41; }
sub mcActionGetPlayRate ()         {         42; }
sub mcActionShowBalloon ()         {         43; }
sub mcActionBadgeClick ()          {         44; }
sub mcActionMovieClick ()          {         45; }
sub mcActionSuspend ()             {         46; }
sub mcActionResume ()              {         47; }
sub mcActionSetControllerKeysEnabled () {         48; }
sub mcActionGetTimeSliderRect ()   {         49; }
sub mcActionMovieEdited ()         {         50; }
sub mcActionGetDragEnabled ()      {         51; }
sub mcActionSetDragEnabled ()      {         52; }
sub mcActionGetSelectionBegin ()   {         53; }
sub mcActionGetSelectionDuration () {         54; }
sub mcActionPrerollAndPlay ()      {         55; }
sub mcActionGetCursorSettingEnabled () {         56; }
sub mcActionSetCursorSettingEnabled () {         57; }
sub mcActionSetColorTable ()       {         58; }


=item mcFlagSuppressMovieFrame

=item mcFlagSuppressStepButtons

=item mcFlagSuppressSpeakerButton

=item mcFlagsUseWindowPalette

=item mcFlagsDontInvalidate

=item mcPositionDontInvalidate

=cut
sub mcFlagSuppressMovieFrame ()    {     1 << 0; }
sub mcFlagSuppressStepButtons ()   {     1 << 1; }
sub mcFlagSuppressSpeakerButton () {     1 << 2; }
sub mcFlagsUseWindowPalette ()     {     1 << 3; }
sub mcFlagsDontInvalidate ()       {     1 << 4; }
sub mcPositionDontInvalidate ()    {     1 << 5; }


=item mcInfoUndoAvailable

=item mcInfoCutAvailable

=item mcInfoCopyAvailable

=item mcInfoPasteAvailable

=item mcInfoClearAvailable

=item mcInfoHasSound

=item mcInfoIsPlaying

=item mcInfoIsLooping

=item mcInfoIsInPalindrome

=item mcInfoEditingEnabled

=item mcInfoMovieIsInteractive

=cut
sub mcInfoUndoAvailable ()         {     1 << 0; }
sub mcInfoCutAvailable ()          {     1 << 1; }
sub mcInfoCopyAvailable ()         {     1 << 2; }
sub mcInfoPasteAvailable ()        {     1 << 3; }
sub mcInfoClearAvailable ()        {     1 << 4; }
sub mcInfoHasSound ()              {     1 << 5; }
sub mcInfoIsPlaying ()             {     1 << 6; }
sub mcInfoIsLooping ()             {     1 << 7; }
sub mcInfoIsInPalindrome ()        {     1 << 8; }
sub mcInfoEditingEnabled ()        {     1 << 9; }
sub mcInfoMovieIsInteractive ()    {    1 << 10; }


=item mcMenuUndo

=item mcMenuCut

=item mcMenuCopy

=item mcMenuPaste

=item mcMenuClear

Lots of as yet unspecified constants.

=cut
sub mcMenuUndo ()                  {          1; }
sub mcMenuCut ()                   {          3; }
sub mcMenuCopy ()                  {          4; }
sub mcMenuPaste ()                 {          5; }
sub mcMenuClear ()                 {          6; }

=back

=cut

%ActionFilter = ();

sub _ActionFilter {
	my $controller 	= $_[0];
	my $filter 		= $ActionFilter{$controller};
	
	$filter ? &$filter(@_) : 0;
}

sub DisposeMovieController {
	my $controller = $_[0];
	_DisposeMovieController($controller);
	delete $ActionFilter{$controller};
}

sub MCSetActionFilter {
	my ($mc,$filter) = @_;
	
	if ($filter) {
		$ActionFilter{$mc} = $filter;
		_MCSetActionFilter($mc, 0);
	} else {
		_MCSetActionFilter($mc, 0);
		delete $ActionFilter{$mc};
	}
}

sub MCGetMovie {
	my ($mc) = @_;
	
	return MCGetIndMovie($mc, 0);
}

=include Movies.xs

=head2 Extension to MacWindow

=over 4

=cut
package MacWindow;

use Carp;
import Mac::Movies;

=item new_movie [CLASS, ] MOVIECONTROLLER [, CANFOCUS ]

=item new_movie [CLASS, ] MOVIE, RECT [, FLAGS [, CANFOCUS ]]

Create a new movie controller, attach it to the window, and return it. In the 
first form, registers an existing movie controller. In the second form, calls 
C<NewMovieController>.

=cut
sub new_movie {
	my($my) = shift @_;
	my($type) = @_;
	my($class,$mc, $focus);

	if (ref($type) || $type =~ /^\d+$/) {
		$class = "MacMovie"
	} else {
		$class = shift @_;
		$type  = $_[0];
	}
	if (ref($type) ne "Movie") {
		$focus = pop(@_) if scalar(@_)>1;
		$mc = $type;
	} else {
		$focus = pop(@_) if scalar(@_)>3;
		$mc    = NewMovieController(@_) or croak "NewMovieController failed";
	} 
	$class->new($my, $mc, $focus);
}

=head2 MacMovie - The object interface to a movie controller

MacMovie is a QuickTime Movie Controller embedded into a pane.

=cut
package MacMovie;

BEGIN {
	use Mac::Hooks ();
	use Mac::Pane;
	use Mac::Events;
	use Mac::Windows   qw(InvalRgn);
	use Mac::QuickDraw qw(GetPenState InsetRgn patOr patBic);
	import Mac::Movies;

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Pane Mac::Hooks);
}

=item new WINDOW, CONTROLLER, FOCUS

Initialize a C<MacMovie> (which is always created with 
C<MacWindow::new_movie>).

=cut
sub new {
	my($class, $window, $mc, $focus) = @_;

	my(%vars) = (window => $window, movie => $mc, focus => $focus);
	
	my $me = bless \%vars, $class;
	
	$window->add_pane($me);
	$window->add_idle($me);
	$window->add_focusable($me) if $focus;
	
	InvalRgn MCGetControllerBoundsRgn($mc);
	
	$me;
}

=item dispose

Dispose of the movie controller.

=cut
sub dispose {
	my($my) = @_;
	DisposeMovieController($my->{movie}) if $my->{movie};
	delete $my->{movie};
}

=item DESTROY

Destroys the C<MacMovie>.

=cut
sub DESTROY {
	dispose(@_);
}

=item movie

Get the QuickTime Movie Controller.

=cut
sub movie {
	my($my) = @_;
	
	$my->{movie};
}

=item activate(WINDOW, ACTIVE, SUSPEND)

Handle activate/suspend.

=cut
sub activate {
	my($my, $window, $active, $suspend) = @_;
	
	MCActivate($my->{movie}, $window->window, $active);
}

=item focus(WINDOW, FOCUS)

Called by MacWindow to indicate that the movie has acquired (1) or lost (0) the 
focus.

=cut
sub focus {
	my($my, $window, $focus) = @_;
	my $movie = $my->{movie};
	
	MCDoAction($movie, mcActionSetKeysEnabled, $focus);
	
	$my->callhook("focus", @_) and return;

	return unless $window->can_focus;
	
	my $pen  = GetPenState;
	my $rgn  = InsetRgn MCGetControllerBoundsRgn($movie), -4, -4;	
	PenSize(2,2);
	PenMode($focus ? patOr : patBic);
	FrameRgn($rgn);
	SetPenState($pen);
}

=item redraw(WINDOW)

Redraw the contents of the pane.

=cut
sub redraw {
	my($my, $window) = @_;
	my $movie = $my->{movie};
	
	MCDraw($my->{movie}, $window->window);

	$my->callhook("redraw", @_) && return;
	
	return unless $window->has_focus($my) && $window->can_focus;
	
	my $pen  = GetPenState;
	my $rgn  = InsetRgn MCGetControllerBoundsRgn($movie), -4, -4;	
	PenSize(2,2);
	FrameRgn($rgn);
	SetPenState($pen);
}

=item key(WINDOW, KEY)

Handle a key stroke.

=cut
sub key {
	my($my, $window, $key) = @_;
	my $movie = $my->{movie};
	
	$my->callhook("key", @_) and return;

	MCKey($movie, $key, $Mac::Events::CurrentEvent->modifiers);	
}

=item click(WINDOW, PT)

Handle a click.

=cut
sub click {
	my($my, $window, $pt) = @_;
	my($res);
	
	($res = $my->callhook("click", @_)) and return $res;
	
	MCClick(
		$my->{movie}, $window->window, $pt, 
		$Mac::Events::CurrentEvent->when,
		$Mac::Events::CurrentEvent->modifiers);
}

=item cursor(WINDOW, PT)

Do cursor.

=cut
sub cursor {
	my($my, $window, $pt) = @_;
	
	return PtInMovie(MCGetMovie($my->{movie}), $pt);
}

=item idle(WINDOW)

Do idle time.

=cut
sub idle {
	my($my, $window) = @_;
	
	MCIdle($my->{movie});
}

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
