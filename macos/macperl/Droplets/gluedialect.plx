#!perl -w
use strict;

BEGIN { $Mac::Glue::CREATINGGLUES = 1 }

use Cwd;
use File::Basename;
use File::Spec::Functions;
use Mac::Files;
use Mac::Gestalt qw[Gestalt gestaltSystemVersion];
use Mac::Glue;
use Mac::AETE::App;
use Mac::AETE::Dialect;
use Mac::AETE::Format::Glue;

if (!@ARGV) {
    $ARGV[0] = catdir((Gestalt(gestaltSystemVersion) >= hex(800)
        ? FindFolder(kOnSystemDisk, 'Äscr')
        : catdir(FindFolder(kOnSystemDisk, kExtensionFolderType),
            'Scripting Additions')), 'Dialects');
}
die "Can't find Dialects folder\n" if !@ARGV;

if (Gestalt(gestaltSystemVersion) >= hex(900)) {
    @ARGV = catfile(FindFolder(kOnSystemDisk, kExtensionFolderType), 'AppleScript');
    warn "Because you are using Mac OS 9, which has a different \"dialect\" setup,\n",
         "you should go delete old dialect files manually from:\n  $ENV{MACGLUEDIR}dialects:\n\n";
} elsif (@ARGV == 1) {
    die "Can't find Dialects folder: $ARGV[0] " .
        "(feel free to drag-and-drop the folder on this droplet)\n" if ! -e $ARGV[0];
    if (-d _) {
        chdir $ARGV[0] or die $!;
        opendir DIR, $ARGV[0] or die $!;
        @ARGV = readdir DIR;
    }
}

my $delete = MacPerl::Answer('Overwrite existing glues if they exist?',
    qw(OK No Cancel));
exit if $delete == 0;
$delete = 0 if $delete == 2;

foreach my $dlct (@ARGV) {
    my $cwd = cwd();
    my($conv, $aeut, $output, $file, $dir, $fixed);

    # initialize
    ($file, $dir) = fileparse($dlct, '');

    print("$file does not appear to be a Dialect (Skipped)\n")
        && next unless is_dialect($dlct);

    $file =~ s/\s+Dialect$//;
    $fixed = Mac::AETE::Format::Glue::fixname($file);
    $output = "$ENV{MACGLUEDIR}dialects:" . $fixed;

    $aeut = Mac::AETE::Dialect->new( -e catfile($cwd, $dlct) ? catfile($cwd, $dlct) : $dlct);
    $conv = Mac::AETE::Format::Glue->new($output, !$delete);

    $aeut->set_format($conv);
    $aeut->read();
    $aeut->write();
    $conv->finish();
    print "Created and installed Dialect glue for $file ($fixed)\n";
}

sub is_dialect {
    my $dlct = shift;

    return unless -f $dlct;

    my($creator, $type) = MacPerl::GetFileInfo($dlct);
    return if !$type || !$creator || $creator ne 'ascr' ||
        ($type ne 'shlb' && $type ne 'dlct' && $type ne 'thng');

    return 1;
}
