use strict;
use warnings;
use lib qq'Porting';
use Maintainers qw(%Modules files_to_modules);
use Archive::Extract;
use File::Fetch;
use HTTP::Tiny;
use JSON::PP;
use File::Spec;
use File::Temp ();
use File::Copy ();
use File::Path ();
use IPC::Cmd qw[can_run run];

require "Maintainers.pl";

die "No 'git', no joy\n" unless can_run('git');

my $metacpan= 'http://api.metacpan.org/release/';
my $module = shift || die "No module to update provided\n";

die "That module is not listed in Porting/Maintainers.pl\n" unless
  exists $Modules{ $module };

my $mod = $Modules{ $module };

my %ignorable = map { ( $_ => 1 ) } @Maintainers::IGNORABLE;

# find and check for new distribution
my ($dist) = distname_info( $mod->{DISTRIBUTION} );
my $cpan = get_metadata( $dist );
die "Something went wrong\n" unless $cpan;
if ( $cpan->{download_url} =~ m!\Q$mod->{DISTRIBUTION}\E$! ) {
  warn "'$module' is already up to date\n";
  #exit 0;
}
# okay, lets fetch and extract
if ( -d $mod->{FILES} ) {
  warn "okay FILES is a dir\n";
  {
    my $cache_dir = File::Temp::tempdir( CLEANUP => 1 );
    my $ff = File::Fetch->new( uri => $cpan->{download_url} );
    my $where = $ff->fetch( to => $cache_dir ) or die $ff->error;
    my $ae = Archive::Extract->new(archive => $where);
    my $sub = ( split m!/!, $mod->{FILES} )[0];
    $ae->extract( to => $sub ) or die $ae->error;
    File::Path::remove_tree( $mod->{FILES} );
    File::Copy::move( $ae->extract_path, $mod->{FILES} ) or die "$!\n";
    restore_gitignore();
    fix_exefiles();
    my @new = find_new_files();
    {
      # Filter out EXCLUDED
      my @filtered = @new;
      my $prefix = $mod->{FILES} . '/';
      s!\Q$prefix\E!! for @filtered;
      @filtered = Maintainers::filter_excluded( $module, @filtered );
      @new = map { $prefix . $_ } @filtered;
    }
    system(qw(git add), $_) for @new;
    my @del = find_del_files();
    {
      my $deleted = join '|', map { quotemeta } @del;
      open my $IN, '<', 'MANIFEST' or die "$!\n";
      my @manifest = grep { ! m!^($deleted)\s! } <$IN>;
      close($IN) or die "$!\n";
      chomp(@manifest);
      my @sorted = sort {
         (my $aa = $a) =~ s/[^\s\da-zA-Z]//g;
         (my $bb = $b) =~ s/[^\s\da-zA-Z]//g;
         uc($aa) cmp uc($bb)
      } @manifest, @new;
      open(my $OUT, '>', 'MANIFEST')
        or die("Can't open output file 'MANIFEST': $!");
      print($OUT join("\n", @sorted), "\n");
      close($OUT) or die($!);
    }
    {
      ( my $newdist = $cpan->{download_url} ) =~ s!\Qhttp://cpan.metacpan.org/authors/id/\E\w/\w{2}/!!;
      system($^X,'-pi','-e','s!\Q' . $mod->{DISTRIBUTION} . '\E!' . $newdist . '!', 'Porting/Maintainers.pl' );
    }
    {
      warn "Running 'git clean -dxf' pay attention to what is removed\n";
      system(qw(git clean -dxf));
    }
  }
warn <<'EOF';
Done as much as I can do.

Check "git status" and "git diff" to see changes.

Adjust to taste (remembering to update pod/perldelta.pod)
and then "git commit -a" when ready to commit.

Good luck!
EOF
}
exit 0;

# borrowed from CPAN::DistnameInfo
sub distname_info {
  my $distfile = shift or return;
  $distfile =~ s,//+,/,g;
  my ($distvname) = $distfile =~ m,([^/]+)\.(tar\.(?:g?z|bz2)|zip|tgz)$,i;
  my ($dist, $version) = $distvname =~ /^
    ((?:[-+.]*(?:[A-Za-z0-9]+|(?<=\D)_|_(?=\D))*
     (?:
  [A-Za-z](?=[^A-Za-z]|$)
  |
  \d(?=-)
     )(?<![._-][vV])
    )+)(.*)
  $/xs or return ($distfile,undef,undef);

  if ($dist =~ /-undef\z/ and ! length $version) {
    $dist =~ s/-undef\z//;
  }

  # Remove potential -withoutworldwriteables suffix
  $version =~ s/-withoutworldwriteables$//;

  if ($version =~ /^(-[Vv].*)-(\d.*)/) {

    # Catch names like Unicode-Collate-Standard-V3_1_1-0.1
    # where the V3_1_1 is part of the distname
    $dist .= $1;
    $version = $2;
  }

  if ($version =~ /(.+_.*)-(\d.*)/) {
      # Catch names like Task-Deprecations5_14-1.00.tar.gz where the 5_14 is
      # part of the distname. However, names like libao-perl_0.03-1.tar.gz
      # should still have 0.03-1 as their version.
      $dist .= $1;
      $version = $2;
  }

  # Normalize the Dist.pm-1.23 convention which CGI.pm and
  # a few others use.
  $dist =~ s{\.pm$}{};

  $version = $1
    if !length $version and $dist =~ s/-(\d+\w)$//;

  $version = $1 . $version
    if $version =~ /^\d+$/ and $dist =~ s/-(\w+)$//;

  if ($version =~ /\d\.\d/) {
    $version =~ s/^[-_.]+//;
  }
  else {
    $version =~ s/^[-_]+//;
  }

  my $dev;
  if (length $version) {
    if ($distfile =~ /^perl-?\d+\.(\d+)(?:\D(\d+))?(-(?:TRIAL|RC)\d+)?$/) {
      $dev = 1 if (($1 > 6 and $1 & 1) or ($2 and $2 >= 50)) or $3;
    }
    elsif ($version =~ /\d\D\d+_\d/ or $version =~ /-TRIAL/) {
      $dev = 1;
    }
  }
  else {
    $version = undef;
  }

  ($dist, $version, $dev);
}

sub get_metadata {
  my $dist = shift;
  my $resp = HTTP::Tiny->new( )->get( $metacpan . $dist );
  unless ( $resp->{success} ) {
    warn "'$dist' doesn't exist\n";
    return;
  }
  my $json = $resp->{content} || die "No content from metacpan\n";
  return eval { decode_json $json };
}

sub restore_gitignore {
  system('git', 'checkout', '--', $_) for
    map { $_->[1] }
    grep { $_->[0] =~ /D/i }
    grep { $_->[1] =~ /\.gitignore$/ }
    map { chomp; [ split ' ' ] }
     `git status -s`;
}

sub fix_exefiles {
  my %exe_list =
    map   { $_ => 1 }
    map   { my ($f) = split; glob("../$f") }
    grep  { $_ !~ /\A#/ && $_ !~ /\A\s*\z/ }
    map   { split "\n" }
    do    { local (@ARGV, $/) = 'Porting/exec-bit.txt'; <> };

  chmod( 0644, $_) for
    map { $_->[1] }
    grep { $_->[0] =~ /M/i }
    grep { ! $exe_list{ $_->[1] } }
    map { chomp; [ split ' ' ] }
      `git status -s`;
}

sub find_new_files {
  my $ignore = join '|', map { quotemeta } keys %ignorable;
  my @poss =
    map { $_->[1] }
    grep { $_->[1] !~ m!($ignore)$! }
    grep { $_->[0] =~ /\?{2}/ }
    map { chomp; [ split ' ' ] }
      `git status -s`;
  return @poss;
}

sub find_del_files {
  my @poss =
    map { $_->[1] }
    grep { $_->[0] =~ /D/i }
    map { chomp; [ split ' ' ] }
      `git status -s`;
  return @poss;
}

