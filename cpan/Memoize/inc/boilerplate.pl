use strict; use warnings;

use CPAN::Meta;
use Software::LicenseUtils 0.103011;
use Pod::Readme::Brief 1.001;

sub slurp { open my $fh, '<', $_[0] or die "Couldn't open $_[0] to read: $!\n"; local $/; readline $fh }
sub trimnl { s/\A\s*\n//, s/\s*\z/\n/ for @_; wantarray ? @_ : $_[-1] }
sub mkparentdirs {
	my @dir = do { my %seen; sort grep s!/[^/]+\z!! && !$seen{ $_ }++, my @copy = @_ };
	if ( @dir ) { mkparentdirs( @dir ); mkdir for @dir }
}

chdir $ARGV[0] or die "Cannot chdir to $ARGV[0]: $!\n";

my %file;

my $meta = CPAN::Meta->load_file( 'META.json' );

my $license = do {
	my @key = ( $meta->license, $meta->meta_spec_version );
	my ( $class, @ambiguous ) = Software::LicenseUtils->guess_license_from_meta_key( @key );
	die if @ambiguous or not $class;
	$class->new( $meta->custom( 'x_copyright' ) );
};

$file{'LICENSE'} = trimnl $license->fulltext;

my ( $main_module ) = map { s!-!/!g; s!^!lib/! if -d 'lib'; -f "$_.pod" ? "$_.pod" : "$_.pm" } $meta->name;

( $file{ $main_module } = slurp $main_module ) =~ s{(^=cut\s*\z)}{ join "\n", (
	"=head1 AUTHOR\n", trimnl( $meta->authors ),
	"=head1 COPYRIGHT AND LICENSE\n", trimnl( $license->notice ),
	"=cut\n",
) }me;

die unless -e 'Makefile.PL';
$file{'README'} = Pod::Readme::Brief->new( $file{ $main_module } )->render( installer => 'eumm', width => 72 );

my @manifest = split /\n/, slurp 'MANIFEST';
my %manifest = map /\A([^\s#]+)()/, @manifest;
$file{'MANIFEST'} = join "\n", @manifest, ( sort grep !exists $manifest{ $_ }, keys %file ), '';

mkparentdirs sort keys %file;
for my $fn ( sort keys %file ) {
	unlink $fn if -e $fn;
	open my $fh, '>', $fn or die "Couldn't open $fn to write: $!\n";
	print $fh $file{ $fn };
	close $fh or die "Couldn't close $fn after writing: $!\n";
}
