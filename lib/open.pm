package open;
use Carp;
$open::hint_bits = 0x20000;

our $VERSION = '1.01';

my $locale_encoding;

sub in_locale { $^H & $locale::hint_bits }

sub _get_locale_encoding {
    unless (defined $locale_encoding) {
	eval {
	    # I18N::Langinfo isn't available everywhere
	    require I18N::Langinfo;
	    I18N::Langinfo->import('langinfo', 'CODESET');
	};
	unless ($@) {
	    $locale_encoding = langinfo(CODESET());
	}
	my $country_language;
        if (not $locale_encoding && in_locale()) {
	    if ($ENV{LC_ALL} =~ /^([^.]+)\.([^.]+)$/) {
		($country_language, $locale_encoding) = ($1, $2);
	    } elsif ($ENV{LANG} =~ /^([^.]+)\.([^.]+)$/) {
		($country_language, $locale_encoding) = ($1, $2);
	    }
	} elsif (not $locale_encoding) {
	    if ($ENV{LC_ALL} =~ /\butf-?8\b/i ||
		$ENV{LANG}   =~ /\butf-?8\b/i) {
		$locale_encoding = 'utf8';
	    }
	    # Could do more heuristics based on the country and language
	    # parts of LC_ALL and LANG (the parts before the dot (if any)),
	    # since we have Locale::Country and Locale::Language available.
	    # TODO: get a database of Language -> Encoding mappings
	    # (the Estonian database at http://www.eki.ee/letter/
	    # would be excellent!) --jhi
	}
	if (defined $locale_encoding &&
	    $locale_encoding eq 'euc' &&
	    defined $country_language) {
	    if ($country_language =~ /^ja_JP|japan(?:ese)?$/i) {
		$locale_encoding = 'euc-jp';
	    } elsif ($country_language =~ /^ko_KR|korean?$/i) {
		$locale_encoding = 'euc-kr';
	    } elsif ($country_language =~ /^zh_TW|taiwan(?:ese)?$/i) {
		$locale_encoding = 'euc-tw';
	    }
	    croak "Locale encoding 'euc' too ambiguous"
		if $locale_encoding eq 'euc';
	}
    }
}

sub import {
    my ($class,@args) = @_;
    croak("`use open' needs explicit list of disciplines") unless @args;
    $^H |= $open::hint_bits;
    my ($in,$out) = split(/\0/,(${^OPEN} || "\0"), -1);
    while (@args) {
	my $type = shift(@args);
	my $dscp;
	if ($type =~ /^:?(utf8|locale|encoding\(.+\))$/) {
	    $type = 'IO';
	    $dscp = ":$1";
	} else {
	    $dscp = shift(@args);
	}
	my @val;
	foreach my $layer (split(/\s+/,$dscp)) {
            $layer =~ s/^://;
	    if ($layer eq 'locale') {
		use Encode;
		_get_locale_encoding()
		    unless defined $locale_encoding;
		croak "Cannot figure out an encoding to use"
		    unless defined $locale_encoding;
		if ($locale_encoding =~ /^utf-?8$/i) {
		    $layer = "utf8";
		} else {
		    $layer = "encoding($locale_encoding)";
		}
	    } else {
		unless(PerlIO::Layer::->find($layer)) {
		    carp("Unknown discipline layer '$layer'");
		}
	    }
	    push(@val,":$layer");
	    if ($layer =~ /^(crlf|raw)$/) {
		$^H{"open_$type"} = $layer;
	    }
	}
	# print "# type = $type, val = @val\n";
	if ($type eq 'IN') {
	    $in  = join(' ',@val);
	}
	elsif ($type eq 'OUT') {
	    $out = join(' ',@val);
	}
	elsif ($type eq 'IO') {
	    $in = $out = join(' ',@val);
	}
	else {
	    croak "Unknown discipline class '$type'";
	}
    }
    ${^OPEN} = join("\0",$in,$out);
}

1;
__END__

=head1 NAME

open - perl pragma to set default disciplines for input and output

=head1 SYNOPSIS

    use open IN  => ":crlf", OUT => ":raw";
    use open OUT => ':utf8';
    use open IO  => ":encoding(iso-8859-7)";

    use open IO  => ':locale';
  
    use open ':utf8';
    use open ':locale';
    use open ':encoding(iso-8859-7)';

=head1 DESCRIPTION

Full-fledged support for I/O disciplines is now implemented provided
Perl is configured to use PerlIO as its IO system (which is now the
default).

The C<open> pragma serves as one of the interfaces to declare default
"layers" (aka disciplines) for all I/O.

The C<open> pragma is used to declare one or more default layers for
I/O operations.  Any open(), readpipe() (aka qx//) and similar
operators found within the lexical scope of this pragma will use the
declared defaults.

With the C<IN> subpragma you can declare the default layers
of input sterams, and with the C<OUT> subpragma you can declare
the default layers of output streams.  With the C<IO>  subpragma
you can control both input and output streams simultaneously.

If you have a legacy encoding, you can use the C<:encoding(...)> tag.

if you want to set your encoding disciplines based on your
locale environment variables, you can use the C<:locale> tag.
For example:

    $ENV{LANG} = 'ru_RU.KOI8-R';
    # the :locale will probe the locale environment variables like LANG
    use open OUT => ':locale';
    open(O, ">koi8");
    print O chr(0x430); # Unicode CYRILLIC SMALL LETTER A = KOI8-R 0xc1
    close O;
    open(I, "<koi8");
    printf "%#x\n", ord(<I>), "\n"; # this should print 0xc1
    close I;

These are equivalent

    use open ':utf8';
    use open IO => ':utf8';

as are these

    use open ':locale';
    use open IO => ':locale';

and these

    use open ':encoding(iso-8859-7)';
    use open IO => ':encoding(iso-8859-7)';

When open() is given an explicit list of layers they are appended to
the list declared using this pragma.

Directory handles may also support disciplines in future.

=head1 NONPERLIO FUNCTIONALITY

If Perl is not built to use PerlIO as its IO system then only the two
pseudo-disciplines ":raw" and ":crlf" are available.

The ":raw" discipline corresponds to "binary mode" and the ":crlf"
discipline corresponds to "text mode" on platforms that distinguish
between the two modes when opening files (which is many DOS-like
platforms, including Windows).  These two disciplines are no-ops on
platforms where binmode() is a no-op, but perform their functions
everywhere if PerlIO is enabled.

=head1 IMPLEMENTATION DETAILS

There is a class method in C<PerlIO::Layer> C<find> which is
implemented as XS code.  It is called by C<import> to validate the
layers:

   PerlIO::Layer::->find("perlio")

The return value (if defined) is a Perl object, of class
C<PerlIO::Layer> which is created by the C code in F<perlio.c>.  As
yet there is nothing useful you can do with the object at the perl
level.

=head1 SEE ALSO

L<perlfunc/"binmode">, L<perlfunc/"open">, L<perlunicode>, L<PerlIO>,
L<encoding>

=cut
