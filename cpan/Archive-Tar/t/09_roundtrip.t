BEGIN { chdir 't' if -d 't' }

use Test::More;
use strict;
use lib '../lib';

use File::Spec ();
use File::Temp qw( tempfile );

use Archive::Tar;

# Identify tarballs available for testing
# Some contain only files
# Others contain both files and directories

my @file_only_archives = (
  [qw( src short bar.tar )],
);
push @file_only_archives, [qw( src short foo.tgz )]
  if Archive::Tar->has_zlib_support;
push @file_only_archives, [qw( src short foo.tbz )]
  if Archive::Tar->has_bzip2_support;

@file_only_archives = map File::Spec->catfile(@$_), @file_only_archives;


my @file_and_directory_archives = (
    [qw( src long bar.tar )],
    [qw( src linktest linktest_with_dir.tar )],
);
push @file_and_directory_archives, [qw( src long foo.tgz )]
  if Archive::Tar->has_zlib_support;
push @file_and_directory_archives, [qw( src long foo.tbz )]
  if Archive::Tar->has_bzip2_support;

@file_and_directory_archives = map File::Spec->catfile(@$_), @file_and_directory_archives;

my @archives = (@file_only_archives, @file_and_directory_archives);
plan tests => scalar @archives;

# roundtrip test
for my $archive_name (@file_only_archives) {

      # create a new tarball with the same content as the old one
      my $old = Archive::Tar->new($archive_name);
      my $new = Archive::Tar->new();
      $new->add_files( $old->get_files );

      # save differently if compressed
      my $ext = ( split /\./, $archive_name )[-1];
      my @compress =
          $ext =~ /t?gz$/       ? (COMPRESS_GZIP)
        : $ext =~ /(tbz|bz2?)$/ ? (COMPRESS_BZIP)
        : ();

      my ( $fh, $filename ) = tempfile( UNLINK => 1 );
      $new->write( $filename, @compress );

      # read the archive again from disk
      $new = Archive::Tar->new($filename);

      # compare list of files
      is_deeply(
          [ $new->list_files ],
          [ $old->list_files ],
          "$archive_name roundtrip on file names"
      );
}

# rt.cpan.org #115160
# t/09_roundtrip.t was added with all 7 then existent tests marked TODO even
# though 3 of them were passing.  So what was really TODO was to figure out
# why the other 4 were not passing.
#
# It turns out that the tests are expecting behavior which, though on the face
# of it plausible and desirable, is not Archive::Tar::write()'s current
# behavior.  write() -- which is used in the unit tests in this file -- relies
# on Archive::Tar::File::_prefix_and_file().  Since at least 2006 this helper
# method has had the effect of removing a trailing slash from archive entries
# which are in fact directories.  So we have to adjust our expectations for
# what we'll get when round-tripping on an archive which contains one or more
# entries for directories.

for my $archive_name (@file_and_directory_archives) {
    my @contents;
    if ($archive_name =~ m/\.tar$/) {
        @contents = qx{tar tvf $archive_name};
    }
    elsif ($archive_name =~ m/\.tgz$/) {
        @contents = qx{tar tzvf $archive_name};
    }
    elsif ($archive_name =~ m/\.tbz$/) {
        @contents = qx{tar tjvf $archive_name};
    }
    chomp(@contents);
    my @directory_or_not;
    for my $entry (@contents) {
        my $perms = (split(/\s+/ => $entry))[0];
        my @chars = split('' => $perms);
        push @directory_or_not,
            ($chars[0] eq 'd' ? 1 : 0);
    }

    # create a new tarball with the same content as the old one
    my $old = Archive::Tar->new($archive_name);
    my $new = Archive::Tar->new();
    $new->add_files( $old->get_files );

    # save differently if compressed
    my $ext = ( split /\./, $archive_name )[-1];
    my @compress =
        $ext =~ /t?gz$/       ? (COMPRESS_GZIP)
      : $ext =~ /(tbz|bz2?)$/ ? (COMPRESS_BZIP)
      : ();

    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    $new->write( $filename, @compress );

    # read the archive again from disk
    $new = Archive::Tar->new($filename);

    # Adjust our expectations of
    my @oldfiles = $old->list_files;
    for (my $i = 0; $i <= $#oldfiles; $i++) {
        chop $oldfiles[$i] if $directory_or_not[$i];
    }

    # compare list of files
    is_deeply(
        [ $new->list_files ],
        [ @oldfiles ],
        "$archive_name roundtrip on file names"
    );
}
