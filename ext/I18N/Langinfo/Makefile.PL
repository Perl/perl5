use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'I18N::Langinfo',
    'VERSION_FROM'	=> 'Langinfo.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Langinfo.pm', # retrieve abstract from module
       AUTHOR     => 'Jarkko Hietaniemi <jhi@hut.fi>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
    # Without this the constants xs files are spotted, and cause rules to be
    # added to delete the similarly named C files, which isn't what we want.
    XS => {'Langinfo.xs' => 'Langinfo.c'},
    realclean => {FILES=> 'constants.c constants.xs'},
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
if (eval {require ExtUtils::Constant; 1}) {
  my @names = (qw(ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7
                  ABMON_1 ABMON_10 ABMON_11 ABMON_12 ABMON_2 ABMON_3 ABMON_4
                  ABMON_5 ABMON_6 ABMON_7 ABMON_8 ABMON_9 ALT_DIGITS AM_STR
                  CODESET CRNCYSTR DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7
                  D_FMT D_T_FMT ERA ERA_D_FMT ERA_D_T_FMT ERA_T_FMT MON_1
                  MON_10 MON_11 MON_12 MON_2 MON_3 MON_4 MON_5 MON_6 MON_7
                  MON_8 MON_9 NOEXPR NOSTR PM_STR RADIXCHAR THOUSEP T_FMT
                  T_FMT_AMPM YESEXPR YESSTR));
  ExtUtils::Constant::WriteConstants(
                                     NAME => 'I18N::Langinfo',
                                     NAMES => \@names,
                                    );
} else {
  use File::Copy;
  copy ('fallback.c', 'constants.c')
    or die "Can't copy fallback.c to constants.c: $!";
  copy ('fallback.xs', 'constants.xs')
    or die "Can't copy fallback.xs to constants.xs: $!";
}
