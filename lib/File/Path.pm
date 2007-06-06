package File::Path;

=head1 NAME

File::Path - Create or remove directory trees

=head1 VERSION

This document describes version 2.00_01 of File::Path, released
2007-xx-xx.

=head1 SYNOPSIS

    use File::Path;

    # modern
    mkpath( 'foo/bar/baz', '/zug/zwang', {verbose => 1} );

    rmtree(
        'foo/bar/baz', '/zug/zwang',
        { verbose => 1, error  => \my $err_list }
    );

    # traditional
    mkpath(['/foo/bar/baz', 'blurfl/quux'], 1, 0711);
    rmtree(['foo/bar/baz', 'blurfl/quux'], 1, 1);

=head1 DESCRIPTION

The C<mkpath> function provides a convenient way to create directories,
even if your C<mkdir> kernel call won't create more than one level
of directory at a time. Similarly, the C<rmtree> function provides
a convenient way to delete a subtree from the directory structure,
much like the Unix command C<rm -r>.

Both functions may be called in one of two ways, the traditional,
compatible with code written since the dawn of time, and modern,
that offers a more flexible and readable idiom. New code should use
the modern interface.

=head2 FUNCTIONS

The modern way of calling C<mkpath> and C<rmtree> is with an optional
hash reference at the end of the parameter list that holds various
keys that can be used to control the function's behaviour, following
a plain list of directories upon which to operate.

=head3 C<mkpath>

The following keys are recognised as as parameters to C<mkpath>.
It returns the list of files actually created during the call.

  my @created = mkpath(
    qw(/tmp /flub /home/nobody),
    {verbose => 1, mode => 0750},
  );
  print "created $_\n" for @created;

=over 4

=item mode

The numeric mode to use when creating the directories (defaults
to 07777), to be modified by the current C<umask>. (C<mask> is
recognised as an alias for this parameter).

=item verbose

If present, will cause C<mkpath> to print the name of each directory
as it is created. By default nothing is printed.

=item error

If present, will be interpreted as a reference to a list, and will
be used to store any errors that are encountered.  See the ERROR
HANDLING section below to find out more.

If this parameter is not used, any errors encountered will raise a
fatal error that need to be trapped in an C<eval> block, or the
program will halt.

=back

=head3 C<rmtree>

=over 4

=item verbose

If present, will cause C<rmtree> to print the name of each file as
it is unlinked. By default nothing is printed.

=item skip_others

When set to a true value, will cause C<rmtree> to skip any files
to which you do not have delete access (if running under VMS) or
write access (if running under another OS). This will change in
the future when a criterion for 'delete permission' under OSs other
than VMS is settled.

=item keep_root

When set to a true value, will cause everything except the specified
base directories to be unlinked. This comes in handy when cleaning
out an application's scratch directory.

  rmtree( '/tmp', {keep_root => 1} );

=item result

If present, will be interpreted as a reference to a list, and will
be used to store the list of all files and directories unlinked
during the call. If nothing is unlinked, a reference to an empty
list is returned (rather than C<undef>).

  rmtree( '/tmp', {result => \my $list} );
  print "unlinked $_\n" for @$list;

=item error

If present, will be interpreted as a reference to a list,
and will be used to store any errors that are encountered.
See the ERROR HANDLING section below to find out more.

If this parameter is not used, any errors encountered will
raise a fatal error that need to be trapped in an C<eval>
block, or the program will halt.

=back

=head2 TRADITIONAL INTERFACE

The old interface for C<mkpath> and C<rmtree> take a
reference to a list of directories (to create or remove),
followed by a series of positional numeric modal parameters that
control their behaviour.

This design made it difficult to add
additional functionality, as well as posed the problem
of what to do when you don't care how the initial
positional parameters are specified but only the last
one needs to be specified. The calls themselves are also
less self-documenting.

C<mkpath> takes three arguments:

=over 4

=item *

The name of the path to create, or a reference
to a list of paths to create,

=item *

a boolean value, which if TRUE will cause C<mkpath>
to print the name of each directory as it is created
(defaults to FALSE), and

=item *

the numeric mode to use when creating the directories
(defaults to 0777), to be modified by the current umask.

=back

It returns a list of all directories (including intermediates, determined
using the Unix '/' separator) created.  In scalar context it returns
the number of directories created.

If a system error prevents a directory from being created, then the
C<mkpath> function throws a fatal error with C<Carp::croak>. This error
can be trapped with an C<eval> block:

  eval { mkpath($dir) };
  if ($@) {
    print "Couldn't create $dir: $@";
  }

In the traditional form, C<rmtree> takes three arguments:

=over 4

=item *

the root of the subtree to delete, or a reference to
a list of roots.  All of the files and directories
below each root, as well as the roots themselves,
will be deleted.

=item *

a boolean value, which if TRUE will cause C<rmtree> to
print a message each time it examines a file, giving the
name of the file, and indicating whether it's using C<rmdir>
or C<unlink> to remove it, or that it's skipping it.
(defaults to FALSE)

=item *

a boolean value, which if TRUE will cause C<rmtree> to
skip any files to which you do not have delete access
(if running under VMS) or write access (if running
under another OS).  This will change in the future when
a criterion for 'delete permission' under OSs other
than VMS is settled.  (defaults to FALSE)

=back

It returns the number of files, directories and symlinks successfully
deleted.  Symlinks are simply deleted and not followed.

Note also that the occurrence of errors in C<rmtree> using the
traditional interface can be determined I<only> by trapping diagnostic
messages using C<$SIG{__WARN__}>; it is not apparent from the return
value. (The modern interface may use the C<error> parameter to
record any problems encountered.

=head2 ERROR HANDLING

If C<mkpath> or C<rmtree> encounter an error, a diagnostic message
will be printed to C<STDERR> via C<carp> (for non-fatal errors),
or via C<croak> (for fatal errors).

If this behaviour is not desirable, the C<error> attribute may be
used to hold a reference to a variable, which will be used to store
the diagnostics. The result is a reference to a list of hash
references. For each hash reference, the key is the name of the
file, and the value is the error message (usually the contents of
C<$!>). An example usage looks like:

  rmpath( 'foo/bar', 'bar/rat', {error => \my $err} );
  for my $diag (@$err) {
    my ($file, $message) = each %$diag;
    print "problem unlinking $file: $message\n";
  }

If no errors are encountered, C<$err> will point to an empty list
(thus there is no need to test for C<undef>). If a general error
is encountered (for instance, C<rmtree> attempts to remove a directory
tree that does not exist), the diagnostic key will be empty, only
the value will be set:

  rmpath( '/no/such/path', {error => \my $err} );
  for my $diag (@$err) {
    my ($file, $message) = each %$diag;
    if ($file eq '') {
      print "general error: $message\n";
    }
  }

=head2 NOTES

=head3 HEURISTICS

The functions detect (as far as possible) which way they are being
called and will act appropriately. It is important to remember that
the heuristic for detecting the old style is either the presence
of an array reference, or two or three parameters total and second
and third parameters are numeric. Hence...

    mkpath '486', '487', '488';

... will not assume the modern style and create three directories, rather
it will create one directory verbosely, setting the permission to
0750 (488 being the decimal equivalent of octal 750). Here, old
style trumps new. It must, for backwards compatibility reasons.

If you want to ensure there is absolutely no ambiguity about which
way the function will behave, make sure the first parameter is a
reference to a one-element list, to force the old style interpretation:

    mkpath ['486'], '487', '488';

and get only one directory created. Or add a reference to an empty
parameter hash, to force the new style:

    mkpath '486', '487', '488', {};

... and hence create the three directories. If the empty hash
reference seems a little strange to your eyes, or you suspect a
subsequent programmer might I<helpfully> optimise it away, you
can add a parameter set to a default value:

    mkpath '486', '487', '488', {verbose => 0};

=head3 RACE CONDITIONS

There are race conditions internal to the implementation of C<rmtree>
making it unsafe to use on directory trees which may be altered or
moved while C<rmtree> is running, and in particular on any directory
trees with any path components or subdirectories potentially writable
by untrusted users.

Additionally, if the C<skip_others> parameter is not set (or the
third parameter in the traditional inferface is not TRUE) and
C<rmtree> is interrupted, it may leave files and directories with
permissions altered to allow deletion.

C<File::Path> blindly exports C<mkpath> and C<rmtree> into the
current namespace. These days, this is considered bad style, but
to change it now would break too much code. Nonetheless, you are
invited to specify what it is you are expecting to use:

  use File::Path 'rmtree';

=head1 DIAGNOSTICS

=over 4

=item *

On Windows, if C<mkpath> gives you the warning: B<No such file or
directory>, this may mean that you've exceeded your filesystem's
maximum path length.

=back

=head1 SEE ALSO

=over 4

=item *

L<Find::File::Rule>

When removing directory trees, if you want to examine each file
before deciding whether to deleting it (and possibly leaving large
swathes alone), F<File::Find::Rule> offers a convenient and flexible
approach.

=back

=head1 BUGS

Please report all bugs on the RT queue:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Path>

=head1 AUTHORS

Tim Bunce <F<Tim.Bunce@ig.co.uk>> and
Charles Bailey <F<bailey@newman.upenn.edu>>.

Currently maintained by David Landgren <F<david@landgren.net>>.

=head1 COPYRIGHT

This module is copyright (C) Charles Bailey, Tim Bunce and
David Landgren 1995-2007.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use 5.005_04;
use strict;

use File::Basename ();
use File::Spec     ();
BEGIN {
    if ($] < 5.006) {
        # can't say 'opendir my $dh, $dirname'
        # need to initialise $dh
        eval "use Symbol";
    }
}

use Exporter ();
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '2.00_01';
@ISA     = qw(Exporter);
@EXPORT  = qw(mkpath rmtree);

my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

# These OSes complain if you want to remove a file that you have no
# write permission to:
my $Force_Writeable = ($^O eq 'os2' || $^O eq 'dos' || $^O eq 'MSWin32' ||
		       $^O eq 'amigaos' || $^O eq 'MacOS' || $^O eq 'epoc');

sub _carp {
    require Carp;
    goto &Carp::carp;
}

sub _croak {
    require Carp;
    goto &Carp::croak;
}

sub mkpath {
    my $new_style = (
        ref($_[0]) eq 'ARRAY'
        or (@_ == 2 and $_[1] =~ /\A\d+\z/)
        or (@_ == 3 and $_[1] =~ /\A\d+\z/ and $_[2] =~ /\A\d+\z/)
    ) ? 0 : 1;

    my $arg;
    my $paths;

    if ($new_style) {
        if (ref $_[-1] eq 'HASH') {
            $arg = pop @_;
            exists $arg->{mask} and $arg->{mode} = delete $arg->{mask};
            $arg->{mode} = 0777 unless exists $arg->{mode};
            ${$arg->{error}} = [] if exists $arg->{error};
        }
        else {
            @{$arg}{qw(verbose mode)} = (0, 0777);
        }
        $paths = [@_];
    }
    else {
        my ($verbose, $mode);
        ($paths, $verbose, $mode) = @_;
        $paths = [$paths] unless ref($paths) eq 'ARRAY';
        $arg->{verbose} = defined $verbose ? $verbose : 0;
        $arg->{mode}    = defined $mode    ? $mode    : 0777;
    }
    return _mkpath($arg, $paths);
}

sub _mkpath {
    my $arg   = shift;
    my $paths = shift;

    local($")=$Is_MacOS ? ":" : "/";
    my(@created,$path);
    foreach $path (@$paths) {
        next unless length($path);
	$path .= '/' if $^O eq 'os2' and $path =~ /^\w:\z/s; # feature of CRT 
	# Logic wants Unix paths, so go with the flow.
	if ($Is_VMS) {
	    next if $path eq '/';
	    $path = VMS::Filespec::unixify($path);
	}
	next if -d $path;
	my $parent = File::Basename::dirname($path);
	unless (-d $parent or $path eq $parent) {
            push(@created,_mkpath($arg, [$parent]));
        }
        print "mkdir $path\n" if $arg->{verbose};
        if (mkdir($path,$arg->{mode})) {
            push(@created, $path);
	}
        else {
            my $save_bang = $!;
            my ($e, $e1) = ($save_bang, $^E);
	    $e .= "; $e1" if $e ne $e1;
	    # allow for another process to have created it meanwhile
            if (!-d $path) {
                $! = $save_bang;
                if ($arg->{error}) {
                    push @{${$arg->{error}}}, {$path => $e};
                }
                else {
                    _croak("mkdir $path: $e");
                }
	}
    }
    }
    return @created;
}

sub rmtree {
    my $new_style = (
        ref($_[0]) eq 'ARRAY'
        or (@_ == 2 and $_[1] =~ /\A\d+\z/)
        or (@_ == 3 and $_[1] =~ /\A\d+\z/ and $_[2] =~ /\A\d+\z/)
    ) ? 0 : 1;

    my $arg;
    my $paths;

    if ($new_style) {
        if (ref $_[-1] eq 'HASH') {
            $arg = pop @_;
            ${$arg->{error}}  = [] if exists $arg->{error};
            ${$arg->{result}} = [] if exists $arg->{result};
        }
        else {
            @{$arg}{qw(verbose safe)} = (0, 0);
        }
        $arg->{depth} = 0;
        $paths = [@_];
    }
    else {
        my ($verbose, $safe);
        ($paths, $verbose, $safe) = @_;
        $paths = [$paths] unless ref($paths) eq 'ARRAY';
        $arg->{verbose} = defined $verbose ? $verbose : 0;
        $arg->{safe}    = defined $safe    ? $safe    : 0;
    }

    if (@$paths < 1) {
        if ($arg->{error}) {
            push @{${$arg->{error}}}, {'' => "No root path(s) specified"};
    }
    else {
            $arg->{verbose} and _carp ("No root path(s) specified\n");
        }
      return 0;
    }
    return _rmtree($arg, $paths);
}

sub _rmtree {
    my $arg   = shift;
    my $paths = shift;
    my($count) = 0;
    my (@files, $root);
    foreach $root (@{$paths}) {
    	if ($Is_MacOS) {
	    $root = ":$root" if $root !~ /:/;
            $root =~ s/([^:])\z/$1:/;
        }
        else {
	    $root =~ s#/\z##;
	}
        my $rp = (lstat $root)[2] or next;
	$rp &= 07777;	# don't forget setuid, setgid, sticky bits
	if ( -d _ ) {
	    # notabene: 0700 is for making readable in the first place,
	    # it's also intended to change it to writable in case we have
	    # to recurse in which case we are better than rm -rf for 
	    # subtrees with strange permissions
            if (!chmod($rp | 0700,
                ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
            ) {
                if (!$arg->{safe}) {
                    if ($arg->{error}) {
                          push @{${$arg->{error}}},
                            {$root => "Can't make directory read+writeable: $!"};
                    }
                    else {
                        _carp ("Can't make directory $root read+writeable: $!");
                    }
                }
            }

            my $d;
            $d = gensym() if $] < 5.006;
            if (!opendir $d, $root) {
                if ($arg->{error}) {
                      push @{${$arg->{error}}}, {$root => "opendir: $!"};
                }
                else {
                    _carp ("Can't read $root: $!");
                }
                @files = ();
            }
            else {
		no strict 'refs';
		if (!defined ${"\cTAINT"} or ${"\cTAINT"}) {
                    # Blindly untaint dir names if taint mode is
                    # active, or any perl < 5.006
                    @files = map { /\A(.*)\z/s; $1 } readdir $d;
                }
                else {
		    @files = readdir $d;
		}
		closedir $d;
	    }

	    # Deleting large numbers of files from VMS Files-11 filesystems
	    # is faster if done in reverse ASCIIbetical order 
	    @files = reverse @files if $Is_VMS;
	    ($root = VMS::Filespec::unixify($root)) =~ s#\.dir\z## if $Is_VMS;
	    if ($Is_MacOS) {
		@files = map("$root$_", @files);
	    }
            else {
                my $updir  = File::Spec->updir();
                my $curdir = File::Spec->curdir();
                @files = map(File::Spec->catfile($root,$_),
                    grep {$_ ne $updir and $_ ne $curdir}
                    @files
                );
            }
            $arg->{depth}++;
            $count += _rmtree($arg, \@files);
            $arg->{depth}--;
            if ($arg->{depth} or !$arg->{keep_root}) {
                if ($arg->{safe} &&
		($Is_VMS ? !&VMS::Filespec::candelete($root) : !-w $root)) {
                    print "skipped $root\n" if $arg->{verbose};
		next;
	    }
                if (!chmod $rp | 0700, $root) {
                    if ($Force_Writeable) {
                        if ($arg->{error}) {
                            push @{${$arg->{error}}},
                                {$root => "Can't make directory writeable: $!"};
                        }
                        else {
                            _carp ("Can't make directory $root writeable: $!")
                        }
                    }
                }
                print "rmdir $root\n" if $arg->{verbose};
	    if (rmdir $root) {
                    push @{${$arg->{result}}}, $root if $arg->{result};
		++$count;
	    }
	    else {
                    if ($arg->{error}) {
                        push @{${$arg->{error}}}, {$root => "rmdir: $!"};
                    }
                    else {
                        _carp ("Can't remove directory $root: $!");
	    }
                    if (!chmod($rp,
                        ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
                    ) {
                        my $mask = sprintf("0%o",$rp);
                        if ($arg->{error}) {
                            push @{${$arg->{error}}}, {$root => "restore chmod: $!"};
	}
	else { 
                            _carp("and can't restore permissions to $mask\n");
                        }
                    }
                }
            }
        }
        else {
            if ($arg->{safe} &&
		($Is_VMS ? !&VMS::Filespec::candelete($root)
		         : !(-l $root || -w $root)))
	    {
                print "skipped $root\n" if $arg->{verbose};
		next;
	    }
            if (!chmod $rp | 0600, $root) {
                if ($Force_Writeable) {
                    if ($arg->{error}) {
                        push @{${$arg->{error}}},
                            {$root => "Can't make file writeable: $!"};
                    }
                    else {
                        _carp ("Can't make file $root writeable: $!")
                    }
                }
            }
            print "unlink $root\n" if $arg->{verbose};
	    # delete all versions under VMS
	    for (;;) {
                if (unlink $root) {
                    push @{${$arg->{result}}}, $root if $arg->{result};
                }
                else {
                    if ($arg->{error}) {
                        push @{${$arg->{error}}},
                            {$root => "unlink: $!"};
                    }
                    else {
                        _carp ("Can't unlink file $root: $!");
                    }
                    if ($Force_Writeable) {
                        if (!chmod $rp, $root) {
                            my $mask = sprintf("0%o",$rp);
                            if ($arg->{error}) {
                                push @{${$arg->{error}}}, {$root => "restore chmod: $!"};
                            }
                            else {
                                _carp("and can't restore permissions to $mask\n");
                            }
                        }
		    }
		    last;
		}
		++$count;
		last unless $Is_VMS && lstat $root;
	    }
	}
    }

    return $count;
}

1;
