package OS2::localMorphPM;

sub new { my ($c,$f) = @_; OS2::MorphPM($f); bless [shift], $c }
sub DESTROY { OS2::UnMorphPM(shift->[0]) }

package OS2::Process;

BEGIN {
  require Exporter;
  require DynaLoader;
  #require AutoLoader;

  @ISA = qw(Exporter DynaLoader);
  $VERSION = "1.0";
  bootstrap OS2::Process;
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	P_BACKGROUND
	P_DEBUG
	P_DEFAULT
	P_DETACH
	P_FOREGROUND
	P_FULLSCREEN
	P_MAXIMIZE
	P_MINIMIZE
	P_NOCLOSE
	P_NOSESSION
	P_NOWAIT
	P_OVERLAY
	P_PM
	P_QUOTE
	P_SESSION
	P_TILDE
	P_UNRELATED
	P_WAIT
	P_WINDOWED
	my_type
	file_type
	T_NOTSPEC
	T_NOTWINDOWCOMPAT
	T_WINDOWCOMPAT
	T_WINDOWAPI
	T_BOUND
	T_DLL
	T_DOS
	T_PHYSDRV
	T_VIRTDRV
	T_PROTDLL
	T_32BIT
	ppid
	ppidOf
	sidOf
	scrsize
	scrsize_set
	process_entry
	process_entries
	process_hentry
	process_hentries
	change_entry
	change_entryh
	Title_set
	Title
	WindowText
	WindowText_set
	WindowPos
	WindowPos_set
	WindowProcess
	SwitchToProgram
	ActiveWindow
	ClassName
	FocusWindow
	FocusWindow_set
	ShowWindow
	PostMsg
	BeginEnumWindows
	EndEnumWindows
	GetNextWindow
	IsWindow
	ChildWindows
	out_codepage
	out_codepage_set
	in_codepage
	in_codepage_set
	cursor
	cursor_set
	screen
	screen_set
	process_codepages
	QueryWindow
	WindowFromId
	WindowFromPoint
	EnumDlgItem

	get_title
	set_title
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined OS2::Process macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

# Preloaded methods go here.

sub Title () { (process_entry())[0] }

# *Title_set = \&sesmgr_title_set;

sub swTitle_set_sw {
  my ($title, @sw) = @_;
  $sw[0] = $title;
  change_entry(@sw);
}

sub swTitle_set {
  my (@sw) = process_entry();
  swTitle_set_sw(shift, @sw);
}

sub winTitle_set_sw {
  my ($title, @sw) = @_;
  my $h = OS2::localMorphPM->new(0);
  WindowText_set $sw[1], $title;
}

sub winTitle_set {
  my (@sw) = process_entry();
  winTitle_set_sw(shift, @sw);
}

sub bothTitle_set {
  my (@sw) = process_entry();
  my $t = shift;
  winTitle_set_sw($t, @sw);
  swTitle_set_sw($t, @sw);
}

sub Title_set {
  my $t = shift;
  return 1 if sesmgr_title_set($t);
  return 0 unless $^E == 372;
  my (@sw) = process_entry();
  winTitle_set_sw($t, @sw);
  swTitle_set_sw($t, @sw);
}

sub process_entry { swentry_expand(process_swentry(@_)) }

our @hentry_fields = qw( title owner_hwnd icon_hwnd 
			 owner_phandle owner_pid owner_sid
			 visible nonswitchable jumpable ptype sw_entry );

sub swentry_hexpand ($) {
  my %h;
  @h{@hentry_fields} = swentry_expand(shift);
  \%h;
}

sub process_hentry { swentry_hexpand(process_swentry(@_)) }

my $swentry_size = swentry_size();

sub sw_entries () {
  my $s = swentries_list();
  my ($c, $s1) = unpack 'La*', $s;
  die "Unconsistent size in swentries_list()" unless 4+$c*$swentry_size == length $s;
  my (@l, $e);
  push @l, $e while $e = substr $s1, 0, $swentry_size, '';
  @l;
}

sub process_entries () {
  map [swentry_expand($_)], sw_entries;
}

sub process_hentries () {
  map swentry_hexpand($_), sw_entries;
}

sub change_entry {
  change_swentry(create_swentry(@_));
}

sub create_swentryh ($) {
  my $h = shift;
  create_swentry(@$h{@hentry_fields});
}

sub change_entryh ($) {
  change_swentry(create_swentryh(shift));
}

# Massage entries into the same order as WindowPos_set:
sub WindowPos ($) {
  my ($fl, $w, $h, $x, $y, $behind, $hwnd, @rest)
	= unpack 'L l4 L4', WindowSWP(shift);
  ($x, $y, $fl, $w, $h, $behind, @rest);
}

sub ChildWindows ($) {
  my @kids;
  my $h = BeginEnumWindows shift;
  my $w;
  push @kids, $w while $w = GetNextWindow $h;
  EndEnumWindows $h;
  @kids;
}

# backward compatibility
*set_title = \&Title_set;
*get_title = \&Title;

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__

=head1 NAME

OS2::Process - exports constants for system() call, and process control on OS2.

=head1 SYNOPSIS

    use OS2::Process;
    $pid = system(P_PM | P_BACKGROUND, "epm.exe");

=head1 DESCRIPTION

=head2 Optional argument to system()

the builtin function system() under OS/2 allows an optional first
argument which denotes the mode of the process. Note that this argument is
recognized only if it is strictly numerical.

You can use either one of the process modes:

	P_WAIT (0)	= wait until child terminates (default)
	P_NOWAIT	= do not wait until child terminates
	P_SESSION	= new session
	P_DETACH	= detached
	P_PM		= PM program

and optionally add PM and session option bits:

	P_DEFAULT (0)	= default
	P_MINIMIZE	= minimized
	P_MAXIMIZE	= maximized
	P_FULLSCREEN	= fullscreen (session only)
	P_WINDOWED	= windowed (session only)

	P_FOREGROUND	= foreground (if running in foreground)
	P_BACKGROUND	= background

	P_NOCLOSE	= don't close window on exit (session only)

	P_QUOTE		= quote all arguments
	P_TILDE		= MKS argument passing convention
	P_UNRELATED	= do not kill child when father terminates

=head2 Access to process properties

On OS/2 processes have the usual I<parent/child> semantic;
additionally, there is a hierarchy of sessions with their own
I<parent/child> tree.  A session is either a FS session, or a windowed
pseudo-session created by PM.  A session is a "unit of user
interaction", a change to in/out settings in one of them does not
affect other sessions.

=over

=item my_type()

returns the type of the current process (one of
"FS", "DOS", "VIO", "PM", "DETACH" and "UNKNOWN"), or C<undef> on error.

=item C<file_type(file)>

returns the type of the executable file C<file>, or
dies on error.  The bits 0-2 of the result contain one of the values

=over

=item C<T_NOTSPEC> (0)

Application type is not specified in the executable header.

=item C<T_NOTWINDOWCOMPAT> (1)

Application type is not-window-compatible.

=item C<T_WINDOWCOMPAT> (2)

Application type is window-compatible.

=item C<T_WINDOWAPI> (3)

Application type is window-API.

=back

The remaining bits should be masked with the following values to
determine the type of the executable:

=over

=item C<T_BOUND> (8)

Set to 1 if the executable file has been "bound" (by the BIND command)
as a Family API application. Bits 0, 1, and 2 still apply.

=item C<T_DLL> (0x10)

Set to 1 if the executable file is a dynamic link library (DLL)
module. Bits 0, 1, 2, 3, and 5 will be set to 0.

=item C<T_DOS> (0x20)

Set to 1 if the executable file is in PC/DOS format. Bits 0, 1, 2, 3,
and 4 will be set to 0.

=item C<T_PHYSDRV> (0x40)

Set to 1 if the executable file is a physical device driver.

=item C<T_VIRTDRV> (0x80)

Set to 1 if the executable file is a virtual device driver.

=item C<T_PROTDLL> (0x100)

Set to 1 if the executable file is a protected-memory dynamic link
library module.

=item C<T_32BIT> (0x4000)

Set to 1 for 32-bit executable files.

=back

file_type() may croak with one of the strings C<"Invalid EXE
signature"> or C<"EXE marked invalid"> to indicate typical error
conditions.  If given non-absolute path, will look on C<PATH>, will
add extention F<.exe> if no extension is present (add extension F<.>
to suppress).

=item C<@list = process_codepages()>

the first element is the currently active codepage, up to 2 additional
entries specify the system's "prepared codepages": the codepages the
user can switch to.  The active codepage of a process is one of the
prepared codepages of the system (if present).

=item C<process_codepage_set($cp)>

sets the currently active codepage.  [Affects printer output, in/out
codepages of sessions started by this process, and the default
codepage for drawing in PM; is inherited by kids.  Does not affect the
out- and in-codepages of the session.]

=item ppid()

returns the PID of the parent process.

=item C<ppidOf($pid = $$)>

returns the PID of the parent process of $pid.  -1 on error.

=item C<sidOf($pid = $$)>

returns the session id of the process id $pid.  -1 on error.

=back

=head2 Control of VIO sessions

VIO applications are applications running in a text-mode session.

=over

=item out_codepage()

gets code page used for screen output (glyphs).  -1 means that a user font
was loaded.

=item C<out_codepage_set($cp)>

sets code page used for screen output (glyphs).  -1 switches to a preloaded
user font.  -2 switches off the preloaded user font.

=item in_codepage()

gets code page used for keyboard input.  0 means that a hardware codepage
is used.

=item C<in_codepage_set($cp)>

sets code page used for keyboard input.

=item C<($w, $h) = scrsize()>

width and height of the given console window in character cells.

=item C<scrsize_set([$w, ] $h)>

set height (and optionally width) of the given console window in
character cells.  Use 0 size to keep the old size.

=item C<($s, $e, $w, $a) = cursor()>

gets start/end lines of the blinking cursor in the charcell, its width
(1 on text modes) and attribute (-1 for hidden, in text modes other
values mean visible, in graphic modes color).

=item C<cursor_set($s, $e, [$w [, $a]])>

sets start/end lines of the blinking cursor in the charcell.  Negative
values mean percents of the character cell height.

=item screen()

gets a buffer with characters and attributes of the screen.

=item C<screen_set($buffer)>

restores the screen given the result of screen().

=back

=head2 Control of the process list

With the exception of Title_set(), all these calls require that PM is
running, they would not work under alternative Session Managers.

=over

=item process_entry()

returns a list of the following data:

=over

=item

Title of the process (in the C<Ctrl-Esc> list);

=item

window handle of switch entry of the process (in the C<Ctrl-Esc> list);

=item

window handle of the icon of the process;

=item

process handle of the owner of the entry in C<Ctrl-Esc> list;

=item

process id of the owner of the entry in C<Ctrl-Esc> list;

=item

session id of the owner of the entry in C<Ctrl-Esc> list;

=item

whether visible in C<Ctrl-Esc> list;

=item

whether item cannot be switched to (note that it is not actually
grayed in the C<Ctrl-Esc> list));

=item

whether participates in jump sequence;

=item

program type.  Possible values are:

     PROG_DEFAULT                       0
     PROG_FULLSCREEN                    1
     PROG_WINDOWABLEVIO                 2
     PROG_PM                            3
     PROG_VDM                           4
     PROG_WINDOWEDVDM                   7

Although there are several other program types for WIN-OS/2 programs,
these do not show up in this field. Instead, the PROG_VDM or
PROG_WINDOWEDVDM program types are used. For instance, for
PROG_31_STDSEAMLESSVDM, PROG_WINDOWEDVDM is used. This is because all
the WIN-OS/2 programs run in DOS sessions. For example, if a program
is a windowed WIN-OS/2 program, it runs in a PROG_WINDOWEDVDM
session. Likewise, if it's a full-screen WIN-OS/2 program, it runs in
a PROG_VDM session.

=item

switch-entry handle.

=back

Optional arguments: the pid and the window-handle of the application running
in the OS/2 session to query.

=item process_hentry()

similar to process_entry(), but returns a hash reference, the keys being

  title owner_hwnd icon_hwnd owner_phandle owner_pid owner_sid
  visible nonswitchable jumpable ptype sw_entry

(a copy of the list of keys is in @hentry_fields).

=item process_entries()

similar to process_entry(), but returns a list of array reference for all
the elements in the switch list (one controlling C<Ctrl-Esc> window).

=item process_hentries()

similar to process_hentry(), but returns a list of hash reference for all
the elements in the switch list (one controlling C<Ctrl-Esc> window).

=item change_entry()

changes a process entry, arguments are the same as process_entry() returns.

=item change_entryh()

Similar to change_entry(), but takes a hash reference as an argument.

=item Title()

returns a title of the current session.  (There is no way to get this
info in non-standard Session Managers, this implementation is a
shortcut via process_entry().)

=item C<Title_set(newtitle)>

tries two different interfaces.  The Session Manager one does not work
with some windows (if the title is set from the start).
This is a limitation of OS/2, in such a case $^E is set to 372 (type

  help 372

for a funny - and wrong  - explanation ;-).  In such cases a
direct-manipulation of low-level entries is used.  Keep in mind that
some versions of OS/2 leak memory with such a manipulation.

=item C<SwitchToProgram($sw_entry)>

switch to session given by a switch list handle.

Use of this function causes another window (and its related windows)
of a PM session to appear on the front of the screen, or a switch to
another session in the case of a non-PM program. In either case,
the keyboard (and mouse for the non-PM case) input is directed to
the new program.

=back

=head2 Control of the PM windows

Some of these API's require sending a message to the specified window.
In such a case the process needs to be a PM process, or to be morphed
to a PM process via OS2::MorphPM().

For a temporary morphing to PM use L<OS2::localMorphPM class>.

Keep in mind that PM windows are engaged in 2 "orthogonal" window
trees, as well as in the z-order list.

One tree is given by the I<parent/child> relationship.  This
relationship affects drawing (child is drawn relative to its parent
(lower-left corner), and the drawing is clipped by the parent's
boundary; parent may request that I<it's> drawing is clipped to be
confined to the outsize of the childs and/or siblings' windows);
hiding; minimizing/restoring; and destroying windows.

Another tree (not necessarily connected?) is given by I<ownership>
relationship.  Ownership relationship assumes cooperation of the
engaged windows via passing messages on "important events"; e.g.,
scrollbars send information messages when the "bar" is moved, menus
send messages when an item is selected; frames
move/hide/unhide/minimize/restore/change-z-order-of owned frames when
the owner is moved/etc., and destroy the owned frames (even when these
frames are not descendants) when the owner is destroyed; etc.  [An
important restriction on ownership is that owner should be created by
the same thread as the owned thread, so they engage in the same
message queue.]

Windows may be in many different state: Focused, Activated (=Windows
in the I<parent/child> tree between the root and the window with
focus; usually indicate such "active state" by titlebar highlights),
Enabled/Disabled (this influences *an ability* to receive user input
(be focused?), and may change appearance, as for enabled/disabled
buttons), Visible/Hidden, Minimized/Maximized/Restored, Modal, etc.

=over

=item C<WindowText($hwnd)>

gets "a text content" of a window.

=item C<WindowText_set($hwnd, $text)>

sets "a text content" of a window.

=item C<WindowPos($hwnd)>

gets window position info as 8 integers (of C<SWP>), in the order suitable
for WindowPos_set(): $x, $y, $fl, $w, $h, $behind, @rest.

=item C<WindowPos_set($hwnd, $x, $y, $flags = SWP_MOVE, $wid = 0, $h = 0, $behind = HWND_TOP)>

Set state of the window: position, size, zorder, show/hide, activation,
minimize/maximize/restore etc.  Which of these operations to perform
is governed by $flags.

=item C<WindowProcess($hwnd)>

gets I<PID> and I<TID> of the process associated to the window.

=item ActiveWindow([$parentHwnd])

gets the active subwindow's handle for $parentHwnd or desktop.
Returns FALSE if none.

=item C<ClassName($hwnd)>

returns the class name of the window.

If this window is of any of the preregistered WC_* classes the class
name returned is in the form "#nnnnn", where "nnnnn" is a group
of up to five digits that corresponds to the value of the WC_* class name
constant.

=item FocusWindow()

returns the handle of the focus window.  Optional argument for specifying the desktop
to use.

=item C<FocusWindow_set($hwnd)>

set the focus window by handle.  Optional argument for specifying the desktop
to use.  E.g, the first entry in program_entries() is the C<Ctrl-Esc> list.
To show it

       WinShowWindow( wlhwnd, TRUE );
       WinSetFocus( HWND_DESKTOP, wlhwnd );
       WinSwitchToProgram(wlhswitch);


=item C<ShowWindow($hwnd [, $show])>

Set visible/hidden flag of the window.  Default: $show is TRUE.

=item C<PostMsg($hwnd, $msg, $mp1, $mp2)>

post message to a window.  The meaning of $mp1, $mp2 is specific for each
message id $msg, they default to 0.  E.g., in C it is done similar to

    /* Emulate `Restore' */
    WinPostMsg(SwitchBlock.tswe[i].swctl.hwnd, WM_SYSCOMMAND,
               MPFROMSHORT(SC_RESTORE),        0);

    /* Emulate `Show-Contextmenu' (Double-Click-2) */
    hwndParent = WinQueryFocus(HWND_DESKTOP);
    hwndActive = WinQueryActiveWindow(hwndParent);
    WinPostMsg(hwndActive, WM_CONTEXTMENU, MPFROM2SHORT(0,0), MPFROMLONG(0));

    /* Emulate `Close' */
    WinPostMsg(pSWB->aswentry[i].swctl.hwnd, WM_CLOSE, 0, 0);

    /* Same but softer: */
    WinPostMsg(hwndactive, WM_SAVEAPPLICATION, 0L, 0L);
    WinPostMsg(hwndactive, WM_CLOSE, 0L, 0L));
    WinPostMsg(hwndactive, WM_QUIT, 0L, 0L));

=item C<$eh = BeginEnumWindows($hwnd)>

starts enumerating immediate child windows of $hwnd in z-order.  The
enumeration reflects the state at the moment of BeginEnumWindows() calls;
use IsWindow() to be sure.

=item C<$kid_hwnd = GetNextWindow($eh)>

gets the next kid in the list.  Gets 0 on error or when the list ends.

=item C<EndEnumWindows($eh)>

End enumeration and release the list.

=item C<@list = ChildWindows($hwnd)>

returns the list of child windows at the moment of the call.  Same remark
as for enumeration interface applies.  Example of usage:

  sub l {
    my ($o,$h) = @_;
    printf ' ' x $o . "%#x\n", $h;
    l($o+2,$_) for ChildWindows $h;
  }
  l 0, $HWND_DESKTOP

=item C<IsWindow($hwnd)>

true if the window handle is still valid.

=item C<QueryWindow($hwnd, $type)>

gets the handle of a related window.  $type should be one of C<QW_*> constants.

=item C<IsChild($hwnd, $parent)>

return TRUE if $hwnd is a descendant of $parent.

=item C<WindowFromId($hwnd, $id)>

return a window handle of a child of $hwnd with the given $id.

  hwndSysMenu = WinWindowFromID(hwndDlg, FID_SYSMENU);
  WinSendMsg(hwndSysMenu, MM_SETITEMATTR,
      MPFROM2SHORT(SC_CLOSE, TRUE),
      MPFROM2SHORT(MIA_DISABLED, MIA_DISABLED));

=item C<WindowFromPoint($x, $y [, $hwndParent [, $descedantsToo]])>

gets a handle of a child of $hwndParent at C<($x,$y)>.  If $descedantsToo
(defaulting to 0) then children of children may be returned too.  May return
$hwndParent (defaults to desktop) if no suitable children are found,
or 0 if the point is outside the parent.

$x and $y are relative to $hwndParent.

=item C<EnumDlgItem($dlgHwnd, $type [, $relativeHwnd])>

gets a dialog item window handle for an item of type $type of $dlgHwnd
relative to $relativeHwnd, which is descendant of $dlgHwnd.
$relativeHwnd may be specified if $type is EDI_FIRSTTABITEM or
EDI_LASTTABITEM.

The return is always an immediate child of hwndDlg, even if hwnd is
not an immediate child window.  $type may be

=over

=item EDI_FIRSTGROUPITEM

First item in the same group.

=item EDI_FIRSTTABITEM

First item in dialog with style WS_TABSTOP. hwnd is ignored.

=item EDI_LASTGROUPITEM

Last item in the same group.

=item EDI_LASTTABITEM

Last item in dialog with style WS_TABSTOP. hwnd is ignored.

=item EDI_NEXTGROUPITEM

Next item in the same group. Wraps around to beginning of group when
the end of the group is reached.

=item EDI_NEXTTABITEM

Next item with style WS_TABSTOP. Wraps around to beginning of dialog
item list when end is reached.

=item EDI_PREVGROUPITEM

Previous item in the same group. Wraps around to end of group when the
start of the group is reached. For information on the WS_GROUP style,
see Window Styles.

=item EDI_PREVTABITEM

Previous item with style WS_TABSTOP. Wraps around to end of dialog
item list when beginning is reached.

=back

=back

=head1 OS2::localMorphPM class

This class morphs the process to PM for the duration of the given context.

  {
    my $h = OS2::localMorphPM->new(0);
    # Do something
  }

The argument has the same meaning as one to OS2::MorphPM().  Calls can
nest with internal ones being NOPs.

=head1 TODO

Constants (currently one needs to get them looking in a header file):

  HWND_*
  WM_*			/* Separate module? */
  SC_*
  SWP_*
  WC_*
  PROG_*
  QW_*
  EDI_*
  WS_*

Show/Hide, Enable/Disable (WinShowWindow(), WinIsWindowVisible(),
WinEnableWindow(), WinIsWindowEnabled()).

Maximize/minimize/restore via WindowPos_set(), check via checking
WS_MAXIMIZED/WS_MINIMIZED flags (how to get them?).

=head1 $^E

the majority of the APIs of this module set $^E on failure (no matter
whether they die() on failure or not).  By the semantic of PM API
which returns something other than a boolean, it is impossible to
distinguish failure from a "normal" 0-return.  In such cases C<$^E ==
0> indicates an absence of error.

=head1 BUGS

whether a given API dies or returns FALSE/empty-list on error may be
confusing.  This may change in the future.

=head1 AUTHOR

Andreas Kaiser <ak@ananke.s.bawue.de>,
Ilya Zakharevich <ilya@math.ohio-state.edu>.

=head1 SEE ALSO

C<spawn*>() system calls, L<OS2::Proc> and L<OS2::WinObject> modules.

=cut
