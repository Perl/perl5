use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Math::BigInt::FastCalc',
    'VERSION_FROM'	=> 'FastCalc.pm',	# finds $VERSION
    'PREREQ_PM'		=> {
	Math::BigInt => 1.76,
      },
    'LIBS'		=> [''], 	# e.g., '-lm'
    'DEFINE'		=> '', 		# e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', 		# e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
