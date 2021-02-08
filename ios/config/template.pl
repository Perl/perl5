#!/usr/bin/env perl
use strict;
use warnings;

my @config_files = qw (
  ./watch/armv7k/config
  ./watch/x86_64/config
  ./appletv/arm64/config
  ./appletv/x86_64/config
  ./iphone/armv7/config
  ./iphone/arm64/config
  ./iphone/x86_64/config
);

my @sh_keys = qw (
	alignbytes
	aphostname
	c
	castflags
	cccdlflags
	ccflags
	cf_time
	cppflags
	cpprun
	cppstdin
	cppsymbols
	d_bsd
	d_builtin_add_overflow
	d_builtin_mul_overflow
	d_builtin_sub_overflow
	d_casti32
	d_castneg
	d_eofnblk
	d_faststdio
	d_fchmodat
	d_fork
	d_futimes
	d_gconvert
	d_linkat
	d_long_double_style_ieee
	d_long_double_style_ieee_extended
	d_mkostemp
	d_nv_preserves_uv
	d_nv_zero_is_allbits_zero
	d_openat
	d_renameat
	d_semctl_semid_ds
	d_semctl_semun
	d_stdio_cnt_lval
	d_stdio_ptr_lval
	d_stdio_ptr_lval_nochange_cnt
	d_stdiobase
	d_stdstdio
	d_syscall
	d_syscallproto
	d_system
	d_unlinkat
	d_vfork
	doublenanbytes
	gidformat
	i_sysdir
	i32type
	i64type
	incpth
	ios_build
	ivsize
	ld
	lddlflags
	ldflags
	libpth
	libsdirs
	libsfiles
	libsfound
	libspath
	locincpth
	loclibpth
	longdblinfbytes
	longdblkind
	longdblmantbits
	longdblnanbytes
	longdblsize
	longsize
	myarchname
	n
	need_va_copy
	nv_overflows_integers_at
	nv_preserves_uv_bits
	nveformat
	nveuformat
	nvfformat
	nvfuformat
	nvgformat
	nvguformat
	nvmantbits
	nvsize
	nvtype
	ptrsize
	quadkind
	quadtype
	rd_nodata
	sgmtime_max
	sgmtime_min
	sizesize
	slocaltime_max
	slocaltime_min
	sprid64
	sprieldbl
	sprieuldbl
	sprifldbl
	sprifuldbl
	sprigldbl
	spriguldbl
	sprii64
	sprio64
	spriu64
	sprix64
	sprixu64
	sscnfldbl
	timeincl
	tv_build
	u32type
	u64type
	uidformat
	uquadtype
	use64bitall
	use64bitint
	uselongdouble
	usevfork
	uvsize
	watch_build
);

my @h_keys = qw (
  has_syscall
  i_sys_dir
  longsize
  quad_t
  uquad_t
  quadkind
  mem_alignbytes
  casti32
  castnegfloat
  castflags
  gconvert
  use_stdio_ptr
  stdio_ptr_lvalue
  stdio_cnt_lvalue
  stdio_ptr_lval_nochange_cnt
  use_stdio_base
  rd_nodata
  eof_nonblock
  ptrsize
  cppstdin
  cpprun
  long_doublesize
  long_doublekind
  long_double_style_ieee
  long_double_style_ieee_extended
  use_semctl_semun
  use_semctl_semid_ds
  has_builtin_add_overflow
  has_builtin_sub_overflow
  has_builtin_mul_overflow
  has_fast_stdio
  has_fchmodat
  has_linkat
  has_openat
  has_renameat
  has_unlinkat
  has_futimes
  has_syscall_proto
  db_version_major_cfg
  db_version_minor_cfg
  db_version_patch_cfg
  doublenanbytes
  longdblinfbytes
  longdblnanbytes
  perl_prifldbl
  perl_prigldbl
  perl_prieldbl
  perl_scnfldbl
  longdblmantbits
  nvmantbits
  need_va_copy
  i32type
  u32type
  i64type
  u64type
  nvtype
  ivsize
  uvsize
  nvsize
  nv_preserves_uv
  nv_preserves_uv_bits
  nv_overflows_integers_at
  nv_zero_is_allbits_zero
  nvef
  nvff
  nvgf
  gmtime_max
  gmtime_min
  localtime_max
  localtime_min
  use_64_bit_int
  use_64_bit_all
  use_long_double
  gid_t_f
  size_t_size
  uid_t_f
  has_fork
  has_system
  has_mkostemp
);

sub split_row {
  my ($ext, $row) = @_;
  my @key;
  if ($ext eq 'h') {
    @key = $row =~ m/^(?:\/\*)?(?:\s*)#(?:\s*)(?:define|undef)(?:\s*)([A-Za-z_0-9]*)(?:.*$)/ ;
  } elsif ($ext eq 'sh') {
    @key = split /=/, $row;
  }
  return @key;
}

sub write_file {
  my ($config, $output) = @_;
  open(my $fh, '>:encoding(UTF-8)', $config )
    or die "Could not open file $config  $!";
  print $fh $output;
  close $fh;
}

sub read_file {
  my ($filename) = @_;
  my $result;
  
  open(my $fh, '<:encoding(UTF-8)', $filename)
    or die "Could not open file $filename $!";

  while (my $row = <$fh>) {
    $result .= $row;
  }
  close $fh;
  return $result;
}

sub write_config
{
  my $ext = shift;
  my $orig_files = `find . -name config.$ext`;
  my @config_files = split /\n/, $orig_files;
  
  my %config_keys;
  if ($ext eq 'h') {
    $config_keys{$_}++ for (@h_keys);
  } elsif ($ext eq 'sh') {
    $config_keys{$_}++ for (@sh_keys);
  }
  
  foreach my $file (@config_files)
  {
    my $template = "./config.$ext.tt";
    my $target = "./$file";
    my $diff = "./$file.diff";
    
    my $template_config = read_file($template);
    my $target_config = read_file($target);
    
    my @template_lines = split /\n/, $template_config;
    my @target_lines = split /\n/, $target_config;  
  
    my $output;
    my $index = 0;
    
    foreach my $row (@target_lines) {
      my @key = split_row($ext, $row);
      if (scalar @key) {
        if (exists $config_keys{lc $key[0]}) {
          $output .= $target_lines[$index] . "\n";
        }
      }
      $index ++;
    }
    write_file($diff , $output);
  }
}

sub get_config
{
  my $ext = shift;
  my $orig_files = `find . -name config.$ext`;

  foreach my $file (@config_files)
  {
    my $template = "config.$ext.tt";
    my $target = "$file.$ext.diff";
    my $config = "$file.$ext";
    
    my $template_config = read_file($template);
    my $target_config = read_file($target);
    
    my @template_lines = split /\n/, $template_config;
    my @target_lines = split /\n/, $target_config;  
    my $output;
    my $index = 0;
    
    my %target_config;
    
    print "processing $file\n";
    
    if ($ext eq 'sh') {
      $output .= read_file("./$file.$ext.cc");
    }
    
    foreach my $row (@target_lines)
    {    
      my @key = split_row($ext, $row);
      if (scalar @key)
      {
        $target_config{lc $key[0]} = $row;
      }
      $index++;
    } 
  
    $index = 0;
    foreach my $row (@template_lines) {
      if ($row !~ /^\[% /) {
        $output .= $row . "\n";
      } else {
        my @key = $row =~ m/^\s*\[%\s*(\S*)\s*%\]/ ;
        if (scalar @key) {
          my $k = lc $key[0];
          if (exists $target_config{$k})
          {
            if (defined $target_config{$k}) {
              $output .= $target_config{$k} . "\n";
            } else {
              warn "configuration key $k not defined in $target";
            }
          } else {
            warn "config not defined $k";
          }    
        } else {
          die "template config cannot be parsed at line $index"
        }
      }
      $index ++;
    }
    write_file($config, $output);
  }
}

sub verify_config {
  my $ext = shift;
  my $orig_files = `find . -name config.$ext`;
  my @config_files = split /\n/, $orig_files;

  foreach my $file (@config_files)
  {
    my $old_config = read_file($file);
    my $new_config = read_file("$file.new");
    if ($old_config eq $new_config) {
      print "$file.new verifies ok\n";
    } else {
      print "$file.new fails to verify\n";
    }
  }
}

# write_config('h');
# write_config('sh');
get_config('h');
get_config('sh');
#verify_config('h');
#verify_config('sh');

exit 0;

