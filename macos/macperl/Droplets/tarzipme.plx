#!perl
#-----------------------------------------------------------------#
#  tarzipme.plx
#  http://pudge.net/
#
#  Created:       Chris Nandor (pudge@pobox.com)       04 Jan 1999
#  Last Modified: Chris Nandor (pudge@pobox.com)       28 Jul 1999
#-----------------------------------------------------------------#
# This script primarily for developers, to make distributions.
# Feel free to edit it to suit your needs: you might want to,
# for instance, make the macbinarizing non-interactive, and
# work only on certain file types.
#
# In file window, text files are normal font, macbinary are bold,
# and no conversion is italic.
#
# Edit $verbose and $switch variables to customize for verbosity
# and conversion behavior.
#-----------------------------------------------------------------#
use Archive::Tar;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;

use Mac::Conversions;
use Mac::Dialogs;
use Mac::Events;
use Mac::Files;
use Mac::Fonts;
use Mac::Lists;
use Mac::MoreFiles;
use Mac::QuickDraw;
use Mac::Windows;

use strict;
use constant NO_CONVERSION  => 0;
use constant TEXT           => 1;
use constant MACBINARY      => 2;

$^W = 1;

my($verbose, $ans, $switch, $conv, %con, %style);
$verbose = 1;
$conv = new Mac::Conversions;

%style = (
    NO_CONVERSION, italic,
    TEXT         , normal,
    MACBINARY    , bold,
);
$ans = <<EOT;
Select a method for file conversion.  Select automatic conversion
(where -T means CR to LF conversion, and -B means MacBinarize),
pick a method for each file manually, or do no conversion.
EOT
$ans =~ s/\n/ /g;

do_it();
print "Done.\n";

#-----------------------------------------------------------------#
sub do_it {
    my($dir, $tar, $file, @f, $mdir, $ndir, $tdir, $edir);
    local $|;

    $dir = $ARGV[0];
    unless ($dir && -d $dir) {
        die "Need directory name";
    }
    $dir  =~ s/:$//;
    $file = get_filename($dir);
    $ndir = basename($dir);
    $edir = "$ENV{TMPDIR}macperltar:";
    $tdir = "$edir$ndir";
    $mdir = dirname($tdir);
    $tar  = new Archive::Tar;

    die "Cannot continue: archive $file exists\n" if -e $file;
    create_dir($dir, $edir, $tdir);
    create_file($file);

    chdir($edir) or die "Can't chdir $edir: $!";

    $switch = MacPerl::Answer($ans, 'Automatic', 'Manual', 'None');
    do_dialog($tdir, $mdir) if $switch == 1;

    print "Converting files ...\n";
    find(sub {
        my $f = $File::Find::name;
        return if ! -f $f || $f =~ /:Icon\n$/;
        (my $n = $f) =~ s/^$mdir//;
        $n = ":$n" unless $n =~ /^:/;
        $n = convert($f, $n) if $switch;
        push @f, $n;
    }, $tdir);

    print "Adding files to archive ...\n";
    $tar->add_files(@f);
    print "Writing archive to <$file> ...\n";
    $tar->write($file, 1);
    print "Cleaning up ...\n";
    rmtree($tdir);
}
#-----------------------------------------------------------------#
sub guess {
    my $f = shift;
    my $guess = 0;
    if (-s $f && -T _) {
        $guess = TEXT;
    } elsif (-s _ && -B _) {
        $guess = MACBINARY;
    } elsif (-B _) {
        my $cat  = FSpGetCatInfo($f);
        $guess = MACBINARY if ($cat->ioFlRLgLen());
    }
    return $guess;
}
#-----------------------------------------------------------------#
sub convert {
    my($f, $n) = @_;
    if ($switch == 2) {
        my $guess = guess($f);
        if ($guess == TEXT) {
            return cr2lf($f, $n);
        } elsif ($guess == MACBINARY) {
            return bi2bin($f, $n);
        } else {
            return leave_alone($f, $n);
        }
    } elsif ($switch == 1) {
        if ($con{$n} == TEXT) {
            return cr2lf($f, $n);
        } elsif ($con{$n} == MACBINARY) {
            return bi2bin($f, $n);
        } else {
            return leave_alone($f, $n);
        }
    }
}
#-----------------------------------------------------------------#
sub leave_alone {
    my($f, $n, $t) = @_;
    print "  Left alone   $n\n" if $verbose;
    return $n;
}
#-----------------------------------------------------------------#
sub bi2bin {
    my($f, $n, $t) = @_;
    undef $t;
    $conv->macbinary($f);
    $n .= '.bin';
    print "  Macbinarized $n\n" if $verbose;
    return $n;
}
#-----------------------------------------------------------------#
sub cr2lf {
    local(*F, $/);
    my($f, $n, $t) = @_;
    open(F, "< $f\0") or die "Can't open $f: $!";
    $t = <F>;
    close(F);
    $t =~ s/\015\012?/\012/g if $t;
    open(F, "> $f\0") or die "Can't open $f: $!";
    print F $t;
    close(F);
    print "  CRLF? to LF  $n\n" if $verbose;
    return $n;
}
#-----------------------------------------------------------------#
sub create_file {FSpCreate(shift, qw/Gzip Gzip/) or die $^E}
#-----------------------------------------------------------------#
sub create_dir {
    my($dir, $edir, $tdir) = @_;
    unless (-d $edir) {mkdir $edir, 0777 or die "Cannot create $edir: $!"}
    rmtree($tdir) if -d $tdir;
    FSpDirectoryCopy($dir, $edir, 1)
        or die "Can't copy $dir to $edir: $^E";
}
#-----------------------------------------------------------------#
sub get_filename {
    my $name = shift;
    my($file, $path) = fileparse($name, '');
    my $tfile = length($file) < 24 ? "$file.tar.gz" :
        length($file) < 28 ? "$file.tgz" :
        substr($file, 0, 23) . "\xC9.tar.gz";
    return "$path$tfile";
}

#=================================================================#
# List stuff for manual selection #
#=================================================================#
sub do_dialog {
    my($tdir, $mdir) = @_;
    my @files;

    find(sub {
        my $f = $File::Find::name;
        return if ! -f $f || $f =~ /:Icon\n$/;
        (my $n = $f) =~ s/^$mdir/:/;
        push @files, $n;
        $con{$n} = [guess($f), 0];
    }, $tdir);

    my $win = MacWindow->new(
        Rect->new(100, 50, 600, 350), 'Files to tarzip',
        1, floatProc(), 1
    );
    $win->sethook(redraw => sub {});
    SetPort($win->window);
    TextFont(geneva());
    TextSize(9);
    my $list = $win->new_list(
        Rect->new(0, 0, 484, 300),
        Rect->new(0, 0, 1, scalar @files),
        Point->new(0, 13), \&myLDEF, 1, 1
    );

    $list->sethook(key=>sub{
        my($mod) = $Mac::Events::CurrentEvent->modifiers();
        if ($_[2] == ord('w') && (($mod & cmdKey()) == cmdKey())) {
            $win->dispose();
            return 1;
        }
        return;
    });
    
    for (my $c = 0; $c <= $#files; $c++) {
        $list->set(0, $c, $files[$c]);
    }
    
    while ($win->window()) {
        WaitNextEvent();
    }
    
    $win->dispose() if defined($win);
    
    END {
        $win->dispose() if defined($win);
    }

    foreach my $n (keys %con) {
        $con{$n} = $con{$n}->[0] % 3;
    }
}
#-----------------------------------------------------------------#
sub myLDEF {
    my($msg, $select, $rect, $cell, $data, $list) = @_;

    return unless $msg == lDrawMsg || $msg == lHiliteMsg;
    my($where) = AddPt($rect->topLeft, $list->indent);
    EraseRect $rect;

    $con{$data}->[0]++ if ($select && ($con{$data}->[1]++ % 2));
    TextFace($style{ $con{$data}->[0] % 3 });
    LSetSelect(0, $cell, $list);

    MoveTo($where->h, $where->v);
    DrawString $data;
}
#-----------------------------------------------------------------#
sub check_value {
    my($win, $list, $x, $y) = @_;
    return if !$list->{'list'};
    $y = LGetSelect(1, Point->new(0,1), $list->{'list'});
    $x = $list->get($y) if $y;
    return if ref($x);
}
#-----------------------------------------------------------------#

__END__
