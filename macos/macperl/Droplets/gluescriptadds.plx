#!perl -w
use strict;

BEGIN { $Mac::Glue::CREATINGGLUES = 1 }

use Mac::Glue;
use Cwd;
use File::Basename;
use File::Spec::Functions;
use Mac::Files;
use Mac::Gestalt;
use Mac::AETE::App;
use Mac::AETE::Dialect;
use Mac::AETE::Format::Glue;

if (!@ARGV) {
    $ARGV[0] = Gestalt(gestaltSystemVersion) >= hex(800)
        ? FindFolder(kOnSystemDisk, 'Äscr')
        : catdir(FindFolder(kOnSystemDisk, kExtensionFolderType),
            'Scripting Additions');
}
die "Can't find Scripting Additions folder\n" if !@ARGV;

if (@ARGV == 1 && -d $ARGV[0]) {
    die "Can't find Scripting Additions folder: $ARGV[0] " .
        "(feel free to drag-and-drop the folder on this droplet)\n" if ! -e $ARGV[0];
    if (-d _) {
        chdir $ARGV[0] or die $!;
        opendir DIR, $ARGV[0] or die $!;
        my $cwd = cwd();
        @ARGV = map { catfile($cwd, $_) } readdir DIR;
    }
}

my $delete = MacPerl::Answer('Overwrite existing glues if they exist?',
    qw(OK No Cancel));
exit if $delete == 0;
$delete = 0 if $delete == 2;

foreach my $osax (@ARGV) {
    my($conv, $aete, $output, $file, $dir, $fixed);

    # initialize
    ($file, $dir) = fileparse($osax, '');

    print("$file does not appear to be an OSAX (Skipping)\n")
        && next unless is_osax($osax);

    $fixed = Mac::AETE::Format::Glue::fixname($file);
    $output = "$ENV{MACGLUEDIR}additions:" . $fixed;

    $aete = Mac::AETE::App->new( $osax );
    $conv = Mac::AETE::Format::Glue->new($output, !$delete);

    $aete->set_format($conv);
    $aete->read();
    $aete->write();
    $conv->finish();
    print "Created and installed OSAX glue for $file ($fixed)\n";
}

sub is_osax {
    my $osax = shift;

    return unless -f $osax;

    my $type = MacPerl::GetFileInfo($osax);
    return if !$type || $type ne 'osax';

    return 1;
}
