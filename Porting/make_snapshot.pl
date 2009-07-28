#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use Cwd;

use POSIX qw(strftime);
sub isotime { strftime "%Y-%m-%d.%H:%M:%S",gmtime(shift||time) }

my ($abbr,$sha1,$tstamp);
$sha1= shift || "HEAD";
my $zip_root= $ENV{PERL_SNAPSHOT_ZIP_ROOT} || "/gitcommon/branches/snapshot";
my $gitdir= shift || `git rev-parse --git-dir`
    or die "Not a git repo!\n";
chomp $gitdir;
my $workdir= $gitdir;
if ( $workdir =~ s!/\.git\z!! ) {
    chdir $workdir 
        or die "Failed to chdir to $workdir\n";
} else {
    chdir $workdir
        or die "Failed to chdir to bare repo $workdir\n";
}

($sha1, $abbr,$tstamp)= split /\s+/, `git log --pretty='format:%H %h %ct' -1 $sha1`
    or die "Failed to parse '$sha1'\n";
chomp($sha1,$abbr,$tstamp);

#die "'$sha1','$abbr'\n";

my $path= join "/", $zip_root, substr($sha1,0,2), substr($sha1,0,4);
my $tar_file= "$sha1.tar.$$";
my $gz_file= "$sha1.tgz";
my $prefix= "perl-$abbr/";

if (!-e "$path/$gz_file") {
    mkpath $path if !-d $path;

    system("git archive --format=tar --prefix=$prefix $sha1 > $path/$tar_file");
    my @branches=(
              'origin/blead',
              'origin/maint-5.10',
              'origin/maint-5.8',
              'origin/maint-5.8-dor',
              'origin/maint-5.6',
              'origin/maint-5.005',
              'origin/maint-5.004',
    );
    my $branch;
    foreach my $b (@branches) {
        $branch= $b and last 
            if `git log --pretty='format:%H' $b | grep $sha1`;
    }

    $branch ||= "unknown-branch";
    chomp(my $describe= `git describe`);
    chdir $path;
    {
        open my $fh,">","$path/$$.patch" or die "Failed to open $$.patch for writing\n";
        print $fh join(" ", $branch, $tstamp, $sha1, $describe) . "\n";
        close $fh;
    }
    system("tar -f $tar_file --transform='s,^$$,$prefix,g' --owner=root --group=root --mode=664 --append $$.patch");
    system("gzip -S .gz -9 $tar_file");
    rename "$tar_file.gz", "$gz_file";
}
print "$path/$gz_file", -t STDOUT ? "\n" :"";

