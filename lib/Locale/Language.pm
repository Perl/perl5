#-----------------------------------------------------------------------

=head1 NAME

Locale::Language - ISO two letter codes for language identification (ISO 639)

=head1 SYNOPSIS

    use Locale::Language;
    
    $lang = code2language('en');        # $lang gets 'English'
    $code = language2code('French');    # $code gets 'fr'
    
    @codes   = all_language_codes();
    @names   = all_language_names();

=cut

#-----------------------------------------------------------------------

package Locale::Language;
use strict;
require 5.002;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Locale::Language> module provides access to the ISO two-letter
codes for identifying languages, as defined in ISO 639. You can either
access the codes via the L<conversion routines> (described below),
or with the two functions which return lists of all language codes or
all language names.

=cut

#-----------------------------------------------------------------------

require Exporter;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT);
$VERSION      = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);
@ISA          = qw(Exporter);
@EXPORT       = qw(&code2language &language2code
                   &all_language_codes &all_language_names );

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my %CODES     = ();
my %LANGUAGES = ();


#=======================================================================

=head1 CONVERSION ROUTINES

There are two conversion routines: C<code2language()> and C<language2code()>.

=over 8

=item code2language()

This function takes a two letter language code and returns a string
which contains the name of the language identified. If the code is
not a valid language code, as defined by ISO 639, then C<undef>
will be returned.

    $lang = code2language($code);

=item language2code()

This function takes a language name and returns the corresponding
two letter language code, if such exists.
If the argument could not be identified as a language name,
then C<undef> will be returned.

    $code = language2code('French');

The case of the language name is not important.
See the section L<KNOWN BUGS AND LIMITATIONS> below.

=back

=cut

#=======================================================================
sub code2language
{
    my $code = shift;


    return undef unless defined $code;
    $code = lc($code);
    if (exists $CODES{$code})
    {
        return $CODES{$code};
    }
    else
    {
        #---------------------------------------------------------------
        # no such language code!
        #---------------------------------------------------------------
        return undef;
    }
}

sub language2code
{
    my $lang = shift;


    return undef unless defined $lang;
    $lang = lc($lang);
    if (exists $LANGUAGES{$lang})
    {
        return $LANGUAGES{$lang};
    }
    else
    {
        #---------------------------------------------------------------
        # no such language!
        #---------------------------------------------------------------
        return undef;
    }
}

#=======================================================================

=head1 QUERY ROUTINES

There are two function which can be used to obtain a list of all
language codes, or all language names:

=over 8

=item C<all_language_codes()>

Returns a list of all two-letter language codes.
The codes are guaranteed to be all lower-case,
and not in any particular order.

=item C<all_language_names()>

Returns a list of all language names for which there is a corresponding
two-letter language code. The names are capitalised, and not returned
in any particular order.

=back

=cut

#=======================================================================
sub all_language_codes
{
    return keys %CODES;
}

sub all_language_names
{
    return values %CODES;
}

#-----------------------------------------------------------------------

=head1 EXAMPLES

The following example illustrates use of the C<code2language()> function.
The user is prompted for a language code, and then told the corresponding
language name:

    $| = 1;    # turn off buffering
    
    print "Enter language code: ";
    chop($code = <STDIN>);
    $lang = code2language($code);
    if (defined $lang)
    {
        print "$code = $lang\n";
    }
    else
    {
        print "'$code' is not a valid language code!\n";
    }

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item *

In the current implementation, all data is read in when the
module is loaded, and then held in memory.
A lazy implementation would be more memory friendly.

=item *

Currently just supports the two letter language codes -
there are also three-letter codes, and numbers.
Would these be of any use to anyone?

=back

=head1 SEE ALSO

=over 4

=item Locale::Country

ISO codes for identification of country (ISO 3166).
Supports 2-letter, 3-letter, and numeric country codes.

=item Locale::Currency

ISO three letter codes for identification of currencies and funds (ISO 4217).

=item ISO 639:1988 (E/F)

Code for the representation of names of languages.

=item http://lcweb.loc.gov/standards/iso639-2/langhome.html

Home page for ISO 639-2

=back


=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997-2001 Canon Research Centre Europe (CRE).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the CODES hash
#=======================================================================
{
    no utf8; # __DATA__ contains Latin-1

    my $code;
    my $language;


    while (<DATA>)
    {
	next unless /\S/;
        chop;
        ($code, $language) = split(/:/, $_, 2);
        $CODES{$code} = $language;
        $LANGUAGES{"\L$language"} = $code;
    }
}

1;

__DATA__
aa:Afar
ab:Abkhazian
ae:Avestan
af:Afrikaans
am:Amharic
ar:Arabic
as:Assamese
ay:Aymara
az:Azerbaijani

ba:Bashkir
be:Belarusian
bg:Bulgarian
bh:Bihari
bi:Bislama
bn:Bengali
bo:Tibetan
br:Breton
bs:Bosnian

ca:Catalan
ce:Chechen
ch:Chamorro
co:Corsican
cs:Czech
cu:Church Slavic
cv:Chuvash
cy:Welsh

da:Danish
de:German
dz:Dzongkha

el:Greek
en:English
eo:Esperanto
es:Spanish
et:Estonian
eu:Basque

fa:Persian
fi:Finnish
fj:Fijian
fo:Faeroese
fr:French
fy:Frisian

ga:Irish
gd:Gaelic (Scots)
gl:Gallegan
gn:Guarani
gu:Gujarati
gv:Manx

ha:Hausa
he:Hebrew
hi:Hindi
ho:Hiri Motu
hr:Croatian
hu:Hungarian
hy:Armenian
hz:Herero

ia:Interlingua
id:Indonesian
ie:Interlingue
ik:Inupiaq
is:Icelandic
it:Italian
iu:Inuktitut

ja:Japanese
jw:Javanese

ka:Georgian
ki:Kikuyu
kj:Kuanyama
kk:Kazakh
kl:Kalaallisut
km:Khmer
kn:Kannada
ko:Korean
ks:Kashmiri
ku:Kurdish
kv:Komi
kw:Cornish
ky:Kirghiz

la:Latin
lb:Letzeburgesch
ln:Lingala
lo:Lao
lt:Lithuanian
lv:Latvian

mg:Malagasy
mh:Marshall
mi:Maori
mk:Macedonian
ml:Malayalam
mn:Mongolian
mo:Moldavian
mr:Marathi
ms:Malay
mt:Maltese
my:Burmese

na:Nauru
nb:Norwegian Bokmål
nd:Ndebele, North
ne:Nepali
ng:Ndonga
nl:Dutch
nn:Norwegian Nynorsk
no:Norwegian
nr:Ndebele, South
nv:Navajo
ny:Chichewa; Nyanja

oc:Occitan (post 1500)
om:Oromo
or:Oriya
os:Ossetian; Ossetic

pa:Panjabi
pi:Pali
pl:Polish
ps:Pushto
pt:Portuguese

qu:Quechua

rm:Rhaeto-Romance
rn:Rundi
ro:Romanian
ru:Russian
rw:Kinyarwanda

sa:Sanskrit
sc:Sardinian
sd:Sindhi
se:Sami
sg:Sango
si:Sinhalese
sk:Slovak
sl:Slovenian
sm:Samoan
sn:Shona
so:Somali
sq:Albanian
sr:Serbian
ss:Swati
st:Sotho
su:Sundanese
sv:Swedish
sw:Swahili

ta:Tamil
te:Telugu
tg:Tajik
th:Thai
ti:Tigrinya
tk:Turkmen
tl:Tagalog
tn:Tswana
to:Tonga
tr:Turkish
ts:Tsonga
tt:Tatar
tw:Twi

ug:Uighur
uk:Ukrainian
ur:Urdu
uz:Uzbek

vi:Vietnamese
vo:Volapük

wo:Wolof

xh:Xhosa

yi:Yiddish
yo:Yoruba

za:Zhuang
zh:Chinese
zu:Zulu
