#!./perl -T


my %Expect;
my $symlink_exists = eval { symlink("",""); 1 };
my $warn_msg;
my $cwd;
my $cwd_untainted;

BEGIN {
    chdir 't' if -d 't';
   @INC = '../lib';

    for (keys %ENV) { # untaint ENV
	($ENV{$_}) = keys %{{ map {$_ => 1} $ENV{$_} }};
    }

    $SIG{'__WARN__'} = sub { $warn_msg = $_[0]; warn "# Warn: $_[0]"; }
}

if ( $symlink_exists ) { print "1..184\n"; }
else                   { print "1..75\n";  }

use File::Find;
use Cwd;

# Remove insecure directories from PATH
my @path;
my $sep = ($^O eq 'MSWin32') ? ';' : ':';
foreach my $dir (split(/$sep/,$ENV{'PATH'}))
 {
  push(@path,$dir) unless -w $dir;
 }
$ENV{'PATH'} = join($sep,@path);

cleanup();

if ($^O eq 'MacOS') {
    find({wanted => sub { print "ok 1\n" if $_ eq 'filefind.t'; }, untaint => 1}, ':');
    finddepth({wanted => sub { print "ok 2\n" if $_ eq 'filefind.t'; }, untaint => 1}, ':');
} else {
    find({wanted => sub { print "ok 1\n" if $_ eq 'filefind.t'; }, untaint => 1,
          untaint_pattern => qr|^(.+)$|}, '.');
    finddepth({wanted => sub { print "ok 2\n" if $_ eq 'filefind.t'; },
               untaint => 1, untaint_pattern => qr|^(.+)$|}, '.');
}

my $case = 2;
my $FastFileTests_OK = 0;

sub cleanup {
    if ($^O eq 'MacOS') {
	if (-d ':for_find') {
	    chdir(':for_find');
	}
	if (-d ':fa') {
	    unlink ':fa:fa_ord',':fa:fsl',':fa:faa:faa_ord',
		':fa:fab:fab_ord',':fa:fab:faba:faba_ord',
		':fb:fb_ord',':fb:fba:fba_ord';
	    rmdir ':fa:faa';
	    rmdir ':fa:fab:faba';
	    rmdir ':fa:fab';
	    rmdir ':fa';
	    rmdir ':fb:fba';
	    rmdir ':fb';
	    chdir '::';
	    rmdir ':for_find';
	}
    } else {
	if (-d 'for_find') {
	    chdir('for_find');
	}
	if (-d 'fa') {
	    unlink 'fa/fa_ord','fa/fsl','fa/faa/faa_ord',
		'fa/fab/fab_ord','fa/fab/faba/faba_ord',
		'fb/fb_ord','fb/fba/fba_ord';
	    rmdir 'fa/faa';
	    rmdir 'fa/fab/faba';
	    rmdir 'fa/fab';
	    rmdir 'fa';
	    rmdir 'fb/fba';
	    rmdir 'fb';
	    chdir '..';
	    rmdir 'for_find';
	}
    }
}

END {
    cleanup();
}

sub Check($) {
  $case++;
  if ($_[0]) { print "ok $case\n"; }
  else       { print "not ok $case\n"; }
}

sub CheckDie($) {
  $case++;
  if ($_[0]) { print "ok $case\n"; }
  else { print "not ok $case\n $!\n"; exit 0; }
}

sub touch {
  CheckDie( open(my $T,'>',$_[0]) );
}

sub MkDir($$) {
  CheckDie( mkdir($_[0],$_[1]) );
}

sub wanted {
  print "# '$_' => 1\n";
  s#\.$## if ($^O eq 'VMS' && $_ ne '.');
  Check( $Expect{$_} );
  if ( $FastFileTests_OK ) {
    delete $Expect{$_}
      unless ( $Expect_Dir{$_} && ! -d _ );
  } else {
    delete $Expect{$_}
      unless ( $Expect_Dir{$_} && ! -d $_ );
  }
  $File::Find::prune=1 if  $_ eq 'faba';

}

sub dn_wanted {
  my $n = $File::Find::name;
  $n =~ s#\.$## if ($^O eq 'VMS' && $n ne '.');
  print "# '$n' => 1\n";
  my $i = rindex($n,'/');
  my $OK = exists($Expect{$n});
  unless ($^O eq 'MacOS') {
    if ( $OK ) {
  	  $OK= exists($Expect{substr($n,0,$i)})  if $i >= 0;
    }
  }
  Check($OK);
  delete $Expect{$n};
}

sub d_wanted {
  print "# '$_' => 1\n";
  s#\.$## if ($^O eq 'VMS' && $_ ne '.');
  my $i = rindex($_,'/');
  my $OK = exists($Expect{$_});
  unless ($^O eq 'MacOS') {
    if ( $OK ) {
        $OK= exists($Expect{substr($_,0,$i)})  if $i >= 0;
    }
  }
  Check($OK);
  delete $Expect{$_};
}

sub simple_wanted {
  print "# \$File::Find::dir => '$File::Find::dir'\n";
  print "# \$_ => '$_'\n";
}

sub noop_wanted {}

sub my_preprocess {
  @files = @_;
  print "# --PREPROCESS--\n";
  print "#   \$File::Find::dir => '$File::Find::dir' \n";
  foreach $file (@files) {
    print "#   $file \n";
    delete $Expect{$File::Find::dir}->{$file};
  }
  print "# --END PREPROCESS--\n";
  Check(scalar(keys %{$Expect{$File::Find::dir}}) == 0);
  if (scalar(keys %{$Expect{$File::Find::dir}}) == 0) {
    delete $Expect{$File::Find::dir}
  }
  return @files;
}

sub my_postprocess {
  print "# POSTPROCESS: \$File::Find::dir => '$File::Find::dir' \n";
  delete $Expect{$File::Find::dir};
}


if ($^O eq 'MacOS') {

    MkDir( 'for_find',0770 );
    CheckDie(chdir(for_find));

    $cwd = cwd(); # save cwd
    ( $cwd_untainted ) = $cwd =~ m|^(.+)$|; # untaint it

    MkDir( 'fa',0770 );
    MkDir( 'fb',0770  );
    touch(':fb:fb_ord');
    MkDir( ':fb:fba',0770  );
    touch(':fb:fba:fba_ord');
    CheckDie( symlink(':fb',':fa:fsl') ) if $symlink_exists;
    touch(':fa:fa_ord');

    MkDir( ':fa:faa',0770  );
    touch(':fa:faa:faa_ord');	
    MkDir( ':fa:fab',0770  );
    touch(':fa:fab:fab_ord');
    MkDir( ':fa:fab:faba',0770  );
    touch(':fa:fab:faba:faba_ord');

    %Expect = (':' => 1, 'fsl' => 1, 'fa_ord' => 1, 'fab' => 1, 'fab_ord' => 1,
           'faba' => 1, 'faa' => 1, 'faa_ord' => 1);
    delete $Expect{'fsl'} unless $symlink_exists;
    %Expect_Dir = (':' => 1, 'fa' => 1, 'faa' => 1, 'fab' => 1, 'faba' => 1,
                   'fb' => 1, 'fba' => 1);
    delete @Expect_Dir{'fb','fba'} unless $symlink_exists;
    File::Find::find( {wanted => \&wanted, untaint => 1},':fa' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=(':fa' => 1, ':fa:fsl' => 1, ':fa:fa_ord' => 1, ':fa:fab' => 1,
         ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1,
         ':fa:fab:faba:faba_ord' => 1, ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
    delete $Expect{':fa:fsl'} unless $symlink_exists;
    %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                   ':fb' => 1, ':fb:fba' => 1);
    delete @Expect_Dir{':fb',':fb:fba'} unless $symlink_exists;
    File::Find::find( {wanted => \&wanted, no_chdir => 1, untaint => 1},':fa' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=(':' => 1, ':fa' => 1, ':fa:fsl' => 1, ':fa:fa_ord' => 1, ':fa:fab' => 1,
             ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1,
             ':fa:fab:faba:faba_ord' => 1, ':fa:faa' => 1, ':fa:faa:faa_ord' => 1,
             ':fb' => 1, ':fb:fba' => 1, ':fb:fba:fba_ord' => 1, ':fb:fb_ord' => 1);
    delete $Expect{':fa:fsl'} unless $symlink_exists;
    %Expect_Dir = (':' => 1, ':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                   ':fb' => 1, ':fb:fba' => 1);
    delete @Expect_Dir{':fb',':fb:fba'} unless $symlink_exists;
    File::Find::finddepth( {wanted => \&dn_wanted, untaint  => 1 },':' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=(':' => 1, ':fa' => 1, ':fa:fsl' => 1, ':fa:fa_ord' => 1, ':fa:fab' => 1,
             ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1,
             ':fa:fab:faba:faba_ord' => 1, ':fa:faa' => 1, ':fa:faa:faa_ord' => 1,
             ':fb' => 1, ':fb:fba' => 1, ':fb:fba:fba_ord' => 1, ':fb:fb_ord' => 1);
    delete $Expect{':fa:fsl'} unless $symlink_exists;
    %Expect_Dir = (':' => 1, ':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                   ':fb' => 1, ':fb:fba' => 1);
    delete @Expect_Dir{':fb',':fb:fba'} unless $symlink_exists;
    File::Find::finddepth( {wanted => \&d_wanted, no_chdir => 1, untaint => 1 },':' );
    Check( scalar(keys %Expect) == 0 );

    # untaint, preprocess and postprocess tests below added by Thomas Wegner, 17-05-2001

    print "# check untainting (no follow)\n";
    # don't untaint at all
    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted},':fa' );};
    print "# Died: $@";
    Check( $@ =~ m|Insecure dependency| );
    chdir($cwd_untainted);

    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1,
                             untaint_pattern => qr|^(NO_MATCH)$|},':fa' );};
    print "# Died: $@";
    Check( $@ =~ m|is still tainted| );
    chdir($cwd_untainted);

    print "# check untaint_skip (no follow)\n";
    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1, untaint_skip => 1,
                             untaint_pattern => qr|^(NO_MATCH)$|}, ':fa' );};
    print "# Died: $@";
    Check( $@ =~ m|insecure cwd| );
    chdir($cwd_untainted);

    print "# check preprocess\n";
    %Expect=(
              ':' => {fa => 1, fb => 1},
              ':fa:' => {faa => 1, fab => 1, fa_ord => 1},
              ':fa:faa:' => {faa_ord => 1},
              ':fa:fab:' => {faba => 1, fab_ord => 1},
              ':fa:fab:faba:' => {faba_ord => 1},		
              ':fb:' => {fba => 1, fb_ord => 1},
              ':fb:fba:' => {fba_ord => 1}
            );
    File::Find::find( {wanted => \&noop_wanted, untaint => 1, preprocess => \&my_preprocess}, ':' );
    Check( scalar(keys %Expect) == 0 );

    print "# check postprocess\n";
    %Expect=(':' => 1, ':fa:' => 1, ':fa:faa:' => 1, ':fa:fab:' => 1, ':fa:fab:faba:' => 1, ':fb:' => 1,
             ':fb:fba:' => 1 );
    File::Find::find( {wanted => \&noop_wanted, untaint => 1, postprocess => \&my_postprocess}, ':' );
    Check( scalar(keys %Expect) == 0 );

    # Verify that File::Find::find will call wanted even if the topdir of
    #  is a symlink to a directory, and it shouldn't follow the link
    #  unless follow is set, which it isn't in this case
    %Expect = ('fsl' => 1);
    %Expect_Dir = ();
    File::Find::find( {wanted => \&wanted, untaint => 1},':fa:fsl' );
    Check( scalar(keys %Expect) == 0 );

    if ( $symlink_exists ) {
      $FastFileTests_OK= 1;
      %Expect=(':' => 1, 'fa_ord' => 1, 'fsl' => 1, 'fb_ord' => 1, 'fba' => 1,
               'fba_ord' => 1, 'fab' => 1, 'fab_ord' => 1, 'faba' => 1, 'faa' => 1,
               'faa_ord' => 1);
      %Expect_Dir = (':' => 1, 'fa' => 1, 'faa' => 1, 'fab' => 1, 'faba' => 1,
                     'fb' => 1, 'fba' => 1);	
      File::Find::find( {wanted => \&wanted, follow_fast => 1, untaint => 1},':fa' );
      Check( scalar(keys %Expect) == 0 );	

      %Expect=(':fa' => 1, ':fa:fa_ord' => 1, ':fa:fsl' => 1, ':fa:fsl:fb_ord' => 1,
               ':fa:fsl:fba' => 1, ':fa:fsl:fba:fba_ord' => 1, ':fa:fab' => 1,
               ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1, ':fa:fab:faba:faba_ord' => 1,
               ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
      %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                     ':fb' => 1, ':fb:fba' => 1);
      File::Find::find( {wanted => \&wanted, follow_fast => 1, no_chdir => 1, untaint => 1 },':fa' );
      Check( scalar(keys %Expect) == 0 );

      %Expect=(':fa' => 1, ':fa:fa_ord' => 1, ':fa:fsl' => 1, ':fa:fsl:fb_ord' => 1,
               ':fa:fsl:fba' => 1, ':fa:fsl:fba:fba_ord' => 1, ':fa:fab' => 1,
               ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1, ':fa:fab:faba:faba_ord' => 1,
               ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
        %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                       ':fb' => 1, ':fb:fba' => 1);
      File::Find::finddepth( {wanted => \&dn_wanted, follow_fast => 1, untaint => 1 },':fa' );
      Check( scalar(keys %Expect) == 0 );

      %Expect=(':fa' => 1, ':fa:fa_ord' => 1, ':fa:fsl' => 1, ':fa:fsl:fb_ord' => 1,
               ':fa:fsl:fba' => 1, ':fa:fsl:fba:fba_ord' => 1, ':fa:fab' => 1,
               ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1, ':fa:fab:faba:faba_ord' => 1,
               ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
      %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                     ':fb' => 1, ':fb:fba' => 1);
      File::Find::finddepth( {wanted => \&d_wanted, follow_fast => 1, no_chdir => 1, untaint => 1 },':fa' );
      Check( scalar(keys %Expect) == 0 );

      # tests below added by Thomas Wegner, 17-05-2001

      print "# check dangling symbolic links\n";
      MkDir( 'dangling_dir',0770 );
      CheckDie( symlink('dangling_dir','dangling_dir_sl') );
      rmdir 'dangling_dir';
      touch('dangling_file');
      CheckDie( symlink('dangling_file',':fa:dangling_file_sl') );
      unlink 'dangling_file';

      %Expect=(':' => 1, 'fa_ord' => 1, 'fsl' => 1, 'fb_ord' => 1, 'fba' => 1,
               'fba_ord' => 1, 'fab' => 1, 'fab_ord' => 1, 'faba' => 1, 'faba_ord' => 1,
               'faa' => 1, 'faa_ord' => 1);
      %Expect_Dir = (':' => 1, 'fa' => 1, 'faa' => 1, 'fab' => 1, 'faba' => 1,
                     'fb' => 1, 'fba' => 1);
      undef $warn_msg;
      File::Find::find( {wanted => \&d_wanted, follow => 1, untaint => 1 }, 'dangling_dir_sl', ':fa' );
      Check( $warn_msg =~ m|dangling_dir_sl is a dangling symbolic link| );	
      unlink ':fa:dangling_file_sl', 'dangling_dir_sl';

      print "# check recursion\n";
      CheckDie( symlink(':fa:faa',':fa:faa:faa_sl') );
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, no_chdir => 1, untaint => 1 },':fa' ); };
      print "# Died: $@";
      Check( $@ =~ m|:for_find:fa:faa:faa_sl is a recursive symbolic link| );	
      unlink ':fa:faa:faa_sl';

      print "# check follow_skip (file)\n";
      CheckDie( symlink(':fa:fa_ord',':fa:fa_ord_sl') ); # symlink to a file
      undef $@;
      eval {File::Find::finddepth( {wanted => \&simple_wanted, follow => 1,follow_skip => 0,
                                    no_chdir => 1, untaint => 1 },':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|:for_find:fa:fa_ord encountered a second time| );

      %Expect=(':fa' => 1, ':fa:fa_ord' => 1, ':fa:fsl' => 1, ':fa:fsl:fb_ord' => 1,
               ':fa:fsl:fba' => 1, ':fa:fsl:fba:fba_ord' => 1, ':fa:fab' => 1,
               ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1, ':fa:fab:faba:faba_ord' => 1,
               ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
      %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                     ':fb' => 1, ':fb:fba' => 1);	
      File::Find::finddepth( {wanted => \&wanted, follow => 1, follow_skip => 1, no_chdir => 1,
                              untaint => 1 },':fa' );
      Check( scalar(keys %Expect) == 0 );
      unlink ':fa:fa_ord_sl';

      print "# check follow_skip (directory)\n";
      CheckDie( symlink(':fa:faa',':fa:faa_sl') ); # symlink to a directory
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, follow_skip => 0,
                               no_chdir => 1, untaint => 1 },':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|:for_find:fa:faa: encountered a second time| );

      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, follow_skip => 1,
                               no_chdir => 1, untaint => 1 },':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|:for_find:fa:faa: encountered a second time| );	

      %Expect=(':fa' => 1, ':fa:fa_ord' => 1, ':fa:fsl' => 1, ':fa:fsl:fb_ord' => 1,
               ':fa:fsl:fba' => 1, ':fa:fsl:fba:fba_ord' => 1, ':fa:fab' => 1,
               ':fa:fab:fab_ord' => 1, ':fa:fab:faba' => 1, ':fa:fab:faba:faba_ord' => 1,
               ':fa:faa' => 1, ':fa:faa:faa_ord' => 1);
      %Expect_Dir = (':fa' => 1, ':fa:faa' => 1, ':fa:fab' => 1, ':fa:fab:faba' => 1,
                     ':fb' => 1, ':fb:fba' => 1);	
      File::Find::find( {wanted => \&wanted, follow => 1, follow_skip => 2, no_chdir => 1,
                         untaint => 1},':fa' );
      Check( scalar(keys %Expect) == 0 );
      unlink ':fa:faa_sl';

      print "# check untainting (follow)\n";
      # don't untaint at all
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1},':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|Insecure dependency| );
      chdir($cwd_untainted);

      undef $@;	
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, untaint => 1,
                               untaint_pattern => qr|^(NO_MATCH)$|},':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|is still tainted| );
      chdir($cwd_untainted);

      print "# check untaint_skip (follow)\n";
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1, untaint_skip => 1,
                               untaint_pattern => qr|^(NO_MATCH)$|}, ':fa' );};
      print "# Died: $@";
      Check( $@ =~ m|insecure cwd| );
      chdir($cwd_untainted);

    }

} else {

    MkDir( 'for_find',0770 );
    CheckDie(chdir(for_find));

    $cwd = cwd(); # save cwd
    ( $cwd_untainted ) = $cwd =~ m|^(.+)$|; # untaint it

    MkDir( 'fa',0770 );
    MkDir( 'fb',0770  );
    touch('fb/fb_ord');
    MkDir( 'fb/fba',0770  );
    touch('fb/fba/fba_ord');
    CheckDie( symlink('../fb','fa/fsl') ) if $symlink_exists;
    touch('fa/fa_ord');

    MkDir( 'fa/faa',0770  );
    touch('fa/faa/faa_ord');
    MkDir( 'fa/fab',0770  );
    touch('fa/fab/fab_ord');
    MkDir( 'fa/fab/faba',0770  );
    touch('fa/fab/faba/faba_ord');

    %Expect = ('.' => 1, 'fsl' => 1, 'fa_ord' => 1, 'fab' => 1, 'fab_ord' => 1,
           'faba' => 1, 'faa' => 1, 'faa_ord' => 1);
    delete $Expect{'fsl'} unless $symlink_exists;
    %Expect_Dir = ('fa' => 1, 'faa' => 1, 'fab' => 1, 'faba' => 1,
                   'fb' => 1, 'fba' => 1);
    delete @Expect_Dir{'fb','fba'} unless $symlink_exists;
    File::Find::find( {wanted => \&wanted, untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=('fa' => 1, 'fa/fsl' => 1, 'fa/fa_ord' => 1, 'fa/fab' => 1,
         'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1,
         'fa/fab/faba/faba_ord' => 1, 'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
    delete $Expect{'fa/fsl'} unless $symlink_exists;
    %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                   'fb' => 1, 'fb/fba' => 1);
    delete @Expect_Dir{'fb','fb/fba'} unless $symlink_exists;
    File::Find::find( {wanted => \&wanted, no_chdir => 1, untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=('.' => 1, './fa' => 1, './fa/fsl' => 1, './fa/fa_ord' => 1, './fa/fab' => 1,
             './fa/fab/fab_ord' => 1, './fa/fab/faba' => 1,
             './fa/fab/faba/faba_ord' => 1, './fa/faa' => 1, './fa/faa/faa_ord' => 1,
             './fb' => 1, './fb/fba' => 1, './fb/fba/fba_ord' => 1, './fb/fb_ord' => 1);
    delete $Expect{'./fa/fsl'} unless $symlink_exists;
    %Expect_Dir = ('./fa' => 1, './fa/faa' => 1, '/fa/fab' => 1, './fa/fab/faba' => 1,
                   './fb' => 1, './fb/fba' => 1);
    delete @Expect_Dir{'./fb','./fb/fba'} unless $symlink_exists;
    File::Find::finddepth( {wanted => \&dn_wanted , untaint => 1, untaint_pattern => qr|^(.+)$|},'.' );
    Check( scalar(keys %Expect) == 0 );

    %Expect=('.' => 1, './fa' => 1, './fa/fsl' => 1, './fa/fa_ord' => 1, './fa/fab' => 1,
             './fa/fab/fab_ord' => 1, './fa/fab/faba' => 1,
             './fa/fab/faba/faba_ord' => 1, './fa/faa' => 1, './fa/faa/faa_ord' => 1,
             './fb' => 1, './fb/fba' => 1, './fb/fba/fba_ord' => 1, './fb/fb_ord' => 1);
    delete $Expect{'./fa/fsl'} unless $symlink_exists;
    %Expect_Dir = ('./fa' => 1, './fa/faa' => 1, '/fa/fab' => 1, './fa/fab/faba' => 1,
                   './fb' => 1, './fb/fba' => 1);
    delete @Expect_Dir{'./fb','./fb/fba'} unless $symlink_exists;
    File::Find::finddepth( {wanted => \&d_wanted, no_chdir => 1, untaint => 1, untaint_pattern => qr|^(.+)$| },'.' );
    Check( scalar(keys %Expect) == 0 );

    # untaint, preprocess and postprocess tests below added by Thomas Wegner, 17-05-2001

    print "# check untainting (no follow)\n";
    # don't untaint at all
    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted},'fa' );};
    print "# Died: $@";
    Check( $@ =~ m|Insecure dependency| );
    chdir($cwd_untainted);

    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1,
                             untaint_pattern => qr|^(NO_MATCH)$|},'fa' );};
    print "# Died: $@";
    Check( $@ =~ m|is still tainted| );
    chdir($cwd_untainted);

    print "# check untaint_skip (no follow)\n";
    undef $@;
    eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1, untaint_skip => 1,
                             untaint_pattern => qr|^(NO_MATCH)$|}, 'fa' );};
    print "# Died: $@";
    Check( $@ =~ m|insecure cwd| );
    chdir($cwd_untainted);

    print "# check preprocess\n";
    %Expect=(
              '.' => {fa => 1, fb => 1},
              './fa' => {faa => 1, fab => 1, fa_ord => 1},
              './fa/faa' => {faa_ord => 1},
              './fa/fab' => {faba => 1, fab_ord => 1},
              './fa/fab/faba' => {faba_ord => 1},		
              './fb' => {fba => 1, fb_ord => 1},
              './fb/fba' => {fba_ord => 1}
            );

    File::Find::find( {wanted => \&noop_wanted, preprocess => \&my_preprocess, untaint => 1,
                       untaint_pattern => qr|^(.+)$|}, '.' );
    Check( scalar(keys %Expect) == 0 );

    print "# check postprocess\n";
    %Expect=('.' => 1, './fa' => 1, './fa/faa' => 1, './fa/fab' => 1, './fa/fab/faba' => 1, './fb' => 1,
             './fb/fba' => 1 );
    File::Find::find( {wanted => \&noop_wanted, postprocess => \&my_postprocess, untaint => 1,
                       untaint_pattern => qr|^(.+)$|}, '.' );
    Check( scalar(keys %Expect) == 0 );

    # Verify that File::Find::find will call wanted even if the topdir of
    #  is a symlink to a directory, and it shouldn't follow the link
    #  unless follow is set, which it isn't in this case
    %Expect = ('fsl' => 1);
    %Expect_Dir = ();
    File::Find::find( {wanted => \&wanted, untaint => 1},'fa/fsl' );
    Check( scalar(keys %Expect) == 0 );

    if ( $symlink_exists ) {
      $FastFileTests_OK= 1;
      %Expect=('.' => 1, 'fa_ord' => 1, 'fsl' => 1, 'fb_ord' => 1, 'fba' => 1,
               'fba_ord' => 1, 'fab' => 1, 'fab_ord' => 1, 'faba' => 1, 'faa' => 1,
               'faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);
      File::Find::find( {wanted => \&wanted, follow_fast => 1, untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );

      %Expect=('fa' => 1, 'fa/fa_ord' => 1, 'fa/fsl' => 1, 'fa/fsl/fb_ord' => 1,
               'fa/fsl/fba' => 1, 'fa/fsl/fba/fba_ord' => 1, 'fa/fab' => 1,
               'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1, 'fa/fab/faba/faba_ord' => 1,
               'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);
      File::Find::find( {wanted => \&wanted, follow_fast => 1, no_chdir => 1, untaint => 1,
                         untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );

      %Expect=('fa' => 1, 'fa/fa_ord' => 1, 'fa/fsl' => 1, 'fa/fsl/fb_ord' => 1,
               'fa/fsl/fba' => 1, 'fa/fsl/fba/fba_ord' => 1, 'fa/fab' => 1,
               'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1, 'fa/fab/faba/faba_ord' => 1,
               'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);					
      File::Find::finddepth( {wanted => \&dn_wanted, follow_fast => 1, untaint => 1,
                              untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );

      %Expect=('fa' => 1, 'fa/fa_ord' => 1, 'fa/fsl' => 1, 'fa/fsl/fb_ord' => 1,
               'fa/fsl/fba' => 1, 'fa/fsl/fba/fba_ord' => 1, 'fa/fab' => 1,
               'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1, 'fa/fab/faba/faba_ord' => 1,
               'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);
      File::Find::finddepth( {wanted => \&d_wanted, follow_fast => 1, no_chdir => 1,
                              untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );

      # tests below added by Thomas Wegner, 17-05-2001

      print "# check dangling symbolic links\n";
      MkDir( 'dangling_dir',0770 );
      CheckDie( symlink('dangling_dir','dangling_dir_sl') );
      rmdir 'dangling_dir';
      touch('dangling_file');
      CheckDie( symlink('../dangling_file','fa/dangling_file_sl') );
      unlink 'dangling_file';

      %Expect=('.' => 1, 'fa_ord' => 1, 'fsl' => 1, 'fb_ord' => 1, 'fba' => 1,
               'fba_ord' => 1, 'fab' => 1, 'fab_ord' => 1, 'faba' => 1, 'faba_ord' => 1,
               'faa' => 1, 'faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, 'fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);
      undef $warn_msg;
      File::Find::find( {wanted => \&d_wanted, follow => 1, untaint => 1,
                         untaint_pattern => qr|^(.+)$|}, 'dangling_dir_sl', 'fa' );
      Check( $warn_msg =~ m|dangling_dir_sl is a dangling symbolic link| );	
      unlink 'fa/dangling_file_sl', 'dangling_dir_sl';

      print "# check recursion\n";
      CheckDie( symlink('../faa','fa/faa/faa_sl') );
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, no_chdir => 1,
                               untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' ); };
      print "# Died: $@";
      Check( $@ =~ m|for_find/fa/faa/faa_sl is a recursive symbolic link| );	
      unlink 'fa/faa/faa_sl';

      print "# check follow_skip (file)\n";
      CheckDie( symlink('./fa_ord','fa/fa_ord_sl') ); # symlink to a file
      undef $@;
      eval {File::Find::finddepth( {wanted => \&simple_wanted, follow => 1, follow_skip => 0, no_chdir => 1,
                                    untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|for_find/fa/fa_ord encountered a second time| );

      %Expect=('fa' => 1, 'fa/fa_ord' => 1, 'fa/fsl' => 1, 'fa/fsl/fb_ord' => 1,
               'fa/fsl/fba' => 1, 'fa/fsl/fba/fba_ord' => 1, 'fa/fab' => 1,
               'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1, 'fa/fab/faba/faba_ord' => 1,
               'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);
      File::Find::finddepth( {wanted => \&wanted, follow => 1, follow_skip => 1, no_chdir => 1,
                              untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );
      unlink 'fa/fa_ord_sl';

      print "# check follow_skip (directory)\n";
      CheckDie( symlink('./faa','fa/faa_sl') ); # symlink to a directory
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, follow_skip => 0, no_chdir => 1,
                               untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|for_find/fa/faa encountered a second time| );

      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, follow_skip => 1, no_chdir => 1,
                               untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|for_find/fa/faa encountered a second time| );

      %Expect=('fa' => 1, 'fa/fa_ord' => 1, 'fa/fsl' => 1, 'fa/fsl/fb_ord' => 1,
               'fa/fsl/fba' => 1, 'fa/fsl/fba/fba_ord' => 1, 'fa/fab' => 1,
               'fa/fab/fab_ord' => 1, 'fa/fab/faba' => 1, 'fa/fab/faba/faba_ord' => 1,
               'fa/faa' => 1, 'fa/faa/faa_ord' => 1);
      %Expect_Dir = ('fa' => 1, 'fa/faa' => 1, '/fa/fab' => 1, 'fa/fab/faba' => 1,
                     'fb' => 1, 'fb/fba' => 1);		
      File::Find::find( {wanted => \&wanted, follow => 1, follow_skip => 2, no_chdir => 1,
                         untaint => 1, untaint_pattern => qr|^(.+)$|},'fa' );
      Check( scalar(keys %Expect) == 0 );
      unlink 'fa/faa_sl';

      print "# check untainting (follow)\n";
      # don't untaint at all
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1},'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|Insecure dependency| );
      chdir($cwd_untainted);

      undef $@;	
      eval {File::Find::find( {wanted => \&simple_wanted, follow => 1, untaint => 1,
                               untaint_pattern => qr|^(NO_MATCH)$|},'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|is still tainted| );
      chdir($cwd_untainted);

      print "# check untaint_skip (follow)\n";
      undef $@;
      eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1, untaint_skip => 1,
                               untaint_pattern => qr|^(NO_MATCH)$|}, 'fa' );};
      print "# Died: $@";
      Check( $@ =~ m|insecure cwd| );
      chdir($cwd_untainted);

    }
}

print "# of cases: $case\n";
