use strict;
use Test::More;
use Config;
use lib 't/';
use FilePathTest;
use File::Path qw(rmtree mkpath make_path remove_tree);
use File::Spec::Functions;


my $prereq = prereq();
plan skip_all  => $prereq if defined $prereq;
plan tests     => 8;

my $pwent = max_u();
my $grent = max_g();
my ( $max_uid, $max_user ) = @{ $pwent };
my ( $max_gid, $max_group ) = @{ $grent };

my $tmp_base = catdir(
    curdir(),
    sprintf( 'test-%x-%x-%x', time, $$, rand(99999) ),
);

# invent some names
my @dir = (
    catdir($tmp_base, qw(a b)),
    catdir($tmp_base, qw(a c)),
    catdir($tmp_base, qw(z b)),
    catdir($tmp_base, qw(z c)),
);

# create them
my @created = mkpath([@dir]);

my $dir;
my $dir2;

my $dir_stem = $dir = catdir($tmp_base, 'owned-by');

$dir = catdir($dir_stem, 'aaa');
@created = make_path($dir, {owner => $max_user});
is(scalar(@created), 2, "created a directory owned by $max_user...");

my $dir_uid = (stat $created[0])[4];
is($dir_uid, $max_uid, "... owned by $max_uid");

$dir = catdir($dir_stem, 'aab');
@created = make_path($dir, {group => $max_group});
is(scalar(@created), 1, "created a directory owned by group $max_group...");

my $dir_gid = (stat $created[0])[5];
is($dir_gid, $max_gid, "... owned by group $max_gid");

$dir = catdir($dir_stem, 'aac');
@created = make_path( $dir, { user => $max_user,
                              group => $max_group});
is(scalar(@created), 1, "created a directory owned by $max_user:$max_group...");

($dir_uid, $dir_gid) = (stat $created[0])[4,5];
is($dir_uid, $max_uid, "... owned by $max_uid");
is($dir_gid, $max_gid, "... owned by group $max_gid");

SKIP: {
  skip('Skip until RT 85878 is fixed', 1);
  # invent a user and group that don't exist
  do { ++$max_user  } while ( getpwnam( $max_user ) );
  do { ++$max_group } while ( getgrnam( $max_group ) );

  $dir = catdir($dir_stem, 'aad');
  my $rv = _run_for_warning( sub { make_path( $dir,
                                              { user => $max_user,
                                                group => $max_group } ) } );
  like( $rv,
        qr{\Aunable to map $max_user to a uid, ownership not changed: .* at \S+ line \d+
unable to map $max_group to a gid, group ownership not changed: .* at \S+ line \d+\b},
        "created a directory not owned by $max_user:$max_group..."
      );
}

sub max_u {
  # find the highest uid ('nobody' or similar)
  my $max_uid   = 0;
  my $max_user = undef;
  while (my @u = getpwent()) {
    if ($max_uid < $u[2]) {
      $max_uid  = $u[2];
      $max_user = $u[0];
    }
  }
  setpwent(); # in case we want to run again later
  return [ $max_uid, $max_user ];
}

sub max_g {
  # find the highest gid ('nogroup' or similar)
  my $max_gid   = 0;
  my $max_group = undef;
  while ( my @g = getgrent() ) {
    print Dumper @g;
    if ($max_gid < $g[2]) {
      $max_gid = $g[2];
      $max_group = $g[0];
    }
  }
  setgrent(); # in case we want to run again later
  return [ $max_gid, $max_group ];
}

sub prereq {
  return "getpwent() not implemented on $^O" unless $Config{d_getpwent};
  return "getgrent() not implemented on $^O" unless $Config{d_getgrent};
  return "not running as root" unless $< == 0;
  return "darwin's nobody and nogroup are -1 or -2" if $^O eq 'darwin';

  my $pwent = max_u();
  my $grent = max_g();
  my ( $max_uid, $max_user ) = @{ $pwent };
  my ( $max_gid, $max_group ) = @{ $grent };

  return "getpwent() appears to be insane" unless $max_uid > 0;
  return "getgrent() appears to be insane" unless $max_gid > 0;
  return undef;
}
