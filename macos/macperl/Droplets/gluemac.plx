#!perl -w
use strict;

use File::Basename;
use Mac::Glue;
use Mac::AETE::App;
use Mac::AETE::Dialect;
use Mac::AETE::Format::Glue;

my $delete = MacPerl::Answer('Overwrite existing glues if they exist?',
    qw(OK No Cancel));
exit if $delete == 0;
$delete = 0 if $delete == 2;

foreach my $drop (@ARGV) {
    my($oldfh, $conv, $aeut, $aete, $output, $file, $dir, $fixed);

    $drop = readlink $drop while -l $drop;

    # initialize
    $drop =~ s/:$//;  # is dir/package ?
    ($file, $dir) = fileparse($drop, '');
    $fixed = Mac::AETE::Format::Glue::fixname($file);
    $fixed = MacPerl::Ask('What is the glue name?', $fixed);
    print("No name given for $file (Skipped)\n")
        && next if !$fixed || $fixed eq '';
    $output = $ENV{MACGLUEDIR} . $fixed;

    next unless $aete = Mac::AETE::App->new($drop);
    $conv = Mac::AETE::Format::Glue->new($output, !$delete);

    $aete->set_format($conv);
    $aete->read();
    $aete->write();
    $conv->finish();
    print "Created and installed glue for $file ($fixed)\n";
}
