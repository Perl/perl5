package ExtUtils::Install;

require Exporter;
@ISA = ('Exporter');
@EXPORT = ('install','uninstall');

use Carp;
use Cwd qw(cwd);
use ExtUtils::MakeMaker; # to implement a MY class
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(mkpath);
#use strict;

sub install {
    my($hash,$verbose,$nonono) = @_;
    $verbose ||= 0;
    $nonono  ||= 0;
    my(%hash) = %$hash;
    my(%pack, %write,$dir);
    local(*DIR, *P);
    for (qw/read write/) {
	$pack{$_}=$hash{$_};
	delete $hash{$_};
    }
    my($blibdir);
    foreach $blibdir (sort keys %hash) {
	#Check if there are files, and if yes, look if the corresponding
	#target directory is writable for us
	opendir DIR, $blibdir or next;
	while ($_ = readdir DIR) {
	    next if $_ eq "." || $_ eq ".." || $_ eq ".exists";
	    if (-w $hash{$blibdir} || mkpath($hash{$blibdir})) {
		last;
	    } else {
		croak("You do not have permissions to install into $hash{$blibdir}");
	    }
	}
	closedir DIR;
    }
    if (-f $pack{"read"}) {
	open P, $pack{"read"} or die "Couldn't read $pack{'read'}";
	# Remember what you found
	while (<P>) {
	    chomp;
	    $write{$_}++;
	}
	close P;
    }
    my $cwd = cwd();
    my $umask = umask 0;

    # This silly reference is just here to be able to call MY->catdir
    # without a warning (Waiting for a proper path/directory module,
    # Charles!) The catdir and catfile calls leave us with a lot of
    # paths containing ././, but I don't want to use regexes on paths
    # anymore to delete them :-)
    my $MY = {};
    bless $MY, 'MY';
    my($source);
    MOD_INSTALL: foreach $source (sort keys %hash) {
	#copy the tree to the target directory without altering
	#timestamp and permission and remember for the .packlist
	#file. The packlist file contains the absolute paths of the
	#install locations. AFS users may call this a bug. We'll have
	#to reconsider how to add the means to satisfy AFS users also.
	chdir($source) or next;
	find(sub {
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
                         $atime,$mtime,$ctime,$blksize,$blocks) = stat;
	    return unless -f _;
	    return if $_ eq ".exists";
	    my $targetdir = $MY->catdir($hash{$source},$File::Find::dir);
	    my $targetfile = $MY->catfile($targetdir,$_);
	    my $diff = 0;

	    if ( -f $targetfile && -s _ == $size) {
		# We have a good chance, we can skip this one
		local(*F,*T);
		open F, $_ or croak("Couldn't open $_: $!");
		open T, $targetfile or croak("Couldn't open $targetfile: $!");
		my($fr, $tr, $fbuf,$tbuf,$size);
		$size = 1024;
		# print "Reading $_\n";
		while ( $fr = read(F,$fbuf,$size)) {
		    unless (
			    $tr = read(T,$tbuf,$size) and 
			    $tbuf eq $fbuf
			   ){
			# print "diff ";
			$diff++;
			last;
		    }
		    # print "$fr/$tr ";
		}
		# print "\n";
		close F;
		close T;
	    } else {
		print "$_ differs\n" if $verbose>1;
		$diff++;
	    }

	    if ($diff){
		mkpath($targetdir,0,0755) unless $nonono;
		print "mkpath($targetdir,0,0755)\n" if $verbose>1;
		unlink $targetfile if -f $targetfile;
		copy($_,$targetfile) unless $nonono;
		print "Installing $targetfile\n" if $verbose;
		utime($atime,$mtime,$targetfile) unless $nonono>1;
		print "utime($atime,$mtime,$targetfile)\n" if $verbose>1;
		chmod $mode, $targetfile;
		print "chmod($mode, $targetfile)\n" if $verbose>1;
	    } else {
		print "Skipping $targetfile (unchanged)\n";
	    }

	    $write{$targetfile}++;

	}, ".");
	chdir($cwd) or croak("Couldn't chdir....");
    }
    umask $umask;
    if ($pack{'write'}) {
	$dir = dirname($pack{'write'});
	mkpath($dir,0,0755);
	print "Writing $pack{'write'}\n";
	open P, ">$pack{'write'}" or croak("Couldn't write $pack{'write'}: $!");
	for (sort keys %write) {
	    print P "$_\n";
	}
	close P;
    }
}

sub uninstall {
    my($fil,$verbose,$nonono) = @_;
    die "no packlist file found: $fil" unless -f $fil;
    local *P;
    open P, $fil or croak("uninstall: Could not read packlist file $fil: $!");
    while (<P>) {
	chomp;
	print "unlink $_\n" if $verbose;
	unlink($_) || carp("Couldn't unlink $_") unless $nonono;
    }
    print "unlink $fil\n" if $verbose;
    unlink($fil) || carp("Couldn't unlink $fil") unless $nonono;
}

1;

__END__

=head1 NAME

ExtUtils::Install - install files from here to there

=head1 SYNOPSIS

B<use ExtUtils::Install;>

B<install($hashref,$verbose,$nonono);>

B<uninstall($packlistfile,$verbose,$nonono);>

=head1 DESCRIPTION

Both functions, install() and uninstall() are specific to the way
ExtUtils::MakeMaker handles the installation and deinstallation of
perl modules. They are not designed as general purpose tools.

install() takes three arguments. A reference to a hash, a verbose
switch and a don't-really-do-it switch. The hash ref contains a
mapping of directories: each key/value pair is a combination of
directories to be copied. Key is a directory to copy from, value is a
directory to copy to. The whole tree below the "from" directory will
be copied preserving timestamps and permissions.

There are two keys with a special meaning in the hash: "read" and
"write". After the copying is done, install will write the list of
target files to the file named by $hashref->{write}. If there is
another file named by $hashref->{read}, the contents of this file will
be merged into the written file. The read and the written file may be
identical, but on AFS it is quite likely, people are installing to a
different directory than the one where the files later appear.

uninstall() takes as first argument a file containing filenames to be
unlinked. The second argument is a verbose switch, the third is a
no-don't-really-do-it-now switch.

=cut

#=head1 NOTES

#=head1 BUGS

#=head1 AUTHORS

