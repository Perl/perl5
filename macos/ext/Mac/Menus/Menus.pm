
=head1 NAME

Mac::Menus - Macintosh Toolbox Interface to Menu Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Menus;

BEGIN {
	use Exporter    ();
	use DynaLoader  ();
	use Mac::Events ();
	
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %Menu);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		GetMBarHeight
		NewMenu
		GetMenu
		DisposeMenu
		AppendMenu
		AppendResMenu
		InsertResMenu
		InsertMenu
		DrawMenuBar
		InvalMenuBar
		DeleteMenu
		ClearMenuBar
		GetNewMBar
		GetMenuBar
		SetMenuBar
		InsertMenuItem
		DeleteMenuItem
		HiliteMenu
		SetMenuItemText
		GetMenuItemText
		DisableItem
		EnableItem
		CheckItem
		SetItemMark
		GetItemMark
		SetItemIcon
		GetItemIcon
		SetItemStyle
		GetItemStyle
		CalcMenuSize
		CountMItems
		GetMenuHandle
		FlashMenuBar
		SetMenuFlash
		GetItemCmd
		SetItemCmd
		PopUpMenuSelect
		MenuChoice
		InsertFontResMenu
		InsertIntlResMenu
		
		noMark
		textMenuProc
		hMenuCmd
		hierMenu
	);
	
	@EXPORT_OK = qw(
		%Menu
	);
}
#
# _HandleMenu handles a menu selection
#
sub _HandleMenu {
	my($menuid, $item) = @_;
	return unless $item;
	my($handler);
	if ($handler = $Menu{sprintf("%04X", $menuid)}) {
		$handler->handle($menuid, $item);
	} elsif ($handler = $Menu{sprintf("%04X%04X", $menuid, $item)}) {
		&$handler($menuid, $item);
	}
}

#
# _PrepareMenus prepares all menus before a MenuSelect or MenuKey
#
sub _PrepareMenus {
	for my $menu (keys %Menu) {
		$Menu{$menu}->prepare if length($menu) == 4;
	}
}

my %MDEF;

#
# _MenuDefProc calls a custom MDEF
#
sub _MenuDefProc {
	my($item, $menu) = @_;
	my $mdef = $MDEF{$menu};
	
	&$mdef(@_) unless !defined $mdef;
}

package MenuHandle;

sub menuProc {
	my($menu, $proc) = @_;
	
	if (defined($proc)) {
		Mac::Menus::_SetMDEFProc($menu);
		$MDEF{$menu} = $proc;
	} else {
		$MDEF{$menu};
	}
}

package Mac::Menus;

bootstrap Mac::Menus;

=head2 Constants

=over 4

=item noMark

Don't mark this menu item.

=item textMenuProc

The standard menu definition procedure ID.

=item hierMenu

Insert as a hierarchical menu.

=back

=cut
sub noMark ()                      {          0; }
sub textMenuProc ()                {          0; }
sub hMenuCmd ()                    {    chr(27); }
sub hierMenu ()                    {         -1; }

=include Menus.xs

=item PopUpMenuSelect MENU, TOP, LEFT, POPITEM;

=cut
sub PopUpMenuSelect {
	&_HandleMenu(&_PopUpMenuSelect);
}

=item MenuChoice()

=cut
sub MenuChoice {
	&_HandleMenu(&_MenuChoice);
}

sub DisposeMenu {
	my($menu) = @_;
	delete $MDEF{$menu};
	_DisposeMenu($menu);
}

=back

=cut

=head2 MacMenu - The Object Interface

The C<MacMenu> class provides a convenient way of handling menus.

=over 4

=cut

package MacMenu;

BEGIN {
	use Carp;
	use Mac::Hooks ();
	import Mac::Menus;
	import Mac::Menus qw(%Menu);

	use vars qw(@ISA);
	
	@ISA = qw(Mac::Hooks);
}

=item new MacMenu ID, TITLE [, HANDLER] [, ITEMS]

=item new MacMenu MENU [, HANDLER] [, ITEMS]

Create a new C<MacMenu> and optionally install a default handler and items.

=cut
sub new {
	my($class, $id) = @_;
	
	if (ref($id) eq "MenuHandle") {	# Existing menu
		my($class, $menu, $handler) = @_;
		splice(@_, 0, 3);
		if (ref($handler) eq "ARRAY") {
			unshift @_, $handler;
			$handler = "";
		}
		my($ident) = sprintf("%04X", $id = $menu->menuID);
		my(%my) = 
			(	id 		=> $id, 
				ident 	=> $ident,
				inserted=> 0,
				menu 	=> $menu, 
				items	=> [$handler]
			);
		my($me) = bless \%my, $class;
		$Menu{$ident} = $me;
		for (@_) {
			push @{$me->{items}}, ${$_}[0];
		}
		$me;
	} else {
		my($class, $id, $title, $handler) = @_;
		splice(@_, 0, 4);
		if (ref($handler) eq "ARRAY") {
			unshift @_, $handler;
			$handler = "";
		}
		my($ident) = sprintf("%04X", $id);
		my($menu) = NewMenu($id, $title) or croak "NewMenu failed";
		my(%my) = 
			(	id 		=> $id, 
				ident 	=> $ident,
				inserted=> 0,
				menu 	=> $menu, 
				items	=> [$handler]
			);
		my($me) = bless \%my, $class;
		$Menu{$ident} = $me;
		for (@_) {
			if (scalar(@{$_})) {
				$me->add_item(@{$_});
			} else {
				$me->add_separator;
			}
		}
		$me;
	}
}

=item dispose 

Unregisters and disposes the menu.

=cut
sub dispose {
	my($my) = @_;
	return unless $my->{menu};
	defined($_[0]->callhook("dispose", @_)) and return;
	$my->delete;
	delete $Mac::Menus::Menu{$my->{ident}};
	DisposeMenu($my->{menu});
	$my->{menu} = "";
}

sub DESTROY {
	my($my) = @_;
	$my->dispose;
}

=item handle MENUID, ITEM

Item handle an item selection.

=cut
sub handle {
	my($handled);
	defined($handled = $_[0]->callhook("handle", @_)) and return $handled;
	my($my,$menuid,$item) = @_;
	my($handler) = $my->{items}[$item] || $my->{items}[0];
	$handler or return 0;
	&$handler($menuid, $item);
	1;
}

=item prepare 

Prepare menu before MenuSelect or MenuKey.

=cut
sub prepare {
	defined($_[0]->callhook("prepare", @_)) and return;
}

=item insert [BEFORE] 

Insert menu in menubar.

=cut
sub insert {
	return if $_[0]->{inserted};
	defined($_[0]->callhook("insert", @_)) and return;
	my($my) = shift;
	InsertMenu($my->{menu}, @_) ;
	$my->{inserted} = 1;
	InvalMenuBar();
}

=item delete

Delete menu from menubar.

=cut
sub delete {
	return unless $_[0]->{inserted};
	defined($_[0]->callhook("delete", @_)) and return;
	my($my) = @_;
	DeleteMenu($my->{id});
	$my->{inserted} = 0;
	InvalMenuBar();
}

=item ITEM = add_item TEXT, HANDLER, [, KEY [, MARK [, ICON]]]

Add an item.

=cut
sub add_item {
	defined($_[0]->callhook("add_item", @_)) and return;
	my($my, $text, $handler, $key, $mark, $icon) = @_;
	my($item) = scalar(@{$my->{items}});
	push @{$my->{items}}, $handler;
	AppendMenu($my->{menu}, "-");
	SetMenuItemText($my->{menu}, $item, $text);
	SetItemCmd($my->{menu}, $item, $key)		if defined($key);
	SetItemMark($my->{menu}, $item, $mark)		if defined($mark);
	SetItemIcon($my->{menu}, $item, $icon)		if defined($icon);
	$item;
}

=item ITEM = add_separator

Add an separator line.

=cut
sub add_separator {
	defined($_[0]->callhook("add_separator", @_)) and return;
	my($my) = @_;
	my($item) = scalar(@{$my->{items}});
	push @{$my->{items}}, "";
	AppendMenu($my->{menu}, "-(");
	$item;
}

=head2 MacHierMenu - The Object Interface to hierarchical menus.

The C<MacHierMenu> class provides a convenient way of handling hierarchical menus.
everything works identically to C<MacMenu>, except that C<insert> always inserts
hierachically.

=over 4

=cut
package MacHierMenu;

BEGIN {
	import Mac::Menus;

	use vars qw(@ISA);
	
	@ISA = qw(MacMenu);
}

sub insert {
	my($my) = @_;
	MacMenu::insert($my, &hierMenu);
}

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
