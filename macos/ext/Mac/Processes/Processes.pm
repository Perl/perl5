
=head1 NAME

Mac::Processes - Macintosh Toolbox Interface to Process Manager

=head1 SYNOPSIS

	use Mac::Processes;
	
    while ( ($psn, $psi) = each(%Process) ) {
        print "$psn\t", $psi->processName, 
        " ", $psi->processNumber,
        " ", $psi->processType,
        " ", $psi->processSignature,
        " ", $psi->processSize,
        " ", $psi->processMode,
        " ", $psi->processLocation,
        " ", $psi->processLauncher,
        " ", $psi->processLaunchDate,
        " ", $psi->processActiveTime,
        " ", $psi->processAppSpec, "\n";
    }

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Processes::_ProcessInfoMap;
	
package Mac::Processes;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw(@ISA @EXPORT %Process $VERSION);
	
	$VERSION = '1.01';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		LaunchApplication
		LaunchDeskAccessory
		GetCurrentProcess
		GetFrontProcess
		GetNextProcess
		GetProcessInformation
		SetFrontProcess
		WakeUpProcess
		SameProcess
		ExitToShell
		
		%Process
		
		kNoProcess
		kSystemProcess
		kCurrentProcess
		launchContinue
		launchNoFileFlags
		launchUseMinimum
		launchDontSwitch
		launchAllow24Bit
		launchInhibitDaemon
		modeDeskAccessory
		modeMultiLaunch
		modeNeedSuspendResume
		modeCanBackground
		modeDoesActivateOnFGSwitch
		modeOnlyBackground
		modeGetFrontClicks
		modeGetAppDiedMsg
		mode32BitCompatible
		modeHighLevelEventAware
		modeLocalAndRemoteHLEvents
		modeStationeryAware
		modeUseTextEditServices
		modeDisplayManagerAware
	);
}

bootstrap Mac::Processes;

tie %Process, q(Mac::Processes::_ProcessInfoMap);

=head2 Constants

=over 4

=item kNoProcess

=item kSystemProcess

=item kCurrentProcess

Special process IDs.

=cut
sub kNoProcess ()                    {          0; }
sub kSystemProcess ()                {          1; }
sub kCurrentProcess ()               {          2; }


=item launchContinue

=item launchNoFileFlags

=item launchUseMinimum

=item launchDontSwitch

=item launchAllow24Bit

=item launchInhibitDaemon

Launch flags.

=cut
sub launchContinue ()                {     0x4000; }
sub launchNoFileFlags ()             {     0x0800; }
sub launchUseMinimum ()              {     0x0400; }
sub launchDontSwitch ()              {     0x0200; }
sub launchAllow24Bit ()              {     0x0100; }
sub launchInhibitDaemon ()           {     0x0080; }


=item modeDeskAccessory

=item modeMultiLaunch

=item modeNeedSuspendResume

=item modeCanBackground

=item modeDoesActivateOnFGSwitch

=item modeOnlyBackground

=item modeGetFrontClicks

=item modeGetAppDiedMsg

=item mode32BitCompatible

=item modeHighLevelEventAware

=item modeLocalAndRemoteHLEvents

=item modeStationeryAware

=item modeUseTextEditServices

=item modeDisplayManagerAware

Mode flags in SIZE resource.

=cut
sub modeDeskAccessory ()             { 0x00020000; }
sub modeMultiLaunch ()               { 0x00010000; }
sub modeNeedSuspendResume ()         { 0x00004000; }
sub modeCanBackground ()             { 0x00001000; }
sub modeDoesActivateOnFGSwitch ()    { 0x00000800; }
sub modeOnlyBackground ()            { 0x00000400; }
sub modeGetFrontClicks ()            { 0x00000200; }
sub modeGetAppDiedMsg ()             { 0x00000100; }
sub mode32BitCompatible ()           { 0x00000080; }
sub modeHighLevelEventAware ()       { 0x00000040; }
sub modeLocalAndRemoteHLEvents ()    { 0x00000020; }
sub modeStationeryAware ()           { 0x00000010; }
sub modeUseTextEditServices ()       { 0x00000008; }
sub modeDisplayManagerAware ()       { 0x00000004; }

=back

=cut

package Mac::Processes::_ProcessInfoMap;

use Carp;

sub TIEHASH {
	my($pack) = @_;
	
	bless \{}, $pack;
}

sub FETCH {
	my($self,$psn) = @_;
	
	Mac::Processes::GetProcessInformation($psn);
}

sub FIRSTKEY {
	Mac::Processes::GetNextProcess(0);
}

sub NEXTKEY {
	my($self,$psn) = @_;
	
	Mac::Processes::GetNextProcess($psn);
}

sub DESTROY {
}

sub STORE { croak "Can't change process info"; }
sub DELETE { croak "Can't DELETE processes yet"; }

package LaunchParam;

sub new {
	my $package = shift @_;
	my $my = _new();
	my ($arg,$value);
	
	while (($arg, $value) = splice(@_, 0, 2)) {
		$my->$arg($value);
	}
	$my;
}

=include Processes.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> Author

Bob Dalgleish <bob.dalgleish@sasknet.sk.ca> Documenter

=cut

__END__
