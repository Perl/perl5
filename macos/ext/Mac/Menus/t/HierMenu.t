#!perl
use Mac::Menus;
use Mac::Events;

$menu = MacMenu->new(2048, "Demo", (
  ["One", \&Handler],
  ["Two", \&Handler],
  ["Three", \&Handler, hMenuCmd(), chr(217)],
));
$menu1 = MacHierMenu->new(217, "Demo1", (
  ["One", \&Handler],
  ["Two", \&Handler],
  ["Three", \&Handler],
));

$menu->insert();
$menu1->insert();

WaitNextEvent until defined $Menu;

$menu->dispose();

sub Handler {
  my($menu,$item) = @_;

  print "Selected menu ", $menu, " item ", $item, "\n";
  $Menu = $item;
}
