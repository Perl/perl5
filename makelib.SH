case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi
    . config.sh
    ;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting makelib (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >makelib <<!GROK!THIS!
#!/usr/bin/perl

\$perlincl = '$privlib';
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>makelib <<'!NO!SUBS!'

chdir '/usr/include' || die "Can't cd /usr/include";

%isatype = ('char',1,'short',1,'int',1,'long',1);

foreach $file (@ARGV) {
    print $file,"\n";
    if ($file =~ m|^(.*)/|) {
	$dir = $1;
	if (!-d "$perlincl/$dir") {
	    mkdir("$perlincl/$dir",0777);
	}
    }
    open(IN,"$file") || ((warn "Can't open $file: $!\n"),next);
    open(OUT,">$perlincl/$file") || die "Can't create $file: $!\n";
    while (<IN>) {
	chop;
	while (/\\$/) {
	    chop;
	    $_ .= <IN>;
	    chop;
	}
	if (s:/\*:\200:g) {
	    s:\*/:\201:g;
	    s/\200[^\201]*\201//g;	# delete single line comments
	    if (s/\200.*//) {		# begin multi-line comment?
		$_ .= '/*';
		$_ .= <IN>;
		redo;
	    }
	}
	if (s/^#\s*//) {
	    if (s/^define\s+(\w+)//) {
		$name = $1;
		$new = '';
		s/\s+$//;
		if (s/^\(([\w,\s]*)\)//) {
		    $args = $1;
		    if ($args ne '') {
			foreach $arg (split(/,\s*/,$args)) {
			    $curargs{$arg} = 1;
			}
			$args =~ s/\b(\w)/\$$1/g;
			$args = "local($args) = \@_;\n$t    ";
		    }
		    s/^\s+//;
		    do expr();
		    $new =~ s/(["\\])/\\$1/g;
		    if ($t ne '') {
			$new =~ s/(['\\])/\\$1/g;
			print OUT $t,
			  "eval 'sub $name {\n$t    ${args}eval \"$new\";\n$t}';\n";
		    }
		    else {
			print OUT "sub $name {\n    ${args}eval \"$new\";\n}\n";
		    }
		    %curargs = ();
		}
		else {
		    s/^\s+//;
		    do expr();
		    $new = 1 if $new eq '';
		    if ($t ne '') {
			$new =~ s/(['\\])/\\$1/g;
			print OUT $t,"eval 'sub $name {",$new,";}';\n";
		    }
		    else {
			print OUT $t,"sub $name {",$new,";}\n";
		    }
		}
	    }
	    elsif (/^include <(.*)>/) {
		print OUT $t,"do '$1' || die \"Can't include $1: \$!\";\n";
	    }
	    elsif (/^ifdef\s+(\w+)/) {
		print OUT $t,"if (defined &$1) {\n";
		$tab += 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
	    }
	    elsif (/^ifndef\s+(\w+)/) {
		print OUT $t,"if (!defined &$1) {\n";
		$tab += 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
	    }
	    elsif (s/^if\s+//) {
		$new = '';
		do expr();
		print OUT $t,"if ($new) {\n";
		$tab += 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
	    }
	    elsif (s/^elif\s+//) {
		$new = '';
		do expr();
		$tab -= 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
		print OUT $t,"}\n${t}elsif ($new) {\n";
		$tab += 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
	    }
	    elsif (/^else/) {
		$tab -= 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
		print OUT $t,"}\n${t}else {\n";
		$tab += 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
	    }
	    elsif (/^endif/) {
		$tab -= 4;
		$t = "\t" x ($tab / 8) . ' ' x ($tab % 8);
		print OUT $t,"}\n";
	    }
	}
    }
    print OUT "1;\n";
}

sub expr {
    while ($_ ne '') {
	s/^(\s+)//		&& do {$new .= ' '; next;};
	s/^(0x[0-9a-fA-F]+)//	&& do {$new .= $1; next;};
	s/^(\d+)//		&& do {$new .= $1; next;};
	s/^("(\\"|[^"])*")//	&& do {$new .= $1; next;};
	s/^'((\\"|[^"])*)'//	&& do {
	    if ($curargs{$1}) {
		$new .= "ord('\$$1')";
	    }
	    else {
		$new .= "ord('$1')";
	    }
	    next;
	};
	s/^(struct\s+\w+)//	&& do {$new .= "'$1'"; next;};
	s/^sizeof\s*\(([^)]+)\)/{$1}/ && do {
	    $new .= '$sizeof';
	    next;
	};
	s/^([_a-zA-Z]\w*)//	&& do {
	    $id = $1;
	    if ($curargs{$id}) {
		$new .= '$' . $id;
	    }
	    elsif ($id eq 'defined') {
		$new .= 'defined';
	    }
	    elsif (/^\(/) {
		s/^\((\w),/("$1",/ if $id =~ /^_IO[WR]*$/;	# cheat
		$new .= "&$id";
	    }
	    elsif ($isatype{$id}) {
		$new .= "'$id'";
	    }
	    else {
		$new .= '&' . $id;
	    }
	    next;
	};
	s/^(.)//			&& do {$new .= $1; next;};
    }
}
!NO!SUBS!
chmod 755 makelib
$eunicefix makelib
