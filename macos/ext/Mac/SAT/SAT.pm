=head1 NAME

Mac::SAT - Macintosh Toolbox Interface to the Sprite Animation Toolkit

=head1 SYNOPSIS


=head1 DESCRIPTION

Please refer to the SAT documentation, available from
http://www.lysator.liu.se/~ingemar/sat.html, for instructions.
You may redistribute the MacPerl glue to SAT under the same conditions
as SAT itself. 

=cut

use strict;

package Mac::SAT;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		kVPositionSort
		kLayerSort
		kNoSort
		kKindCollision
		kForwardCollision
		kBackwardCollision
		kNoCollision
		kForwardOneCollision
		
		gSAT
		SATConfigure
		SATInit
		SATCustomInit
		SATDepthChangeTest
		SATDrawPICTs
		SATRedraw
		SATPlotFace
		SATPlotFaceToScreen
		SATCopyBits
		SATCopyBitsToScreen
		SATBackChanged
		SATGetPort
		SATSetPort
		SATSetPortOffScreen
		SATSetPortBackScreen
		SATSetPortScreen
		SATGetFace
		SATDisposeFace
		SATNewSprite
		SATNewSpriteAfter
		SATKillSprite
		SATRun
		SATRun2
		SATInstallSynch
		SATInstallEmergency
		SATSetSpriteRecSize
		SATSkip
		SATKill
		SATWindMoved
		SATSetPortMask
		SATSetPortFace
		SATSetPortFace2
		SATNewFace
		SATChangedFace
		SATSafeRectBlit
		SATSafeMaskBlit
		SATCopySprite
		SATCopyFace
		SATGetCicn
		SATPlotCicn
		SATDisposeCicn
		SATSetStrings
		SATTrapAvailable
		SATDrawInt
		SATDrawLong
		SATRand
		SATRand10
		SATRand100
		SATReportStr
		SATQuestionStr
		CheckNoMem
		SATFakeAlert
		SATSetMouse
		SATInitToolbox
		SATGetVersion
		SATPenPat
		SATBackPat
		SATGetPat
		SATDisposePat
		SATShowMBar
		SATHideMBar
		SATGetandDrawPICTRes
		SATGetandDrawPICTResInRect
		SATGetandCenterPICTResInRect
		SATSoundPlay
		SATSoundShutup
		SATSoundEvents
		SATSoundDone
		SATGetSound
		SATGetNamedSound
		SATDisposeSound
		SATSoundOn
		SATSoundOff
		SATSoundInitChannels
		SATSoundDoneChannel
		SATSoundPlayChannel
		SATSoundReserveChannel
		SATSoundShutupChannel
		SATPreloadChannels
		SATSoundPlay2
		SATSoundPlayEasy
		SATGetNumChannels
		SATGetChannel
		SATSetSoundInitParams
		SATSoundPlayVolume
		SATSoundFadeChannel
		SATSoundLoop
		SATStepScroll
	);
}

bootstrap Mac::SAT;

=head2 Constants

=over 4

=cut

sub kVPositionSort()		{ 0; }
sub kLayerSort()			{ 1; }
sub kNoSort()				{ 2; }
sub kKindCollision()		{ 0; }
sub kForwardCollision()		{ 1; }
sub kBackwardCollision()	{ 2; }
sub kNoCollision()			{ 3; }
sub kForwardOneCollision()	{ 4; }

=include SAT.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Sprite Animation Toolkit 	by Ingemar Ragnemalm <ingemar@lysator.liu.se>
MacPerl SAT glue 			by Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
