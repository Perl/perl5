case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting pod/pod2html (with variable substitutions)"
rm -f pod2html
$spitshell >pod2html <<!GROK!THIS!
#!$binexp/perl
eval 'exec perl -S \$0 \${1+"\$@"}'
	if \$running_under_some_shell;
!GROK!THIS!

$spitshell >>pod2html <<'!NO!SUBS!'
#
# pod2html - convert pod format to html
# 
# usage: pod2html [podfiles]
# will read the cwd and parse all files with .pod extension
# if no arguments are given on the command line.
#
*RS = */;
*ERRNO = *!;

use Carp;

$gensym = 0;

while ($ARGV[0] =~ /^-d(.*)/) {
    shift;
    $Debug{ lc($1 || shift) }++;
}

# look in these pods for things not found within the current pod
@inclusions = qw[
     perlfunc perlvar perlrun perlop 
];

# ck for podnames on command line
while ($ARGV[0]) {
    push(@Pods,shift);
}
$A={};

# location of pods
$dir="."; 

# The beginning of the url for the anchors to the other sections.
# Edit $type to suit.  It's configured for relative url's now.
$type='<A HREF="';		
$debug = 0;

unless(@Pods){
    opendir(DIR,$dir)  or  die "Can't opendir $dir: $ERRNO";
    @Pods = grep(/\.pod$/,readdir(DIR));
    closedir(DIR) or die "Can't closedir $dir: $ERRNO";
}
@Pods or die "expected pods";

# loop twice through the pods, first to learn the links, then to produce html
for $count (0,1){
    (print "Scanning pods...\n") unless $count;
    foreach $podfh ( @Pods ) {
	($pod = $podfh) =~ s/\.pod$//;
	Debug("files", "opening 2 $podfh" );
	(print "Creating $pod.html from $podfh\n") if $count;
	$RS = "\n=";
	open($podfh,"<".$podfh)  || die "can't open $podfh: $ERRNO";
	@all=<$podfh>;
	close($podfh);
	$RS = "\n";
	$all[0]=~s/^=//;
	for(@all){s/=$//;}
	$Podnames{$pod} = 1;
	$in_list=0;
	$html=$pod.".html";
	if($count){
	    open(HTML,">$html") || die "can't create $html: $ERRNO";
	    print HTML <<'HTML__EOQ', <<"HTML__EOQQ";
	    <!-- \$RCSfile\$\$Revision\$\$Date\$ -->
	    <!-- \$Log\$ -->
	    <HTML>
HTML__EOQ
	    <TITLE> \U$pod\E </TITLE>
HTML__EOQQ
	}

	for($i=0;$i<=$#all;$i++){

	    $all[$i] =~ /^(\w+)\s*(.*)\n?([^\0]*)$/ ;
	    ($cmd, $title, $rest) = ($1,$2,$3);
	    if ($cmd eq "item") {
		if($count ){
		    ($depth) or do_list("over",$all[$i],\$in_list,\$depth);
		    do_item($title,$rest,$in_list);
		}
		else{
		    # scan item
		    scan_thing("item",$title,$pod);
		}
	    }
	    elsif ($cmd =~ /^head([12])/){
		$num=$1;
		if($count){
		    do_hdr($num,$title,$rest,$depth);
		}
		else{
		    # header scan
		    scan_thing($cmd,$title,$pod); # skip head1
		}
	    }
	    elsif ($cmd =~ /^over/) {
		$count and $depth and do_list("over",$all[$i+1],\$in_list,\$depth);
	    }
	    elsif ($cmd =~ /^back/) {
		if($count){
		    ($depth) or next; # just skip it
		    do_list("back",$all[$i+1],\$in_list,\$depth);
		    do_rest("$title.$rest");
		}
	    }
	    elsif ($cmd =~ /^cut/) {
		next;
	    }
	    elsif($Debug){
		(warn "unrecognized header: $cmd") if $Debug;
	    }
	}
        # close open lists without '=back' stmts
	if($count){
	    while($depth){
		 do_list("back",$all[$i+1],\$in_list,\$depth);
	    }
	    print HTML "\n</HTML>\n";
	}
    }
}

sub do_list{
    my($which,$next_one,$list_type,$depth)=@_;
    my($key);
    if($which eq "over"){
	($next_one =~ /^item\s+(.*)/ ) or (warn "Bad list, $1\n") if $Debug;
	$key=$1;
	if($key =~ /^1\.?/){
	$$list_type = "OL";
	}
	elsif($key =~ /\*\s*$/){
	$$list_type="UL";
	}
	elsif($key =~ /\*?\s*\w/){
	$$list_type="DL";
	}
	else{
	(warn "unknown list type for item $key") if $Debug;
	}
	print HTML qq{\n};
	print HTML qq{<$$list_type>};
	$$depth++;
    }
    elsif($which eq "back"){
	print HTML qq{\n</$$list_type>\n};
	$$depth--;
    }
}

sub do_hdr{
    my($num,$title,$rest,$depth)=@_;
    ($num == 1) and print HTML qq{<p><hr>\n};
    process_thing(\$title,"NAME");
    print HTML qq{\n<H$num> };
    print HTML $title; 
    print HTML qq{</H$num>\n};
    do_rest($rest);
}

sub do_item{
    my($title,$rest,$list_type)=@_;
    process_thing(\$title,"NAME");
    if($list_type eq "DL"){
	print HTML qq{\n<DT><STRONG>\n};
	print HTML $title; 
	print HTML qq{\n</STRONG></DT>\n};
	print HTML qq{<DD>\n};
    }
    else{
	print HTML qq{\n<LI>};
	($list_type ne "OL") && (print HTML $title,"\n");
    }
    do_rest($rest);
    print HTML ($list_type eq "DL" )? qq{</DD>} : qq{</LI>};
}

sub do_rest{
    my($rest)=@_;
    my(@lines,$p,$q,$line,,@paras,$inpre);
    @paras=split(/\n\n+/,$rest);
    for($p=0;$p<=$#paras;$p++){
	@lines=split(/\n/,$paras[$p]);
	if($lines[0] =~ /^\s+\w*\t.*/){  # listing or unordered list
	    print HTML qq{<UL>};
	    foreach $line (@lines){ 
		($line =~ /^\s+(\w*)\t(.*)/) && (($key,$rem) = ($1,$2));
		print HTML defined($Podnames{$key}) ?
		    "<LI>$type$key.html\">$key<\/A>\t$rem</LI>\n" : 
			"<LI>$line</LI>\n";
	    }
	    print HTML qq{</UL>\n};
	}
	elsif($lines[0] =~ /^\s/){       # preformatted code
	    if($paras[$p] =~/>>|<</){
		print HTML qq{\n<PRE>\n};
		$inpre=1;
	    }
	    else{
		print HTML qq{\n<XMP>\n};
		$inpre=0;
	    }
inner:
	    while(defined($paras[$p])){
	        @lines=split(/\n/,$paras[$p]);
		foreach $q (@lines){
		    if($paras[$p]=~/>>|<</){
			if($inpre){
			    process_thing(\$q,"HTML");
			}
			else {
			    print HTML qq{\n</XMP>\n};
			    print HTML qq{<PRE>\n};
			    $inpre=1;
			    process_thing(\$q,"HTML");
			}
		    }
		    while($q =~  s/\t+/' 'x (length($&) * 8 - length($`) % 8)/e){
			1;
		    }
		    print HTML  $q,"\n";
		}
		last if $paras[$p+1] !~ /^\s/;
		$p++;
	    }
	    print HTML ($inpre==1) ? (qq{\n</PRE>\n}) : (qq{\n</XMP>\n});
	}
	else{                             # other text
	    @lines=split(/\n/,$paras[$p]);
	    foreach $line (@lines){
                process_thing(\$line,"HTML");
		print HTML qq{$line\n};
	    }
	}
	print HTML qq{<p>};
    }
}

sub process_thing{
    my($thing,$htype)=@_;
    pre_escapes($thing);
    find_refs($thing,$htype);
    post_escapes($thing);
}

sub scan_thing{
    my($cmd,$title,$pod)=@_;
    $_=$title;
    s/\n$//;
    s/E<(.*?)>/&$1;/g;
    # remove any formatting information for the headers
    s/[SFCBI]<(.*?)>/$1/g;         
    # the "don't format me" thing
    s/Z<>//g;
    if ($cmd eq "item") {

        if (/^\*/) 	{  return } 	# skip bullets
        if (/^\d+\./) 	{  return } 	# skip numbers
        s/(-[a-z]).*/$1/i;
	trim($_);
        return if defined $A->{$pod}->{"Items"}->{$_};
        $A->{$pod}->{"Items"}->{$_} = gensym($pod, $_);
        $A->{$pod}->{"Items"}->{(split(' ',$_))[0]}=$A->{$pod}->{"Items"}->{$_};
        Debug("items", "item $_");
        if (!/^-\w$/ && /([%\$\@\w]+)/ && $1 ne $_ 
    	    && !defined($A->{$pod}->{"Items"}->{$_}) && ($_ ne $1)) 
        {
    	    $A->{$pod}->{"Items"}->{$1} = $A->{$pod}->{"Items"}->{$_};
    	    Debug("items", "item $1 REF TO $_");
        } 
        if ( m{^(tr|y|s|m|q[qwx])/.*[^/]} ) {
    	    my $pf = $1 . '//';
    	    $pf .= "/" if $1 eq "tr" || $1 eq "y" || $1 eq "s";
    	    if ($pf ne $_) {
    	        $A->{$pod}->{"Items"}->{$pf} = $A->{$pod}->{"Items"}->{$_};
    	        Debug("items", "item $pf REF TO $_");
    	    }
	}
    }
    elsif ($cmd =~ /^head[12]/){                
        return if defined($Headers{$_});
        $A->{$pod}->{"Headers"}->{$_} = gensym($pod, $_);
        Debug("headers", "header $_");
    } 
    else {
        (warn "unrecognized header: $cmd") if $Debug;
    } 
}


sub picrefs { 
    my($char, $bigkey, $lilkey,$htype) = @_;
    my($key,$ref,$podname);
    for $podname ($pod,@inclusions){
	for $ref ( "Items", "Headers" ) {
	    if (defined $A->{$podname}->{$ref}->{$bigkey}) {
		$value = $A->{$podname}->{$ref}->{$key=$bigkey};
		Debug("subs", "bigkey is $bigkey, value is $value\n");
	    } 
	    elsif (defined $A->{$podname}->{$ref}->{$lilkey}) {
		$value = $A->{$podname}->{$ref}->{$key=$lilkey};
		return "" if $lilkey eq '';
		Debug("subs", "lilkey is $lilkey, value is $value\n");
	    } 
	} 
	if (length($key)) {
            ($pod2,$num) = split(/_/,$value,2);
	    if($htype eq "NAME"){  
		return "\n<A NAME=\"".$value."\">\n$bigkey</A>\n"
	    }
	    else{
		return "\n$type$pod2.html\#".$value."\">$bigkey<\/A>\n";
	    }
	} 
    }
    if ($char =~ /[IF]/) {
	return "<EM> $bigkey </EM>";
    } elsif($char =~ /C/) {
	return "<CODE> $bigkey </CODE>";
    } else {
	return "<STRONG> $bigkey </STRONG>";
    }
} 

sub find_refs { 
    my($thing,$htype)=@_;
    my($orig) = $$thing;
    # LREF: a manpage(3f) we don't know about
    $$thing=~s:L<([a-zA-Z][^\s\/]+)(\([^\)]+\))>:the I<$1>$2 manpage:g;
    $$thing=~s/L<([^>]*)>/lrefs($1,$htype)/ge;
    $$thing=~s/([CIBF])<(\W*?(-?\w*).*?)>/picrefs($1, $2, $3, $htype)/ge;
    $$thing=~s/((\w+)\(\))/picrefs("I", $1, $2,$htype)/ge;
    $$thing=~s/([\$\@%](?!&[gl]t)([\w:]+|\W\b))/varrefs($1,$htype)/ge;
    (($$thing eq $orig) && ($htype eq "NAME")) && 
	($$thing=picrefs("I", $$thing, "", $htype));
}

sub lrefs {
    my($page, $item) = split(m#/#, $_[0], 2);
    my($htype)=$_[1];
    my($podname);
    my($section) = $page =~ /\((.*)\)/;
    my $selfref;
    if ($page =~ /^[A-Z]/ && $item) {
	$selfref++;
	$item = "$page/$item";
	$page = $pod;
    }  elsif (!$item && $page =~ /[^a-z\-]/ && $page !~ /^\$.$/) {
	$selfref++;
	$item = $page;
	$page = $pod;
    } 
    $item =~ s/\(\)$//;
    if (!$item) {
    	if (!defined $section && defined $Podnames{$page}) {
	    return "\n$type$page.html\">\nthe <EM> $page </EM> manpage<\/A>\n";
	} else {
	    (warn "Bizarre entry $page/$item") if $Debug;
	    return "the <EM> $_[0] </EM>  manpage\n";
	} 
    } 

    if ($item =~ s/"(.*)"/$1/ || ($item =~ /[^\w\/\-]/ && $item !~ /^\$.$/)) {
	$text = "<EM> $item </EM>";
	$ref = "Headers";
    } else {
	$text = "<EM> $item </EM>";
	$ref = "Items";
    } 
    for $podname ($pod, @inclusions){
	undef $value;
	if ($ref eq "Items") {
	    if (defined($value = $A->{$podname}->{$ref}->{$item})) {
		($pod2,$num) = split(/_/,$value,2);
		return (($pod eq $pod2) && ($htype eq "NAME"))
	    	? "\n<A NAME=\"".$value."\">\n$text</A>\n"
	    	: "\n$type$pod2.html\#".$value."\">$text<\/A>\n";
            }
        } 
	elsif($ref eq "Headers") {
	    if (defined($value = $A->{$podname}->{$ref}->{$item})) {
		($pod2,$num) = split(/_/,$value,2);
		return (($pod eq $pod2) && ($htype eq "NAME")) 
	    	? "\n<A NAME=\"".$value."\">\n$text</A>\n"
	    	: "\n$type$pod2.html\#".$value."\">$text<\/A>\n";
            }
	}
    }
    (warn "No $ref reference for $item (@_)") if $Debug;
    return $text;
} 

sub varrefs {
    my ($var,$htype) = @_;
    for $podname ($pod,@inclusions){
	if ($value = $A->{$podname}->{"Items"}->{$var}) {
	    ($pod2,$num) = split(/_/,$value,2);
	    Debug("vars", "way cool -- var ref on $var");
	    return (($pod eq $pod2) && ($htype eq "NAME"))  # INHERIT $_, $pod
		? "\n<A NAME=\"".$value."\">\n$var</A>\n"
		: "\n$type$pod2.html\#".$value."\">$var<\/A>\n";
	}
    }
    Debug( "vars", "bummer, $var not a var");
    return "<STRONG> $var </STRONG>";
} 

sub gensym {
    my ($podname, $key) = @_;
    $key =~ s/\s.*//;
    ($key = lc($key)) =~ tr/a-z/_/cs;
    my $name = "${podname}_${key}_0";
    $name =~ s/__/_/g;
    while ($sawsym{$name}++) {
        $name =~ s/_?(\d+)$/'_' . ($1 + 1)/e;
    }
    return $name;
} 

sub pre_escapes {
    my($thing)=@_;
    $$thing=~s/&/noremap("&amp;")/ge;
    $$thing=~s/<</noremap("&lt;&lt;")/eg;
    $$thing=~s/(?:[^ESIBLCF])</noremap("&lt;")/eg;
    $$thing=~s/E<([^\/][^<>]*)>/\&$1\;/g;              # embedded special
}

sub noremap {
    my $hide = $_[0];
    $hide =~ tr/\000-\177/\200-\377/;
    $hide;
} 

sub post_escapes {
    my($thing)=@_;
    $$thing=~s/[^GM]>>/\&gt\;\&gt\;/g;
    $$thing=~s/([^"MGAE])>/$1\&gt\;/g;
    $$thing=~tr/\200-\377/\000-\177/;
}

sub Debug {
    my $level = shift;
    print STDERR @_,"\n" if $Debug{$level};
} 

sub dumptable  {
    my $t = shift;
    print STDERR "TABLE DUMP $t\n";
    foreach $k (sort keys %$t) {
	printf STDERR "%-20s <%s>\n", $t->{$k}, $k;
    } 
} 
sub trim {
    for (@_) {
        s/^\s+//;
        s/\s\n?$//;
    }
}


!NO!SUBS!
chmod 755 pod2html
$eunicefix pod2html
