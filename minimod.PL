# minimod.PL writes the contents of miniperlmain.c into the module
# ExtUtils::Miniperl for later perusal (when the perl source is
# deleted)
#
# It also writes the subroutine writemain(), which takes as its
# arguments module names that shall be statically linked into perl.
#
# Authors: Andreas Koenig <k@franz.ww.TU-Berlin.DE>, Tim Bunce
#          <Tim.Bunce@ig.co.uk>
#
# Version 1.0, Feb 2nd 1995 by Andreas Koenig

print <<'END';
# This File keeps the contents of miniperlmain.c.
#
# It was generated automatically by minimod.PL from the contents
# of miniperlmain.c. Don't edit this file!
#
#       ANY CHANGES MADE HERE WILL BE LOST! 
#


package ExtUtils::Miniperl;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&writemain);

$head= <<'EOF!HEAD';
END

open MINI, "miniperlmain.c";
while (<MINI>) {
    last if /Do not delete this line--writemain depends on it/;
    print;
}

print <<'END';
EOF!HEAD
$tail=<<'EOF!TAIL';
END

while (<MINI>) {
    print;
}
close MINI;

print <<'END';
EOF!TAIL

sub writemain{
    my(@exts) = @_;

    my($pname);
    my($dl) = canon('/','DynaLoader');
    print $head;
    print "	char *file = __FILE__;\n";
    foreach $_ (@exts){
	my($pname) = canon('/', $_);
	my($mname, $cname);
	($mname = $pname) =~ s!/!::!g;
	($cname = $pname) =~ s!/!__!g;
	print "\t{   extern void boot_${cname} _((CV* cv));\n";
	if ($pname eq $dl){
	    # Must NOT install 'DynaLoader::boot_DynaLoader' as 'bootstrap'!
	    # boot_DynaLoader is called directly in DynaLoader.pm
	    print "\t/* DynaLoader is a special case */\n";
	    print "\tnewXS(\"${mname}::boot_${cname}\", boot_${cname}, file);\n"
	} else {
	    print "\tnewXS(\"${mname}::bootstrap\", boot_${cname}, file);\n"
	}
	print "\t}\n";
    }
    print $tail;
}

sub canon{
    my($as, @ext) = @_;
	foreach(@ext){
	    # might be X::Y or lib/auto/X/Y/Y.a
		next if s!::!/!g;
	    s:^(lib|ext)/(auto/)?::;
	    s:/\w+\.\w+$::;
	}
	grep(s:/:$as:, @ext) if ($as ne '/');
	@ext;
}

1;
END
