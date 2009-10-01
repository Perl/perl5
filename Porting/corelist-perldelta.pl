#!perl
use 5.010;
use strict;
use warnings;
use lib 'Porting';
use Maintainers qw/%Modules/;
use Module::CoreList;

my $corelist = \%Module::CoreList::version;
my @versions = sort keys %$corelist;

# by default, compare latest two version in CoreList;
my ($old, $new) = @ARGV;
$old ||= $versions[-2];
$new ||= $versions[-1];

say "=head2 Updated Modules\n";
say "=over 4\n";

for my $mod ( sort { lc $a cmp lc $b } keys %Modules ) {
  my $old_ver = $corelist->{$old}{$mod};
  my $new_ver = $corelist->{$new}{$mod};
  next unless defined $old_ver && defined $new_ver && $old_ver ne $new_ver;
  say "=item C<$mod>\n";
  say "Upgraded from version $old_ver to $new_ver.\n";
}

say "=back\n";
