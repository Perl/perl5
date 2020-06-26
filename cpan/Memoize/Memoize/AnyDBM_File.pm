package Memoize::AnyDBM_File;

=head1 NAME

Memoize::AnyDBM_File - glue to provide EXISTS for AnyDBM_File for Storable use

=head1 DESCRIPTION

See L<Memoize>.

=cut

use vars qw(@ISA $VERSION);
$VERSION = '1.04';
@ISA = qw(DB_File GDBM_File Memoize::NDBM_File Memoize::SDBM_File ODBM_File) unless @ISA;

my $verbose;

my $mod;
for $mod (@ISA) {
#  (my $truemod = $mod) =~ s/^Memoize:://;
#  my $file = "$mod.pm";
#  $file =~ s{::}{/}g;
  if (eval "require $mod") {
    print STDERR "AnyDBM_File => Selected $mod.\n" if $verbose;
    @ISA = ($mod);	# if we leave @ISA alone, warnings abound
    return 1;
  }
}

die "No DBM package was successfully found or installed";
