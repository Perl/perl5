package File::Mkpath;

=head1 NAME

File::Mkpath - create or remove a series of directories

=head1 SYNOPSIS

C<use File::Mkpath>

C<mkpath(['/foo/bar/baz', 'blurfl/quux'], 1, 0711);>

C<rmtree(['foo/bar/baz', 'blurfl/quux'], 1, 1);>

=head1 DESCRIPTION

The C<mkpath> function provides a convenient way to create directories, even if
your C<mkdir> kernel call won't create more than one level of directory at a
time.  C<mkpath> takes three arguments:

=over 4

=item *

the name of the path to create, or a reference
to a list of paths to create,

=item *

a boolean value, which if TRUE will cause C<mkpath>
to print the name of each directory as it is created
(defaults to FALSE), and

=item *

the numeric mode to use when creating the directories
(defaults to 0777)

=back

It returns a list of all directories (including intermediates, determined using
the Unix '/' separator) created.

Similarly, the C<rmtree> function provides a convenient way to delete a
subtree from the directory structure, much like the Unix command C<rm -r>.
C<rmtree> takes three arguments:

=over 4

=item *

the root of the subtree to delete, or a reference to
a list of roots.  All of the files and directories
below each root, as well as the roots themselves,
will be deleted.  For the moment, C<rmtree> expects
Unix file specification syntax.

=item *

a boolean value, which if TRUE will cause C<rmtree> to
print a message each time it tries to delete a file,
giving the name of the file, and indicating whether
it's using C<rmdir> or C<unlink> to remove it.
(defaults to FALSE)

=item *

a boolean value, which if TRUE will cause C<rmtree> to
skip any files to which you do not have write access.
This will change in the future when a criterion for
'delete permission' is settled. (defaults to FALSE)

=back

It returns the number of files successfully deleted.

=head1 AUTHORS

Tim Bunce <Tim.Bunce@ig.co.uk>
Charles Bailey <bailey@genetics.upenn.edu>

=head1 REVISION

This document was last revised 29-Jan-1995, for perl 5.001

=cut

require 5.000;
use Config;
use Carp;
require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( mkpath rmtree );

sub mkpath{
    my($paths, $verbose, $mode) = @_;
    # $paths   -- either a path string or ref to list of paths
    # $verbose -- optional print "mkdir $path" for each directory created
    # $mode    -- optional permissions, defaults to 0777
    local($")="/";
    $mode = 0777 unless defined($mode);
    $paths = [$paths] unless ref $paths;
    my(@created);
    foreach $path (@$paths){
	next if -d $path;
        my(@p);
        foreach(split(/\//, $path)){
            push(@p, $_);
            next if -d "@p/";
            print "mkdir @p\n" if $verbose;
	    mkdir("@p",$mode) || croak "mkdir @p: $!";
            push(@created, "@p");
        }
    }
    @created;
}

sub rmtree {
    my($roots, $verbose, $safe) = @_;
    my(@files,$count);
    $roots = [$roots] unless ref $roots;

    foreach $root (@{$roots}) {
       $root =~ s#/$##;
       if (-d $root) { 
           opendir(D,$root);
           @files = map("$root/$_", grep $_!~/^\.{1,2}$/, readdir(D));
           closedir(D);
           $count += rmtree(\@files,$verbose,$safe);
           next if ($safe && !(-w $root));
           print "rmdir $root\n" if $verbose;
           (rmdir $root && ++$count) or carp "Can't remove directory $root: $!";
        }
        else { 
           next if ($safe && !(-w $root));
           print "unlink $root\n" if $verbose;
           (unlink($root) && ++$count) or carp "Can't unlink file $root: $!";
        }
    }

    $count;
}

1;

__END__
