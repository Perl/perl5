package ExtUtils::Liblist;

# Broken out of MakeMaker from version 4.11

use Config;
use Cwd;
use File::Basename;

my $Config_libext = $Config{lib_ext} || ".a";

# --- Determine libraries to use and how to use them ---

sub ext {
    my($potential_libs, $Verbose) = @_;
    return ("", "", "", "") unless $potential_libs;
    print STDOUT "Potential libraries are '$potential_libs':\n" if $Verbose;

    my($so)   = $Config{'so'};
    my($libs) = $Config{'libs'};

    # compute $extralibs, $bsloadlibs and $ldloadlibs from
    # $potential_libs
    # this is a rewrite of Andy Dougherty's extliblist in perl
    # its home is in <distribution>/ext/util

    my(@searchpath); # from "-L/path" entries in $potential_libs
    my(@libpath) = split " ", $Config{'libpth'};
    my(@ldloadlibs, @bsloadlibs, @extralibs, @ld_run_path, %ld_run_path_seen);
    my($fullname, $thislib, $thispth, @fullname);
    my($pwd) = fastcwd(); # from Cwd.pm
    my($found) = 0;

    foreach $thislib (split ' ', $potential_libs){

	# Handle possible linker path arguments.
	if ($thislib =~ s/^(-[LR])//){	# save path flag type
	    my($ptype) = $1;
	    unless (-d $thislib){
		print STDOUT "$ptype$thislib ignored, directory does not exist\n"
			if $Verbose;
		next;
	    }
	    if ($thislib !~ m|^/|) {
	      print STDOUT "Warning: $ptype$thislib changed to $ptype$pwd/$thislib\n";
	      $thislib = "$pwd/$thislib";
	    }
	    push(@searchpath, $thislib);
	    push(@extralibs,  "$ptype$thislib");
	    push(@ldloadlibs, "$ptype$thislib");
	    next;
	}

	# Handle possible library arguments.
	unless ($thislib =~ s/^-l//){
	  print STDOUT "Unrecognized argument in LIBS ignored: '$thislib'\n";
	  next;
	}

	my($found_lib)=0;
	foreach $thispth (@searchpath, @libpath){

		# Try to find the full name of the library.  We need this to
		# determine whether it's a dynamically-loadable library or not.
		# This tends to be subject to various os-specific quirks.
		# For gcc-2.6.2 on linux (March 1995), DLD can not load
		# .sa libraries, with the exception of libm.sa, so we
		# deliberately skip them.
	    if (@fullname = lsdir($thispth,"^lib$thislib\.$so\.[0-9]+")){
		# Take care that libfoo.so.10 wins against libfoo.so.9.
		# Compare two libraries to find the most recent version
		# number.  E.g.  if you have libfoo.so.9.0.7 and
		# libfoo.so.10.1, first convert all digits into two
		# decimal places.  Then we'll add ".00" to the shorter
		# strings so that we're comparing strings of equal length
		# Thus we'll compare libfoo.so.09.07.00 with
		# libfoo.so.10.01.00.  Some libraries might have letters
		# in the version.  We don't know what they mean, but will
		# try to skip them gracefully -- we'll set any letter to
		# '0'.  Finally, sort in reverse so we can take the
		# first element.

		#TODO: iterate through the directory instead of sorting

		$fullname = "$thispth/" .
		(sort { my($ma) = $a;
			my($mb) = $b;
			$ma =~ tr/A-Za-z/0/s;
			$ma =~ s/\b(\d)\b/0$1/g;
			$mb =~ tr/A-Za-z/0/s;
			$mb =~ s/\b(\d)\b/0$1/g;
			while (length($ma) < length($mb)) { $ma .= ".00"; }
			while (length($mb) < length($ma)) { $mb .= ".00"; }
			# Comparison deliberately backwards
			$mb cmp $ma;} @fullname)[0];
	    } elsif (-f ($fullname="$thispth/lib$thislib.$so")
		 && (($Config{'dlsrc'} ne "dl_dld.xs") || ($thislib eq "m"))){
	    } elsif (-f ($fullname="$thispth/lib${thislib}_s$Config_libext")
		 && ($thislib .= "_s") ){ # we must explicitly use _s version
	    } elsif (-f ($fullname="$thispth/lib$thislib$Config_libext")){
	    } elsif (-f ($fullname="$thispth/Slib$thislib$Config_libext")){
	    } else {
		print STDOUT "$thislib not found in $thispth\n" if $Verbose;
		next;
	    }
	    print STDOUT "'-l$thislib' found at $fullname\n" if $Verbose;
	    my($fullnamedir) = dirname($fullname);
	    push @ld_run_path, $fullnamedir unless $ld_run_path_seen{$fullnamedir}++;
	    $found++;
	    $found_lib++;

	    # Now update library lists

	    # what do we know about this library...
	    my $is_dyna = ($fullname !~ /\Q$Config_libext\E$/);
	    my $in_perl = ($libs =~ /\B-l${thislib}\b/s);

	    # Do not add it into the list if it is already linked in
	    # with the main perl executable.
	    # We have to special-case the NeXT, because all the math 
	    # is also in libsys_s
	    unless ($in_perl || 
		    ($Config{'osname'} eq 'next' && $thislib eq 'm') ){
		push(@extralibs, "-l$thislib");
	    }

	    # We might be able to load this archive file dynamically
	    if ( $Config{'dlsrc'} =~ /dl_next|dl_dld/){
		# We push -l$thislib instead of $fullname because
		# it avoids hardwiring a fixed path into the .bs file.
		# Mkbootstrap will automatically add dl_findfile() to
		# the .bs file if it sees a name in the -l format.
		# USE THIS, when dl_findfile() is fixed: 
		# push(@bsloadlibs, "-l$thislib");
		# OLD USE WAS while checking results against old_extliblist
		push(@bsloadlibs, "$fullname");
	    } else {
		if ($is_dyna){
                    # For SunOS4, do not add in this shared library if
                    # it is already linked in the main perl executable
		    push(@ldloadlibs, "-l$thislib")
			unless ($in_perl and $Config{'osname'} eq 'sunos');
		} else {
		    push(@ldloadlibs, "-l$thislib");
		}
	    }
	    last;	# found one here so don't bother looking further
	}
	print STDOUT "Warning (non-fatal): No library found for -l$thislib\n"
	    unless $found_lib>0;
    }
    return ('','','','') unless $found;
    ("@extralibs", "@bsloadlibs", "@ldloadlibs",join(":",@ld_run_path));
}

sub lsdir { #yes, duplicate code seems less hassle than having an
            #extra file with only lsdir
    my($dir, $regex) = @_;
    local(*DIR, @ls);
    opendir(DIR, $dir || ".") or return ();
    @ls = readdir(DIR);
    closedir(DIR);
    @ls = grep(/$regex/, @ls) if $regex;
    @ls;
}

1;
