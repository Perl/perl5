# This file fills in a config_h.SH template based on the data
# of the file config.def and outputs a config.sh.

if (open(CONFIG_DEF, "config.def")) {
    while (<CONFIG_DEF>) {
	if (/^([^=]+)='(.+)'$/) {
	    my ($var, $val) = ($1, $2);
	    $define{$var} = $val;
	} else {
	    warn "config.def: $.: illegal line: $_";
	}
    }
} else {
    die "$0: Cannot open config.def: $!";
}

if (open(CONFIG_SH, "config_h.SH_orig")) {
    while (<CONFIG_SH>) {
	last if /^sed <<!GROK!THIS!/;
    }
    while (<CONFIG_SH>) {
	last if /^!GROK!THIS!/;
	s/\\\$Id:/\$Id:/;
	s/\$package/perl5/;
	s/\$cf_time/localtime/e;
	s/\$myuname/$define{OSNAME}/;
        s/\$seedfunc/$define{seedfunc}/;
	if (/^#\$\w+\s+(\w+)/) {
	    if (exists $define{$1}) {
		if ($define{$1} eq 'define') {
		    print "#define $1\t/**/\n";
		} else {
		    print "#define $1 $define{$1}\n";
		}
	    } else {
		print "/*#define $1\t/**/\n";
	    }
	} elsif (/^#define\s+(\S+)/) {
	    print "#define $1 $define{$1}\n";
	} elsif (s/\$cpp_stuff/$define{cpp_stuff}/g) { 
	    print;
	} else {
	    print;
	}
    }
} else {
    die "$0: Cannot open config_h.SH_orig: $!";
}
