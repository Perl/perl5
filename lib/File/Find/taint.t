#!./perl -T


my %Expect_File = (); # what we expect for $_ 
my %Expect_Name = (); # what we expect for $File::Find::name/fullname
my %Expect_Dir  = (); # what we expect for $File::Find::dir
my $symlink_exists = eval { symlink("",""); 1 };
my $cwd;
my $cwd_untainted;

use Config;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';

    for (keys %ENV) { # untaint ENV
	($ENV{$_}) = $ENV{$_} =~ /(.*)/;
    }

    # Remove insecure directories from PATH
    my @path;
    my $sep = $Config{path_sep};
    foreach my $dir (split(/\Q$sep/,$ENV{'PATH'}))
    {
	##
	## Match the directory taint tests in mg.c::Perl_magic_setenv()
	##
	push(@path,$dir) unless (length($dir) >= 256
				 or
				 substr($dir,0,1) ne "/"
				 or
				 (stat $dir)[2] & 002);
    }
    $ENV{'PATH'} = join($sep,@path);
}


if ( $symlink_exists ) { print "1..45\n"; }
else                   { print "1..27\n";  }

use File::Find;
use File::Spec;
use Cwd;


my $NonTaintedCwd = $^O eq 'MSWin32' || $^O eq 'cygwin';

cleanup();

find({wanted => sub { print "ok 1\n" if $_ eq 'commonsense.t'; },
      untaint => 1, untaint_pattern => qr|^(.+)$|}, File::Spec->curdir);

finddepth({wanted => sub { print "ok 2\n" if $_ eq 'commonsense.t'; },
           untaint => 1, untaint_pattern => qr|^(.+)$|},
           File::Spec->curdir);

my $case = 2;
my $FastFileTests_OK = 0;

sub cleanup {
    if (-d dir_path('for_find')) {
        chdir(dir_path('for_find'));
    }
    if (-d dir_path('fa')) {
        unlink file_path('fa', 'fa_ord'),
               file_path('fa', 'fsl'),
               file_path('fa', 'faa', 'faa_ord'),
               file_path('fa', 'fab', 'fab_ord'),
               file_path('fa', 'fab', 'faba', 'faba_ord'),
               file_path('fb', 'fb_ord'),
               file_path('fb', 'fba', 'fba_ord');
        rmdir dir_path('fa', 'faa');
        rmdir dir_path('fa', 'fab', 'faba');
        rmdir dir_path('fa', 'fab');
        rmdir dir_path('fa');
        rmdir dir_path('fb', 'fba');
        rmdir dir_path('fb');
        chdir File::Spec->updir;
        rmdir dir_path('for_find');
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
    else       { print "not ok $case\n"; exit 0; }
}

sub Skip($) {
    $case++;
    print "ok $case # skipped: ",$_[0],"\n"; 
}

sub touch {
    CheckDie( open(my $T,'>',$_[0]) );
}

sub MkDir($$) {
    CheckDie( mkdir($_[0],$_[1]) );
}

sub wanted_File_Dir {
    print "# \$File::Find::dir => '$File::Find::dir'\n";
    print "# \$_ => '$_'\n";
    s#\.$## if ($^O eq 'VMS' && $_ ne '.');
    Check( $Expect_File{$_} );
    if ( $FastFileTests_OK ) {
        delete $Expect_File{ $_} 
          unless ( $Expect_Dir{$_} && ! -d _ );
    } else {
        delete $Expect_File{$_} 
          unless ( $Expect_Dir{$_} && ! -d $_ );
    }
}

sub wanted_File_Dir_prune {
    &wanted_File_Dir;
    $File::Find::prune=1 if  $_ eq 'faba';
}


sub simple_wanted {
    print "# \$File::Find::dir => '$File::Find::dir'\n";
    print "# \$_ => '$_'\n";
}


# Use dir_path() to specify a directory path that's expected for
# $File::Find::dir (%Expect_Dir). Also use it in file operations like
# chdir, rmdir etc.
#
# dir_path() concatenates directory names to form a _relative_
# directory path, independant from the platform it's run on, although
# there are limitations.  Don't try to create an absolute path,
# because that may fail on operating systems that have the concept of
# volume names (e.g. Mac OS). Be careful when you want to create an
# updir path like ../fa (Unix) or ::fa: (Mac OS). Plain directory
# names will work best. As a special case, you can pass it a "." as
# first argument, to create a directory path like "./fa/dir" on
# operating systems other than Mac OS (actually, Mac OS will ignore
# the ".", if it's the first argument). If there's no second argument,
# this function will return the empty string on Mac OS and the string
# "./" otherwise.

sub dir_path {
    my $first_item = shift @_;

    if ($first_item eq '.') {
        if ($^O eq 'MacOS') {
            return '' unless @_;
            # ignore first argument; return a relative path
            # with leading ":" and with trailing ":"
            return File::Spec->catdir("", @_); 
        } else { # other OS
            return './' unless @_;
            my $path = File::Spec->catdir(@_);
            # add leading "./"
            $path = "./$path";
            return $path;
        }

    } else { # $first_item ne '.'
        return $first_item unless @_; # return plain filename
        if ($^O eq 'MacOS') {
            # relative path with leading ":" and with trailing ":"
            return File::Spec->catdir("", $first_item, @_);
        } else { # other OS
            return File::Spec->catdir($first_item, @_);
        }
    }
}


# Use topdir() to specify a directory path that you want to pass to
#find/finddepth Basically, topdir() does the same as dir_path() (see
#above), except that there's no trailing ":" on Mac OS.

sub topdir {
    my $path = dir_path(@_);
    $path =~ s/:$// if ($^O eq 'MacOS');
    return $path;
}


# Use file_path() to specify a file path that's expected for $_ (%Expect_File).
# Also suitable for file operations like unlink etc.

# file_path() concatenates directory names (if any) and a filename to
# form a _relative_ file path (the last argument is assumed to be a
# file). It's independant from the platform it's run on, although
# there are limitations (see the warnings for dir_path() above). As a
# special case, you can pass it a "." as first argument, to create a
# file path like "./fa/file" on operating systems other than Mac OS
# (actually, Mac OS will ignore the ".", if it's the first
# argument). If there's no second argument, this function will return
# the empty string on Mac OS and the string "./" otherwise.

sub file_path {
    my $first_item = shift @_;

    if ($first_item eq '.') {
        if ($^O eq 'MacOS') {
            return '' unless @_;
            # ignore first argument; return a relative path  
            # with leading ":", but without trailing ":"
            return File::Spec->catfile("", @_); 
        } else { # other OS
            return './' unless @_;
            my $path = File::Spec->catfile(@_);
            # add leading "./" 
            $path = "./$path"; 
            return $path;
        }

    } else { # $first_item ne '.'
        return $first_item unless @_; # return plain filename
        if ($^O eq 'MacOS') {
            # relative path with leading ":", but without trailing ":"
            return File::Spec->catfile("", $first_item, @_);
        } else { # other OS
            return File::Spec->catfile($first_item, @_);
        }
    }
}


# Use file_path_name() to specify a file path that's expected for
# $File::Find::Name (%Expect_Name). Note: When the no_chdir => 1
# option is in effect, $_ is the same as $File::Find::Name. In that
# case, also use this function to specify a file path that's expected
# for $_.
#
# Basically, file_path_name() does the same as file_path() (see
# above), except that there's always a leading ":" on Mac OS, even for
# plain file/directory names.

sub file_path_name {
    my $path = file_path(@_);
    $path = ":$path" if (($^O eq 'MacOS') && ($path !~ /:/));
    return $path;
}



MkDir( dir_path('for_find'), 0770 );
CheckDie(chdir( dir_path('for_find')));

$cwd = cwd(); # save cwd
( $cwd_untainted ) = $cwd =~ m|^(.+)$|; # untaint it

MkDir( dir_path('fa'), 0770 );
MkDir( dir_path('fb'), 0770  );
touch( file_path('fb', 'fb_ord') );
MkDir( dir_path('fb', 'fba'), 0770  );
touch( file_path('fb', 'fba', 'fba_ord') );
if ($^O eq 'MacOS') {
      CheckDie( symlink(':fb',':fa:fsl') ) if $symlink_exists;
} else {
      CheckDie( symlink('../fb','fa/fsl') ) if $symlink_exists;
}
touch( file_path('fa', 'fa_ord') );

MkDir( dir_path('fa', 'faa'), 0770  );
touch( file_path('fa', 'faa', 'faa_ord') );
MkDir( dir_path('fa', 'fab'), 0770  );
touch( file_path('fa', 'fab', 'fab_ord') );
MkDir( dir_path('fa', 'fab', 'faba'), 0770  );
touch( file_path('fa', 'fab', 'faba', 'faba_ord') );

print "# check untainting (no follow)\n";

# untainting here should work correctly

%Expect_File = (File::Spec->curdir => 1, file_path('fsl') =>
                1,file_path('fa_ord') => 1, file_path('fab') => 1,
                file_path('fab_ord') => 1, file_path('faba') => 1,
                file_path('faa') => 1, file_path('faa_ord') => 1);
delete $Expect_File{ file_path('fsl') } unless $symlink_exists;
%Expect_Name = ();

%Expect_Dir = ( dir_path('fa') => 1, dir_path('faa') => 1,
                dir_path('fab') => 1, dir_path('faba') => 1,
                dir_path('fb') => 1, dir_path('fba') => 1);

delete @Expect_Dir{ dir_path('fb'), dir_path('fba') } unless $symlink_exists;

File::Find::find( {wanted => \&wanted_File_Dir_prune, untaint => 1,
		   untaint_pattern => qr|^(.+)$|}, topdir('fa') );

Check( scalar(keys %Expect_File) == 0 );


# don't untaint at all, should die
%Expect_File = ();
%Expect_Name = ();
%Expect_Dir  = ();
undef $@;
eval {File::Find::find( {wanted => \&simple_wanted}, topdir('fa') );};
Check( $@ =~ m|Insecure dependency| );
chdir($cwd_untainted);


# untaint pattern doesn't match, should die 
undef $@;

eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1,
                         untaint_pattern => qr|^(NO_MATCH)$|},
                         topdir('fa') );};

Check( $@ =~ m|is still tainted| );
chdir($cwd_untainted);


# untaint pattern doesn't match, should die when we chdir to cwd   
print "# check untaint_skip (No follow)\n";
undef $@;

eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1,
                         untaint_skip => 1, untaint_pattern =>
                         qr|^(NO_MATCH)$|}, topdir('fa') );};

print "# $@" if $@;
#$^D = 8;
if ($NonTaintedCwd) {
	Skip("$^O does not taint cwd");
    } 
else {
	Check( $@ =~ m|insecure cwd| );
}
chdir($cwd_untainted);


if ( $symlink_exists ) {
    print "# --- symbolic link tests --- \n";
    $FastFileTests_OK= 1;

    print "# check untainting (follow)\n";

    # untainting here should work correctly
    # no_chdir is in effect, hence we use file_path_name to specify the expected paths for %Expect_File

    %Expect_File = (file_path_name('fa') => 1,
		    file_path_name('fa','fa_ord') => 1,
		    file_path_name('fa', 'fsl') => 1,
                    file_path_name('fa', 'fsl', 'fb_ord') => 1,
                    file_path_name('fa', 'fsl', 'fba') => 1,
                    file_path_name('fa', 'fsl', 'fba', 'fba_ord') => 1,
                    file_path_name('fa', 'fab') => 1,
                    file_path_name('fa', 'fab', 'fab_ord') => 1,
                    file_path_name('fa', 'fab', 'faba') => 1,
                    file_path_name('fa', 'fab', 'faba', 'faba_ord') => 1,
                    file_path_name('fa', 'faa') => 1,
                    file_path_name('fa', 'faa', 'faa_ord') => 1);

    %Expect_Name = ();

    %Expect_Dir = (dir_path('fa') => 1,
		   dir_path('fa', 'faa') => 1,
                   dir_path('fa', 'fab') => 1,
		   dir_path('fa', 'fab', 'faba') => 1,
		   dir_path('fb') => 1,
		   dir_path('fb', 'fba') => 1);

    File::Find::find( {wanted => \&wanted_File_Dir, follow_fast => 1,
                       no_chdir => 1, untaint => 1, untaint_pattern =>
                       qr|^(.+)$| }, topdir('fa') );

    Check( scalar(keys %Expect_File) == 0 );
 
    
    # don't untaint at all, should die
    undef $@;

    eval {File::Find::find( {wanted => \&simple_wanted, follow => 1},
			    topdir('fa') );};

    Check( $@ =~ m|Insecure dependency| );
    chdir($cwd_untainted);

    # untaint pattern doesn't match, should die
    undef $@;

    eval {File::Find::find( {wanted => \&simple_wanted, follow => 1,
                             untaint => 1, untaint_pattern =>
                             qr|^(NO_MATCH)$|}, topdir('fa') );};

    Check( $@ =~ m|is still tainted| );
    chdir($cwd_untainted);

    # untaint pattern doesn't match, should die when we chdir to cwd
    print "# check untaint_skip (Follow)\n";
    undef $@;

    eval {File::Find::find( {wanted => \&simple_wanted, untaint => 1,
                             untaint_skip => 1, untaint_pattern =>
                             qr|^(NO_MATCH)$|}, topdir('fa') );};
    if ($NonTaintedCwd) {
	Skip("$^O does not taint cwd");
    } 
    else {
	Check( $@ =~ m|insecure cwd| );
    }
    chdir($cwd_untainted);
} 

