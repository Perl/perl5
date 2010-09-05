package Unicode::Collate::Locale;

use strict;
use Carp;
use base qw(Unicode::Collate);

our $VERSION = '0.59';

use File::Spec;

(my $ModPath = $INC{'Unicode/Collate/Locale.pm'}) =~ s/\.pm$//;
my $KeyPath = File::Spec->catfile('allkeys.txt');
my $PL_EXT  = '.pl';

my %LocaleFile = map { ($_, $_) } qw(
   af az ca cs cy da eo es et fi fil fo fr ha haw
   is kl lt lv mt nn pl ro sk sl sv sw tr wo yo
);
   $LocaleFile{'default'}         = '';
   $LocaleFile{'es__traditional'} = 'es_trad';
   $LocaleFile{'nb'} = 'nn';

sub _locale {
    my $locale = shift;
    if ($locale) {
	$locale = lc $locale;
	$locale =~ tr/\-\ \./_/;
	$locale =~ s/_trad\z/_traditional/;
	$LocaleFile{$locale} and return $locale;

	my ($l,$t,$v) = split(/_/, $locale.'__');
	for my $loc ("${l}_${t}_$v", "${l}_$t", "${l}__$v", "${l}__$t", $l) {
	    $LocaleFile{$loc} and return $loc;
	}
    }
    return 'default';
}

sub getlocale {
    return shift->{accepted_locale};
}

sub _fetchpl {
    my $accepted = shift;
    my $f = $LocaleFile{$accepted};
    return if !$f;
    $f .= $PL_EXT;
    my $path = File::Spec->catfile($ModPath, $f);
    my $h = do $path;
    croak "Unicode/Collate/Locale/$f can't be found" if !$h;
    return $h;
}

sub new {
    my $class = shift;
    my %hash = @_;
    $hash{accepted_locale} = _locale($hash{locale});

    if (exists $hash{table}) {
	croak "your table can't be used with Unicode::Collate::Locale";
    }
    $hash{table} = $KeyPath;

    my $href = _fetchpl($hash{accepted_locale});
    while (my($k,$v) = each %$href) {
	if (exists $hash{$k}) {
	    croak "$k is reserved by $hash{locale}, can't be overwritten";
	}
	$hash{$k} = $v;
    }
    return $class->SUPER::new(%hash);
}

1;
__END__

=head1 NAME

Unicode::Collate::Locale - Linguistic tailoring for DUCET via Unicode::Collate

=head1 SYNOPSIS

  use Unicode::Collate::Locale;

  $Collator = Unicode::Collate::Locale->
      new(locale => $locale_name, %tailoring);

  @sorted = $Collator->sort(@not_sorted);

=head1 DESCRIPTION

This module provides linguistic tailoring for it
taking advantage of C<Unicode::Collate>.

=head2 Constructor

The C<new> method returns a collator object.

A parameter list for the constructor is a hash, which can include
a special key C<'locale'> and its value (case-insensitive) standing
for a two-letter language code (ISO-639) like C<'en'> for English.
For example, C<Unicode::Collate::Locale-E<gt>new(locale =E<gt> 'FR')>
returns a collator tailored for French.

C<$locale_name> may be suffixed with a territory(country)
code or a variant code, which are separated with C<'_'>.
E.g. C<en_US> for English in USA,
C<es_ES_traditional> for Spanish in Spain (Traditional),

If C<$localename> is not defined,
fallback is selected in the following order:

    1. language_territory_variant
    2. language_territory
    3. language__variant
    4. language
    5. default

Tailoring tags provided by C<Unicode::Collate> are allowed
as long as they are not used for C<'locale'> support.
Esp. the C<table> tag is always untailorable
since it is reserved for DUCET.

E.g. a collator for French, which ignores diacritics and case difference
(i.e. level 1), with reversed case ordering and no normalization.

    Unicode::Collate::Locale->new(
        level => 1,
        locale => 'fr',
        upper_before_lower => 1,
        normalization => undef
    )

=head2 Methods

C<Unicode::Collate::Locale> is a subclass of C<Unicode::Collate>
and methods other than C<new> are inherited from C<Unicode::Collate>.

Here is a list of additional methods:

=over 4

=item C<$Collator-E<gt>getlocale>

Returns a language code accepted and used actually on collation.
If linguistic tailoring is not provided for a language code you passed
(intensionally for some languages, or due to the incomplete implementation),
this method returns a string C<'default'> meaning no special tailoring.

=back

=head2 A list of tailorable locales

      locale name       description
    ----------------------------------------------------------
      af                Afrikaans
      az                Azerbaijani (Azeri)
      ca                Catalan
      cs                Czech
      cy                Welsh
      da                Danish
      eo                Esperanto
      es                Spanish
      es__traditional   Spanish ('ch' and 'll' as a grapheme)
      et                Estonian
      fi                Finnish
      fil               Filipino
      fo                Faroese
      fr                French
      ha                Hausa
      haw               Hawaiian
      is                Icelandic
      kl                Kalaallisut
      lt                Lithuanian
      lv                Latvian
      mt                Maltese
      nb                Norwegian Bokmal
      nn                Norwegian Nynorsk
      pl                Polish
      ro                Romanian
      sk                Slovak
      sl                Slovenian
      sv                Swedish
      sw                Swahili
      tr                Turkish
      wo                Wolof
      yo                Yoruba

=head1 INSTALL

Installation of Unicode::Collate::Locale requires F<Collate/Locale.pm>,
F<Collate/Locale/*.pm> and F<Collate/allkeys.txt>.  On building,
Unicode::Collate::Locale doesn't require F<data/*.txt> and F<mklocale>.
Tests for Unicode::Collate::Locale are named F<t/loc_*.t>.

=head1 AUTHOR

The Unicode::Collate::Locale module for perl was written
by SADAHIRO Tomoyuki, <SADAHIRO@cpan.org>.
This module is Copyright(C) 2004-2010, SADAHIRO Tomoyuki. Japan.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item Unicode Collation Algorithm - UTS #10

L<http://www.unicode.org/reports/tr10/>

=item The Default Unicode Collation Element Table (DUCET)

L<http://www.unicode.org/Public/UCA/latest/allkeys.txt>

=item CLDR - Unicode Common Locale Data Repository

L<http://cldr.unicode.org/>

=item L<Unicode::Collate>

=item L<Unicode::Normalize>

=back

=cut
