use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Time::Piece',
    MAN3PODS    => {},  # Pods will be built by installman.
    'VERSION_FROM' => 'Piece.pm',
);
