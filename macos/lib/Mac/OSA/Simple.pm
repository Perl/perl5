package Mac::OSA::Simple;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
    %ScriptComponents);
use Mac::Components;
use Mac::OSA;
use Mac::AppleEvents;
use Mac::Resources;
use Mac::Memory;
use Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(frontier applescript osa_script
    compile_applescript compile_frontier compile_osa_script
    load_osa_script %ScriptComponents);
@EXPORT_OK = @Mac::OSA::EXPORT;
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);
$VERSION = '0.51';

tie %ScriptComponents, 'Mac::OSA::Simple::Components';

sub frontier            { _doscript('LAND', $_[0])          }
sub applescript         { _doscript('ascr', $_[0])          }
sub osa_script          { _doscript(@_[0, 1])               }

sub compile_frontier    { _compile_script('LAND', $_[0])    }
sub compile_applescript { _compile_script('ascr', $_[0])    }
sub compile_osa_script  { _compile_script(@_[0, 1])         }

sub load_osa_script     { _load_script(@_[0, 1, 2])         }

sub execute {
    my($self, $value, $return) = ($_[0], '', '');

    $value = OSAExecute($self->{COMP}, $self->{ID}, 0, 0)
        or _mydie() && return;

    if ($value) {
        $return = OSADisplay($self->{COMP}, $value, 'TEXT', 0)
            or _mydie() && return;
        OSADispose($self->{COMP}, $value);
    }

    $self->{RETURN} = $return && $return->isa('AEDesc')
        ? $return->get : 1;

    AEDisposeDesc($return) if $return;

    $self->{RETURN};
}

sub dispose {
    my $self = shift;

    if ($self->{ID} && $self->{COMP}) {
        OSADispose($self->{COMP}, $self->{ID});
        delete $self->{ID};
    }

    if ($self->{SCRIPT}) {
        AEDisposeDesc($self->{SCRIPT});
        delete $self->{SCRIPT};
    }

    1;
}

sub save {
    my($self, $file, $resid, $name, $len, $scpt, $res, $foo) = @_;

    $scpt = $self->compiled or _mydie() && return;

    $resid = defined($resid) ? $resid : 128;
    $name  = defined($name)  ? $name  : 'MacPerl Script';

    unless (-e $file) {
        CreateResFile($file) or _mydie() && return;
        MacPerl::SetFileInfo('ToyS', 'osas', $file);
    }

    $res = FSpOpenResFile($file, 0) or _mydie() && return;
    $foo = Get1Resource(kOSAScriptResourceType, $resid);
    if (defined $foo) {
        RemoveResource($foo) or _mydie() && return;
    }

    AddResource($scpt, kOSAScriptResourceType, 128, $name)
        or _mydie() && return;

    UpdateResFile($res) or _mydie() && return;
    CloseResFile($res);

    1;
}

sub source {
    my($self, $source, $text) = @_;
    
    $source = OSAGetSource($self->{COMP}, $self->{ID}, typeChar)
        or _mydie() && return;

    $self->{SOURCE} = $source && $source->isa('AEDesc')
        ? $source->get : '';

    AEDisposeDesc($source);

    $self->{SOURCE};
}


sub compiled {
    my($self, $script) = @_;

    $script = OSAStore(@$self{qw(COMP ID)}, typeOSAGenericStorage, 0)
        or _mydie() && return;

    push @{$self->{AEDESC}}, $script;

    $script->data;
}

sub _doscript {
    my($c, $text, $self, $return) = @_;
    $self = _compile_script($c, $text) or _mydie() && return;
    $return = $self->execute or _mydie() && return;
    $self->dispose;
    $return;
}

sub _load_script {
    my($scpt, $from_file, $resid, $c, $desc, $self, $res) = @_;

    $c = kOSAGenericScriptingComponentSubtype;
    $self = bless {COMP => $ScriptComponents{$c},
        TYPE => $c}, __PACKAGE__;

    if ($from_file) {
        my($resc, $file);
        $resid = defined($resid) ? $resid : 128;
        $file = $scpt;
        $res = FSpOpenResFile($file, 0) or _mydie() && return;
        $scpt = Get1Resource(kOSAScriptResourceType, $resid)
            or _mydie() && return;
    }

    unless ($scpt->isa('Handle')) {
        die "data is not of type Handle";  # did you mean to
                                           # specify a file instead?
    }

    $desc = AECreateDesc(typeOSAGenericStorage, $scpt->get) or
        _mydie() && return;

    $self->{ID} = OSALoad($self->{COMP}, $desc, 0) or
        _mydie() && return;

    AEDisposeDesc($desc) if $desc;
    CloseResFile($res) if $res;

    $self;
}

sub _compile_script {
    my($c, $text, $comp, $script, $self) = @_;
    $self = bless {COMP => $ScriptComponents{$c},
        SOURCE => $text, TYPE => $c}, __PACKAGE__;
    $self->_compile;
}

sub _compile {
    my $self = shift;
    my($text, $comp, $script, $id);
    $self->{SCRIPT} = AECreateDesc('TEXT', $self->{SOURCE}) or
        _mydie() && return;
    $self->{ID} = OSACompile($self->{COMP}, $self->{SCRIPT}, 0) or
        _mydie() && return;
    $self;
}

sub _mydie {
    # maybe do something here some day
    1;
}

sub DESTROY {
    my $self = shift;
    if (exists($self->{ID}) || exists($self->{SCRIPT})) {
        $self->dispose;
    }
    if ($self->{AEDESC}) {
        for (@{$self->{AEDESC}}) {
            AEDisposeDesc($_);
        }
    }
}

END {
    foreach my $comp (keys %ScriptComponents) {
        CloseComponent($ScriptComponents{$comp});
    }
}

package Mac::OSA::Simple::Components;

BEGIN {
    use Carp;
    use Tie::Hash ();
    use Mac::Components;
    use Mac::OSA;
    use vars qw(@ISA);
    @ISA = qw(Tie::StdHash);
}

sub FETCH {
    my($self, $comp, $c) = @_;

    $c = $comp;
    if ($comp eq kOSAGenericScriptingComponentSubtype) {
        $c = 0;
        $c++ while exists $self->{$c};  # get unique key
    }

    if (!$self->{$c}) {
        $self->{$c} = 
            OpenDefaultComponent(kOSAComponentType(), $comp) or
            Mac::OSA::Simple::_mydie() && return;
    }
    $self->{$c};
}

package Mac::OSA::Simple;  # odd "fix" for AutoSplit

1;
__END__

=head1 NAME

Mac::OSA::Simple - Simple access to Mac::OSA

=head1 SYNOPSIS

    #!perl -wl
    use Mac::OSA::Simple;
    osa_script('LAND', <<'EOS');
      dialog.getInt ("Duration?",@examples.duration);
      dialog.getInt ("Amplitude?",@examples.amplitude);
      dialog.getInt ("Frequency?",@examples.frequency);
      speaker.sound (examples.duration, examples.amplitude,
          examples.frequency)
    EOS

    print frontier('clock.now()');

    applescript('beep 3');

=head1 DESCRIPTION

    **MAJOR CHANGE**
    Scripting component in osa_script and compile_osa_script
    is now the first parameter, not the second.
    Now the script text is second.

You can access scripting components via the tied hash
C<%ScriptComponents> which is automatically exported.  Components are
only opened if they have not been already, and are closed when the
program exits.  It is normally not necessary to use this hash, as it is
accessed internally when needed.

Also usually not necessary, but possibly useful, are all the functions
and constants from Mac::OSA, available with the EXPORT_TAG "all".


=head2 Functions

The following functions are automatically exported.

=over 4

=item osa_script(SCRIPTCOMPONENT, SCRIPTTEXT)

Compiles and executes SCRIPTTEXT, using four-char SCRIPTCOMPONENT.
Component is opened and closed behind the scenes, and SCRIPTTEXT
is compiled, executed, and disposed of behind the scenes.  If
the script returns data, the function returns the data, else it
returns 1 or undef on failure.

=item applescript(SCRIPTTEXT)

=item frontier(SCRIPTTEXT)

Same thing as C<osa_script> with SCRIPTCOMPONENT already set
('ascr' for AppleScript, 'LAND' for Frontier).


=item compile_osa_script(SCRIPTCOMPONENT, SCRIPTTEXT)

Compiles script as C<osa_script> above, but does not execute it.
Returns Mac::OSA::Simple object.  See L<"Methods"> for more information.

=item compile_applescript(SCRIPTTEXT)

=item compile_frontier(SCRIPTTEXT)

Same thing as C<compile_osa_script> with SCRIPTCOMPONENT already set.


=item load_osa_script(HANDLE)

=item load_osa_script(FILE, FROMFILE [, RESOURCEID])

In the first form, load compiled OSA script using data in HANDLE
(same data as returned by C<compiled> method; see L<Mac::Memory>).
In the second form, with FROMFILE true, gets
script from FILE using RESOURCEID (which is 128 by default).  Returns
Mac::OSA::Simple object.

    **NOTE**
    This function uses FSpOpenResFile, which has a bug in it
    that causes it to treat $ENV{MACPERL} as the current
    directory.  For safety, always pass FILE as an absolute
    path, for now.

Example:

    use Mac::OSA::Simple qw(:all);
    use Mac::Resources;
    $res = FSpOpenResFile($file, 0) or die $^E;
    $scpt = Get1Resource(kOSAScriptResourceType, 128)
        or die $^E;
    $osa = load_osa_script($scpt);
    $osa->execute;
    CloseResFile($res);

Same thing:

    use Mac::OSA::Simple;
    $osa = load_osa_script($file, 1);
    $osa->execute;

Another example:

    use Mac::OSA::Simple;
    $osa1 = compile_applescript('return "foo"');
    print $osa1->execute;

    # make copy of script in $osa1 and execute it
    $osa2 = load_osa_script($osa1->compiled);
    print $osa2->execute;

See L<"Methods"> for more information.

=back


=head2 Methods

This section describes methods for use on objects returned by
C<compile_osa_script> and its related functions and C<load_osa_script>.

=over 4

=item compiled

Returns a HANDLE containing the raw compiled form of the script
(see L<Mac::Memory>).

=item dispose

Disposes of OSA script.  Done automatically if not called explicitly.

=item execute

Executes script.  Can be executed more than once.

=item save(FILE [, ID [, NAME]])

Saves script in FILE with ID and NAME.  ID defaults to 128, NAME
defaults to "MacPerl Script".  DANGEROUS!  Will overwrite
existing resource!

    **NOTE**
    This function uses FSpOpenResFile, which has a bug in it
    that causes it to treat $ENV{MACPERL} as the current
    directory.  For safety, always pass FILE as an absolute
    path, for now.


=back


=head1 BUGS

C<load_osa_script> function and C<save> method require absolute
paths.  Problem in Mac::Resources itself.

=head1 TODO

Work on error handling.  We don't want to die when a toolbox function
fails.  We'd rather return undef and have the user check $^E.

Should C<frontier> and/or C<osa_script('LAND', $script)> launch
Frontier if it is not running?

Add C<run_osa_script>, which could take script data in a Handle or
a path to a script (as with C<load_osa_script>.

Should C<save> have optional parameter for overwriting resource?

Should C<run_osa_script> and C<execute> take arguments?  If so, how?


=head1 HISTORY

=over 4

Changed TEXT to SOURCE in internal hash storing text source of script.

Added C<source> method (finish adding docs).

Made calls for generic scripting component to C<%ScriptComponents>
make new call to OpenComponent each time.

=item v0.51, Saturday, March 20, 1999

Fixed silly bug in return from execute, where multiline
return values would not return (added /s so . would match \n)
(John Moreno E<lt>phenix@interpath.comE<gt>).

=item v0.50, Friday, March 12, 1999

Changed around the argument order for C<osa_script> and
C<compile_osa_script>.

Added C<load_osa_script> function.

Added C<save> method.

Added lots of tests.

=item v0.10, Tuesday, March 9, 1999

Added lots of stuff to get compiled script data.

=item v0.02, May 19, 1998

Here goes ...

=back

=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1999 Chris Nandor.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

=head1 SEE ALSO

Mac::OSA, Mac::AppleEvents, Mac::AppleEvents::Simple, macperlcat.

=head1 VERSION

Version 0.51 (Saturday, March 20, 1999)

=cut
