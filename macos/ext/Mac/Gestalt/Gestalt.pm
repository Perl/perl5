=head1 NAME

Mac::Gestalt - Macintosh Toolbox Interface to the Gestalt Manager

=head1 SYNOPSIS


	# Only bring in the names we want
	use Mac::Gestalt qw(%Gestalt gestaltAppleTalkVersion);
	
	if ( $Gestalt{gestaltAppleTalkVersion} lt "58" ) {
		warn "Unable to use AppleTalk\n";
	}

=head1 DESCRIPTION

You can use the Gestalt function or the %Gestalt tied hash to obtain information about 
the operating environment. You specify what information you need by passing one of
the selector codes recognized by Gestalt.

=cut

use strict;

package Mac::Gestalt;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT %Gestalt);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		Gestalt
		
		%Gestalt
		
		gestaltAddressingModeAttr
		gestalt32BitAddressing
		gestalt32BitSysZone
		gestalt32BitCapable
		gestaltAliasMgrAttr
		gestaltAliasMgrPresent
		gestaltAliasMgrSupportsRemoteAppletalk
		gestaltAppleTalkVersion
		gestaltAUXVersion
		gestaltCloseViewAttr
		gestaltCloseViewEnabled
		gestaltCloseViewDisplayMgrFriendly
		gestaltCFMAttr
		gestaltCFMPresent
		gestaltColorMatchingAttr
		gestaltHighLevelMatching
		gestaltColorMatchingLibLoaded
		gestaltColorMatchingVersion
		gestaltColorSync10
		gestaltColorSync11
		gestaltColorSync104
		gestaltColorSync105
		gestaltConnMgrAttr
		gestaltConnMgrPresent
		gestaltConnMgrCMSearchFix
		gestaltConnMgrErrorString
		gestaltConnMgrMultiAsyncIO
		gestaltComponentMgr
		gestaltColorPickerVersion
		gestaltColorPicker
		gestaltNativeCPUtype
		gestaltCPU68000
		gestaltCPU68010
		gestaltCPU68020
		gestaltCPU68030
		gestaltCPU68040
		gestaltCPU601
		gestaltCPU603
		gestaltCPU604
		gestaltCRMAttr
		gestaltCRMPresent
		gestaltCRMPersistentFix
		gestaltCRMToolRsrcCalls
		gestaltControlStripVersion
		gestaltCTBVersion
		gestaltDBAccessMgrAttr
		gestaltDBAccessMgrPresent
		gestaltDictionaryMgrAttr
		gestaltDictionaryMgrPresent
		gestaltDITLExtAttr
		gestaltDITLExtPresent
		gestaltDisplayMgrAttr
		gestaltDisplayMgrPresent
		gestaltDisplayMgrCanSwitchMirrored
		gestaltDisplayMgrSetDepthNotifies
		gestaltDisplayMgrVers
		gestaltDragMgrAttr
		gestaltDragMgrPresent
		gestaltDragMgrFloatingWind
		gestaltPPCDragLibPresent
		gestaltEasyAccessAttr
		gestaltEasyAccessOff
		gestaltEasyAccessOn
		gestaltEasyAccessSticky
		gestaltEasyAccessLocked
		gestaltEditionMgrAttr
		gestaltEditionMgrPresent
		gestaltEditionMgrTranslationAware
		gestaltAppleEventsAttr
		gestaltAppleEventsPresent
		gestaltScriptingSupport
		gestaltOSLInSystem
		gestaltFinderAttr
		gestaltFinderDropEvent
		gestaltFinderMagicPlacement
		gestaltFinderCallsAEProcess
		gestaltOSLCompliantFinder
		gestaltFinderSupports4GBVolumes
		gestaltFinderHasClippings
		gestaltFindFolderAttr
		gestaltFindFolderPresent
		gestaltFontMgrAttr
		gestaltOutlineFonts
		gestaltFPUType
		gestaltNoFPU
		gestalt68881
		gestalt68882
		gestalt68040FPU
		gestaltFSAttr
		gestaltFullExtFSDispatching
		gestaltHasFSSpecCalls
		gestaltHasFileSystemManager
		gestaltFSMDoesDynamicLoad
		gestaltFSSupports4GBVols
		gestaltFSSupports2TBVols
		gestaltHasExtendedDiskInit
		gestaltFSMVersion
		gestaltFXfrMgrAttr
		gestaltFXfrMgrPresent
		gestaltFXfrMgrMultiFile
		gestaltFXfrMgrErrorString
		gestaltGraphicsAttr
		gestaltGraphicsIsDebugging
		gestaltGraphicsIsLoaded
		gestaltGraphicsIsPowerPC
		gestaltGraphicsVersion
		gestaltCurrentGraphicsVersion
		gestaltHardwareAttr
		gestaltHasVIA1
		gestaltHasVIA2
		gestaltHasASC
		gestaltHasSCC
		gestaltHasSCSI
		gestaltHasSoftPowerOff
		gestaltHasSCSI961
		gestaltHasSCSI962
		gestaltHasUniversalROM
		gestaltHasEnhancedLtalk
		gestaltHelpMgrAttr
		gestaltHelpMgrPresent
		gestaltHelpMgrExtensions
		gestaltCompressionMgr
		gestaltIconUtilitiesAttr
		gestaltIconUtilitiesPresent
		gestaltKeyboardType
		gestaltMacKbd
		gestaltMacAndPad
		gestaltMacPlusKbd
		gestaltExtADBKbd
		gestaltStdADBKbd
		gestaltPrtblADBKbd
		gestaltPrtblISOKbd
		gestaltStdISOADBKbd
		gestaltExtISOADBKbd
		gestaltADBKbdII
		gestaltADBISOKbdII
		gestaltPwrBookADBKbd
		gestaltPwrBookISOADBKbd
		gestaltAppleAdjustKeypad
		gestaltAppleAdjustADBKbd
		gestaltAppleAdjustISOKbd
		gestaltJapanAdjustADBKbd
		gestaltPwrBkExtISOKbd
		gestaltPwrBkExtJISKbd
		gestaltPwrBkExtADBKbd
		gestaltLowMemorySize
		gestaltLogicalRAMSize
		gestaltMachineType
		gestaltClassic
		gestaltMacXL
		gestaltMac512KE
		gestaltMacPlus
		gestaltMacSE
		gestaltMacII
		gestaltMacIIx
		gestaltMacIIcx
		gestaltMacSE030
		gestaltPortable
		gestaltMacIIci
		gestaltMacIIfx
		gestaltMacClassic
		gestaltMacIIsi
		gestaltMacLC
		gestaltQuadra900
		gestaltPowerBook170
		gestaltQuadra700
		gestaltClassicII
		gestaltPowerBook100
		gestaltPowerBook140
		gestaltQuadra950
		gestaltMacLCIII
		gestaltPerforma450
		gestaltPowerBookDuo210
		gestaltMacCentris650
		gestaltPowerBookDuo230
		gestaltPowerBook180
		gestaltPowerBook160
		gestaltMacQuadra800
		gestaltMacQuadra650
		gestaltMacLCII
		gestaltPowerBookDuo250
		gestaltAWS9150_80
		gestaltPowerMac8100_110
		gestaltAWS8150_110
		gestaltMacIIvi
		gestaltMacIIvm
		gestaltPerforma600
		gestaltPowerMac7100_80
		gestaltMacIIvx
		gestaltMacColorClassic
		gestaltPerforma250
		gestaltPowerBook165c
		gestaltMacCentris610
		gestaltMacQuadra610
		gestaltPowerBook145
		gestaltPowerMac8100_100
		gestaltMacLC520
		gestaltAWS9150_120
		gestaltMacCentris660AV
		gestaltPerforma46x
		gestaltPowerMac8100_80
		gestaltAWS8150_80
		gestaltPowerBook180c
		gestaltPowerMac6100_60
		gestaltAWS6150_60
		gestaltPowerBookDuo270c
		gestaltMacQuadra840AV
		gestaltPerforma550
		gestaltPowerBook165
		gestaltMacTV
		gestaltMacLC475
		gestaltPerforma47x
		gestaltMacLC575
		gestaltMacQuadra605
		gestaltQuadra630
		gestaltPowerMac6100_66
		gestaltAWS6150_66
		gestaltPowerBookDuo280
		gestaltPowerBookDuo280c
		gestaltPowerMac7100_66
		gestaltPowerBook150
		kMachineNameStrID
		gestaltMachineIcon
		gestaltMiscAttr
		gestaltScrollingThrottle
		gestaltSquareMenuBar
		gestaltMixedModeVersion
		gestaltMixedModeAttr
		gestaltPowerPCAware
		gestaltMMUType
		gestaltNoMMU
		gestaltAMU
		gestalt68851
		gestalt68030MMU
		gestalt68040MMU
		gestaltEMMU1
		gestaltStdNBPAttr
		gestaltStdNBPPresent
		gestaltNotificationMgrAttr
		gestaltNotificationPresent
		gestaltNameRegistryVersion
		gestaltNuBusSlotCount
		gestaltOpenFirmwareInfo
		gestaltOSAttr
		gestaltSysZoneGrowable
		gestaltLaunchCanReturn
		gestaltLaunchFullFileSpec
		gestaltLaunchControl
		gestaltTempMemSupport
		gestaltRealTempMemory
		gestaltTempMemTracked
		gestaltIPCSupport
		gestaltSysDebuggerSupport
		gestaltOSTable
		gestaltPCXAttr
		gestaltPCXHas8and16BitFAT
		gestaltPCXHasProDOS
		gestaltLogicalPageSize
		gestaltPopupAttr
		gestaltPopupPresent
		gestaltPowerMgrAttr
		gestaltPMgrExists
		gestaltPMgrCPUIdle
		gestaltPMgrSCC
		gestaltPMgrSound
		gestaltPMgrDispatchExists
		gestaltPPCToolboxAttr
		gestaltPPCToolboxPresent
		gestaltPPCSupportsRealTime
		gestaltPPCSupportsIncoming
		gestaltPPCSupportsOutGoing
		gestaltProcessorType
		gestalt68000
		gestalt68010
		gestalt68020
		gestalt68030
		gestalt68040
		gestaltParityAttr
		gestaltHasParityCapability
		gestaltParityEnabled
		gestaltQuickdrawVersion
		gestaltOriginalQD
		gestalt8BitQD
		gestalt32BitQD
		gestalt32BitQD11
		gestalt32BitQD12
		gestalt32BitQD13
		gestaltQuickdrawFeatures
		gestaltHasColor
		gestaltHasDeepGWorlds
		gestaltHasDirectPixMaps
		gestaltHasGrayishTextOr
		gestaltSupportsMirroring
		gestaltQuickTimeVersion
		gestaltQuickTime
		gestaltQuickTimeFeatures
		gestaltPPCQuickTimeLibPresent
		gestaltPhysicalRAMSize
		gestaltRBVAddr
		gestaltROMSize
		gestaltROMVersion
		gestaltResourceMgrAttr
		gestaltPartialRsrcs
		gestaltRealtimeMgrAttr
		gestaltRealtimeMgrPresent
		gestaltSCCReadAddr
		gestaltSCCWriteAddr
		gestaltScrapMgrAttr
		gestaltScrapMgrTranslationAware
		gestaltScriptMgrVersion
		gestaltScriptCount
		gestaltSCSI
		gestaltAsyncSCSI
		gestaltAsyncSCSIINROM
		gestaltSCSISlotBoot
		gestaltControlStripAttr
		gestaltControlStripExists
		gestaltControlStripVersionFixed
		gestaltControlStripUserFont
		gestaltControlStripUserHotKey
		gestaltSerialAttr
		gestaltHasGPIaToDCDa
		gestaltHasGPIaToRTxCa
		gestaltHasGPIbToDCDb
		gestaltNuBusConnectors
		gestaltSlotAttr
		gestaltSlotMgrExists
		gestaltNuBusPresent
		gestaltSESlotPresent
		gestaltSE30SlotPresent
		gestaltPortableSlotPresent
		gestaltFirstSlotNumber
		gestaltSoundAttr
		gestaltStereoCapability
		gestaltStereoMixing
		gestaltSoundIOMgrPresent
		gestaltBuiltInSoundInput
		gestaltHasSoundInputDevice
		gestaltPlayAndRecord
		gestalt16BitSoundIO
		gestaltStereoInput
		gestaltLineLevelInput
		gestaltSndPlayDoubleBuffer
		gestaltMultiChannels
		gestalt16BitAudioSupport
		gestaltStandardFileAttr
		gestaltStandardFile58
		gestaltStandardFileTranslationAware
		gestaltStandardFileHasColorIcons
		gestaltStandardFileUseGenericIcons
		gestaltStandardFileHasDynamicVolumeAllocation
		gestaltSysArchitecture
		gestalt68k
		gestaltPowerPC
		gestaltSystemVersion
		gestaltTSMgrVersion
		gestaltTSMgr2
		gestaltTSMgrAttr
		gestaltTSMDisplayMgrAwareBit
		gestaltTSMdoesTSMTEBit
		gestaltTSMTEVersion
		gestaltTSMTE1
		gestaltTSMTE2
		gestaltTSMTEAttr
		gestaltTSMTEPresent
		gestaltTSMTE
		gestaltTextEditVersion
		gestaltTE1
		gestaltTE2
		gestaltTE3
		gestaltTE4
		gestaltTE5
		gestaltTE6
		gestaltTEAttr
		gestaltTEHasGetHiliteRgn
		gestaltTESupportsInlineInput
		gestaltTESupportsTextObjects
		gestaltTeleMgrAttr
		gestaltTeleMgrPresent
		gestaltTeleMgrPowerPCSupport
		gestaltTeleMgrSoundStreams
		gestaltTeleMgrAutoAnswer
		gestaltTeleMgrIndHandset
		gestaltTeleMgrSilenceDetect
		gestaltTeleMgrNewTELNewSupport
		gestaltTermMgrAttr
		gestaltTermMgrPresent
		gestaltTermMgrErrorString
		gestaltTimeMgrVersion
		gestaltStandardTimeMgr
		gestaltRevisedTimeMgr
		gestaltExtendedTimeMgr
		gestaltSpeechAttr
		gestaltSpeechMgrPresent
		gestaltSpeechHasPPCGlue
		gestaltToolboxTable
		gestaltThreadMgrAttr
		gestaltThreadMgrPresent
		gestaltSpecificMatchSupport
		gestaltThreadsLibraryPresent
		gestaltTVAttr
		gestaltHasTVTuner
		gestaltHasSoundFader
		gestaltHasHWClosedCaptioning
		gestaltHasIRRemote
		gestaltHasVidDecoderScaler
		gestaltHasStereoDecoder
		gestaltVersion
		gestaltValueImplementedVers
		gestaltVIA1Addr
		gestaltVIA2Addr
		gestaltVMAttr
		gestaltVMPresent
		gestaltTranslationAttr
		gestaltTranslationMgrExists
		gestaltTranslationMgrHintOrder
		gestaltTranslationPPCAvail
		gestaltTranslationGetPathAPIAvail
		gestaltExtToolboxTable
	);
}

package Mac::Gestalt::_GestaltHash;

BEGIN {
	use Tie::Hash ();

	use vars qw(@ISA);
	
	@ISA = qw(Tie::StdHash);
}

sub FETCH {
	my($self,$id) = @_;
	
	if (!$self->{$id}) {
		$self->{$id} = Mac::Gestalt::Gestalt($id);
	}
	$self->{$id};
}

package Mac::Gestalt;

tie %Gestalt, q(Mac::Gestalt::_GestaltHash);

bootstrap Mac::Gestalt;

=pod

There is a huge list of codes. Many of them return a bitmask, so to find out 
whether e.g. the Code Fragment Manager is present, you  write

	$Gestalt{gestaltCFMAttr} & (1 << gestaltCFMPresent)

=head2 Constants

=over 4

=cut 


=item gestaltAddressingModeAttr

=item gestalt32BitAddressing

=item gestalt32BitSysZone

=item gestalt32BitCapable

Address mode.

=cut
sub gestaltAddressingModeAttr ()   {     'addr'; }
sub gestalt32BitAddressing ()      {          0; }
sub gestalt32BitSysZone ()         {          1; }
sub gestalt32BitCapable ()         {          2; }


=item gestaltAliasMgrAttr

=item gestaltAliasMgrPresent

=item gestaltAliasMgrSupportsRemoteAppletalk

Alias manager.

=cut
sub gestaltAliasMgrAttr ()         				{     'alis'; }
sub gestaltAliasMgrPresent ()      				{          0; }
sub gestaltAliasMgrSupportsRemoteAppletalk () 	{          1; }


=item gestaltAppleTalkVersion

AppleTalk.

=cut
sub gestaltAppleTalkVersion ()     {     'atlk'; }


=item gestaltAUXVersion

A/UX.

=cut
sub gestaltAUXVersion ()           {     'a/ux'; }


=item gestaltCloseViewAttr

=item gestaltCloseViewEnabled

=item gestaltCloseViewDisplayMgrFriendly

CloseView.

=cut
sub gestaltCloseViewAttr ()        			{     'BSDa'; }
sub gestaltCloseViewEnabled ()     			{          0; }
sub gestaltCloseViewDisplayMgrFriendly () 	{          1; }


=item gestaltCFMAttr

=item gestaltCFMPresent

Code Fragment Manager.

=cut
sub gestaltCFMAttr ()              {     'cfrg'; }
sub gestaltCFMPresent ()           {          0; }


=item gestaltColorMatchingAttr

=item gestaltHighLevelMatching

=item gestaltColorMatchingLibLoaded

ColorSync.

=cut
sub gestaltColorMatchingAttr ()    		{     'cmta'; }
sub gestaltHighLevelMatching ()    		{          0; }
sub gestaltColorMatchingLibLoaded () 	{          1; }


=item gestaltColorMatchingVersion

=item gestaltColorSync10

=item gestaltColorSync11

=item gestaltColorSync104

=item gestaltColorSync105

ColorSync version.

=cut
sub gestaltColorMatchingVersion () {     'cmtc'; }
sub gestaltColorSync10 ()          {     0x0100; }
sub gestaltColorSync11 ()          {     0x0110; }
sub gestaltColorSync104 ()         {     0x0104; }
sub gestaltColorSync105 ()         {     0x0105; }


=item gestaltConnMgrAttr

=item gestaltConnMgrPresent

=item gestaltConnMgrCMSearchFix

=item gestaltConnMgrErrorString

=item gestaltConnMgrMultiAsyncIO

Communications toolbox connection manager.

=cut
sub gestaltConnMgrAttr ()          {     'conn'; }
sub gestaltConnMgrPresent ()       {          0; }
sub gestaltConnMgrCMSearchFix ()   {          1; }
sub gestaltConnMgrErrorString ()   {          2; }
sub gestaltConnMgrMultiAsyncIO ()  {          3; }


=item gestaltComponentMgr

Component manager.

=cut
sub gestaltComponentMgr ()         {     'cpnt'; }


=item gestaltColorPickerVersion

=item gestaltColorPicker

Color picker.

=cut
sub gestaltColorPickerVersion ()   {     'cpkr'; }
sub gestaltColorPicker ()          {     'cpkr'; }

=item gestaltNativeCPUtype

=item gestaltCPU68000

=item gestaltCPU68010

=item gestaltCPU68020

=item gestaltCPU68030

=item gestaltCPU68040

=item gestaltCPU601

=item gestaltCPU603

=item gestaltCPU604

CPU type.

=cut
sub gestaltNativeCPUtype ()        {     'cput'; }
sub gestaltCPU68000 ()             {          1; }
sub gestaltCPU68010 ()             {          2; }
sub gestaltCPU68020 ()             {          3; }
sub gestaltCPU68030 ()             {          4; }
sub gestaltCPU68040 ()             {          5; }
sub gestaltCPU601 ()               {      0x101; }
sub gestaltCPU603 ()               {      0x103; }
sub gestaltCPU604 ()               {      0x104; }


=item gestaltCRMAttr

=item gestaltCRMPresent

=item gestaltCRMPersistentFix

=item gestaltCRMToolRsrcCalls

Communications toolbox connection resource manager.

=cut
sub gestaltCRMAttr ()              {     'crm '; }
sub gestaltCRMPresent ()           {          0; }
sub gestaltCRMPersistentFix ()     {          1; }
sub gestaltCRMToolRsrcCalls ()     {          2; }


=item gestaltControlStripVersion

Control strip manager.

=cut
sub gestaltControlStripVersion ()  {     'csvr'; }


=item gestaltCTBVersion

Communications toolbox.

=cut
sub gestaltCTBVersion ()           {     'ctbv'; }


=item gestaltDBAccessMgrAttr

=item gestaltDBAccessMgrPresent

Database access manager.

=cut
sub gestaltDBAccessMgrAttr ()      {     'dbac'; }
sub gestaltDBAccessMgrPresent ()   {          0; }


=item gestaltDictionaryMgrAttr

=item gestaltDictionaryMgrPresent

Dictionary manager.

=cut
sub gestaltDictionaryMgrAttr ()    {     'dict'; }
sub gestaltDictionaryMgrPresent () {          0; }


=item gestaltDITLExtAttr

=item gestaltDITLExtPresent

Dialog manager extensions.

=cut
sub gestaltDITLExtAttr ()          {     'ditl'; }
sub gestaltDITLExtPresent ()       {          0; }


=item gestaltDisplayMgrAttr

=item gestaltDisplayMgrPresent

=item gestaltDisplayMgrCanSwitchMirrored

=item gestaltDisplayMgrSetDepthNotifies

Display manager.

=cut
sub gestaltDisplayMgrAttr ()       			{     'dply'; }
sub gestaltDisplayMgrPresent ()    			{          0; }
sub gestaltDisplayMgrCanSwitchMirrored () 	{          2; }
sub gestaltDisplayMgrSetDepthNotifies () 	{          3; }


=item gestaltDisplayMgrVers

Display manager version.

=cut
sub gestaltDisplayMgrVers ()       {     'dplv'; }


=item gestaltDragMgrAttr

=item gestaltDragMgrPresent

=item gestaltDragMgrFloatingWind

=item gestaltPPCDragLibPresent

Drag manager.

=cut
sub gestaltDragMgrAttr ()          {     'drag'; }
sub gestaltDragMgrPresent ()       {          0; }
sub gestaltDragMgrFloatingWind ()  {          1; }
sub gestaltPPCDragLibPresent ()    {          2; }


=item gestaltEasyAccessAttr

=item gestaltEasyAccessOff

=item gestaltEasyAccessOn

=item gestaltEasyAccessSticky

=item gestaltEasyAccessLocked

Easy access.

=cut
sub gestaltEasyAccessAttr ()       {     'easy'; }
sub gestaltEasyAccessOff ()        {          0; }
sub gestaltEasyAccessOn ()         {          1; }
sub gestaltEasyAccessSticky ()     {          2; }
sub gestaltEasyAccessLocked ()     {          3; }


=item gestaltEditionMgrAttr

=item gestaltEditionMgrPresent

=item gestaltEditionMgrTranslationAware

Edition manager.

=cut
sub gestaltEditionMgrAttr ()       			{     'edtn'; }
sub gestaltEditionMgrPresent ()    			{          0; }
sub gestaltEditionMgrTranslationAware () 	{          1; }


=item gestaltAppleEventsAttr

=item gestaltAppleEventsPresent

=item gestaltScriptingSupport

=item gestaltOSLInSystem

AppleEvent manager.

=cut
sub gestaltAppleEventsAttr ()      {     'evnt'; }
sub gestaltAppleEventsPresent ()   {          0; }
sub gestaltScriptingSupport ()     {          1; }
sub gestaltOSLInSystem ()          {          2; }


=item gestaltFinderAttr

=item gestaltFinderDropEvent

=item gestaltFinderMagicPlacement

=item gestaltFinderCallsAEProcess

=item gestaltOSLCompliantFinder

=item gestaltFinderSupports4GBVolumes

=item gestaltFinderHasClippings

Finder attributes.

=cut
sub gestaltFinderAttr ()           		{     'fndr'; }
sub gestaltFinderDropEvent ()      		{          0; }
sub gestaltFinderMagicPlacement () 		{          1; }
sub gestaltFinderCallsAEProcess () 		{          2; }
sub gestaltOSLCompliantFinder ()   		{          3; }
sub gestaltFinderSupports4GBVolumes ()	{          4; }
sub gestaltFinderHasClippings ()   		{          6; }


=item gestaltFindFolderAttr

=item gestaltFindFolderPresent

Folder manager.

=cut
sub gestaltFindFolderAttr ()       {     'fold'; }
sub gestaltFindFolderPresent ()    {          0; }


=item gestaltFontMgrAttr

=item gestaltOutlineFonts

Font manager.

=cut
sub gestaltFontMgrAttr ()          {     'font'; }
sub gestaltOutlineFonts ()         {          0; }


=item gestaltFPUType

=item gestaltNoFPU

=item gestalt68881

=item gestalt68882

=item gestalt68040FPU

680X0 FPU.

=cut
sub gestaltFPUType ()              {     'fpu '; }
sub gestaltNoFPU ()                {          0; }
sub gestalt68881 ()                {          1; }
sub gestalt68882 ()                {          2; }
sub gestalt68040FPU ()             {          3; }


=item gestaltFSAttr

=item gestaltFullExtFSDispatching

=item gestaltHasFSSpecCalls

=item gestaltHasFileSystemManager

=item gestaltFSMDoesDynamicLoad

=item gestaltFSSupports4GBVols

=item gestaltFSSupports2TBVols

=item gestaltHasExtendedDiskInit

File system attributes.

=cut
sub gestaltFSAttr ()               {     'fs  '; }
sub gestaltFullExtFSDispatching () {          0; }
sub gestaltHasFSSpecCalls ()       {          1; }
sub gestaltHasFileSystemManager () {          2; }
sub gestaltFSMDoesDynamicLoad ()   {          3; }
sub gestaltFSSupports4GBVols ()    {          4; }
sub gestaltFSSupports2TBVols ()    {          5; }
sub gestaltHasExtendedDiskInit ()  {          6; }


=item gestaltFSMVersion

File system manager.

=cut
sub gestaltFSMVersion ()           {     'fsm '; }


=item gestaltFXfrMgrAttr

=item gestaltFXfrMgrPresent

=item gestaltFXfrMgrMultiFile

=item gestaltFXfrMgrErrorString

File transfer manager.

=cut
sub gestaltFXfrMgrAttr ()          {     'fxfr'; }
sub gestaltFXfrMgrPresent ()       {          0; }
sub gestaltFXfrMgrMultiFile ()     {          1; }
sub gestaltFXfrMgrErrorString ()   {          2; }


=item gestaltGraphicsAttr

=item gestaltGraphicsIsDebugging

=item gestaltGraphicsIsLoaded

=item gestaltGraphicsIsPowerPC

QuickDraw GX attributes.

=cut
sub gestaltGraphicsAttr ()         {     'gfxa'; }
sub gestaltGraphicsIsDebugging ()  { 0x00000001; }
sub gestaltGraphicsIsLoaded ()     { 0x00000002; }
sub gestaltGraphicsIsPowerPC ()    { 0x00000004; }


=item gestaltGraphicsVersion

=item gestaltCurrentGraphicsVersion

QuickDraw GX version.

=cut
sub gestaltGraphicsVersion ()      {     'grfx'; }
sub gestaltCurrentGraphicsVersion () { 0x00010000; }


=item gestaltHardwareAttr

=item gestaltHasVIA1

=item gestaltHasVIA2

=item gestaltHasASC

=item gestaltHasSCC

=item gestaltHasSCSI

=item gestaltHasSoftPowerOff

=item gestaltHasSCSI961

=item gestaltHasSCSI962

=item gestaltHasUniversalROM

=item gestaltHasEnhancedLtalk

Hardware attributes.

=cut
sub gestaltHardwareAttr ()         {     'hdwr'; }
sub gestaltHasVIA1 ()              {          0; }
sub gestaltHasVIA2 ()              {          1; }
sub gestaltHasASC ()               {          3; }
sub gestaltHasSCC ()               {          4; }
sub gestaltHasSCSI ()              {          7; }
sub gestaltHasSoftPowerOff ()      {         19; }
sub gestaltHasSCSI961 ()           {         21; }
sub gestaltHasSCSI962 ()           {         22; }
sub gestaltHasUniversalROM ()      {         24; }
sub gestaltHasEnhancedLtalk ()     {         30; }


=item gestaltHelpMgrAttr

=item gestaltHelpMgrPresent

=item gestaltHelpMgrExtensions

Help manager.

=cut
sub gestaltHelpMgrAttr ()          {     'help'; }
sub gestaltHelpMgrPresent ()       {          0; }
sub gestaltHelpMgrExtensions ()    {          1; }


=item gestaltCompressionMgr

QuickTime image compression manager.

=cut
sub gestaltCompressionMgr ()       {     'icmp'; }


=item gestaltIconUtilitiesAttr

=item gestaltIconUtilitiesPresent

Icon utilities.

=cut
sub gestaltIconUtilitiesAttr ()    {     'icon'; }
sub gestaltIconUtilitiesPresent () {          0; }


=item gestaltKeyboardType

=item gestaltMacKbd

=item gestaltMacAndPad

=item gestaltMacPlusKbd

=item gestaltExtADBKbd

=item gestaltStdADBKbd

=item gestaltPrtblADBKbd

=item gestaltPrtblISOKbd

=item gestaltStdISOADBKbd

=item gestaltExtISOADBKbd

=item gestaltADBKbdII

=item gestaltADBISOKbdII

=item gestaltPwrBookADBKbd

=item gestaltPwrBookISOADBKbd

=item gestaltAppleAdjustKeypad

=item gestaltAppleAdjustADBKbd

=item gestaltAppleAdjustISOKbd

=item gestaltJapanAdjustADBKbd

=item gestaltPwrBkExtISOKbd

=item gestaltPwrBkExtJISKbd

=item gestaltPwrBkExtADBKbd

Keyboard types.

=cut
sub gestaltKeyboardType ()         {     'kbd '; }
sub gestaltMacKbd ()               {          1; }
sub gestaltMacAndPad ()            {          2; }
sub gestaltMacPlusKbd ()           {          3; }
sub gestaltExtADBKbd ()            {          4; }
sub gestaltStdADBKbd ()            {          5; }
sub gestaltPrtblADBKbd ()          {          6; }
sub gestaltPrtblISOKbd ()          {          7; }
sub gestaltStdISOADBKbd ()         {          8; }
sub gestaltExtISOADBKbd ()         {          9; }
sub gestaltADBKbdII ()             {         10; }
sub gestaltADBISOKbdII ()          {         11; }
sub gestaltPwrBookADBKbd ()        {         12; }
sub gestaltPwrBookISOADBKbd ()     {         13; }
sub gestaltAppleAdjustKeypad ()    {         14; }
sub gestaltAppleAdjustADBKbd ()    {         15; }
sub gestaltAppleAdjustISOKbd ()    {         16; }
sub gestaltJapanAdjustADBKbd ()    {         17; }
sub gestaltPwrBkExtISOKbd ()       {         20; }
sub gestaltPwrBkExtJISKbd ()       {         21; }
sub gestaltPwrBkExtADBKbd ()       {         24; }


=item gestaltLowMemorySize

Size of low memory area.

=cut
sub gestaltLowMemorySize ()        {     'lmem'; }


=item gestaltLogicalRAMSize

Locical RAM size.

=cut
sub gestaltLogicalRAMSize ()       {     'lram'; }


=item gestaltMachineType

=item gestaltClassic

=item gestaltMacXL

=item gestaltMac512KE

=item gestaltMacPlus

=item gestaltMacSE

=item gestaltMacII

=item gestaltMacIIx

=item gestaltMacIIcx

=item gestaltMacSE030

=item gestaltPortable

=item gestaltMacIIci

=item gestaltMacIIfx

=item gestaltMacClassic

=item gestaltMacIIsi

=item gestaltMacLC

=item gestaltQuadra900

=item gestaltPowerBook170

=item gestaltQuadra700

=item gestaltClassicII

=item gestaltPowerBook100

=item gestaltPowerBook140

=item gestaltQuadra950

=item gestaltMacLCIII

=item gestaltPerforma450

=item gestaltPowerBookDuo210

=item gestaltMacCentris650

=item gestaltPowerBookDuo230

=item gestaltPowerBook180

=item gestaltPowerBook160

=item gestaltMacQuadra800

=item gestaltMacQuadra650

=item gestaltMacLCII

=item gestaltPowerBookDuo250

=item gestaltAWS9150_80

=item gestaltPowerMac8100_110

=item gestaltAWS8150_110

=item gestaltMacIIvi

=item gestaltMacIIvm

=item gestaltPerforma600

=item gestaltPowerMac7100_80

=item gestaltMacIIvx

=item gestaltMacColorClassic

=item gestaltPerforma250

=item gestaltPowerBook165c

=item gestaltMacCentris610

=item gestaltMacQuadra610

=item gestaltPowerBook145

=item gestaltPowerMac8100_100

=item gestaltMacLC520

=item gestaltAWS9150_120

=item gestaltMacCentris660AV

=item gestaltPerforma46x

=item gestaltPowerMac8100_80

=item gestaltAWS8150_80

=item gestaltPowerBook180c

=item gestaltPowerMac6100_60

=item gestaltAWS6150_60

=item gestaltPowerBookDuo270c

=item gestaltMacQuadra840AV

=item gestaltPerforma550

=item gestaltPowerBook165

=item gestaltMacTV

=item gestaltMacLC475

=item gestaltPerforma47x

=item gestaltMacLC575

=item gestaltMacQuadra605

=item gestaltQuadra630

=item gestaltPowerMac6100_66

=item gestaltAWS6150_66

=item gestaltPowerBookDuo280

=item gestaltPowerBookDuo280c

=item gestaltPowerMac7100_66

=item gestaltPowerBook150

Macintosh system type.

=cut
sub gestaltMachineType ()          {     'mach'; }
sub gestaltClassic ()              {          1; }
sub gestaltMacXL ()                {          2; }
sub gestaltMac512KE ()             {          3; }
sub gestaltMacPlus ()              {          4; }
sub gestaltMacSE ()                {          5; }
sub gestaltMacII ()                {          6; }
sub gestaltMacIIx ()               {          7; }
sub gestaltMacIIcx ()              {          8; }
sub gestaltMacSE030 ()             {          9; }
sub gestaltPortable ()             {         10; }
sub gestaltMacIIci ()              {         11; }
sub gestaltMacIIfx ()              {         13; }
sub gestaltMacClassic ()           {         17; }
sub gestaltMacIIsi ()              {         18; }
sub gestaltMacLC ()                {         19; }
sub gestaltQuadra900 ()            {         20; }
sub gestaltPowerBook170 ()         {         21; }
sub gestaltQuadra700 ()            {         22; }
sub gestaltClassicII ()            {         23; }
sub gestaltPowerBook100 ()         {         24; }
sub gestaltPowerBook140 ()         {         25; }
sub gestaltQuadra950 ()            {         26; }
sub gestaltMacLCIII ()             {         27; }
sub gestaltPerforma450 ()          { gestaltMacLCIII; }
sub gestaltPowerBookDuo210 ()      {         29; }
sub gestaltMacCentris650 ()        {         30; }
sub gestaltPowerBookDuo230 ()      {         32; }
sub gestaltPowerBook180 ()         {         33; }
sub gestaltPowerBook160 ()         {         34; }
sub gestaltMacQuadra800 ()         {         35; }
sub gestaltMacQuadra650 ()         {         36; }
sub gestaltMacLCII ()              {         37; }
sub gestaltPowerBookDuo250 ()      {         38; }
sub gestaltAWS9150_80 ()           {         39; }
sub gestaltPowerMac8100_110 ()     {         40; }
sub gestaltAWS8150_110 ()          { gestaltPowerMac8100_110; }
sub gestaltMacIIvi ()              {         44; }
sub gestaltMacIIvm ()              {         45; }
sub gestaltPerforma600 ()          { gestaltMacIIvm; }
sub gestaltPowerMac7100_80 ()      {         47; }
sub gestaltMacIIvx ()              {         48; }
sub gestaltMacColorClassic ()      {         49; }
sub gestaltPerforma250 ()          { gestaltMacColorClassic; }
sub gestaltPowerBook165c ()        {         50; }
sub gestaltMacCentris610 ()        {         52; }
sub gestaltMacQuadra610 ()         {         53; }
sub gestaltPowerBook145 ()         {         54; }
sub gestaltPowerMac8100_100 ()     {         55; }
sub gestaltMacLC520 ()             {         56; }
sub gestaltAWS9150_120 ()          {         57; }
sub gestaltMacCentris660AV ()      {         60; }
sub gestaltPerforma46x ()          {         62; }
sub gestaltPowerMac8100_80 ()      {         65; }
sub gestaltAWS8150_80 ()           { gestaltPowerMac8100_80; }
sub gestaltPowerBook180c ()        {         71; }
sub gestaltPowerMac6100_60 ()      {         75; }
sub gestaltAWS6150_60 ()           { gestaltPowerMac6100_60; }
sub gestaltPowerBookDuo270c ()     {         77; }
sub gestaltMacQuadra840AV ()       {         78; }
sub gestaltPerforma550 ()          {         80; }
sub gestaltPowerBook165 ()         {         84; }
sub gestaltMacTV ()                {         88; }
sub gestaltMacLC475 ()             {         89; }
sub gestaltPerforma47x ()          { gestaltMacLC475; }
sub gestaltMacLC575 ()             {         92; }
sub gestaltMacQuadra605 ()         {         94; }
sub gestaltQuadra630 ()            {         98; }
sub gestaltPowerMac6100_66 ()      {        100; }
sub gestaltAWS6150_66 ()           { gestaltPowerMac6100_66; }
sub gestaltPowerBookDuo280 ()      {        102; }
sub gestaltPowerBookDuo280c ()     {        103; }
sub gestaltPowerMac7100_66 ()      {        112; }
sub gestaltPowerBook150 ()         {        115; }


=item kMachineNameStrID

Resource ID of C<'STR '> resource containing machine type.

=cut
sub kMachineNameStrID ()           {     -16395; }


=item gestaltMachineIcon

Machine icon.

=cut
sub gestaltMachineIcon ()          {     'micn'; }


=item gestaltMiscAttr

=item gestaltScrollingThrottle

=item gestaltSquareMenuBar

Miscellaneous attributes.

=cut
sub gestaltMiscAttr ()             {     'misc'; }
sub gestaltScrollingThrottle ()    {          0; }
sub gestaltSquareMenuBar ()        {          2; }


=item gestaltMixedModeVersion

=item gestaltMixedModeAttr

=item gestaltPowerPCAware

Mixed mode manager.

=cut
sub gestaltMixedModeVersion ()     {     'mixd'; }
sub gestaltMixedModeAttr ()        {     'mixd'; }
sub gestaltPowerPCAware ()         {          0; }


=item gestaltMMUType

=item gestaltNoMMU

=item gestaltAMU

=item gestalt68851

=item gestalt68030MMU

=item gestalt68040MMU

=item gestaltEMMU1

680X0 MMU types.

=cut
sub gestaltMMUType ()              {     'mmu '; }
sub gestaltNoMMU ()                {          0; }
sub gestaltAMU ()                  {          1; }
sub gestalt68851 ()                {          2; }
sub gestalt68030MMU ()             {          3; }
sub gestalt68040MMU ()             {          4; }
sub gestaltEMMU1 ()                {          5; }


=item gestaltStdNBPAttr

=item gestaltStdNBPPresent

Standard NBP dialog.

=cut
sub gestaltStdNBPAttr ()           {     'nlup'; }
sub gestaltStdNBPPresent ()        {          0; }


=item gestaltNotificationMgrAttr

=item gestaltNotificationPresent

Notification manager.

=cut
sub gestaltNotificationMgrAttr ()  {     'nmgr'; }
sub gestaltNotificationPresent ()  {          0; }


=item gestaltNameRegistryVersion

Name registry.

=cut
sub gestaltNameRegistryVersion ()  {     'nreg'; }


=item gestaltNuBusSlotCount

Number of NuBus solts.

=cut
sub gestaltNuBusSlotCount ()       {     'nubs'; }


=item gestaltOpenFirmwareInfo

Open firmware.

=cut
sub gestaltOpenFirmwareInfo ()     {     'opfw'; }


=item gestaltOSAttr

=item gestaltSysZoneGrowable

=item gestaltLaunchCanReturn

=item gestaltLaunchFullFileSpec

=item gestaltLaunchControl

=item gestaltTempMemSupport

=item gestaltRealTempMemory

=item gestaltTempMemTracked

=item gestaltIPCSupport

=item gestaltSysDebuggerSupport

OS attributes.

=cut
sub gestaltOSAttr ()               {     'os  '; }
sub gestaltSysZoneGrowable ()      {          0; }
sub gestaltLaunchCanReturn ()      {          1; }
sub gestaltLaunchFullFileSpec ()   {          2; }
sub gestaltLaunchControl ()        {          3; }
sub gestaltTempMemSupport ()       {          4; }
sub gestaltRealTempMemory ()       {          5; }
sub gestaltTempMemTracked ()       {          6; }
sub gestaltIPCSupport ()           {          7; }
sub gestaltSysDebuggerSupport ()   {          8; }


=item gestaltOSTable

OS Trap table.

=cut
sub gestaltOSTable ()              {     'ostt'; }


=item gestaltPCXAttr

=item gestaltPCXHas8and16BitFAT

=item gestaltPCXHasProDOS

PC Exchange.

=cut
sub gestaltPCXAttr ()              {     'pcxg'; }
sub gestaltPCXHas8and16BitFAT ()   {          0; }
sub gestaltPCXHasProDOS ()         {          1; }


=item gestaltLogicalPageSize

Logical memory page size.

=cut
sub gestaltLogicalPageSize ()      {     'pgsz'; }


=item gestaltPopupAttr

=item gestaltPopupPresent

Popup menu controls.

=cut
sub gestaltPopupAttr ()            {     'pop!'; }
sub gestaltPopupPresent ()         {          0; }


=item gestaltPowerMgrAttr

=item gestaltPMgrExists

=item gestaltPMgrCPUIdle

=item gestaltPMgrSCC

=item gestaltPMgrSound

=item gestaltPMgrDispatchExists

Power manager.

=cut
sub gestaltPowerMgrAttr ()         {     'powr'; }
sub gestaltPMgrExists ()           {          0; }
sub gestaltPMgrCPUIdle ()          {          1; }
sub gestaltPMgrSCC ()              {          2; }
sub gestaltPMgrSound ()            {          3; }
sub gestaltPMgrDispatchExists ()   {          4; }


=item gestaltPPCToolboxAttr

=item gestaltPPCToolboxPresent

=item gestaltPPCSupportsRealTime

=item gestaltPPCSupportsIncoming

=item gestaltPPCSupportsOutGoing

Process-to-Process communications toolbox.

=cut
sub gestaltPPCToolboxAttr ()       {     'ppc '; }
sub gestaltPPCToolboxPresent ()    {     0x0000; }
sub gestaltPPCSupportsRealTime ()  {     0x1000; }
sub gestaltPPCSupportsIncoming ()  {     0x0001; }
sub gestaltPPCSupportsOutGoing ()  {     0x0002; }


=item gestaltProcessorType

=item gestalt68000

=item gestalt68010

=item gestalt68020

=item gestalt68030

=item gestalt68040

Processor type.

=cut
sub gestaltProcessorType ()        {     'proc'; }
sub gestalt68000 ()                {          1; }
sub gestalt68010 ()                {          2; }
sub gestalt68020 ()                {          3; }
sub gestalt68030 ()                {          4; }
sub gestalt68040 ()                {          5; }


=item gestaltParityAttr

=item gestaltHasParityCapability

=item gestaltParityEnabled

Memory parity checking.

=cut
sub gestaltParityAttr ()           {     'prty'; }
sub gestaltHasParityCapability ()  {          0; }
sub gestaltParityEnabled ()        {          1; }


=item gestaltQuickdrawVersion

=item gestaltOriginalQD

=item gestalt8BitQD

=item gestalt32BitQD

=item gestalt32BitQD11

=item gestalt32BitQD12

=item gestalt32BitQD13

QuickDraw attributes.

=cut
sub gestaltQuickdrawVersion ()     {     'qd  '; }
sub gestaltOriginalQD ()           {      0x000; }
sub gestalt8BitQD ()               {      0x100; }
sub gestalt32BitQD ()              {      0x200; }
sub gestalt32BitQD11 ()            {      0x201; }
sub gestalt32BitQD12 ()            {      0x220; }
sub gestalt32BitQD13 ()            {      0x230; }


=item gestaltQuickdrawFeatures

=item gestaltHasColor

=item gestaltHasDeepGWorlds

=item gestaltHasDirectPixMaps

=item gestaltHasGrayishTextOr

=item gestaltSupportsMirroring

QuickDraw features.

=cut
sub gestaltQuickdrawFeatures ()    {     'qdrw'; }
sub gestaltHasColor ()             {          0; }
sub gestaltHasDeepGWorlds ()       {          1; }
sub gestaltHasDirectPixMaps ()     {          2; }
sub gestaltHasGrayishTextOr ()     {          3; }
sub gestaltSupportsMirroring ()    {          4; }


=item gestaltQuickTimeVersion

=item gestaltQuickTime

QuickTime.

=cut
sub gestaltQuickTimeVersion ()     {     'qtim'; }
sub gestaltQuickTime ()            {     'qtim'; }


=item gestaltQuickTimeFeatures

=item gestaltPPCQuickTimeLibPresent

QuickTime features.

=cut
sub gestaltQuickTimeFeatures ()    {     'qtrs'; }
sub gestaltPPCQuickTimeLibPresent () {          0; }


=item gestaltPhysicalRAMSize

Size of physical RAM.

=cut
sub gestaltPhysicalRAMSize ()      {     'ram '; }


=item gestaltRBVAddr

RBV, whatever that is.

=cut
sub gestaltRBVAddr ()              {     'rbv '; }


=item gestaltROMSize

Size of built in ROM.

=cut
sub gestaltROMSize ()              {     'rom '; }


=item gestaltROMVersion

ROM version.

=cut
sub gestaltROMVersion ()           {     'romv'; }


=item gestaltResourceMgrAttr

=item gestaltPartialRsrcs

Resource manager.

=cut
sub gestaltResourceMgrAttr ()      {     'rsrc'; }
sub gestaltPartialRsrcs ()         {          0; }


=item gestaltRealtimeMgrAttr

=item gestaltRealtimeMgrPresent

Realtime manager.

=cut
sub gestaltRealtimeMgrAttr ()      {     'rtmr'; }
sub gestaltRealtimeMgrPresent ()   {          0; }


=item gestaltSCCReadAddr

Serial controller read address.

=cut
sub gestaltSCCReadAddr ()          {     'sccr'; }


=item gestaltSCCWriteAddr

Serial controller write address.

=cut
sub gestaltSCCWriteAddr ()         {     'sccw'; }


=item gestaltScrapMgrAttr

=item gestaltScrapMgrTranslationAware

Scrap manager.

=cut
sub gestaltScrapMgrAttr ()         {     'scra'; }
sub gestaltScrapMgrTranslationAware () {          0; }


=item gestaltScriptMgrVersion

Script manager/

=cut
sub gestaltScriptMgrVersion ()     {     'scri'; }


=item gestaltScriptCount

Number of installed script systems.

=cut
sub gestaltScriptCount ()          {     'scr#'; }


=item gestaltSCSI

=item gestaltAsyncSCSI

=item gestaltAsyncSCSIINROM

=item gestaltSCSISlotBoot

SCSI manager.

=cut
sub gestaltSCSI ()                 {     'scsi'; }
sub gestaltAsyncSCSI ()            {          0; }
sub gestaltAsyncSCSIINROM ()       {          1; }
sub gestaltSCSISlotBoot ()         {          2; }


=item gestaltControlStripAttr

=item gestaltControlStripExists

=item gestaltControlStripVersionFixed

=item gestaltControlStripUserFont

=item gestaltControlStripUserHotKey

Control strip attributes.

=cut
sub gestaltControlStripAttr ()     		{     'sdev'; }
sub gestaltControlStripExists ()   		{          0; }
sub gestaltControlStripVersionFixed ()	{          1; }
sub gestaltControlStripUserFont () 		{          2; }
sub gestaltControlStripUserHotKey () 	{          3; }


=item gestaltSerialAttr

=item gestaltHasGPIaToDCDa

=item gestaltHasGPIaToRTxCa

=item gestaltHasGPIbToDCDb

Serial atrributes.

=cut
sub gestaltSerialAttr ()           {     'ser '; }
sub gestaltHasGPIaToDCDa ()        {          0; }
sub gestaltHasGPIaToRTxCa ()       {          1; }
sub gestaltHasGPIbToDCDb ()        {          2; }


=item gestaltNuBusConnectors

Number of NuBus connectors.

=cut
sub gestaltNuBusConnectors ()      {     'sltc'; }


=item gestaltSlotAttr

=item gestaltSlotMgrExists

=item gestaltNuBusPresent

=item gestaltSESlotPresent

=item gestaltSE30SlotPresent

=item gestaltPortableSlotPresent

Slot attributes.

=cut
sub gestaltSlotAttr ()             {     'slot'; }
sub gestaltSlotMgrExists ()        {          0; }
sub gestaltNuBusPresent ()         {          1; }
sub gestaltSESlotPresent ()        {          2; }
sub gestaltSE30SlotPresent ()      {          3; }
sub gestaltPortableSlotPresent ()  {          4; }


=item gestaltFirstSlotNumber

Number of first slot.

=cut
sub gestaltFirstSlotNumber ()      {     'slt1'; }


=item gestaltSoundAttr

=item gestaltStereoCapability

=item gestaltStereoMixing

=item gestaltSoundIOMgrPresent

=item gestaltBuiltInSoundInput

=item gestaltHasSoundInputDevice

=item gestaltPlayAndRecord

=item gestalt16BitSoundIO

=item gestaltStereoInput

=item gestaltLineLevelInput

=item gestaltSndPlayDoubleBuffer

=item gestaltMultiChannels

=item gestalt16BitAudioSupport

Sound attributes.

=cut
sub gestaltSoundAttr ()            {     'snd '; }
sub gestaltStereoCapability ()     {          0; }
sub gestaltStereoMixing ()         {          1; }
sub gestaltSoundIOMgrPresent ()    {          3; }
sub gestaltBuiltInSoundInput ()    {          4; }
sub gestaltHasSoundInputDevice ()  {          5; }
sub gestaltPlayAndRecord ()        {          6; }
sub gestalt16BitSoundIO ()         {          7; }
sub gestaltStereoInput ()          {          8; }
sub gestaltLineLevelInput ()       {          9; }
sub gestaltSndPlayDoubleBuffer ()  {         10; }
sub gestaltMultiChannels ()        {         11; }
sub gestalt16BitAudioSupport ()    {         12; }


=item gestaltStandardFileAttr

=item gestaltStandardFile58

=item gestaltStandardFileTranslationAware

=item gestaltStandardFileHasColorIcons

=item gestaltStandardFileUseGenericIcons

=item gestaltStandardFileHasDynamicVolumeAllocation

Standard file manager attributes.

=cut
sub gestaltStandardFileAttr ()     						{     'stdf'; }
sub gestaltStandardFile58 ()       						{          0; }
sub gestaltStandardFileTranslationAware () 				{          1; }
sub gestaltStandardFileHasColorIcons () 				{          2; }
sub gestaltStandardFileUseGenericIcons () 				{          3; }
sub gestaltStandardFileHasDynamicVolumeAllocation ()	{          4; }


=item gestaltSysArchitecture

=item gestalt68k

=item gestaltPowerPC

System architecture.

=cut
sub gestaltSysArchitecture ()      {     'sysa'; }
sub gestalt68k ()                  {          1; }
sub gestaltPowerPC ()              {          2; }


=item gestaltSystemVersion

System version.

=cut
sub gestaltSystemVersion ()        {     'sysv'; }


=item gestaltTSMgrVersion

=item gestaltTSMgr2

Text system manager.

=cut
sub gestaltTSMgrVersion ()         {     'tsmv'; }
sub gestaltTSMgr2 ()               {      0x200; }


=item gestaltTSMgrAttr

=item gestaltTSMDisplayMgrAwareBit

=item gestaltTSMdoesTSMTEBit

Text system manager attributes.

=cut
sub gestaltTSMgrAttr ()            {     'tsma'; }
sub gestaltTSMDisplayMgrAwareBit () {          0; }
sub gestaltTSMdoesTSMTEBit ()      {          1; }


=item gestaltTSMTEVersion

=item gestaltTSMTE1

=item gestaltTSMTE2

Text system manager for TextEdit.

=cut
sub gestaltTSMTEVersion ()         {     'tmTV'; }
sub gestaltTSMTE1 ()               {      0x100; }
sub gestaltTSMTE2 ()               {      0x200; }


=item gestaltTSMTEAttr

=item gestaltTSMTEPresent

=item gestaltTSMTE

Text system manager for TextEdit attributes.

=cut
sub gestaltTSMTEAttr ()            {     'tmTE'; }
sub gestaltTSMTEPresent ()         {          0; }
sub gestaltTSMTE ()                {          0; }


=item gestaltTextEditVersion

=item gestaltTE1

=item gestaltTE2

=item gestaltTE3

=item gestaltTE4

=item gestaltTE5

=item gestaltTE6

TextEdit manager.

=cut
sub gestaltTextEditVersion ()      {     'te  '; }
sub gestaltTE1 ()                  {          1; }
sub gestaltTE2 ()                  {          2; }
sub gestaltTE3 ()                  {          3; }
sub gestaltTE4 ()                  {          4; }
sub gestaltTE5 ()                  {          5; }
sub gestaltTE6 ()                  {          6; }


=item gestaltTEAttr

=item gestaltTEHasGetHiliteRgn

=item gestaltTESupportsInlineInput

=item gestaltTESupportsTextObjects

TextEdit attributes.

=cut
sub gestaltTEAttr ()              	{     'teat'; }
sub gestaltTEHasGetHiliteRgn ()		{          0; }
sub gestaltTESupportsInlineInput ()	{          1; }
sub gestaltTESupportsTextObjects ()	{          2; }


=item gestaltTeleMgrAttr

=item gestaltTeleMgrPresent

=item gestaltTeleMgrPowerPCSupport

=item gestaltTeleMgrSoundStreams

=item gestaltTeleMgrAutoAnswer

=item gestaltTeleMgrIndHandset

=item gestaltTeleMgrSilenceDetect

=item gestaltTeleMgrNewTELNewSupport

Telephone attributes.

=cut
sub gestaltTeleMgrAttr ()          	{     'tele'; }
sub gestaltTeleMgrPresent ()       	{          0; }
sub gestaltTeleMgrPowerPCSupport () {          1; }
sub gestaltTeleMgrSoundStreams ()  	{          2; }
sub gestaltTeleMgrAutoAnswer ()    	{          3; }
sub gestaltTeleMgrIndHandset ()    	{          4; }
sub gestaltTeleMgrSilenceDetect () 	{          5; }
sub gestaltTeleMgrNewTELNewSupport () {          6; }


=item gestaltTermMgrAttr

=item gestaltTermMgrPresent

=item gestaltTermMgrErrorString

Communications toolbox terminal manager.

=cut
sub gestaltTermMgrAttr ()          {     'term'; }
sub gestaltTermMgrPresent ()       {          0; }
sub gestaltTermMgrErrorString ()   {          2; }


=item gestaltTimeMgrVersion

=item gestaltStandardTimeMgr

=item gestaltRevisedTimeMgr

=item gestaltExtendedTimeMgr

Time manager.

=cut
sub gestaltTimeMgrVersion ()       {     'tmgr'; }
sub gestaltStandardTimeMgr ()      {          1; }
sub gestaltRevisedTimeMgr ()       {          2; }
sub gestaltExtendedTimeMgr ()      {          3; }


=item gestaltSpeechAttr

=item gestaltSpeechMgrPresent

=item gestaltSpeechHasPPCGlue

Speech synthesis manager.

=cut
sub gestaltSpeechAttr ()           {     'ttsc'; }
sub gestaltSpeechMgrPresent ()     {          0; }
sub gestaltSpeechHasPPCGlue ()     {          1; }


=item gestaltToolboxTable

Toolbox dispatch table.

=cut
sub gestaltToolboxTable ()         {     'tbtt'; }


=item gestaltThreadMgrAttr

=item gestaltThreadMgrPresent

=item gestaltSpecificMatchSupport

=item gestaltThreadsLibraryPresent

Thread manager.

=cut
sub gestaltThreadMgrAttr ()        	{     'thds'; }
sub gestaltThreadMgrPresent ()     	{          0; }
sub gestaltSpecificMatchSupport () 	{          1; }
sub gestaltThreadsLibraryPresent () {          2; }


=item gestaltTVAttr

=item gestaltHasTVTuner

=item gestaltHasSoundFader

=item gestaltHasHWClosedCaptioning

=item gestaltHasIRRemote

=item gestaltHasVidDecoderScaler

=item gestaltHasStereoDecoder

TV interface.

=cut
sub gestaltTVAttr ()               	{     'tv  '; }
sub gestaltHasTVTuner ()           	{          0; }
sub gestaltHasSoundFader ()        	{          1; }
sub gestaltHasHWClosedCaptioning () {          2; }
sub gestaltHasIRRemote ()          	{          3; }
sub gestaltHasVidDecoderScaler ()  	{          4; }
sub gestaltHasStereoDecoder ()     	{          5; }


=item gestaltVersion

=item gestaltValueImplementedVers

Gestalt version.

=cut
sub gestaltVersion ()              {     'vers'; }
sub gestaltValueImplementedVers () {          5; }


=item gestaltVIA1Addr

=item gestaltVIA2Addr

VIA addresses.

=cut
sub gestaltVIA1Addr ()             {     'via1'; }
sub gestaltVIA2Addr ()             {     'via2'; }


=item gestaltVMAttr

=item gestaltVMPresent

Virtual memory.

=cut
sub gestaltVMAttr ()               {     'vm  '; }
sub gestaltVMPresent ()            {          0; }


=item gestaltTranslationAttr

=item gestaltTranslationMgrExists

=item gestaltTranslationMgrHintOrder

=item gestaltTranslationPPCAvail

=item gestaltTranslationGetPathAPIAvail

Translation manager.

=cut
sub gestaltTranslationAttr ()      			{     'xlat'; }
sub gestaltTranslationMgrExists () 			{          0; }
sub gestaltTranslationMgrHintOrder () 		{          1; }
sub gestaltTranslationPPCAvail ()  			{          2; }
sub gestaltTranslationGetPathAPIAvail () 	{          3; }


=item gestaltExtToolboxTable

Extended toolbox dispatch table.

=cut
sub gestaltExtToolboxTable ()      {     'xttt'; }

=back

=include Gestalt.xs

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> Author

Bob Dalgleish <bob.dalgleish@sasknet.sk.ca> Documenter

=cut

1;

__END__
