=head1 NAME

Mac::Dialogs - Macintosh Toolbox Interface to Dialog Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Dialogs;

BEGIN {
    use Exporter   ();
    use DynaLoader ();
    use Carp;
    use Mac::Events;
    use Mac::Events qw(DispatchEvent $CurrentEvent @SavedEvents @Event);
    use Mac::Windows;
    use Mac::Controls qw(HiliteControl GetControlValue SetControlValue);
    
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %Dialog %DialogUserItem);
    $VERSION = '1.00';
    @ISA = qw(Exporter DynaLoader);
    @EXPORT = qw(
        NewDialog
        GetNewDialog
        DisposeDialog
        ParamText
        ModalDialog
        IsDialogEvent
        DialogSelect
        DrawDialog
        UpdateDialog
        Alert
        StopAlert
        NoteAlert
        CautionAlert
        GetDialogItem
        GetDialogItemControl
        SetDialogItem
        SetDialogItemProc
        HideDialogItem
        ShowDialogItem
        SelectDialogItemText
        GetDialogItemText
        SetDialogItemText
        FindDialogItem
        NewColorDialog
        GetAlertStage
        ResetAlertStage
        DialogCut
        DialogPaste
        DialogCopy
        DialogDelete
        SetDialogFont
        AppendDITL
        CountDITL
        ShortenDITL
        StdFilterProc
        SetDialogDefaultItem
        SetDialogCancelItem
        SetDialogTracksCursor
    
        kControlDialogItem
        kButtonDialogItem
        kCheckBoxDialogItem
        kRadioButtonDialogItem
        kResourceControlDialogItem
        kStaticTextDialogItem
        kEditTextDialogItem
        kIconDialogItem
        kPictureDialogItem
        kUserDialogItem
        kItemDisableBit
        kStdOkItemIndex
        kStdCancelItemIndex
        kStopIcon
        kNoteIcon
        kCautionIcon
        kOkItemIndex
        kCancelItemIndex
        overlayDITL
        appendDITLRight
        appendDITLBottom
    );
    
    @EXPORT_OK = qw(
        %Dialog
        %DialogUserItem
    );
}

=head2 Constants

=item kControlDialogItem

=item kButtonDialogItem

=item kCheckBoxDialogItem

=item kRadioButtonDialogItem

=item kResourceControlDialogItem

=item kStaticTextDialogItem

=item kEditTextDialogItem

=item kIconDialogItem

=item kPictureDialogItem

=item kUserDialogItem

=item kItemDisableBit

Dialog item types.

=cut
sub kControlDialogItem ()          {          4; }
sub kButtonDialogItem ()           {          4; }
sub kCheckBoxDialogItem ()         {          5; }
sub kRadioButtonDialogItem ()      {          6; }
sub kResourceControlDialogItem ()  {          7; }
sub kStaticTextDialogItem ()       {          8; }
sub kEditTextDialogItem ()         {         16; }
sub kIconDialogItem ()             {         32; }
sub kPictureDialogItem ()          {         64; }
sub kUserDialogItem ()             {          0; }
sub kItemDisableBit ()             {        128; }


=item kStopIcon

=item kNoteIcon

=item kCautionIcon

Standard icons.

=cut
sub kStopIcon ()                   {          0; }
sub kNoteIcon ()                   {          1; }
sub kCautionIcon ()                {          2; }


=item kStdOkItemIndex

=item kStdCancelItemIndex

Standard button numbers.

=cut
sub kStdOkItemIndex ()             {          1; }
sub kStdCancelItemIndex ()         {          2; }


=item overlayDITL

=item appendDITLRight

=item appendDITLBottom

Options for C<AppendDITL>.

=cut
sub overlayDITL ()                 {          0; }
sub appendDITLRight ()             {          1; }
sub appendDITLBottom ()            {          2; }

=back

=cut
#
# _ModalFilter - call a modal filter procedure
#
sub _ModalFilter {
    no strict qw(refs);
    
    my($proc, $dialog, $event) = @_;
    push @SavedEvents, $CurrentEvent;
    $CurrentEvent = $event;
    my($res) = &$proc($dialog, $event);
    $CurrentEvent = pop @SavedEvents;
    $res;
}

#
# _DefaultModalFilter - simply do the right thing; handle nonlocal updates, drags,
# zooms, grows & the like.
#
sub _DefaultModalFilter {
    my($dialog, $ev) = @_;
    if ($ev->what == updateEvt && ${$ev->window} != $$dialog) {
        DispatchEvent $ev;
        $ev->what(nullEvent);
        
        return 0;
    } elsif ($ev->what == mouseDown) {
        my($code,$win) = FindWindow($ev->where);
        if ($win && $$win == $$dialog && $code != inContent) {
            DispatchEvent $ev;
            $ev->what(nullEvent);
            
            return 0;
        }
    } 
    StdFilterProc($dialog, $ev);
}

#
# _UserItem - draw an user item
#
sub _UserItem {
    my($dialog, $item) = @_;
    my($proc) = $DialogUserItem{$$dialog}->[$item-1];
    
    $proc and &$proc($dialog, $item);
}

bootstrap Mac::Dialogs;

=include Dialogs.xs

=cut
#
# The dialog creation procedures can take a WDEF written in Perl, but to
# concentrate that code in one place, we'll redirect that option to
# Mac::Windows.
#
sub NewDialog {
    my($bounds, $visible, $title, $proc) = @_;
    if (!ref($proc) && (!$proc || $proc != 0)) {
        _NewDialog(@_); # Numeric WDEF
    } else {
        my $dlg = _NewDialog($bounds, 0, $title, zoomDocProc, @_[4..$#_]);
        $dlg->windowDefProc($proc);
        ShowWindow($dlg) if ($visible);
        $dlg;
    }
}

sub NewColorDialog {
    my($bounds, $visible, $title, $proc) = @_;
    if (!ref($proc) && (!$proc || $proc != 0)) {
        _NewColorDialog(@_);    # Numeric WDEF
    } else {
        my $dlg = _NewColorDialog($bounds, 0, $title, zoomDocProc, @_[4..$#_]);
        $dlg->windowDefProc($proc);
        ShowWindow($dlg) if ($visible);
        $dlg;
    }
}

=item TEXT = GetDialogItemText DIALOG, ITEM

=item TEXT = GetDialogItemText ITEMHANDLE

Returns the text of a dialog item.

=cut
sub GetDialogItemText {
    my($variant) = @_;
    my($itemhandle,$dialog,$item);
    if (ref($variant) eq "GrafPtr") {
        ($dialog,$item) = @_;
        $itemhandle = (GetDialogItem($dialog, $item))[1];
    } else {
        $itemhandle = @_;
    }
    _GetDialogItemText($itemhandle);
}

=item SetDialogItemText DIALOG, ITEM, TEXT

=item SetDialogItemText ITEMHANDLE, TEXT

Sets the text of a dialog item.

=cut
sub SetDialogItemText {
    my($variant) = @_;
    my($itemhandle,$dialog,$item,$text);
    if (ref($variant) eq "GrafPtr") {
        ($dialog,$item,$text) = @_;
        $itemhandle = (GetDialogItem($dialog, $item))[1];
    } else {
        ($itemhandle, $text) = @_;
    }
    _SetDialogItemText($itemhandle, $text);
}

=item SetDialogItemProc DIALOG, ITEM, PROC

Set up a drawing procedure for a dialog item.

=cut
sub SetDialogItemProc {
    my($dialog, $item, $proc) = @_;
    $DialogUserItem{$$dialog}->[$item-1] = $proc;
    _SetDialogItemProc($dialog, $item);
}

=item PROC = GetDialogItemProc DIALOG, ITEM

Returns the drawing procedure for a dialog item.

=cut
sub GetDialogItemProc {
    my($dialog, $item) = @_;
    $DialogUserItem{$$dialog}->[$item-1];
}

=item DisposeDialog DIALOG

Delete the dialog.

=cut
sub DisposeDialog {
    my($dialog) = @_;
    delete $DialogUserItem{$$dialog};
    _DisposeDialog($dialog);
}

=back

=head2 MacDialog - The Object Interface

Correctly handling a Mac dialog requires quite a bit of event management. The
C<MacDialog> class relieves you of most of these duties.

=over 4

=cut
package MacDialog;

BEGIN {
    use Mac::Windows qw(%Window);
    import Mac::Dialogs;
    import Mac::Dialogs qw(%Dialog %DialogUserItem);
    use Mac::Events qw($CurrentEvent);
    use Mac::Controls qw(HiliteControl GetControlValue SetControlValue);
    use Carp;
    
    use vars qw(@ISA);
    
    @ISA = qw(MacWindow);
}

=item new MacDialog PORT

=item new MacDialog ID [, BEHIND]

=item new MacDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMS, [, REFCON [, BEHIND]]

=item new MacDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMLIST, [, REFCON [, BEHIND]]

Register a new dialog. In the first form, registers an existing dialog. In the
second form, calls C<GetNewDialog>. In the third form, calls C<NewDialog>. In
the fourth form, takes items as a dialogitemlist.

=cut
sub new {
    my($class) = shift @_;
    my($type) = @_;
    my($port);
    
    if (ref($type) eq "Rect") {
        if (ref($_[5]) eq "ARRAY") { # Item list
            my @items = splice(@_, 5);
            my @rest;
            while (ref($items[$#items]) ne "ARRAY") {
                unshift @rest, shift(@items);
            }
            push @_, (new MacDialogItems @items)->get, @rest;
        }
        $port = NewDialog(@_) or croak "NewDialog failed";
    } elsif (!ref($type)) {
        $port = GetNewDialog(@_) or croak "GetNewDialog failed";
    } else {
        $port = $type;
    }
    my($my) = MacWindow::new($class, $port);
    $Dialog{$$port} = $my;
}

=item dispose 

Unregisters and disposes the dialog.

=cut
sub dispose {
    my($my) = @_;
    return unless $my->{port};
    defined($_[0]->callhook("dispose", @_)) and return;
    delete $Window{${$my->{port}}};
    delete $Dialog{${$my->{port}}};
    DisposeDialog($my->{port});
    $my->{port} = "";
}

sub _dialogselect {
    my($my) = @_;
    my($event) = $CurrentEvent;
    
    $event && IsDialogEvent($event) or return 0;
    
    my($itemhit) = StdFilterProc($my->{port}, $event);
    unless ($itemhit) {
        my($dialog);
        ($dialog, $itemhit) = DialogSelect($event);
    
        croak("Weirdness in DialogSelect") 
            if $itemhit && $$dialog != ${$my->{port}};
    }
    
    $my->hit($itemhit) if $itemhit;
    
    1;
}

=item activate ACTIVE, SUSPEND

Handle activation of the window, which is already set to the current port.
By default doesn't do anything. Override as necessary.

The parameters distinguish the four cases:

   Event      ACTIVE  SUSPEND
   
   Activate      1       0
   Deactivate    0       0
   Suspend       0       1
   Resume        1       1

=cut
sub activate {
    defined($_[0]->callhook("activate", @_)) and return;
    _dialogselect(@_);
}

=item update 

Handle update events. 

=cut
sub update {
    defined($_[0]->callhook("update", @_)) and return;
    _dialogselect(@_);
}

=item key KEY

Handle a keypress and return 1 if the key was handled.

=cut
sub key {
    my($handled);
    defined($handled = $_[0]->callhook("key", @_)) and return $handled;
    _dialogselect(@_);
}

=item click PT

Handle a mouse click and return 1 if the click was handled.

=cut
sub click {
	my($self, $pt) = @_;
	for my $pane (@{$self->{panes}}) { 
		if ($pane->click($self, $pt)) {
			$self->advance_focus($pane);
			return 1; 
		}
	};
	my($handled);
	defined($handled = $self->callhook("click", @_)) and return 1;
	_dialogselect(@_);
}

=item modal [FILTER]

Run dialog modally.

=cut
sub modal {
    $_[0]->callhook("modal", @_) and return;
    
    my($my) = shift @_;
    my($itemhit) = ModalDialog(@_);
    
    $my->hit($itemhit) if $itemhit;
}

=item hit ITEM

Handle a "hit" of an enabled item. Usually dispatches to hook.

=cut
sub hit {
    $_[0]->callhook("hit", @_) and return;
    
    my($my, $itemhit) = @_;
    my($proc) = $my->{items}->[$itemhit-1];
    
    &$proc($my, $itemhit) if $proc;
}

=item idle 

Handle idle (null) events. 

=cut
sub idle {
	#
	# MacPerl 5.1.9r4 and earlier failed to propagate null events, so
	# we'll make mouse moved events honorary null events (luckily these
	# versions also generated too many mouse moved events :-)
	#
	my($savedwhat) = $CurrentEvent->what;
	$CurrentEvent->what(0);
	&_dialogselect;
	$CurrentEvent->what($savedwhat);
	&MacWindow::idle;
}

=item KIND = item_kind ITEM

=item item_kind ITEM, KIND

Get/Set item kind.

=cut
sub item_kind {
    my($my, $item, $kind) = @_;
    
    my($ikind,$ihandle,$ibox) = GetDialogItem($my->{port}, $item);
    
    defined($kind) ? 
        SetDialogItem($my->{port}, $item, $kind, $ihandle, $ibox) 
      : $ikind;
}

=item item_handle ITEM

=item item_handle ITEM, HANDLE

Get/Set item handle.

=cut
sub item_handle {
    my($my, $item, $handle) = @_;
    
    my($ikind,$ihandle,$ibox) = GetDialogItem($my->{port}, $item);
    
    defined($handle) ? 
        SetDialogItem($my->{port}, $item, $ikind, $handle, $ibox) 
      : $ihandle;
}

=item item_control ITEM

Get item control (You should never have a reason to set it).

=cut
sub item_control {
    my($my, $item) = @_;
    
    GetDialogItemControl($my->{port}, $item);
}

=item item_box ITEM

=item item_box ITEM, BOX

Get/Set item boundaries.

=cut
sub item_box {
    my($my, $item, $box) = @_;
    
    my($ikind,$ihandle,$ibox) = GetDialogItem($my->{port}, $item);
    
    defined($box) ? 
        SetDialogItem($my->{port}, $item, $ikind, $ihandle, $box) 
      : $ibox;
}

=item item_draw ITEM

=item item_draw ITEM, PROC

Get/Set procedure to draw item.

=cut
sub item_draw {
    my($my, $item, $proc) = @_;
    
    defined($proc) ? 
        SetDialogItemProc($my->{port}, $item, $proc) 
      : GetDialogItemProc($my->{port}, $item);
}

=item TEXT = item_text ITEM

=item item_text ITEM, TEXT

Get/Set text of dialog item.

=cut
sub item_text {
    my($my, $item, $text) = @_;
    
    defined($text) ? 
        SetDialogItemText($my->{port}, $item, $text) 
      : GetDialogItemText($my->{port}, $item);
}

=item item_hit ITEM

=item item_hit ITEM, PROC

Get/Set handler for item hit.

=cut
sub item_hit {
    my($my, $item, $proc) = @_;
    
    defined($proc) ? 
        ($my->{items}->[$item-1] = $proc)
      : $my->{items}->[$item-1];
}

=item item_hilite ITEM, HILITE

Set item hilite value.

=cut
sub item_hilite {
    my($my, $item, $value) = @_;
    
    HiliteControl($my->item_control($item), $value);
}

=item item_value ITEM

=item item_value ITEM, PROC

Get/Set control value for item.

=cut
sub item_value {
    my($my, $item, $value) = @_;
    
    defined($value) ? 
        SetControlValue($my->item_control($item), $value) :
        GetControlValue($my->item_control($item));
}

=back

=head2 MacColorDialog - The Object Interface

A C<MacColorDialog> is a colorful version of a C<MacDialog>.

=over 4

=cut
package MacColorDialog;

BEGIN {
    import Mac::Dialogs;
    use Carp;
}

=item new MacColorDialog PORT

=item new MacColorDialog ID [, BEHIND]

=item new MacColorDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMS, [, REFCON [, BEHIND]]

=item new MacColorDialog BOUNDS, TITLE, VISIBLE, PROC, GOAWAY, ITEMLIST, [, REFCON [, BEHIND]]

Register a new color dialog. The first two forms are just forwarded to MacDialog,
the third and fourth forms create actual color dialogs.

=cut
sub new {
    my($class) = shift @_;
    my($type) = @_;
    my($port);
    
    if (ref($type) eq "Rect") {
        if (ref($_[5]) eq "ARRAY") { # Item list
            my @items = splice(@_, 5);
            my @rest;
            while (ref($items[$#items]) ne "ARRAY") {
                unshift @rest, shift(@items);
            }
            push @_, (new MacDialogItems @items)->get, @rest;
        }
        $port = NewColorDialog(@_) or croak "NewColorDialog failed";
    } elsif (!ref($type)) {
        $port = GetNewDialog(@_) or croak "GetNewDialog failed";
    } else {
        $port = $type;
    }
    new MacDialog $port;
}

=back

=head2 MacDialogItems - Handle a dialog item list

The C<MacDialogItems> class is a wrapper for dialog item lists.

=over 4

=cut
package MacDialogItems;

BEGIN {
    use Mac::Memory ();
    import Mac::Dialogs;
}

=item new MacDialogItems

=item new MacDialogItems HANDLE

=item new MacDialogItems ITEMLIST

Construct a dialog item list; either an empty one, one derived from an existing
item list, or one constructed from a list of array references.

=cut
sub new {
    my($class) = shift @_;
    my($type) = @_;
    
    my($my) = bless [], $class;
    
    if (ref($type) eq "Handle") {   # Construct from existing item list
        my($data)  = $type->get;
        my($count,$length) = unpack("s", $data);
        $data = substr($data, 2);
        while ($count-- >= 0) {
            ($type,$length) = unpack("CC", substr($data, 12, 2));
            $type &= 127;
            if ($type == kUserDialogItem) {
                $length = 14;
            } elsif ($type == 1) {  # Help items
                $length += 14;
            } elsif ($type == kResourceControlDialogItem || $type >= kIconDialogItem) {
                $length = 16;
            } else {
                $length += 14 + ($length & 1);
            }
            push @$my, substr($data, 0, $length);
            $data = substr($data, $length);
        }
    } else {
        for (@_) {
            $my->add_item(@$_);
        }
    }
    $my;
}

=item add_item TYPE, ...

Add another dialog item.

=cut 
sub add_item {
    my($my,$type) = splice(@_, 0, 2);
    my($kind) = $type & 127;
    if ($type == kUserDialogItem) {
        my($r) = @_;
        push @$my, pack("x4 a8 C x", $$r, $type);
    } elsif ($type == 1) {  # Help items
        my($htype,$id,$item) = @_;
        if ($htype == 8) {
            push @$my, pack("x4 x8 C C s s s", $type, 6, $htype, $id, $item);
        } else {
            push @$my, pack("x4 x8 C C s s", $type, 4, $htype, $id);
        }
    } elsif ($type == kResourceControlDialogItem || $type >= kIconDialogItem) {
        my($r, $id) = @_;
        push @$my, pack("x4 a8 C x s", $$r, $id);
    } else {
        my($r, $text) = @_;
        my($len) = length($text);
        $len += $len&1;
        push @$my, pack("x4 a8 C C a$len", $$r, $type, length($text), $text);
    }   
}

=item (TYPE, ...) = get_item ITEM

=cut
sub get_item {
    my($my, $item) = @_;
    return () unless $item = $$my[$item];
    my($type) = unpack("C", substr($item, 12, 1));
    $type &= 127;
    if ($type == kUserDialogItem) {
        my($r,$type) = unpack("x4 a8 C x", $item);
        return ($type, bless($r, "Rect"));
    } elsif ($type == 1) {  # Help items
        my($type,$htype,$id,$item) = unpack("x4 x8 C x s s s", $item);
        if ($htype == 8) {
            return ($type, $htype, $id, $item);
        } else {
            return ($type, $htype, $id);
        }
    } elsif ($type == kResourceControlDialogItem || $type >= kIconDialogItem) {
        my($r, $type, $id) = unpack("x4 a8 C x s", $item);
        return ($type, bless($r, "Rect"), $id);
    } else {
        my($r, $type, $len) = unpack("x4 a8 C C", $item);
        my($text) = substr($item, 14, $len);
        return ($type, bless($r, "Rect"), $text);
    }   
}

=item HANDLE = get

Get dialog item list handle.

=cut
sub get {
    my($my) = @_;
    
    new Handle(pack("s", scalar(@$my)-1) . join("", @$my));
}

=back

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
