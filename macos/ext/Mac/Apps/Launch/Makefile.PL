#!perl
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mac::Apps::Launch',
    'VERSION_FROM' => 'Launch.pm', # finds $VERSION
);
