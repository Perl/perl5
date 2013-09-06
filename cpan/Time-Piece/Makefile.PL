use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile(
    'NAME'	=> 'Time::Piece',
    'VERSION_FROM' => 'Piece.pm', # finds $VERSION
    'AUTHOR' => 'Matt Sergeant',
    'ABSTRACT_FROM' => 'Piece.pm',
    'INSTALLDIRS' => ( ($] >= 5.009005 and $] < 5.011) ? 'perl' : 'site'),
    'PREREQ_PM' => { Exporter => '5.57' },
     (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
);
