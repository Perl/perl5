=head1 NAME

MacOS Low Memory Globals.

Provide the MacPerl interface to the low memory global variables.

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=head1 SYNOPSIS

	use Mac::LowMem;
	use Mac::QuickDraw;
	
	LMSetMBarHeight(55);
	
	$l = LMGetMouseLocation();
	
	print $l, "\n", $l->h, " ", $l->v, "\n";

=head1 DESCRIPTION

The following routines make it possible to get and set low memory variables.

=cut

use strict;

package Mac::LowMem;

BEGIN {
    use Exporter   ();
	use Mac::Memory();
	use Carp;
    
    use vars qw(@ISA @EXPORT $AUTOLOAD);
    
    @ISA = qw(Exporter);
    @EXPORT = qw(
		LMGetScrVRes
		LMGetScrHRes
		LMGetMemTop
		LMGetBufPtr
		LMGetHeapEnd
		LMGetTheZone
		LMGetUTableBase
		LMGetCPUFlag
		LMGetApplLimit
		LMGetSysEvtMask
		LMGetRndSeed
		LMGetSEvtEnb
		LMGetTicks
		LMGetKeyThresh
		LMGetKeyRepThresh
		LMGetVIA
		LMGetSCCRd
		LMGetSCCWr
		LMGetSPValid
		LMGetSPATalkA
		LMGetSPATalkB
		LMGetSPConfig
		LMGetSPPortA
		LMGetSPPortB
		LMGetSPAlarm
		LMGetSPFont
		LMGetSPKbd
		LMGetSPPrint
		LMGetSPVolCtl
		LMGetSPClikCaret
		LMGetSPMisc2
		LMGetTime
		LMGetBootDrive
		LMGetSFSaveDisk
		LMGetKbdLast
		LMGetKbdType
		LMGetMemErr
		LMGetSdVolume
		LMGetSoundPtr
		LMGetSoundBase
		LMGetSoundLevel
		LMGetCurPitch
		LMGetROM85
		LMGetPortBUse
		LMGetSysZone
		LMGetApplZone
		LMGetROMBase
		LMGetRAMBase
		LMGetDSAlertTab
		LMGetABusVars
		LMGetABusDCE
		LMGetDoubleTime
		LMGetCaretTime
		LMGetScrDmpEnb
		LMGetBufTgFNum
		LMGetBufTgFFlg
		LMGetBufTgFBkNum
		LMGetBufTgDate
		LMGetLo3Bytes
		LMGetMinStack
		LMGetDefltStack
		LMGetGZRootHnd
		LMGetGZMoveHnd
		LMGetFCBSPtr
		LMGetDefVCBPtr
		LMGetCurDirStore
		LMGetFSFCBLen
		LMGetScrnBase
		LMGetMainDevice
		LMGetDeviceList
		LMGetQDColors
		LMGetCrsrBusy
		LMGetWidthListHand
		LMGetJournalRef
		LMGetCrsrThresh
		LMGetCurApRefNum
		LMGetCurrentA5
		LMGetCurStackBase
		LMGetCurJTOffset
		LMGetCurPageOption
		LMGetHiliteMode
		LMGetPrintErr
		LMGetScrapSize
		LMGetScrapHandle
		LMGetScrapCount
		LMGetScrapState
		LMGetROMFont0
		LMGetApFontID
		LMGetWindowList
		LMGetSaveUpdate
		LMGetPaintWhite
		LMGetWMgrPort
		LMGetGrayRgn
		LMGetGhostWindow
		LMGetAuxWinHead
		LMGetCurActivate
		LMGetCurDeactive
		LMGetOldStructure
		LMGetOldContent
		LMGetSaveVisRgn
		LMGetOneOne
		LMGetMinusOne
		LMGetTopMenuItem
		LMGetAtMenuBottom
		LMGetMenuList
		LMGetMBarEnable
		LMGetMenuFlash
		LMGetTheMenu
		LMGetTopMapHndl
		LMGetSysMapHndl
		LMGetSysMap
		LMGetCurMap
		LMGetResLoad
		LMGetResErr
		LMGetFScaleDisable
		LMGetANumber
		LMGetACount
		LMGetTEScrpLength
		LMGetTEScrpHandle
		LMGetAppParmHandle
		LMGetDSErrCode
		LMGetDlgFont
		LMGetWidthPtr
		LMGetATalkHk2
		LMGetHWCfgFlags
		LMGetWidthTabHandle
		LMGetLastSPExtra
		LMGetMenuDisable
		LMGetROMMapInsert
		LMGetTmpResLoad
		LMGetIntlSpec
		LMGetWordRedraw
		LMGetSysFontFam
		LMGetSysFontSize
		LMGetMBarHeight
		LMGetTESysJust
		LMGetLastFOND
		LMGetFractEnable
		LMGetMMU32Bit
		LMGetTheGDevice
		LMGetDeskCPat
		LMGetTimeDBRA
		LMGetTimeSCCDB
		LMGetSynListHandle
		LMGetMenuCInfo
		LMGetTimeSCSIDB
		LMGetCursorNew
		LMGetMouseButtonState
		LMGetMouseTemp
		LMGetRawMouseLocation
		LMGetMouseLocation
		LMGetHighHeapMark
		LMGetStackLowPoint
		LMGetROMMapHandle
		LMGetUnitTableEntryCount
		LMGetDiskFormatingHFSDefaults
		LMGetPortAInfo

		LMSetScrVRes
		LMSetScrHRes
		LMSetMemTop
		LMSetBufPtr
		LMSetHeapEnd
		LMSetTheZone
		LMSetUTableBase
		LMSetCPUFlag
		LMSetApplLimit
		LMSetSysEvtMask
		LMSetRndSeed
		LMSetSEvtEnb
		LMSetTicks
		LMSetKeyThresh
		LMSetKeyRepThresh
		LMSetVIA
		LMSetSCCRd
		LMSetSCCWr
		LMSetSPValid
		LMSetSPATalkA
		LMSetSPATalkB
		LMSetSPConfig
		LMSetSPPortA
		LMSetSPPortB
		LMSetSPAlarm
		LMSetSPFont
		LMSetSPKbd
		LMSetSPPrint
		LMSetSPVolCtl
		LMSetSPClikCaret
		LMSetSPMisc2
		LMSetTime
		LMSetBootDrive
		LMSetSFSaveDisk
		LMSetKbdLast
		LMSetKbdType
		LMSetMemErr
		LMSetSdVolume
		LMSetSoundPtr
		LMSetSoundBase
		LMSetSoundLevel
		LMSetCurPitch
		LMSetROM85
		LMSetPortBUse
		LMSetSysZone
		LMSetApplZone
		LMSetROMBase
		LMSetRAMBase
		LMSetDSAlertTab
		LMSetABusVars
		LMSetABusDCE
		LMSetDoubleTime
		LMSetCaretTime
		LMSetScrDmpEnb
		LMSetBufTgFNum
		LMSetBufTgFFlg
		LMSetBufTgFBkNum
		LMSetBufTgDate
		LMSetLo3Bytes
		LMSetMinStack
		LMSetDefltStack
		LMSetGZRootHnd
		LMSetGZMoveHnd
		LMSetFCBSPtr
		LMSetDefVCBPtr
		LMSetCurDirStore
		LMSetFSFCBLen
		LMSetScrnBase
		LMSetMainDevice
		LMSetDeviceList
		LMSetQDColors
		LMSetCrsrBusy
		LMSetWidthListHand
		LMSetJournalRef
		LMSetCrsrThresh
		LMSetCurApRefNum
		LMSetCurrentA5
		LMSetCurStackBase
		LMSetCurJTOffset
		LMSetCurPageOption
		LMSetHiliteMode
		LMSetPrintErr
		LMSetScrapSize
		LMSetScrapHandle
		LMSetScrapCount
		LMSetScrapState
		LMSetROMFont0
		LMSetApFontID
		LMSetSaveUpdate
		LMSetPaintWhite
		LMSetWMgrPort
		LMSetWindowList
		LMSetGhostWindow
		LMSetAuxWinHead
		LMSetCurActivate
		LMSetCurDeactive
		LMSetOldStructure
		LMSetOldContent
		LMSetGrayRgn
		LMSetSaveVisRgn
		LMSetOneOne
		LMSetMinusOne
		LMSetTopMenuItem
		LMSetAtMenuBottom
		LMSetMenuList
		LMSetMBarEnable
		LMSetMenuFlash
		LMSetTheMenu
		LMSetTopMapHndl
		LMSetSysMapHndl
		LMSetSysMap
		LMSetCurMap
		LMSetResLoad
		LMSetResErr
		LMSetFScaleDisable
		LMSetANumber
		LMSetACount
		LMSetTEScrpLength
		LMSetTEScrpHandle
		LMSetAppParmHandle
		LMSetDSErrCode
		LMSetDlgFont
		LMSetWidthPtr
		LMSetATalkHk2
		LMSetHWCfgFlags
		LMSetWidthTabHandle
		LMSetLastSPExtra
		LMSetMenuDisable
		LMSetROMMapInsert
		LMSetTmpResLoad
		LMSetIntlSpec
		LMSetWordRedraw
		LMSetSysFontFam
		LMSetSysFontSize
		LMSetMBarHeight
		LMSetTESysJust
		LMSetLastFOND
		LMSetFractEnable
		LMSetMMU32Bit
		LMSetTheGDevice
		LMSetDeskCPat
		LMSetTimeDBRA
		LMSetTimeSCCDB
		LMSetSynListHandle
		LMSetMenuCInfo
		LMSetTimeSCSIDB
		LMSetCursorNew
		LMSetMouseButtonState
		LMSetMouseTemp
		LMSetRawMouseLocation
		LMSetMouseLocation
		LMSetHighHeapMark
		LMSetStackLowPoint
		LMSetROMMapHandle
		LMSetUnitTableEntryCount
		LMSetDiskFormatingHFSDefaults
		LMSetPortAInfo
    );
}

# The empty line below is needed to simplify the algorithm

my $sGlobals = <<END_GLOBALS;

ABusDCE                   0x02DC 4 L 
ABusVars                  0x02D8 4 L 
ACount                    0x0A9A 2 s 
ANumber                   0x0A98 2 s 
ATalkHk2                  0x0B18 4 L 
ApFontID                  0x0984 2 s 
AppParmHandle             0x0AEC 4 L Handle
ApplLimit                 0x0130 4 L 
ApplZone                  0x02AA 4 L THz
AtMenuBottom              0x0A0C 2 s 
AuxWinHead                0x0CD0 4 L AuxWinHandle
BootDrive                 0x0210 2 s 
BufPtr                    0x010C 4 L 
BufTgDate                 0x0304 4 l 
BufTgFBkNum               0x0302 2 s 
BufTgFFlg                 0x0300 2 s 
BufTgFNum                 0x02FC 4 l 
CPUFlag                   0x012F 1 C 
CaretTime                 0x02F4 4 L 
CrsrBusy                  0x08CD 1 C 
CrsrThresh                0x08EC 2 s 
CurActivate               0x0A64 4 L GrafPtr
CurApRefNum               0x0900 2 s 
CurDeactive               0x0A68 4 L GrafPtr
CurDirStore               0x0398 4 l 
CurJTOffset               0x0934 2 s 
CurMap                    0x0A5A 2 s 
CurPageOption             0x0936 2 s 
CurPitch                  0x0280 2 s 
CurStackBase              0x0908 4 L 
CurrentA5                 0x0904 4 L 
CursorNew                 0x08CE 1 c 
DSAlertTab                0x02BA 4 L 
DSErrCode                 0x0AF0 2 s 
DefVCBPtr                 0x0352 4 L 
DefltStack                0x0322 4 l 
DeskCPat                  0x0CD8 4 L PixPatHandle
DeviceList                0x08A8 4 L GDHandle
DiskFormatingHFSDefaults  0x039E 4 L 
DlgFont                   0x0AFA 2 s 
DoubleTime                0x02F0 4 L 
FCBSPtr                   0x034E 4 L 
FSFCBLen                  0x03F6 2 s 
FScaleDisable             0x0A63 1 C 
FractEnable               0x0BF4 1 C 
GZMoveHnd                 0x0330 4 L Handle
GZRootHnd                 0x0328 4 L Handle
GhostWindow               0x0A84 4 L GrafPtr
GrayRgn                   0x09EE 4 L RgnHandle
HWCfgFlags                0x0B22 2 s 
HeapEnd                   0x0114 4 L 
HighHeapMark              0x0BAE 4 L 
HiliteMode                0x0938 1 C 
IntlSpec                  0x0BA0 4 L 
JournalRef                0x08E8 2 s 
KbdLast                   0x0218 1 C 
KbdType                   0x021E 1 C 
KeyRepThresh              0x0190 2 s 
KeyThresh                 0x018E 2 s 
LastFOND                  0x0BC2 4 L Handle
LastSPExtra               0x0B4C 4 l 
Lo3Bytes                  0x031A 4 l 
MBarEnable                0x0A20 2 s 
MBarHeight                0x0BAA 2 s 
MMU32Bit                  0x0CB2 1 C 
MainDevice                0x08A4 4 L GDHandle
MemErr                    0x0220 2 s 
MemTop                    0x0108 4 L 
MenuCInfo                 0x0D50 4 L MCTableHandle
MenuDisable               0x0B54 4 l 
MenuFlash                 0x0A24 2 s 
MenuList                  0x0A1C 4 L Handle
MinStack                  0x031E 4 l 
MinusOne                  0x0A06 4 l 
MouseButtonState          0x0172 1 C 
MouseLocation             0x0830 8 - Point
MouseTemp                 0x0828 8 - Point
OldContent                0x09EA 4 L RgnHandle
OldStructure              0x09E6 4 L RgnHandle
OneOne                    0x0A02 4 l 
PaintWhite                0x09DC 2 s 
PortAInfo                 0x0290 1 C 
PortBUse                  0x0291 1 C 
PrintErr                  0x0944 2 s 
QDColors                  0x08B0 4 L Handle
RAMBase                   0x02B2 4 L 
ROM85                     0x028E 2 s 
ROMBase                   0x02AE 4 L 
ROMFont0                  0x0980 4 L Handle
ROMMapHandle              0x0B06 4 L Handle
ROMMapInsert              0x0B9E 1 C 
RawMouseLocation          0x082C 8 - Point
ResErr                    0x0A60 2 s 
ResLoad                   0x0A5E 1 C 
RndSeed                   0x0156 4 l 
SCCRd                     0x01D8 4 L 
SCCWr                     0x01DC 4 L 
SEvtEnb                   0x015C 1 C 
SFSaveDisk                0x0214 2 s 
SPATalkA                  0x01F9 1 C 
SPATalkB                  0x01FA 1 C 
SPAlarm                   0x0200 4 l 
SPClikCaret               0x0209 1 C 
SPConfig                  0x01FB 1 C 
SPFont                    0x0204 2 s 
SPKbd                     0x0206 1 C 
SPMisc2                   0x020B 1 C 
SPPortA                   0x01FC 2 s 
SPPortB                   0x01FE 2 s 
SPPrint                   0x0207 1 C 
SPValid                   0x01F8 1 C 
SPVolCtl                  0x0208 1 C 
SaveUpdate                0x09DA 2 s 
SaveVisRgn                0x09F2 4 L RgnHandle
ScrDmpEnb                 0x02F8 1 C 
ScrHRes                   0x0104 2 s 
ScrVRes                   0x0102 2 s 
ScrapCount                0x0968 2 s 
ScrapHandle               0x0964 4 L Handle
ScrapSize                 0x0960 4 l 
ScrapState                0x096A 2 s 
ScrnBase                  0x0824 4 L 
SdVolume                  0x0260 1 C 
SoundBase                 0x0266 4 L 
SoundLevel                0x027F 1 C 
SoundPtr                  0x0262 4 L 
StackLowPoint             0x0110 4 L 
SynListHandle             0x0D32 4 L Handle
SysEvtMask                0x0144 2 s 
SysFontFam                0x0BA6 2 s 
SysFontSize               0x0BA8 2 s 
SysMap                    0x0A58 2 s 
SysMapHndl                0x0A54 4 L Handle
SysZone                   0x02A6 4 L THz
TEScrpHandle              0x0AB4 4 L Handle
TEScrpLength              0x0AB0 2 S 
TESysJust                 0x0BAC 2 s 
TheGDevice                0x0CC8 4 L GDHandle
TheMenu                   0x0A26 2 s 
TheZone                   0x0118 4 L THz
Ticks                     0x016A 4 L 
Time                      0x020C 4 l 
TimeDBRA                  0x0D00 2 s 
TimeSCCDB                 0x0D02 2 s 
TimeSCSIDB                0x0B24 2 s 
TmpResLoad                0x0B9F 1 C 
TopMapHndl                0x0A50 4 L Handle
TopMenuItem               0x0A0A 2 s 
UTableBase                0x011C 4 L 
UnitTableEntryCount       0x01D2 2 s 
VIA                       0x01D4 4 L 
WMgrPort                  0x09DE 4 L GrafPtr
WidthListHand             0x08E4 4 L Handle
WidthPtr                  0x0B10 4 L 
WidthTabHandle            0x0B2A 4 L Handle
WindowList                0x09D6 4 L GrafPtr
WordRedraw                0x0BA5 1 C 
END_GLOBALS

sub _Getter {
	my($addr, $size, $format, $package) = @_;
	my ($data) = bless(\$addr, "Ptr")->get(0, $size);
	$data = unpack($format, $data) unless $format eq "-";
	return $package ? bless(\$data, $package) : $data;
}

sub _Setter {
	my($addr, $format, $package, $data) = @_;
	$data = $$data if $package;
	$data = pack($format, $data) unless $format eq "-";
	bless(\$addr, "Ptr")->set(0, $data);
}

AUTOLOAD {
	{
		my ($gs, $var) = ($AUTOLOAD =~ /LM([GS])et(\w+)/);
		my ($start) = index($sGlobals, "\n$var");
		croak "$AUTOLOAD not defined" if ($start == -1);
		++$start;
		my ($def) = 
			substr($sGlobals, $start, index($sGlobals, "\n", $start)-$start);
		my ($name, $addr, $size, $format, $package) = split(" ", $def);
		if ($gs eq "G") {
			eval<<END_GETTER;
sub $AUTOLOAD {
	_Getter($addr, $size, "$format", "$package");
}
END_GETTER
		} else {
			eval<<END_SETTER;
sub $AUTOLOAD {
	_Setter($addr, "$format", "$package", \$_[0]);
}
END_SETTER
		}
		goto &$AUTOLOAD;
	}
}

__END__

=head2 Getting Variable Values

=over 4

=item 		LMGetScrVRes

=item 		LMGetScrHRes

=item 		LMGetMemTop

=item 		LMGetBufPtr

=item 		LMGetHeapEnd

=item 		LMGetTheZone

=item 		LMGetUTableBase

=item 		LMGetCPUFlag

=item 		LMGetApplLimit

=item 		LMGetSysEvtMask

=item 		LMGetRndSeed

=item 		LMGetSEvtEnb

=item 		LMGetTicks

=item 		LMGetKeyThresh

=item 		LMGetKeyRepThresh

=item 		LMGetVIA

=item 		LMGetSCCRd

=item 		LMGetSCCWr

=item 		LMGetSPValid

=item 		LMGetSPATalkA

=item 		LMGetSPATalkB

=item 		LMGetSPConfig

=item 		LMGetSPPortA

=item 		LMGetSPPortB

=item 		LMGetSPAlarm

=item 		LMGetSPFont

=item 		LMGetSPKbd

=item 		LMGetSPPrint

=item 		LMGetSPVolCtl

=item 		LMGetSPClikCaret

=item 		LMGetSPMisc2

=item 		LMGetTime

=item 		LMGetBootDrive

=item 		LMGetSFSaveDisk

=item 		LMGetKbdLast

=item 		LMGetKbdType

=item 		LMGetMemErr

=item 		LMGetSdVolume

=item 		LMGetSoundPtr

=item 		LMGetSoundBase

=item 		LMGetSoundLevel

=item 		LMGetCurPitch

=item 		LMGetROM85

=item 		LMGetPortBUse

=item 		LMGetSysZone

=item 		LMGetApplZone

=item 		LMGetROMBase

=item 		LMGetRAMBase

=item 		LMGetDSAlertTab

=item 		LMGetABusVars

=item 		LMGetABusDCE

=item 		LMGetDoubleTime

=item 		LMGetCaretTime

=item 		LMGetScrDmpEnb

=item 		LMGetBufTgFNum

=item 		LMGetBufTgFFlg

=item 		LMGetBufTgFBkNum

=item 		LMGetBufTgDate

=item 		LMGetLo3Bytes

=item 		LMGetMinStack

=item 		LMGetDefltStack

=item 		LMGetGZRootHnd

=item 		LMGetGZMoveHnd

=item 		LMGetFCBSPtr

=item 		LMGetDefVCBPtr

=item 		LMGetCurDirStore

=item 		LMGetFSFCBLen

=item 		LMGetScrnBase

=item 		LMGetMainDevice

=item 		LMGetDeviceList

=item 		LMGetQDColors

=item 		LMGetCrsrBusy

=item 		LMGetWidthListHand

=item 		LMGetJournalRef

=item 		LMGetCrsrThresh

=item 		LMGetCurApRefNum

=item 		LMGetCurrentA5

=item 		LMGetCurStackBase

=item 		LMGetCurJTOffset

=item 		LMGetCurPageOption

=item 		LMGetHiliteMode

=item 		LMGetPrintErr

=item 		LMGetScrapSize

=item 		LMGetScrapHandle

=item 		LMGetScrapCount

=item 		LMGetScrapState

=item 		LMGetROMFont0

=item 		LMGetApFontID

=item 		LMGetWindowList

=item 		LMGetSaveUpdate

=item 		LMGetPaintWhite

=item 		LMGetWMgrPort

=item 		LMGetGrayRgn

=item 		LMGetGhostWindow

=item 		LMGetAuxWinHead

=item 		LMGetCurActivate

=item 		LMGetCurDeactive

=item 		LMGetOldStructure

=item 		LMGetOldContent

=item 		LMGetSaveVisRgn

=item 		LMGetOneOne

=item 		LMGetMinusOne

=item 		LMGetTopMenuItem

=item 		LMGetAtMenuBottom

=item 		LMGetMenuList

=item 		LMGetMBarEnable

=item 		LMGetMenuFlash

=item 		LMGetTheMenu

=item 		LMGetTopMapHndl

=item 		LMGetSysMapHndl

=item 		LMGetSysMap

=item 		LMGetCurMap

=item 		LMGetResLoad

=item 		LMGetResErr

=item 		LMGetFScaleDisable

=item 		LMGetANumber

=item 		LMGetACount

=item 		LMGetTEScrpLength

=item 		LMGetTEScrpHandle

=item 		LMGetAppParmHandle

=item 		LMGetDSErrCode

=item 		LMGetDlgFont

=item 		LMGetWidthPtr

=item 		LMGetATalkHk2

=item 		LMGetHWCfgFlags

=item 		LMGetWidthTabHandle

=item 		LMGetLastSPExtra

=item 		LMGetMenuDisable

=item 		LMGetROMMapInsert

=item 		LMGetTmpResLoad

=item 		LMGetIntlSpec

=item 		LMGetWordRedraw

=item 		LMGetSysFontFam

=item 		LMGetSysFontSize

=item 		LMGetMBarHeight

=item 		LMGetTESysJust

=item 		LMGetLastFOND

=item 		LMGetFractEnable

=item 		LMGetMMU32Bit

=item 		LMGetTheGDevice

=item 		LMGetDeskCPat

=item 		LMGetTimeDBRA

=item 		LMGetTimeSCCDB

=item 		LMGetSynListHandle

=item 		LMGetMenuCInfo

=item 		LMGetTimeSCSIDB

=item 		LMGetCursorNew

=item 		LMGetMouseButtonState

=item 		LMGetMouseTemp

=item 		LMGetRawMouseLocation

=item 		LMGetMouseLocation

=item 		LMGetHighHeapMark

=item 		LMGetStackLowPoint

=item 		LMGetROMMapHandle

=item 		LMGetUnitTableEntryCount

=item 		LMGetDiskFormatingHFSDefaults

=item 		LMGetPortAInfo

=back

=head2 Changing Variable Values

=over 4

=item 		LMSetScrVRes

=item 		LMSetScrHRes

=item 		LMSetMemTop

=item 		LMSetBufPtr

=item 		LMSetHeapEnd

=item 		LMSetTheZone

=item 		LMSetUTableBase

=item 		LMSetCPUFlag

=item 		LMSetApplLimit

=item 		LMSetSysEvtMask

=item 		LMSetRndSeed

=item 		LMSetSEvtEnb

=item 		LMSetTicks

=item 		LMSetKeyThresh

=item 		LMSetKeyRepThresh

=item 		LMSetVIA

=item 		LMSetSCCRd

=item 		LMSetSCCWr

=item 		LMSetSPValid

=item 		LMSetSPATalkA

=item 		LMSetSPATalkB

=item 		LMSetSPConfig

=item 		LMSetSPPortA

=item 		LMSetSPPortB

=item 		LMSetSPAlarm

=item 		LMSetSPFont

=item 		LMSetSPKbd

=item 		LMSetSPPrint

=item 		LMSetSPVolCtl

=item 		LMSetSPClikCaret

=item 		LMSetSPMisc2

=item 		LMSetTime

=item 		LMSetBootDrive

=item 		LMSetSFSaveDisk

=item 		LMSetKbdLast

=item 		LMSetKbdType

=item 		LMSetMemErr

=item 		LMSetSdVolume

=item 		LMSetSoundPtr

=item 		LMSetSoundBase

=item 		LMSetSoundLevel

=item 		LMSetCurPitch

=item 		LMSetROM85

=item 		LMSetPortBUse

=item 		LMSetSysZone

=item 		LMSetApplZone

=item 		LMSetROMBase

=item 		LMSetRAMBase

=item 		LMSetDSAlertTab

=item 		LMSetABusVars

=item 		LMSetABusDCE

=item 		LMSetDoubleTime

=item 		LMSetCaretTime

=item 		LMSetScrDmpEnb

=item 		LMSetBufTgFNum

=item 		LMSetBufTgFFlg

=item 		LMSetBufTgFBkNum

=item 		LMSetBufTgDate

=item 		LMSetLo3Bytes

=item 		LMSetMinStack

=item 		LMSetDefltStack

=item 		LMSetGZRootHnd

=item 		LMSetGZMoveHnd

=item 		LMSetFCBSPtr

=item 		LMSetDefVCBPtr

=item 		LMSetCurDirStore

=item 		LMSetFSFCBLen

=item 		LMSetScrnBase

=item 		LMSetMainDevice

=item 		LMSetDeviceList

=item 		LMSetQDColors

=item 		LMSetCrsrBusy

=item 		LMSetWidthListHand

=item 		LMSetJournalRef

=item 		LMSetCrsrThresh

=item 		LMSetCurApRefNum

=item 		LMSetCurrentA5

=item 		LMSetCurStackBase

=item 		LMSetCurJTOffset

=item 		LMSetCurPageOption

=item 		LMSetHiliteMode

=item 		LMSetPrintErr

=item 		LMSetScrapSize

=item 		LMSetScrapHandle

=item 		LMSetScrapCount

=item 		LMSetScrapState

=item 		LMSetROMFont0

=item 		LMSetApFontID

=item 		LMSetSaveUpdate

=item 		LMSetPaintWhite

=item 		LMSetWMgrPort

=item 		LMSetWindowList

=item 		LMSetGhostWindow

=item 		LMSetAuxWinHead

=item 		LMSetCurActivate

=item 		LMSetCurDeactive

=item 		LMSetOldStructure

=item 		LMSetOldContent

=item 		LMSetGrayRgn

=item 		LMSetSaveVisRgn

=item 		LMSetOneOne

=item 		LMSetMinusOne

=item 		LMSetTopMenuItem

=item 		LMSetAtMenuBottom

=item 		LMSetMenuList

=item 		LMSetMBarEnable

=item 		LMSetMenuFlash

=item 		LMSetTheMenu

=item 		LMSetTopMapHndl

=item 		LMSetSysMapHndl

=item 		LMSetSysMap

=item 		LMSetCurMap

=item 		LMSetResLoad

=item 		LMSetResErr

=item 		LMSetFScaleDisable

=item 		LMSetANumber

=item 		LMSetACount

=item 		LMSetTEScrpLength

=item 		LMSetTEScrpHandle

=item 		LMSetAppParmHandle

=item 		LMSetDSErrCode

=item 		LMSetDlgFont

=item 		LMSetWidthPtr

=item 		LMSetATalkHk2

=item 		LMSetHWCfgFlags

=item 		LMSetWidthTabHandle

=item 		LMSetLastSPExtra

=item 		LMSetMenuDisable

=item 		LMSetROMMapInsert

=item 		LMSetTmpResLoad

=item 		LMSetIntlSpec

=item 		LMSetWordRedraw

=item 		LMSetSysFontFam

=item 		LMSetSysFontSize

=item 		LMSetMBarHeight

=item 		LMSetTESysJust

=item 		LMSetLastFOND

=item 		LMSetFractEnable

=item 		LMSetMMU32Bit

=item 		LMSetTheGDevice

=item 		LMSetDeskCPat

=item 		LMSetTimeDBRA

=item 		LMSetTimeSCCDB

=item 		LMSetSynListHandle

=item 		LMSetMenuCInfo

=item 		LMSetTimeSCSIDB

=item 		LMSetCursorNew

=item 		LMSetMouseButtonState

=item 		LMSetMouseTemp

=item 		LMSetRawMouseLocation

=item 		LMSetMouseLocation

=item 		LMSetHighHeapMark

=item 		LMSetStackLowPoint

=item 		LMSetROMMapHandle

=item 		LMSetUnitTableEntryCount

=item 		LMSetDiskFormatingHFSDefaults

=item 		LMSetPortAInfo

=back

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

