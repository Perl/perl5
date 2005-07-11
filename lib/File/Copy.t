#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More;

my $TB = Test::More->builder;

plan tests => 46;

use File::Copy;
use Config;

for (1..2) {

  # First we create a file
  open(F, ">file-$$") or die;
  binmode F; # for DOSISH platforms, because test 3 copies to stdout
  printf F "ok\n";
  close F;

  copy "file-$$", "copy-$$";

  open(F, "copy-$$") or die;
  $foo = <F>;
  close(F);

  is -s "file-$$", -s "copy-$$";

  is $foo, "ok\n";

  binmode STDOUT unless $^O eq 'VMS'; # Copy::copy works in binary mode
  # This outputs "ok" so its a test.
  copy "copy-$$", \*STDOUT;
  $TB->current_test($TB->current_test + 1);
  unlink "copy-$$" or die "unlink: $!";

  open(F,"file-$$");
  copy(*F, "copy-$$");
  open(R, "copy-$$") or die "open copy-$$: $!"; $foo = <R>; close(R);
  is $foo, "ok\n";
  unlink "copy-$$" or die "unlink: $!";

  open(F,"file-$$");
  copy(\*F, "copy-$$");
  close(F) or die "close: $!";
  open(R, "copy-$$") or die; $foo = <R>; close(R) or die "close: $!";
  is $foo, "ok\n";
  unlink "copy-$$" or die "unlink: $!";

  require IO::File;
  $fh = IO::File->new(">copy-$$") or die "Cannot open copy-$$:$!";
  binmode $fh or die;
  copy("file-$$",$fh);
  $fh->close or die "close: $!";
  open(R, "copy-$$") or die; $foo = <R>; close(R);
  is $foo, "ok\n";
  unlink "copy-$$" or die "unlink: $!";

  require FileHandle;
  my $fh = FileHandle->new(">copy-$$") or die "Cannot open copy-$$:$!";
  binmode $fh or die;
  copy("file-$$",$fh);
  $fh->close;
  open(R, "copy-$$") or die; $foo = <R>; close(R);
  is $foo, "ok\n";
  unlink "file-$$" or die "unlink: $!";

  ok !move("file-$$", "copy-$$"), "move on missing file";
  ok -e "copy-$$",                '  target still there';

  ok move "copy-$$", "file-$$", 'move';
  ok -e "file-$$",              '  destination exists';
  ok !-e "copy-$$",              '  source does not';
  open(R, "file-$$") or die; $foo = <R>; close(R);
  is $foo, "ok\n";

  copy "file-$$", "lib";
  open(R, "lib/file-$$") or die; $foo = <R>; close(R);
  is $foo, "ok\n";
  unlink "lib/file-$$" or die "unlink: $!";

  # Do it twice to ensure copying over the same file works.
  copy "file-$$", "lib";
  open(R, "lib/file-$$") or die; $foo = <R>; close(R);
  is $foo, "ok\n";
  unlink "lib/file-$$" or die "unlink: $!";

  eval { copy("file-$$", "file-$$") };
  like $@, qr/are identical/;
  ok -s "file-$$";

  move "file-$$", "lib";
  open(R, "lib/file-$$") or die "open lib/file-$$: $!"; $foo = <R>; close(R);
  is $foo, "ok\n";
  ok !-e "file-$$";
  unlink "lib/file-$$" or die "unlink: $!";

  SKIP: {
    skip "Testing symlinks", 2 unless $Config{d_symlink};

    open(F, ">file-$$") or die $!;
    print F "dummy content\n";
    close F;
    symlink("file-$$", "symlink-$$") or die $!;
    eval { copy("file-$$", "symlink-$$") };
    like $@, qr/are identical/;
    ok !-z "file-$$", 
      'rt.perl.org 5196: copying to itself would truncate the file';

    unlink "symlink-$$";
    unlink "file-$$";
  }

  SKIP: {
    skip "Testing hard links", 2 if !$Config{d_link} or $^O eq 'MSWin32';

    open(F, ">file-$$") or die $!;
    print F "dummy content\n";
    close F;
    link("file-$$", "hardlink-$$") or die $!;
    eval { copy("file-$$", "hardlink-$$") };
    like $@, qr/are identical/;
    ok ! -z "file-$$",
      'rt.perl.org 5196: copying to itself would truncate the file';

    unlink "hardlink-$$";
    unlink "file-$$";
  }

}


END {
    1 while unlink "file-$$";
    1 while unlink "lib/file-$$";
}
