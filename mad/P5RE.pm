#!/usr/bin/perl

use strict;
use warnings;

my $depth = 0;
my $in = "";
my $delim = 1;

package P5RE;

our $extended;
our $insensitive;
our $singleline;
our $multiline;

my %xmlish = (
	chr(0x00) => "STUPIDXML(#x00)",
	chr(0x01) => "STUPIDXML(#x01)",
	chr(0x02) => "STUPIDXML(#x02)",
	chr(0x03) => "STUPIDXML(#x03)",
	chr(0x04) => "STUPIDXML(#x04)",
	chr(0x05) => "STUPIDXML(#x05)",
	chr(0x06) => "STUPIDXML(#x06)",
	chr(0x07) => "STUPIDXML(#x07)",
	chr(0x08) => "STUPIDXML(#x08)",
	chr(0x09) => "&#9;",
	chr(0x0a) => "&#10;",
	chr(0x0b) => "STUPIDXML(#x0b)",
	chr(0x0c) => "STUPIDXML(#x0c)",
	chr(0x0d) => "&#13;",
	chr(0x0e) => "STUPIDXML(#x0e)",
	chr(0x0f) => "STUPIDXML(#x0f)",
	chr(0x10) => "STUPIDXML(#x10)",
	chr(0x11) => "STUPIDXML(#x11)",
	chr(0x12) => "STUPIDXML(#x12)",
	chr(0x13) => "STUPIDXML(#x13)",
	chr(0x14) => "STUPIDXML(#x14)",
	chr(0x15) => "STUPIDXML(#x15)",
	chr(0x16) => "STUPIDXML(#x16)",
	chr(0x17) => "STUPIDXML(#x17)",
	chr(0x18) => "STUPIDXML(#x18)",
	chr(0x19) => "STUPIDXML(#x19)",
	chr(0x1a) => "STUPIDXML(#x1a)",
	chr(0x1b) => "STUPIDXML(#x1b)",
	chr(0x1c) => "STUPIDXML(#x1c)",
	chr(0x1d) => "STUPIDXML(#x1d)",
	chr(0x1e) => "STUPIDXML(#x1e)",
	chr(0x1f) => "STUPIDXML(#x1f)",
	chr(0x7f) => "STUPIDXML(#x7f)",
	chr(0x80) => "STUPIDXML(#x80)",
	chr(0x81) => "STUPIDXML(#x81)",
	chr(0x82) => "STUPIDXML(#x82)",
	chr(0x83) => "STUPIDXML(#x83)",
	chr(0x84) => "STUPIDXML(#x84)",
	chr(0x86) => "STUPIDXML(#x86)",
	chr(0x87) => "STUPIDXML(#x87)",
	chr(0x88) => "STUPIDXML(#x88)",
	chr(0x89) => "STUPIDXML(#x89)",
	chr(0x90) => "STUPIDXML(#x90)",
	chr(0x91) => "STUPIDXML(#x91)",
	chr(0x92) => "STUPIDXML(#x92)",
	chr(0x93) => "STUPIDXML(#x93)",
	chr(0x94) => "STUPIDXML(#x94)",
	chr(0x95) => "STUPIDXML(#x95)",
	chr(0x96) => "STUPIDXML(#x96)",
	chr(0x97) => "STUPIDXML(#x97)",
	chr(0x98) => "STUPIDXML(#x98)",
	chr(0x99) => "STUPIDXML(#x99)",
	chr(0x9a) => "STUPIDXML(#x9a)",
	chr(0x9b) => "STUPIDXML(#x9b)",
	chr(0x9c) => "STUPIDXML(#x9c)",
	chr(0x9d) => "STUPIDXML(#x9d)",
	chr(0x9e) => "STUPIDXML(#x9e)",
	chr(0x9f) => "STUPIDXML(#x9f)",
	'<'       => "&lt;",
	'>'       => "&gt;",
	'&'       => "&amp;",
	'"'       => "&#34;",		# XML idiocy
);

sub xmlquote {
    my $text = shift;
    $text =~ s/(.)/$xmlish{$1} || $1/seg;
    return $text;
}

sub text {
    my $self = shift;
    return xmlquote($self->{text});
}

sub rep {
    my $self = shift;
    return xmlquote($self->{rep});
}

sub xmlkids {
    my $self = shift;
    my $array = $self->{Kids};
    my $ret = "";
    $depth++;
    $in = ' ' x ($depth * 2);
    foreach my $chunk (@$array) {
	if (ref $chunk eq "ARRAY") {
	    die;
	}
	elsif (ref $chunk) {
	    $ret .= $chunk->xml();
	}
	else {
	    warn $chunk;
	}
    }
    $depth--;
    $in = ' ' x ($depth * 2);
    return $ret;
};

package P5RE::RE; BEGIN { our @ISA = 'P5RE'; }

sub xml {
    my $self = shift;
    my $kind = $self->{kind};
    my $modifiers = $self->{modifiers} || "";
    if ($modifiers) {
	$modifiers = " modifiers=\"$modifiers\"";
    }
    my $text = "$in<$kind$modifiers>\n";
    $text .= $self->xmlkids();
    $text .= "$in</$kind>\n";
    return $text;
}

package P5RE::Alt; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    my $text = "$in<alt>\n";
    $text .= $self->xmlkids();
    $text .= "$in</alt>\n";
    return $text;
}

#package P5RE::Atom; our @ISA = 'P5RE';
#
#sub xml {
#    my $self = shift;
#    my $text = "$in<atom>\n";
#    $text .= $self->xmlkids();
#    $text .= "$in</atom>\n";
#    return $text;
#}

package P5RE::Quant; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    my $q = $self->{type};
    my $text = "$in<quant type=\"$q\">\n";
    $text .= $self->xmlkids();
    $text .= "$in</quant>\n";
    return $text;
}

package P5RE::White; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<white text=\"" . $self->text() . "\" />\n";
}

package P5RE::Char; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<char text=\"" . $self->text() . "\" />\n";
}

package P5RE::Comment; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<comment rep=\"" . $self->rep() . "\" />\n";
}

package P5RE::Mod; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<mod modifiers=\"" . $self->{modifiers} . "\" />\n";
}

package P5RE::Meta; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    my $sem = "";
    if ($self->{sem}) {
	$sem = 'sem="' . $self->{sem} . '" '
    }
    return "$in<meta rep=\"" . $self->rep() . "\" $sem/>\n";
}

package P5RE::Var; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<var name=\"" . $self->{name} . "\" />\n";
}

package P5RE::Closure; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    return "$in<closure rep=\"" . $self->{rep} . "\" />\n";
}

package P5RE::CClass; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    my $neg = $self->{neg} ? "negated" : "normal";
    my $text = "$in<cclass match=\"$neg\">\n";
    $text .= $self->xmlkids();
    $text .= "$in</cclass>\n";
    return $text;
}

package P5RE::Range; our @ISA = 'P5RE';

sub xml {
    my $self = shift;
    my $text = "$in<range>\n";
    $text .= $self->xmlkids();
    $text .= "$in</range>\n";
    return $text;
}

package P5RE;

sub re {
    my $kind = shift;
    my @alts;

    push(@alts, alt());

    while (s/^\|//) {
	push(@alts, alt());
    }
    return bless { Kids => [@alts], kind => $kind }, "P5RE::RE";	
}

sub alt {
    my @quants;

    my $quant;
    local $extended = $extended;
    local $insensitive = $insensitive;
    local $multiline = $multiline;
    local $singleline = $singleline;
    while ($quant = quant()) {
	if (@quants and
	    ref $quant eq ref $quants[-1] and
	    exists $quants[-1]{text} and
	    exists $quant->{text} )
	{
	    $quants[-1]{text} .= $quant->{text};
	}
	else {
	    push(@quants, $quant);
	}
    }
    return bless { Kids => [@quants] }, "P5RE::Alt";	
}

sub quant {
    my $atom = atom();
    return 0 unless $atom;
#    $atom = bless { Kids => [$atom] }, "P5RE::Atom";	
    if (s/^([*+?]\??|\{\d+(?:,\d*)?\}\??)//) {
	return bless { Kids => [$atom], type => $1 }, "P5RE::Quant";	
    }
    return $atom;
}

sub atom {
    my $re;
    if ($_ eq "") { return 0 }
    if (/^[)|]/) { return 0 }

    # whitespace is special because we don't know if /x is in effect
    if ($extended) {
	if (s/^(?=\s|#)(\s*(?:#.*)?)//) { return bless { text => $1 }, "P5RE::White"; }
    }

    # all the parenthesized forms
    if (s/^\(//) {
	if (s/^\?://) {
	    $re = re('bracket');
	}
	elsif (s/^(\?#.*?)\)/)/) {
	    $re = bless { rep => "($1)" }, "P5RE::Comment";	
	}
	elsif (s/^\?=//) {
	    $re = re('lookahead');
	}
	elsif (s/^\?!//) {
	    $re = re('neglookahead');
	}
	elsif (s/^\?<=//) {
	    $re = re('lookbehind');
	}
	elsif (s/^\?<!//) {
	    $re = re('neglookbehind');
	}
	elsif (s/^\?>//) {
	    $re = re('nobacktrack');
	}
	elsif (s/^(\?\??\{.*?\})\)/)/) {
	    $re = bless { rep => "($1)" }, "P5RE::Closure";	
	}
	elsif (s/^(\?\(\d+\))//) {
	    my $mods = $1;
	    $re = re('conditional');
	    $re->{modifiers} = "$mods";
	}
	elsif (s/^\?(?=\(\?)//) {
	    my $mods = $1;
	    my $cond = atom();
	    $re = re('conditional');
	    unshift(@{$re->{Kids}}, $cond);
	}
	elsif (s/^(\?[-imsx]+)://) {
	    my $mods = $1;
	    local $extended = $extended;
	    local $insensitive = $insensitive;
	    local $multiline = $multiline;
	    local $singleline = $singleline;
	    setmods($mods);
	    $re = re('bracket');
	    $re->{modifiers} = "$mods";
	}
	elsif (s/^(\?[-imsx]+)//) {
	    my $mods = $1;
	    $re = bless { modifiers => "($mods)" }, "P5RE::Mod";	
	    setmods($mods);
	}
	elsif (s/^\?//) {
	    $re = re('UNRECOGNIZED');
	}
	else {
	    $re = re('capture');
	}

	if (not s/^\)//) { die "Expected right paren at: '$_'" }
	return $re;
    }

    # special meta
    if (s/^\.//) {
	my $s = $singleline ? '.' : '\N';
	return bless { rep => '.', sem => $s }, "P5RE::Meta";
    }
    if (s/^\^//) {
	my $s = $multiline ? '^^' : '^';
	return bless { rep => '^', sem => $s }, "P5RE::Meta";
    }
    if (s/^\$(?:$|(?=[|)]))//) {
	my $s = $multiline ? '$$' : '$';
	return bless { rep => '$', sem => $s }, "P5RE::Meta";
    }
    if (s/^([\$\@](\w+|.))//) {		# XXX need to handle subscripts here
	return bless { name => $1 }, "P5RE::Var";
    }

    # character classes
    if (s/^\[//) {
	my $re = cclass();
	if (not s/^\]//) { die "Expected right paren at: '$_'" }
	return $re;
    }

    # backwhacks
    if (/^\\(?=.)/) {
	return bless { rep => onechar() }, "P5RE::Meta";
    }

    # optimization, would happen anyway
    if (s/^(\w+)//) { return bless { text => $1 }, "P5RE::Char"; }

    # random character
    if (s/^(.)//) { return bless { text => $1 }, "P5RE::Char"; }
}

sub cclass {
    my @cclass;
    my $cclass = "";
    my $neg = 0;
    if (s/^\^//) { $neg = 1 }
    if (s/^([\]\-])//) { $cclass .= $1 }

    while ($_ ne "" and not /^\]/) {
	# backwhacks
	if (/^\\(?=.)|.-/) {
	    my $o1 = onecharobj();
	    if ($cclass ne "") {
		push @cclass, bless { text => $cclass }, "P5RE::Char";
		$cclass = "";
	    }

	    if (s/^-(?=[^]])//) {
		my $o2 = onecharobj();
		push @cclass, bless { Kids => [$o1, $o2] }, "P5RE::Range";
	    }
	    else {
		push @cclass, $o1;
	    }
	}
	elsif (s/^(\[([:=.])\^?\w*\2\])//) {
	    if ($cclass ne "") {
		push @cclass, bless { text => $cclass }, "P5RE::Char";
		$cclass = "";
	    }
	    push @cclass, bless { rep => $1 }, "P5RE::Meta";
	}
	else {
	    $cclass .= onechar();
	}
    }

    if ($cclass ne "") {
	push @cclass, bless { text => $cclass }, "P5RE::Char";
    }
    return bless { Kids => [@cclass], neg => $neg }, "P5RE::CClass";
}

sub onecharobj {
    my $ch = onechar();
    if ($ch =~ /^\\/) {
	$ch = bless { rep => $ch }, "P5RE::Meta";
    }
    else {
	$ch = bless { text => $ch }, "P5RE::Char";
    }
}

sub onechar {
    die "Oops, short cclass" unless s/^(.)//;
    my $ch = $1;
    if ($ch eq '\\') {
	if (s/^([rntf]|[0-7]{1,4})//) { $ch .= $1 }
	elsif (s/^(x[0-9a-fA-f]{1,2})//) { $ch .= $1 }
	elsif (s/^(x\{[0-9a-fA-f]+\})//) { $ch .= $1 }
	elsif (s/^([NpP]\{.*?\})//) { $ch .= $1 }
	elsif (s/^([cpP].)//) { $ch .= $1 }
	elsif (s/^(.)//) { $ch .= $1 }
	else {
	    die "Oops, short backwhack";
	}
    }
    return $ch;
}

sub setmods {
    my $mods = shift;
    if ($mods =~ /\-.*x/) {
	$extended = 0;
    }
    elsif ($mods =~ /x/) {
	$extended = 1;
    }
    if ($mods =~ /\-.*i/) {
	$insensitive = 0;
    }
    elsif ($mods =~ /i/) {
	$insensitive = 1;
    }
    if ($mods =~ /\-.*m/) {
	$multiline = 0;
    }
    elsif ($mods =~ /m/) {
	$multiline = 1;
    }
    if ($mods =~ /\-.*s/) {
	$singleline = 0;
    }
    elsif ($mods =~ /s/) {
	$singleline = 1;
    }
}

sub reparse {
    local $_ = shift;
    s/^(\W)(.*)\1(\w*)$/$2/;
    my $mod = $3;
    substr($_,0,0) = "(?$mod)" if $mod ne "";
    print $_,"\n";
    return re('re');
}

if (not caller) {
    while (my $line = <>) {
	chop $line;
	my $x = P5RE::reparse($line);
	print $x->xml();
	print "#######################################\n";
    }
}

