#!../../miniperl

use bytes;

$UnicodeData = "Unicode.txt";
$SyllableData = "syllables.txt";
$PropData = "PropList.txt";

my $UnicodeLastHex = '10FFFF';

# Note: we try to keep filenames unique within first 8 chars.  Using
# subdirectories for the following helps.
mkdir "In", 0755;
mkdir "Is", 0755;
mkdir "To", 0755;

@todo = (
# typical

    # 005F: SPACING UNDERSCROE
    ['IsWord',   '$cat =~ /^[LMN]/ or $code eq "005F"',	''],
    ['IsAlnum',  '$cat =~ /^[LMN]/',	''],
    ['IsAlpha',  '$cat =~ /^[LM]/',	''],
    # 0009: HORIZONTAL TABULATION
    # 000A: LINE FEED
    # 000B: VERTICAL TABULATION
    # 000C: FORM FEED
    # 000D: CARRIAGE RETURN
    # 0020: SPACE
    ['IsSpace',  '$cat  =~ /^Z/ ||
                  $code =~ /^(0009|000A|000B|000C|000D)$/',	''],
    ['IsSpacePerl',
                 '$cat  =~ /^Z/ ||
                  $code =~ /^(0009|000A|000C|000D)$/',		''],
    ['IsBlank',  '$code =~ /^(0020|0009)$/ ||
		  $cat  =~ /^Z[^lp]$/',	''],
    ['IsDigit',  '$cat =~ /^Nd$/',	''],
    ['IsUpper',  '$cat =~ /^L[ut]$/',	''],
    ['IsLower',  '$cat =~ /^Ll$/',	''],
    ['IsASCII',  '$code le "007f"',	''],
    ['IsCntrl',  '$cat =~ /^C/',	''],
    ['IsGraph',  '$cat =~ /^([LMNPS]|Co)/',	''],
    ['IsPrint',  '$cat =~ /^([LMNPS]|Co|Zs)/',	''],
    ['IsPunct',  '$cat =~ /^P/',	''],
    # 003[0-9]: DIGIT ZERO..NINE, 00[46][1-6]: A..F, a..f
    ['IsXDigit', '$code =~ /^00(3[0-9]|[46][1-6])$/',	''],
    ['ToUpper',  '$up',			'$up'],
    ['ToLower',  '$down',		'$down'],
    ['ToTitle',  '$title',		'$title'],
    ['ToDigit',  '$dec ne ""',		'$dec'],

# Name

    ['Name',	'$name',		'$name'],

# Category

    ['Category', '$cat',		'$cat'],

# Normative

    ['IsM',	'$cat =~ /^M/',		''],	# Mark
    ['IsMn',	'$cat eq "Mn"',		''],	# Mark, Non-Spacing 
    ['IsMc',	'$cat eq "Mc"',		''],	# Mark, Combining
    ['IsMe',	'$cat eq "Me"',		''],    # Mark, Enclosing

    ['IsN',	'$cat =~ /^N/',		''],	# Number
    ['IsNd',	'$cat eq "Nd"',		''],	# Number, Decimal Digit
    ['IsNo',	'$cat eq "No"',		''],	# Number, Other
    ['IsNl',	'$cat eq "Nl"',		''],    # Number, Letter

    ['IsZ',	'$cat =~ /^Z/',		''],	# Separator
    ['IsZs',	'$cat eq "Zs"',		''],	# Separator, Space
    ['IsZl',	'$cat eq "Zl"',		''],	# Separator, Line
    ['IsZp',	'$cat eq "Zp"',		''],	# Separator, Paragraph

    ['IsC',	'$cat =~ /^C/',		''],	# Crazy
    ['IsCc',	'$cat eq "Cc"',		''],	# Other, Control or Format
    ['IsCo',	'$cat eq "Co"',		''],	# Other, Private Use
    ['IsCn',	'$cat eq "Cn"',		''],	# Other, Not Assigned
    ['IsCf',	'$cat eq "Cf"',		''],    # Other, Format
    ['IsCs',	'$cat eq "Cs"',		''],    # Other, Surrogate
    ['IsCn',	'Unassigned Code Value',$PropData],	# Other, Not Assigned
 
# Informative

    ['IsL',	'$cat =~ /^L/',		''],	# Letter
    ['IsLu',	'$cat eq "Lu"',		''],	# Letter, Uppercase
    ['IsLl',	'$cat eq "Ll"',		''],	# Letter, Lowercase
    ['IsLt',	'$cat eq "Lt"',		''],	# Letter, Titlecase 
    ['IsLm',	'$cat eq "Lm"',		''],	# Letter, Modifier
    ['IsLo',	'$cat eq "Lo"',		''],	# Letter, Other 

    ['IsP',	'$cat =~ /^P/',		''],	# Punctuation
    ['IsPd',	'$cat eq "Pd"',		''],	# Punctuation, Dash
    ['IsPs',	'$cat eq "Ps"',		''],	# Punctuation, Open
    ['IsPe',	'$cat eq "Pe"',		''],	# Punctuation, Close
    ['IsPo',	'$cat eq "Po"',		''],	# Punctuation, Other
    ['IsPc',	'$cat eq "Pc"',		''],	# Punctuation, Connector
    ['IsPi',	'$cat eq "Pi"',		''],	# Punctuation, Initial quote
    ['IsPf',	'$cat eq "Pf"',		''],	# Punctuation, Final quote

    ['IsS',	'$cat =~ /^S/',		''],	# Symbol
    ['IsSm',	'$cat eq "Sm"',		''],	# Symbol, Math
    ['IsSk',	'$cat eq "Sk"',		''],	# Symbol, Modifier
    ['IsSc',	'$cat eq "Sc"',		''],	# Symbol, Currency
    ['IsSo',	'$cat eq "So"',		''],	# Symbol, Other

# Combining class
    ['CombiningClass', '$comb',		'$comb'],

# BIDIRECTIONAL PROPERTIES
 
    ['Bidirectional', '$bid',		'$bid'],

# Strong types:

    ['IsBidiL',	'$bid eq "L"',		''],	# Left-Right; Most alphabetic,
						# syllabic, and logographic
						# characters (e.g., CJK
						# ideographs)
    ['IsBidiR',	'$bid eq "R"',		''],	# Right-Left; Arabic, Hebrew,
						# and punctuation specific to
						# those scripts

    ['IsBidiLRE', '$bid eq "LRE"',       ''],    # Left-to-Right Embedding
    ['IsBidiLRO', '$bid eq "LRO"',       ''],    # Left-to-Right Override
    ['IsBidiAL', '$bid eq "AL"',         ''],    # Right-to-Left Arabic
    ['IsBidiRLE', '$bid eq "RLE"',       ''],    # Right-to-Left Embedding
    ['IsBidiRLO', '$bid eq "RLO"',       ''],    # Right-to-Left Override
    ['IsBidiPDF', '$bid eq "PDF"',       ''],    # Pop Directional Format
    ['IsBidiNSM', '$bid eq "NSM"',       ''],    # Non-Spacing Mark
    ['IsBidiBN', '$bid eq "BN"',         ''],    # Boundary Neutral

# Weak types:

    ['IsBidiEN','$bid eq "EN"',		''],	# European Number
    ['IsBidiES','$bid eq "ES"',		''],	# European Number Separator
    ['IsBidiET','$bid eq "ET"',		''],	# European Number Terminator
    ['IsBidiAN','$bid eq "AN"',		''],	# Arabic Number
    ['IsBidiCS','$bid eq "CS"',		''],	# Common Number Separator

# Separators:

    ['IsBidiB',	'$bid eq "B"',		''],	# Block Separator
    ['IsBidiS',	'$bid eq "S"',		''],	# Segment Separator

# Neutrals:

    ['IsBidiWS','$bid eq "WS"',		''],	# Whitespace
    ['IsBidiON','$bid eq "ON"',		''],	# Other Neutrals ; All other
						# characters: punctuation,
						# symbols

# Decomposition

    ['Decomposition',	'$decomp',	'$decomp'],
    ['IsDecoCanon',	'$decomp && $decomp !~ /^</',	''],
    ['IsDecoCompat',	'$decomp =~ /^</',		''],
    ['IsDCfont',	'$decomp =~ /^<font>/',		''],
    ['IsDCnoBreak',	'$decomp =~ /^<noBreak>/',	''],
    ['IsDCinitial',	'$decomp =~ /^<initial>/',	''],
    ['IsDCmedial',	'$decomp =~ /^<medial>/',	''],
    ['IsDCfinal',	'$decomp =~ /^<final>/',	''],
    ['IsDCisolated',	'$decomp =~ /^<isolated>/',	''],
    ['IsDCcircle',	'$decomp =~ /^<circle>/',	''],
    ['IsDCsuper',	'$decomp =~ /^<super>/',	''],
    ['IsDCsub',		'$decomp =~ /^<sub>/',		''],
    ['IsDCvertical',	'$decomp =~ /^<vertical>/',	''],
    ['IsDCwide',	'$decomp =~ /^<wide>/',		''],
    ['IsDCnarrow',	'$decomp =~ /^<narrow>/',	''],
    ['IsDCsmall',	'$decomp =~ /^<small>/',	''],
    ['IsDCsquare',	'$decomp =~ /^<square>/',	''],
    ['IsDCfraction',	'$decomp =~ /^<fraction>/',	''],
    ['IsDCcompat',	'$decomp =~ /^<compat>/',	''],

# Number

    ['Number', 	'$num ne ""',		'$num'],

# Mirrored

    ['IsMirrored', '$mir eq "Y"',	''],

# Arabic

    ['ArabLink', 	'1',		'$link'],
    ['ArabLnkGrp', 	'1',		'$linkgroup'],

# Jamo

    ['JamoShort',	'1',		'$short'],

# Syllables

    syllable_defs(),

# Line break properties - Normative

    ['IsLbrkBK','$brk eq "BK"',		''],	# Mandatory Break
    ['IsLbrkCR','$brk eq "CR"',		''],	# Carriage Return
    ['IsLbrkLF','$brk eq "LF"',		''],	# Line Feed
    ['IsLbrkCM','$brk eq "CM"',		''],	# Attached Characters and Combining Marks
    ['IsLbrkSG','$brk eq "SG"',		''],	# Surrogates
    ['IsLbrkGL','$brk eq "GL"',		''],	# Non-breaking (Glue)
    ['IsLbrkCB','$brk eq "CB"',		''],	# Contingent Break Opportunity
    ['IsLbrkSP','$brk eq "SP"',		''],	# Space
    ['IsLbrkZW','$brk eq "ZW"',		''],	# Zero Width Space

# Line break properties - Informative
    ['IsLbrkXX','$brk eq "XX"',		''],	# Unknown
    ['IsLbrkOP','$brk eq "OP"',		''],	# Opening Punctuation
    ['IsLbrkCL','$brk eq "CL"',		''],	# Closing Punctuation
    ['IsLbrkQU','$brk eq "QU"',		''],	# Ambiguous Quotation
    ['IsLbrkNS','$brk eq "NS"',		''],	# Non Starter
    ['IsLbrkEX','$brk eq "EX"',		''],	# Exclamation/Interrogation
    ['IsLbrkSY','$brk eq "SY"',		''],	# Symbols Allowing Breaks
    ['IsLbrkIS','$brk eq "IS"',		''],	# Infix Separator (Numeric)
    ['IsLbrkPR','$brk eq "PR"',		''],	# Prefix (Numeric)
    ['IsLbrkPO','$brk eq "PO"',		''],	# Postfix (Numeric)
    ['IsLbrkNU','$brk eq "NU"',		''],	# Numeric
    ['IsLbrkAL','$brk eq "AL"',		''],	# Ordinary Alphabetic and Symbol Characters
    ['IsLbrkID','$brk eq "ID"',		''],	# Ideographic
    ['IsLbrkIN','$brk eq "IN"',		''],	# Inseparable
    ['IsLbrkHY','$brk eq "HY"',		''],	# Hyphen
    ['IsLbrkBB','$brk eq "BB"',		''],	# Break Opportunity Before
    ['IsLbrkBA','$brk eq "BA"',		''],	# Break Opportunity After
    ['IsLbrkSA','$brk eq "SA"',		''],	# Complex Context (South East Asian)
    ['IsLbrkAI','$brk eq "AI"',		''],	# Ambiguous (Alphabetic or Ideographic)
    ['IsLbrkB2','$brk eq "B2"',		''],	# Break Opportunity Before and After
);

# This is not written for speed...

my %InIdScript;
my %InIdBlock;
my $InId = 0;

foreach $file (@todo) {
    my ($table, $wanted, $val) = @$file;
    next if @ARGV and not grep { $_ eq $table } @ARGV;
    print $table, "\n";
    $table =~ s/\W+//g;
    if ($table =~ /^(Is|To)(.+)/) {
	open(OUT, ">$1/$2.pl") or die "Can't create $1/$2.pl: $!\n";
    }
    else {
	open(OUT, ">$table.pl") or die "Can't create $table.pl: $!\n";
    }
    print OUT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
EOH
    print OUT <<"END";
return <<'END';
END
    print OUT proplist($table, $wanted, $val);
    print OUT "END\n";
    close OUT;
}

print "Scripts\n";
open(UD, 'Scripts.txt') or die "Can't open Scripts.txt: $!\n";
open(OUT, ">Scripts.pl") or die "Can't create Scripts.pl: $!\n";
print OUT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
EOH
print OUT <<"END";
return <<'END';
END

my %Scripts;
my $ScriptsVec = '';
my $lastlast   = 0;

while (<UD>) {
    next if /^#/;
    next if /^$/;
    chomp;
    ($code, $last, $name) = /^([0-9a-f]+)(?:\.\.([0-9a-f]+))?\s+;\s+(.+)\s+\#/i;
    if ($name) {
	my $InName = $name;
	my $id;
        unless (exists $InIdScript{$InName}) {
	    print "\t$InName\n";
	    $id = $Scripts{$InName} = $InIdScript{$InName} = $InId++;
	    open(SCRIPT, ">In/$id.pl") or die "create In/$id.pl: $!\n";
	    print SCRIPT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<'END';
EOH
            close(SCRIPT);
	} else {
	    $id = $InIdScript{$InName};
	}
	$last = "" unless defined $last;
	print OUT "$code\t$last\t$name\t# In/$id.pl\n";
        open(SCRIPT, ">>In/$id.pl");
	print SCRIPT <<END;
$code	$last
END
	close SCRIPT;
    }
    my $firsti = hex($code);
    my $lasti  = $last ? hex($last) : $firsti;
    for my $i ($firsti..$lasti) {
	vec($ScriptsVec, $i, 1) = 1;
    }
    $lastlast = $lasti if $lasti > $lastlast;
    print "\t\t$code..$last\n"; 
}

for my $id (values %InIdScript) {
    open(SCRIPT, ">>In/$id.pl");
    print SCRIPT <<END2;
END
END2
    close(SCRIPT);
}

print OUT "END\n";
close OUT;

# Must treat blocks specially.

exit if @ARGV and not grep { $_ eq Block } @ARGV;
print "Blocks\n";
open(UD, 'Blocks.txt') or die "Can't open Blocks.txt: $!\n";
open(OUT, ">Blocks.pl") or die "Can't create Blocks.pl: $!\n";
print OUT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
EOH
print OUT <<"END";
return <<'END';
END

while (<UD>) {
    next if /^#/;
    next if /^$/;
    chomp;
    ($code, $last, $name) = /^([0-9a-f]+)\.\.([0-9a-f]+); (.+?)\s*$/i;
    if ($name) {
	my $InName = $name;
	print "\t$InName\n";
	my $id;
	# TODO: only the first one of Private Use blocks qualifies
        unless (exists $InIdBlock{$InName}) {
	    $InIdBlock{$InName} = $InId++;
	}
	$id = $InIdBlock{$InName};
	open(BLOCK, ">In/$id.pl") or die "create In/$id.pl: $!\n";
	print OUT "$code\t$last\t$name\t# In/$id.pl\n";
	print BLOCK <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
EOH
	print BLOCK <<"END2";
return <<'END';
$code	$last
END
END2
	close BLOCK;
    }
}

print OUT "END\n";
close OUT;

#
# \p{Common} is any code point not assigned to a script
#

my $first;

sub flushzerorange {
    my ($scriptname, $scriptid, $i) = @_;
    if (defined $first) {
	my $last = $i - 1;
	$last = $last == $first ? "" : sprintf("%04x", $last);
	printf SCRIPT "%04x\t$last\t$scriptname\t# In/$scriptid.pl\n", $first;
	printf "\t\t%04x..$last\n", $first;
	undef $first;
    }
}

print "\tCommon\n";
my $CommonId = $Scripts{Common} = $InIdScript{Common} = $InId++;
open(SCRIPT, ">In/$CommonId.pl") or die "create In/$CommonId.pl: $!\n";
print SCRIPT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<'END';
EOH

undef $first;
for my $i (0..$lastlast) {
    if (vec($ScriptsVec, $i, 1)) {
	defined $first && flushzerorange('Common', $CommonId, $i);
    } else {
	$first = $i unless defined $first;
    }
}
flushzerorange('Common', $CommonId, $lastlast+1);
print SCRIPT "END\n";
close(SCRIPT);

#
# \p{Any} is 0..10FFFF (in Unicode 3.1.1)
#

print "\tAny\n";
my $AnyId = $Scripts{Any} = $InIdScript{Any} = $InId++;
open(SCRIPT, ">In/$AnyId.pl") or die "create In/$AnyId.pl: $!\n";
print SCRIPT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
0000	$UnicodeLastHex
END
EOH

my $CnVec = '';

open(UD, 'PropList.txt') or die "Can't open PropList.txt: $!\n";

my $InIdProp;
while (<UD>) {
    next if /^#/;
    next if /^$/;
    chomp;
    ($code, $last, $name) = /^([0-9a-f]+)(?:\.\.([0-9a-f]+))?\s+; (\w+)\s/i;
    $last = "" unless defined $last;
    if ($name) {
	my $InName = $name;
	my $id;
        unless (exists $InIdScript{$InName}) {
	    print "\t$InName\n";
	    print PROP <<EOH if defined $InIdProp;
END
EOH
    	    $id = $InIdProp = $InIdScript{$InName} = $InId++;
	    open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
	    print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
	}
	$id = $InIdScript{$InName};
	print PROP "\L$code\t\L$last\n";
	if ($InName eq 'Cn') {
	    my $firsti = hex($code);
	    my $lasti  = $last ? hex($last) : $firsti;
	    for my $I ($firsti..$hexi) {
		vec($CnVec, $i, 1) = 1;
	    }
	}
    }
}
print PROP <<EOH;
END
EOH

print "\tAssigned\n";
my $AssignedId = $Scripts{Assigned} = $InIdScript{Assigned} = $InId++;
open(SCRIPT, ">In/$AssignedId.pl") or die "create In/$AssignedId.pl: $!\n";
print SCRIPT <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<'END';
EOH

undef $first;
for my $i (0..hex($UnicodeLastHex)) {
    if (vec($CnVec, $i, 1)) {
	defined $first && flushzerorange('Assigned', $AssignedId, $i);
    } else {
	$first = $i unless defined $first;
    }
}
flushzerorange('Common', $CommonId, hex($UnicodeLastHex)+1);
print SCRIPT "END\n";
close(SCRIPT);

#
# \p{Alphabetic} is \pL and \p{Other_Alphabetic}
#

print "\tAlphabetic\n";
my @Alphabetic;
push @Alphabetic, split(/\n/, do "Is/L.pl");
push @Alphabetic, split(/\n/, do "In/$InIdScript{Other_Alphabetic}.pl");
$id = $InIdScript{Alphabetic} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @Alphabetic) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{Lowercase} is \p{Ll} and \p{Other_Lowercase}
#

print "\tLowercase\n";
my @Lowercase;
push @Lowercase, split(/\n/, do "Is/Ll.pl");
push @Lowercase, split(/\n/, do "In/$InIdScript{Other_Lowercase}.pl");
$id = $InIdScript{Lowercase} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @Lowercase) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{Uppercase} is \p{Lu} and \p{Other_Uppercase}
#

print "\tUppercase\n";
my @Uppercase;
push @Uppercase, split(/\n/, do "Is/Lu.pl");
push @Uppercase, split(/\n/, do "In/$InIdScript{Other_Uppercase}.pl");
$id = $InIdScript{Uppercase} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @Uppercase) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{Math} is \p{Sm} and \p{Other_Math}
#

print "\tMath\n";
my @Math;
push @Math, split(/\n/, do "Is/Sm.pl");
push @Math, split(/\n/, do "In/$InIdScript{Other_Math}.pl");
$id = $InIdScript{Math} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @Math) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{L&} is \p{Ll}, \p{Lu} and \p{Lt}
#

print "\tLampersand\n";
my @Lampersand;
push @Lampersand, split(/\n/, do "Is/Ll.pl");
push @Lampersand, split(/\n/, do "Is/Lu.pl");
push @Lampersand, split(/\n/, do "Is/Lt.pl");
$id = $InIdScript{Lampersand} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @Lampersand) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{ID_Start} is \p{Ll}, \p{Lu}, \p{Lt}, \p{Lm}, \p{Lo}, and \p{Nl}
#

print "\tID_Start\n";
my @ID_Start;
push @ID_Start, split(/\n/, do "Is/Ll.pl");
push @ID_Start, split(/\n/, do "Is/Lu.pl");
push @ID_Start, split(/\n/, do "Is/Lt.pl");
push @ID_Start, split(/\n/, do "Is/Lm.pl");
push @ID_Start, split(/\n/, do "Is/Lo.pl");
push @ID_Start, split(/\n/, do "Is/Nl.pl");
$id = $InIdScript{ID_Start} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @ID_Start) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

#
# \p{ID_Continue} is \p{ID_Start}, \p{Mn}, \p{Mc}, \p{Nd}, and \p{Pc}
#

print "\tID_Continue\n";
my @ID_Continue;
push @ID_Continue, split(/\n/, do "In/$InIdScript{ID_Start}.pl");
push @ID_Continue, split(/\n/, do "Is/Mn.pl");
push @ID_Continue, split(/\n/, do "Is/Mc.pl");
push @ID_Continue, split(/\n/, do "Is/Nd.pl");
push @ID_Continue, split(/\n/, do "Is/Pc.pl");
$id = $InIdScript{ID_Continue} = $InId++;
open(PROP, ">In/$id.pl") or die "create In/$id.pl: $!\n";
print PROP <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
return <<END;
EOH
for (sort { hex($a) <=> hex($b) } @ID_Continue) {
    print PROP "$_\n";
}
print PROP <<EOH;
END
EOH

open(INID, ">In.pl");

print INID <<EOH;
# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!! 
# This file is built by $0 from e.g. $UnicodeData.
# Any changes made here will be lost!
%utf8::In = (
EOH

my %InIdScriptById = reverse %InIdScript;
my %InIdBlockById  = reverse %InIdBlock;

my @InIdScriptById = sort { $a <=> $b } keys %InIdScriptById;
my @InIdBlockById  = sort { $a <=> $b } keys %InIdBlockById;

my %InId;
my %IdIdLcName;

for my $id (@InIdScriptById) {
    my $name = $InIdScriptById{$id};
    my $lcname = lc($name);
    $InId{$name} = $id;
    $IdIdLcName{$lcname} = $id;
}

for my $id (@InIdBlockById) {
    my $name = $InIdBlockById{$id};
    my $lcname = lc($name);
    if (exists $IdIdLcName{$lcname}) {
	$InId{"$name Block"} = $id;
    } else {
	$InId{$name} = $id;
    }
    $IdIdLcName{$lcname} = $id;
}

my @InId = sort { $InId{$a} <=> $InId{$b} } keys %InId;

my %InIdPrefix;

foreach my $in (@InId) {
    my $inpat = $in;
    $inpat =~ s/([- _])/(?:[-_]|\\s+)?/g;
    push @{$InIdPrefix{lc(substr($in, 0, 3))}}, [ $in, $inpat ];
    printf INID "%-45s => %3d,\n", "'$in'", $InId{$in};
}

print INID ");\n";

print INID <<EOH;
%utf8::InPat = (
EOH

foreach my $prefix (sort keys %InIdPrefix) {
    printf INID "'$prefix' => {\n";
    foreach my $ininpat (@{$InIdPrefix{$prefix}}) {
	my ($in, $inpat) = @$ininpat;
	printf INID "\t'$inpat' => '$in',\n";
    }
    printf INID "},\n";
}

print INID ");\n";

close(INID);

##################################################

sub proplist {
    my ($table, $wanted, $val) = @_;
    my @wanted;
    my $out;
    my $split;

    return listFromPropFile($wanted) if $val eq $PropData;

    if ($table =~ /^Arab/) {
	open(UD, "ArabShap.txt") or warn "Can't open $table: $!";

	$split = '($code, $name, $link, $linkgroup) = split(/; */);';
    }
    elsif ($table =~ /^Jamo/) {
	open(UD, "Jamo.txt") or warn "Can't open $table: $!";

	$split = '($code, $short, $name) = split(/; */); $code =~ s/^U\+//;';
    }
    elsif ($table =~ /^IsSyl/) {
	open(UD, $SyllableData) or warn "Can't open $table: $!";

	$split = '($code, $short, $syl) = split(/; */); $code =~ s/^U\+//;';
    }
    elsif ($table =~ /^IsLbrk/) {
	open(UD, "LineBrk.txt") or warn "Can't open $table: $!";

	$split = '($code, $brk, $name) = /^([0-9a-f]+);(\w+) # (.+)/i;';
    }
    else {
	open(UD, $UnicodeData) or warn "Can't open $UnicodeData: $!";

	$split = '($code, $name, $cat, $comb, $bid, $decomp, $dec, $dig, $num, $mir, $uni1,
		$comment, $up, $down, $title) = split(/;/);';
    }

    if ($table =~ /^(?:To|Is)[A-Z]/) {
	eval <<"END";
	    while (<UD>) {
		next if /^#/;
		next if /^\\s/;
		s/\\s+\$//;
		$split
		if ($wanted) {
		    push(\@wanted, [hex \$code, hex $val, \$name =~ /, First>\$/]);
		}
	    }
END
	die $@ if $@;

	while (@wanted) {
	    $beg = shift @wanted;
	    $last = $beg;
	    while (@wanted and $wanted[0]->[0] == $last->[0] + 1 and
		(not $val or $wanted[0]->[1] == $last->[1] + 1)) {
		    $last = shift @wanted;
	    }
	    $out .= sprintf "%04x", $beg->[0];
	    if ($beg->[2]) {
		$last = shift @wanted;
	    }
	    if ($beg == $last) {
		$out .= "\t";
	    }
	    else {
		$out .= sprintf "\t%04x", $last->[0];
	    }
	    $out .= sprintf "\t%04x", $beg->[1] if $val;
	    $out .= "\n";
	}
    }
    else {
	eval <<"END";
	    while (<UD>) {
		next if /^#/;
		next if /^\\s*\$/;
		chop;
		$split
		if ($wanted) {
		    push(\@wanted, [hex \$code, $val, \$name =~ /, First>\$/]);
		}
	    }
END
	die $@ if $@;

	while (@wanted) {
	    $beg = shift @wanted;
	    $last = $beg;
	    while (@wanted and $wanted[0]->[0] == $last->[0] + 1 and
		($wanted[0]->[1] eq $last->[1])) {
		    $last = shift @wanted;
	    }
	    $out .= sprintf "%04x", $beg->[0];
	    if ($beg->[2]) {
		$last = shift @wanted;
	    }
	    if ($beg == $last) {
		$out .= "\t";
	    }
	    else {
		$out .= sprintf "\t%04x", $last->[0];
	    }
	    $out .= sprintf "\t%s\n", $beg->[1];
	}
    }
    $out;
}

sub listFromPropFile {
    my ($wanted) = @_;
    my $out;

    open (UD, $PropData) or die "Can't open $PropData: $!\n";
    local($/) = "\n" . '*' x 43 . "\n\nProperty dump for:";   # not 42?

    <UD>;
    while (<UD>) {
        chomp;
        if (s/0x[\d\w]+\s+\((.*?)\)// and $wanted eq $1) {
            s/\(\d+ chars\)//g;
            s/^\s+//mg;
            s/\s+$//mg;
            s/\.\./\t/g;
	    $out = lc $_;
	    last;
        }
    }
    close (UD);
    "$out\n";
}

sub syllable_defs {
    my @defs;
    my %seen;

    open (SD, $SyllableData) or die "Can't open $SyllableData: $!\n";
    while (<SD>) {
        next if /^\s*(#|$)/;
        s/\s+$//;
        ($code, $name, $syl) = split /; */;
        next unless $syl;
        push (@defs, ["IsSyl$syl", qq{\$syl eq "$syl"}, ''])
                                                     unless $seen{$syl}++;
    }
    close (SD);
    return (@defs);
}

# eof
