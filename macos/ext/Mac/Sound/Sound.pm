=head1 NAME

Mac::Sound - Macintosh Toolbox Interface to Sound Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Sound;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	use Mac::Memory();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		twelfthRootTwo
		soundListRsrc
		rate48khz
		rate44khz
		rate22050hz
		rate22khz
		rate11khz
		rate11025hz
		squareWaveSynth
		waveTableSynth
		sampledSynth
		MACE3snthID
		MACE6snthID
		kMiddleC
		kSimpleBeepID
		kFullVolume
		kNoVolume
		stdQLength
		dataOffsetFlag
		kUseOptionalOutputDevice
		notCompressed
		fixedCompression
		variableCompression
		twoToOne
		eightToThree
		threeToOne
		sixToOne
		sixToOnePacketSize
		threeToOnePacketSize
		stateBlockSize
		leftOverBlockSize
		firstSoundFormat
		secondSoundFormat
		dbBufferReady
		dbLastBuffer
		sysBeepDisable
		sysBeepEnable
		sysBeepSynchronous
		unitTypeNoSelection
		unitTypeSeconds
		stdSH
		extSH
		cmpSH
		nullCmd
		initCmd
		freeCmd
		quietCmd
		flushCmd
		reInitCmd
		waitCmd
		pauseCmd
		resumeCmd
		callBackCmd
		syncCmd
		availableCmd
		versionCmd
		totalLoadCmd
		loadCmd
		freqDurationCmd
		restCmd
		freqCmd
		ampCmd
		timbreCmd
		getAmpCmd
		volumeCmd
		getVolumeCmd
		clockComponentCmd
		getClockComponentCmd
		waveTableCmd
		phaseCmd
		soundCmd
		bufferCmd
		rateCmd
		continueCmd
		doubleBufferCmd
		getRateCmd
		rateMultiplierCmd
		getRateMultiplierCmd
		sizeCmd
		convertCmd
		waveInitChannelMask
		waveInitChannel0
		waveInitChannel1
		waveInitChannel2
		waveInitChannel3
		initChan0
		initChan1
		initChan2
		initChan3
		outsideCmpSH
		insideCmpSH
		aceSuccess
		aceMemFull
		aceNilBlock
		aceBadComp
		aceBadEncode
		aceBadDest
		aceBadCmd
		initChanLeft
		initChanRight
		initNoInterp
		initNoDrop
		initMono
		initStereo
		initMACE3
		initMACE6
		initPanMask
		initSRateMask
		initStereoMask
		initCompMask
		siActiveChannels
		siActiveLevels
		siAGCOnOff
		siAsync
		siAVDisplayBehavior
		siChannelAvailable
		siCompressionAvailable
		siCompressionFactor
		siCompressionHeader
		siCompressionNames
		siCompressionParams
		siCompressionType
		siContinuous
		siDeviceBufferInfo
		siDeviceConnected
		siDeviceIcon
		siDeviceName
		siHardwareBalance
		siHardwareBalanceSteps
		siHardwareBass
		siHardwareBassSteps
		siHardwareBusy
		siHardwareFormat
		siHardwareMute
		siHardwareTreble
		siHardwareTrebleSteps
		siHardwareVolume
		siHardwareVolumeSteps
		siHeadphoneMute
		siHeadphoneVolume
		siHeadphoneVolumeSteps
		siInputAvailable
		siInputGain
		siInputSource
		siInputSourceNames
		siLevelMeterOnOff
		siModemGain
		siMonitorAvailable
		siMonitorSource
		siNumberChannels
		siOptionsDialog
		siPlayThruOnOff
		siPostMixerSoundComponent
		siPreMixerSoundComponent
		siQuality
		siRateMultiplier
		siRecordingQuality
		siSampleRate
		siSampleRateAvailable
		siSampleSize
		siSampleSizeAvailable
		siSetupCDAudio
		siSetupModemAudio
		siSlopeAndIntercept
		siSoundClock
		siSpeakerMute
		siSpeakerVolume
		siSSpCPULoadLimit
		siSSpLocalization
		siSSpSpeakerSetup
		siStereoInputGain
		siSubwooferMute
		siTwosComplementOnOff
		siVolume
		siVoxRecordInfo
		siVoxStopInfo
		siWideStereo
		siCloseDriver
		siInitializeDriver
		siPauseRecording
		siUserInterruptProc
		kNoSoundComponentType
		kSoundComponentType
		kSoundComponentPPCType
		kRate8SubType
		kRate16SubType
		kConverterSubType
		kSndSourceSubType
		kMixerType
		kMixer8SubType
		kMixer16SubType
		kSoundOutputDeviceType
		kClassicSubType
		kASCSubType
		kDSPSubType
		kAwacsSubType
		kGCAwacsSubType
		kSingerSubType
		kSinger2SubType
		kWhitSubType
		kSoundBlasterSubType
		kSoundCompressor
		kSoundDecompressor
		kSoundEffectsType
		kSSpLocalizationSubType
		kSoundNotCompressed
		kOffsetBinary
		kMACE3Compression
		kMACE6Compression
		kCDXA4Compression
		kCDXA2Compression
		kIMACompression
		kULawCompression
		kALawCompression
		kLittleEndianFormat
		kFloat32Format
		kFloat64Format
		kTwosComplement
		k8BitRawIn
		k8BitTwosIn
		k16BitIn
		kStereoIn
		k8BitRawOut
		k8BitTwosOut
		k16BitOut
		kStereoOut
		kReverse
		kRateConvert
		kCreateSoundSource
		kHighQuality
		kNonRealTime
		kSourcePaused
		kPassThrough
		kNoSoundComponentChain
		kNoMixing
		kNoSampleRateConversion
		kNoSampleSizeConversion
		kNoSampleFormatConversion
		kNoChannelConversion
		kNoDecompression
		kNoVolumeConversion
		kNoRealtimeProcessing
		kScheduledSource
		kBestQuality
		kInputMask
		kOutputMask
		kOutputShift
		kActionMask
		kSoundComponentBits
		kAVDisplayHeadphoneRemove
		kAVDisplayHeadphoneInsert
		kAVDisplayPlainTalkRemove
		kAVDisplayPlainTalkInsert
		audioAllChannels
		audioLeftChannel
		audioRightChannel
		audioUnmuted
		audioMuted
		audioDoesMono
		audioDoesStereo
		audioDoesIndependentChannels
		siCDQuality
		siBestQuality
		siBetterQuality
		siGoodQuality
		siDeviceIsConnected
		siDeviceNotConnected
		siDontKnowIfConnected
		siReadPermission
		siWritePermission

		SysBeep
		SndDoCommand
		SndDoImmediate
		SndNewChannel
		SndDisposeChannel
		SndPlay
		SndControl
		SndSoundManagerVersion
		SndStartFilePlay
		SndPauseFilePlay
		SndStopFilePlay
		SndChannelStatus
		SndManagerStatus
		SndGetSysBeepState
		SndSetSysBeepState
		MACEVersion
		Comp3to1
		Exp1to3
		Comp6to1
		Exp1to6
		GetSysBeepVolume
		SetSysBeepVolume
		GetDefaultOutputVolume
		SetDefaultOutputVolume
		GetSoundHeaderOffset
		UnsignedFixedMulDiv
		GetCompressionInfo
		SetSoundPreference
		GetSoundPreference
		GetCompressionName
		SPBVersion
		SndRecord
		SndRecordToFile
		SPBSignInDevice
		SPBSignOutDevice
		SPBGetIndexedDevice
		SPBOpenDevice
		SPBCloseDevice
		SPBRecord
		SPBRecordToFile
		SPBPauseRecording
		SPBResumeRecording
		SPBStopRecording
		SPBGetRecordingStatus
	);
}

bootstrap Mac::Sound;

=head2 Constants

=over 4

=cut

sub twelfthRootTwo ()              { 1.05946309435; }
sub soundListRsrc ()               {     'snd '; }
sub rate48khz ()                   { 48000.00000; }
sub rate44khz ()                   { 44100.00000; }
sub rate22050hz ()                 { 22050.00000; }
sub rate22khz ()                   { 22254.54545 ; }
sub rate11khz ()                   { 11127.27273; }
sub rate11025hz ()                 { 11025.00000; }
sub squareWaveSynth ()             {          1; }
sub waveTableSynth ()              {          3; }
sub sampledSynth ()                {          5; }
sub MACE3snthID ()                 {         11; }
sub MACE6snthID ()                 {         13; }
sub kMiddleC ()                    {         60; }
sub kSimpleBeepID ()               {          1; }
sub kFullVolume ()                 {     0x0100; }
sub kNoVolume ()                   {          0; }
sub stdQLength ()                  {        128; }
sub dataOffsetFlag ()              {     0x8000; }
sub kUseOptionalOutputDevice ()    {         -1; }
sub notCompressed ()               {          0; }
sub fixedCompression ()            {         -1; }
sub variableCompression ()         {         -2; }
sub twoToOne ()                    {          1; }
sub eightToThree ()                {          2; }
sub threeToOne ()                  {          3; }
sub sixToOne ()                    {          4; }
sub sixToOnePacketSize ()          {          8; }
sub threeToOnePacketSize ()        {         16; }
sub stateBlockSize ()              {         64; }
sub leftOverBlockSize ()           {         32; }
sub firstSoundFormat ()            {     0x0001; }
sub secondSoundFormat ()           {     0x0002; }
sub dbBufferReady ()               { 0x00000001; }
sub dbLastBuffer ()                { 0x00000004; }
sub sysBeepDisable ()              {     0x0000; }
sub sysBeepEnable ()               {   (1 << 0); }
sub sysBeepSynchronous ()          {   (1 << 1); }
sub unitTypeNoSelection ()         {     0xFFFF; }
sub unitTypeSeconds ()             {     0x0000; }
sub stdSH ()                       {       0x00; }
sub extSH ()                       {       0xFF; }
sub cmpSH ()                       {       0xFE; }
sub nullCmd ()                     {          0; }
sub initCmd ()                     {          1; }
sub freeCmd ()                     {          2; }
sub quietCmd ()                    {          3; }
sub flushCmd ()                    {          4; }
sub reInitCmd ()                   {          5; }
sub waitCmd ()                     {         10; }
sub pauseCmd ()                    {         11; }
sub resumeCmd ()                   {         12; }
sub callBackCmd ()                 {         13; }
sub syncCmd ()                     {         14; }
sub availableCmd ()                {         24; }
sub versionCmd ()                  {         25; }
sub totalLoadCmd ()                {         26; }
sub loadCmd ()                     {         27; }
sub freqDurationCmd ()             {         40; }
sub restCmd ()                     {         41; }
sub freqCmd ()                     {         42; }
sub ampCmd ()                      {         43; }
sub timbreCmd ()                   {         44; }
sub getAmpCmd ()                   {         45; }
sub volumeCmd ()                   {         46; }
sub getVolumeCmd ()                {         47; }
sub clockComponentCmd ()           {         50; }
sub getClockComponentCmd ()        {         51; }
sub waveTableCmd ()                {         60; }
sub phaseCmd ()                    {         61; }
sub soundCmd ()                    {         80; }
sub bufferCmd ()                   {         81; }
sub rateCmd ()                     {         82; }
sub continueCmd ()                 {         83; }
sub doubleBufferCmd ()             {         84; }
sub getRateCmd ()                  {         85; }
sub rateMultiplierCmd ()           {         86; }
sub getRateMultiplierCmd ()        {         87; }
sub sizeCmd ()                     {         90; }
sub convertCmd ()                  {         91; }
sub waveInitChannelMask ()         {       0x07; }
sub waveInitChannel0 ()            {       0x04; }
sub waveInitChannel1 ()            {       0x05; }
sub waveInitChannel2 ()            {       0x06; }
sub waveInitChannel3 ()            {       0x07; }
sub initChan0 ()                   { waveInitChannel0; }
sub initChan1 ()                   { waveInitChannel1; }
sub initChan2 ()                   { waveInitChannel2; }
sub initChan3 ()                   { waveInitChannel3; }
sub outsideCmpSH ()                {          0; }
sub insideCmpSH ()                 {          1; }
sub aceSuccess ()                  {          0; }
sub aceMemFull ()                  {          1; }
sub aceNilBlock ()                 {          2; }
sub aceBadComp ()                  {          3; }
sub aceBadEncode ()                {          4; }
sub aceBadDest ()                  {          5; }
sub aceBadCmd ()                   {          6; }
sub initChanLeft ()                {     0x0002; }
sub initChanRight ()               {     0x0003; }
sub initNoInterp ()                {     0x0004; }
sub initNoDrop ()                  {     0x0008; }
sub initMono ()                    {     0x0080; }
sub initStereo ()                  {     0x00C0; }
sub initMACE3 ()                   {     0x0300; }
sub initMACE6 ()                   {     0x0400; }
sub initPanMask ()                 {     0x0003; }
sub initSRateMask ()               {     0x0030; }
sub initStereoMask ()              {     0x00C0; }
sub initCompMask ()                {     0xFF00; }
sub siActiveChannels ()            {     'chac'; }
sub siActiveLevels ()              {     'lmac'; }
sub siAGCOnOff ()                  {     'agc '; }
sub siAsync ()                     {     'asyn'; }
sub siAVDisplayBehavior ()         {     'avdb'; }
sub siChannelAvailable ()          {     'chav'; }
sub siCompressionAvailable ()      {     'cmav'; }
sub siCompressionFactor ()         {     'cmfa'; }
sub siCompressionHeader ()         {     'cmhd'; }
sub siCompressionNames ()          {     'cnam'; }
sub siCompressionParams ()         {     'cmpp'; }
sub siCompressionType ()           {     'comp'; }
sub siContinuous ()                {     'cont'; }
sub siDeviceBufferInfo ()          {     'dbin'; }
sub siDeviceConnected ()           {     'dcon'; }
sub siDeviceIcon ()                {     'icon'; }
sub siDeviceName ()                {     'name'; }
sub siHardwareBalance ()           {     'hbal'; }
sub siHardwareBalanceSteps ()      {     'hbls'; }
sub siHardwareBass ()              {     'hbas'; }
sub siHardwareBassSteps ()         {     'hbst'; }
sub siHardwareBusy ()              {     'hwbs'; }
sub siHardwareFormat ()            {     'hwfm'; }
sub siHardwareMute ()              {     'hmut'; }
sub siHardwareTreble ()            {     'htrb'; }
sub siHardwareTrebleSteps ()       {     'hwts'; }
sub siHardwareVolume ()            {     'hvol'; }
sub siHardwareVolumeSteps ()       {     'hstp'; }
sub siHeadphoneMute ()             {     'pmut'; }
sub siHeadphoneVolume ()           {     'pvol'; }
sub siHeadphoneVolumeSteps ()      {     'hdst'; }
sub siInputAvailable ()            {     'inav'; }
sub siInputGain ()                 {     'gain'; }
sub siInputSource ()               {     'sour'; }
sub siInputSourceNames ()          {     'snam'; }
sub siLevelMeterOnOff ()           {     'lmet'; }
sub siModemGain ()                 {     'mgai'; }
sub siMonitorAvailable ()          {     'mnav'; }
sub siMonitorSource ()             {     'mons'; }
sub siNumberChannels ()            {     'chan'; }
sub siOptionsDialog ()             {     'optd'; }
sub siPlayThruOnOff ()             {     'plth'; }
sub siPostMixerSoundComponent ()   {     'psmx'; }
sub siPreMixerSoundComponent ()    {     'prmx'; }
sub siQuality ()                   {     'qual'; }
sub siRateMultiplier ()            {     'rmul'; }
sub siRecordingQuality ()          {     'qual'; }
sub siSampleRate ()                {     'srat'; }
sub siSampleRateAvailable ()       {     'srav'; }
sub siSampleSize ()                {     'ssiz'; }
sub siSampleSizeAvailable ()       {     'ssav'; }
sub siSetupCDAudio ()              {     'sucd'; }
sub siSetupModemAudio ()           {     'sumd'; }
sub siSlopeAndIntercept ()         {     'flap'; }
sub siSoundClock ()                {     'sclk'; }
sub siSpeakerMute ()               {     'smut'; }
sub siSpeakerVolume ()             {     'svol'; }
sub siSSpCPULoadLimit ()           {     '3dll'; }
sub siSSpLocalization ()           {     '3dif'; }
sub siSSpSpeakerSetup ()           {     '3dst'; }
sub siStereoInputGain ()           {     'sgai'; }
sub siSubwooferMute ()             {     'bmut'; }
sub siTwosComplementOnOff ()       {     'twos'; }
sub siVolume ()                    {     'volu'; }
sub siVoxRecordInfo ()             {     'voxr'; }
sub siVoxStopInfo ()               {     'voxs'; }
sub siWideStereo ()                {     'wide'; }
sub siCloseDriver ()               {     'clos'; }
sub siInitializeDriver ()          {     'init'; }
sub siPauseRecording ()            {     'paus'; }
sub siUserInterruptProc ()         {     'user'; }
sub kNoSoundComponentType ()       {     '****'; }
sub kSoundComponentType ()         {     'sift'; }
sub kSoundComponentPPCType ()      {     'nift'; }
sub kRate8SubType ()               {     'ratb'; }
sub kRate16SubType ()              {     'ratw'; }
sub kConverterSubType ()           {     'conv'; }
sub kSndSourceSubType ()           {     'sour'; }
sub kMixerType ()                  {     'mixr'; }
sub kMixer8SubType ()              {     'mixb'; }
sub kMixer16SubType ()             {     'mixw'; }
sub kSoundOutputDeviceType ()      {     'sdev'; }
sub kClassicSubType ()             {     'clas'; }
sub kASCSubType ()                 {     'asc '; }
sub kDSPSubType ()                 {     'dsp '; }
sub kAwacsSubType ()               {     'awac'; }
sub kGCAwacsSubType ()             {     'awgc'; }
sub kSingerSubType ()              {     'sing'; }
sub kSinger2SubType ()             {     'sng2'; }
sub kWhitSubType ()                {     'whit'; }
sub kSoundBlasterSubType ()        {     'sbls'; }
sub kSoundCompressor ()            {     'scom'; }
sub kSoundDecompressor ()          {     'sdec'; }
sub kSoundEffectsType ()           {     'snfx'; }
sub kSSpLocalizationSubType ()     {     'snd3'; }
sub kSoundNotCompressed ()         {     'NONE'; }
sub kOffsetBinary ()               {     'raw '; }
sub kMACE3Compression ()           {     'MAC3'; }
sub kMACE6Compression ()           {     'MAC6'; }
sub kCDXA4Compression ()           {     'cdx4'; }
sub kCDXA2Compression ()           {     'cdx2'; }
sub kIMACompression ()             {     'ima4'; }
sub kULawCompression ()            {     'ulaw'; }
sub kALawCompression ()            {     'alaw'; }
sub kLittleEndianFormat ()         {     'sowt'; }
sub kFloat32Format ()              {     'fl32'; }
sub kFloat64Format ()              {     'fl64'; }
sub kTwosComplement ()             {     'twos'; }
sub k8BitRawIn ()                  {   (1 << 0); }
sub k8BitTwosIn ()                 {   (1 << 1); }
sub k16BitIn ()                    {   (1 << 2); }
sub kStereoIn ()                   {   (1 << 3); }
sub k8BitRawOut ()                 {   (1 << 8); }
sub k8BitTwosOut ()                {   (1 << 9); }
sub k16BitOut ()                   {  (1 << 10); }
sub kStereoOut ()                  {  (1 << 11); }
sub kReverse ()                    { (1 << 16); }
sub kRateConvert ()                { (1 << 17); }
sub kCreateSoundSource ()          { (1 << 18); }
sub kHighQuality ()                { (1 << 22); }
sub kNonRealTime ()                { (1 << 23); }
sub kSourcePaused ()               {   (1 << 0); }
sub kPassThrough ()                { (1 << 16); }
sub kNoSoundComponentChain ()      { (1 << 17); }
sub kNoMixing ()                   {   (1 << 0); }
sub kNoSampleRateConversion ()     {   (1 << 1); }
sub kNoSampleSizeConversion ()     {   (1 << 2); }
sub kNoSampleFormatConversion ()   {   (1 << 3); }
sub kNoChannelConversion ()        {   (1 << 4); }
sub kNoDecompression ()            {   (1 << 5); }
sub kNoVolumeConversion ()         {   (1 << 6); }
sub kNoRealtimeProcessing ()       {   (1 << 7); }
sub kScheduledSource ()            {   (1 << 8); }
sub kBestQuality ()                {   (1 << 0); }
sub kInputMask ()                  { 0x000000FF; }
sub kOutputMask ()                 { 0x0000FF00; }
sub kOutputShift ()                {          8; }
sub kActionMask ()                 { 0x00FF0000; }
sub kSoundComponentBits ()         { 0x00FFFFFF; }
sub kAVDisplayHeadphoneRemove ()   {          0; }
sub kAVDisplayHeadphoneInsert ()   {          1; }
sub kAVDisplayPlainTalkRemove ()   {          2; }
sub kAVDisplayPlainTalkInsert ()   {          3; }
sub audioAllChannels ()            {          0; }
sub audioLeftChannel ()            {          1; }
sub audioRightChannel ()           {          2; }
sub audioUnmuted ()                {          0; }
sub audioMuted ()                  {          1; }
sub audioDoesMono ()               {  (1 << 0); }
sub audioDoesStereo ()             {  (1 << 1); }
sub audioDoesIndependentChannels () {  (1 << 2); }
sub siCDQuality ()                 {     'cd  '; }
sub siBestQuality ()               {     'best'; }
sub siBetterQuality ()             {     'betr'; }
sub siGoodQuality ()               {     'good'; }
sub siDeviceIsConnected ()         {          1; }
sub siDeviceNotConnected ()        {          0; }
sub siDontKnowIfConnected ()       {         -1; }
sub siReadPermission ()            {          0; }
sub siWritePermission ()           {          1; }

=back

=cut

sub GetSoundPreference {
	my($theType, $name, $settings) = @_;
	$settings ||= Mac::Memory::NewHandle();
	_GetSoundPreference($theType, $name, $settings) && $settings;
}

sub SndPlay {
	my($chan, $snd, $async) = @_;
	if (!$chan) {
		my($ch) = 0;
		$chan = bless \$ch, "SndChannel";
	}
	$async ||= 0;
	_SndPlay($chan, $snd, $async);
}

=include Sound.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
