package Cwd;
require 5.000;
require Exporter;
use Config;

@ISA = qw(Exporter);
@EXPORT = qw(getcwd fastcwd);
@EXPORT_OK = qw(chdir);


# VMS: $ENV{'DEFAULT'} points to default directory at all times
# 08-Dec-1994  Charles Bailey  bailey@genetics.upenn.edu
# Note: Use of Cwd::getcwd() or Cwd::chdir() (but not Cwd::fastcwd())
#   causes the logical name PWD to be defined in the process 
#   logical name table as the default device and directory 
#   seen by Perl. This may not be the same as the default device 
#   and directory seen by DCL after Perl exits, since the effects
#   the CRTL chdir() function persist only until Perl exits.

# By Brandon S. Allbery
#
# Usage: $cwd = getcwd();

sub getcwd
{
    if($Config{'osname'} eq 'VMS') { return $ENV{'PWD'} = $ENV{'DEFAULT'} }

    my($dotdots, $cwd, @pst, @cst, $dir, @tst);

    unless (@cst = stat('.'))
    {
	warn "stat(.): $!";
	return '';
    }
    $cwd = '';
    $dotdots = '';
    do
    {
	$dotdots .= '/' if $dotdots;
	$dotdots .= '..';
	@pst = @cst;
	unless (opendir(PARENT, $dotdots))
	{
	    warn "opendir($dotdots): $!";
	    return '';
	}
	unless (@cst = stat($dotdots))
	{
	    warn "stat($dotdots): $!";
	    closedir(PARENT);
	    return '';
	}
	if ($pst[0] == $cst[0] && $pst[1] == $cst[1])
	{
	    $dir = '';
	}
	else
	{
	    do
	    {
		unless (defined ($dir = readdir(PARENT)))
	        {
		    warn "readdir($dotdots): $!";
		    closedir(PARENT);
		    return '';
		}
		unless (@tst = lstat("$dotdots/$dir"))
		{
		    warn "lstat($dotdots/$dir): $!";
		    closedir(PARENT);
		    return '';
		}
	    }
	    while ($dir eq '.' || $dir eq '..' || $tst[0] != $pst[0] ||
		   $tst[1] != $pst[1]);
	}
	$cwd = "$dir/$cwd";
	closedir(PARENT);
    } while ($dir);
    chop($cwd); # drop the trailing /
    $cwd;
}



# By John Bazik
#
# Usage: $cwd = &fastcwd;
#
# This is a faster version of getcwd.  It's also more dangerous because
# you might chdir out of a directory that you can't chdir back into.

sub fastcwd {
    if($Config{'osname'} eq 'VMS') { return $ENV{'DEFAULT'} }

    my($odev, $oino, $cdev, $cino, $tdev, $tino);
    my(@path, $path);
    local(*DIR);

    ($cdev, $cino) = stat('.');
    for (;;) {
	my $direntry;
	($odev, $oino) = ($cdev, $cino);
	chdir('..');
	($cdev, $cino) = stat('.');
	last if $odev == $cdev && $oino == $cino;
	opendir(DIR, '.');
	for (;;) {
	    $direntry = readdir(DIR);
	    next if $direntry eq '.';
	    next if $direntry eq '..';

	    last unless defined $direntry;
	    ($tdev, $tino) = lstat($direntry);
	    last unless $tdev != $odev || $tino != $oino;
	}
	closedir(DIR);
	unshift(@path, $direntry);
    }
    chdir($path = '/' . join('/', @path));
    $path;
}


# keeps track of current working directory in PWD environment var
#
# $RCSfile: pwd.pl,v $$Revision: 4.1 $$Date: 92/08/07 18:24:11 $
#
# $Log:	pwd.pl,v $
#
# Usage:
#	use Cwd 'chdir';
#	chdir $newdir;

$chdir_init = 0;

sub chdir_init{
    if ($ENV{'PWD'}) {
	my($dd,$di) = stat('.');
	my($pd,$pi) = stat($ENV{'PWD'});
	if (!defined $dd or !defined $pd or $di != $pi or $dd != $pd) {
	    chop($ENV{'PWD'} = `pwd`);
	}
    }
    else {
	chop($ENV{'PWD'} = `pwd`);
    }
    if ($ENV{'PWD'} =~ m|(/[^/]+(/[^/]+/[^/]+))(.*)|) {
	my($pd,$pi) = stat($2);
	my($dd,$di) = stat($1);
	if (defined $pd and defined $dd and $di == $pi and $dd == $pd) {
	    $ENV{'PWD'}="$2$3";
	}
    }
    $chdir_init = 1;
}

sub chdir {
    my($newdir) = shift;
    $newdir =~ s|/{2,}|/|g;
    chdir_init() unless $chdir_init;
    return 0 unless (CORE::chdir $newdir);
    if ($Config{'osname'} eq 'VMS') { return $ENV{PWD} = $ENV{DEFAULT} }

    if ($newdir =~ m#^/#) {
	$ENV{'PWD'} = $newdir;
    }else{
	my(@curdir) = split(m#/#,$ENV{'PWD'});
	@curdir = '' unless @curdir;
	foreach $component (split(m#/#, $newdir)) {
	    next if $component eq '.';
	    pop(@curdir),next if $component eq '..';
	    push(@curdir,$component);
	}
	$ENV{'PWD'} = join('/',@curdir) || '/';
    }
}

1;

