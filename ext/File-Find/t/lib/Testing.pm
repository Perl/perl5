package Testing;
use 5.006_001;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    create_file_ok
    mkdir_ok
    symlink_ok
);

# Wrappers around Test::More::ok() for creation of files, directories and
# symlinks used in testing of File-Find

*ok = \&Test::More::ok;

sub create_file_ok($;$) {
    my $file = $_[0];
    my $msg = $_[2] || "able to create file: $file";
    ok( open(my $T,'>',$file), $msg )
        or die("Unable to create file: $file");
}

sub mkdir_ok($$;$) {
    my ($dir, $mask) = @_[0..1];
    my $msg = $_[2] || "able to mkdir: $dir";
    ok( mkdir($dir, $mask), $msg )
        or die("Unable to mkdir: $dir");
}

sub symlink_ok($$;$) {
    my ($oldfile, $newfile) = @_[0..1];
    my $msg = $_[2] || "able to symlink from $oldfile to $newfile";
    ok( symlink( $oldfile, $newfile ), $msg)
      or die("Unable to symlink from $oldfile to $newfile");
}

1;
