#!./perl -w

# 2001-12-16 Tels first version

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN { 
    use Test::More; 

    if( $^O =~ /^VMS|os2|MacOS|MSWin32|cygwin$/ ) {
        plan skip_all => 'Non-Unix platform';
    }
    else {
        plan tests => 90; 
    }
}

BEGIN { use_ok( 'ExtUtils::MM_Unix' ); }

use strict;
use File::Spec;

my $class = 'ExtUtils::MM_Unix';

# only one of the following can be true
# test should be removed if MM_Unix ever stops handling other OS than Unix
my $os =  ($ExtUtils::MM_Unix::Is_OS2 	|| 0)
	+ ($ExtUtils::MM_Unix::Is_Mac 	|| 0)
	+ ($ExtUtils::MM_Unix::Is_Win32 || 0) 
	+ ($ExtUtils::MM_Unix::Is_Dos 	|| 0)
	+ ($ExtUtils::MM_Unix::Is_VMS   || 0); 
ok ( $os <= 1,  'There can be only one (or none)');

is ($ExtUtils::MM_Unix::VERSION, '1.12604', 'Should be that version');

# when the following calls like canonpath, catdir etc are replaced by
# File::Spec calls, the test's become a bit pointless

foreach ( qw( xx/ ./xx/ xx/././xx xx///xx) )
  {
  is ($class->canonpath($_), File::Spec->canonpath($_), "canonpath $_");
  }

is ($class->catdir('xx','xx'), File::Spec->catdir('xx','xx'),
     'catdir(xx, xx) => xx/xx');
is ($class->catfile('xx','xx','yy'), File::Spec->catfile('xx','xx','yy'),
     'catfile(xx, xx) => xx/xx');

foreach (qw/updir curdir rootdir/)
  {
  is ($class->$_(), File::Spec->$_(), $_ );
  }

foreach ( qw /
  c_o
  clean
  const_cccmd
  const_config
  const_loadlibs
  constants
  depend
  dir_target
  dist
  dist_basics
  dist_ci
  dist_core
  dist_dir
  dist_test
  dlsyms
  dynamic
  dynamic_bs
  dynamic_lib
  exescan
  export_list
  extliblist
  file_name_is_absolute
  find_perl
  fixin
  force
  guess_name
  has_link_code
  htmlifypods
  init_dirscan
  init_main
  init_others
  install
  installbin
  libscan
  linkext
  lsdir
  macro
  makeaperl
  makefile
  manifypods
  maybe_command
  maybe_command_in_dirs
  needs_linking
  nicetext
  parse_version
  pasthru
  path
  perl_archive
  perl_archive_after
  perl_script
  perldepend
  pm_to_blib
  post_constants
  post_initialize
  postamble
  ppd
  prefixify
  processPL
  quote_paren
  realclean
  replace_manpage_separator
  static
  static_lib
  staticmake
  subdir_x
  subdirs
  test
  test_via_harness
  test_via_script
  tool_autosplit
  tool_xsubpp
  tools_other
  top_targets
  writedoc
  xs_c
  xs_cpp
  xs_o
  xsubpp_version 
  / )
  {
  ok ($class->can ($_), "can $_");
  }


