package DynaLoader;

#
#   And Gandalf said: 'Many folk like to know beforehand what is to
#   be set on the table; but those who have laboured to prepare the
#   feast like to keep their secret; for wonder makes the words of
#   praise louder.'
#

# Quote from Tolkien sugested by Anno Siegel.
#
# Read ext/DynaLoader/README and DynaLoader.doc for
# detailed information.
#
# Tim.Bunce@ig.co.uk, August 1994

use Config;
use Carp;
use AutoLoader;

@ISA=qw(AutoLoader);


# enable messages from DynaLoader perl code
$dl_debug = 0 unless $dl_debug;
$dl_debug = $ENV{'PERL_DL_DEBUG'} if $ENV{'PERL_DL_DEBUG'};

$dl_so = $dl_dlext = ""; # avoid typo warnings
$dl_so = $Config{'so'}; # suffix for shared libraries
$dl_dlext = $Config{'dlext'}; # suffix for dynamic modules

# Some systems need special handling to expand file specifications
# (VMS support by Charles Bailey <bailey@HMIVAX.HUMGEN.UPENN.EDU>)
# See dl_expandspec() for more details. Should be harmless but
# inefficient to define on systems that don't need it.
$do_expand = ($Config{'osname'} eq 'VMS');

@dl_require_symbols = ();       # names of symbols we need
@dl_resolve_using   = ();       # names of files to link with
@dl_library_path    = ();       # path to look for files

# This is a fix to support DLD's unfortunate desire to relink -lc
@dl_resolve_using = dl_findfile('-lc') if $Config{'dlsrc'} eq "dl_dld.xs";

# Initialise @dl_library_path with the 'standard' library path
# for this platform as determined by Configure
push(@dl_library_path, split(' ',$Config{'libpth'}));

# Add to @dl_library_path any extra directories we can gather from
# environment variables. So far LD_LIBRARY_PATH is the only known
# variable used for this purpose. Others may be added later.
push(@dl_library_path, split(/:/, $ENV{'LD_LIBRARY_PATH'}))
    if $ENV{'LD_LIBRARY_PATH'};


# No prizes for guessing why we don't say 'bootstrap DynaLoader;' here.
boot_DynaLoader() if defined(&boot_DynaLoader);


if ($dl_debug){
	print STDERR "DynaLoader.pm loaded (@dl_library_path)\n";
	print STDERR "DynaLoader not linked into this perl\n"
		unless defined(&boot_DynaLoader);
}

1; # End of main code


# The bootstrap function cannot be autoloaded (without complications)
# so we define it here:

sub bootstrap {
    # use local vars to enable $module.bs script to edit values
    local(@args) = @_;
    local($module) = $args[0];
    local(@dirs, $file);

    croak "Usage: DynaLoader::bootstrap(module)"
	unless ($module);

    croak "Can't load module $module, dynamic loading not available in this perl"
	unless defined(&dl_load_file);

    print STDERR "DynaLoader::bootstrap($module)\n" if $dl_debug;

    my(@modparts) = split(/::/,$module);
    my($modfname) = $modparts[-1];
    my($modpname) = join('/',@modparts);
    foreach (@INC) {
	my $dir = "$_/auto/$modpname";
	next unless -d $dir; # skip over uninteresting directories

	# check for common cases to avoid autoload of dl_findfile
	last if ($file=_check_file("$dir/$modfname.$dl_dlext"));

	# no luck here, save dir for possible later dl_findfile search
	push(@dirs, "-L$dir");
    }
    # last resort, let dl_findfile have a go in all known locations
    $file = dl_findfile(@dirs, map("-L$_",@INC), $modfname) unless $file;

    croak "Can't find loadable object for module $module in \@INC"
        unless $file;

    my($bootname) = "boot_$module";
    $bootname =~ s/\W/_/g;
    @dl_require_symbols = ($bootname);

    # Execute optional '.bootstrap' perl script for this module.
    # The .bs file can be used to configure @dl_resolve_using etc to
    # match the needs of the individual module on this architecture.
    my $bs = $file;
    $bs =~ s/(\.\w+)?$/\.bs/; # look for .bs 'beside' the library
    if (-s $bs) { # only read file if it's not empty
        local($osname, $dlsrc) = @Config{'osname','dlsrc'};
        print STDERR "BS: $bs ($osname, $dlsrc)\n" if $dl_debug;
        eval { do $bs; };
        warn "$bs: $@\n" if $@;
    }

    # Many dynamic extension loading problems will appear to come from
    # this section of code: XYZ failed at line 123 of DynaLoader.pm.
    # Often these errors are actually occurring in the initialisation
    # C code of the extension XS file. Perl reports the error as being
    # in this perl code simply because this was the last perl code
    # it executed.

    my $libref = dl_load_file($file) or
	croak "Can't load '$file' for module $module: ".dl_error()."\n";

    my(@unresolved) = dl_undef_symbols();
    carp "Undefined symbols present after loading $file: @unresolved\n"
        if (@unresolved);

    my $boot_symbol_ref = dl_find_symbol($libref, $bootname) or
         croak "Can't find '$bootname' symbol in $file\n";

    dl_install_xsub("${module}::bootstrap", $boot_symbol_ref, $file);

    # See comment block above
    &{"${module}::bootstrap"}(@args);
}


sub _check_file{   # private utility to handle dl_expandspec vs -f tests
    my($file) = @_;
    return $file if (!$do_expand && -f $file); # the common case
    return $file if ( $do_expand && ($file=dl_expandspec($file)));
    return undef;
}


# Let autosplit and the autoloader deal with these functions:
__END__


sub dl_findfile {
    # Read ext/DynaLoader/DynaLoader.doc for detailed information.
    # This function does not automatically consider the architecture
    # or the perl library auto directories.
    my (@args) = @_;
    my (@dirs,  $dir);   # which directories to search
    my (@found);         # full paths to real files we have found
    my ($vms) = ($Config{'osname'} eq 'VMS');

    print STDERR "dl_findfile(@args)\n" if $dl_debug;

    # accumulate directories but process files as they appear
    arg: foreach(@args) {
        #  Special fast case: full filepath requires no search
        if (m:/: && -f $_ && !$do_expand){
	    push(@found,$_);
	    last arg unless wantarray;
	    next;
	}

        # Deal with directories first:
        #  Using a -L prefix is the preferred option (faster and more robust)
        if (m:^-L:){ s/^-L//; push(@dirs, $_); next; }
        #  Otherwise we try to try to spot directories by a heuristic
        #  (this is a more complicated issue than it first appears)
        if (m:/: && -d $_){   push(@dirs, $_); next; }
        # VMS: we may be using native VMS directry syntax instead of
        # Unix emulation, so check this as well
        if ($vms && /[:>\]]/ && -d $_){   push(@dirs, $_); next; }

        #  Only files should get this far...
        my(@names, $name);    # what filenames to look for
        if (m:-l: ){          # convert -lname to appropriate library name
            s/-l//;
            push(@names,"lib$_.$dl_so");
            push(@names,"lib$_.a");
        }else{                # Umm, a bare name. Try various alternatives:
            # these should be ordered with the most likely first
            push(@names,"$_.$dl_so")     unless m/\.$dl_so$/o;
            push(@names,"lib$_.$dl_so")  unless m:/:;
            push(@names,"$_.o")          unless m/\.(o|$dl_so)$/o;
            push(@names,"$_.a")          unless m/\.a$/;
            push(@names, $_);
        }
        foreach $dir (@dirs, @dl_library_path) {
            next unless -d $dir;
            foreach $name (@names) {
		my($file) = "$dir/$name";
                print STDERR " checking in $dir for $name\n" if $dl_debug;
		$file = _check_file($file);
		if ($file){
                    push(@found, $file);
                    next arg; # no need to look any further
                }
            }
        }
    }
    if ($dl_debug) {
        foreach(@dirs) {
            print STDERR " dl_findfile ignored non-existent directory: $_\n" unless -d $_;
        }
        print STDERR "dl_findfile found: @found\n";
    }
    return $found[0] unless wantarray;
    @found;
}


sub dl_expandspec{
    my($spec) = @_;
    # Optional function invoked if DynaLoader.pm sets $do_expand.
    # Most systems do not require or use this function.
    # Some systems may implement it in the dl_*.xs file in which case
    # this autoload version will not be called but is harmless.

    # This function is designed to deal with systems which treat some
    # 'filenames' in a special way. For example VMS 'Logical Names'
    # (something like unix environment variables - but different).
    # This function should recognise such names and expand them into
    # full file paths.
    # Must return undef if $spec is invalid or file does not exist.

    my($file)   = $spec; # default output to input
    my($osname) = $Config{'osname'};

    if ($osname eq 'VMS'){ # dl_expandspec should be defined in dl_vms.xs
	croak "dl_expandspec: should be defined in XS file!\n";
    }else{
	return undef unless -f $file;
    }
    print STDERR "dl_expandspec($spec) => $file\n" if $dl_debug;
    $file;
}
