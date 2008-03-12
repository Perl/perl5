use ExtUtils::MakeMaker;

WriteMakefile
(
          'NAME' => 'Module::Pluggable',
          'VERSION_FROM' => 'lib/Module/Pluggable.pm',
           MAN3PODS     => {}, 	# Pods will be built by installman.
          'PREREQ_PM' => {
                           'File::Basename' => '0',
                           'File::Spec' => '3.00',
                           'Test::More' => '0.62'
                         },
          'EXE_FILES' => [],
          'PL_FILES' => {}
        )
;
