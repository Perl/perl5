package Mac::Apps::Launch;
require 5.004;
use Exporter;
use strict;
use vars qw($VERSION @ISA @EXPORT);
use Mac::Processes;
use Mac::MoreFiles;
use Mac::AppleEvents;
#-----------------------------------------------------------------
$VERSION = '1.70';
@ISA     = 'Exporter';
@EXPORT  = qw(
    LaunchSpecs LaunchApps QuitApps QuitAllApps IsRunning
    Show Hide SetFront
);
#-----------------------------------------------------------------
sub _showhide {
    my($tf, $app, $bool) = @_;
    my $err = 0;
    if (!$bool) {
        foreach my $psn (keys %Process) {
            if ($Process{$psn}->processSignature eq $app) {
                $app = $Process{$psn}->processName;
                last;
            }
        }
    }

    my $e = AEBuildAppleEvent(qw/core setd sign MACS/, 0, 0,
        q"'----': obj {form:prop, want:type(prop), seld:type(pvis), from:" .
        q"obj {form:name, want:type(pcap), seld:TEXT(@), from:'null'()}}," .
        "data:'$tf'", $app);
    $err ||= $^E unless $e;

    my $r = AESend($e, kAEWaitReply);
    $err ||= $^E unless $r;

    if ($r && (my $error = AEGetParamDesc($r, 'errn'))) {
        $err ||= $error->get;
        AEDisposeDesc $error;
    }
    AEDisposeDesc $e if $e;
    AEDisposeDesc $r if $r;
    $^E = $err;
    return !$err;
}
#-----------------------------------------------------------------
sub Show { _showhide('true', @_) }
sub Hide { _showhide('fals', @_) }
#-----------------------------------------------------------------
sub SetFront {
    my $app = shift;
    foreach my $psn (keys %Process) {
        if ($Process{$psn}->processSignature eq $app) {
            SetFrontProcess($psn);
            return 1;
        }
    }
    return;
}
#-----------------------------------------------------------------
sub QuitAllApps {
    my $keepapps = 'McPL';
    my $APPL = unpack 'L*', 'APPL';
    foreach (@_) { $keepapps .= "|\Q$_\E" }
    my @apps;
    foreach my $psn (keys %Process) {
        my $proc = $Process{$psn};
        my $sig = $proc->processSignature;
        next if $sig =~ /$keepapps/; # apps to keep running
        push @apps, $sig if $proc->processType == $APPL;
    }

    QuitApps(@apps);
}
#-----------------------------------------------------------------
sub QuitApps {
    my @apps = @_;
    my $err = 0;
    foreach (@apps) {
        my $e = AEBuildAppleEvent(
            'aevt', 'quit', typeApplSignature, $_,
            kAutoGenerateReturnID, kAnyTransactionID, '');
        $err ||= $^E unless $e;

        my $r = AESend($e, kAEWaitReply);
        $err ||= $^E unless $r;

        AEDisposeDesc $e if $e;
        AEDisposeDesc $r if $r;
    }
    $^E = $err;
    return !$err;
}
#-----------------------------------------------------------------
sub LaunchApps {
    my $err = 0;
    my @apps = ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0];
    my($switch, $specs, %open);

    $specs = 1 if (caller(1))[3]
        && (caller(1))[3] eq __PACKAGE__ . "::LaunchSpecs";

    if ($_[1] && $_[1] == 1) {
        $switch = launchContinue | launchNoFileFlags;
    } else {
        $switch = launchContinue | launchNoFileFlags | launchDontSwitch;
    }

    while(my($n, $i) = each(%Process)) {
        $open{$i->processSignature} = $i->processAppSpec;
    }

    foreach (@apps) {
        if ($specs) {
            _launch($_, $switch) or $err ||= $^E;
        } elsif ($Application{$_}) {
            my $app_spec = exists $open{$_} ? $open{$_} : $Application{$_};
            _launch($app_spec, $switch) or $err ||= $^E;
        } else {
            $err ||= -5012;  # "missing comment/APPL entry"
        }
    }
    $^E = $err;
    return !$err;
}
#-----------------------------------------------------------------
sub LaunchSpecs { LaunchApps(@_) }
#-----------------------------------------------------------------
sub _launch {
    my($app_spec, $switch) = @_;
    return unless -e $app_spec;
    my $Launch = new LaunchParam(
        launchControlFlags => $switch,
        launchAppSpec      => $app_spec,
    );
    LaunchApplication($Launch);
}
#-----------------------------------------------------------------
sub IsRunning {
    my %x;
    while (my($k, $v) = each %Process) {
        goto &IsRunning if !ref $v;  # hopefully we don't go into a neverending loop here
        $x{$v->processSignature} = 1;
    }
    return exists $x{$_[0]};
}
#-----------------------------------------------------------------

1;
__END__

=head1 NAME

Mac::Apps::Launch - MacPerl module to launch applications

=head1 SYNOPSIS

    use Mac::Apps::Launch;
    my @apps = qw(R*ch Arch MPGP);
    my $path = "HD:System Folder:Finder";
    LaunchApps([@apps], 1) or warn $^E; # launch and switch to front
    LaunchApps([@apps])    or warn $^E; # launch and don't switch 
    LaunchApps($app, 1)    or warn $^E; # launch and switch to front
    LaunchSpecs($path, 1)  or warn $^E; # use path instead of app ID
    QuitApps(@apps)        or warn $^E; # quit all @apps
    QuitAllApps(@apps)     or warn $^E; # quit all except @apps
    IsRunning('MACS');                  # returns boolean for whether
                                        # given app ID is running
    SetFront('MACS')       or warn $^E; # set Finder to front
    Hide('MACS')           or warn $^E; # hide Finder
    Show('Finder', 1)      or warn $^E; # show Finder (1 == use name)

=head1 DESCRIPTION

Simply launch or quit applications by their creator ID.  The Finder can
be quit in this way, though it cannot be launched in this way.

This module is used by many other modules.

This module as written does not work with MacPerls prior to 5.1.4r4.

=head1 EXPORT

Exports functions C<QuitApps>, C<QuitAllApps>, and C<LaunchApps>,
C<IsRunning>, C<LaunchSpecs>, C<SetFront>, C<Hide>, C<Show>.

=head1 HISTORY

=over 4

=item v.1.70, June 4, 1999

Cleaned up stuff.  Added C<SetFront>, C<Show>, C<Hide>.  Fixed setting of
C<$^E>.  Improved QuitAllApps to not quit only normal apps by checking
C<processType> for "APPL".

=item v.1.60, September 28, 1998

Added C<LaunchSpecs>.  Use this when the app does not have a unique app ID,
the app is not really an app (like the Finder), or you have more than one
instance of the app, and want to launch a particular one.

=item v.1.50, September 16, 1998

Added C<IsRunning>.

=item v.1.40, August 3, 1998

Only launches application if not already open; e.g., won't launch newer version
it finds if older version is open.

=item v.1.31, May 18, 1998

Added C<AEDisposeDesc> call (D'oh!).  Dunno why I forgot this.

=item v.1.3, January 3, 1998

General cleanup, rewrite of method implementation, no longer support versions prior to 5.1.4r4, addition of Quit methods, methods return undef on failure (most recent error in C<$^E>, but could be multiple errors; oh well).

=back

=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1999 Chris Nandor.  All rights reserved.  This program is free 
software; you can redistribute it and/or modify it under the terms of the 
Artistic License, distributed with Perl.

=head1 VERSION

Version 1.70 (June 4, 1999)

=cut
