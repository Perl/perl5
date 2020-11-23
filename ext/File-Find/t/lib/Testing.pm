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
    dir_path
    file_path
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
        or die("Unable to mkdir $!: $dir");
}

sub symlink_ok($$;$) {
    my ($oldfile, $newfile) = @_[0..1];
    my $msg = $_[2] || "able to symlink from $oldfile to $newfile";
    ok( symlink( $oldfile, $newfile ), $msg)
      or die("Unable to symlink from $oldfile to $newfile");
}

# Use dir_path() to specify a directory path that is expected for
# $File::Find::dir (%Expect_Dir). Also use it in file operations like
# chdir, rmdir etc.
#
# dir_path() concatenates directory names to form a *relative*
# directory path, independent from the platform it is run on, although
# there are limitations. Do not try to create an absolute path,
# because that may fail on operating systems that have the concept of
# volume names (e.g. Mac OS). As a special case, you can pass it a "."
# as first argument, to create a directory path like "./fa/dir". If there is
# no second argument, this function will return "./"

sub dir_path {
    my $first_arg = shift @_;

    if ($first_arg eq '.') {
	    return './' unless @_;
	    my $path = File::Spec->catdir(@_);
	    # add leading "./"
	    $path = "./$path";
	    return $path;
    }
    else { # $first_arg ne '.'
        return $first_arg unless @_; # return plain filename
	    my $fname = File::Spec->catdir($first_arg, @_); # relative path
	    $fname = VMS::Filespec::unixpath($fname) if $^O eq 'VMS';
        return $fname;
    }
}

# Use file_path() to specify a file path that is expected for $_
# (%Expect_File). Also suitable for file operations like unlink etc.
#
# file_path() concatenates directory names (if any) and a filename to
# form a *relative* file path (the last argument is assumed to be a
# file). It is independent from the platform it is run on, although
# there are limitations. As a special case, you can pass it a "." as
# first argument, to create a file path like "./fa/file" on operating
# systems. If there is no second argument, this function will return the
# string "./"

sub file_path {
    my $first_arg = shift @_;

    if ($first_arg eq '.') {
	    return './' unless @_;
	    my $path = File::Spec->catfile(@_);
	    # add leading "./"
	    $path = "./$path";
	    return $path;
    }
    else { # $first_arg ne '.'
        return $first_arg unless @_; # return plain filename
	    my $fname = File::Spec->catfile($first_arg, @_); # relative path
	    $fname = VMS::Filespec::unixify($fname) if $^O eq 'VMS';
        return $fname;
    }
}

1;
