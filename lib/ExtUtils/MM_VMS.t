#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    use Test::More;
    if ($^O eq 'VMS') {
        plan( tests => 13 ); # 49 or more some day...
    }
    # MM_VMS does a C<use VMS::Filespec;> but that module
    # is unlikely to be installed on non VMS machines
    # (although not impossible: no xs, no sys$parse(), pure perl).
    else {
        plan( skip_all => "Only for VMS.  You go home now." );
    }
}

BEGIN {
    use_ok( 'ExtUtils::MM_VMS' );
}

# Those methods that can be ascertained to be defined(), albeit with
# no passed arguments, are so "tested".  Unfortunately, we omit
# testing of methods that need non-trivial arguments.
# Thus leaving test coverage at far less than 100% (patches welcome).
# The lines '#' commented out below are tests that failed with
# the empty arguments.

ok(defined(ExtUtils::MM_VMS::wraplist()),'wraplist defined');
ok(defined(ExtUtils::MM_VMS::rootdir()),'rootdir defined');
ok(!defined(ExtUtils::MM_VMS::ext()),'ext() not defined');
ok(defined(ExtUtils::MM_VMS::guess_name()),'guess_name defined');
#ok(!defined(ExtUtils::MM_VMS::find_perl()),'  defined');
ok(defined(ExtUtils::MM_VMS::path()),'path defined');
#ok(defined(ExtUtils::MM_VMS::maybe_command()),'  defined');
#ok(defined(ExtUtils::MM_VMS::maybe_command_in_dirs()),'  defined');
#ok(defined(ExtUtils::MM_VMS::perl_script()),'perl_script defined');
#ok(defined(ExtUtils::MM_VMS::file_name_is_absolute()),'file_name_is_absolute defined');
#ok(defined(ExtUtils::MM_VMS::replace_manpage_separator()),'replace_manpage_separator defined');
#ok(defined(ExtUtils::MM_VMS::init_others()),'init_others defined');
#ok(defined(ExtUtils::MM_VMS::constants()),'constants defined');
#ok(defined(ExtUtils::MM_VMS::cflags()),'cflags defined');
#ok(defined(ExtUtils::MM_VMS::const_cccmd()),'const_cccmd defined');
#ok(defined(ExtUtils::MM_VMS::pm_to_blib()),'pm_to_blib defined');
ok(defined(ExtUtils::MM_VMS::tool_autosplit()),'tool_autosplit defined');
#ok(defined(ExtUtils::MM_VMS::tool_xsubpp()),'tool_xsubpp defined');
#ok(defined(ExtUtils::MM_VMS::xsubpp_version()),'xsubpp_version defined');
#ok(defined(ExtUtils::MM_VMS::tools_other()),'tools_other defined');
#ok(defined(ExtUtils::MM_VMS::dist()),'dist defined');
#ok(defined(ExtUtils::MM_VMS::c_o()),'c_o defined');
#ok(defined(ExtUtils::MM_VMS::xs_c()),'xs_c defined');
#ok(defined(ExtUtils::MM_VMS::xs_o()),'xs_o defined');
#ok(defined(ExtUtils::MM_VMS::top_targets()),'top_targets defined');
#ok(defined(ExtUtils::MM_VMS::dlsyms()),'dlsyms defined');
#ok(defined(ExtUtils::MM_VMS::dynamic_lib()),'dynamic_lib defined');
#ok(defined(ExtUtils::MM_VMS::dynamic_bs()),'dynamic_bs defined');
#ok(defined(ExtUtils::MM_VMS::static_lib()),'static_lib defined');
#ok(defined(ExtUtils::MM_VMS::manifypods({})),'manifypods defined');
#ok(defined(ExtUtils::MM_VMS::processPL()),'processPL defined');
ok(defined(ExtUtils::MM_VMS::installbin()),'installbin defined');
#ok(defined(ExtUtils::MM_VMS::subdir_x()),'subdir_x defined');
#ok(defined(ExtUtils::MM_VMS::clean()),'clean defined');
#ok(defined(ExtUtils::MM_VMS::realclean()),'realclean defined');
ok(defined(ExtUtils::MM_VMS::dist_basics()),'dist_basics defined');
ok(defined(ExtUtils::MM_VMS::dist_core()),'dist_core defined');
ok(defined(ExtUtils::MM_VMS::dist_dir()),'dist_dir defined');
ok(defined(ExtUtils::MM_VMS::dist_test()),'dist_test defined');
#ok(defined(ExtUtils::MM_VMS::install()),'install defined');
#ok(defined(ExtUtils::MM_VMS::perldepend()),'perldepend defined');
ok(defined(ExtUtils::MM_VMS::makefile()),'makefile defined');
#ok(defined(ExtUtils::MM_VMS::test()),'test defined');
#ok(defined(ExtUtils::MM_VMS::test_via_harness()),'test_via_harness defined');
#ok(defined(ExtUtils::MM_VMS::test_via_script()),'test_via_script defined');
#ok(defined(ExtUtils::MM_VMS::makeaperl()),'makeaperl defined');
#ok(!defined(ExtUtils::MM_VMS::nicetext()),'nicetext() not defined');


