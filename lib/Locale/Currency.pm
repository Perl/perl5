#-----------------------------------------------------------------------

=head1 NAME

Locale::Currency - ISO three letter codes for currency identification (ISO 4217)

=head1 SYNOPSIS

    use Locale::Currency;

    $curr = code2currency('usd');     # $curr gets 'US Dollar'
    $code = currency2code('Euro');    # $code gets 'eur'

    @codes   = all_currency_codes();
    @names   = all_currency_names();

=cut

#-----------------------------------------------------------------------

package Locale::Currency;
use strict;
require 5.002;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Locale::Currency> module provides access to the ISO three-letter
codes for identifying currencies and funds, as defined in ISO 4217.
You can either access the codes via the L<conversion routines>
(described below),
or with the two functions which return lists of all currency codes or
all currency names.

There are two special codes defined by the standard which aren't
understood by this module:

=over 4

=item XTS

Specifically reserved for testing purposes.

=item XXX

For transactions where no currency is involved.

=back

=cut

#-----------------------------------------------------------------------

require Exporter;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT);
$VERSION      = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);
@ISA          = qw(Exporter);
@EXPORT       = qw(&code2currency &currency2code
                   &all_currency_codes &all_currency_names );

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my %CODES      = ();
my %CURRENCIES = ();


#=======================================================================

=head1 CONVERSION ROUTINES

There are two conversion routines: C<code2currency()> and C<currency2code()>.

=over 8

=item code2currency()

This function takes a three letter currency code and returns a string
which contains the name of the currency identified. If the code is
not a valid currency code, as defined by ISO 4217, then C<undef>
will be returned.

    $curr = code2currency($code);

=item currency2code()

This function takes a currency name and returns the corresponding
three letter currency code, if such exists.
If the argument could not be identified as a currency name,
then C<undef> will be returned.

    $code = currency2code('French Franc');

The case of the currency name is not important.
See the section L<KNOWN BUGS AND LIMITATIONS> below.

=back

=cut

#=======================================================================
sub code2currency
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
        # no such currency code!
        #---------------------------------------------------------------
        return undef;
    }
}

sub currency2code
{
    my $curr = shift;


    return undef unless defined $curr;
    $curr = lc($curr);
    if (exists $CURRENCIES{$curr})
    {
        return $CURRENCIES{$curr};
    }
    else
    {
        #---------------------------------------------------------------
        # no such currency!
        #---------------------------------------------------------------
        return undef;
    }
}

#=======================================================================

=head1 QUERY ROUTINES

There are two function which can be used to obtain a list of all
currency codes, or all currency names:

=over 8

=item C<all_currency_codes()>

Returns a list of all three-letter currency codes.
The codes are guaranteed to be all lower-case,
and not in any particular order.

=item C<all_currency_names()>

Returns a list of all currency names for which there is a corresponding
three-letter currency code. The names are capitalised, and not returned
in any particular order.

=back

=cut

#=======================================================================
sub all_currency_codes
{
    return keys %CODES;
}

sub all_currency_names
{
    return values %CODES;
}

#-----------------------------------------------------------------------

=head1 EXAMPLES

The following example illustrates use of the C<code2currency()> function.
The user is prompted for a currency code, and then told the corresponding
currency name:

    $| = 1;    # turn off buffering

    print "Enter currency code: ";
    chop($code = <STDIN>);
    $curr = code2currency($code);
    if (defined $curr)
    {
        print "$code = $curr\n";
    }
    else
    {
        print "'$code' is not a valid currency code!\n";
    }

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item *

In the current implementation, all data is read in when the
module is loaded, and then held in memory.
A lazy implementation would be more memory friendly.

=item *

This module also includes the special codes which are
not for a currency, such as Gold, Platinum, etc.
This might cause a problem if you're using this module
to display a list of currencies.
Let Neil know if this does cause a problem, and we can
do something about it.

=item *

ISO 4217 also defines a numeric code for each currency.
Currency codes are not currently supported by this module,
in the same way Locale::Country supports multiple codesets.

=item *

There are three cases where there is more than one
code for the same currency name.
Kwacha has two codes: mwk for Malawi, and zmk for Zambia.
The Russian Ruble has two codes: rub and rur.
The Belarussian Ruble has two codes: byr and byb.
The currency2code() function only returns one code, so
you might not get back the code you expected.

=back

=head1 SEE ALSO

=over 4

=item Locale::Country

ISO codes for identification of country (ISO 3166).

=item Locale::Script

ISO codes for identification of written scripts (ISO 15924).

=item ISO 4217:1995

Code for the representation of currencies and funds.

=item http://www.bsi-global.com/iso4217currency

Official web page for the ISO 4217 maintenance agency.
This has the latest list of codes, in MS Word format. Boo.

=back

=head1 AUTHOR

Michael Hennecke E<lt>hennecke@rz.uni-karlsruhe.deE<gt>
and
Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001 Michael Hennecke and
Canon Research Centre Europe (CRE).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the CODES hash
#=======================================================================
{
    my $code;
    my $currency;


    while (<DATA>)
    {
        next unless /\S/;
        chop;
        ($code, $currency) = split(/:/, $_, 2);
        $CODES{$code} = $currency;
        $CURRENCIES{"\L$currency"} = $code;
    }
}

1;

__DATA__
adp:Andorran Peseta
aed:UAE Dirham
afa:Afghani
all:Lek
amd:Armenian Dram
ang:Netherlands Antillean Guilder
aoa:Kwanza
aon:New Kwanza
aor:Kwanza Reajustado
ars:Argentine Peso
ats:Schilling
aud:Australian Dollar
awg:Aruban Guilder
azm:Azerbaijanian Manat

bam:Convertible Marks
bbd:Barbados Dollar
bdt:Taka
bef:Belgian Franc
bgl:Lev
bgn:Bulgarian Lev
bhd:Bahraini Dinar
bhd:Dinar
bif:Burundi Franc
bmd:Bermudian Dollar
bnd:Brunei Dollar
bob:Boliviano
bov:MVDol
brl:Brazilian Real
bsd:Bahamian Dollar
btn:Ngultrum
bwp:Pula
byb:Belarussian Ruble
byr:Belarussian Ruble
bzd:Belize Dollar

cad:Candian Dollar
cdf:Franc Congolais
chf:Swiss Franc
clf:Unidades de Formento
clp:Chilean Peso
cny:Yuan Renminbi
cop:Colombian Peso
crc:Costa Rican Colon
cup:Cuban Peso
cve:Cape Verde Escudo
cyp:Cyprus Pound
czk:Czech Koruna

dem:German Mark
djf:Djibouti Franc
dkk:Danish Krone
dop:Dominican Peso
dzd:Algerian Dinar

ecs:Sucre
ecv:Unidad de Valor Constante (UVC)
eek:Kroon
egp:Egyptian Pound
ern:Nakfa
esp:Spanish Peseta
etb:Ethiopian Birr
eur:Euro

fim:Markka
fjd:Fiji Dollar
fkp:Falkland Islands Pound
frf:French Franc

gbp:Pound Sterling
gel:Lari
ghc:Cedi
gip:Gibraltar Pound
gmd:Dalasi
gnf:Guinea Franc
grd:Drachma
gtq:Quetzal
gwp:Guinea-Bissau Peso
gyd:Guyana Dollar

hkd:Hong Kong Dollar
hnl:Lempira
hrk:Kuna
htg:Gourde
huf:Forint

idr:Rupiah
iep:Irish Pound
ils:Shekel
inr:Indian Rupee
iqd:Iraqi Dinar
irr:Iranian Rial
isk:Iceland Krona
itl:Italian Lira

jmd:Jamaican Dollar
jod:Jordanian Dinar
jpy:Yen

kes:Kenyan Shilling
kgs:Som
khr:Riel
kmf:Comoro Franc
kpw:North Korean Won
krw:Won
kwd:Kuwaiti Dinar
kyd:Cayman Islands Dollar
kzt:Tenge

lak:Kip
lbp:Lebanese Pound
lkr:Sri Lanka Rupee
lrd:Liberian Dollar
lsl:Loti
ltl:Lithuanian Litas
luf:Luxembourg Franc
lvl:Latvian Lats
lyd:Libyan Dinar

mad:Moroccan Dirham
mdl:Moldovan Leu
mgf:Malagasy Franc
mkd:Denar
mmk:Kyat
mnt:Tugrik
mop:Pataca
mro:Ouguiya
mtl:Maltese Lira
mur:Mauritius Rupee
mvr:Rufiyaa
mwk:Kwacha
mxn:Mexican Nuevo Peso
myr:Malaysian Ringgit
mzm:Metical

nad:Namibia Dollar
ngn:Naira
nio:Cordoba Oro
nlg:Netherlands Guilder
nok:Norwegian Krone
npr:Nepalese Rupee
nzd:New Zealand Dollar

omr:Rial Omani

pab:Balboa
pen:Nuevo Sol
pgk:Kina
php:Philippine Peso
pkr:Pakistan Rupee
pln:Zloty
pte:Portuguese Escudo
pyg:Guarani

qar:Qatari Rial

rol:Leu
rub:Russian Ruble
rur:Russian Ruble
rwf:Rwanda Franc

sar:Saudi Riyal
sbd:Solomon Islands Dollar
scr:Seychelles Rupee
sdd:Sudanese Dinar
sek:Swedish Krona
sgd:Singapore Dollar
shp:St. Helena Pound
sit:Tolar
skk:Slovak Koruna
sll:Leone
sos:Somali Shilling
srg:Surinam Guilder
std:Dobra
svc:El Salvador Colon
syp:Syrian Pound
szl:Lilangeni

thb:Baht
tjr:Tajik Ruble
tmm:Manat
tnd:Tunisian Dollar
top:Pa'anga
tpe:Timor Escudo
trl:Turkish Lira
ttd:Trinidad and Tobago Dollar
twd:New Taiwan Dollar
tzs:Tanzanian Shilling

uah:Hryvnia
uak:Karbovanets
ugx:Uganda Shilling
usd:US Dollar
usn:US Dollar (Next day)
uss:US Dollar (Same day)
uyu:Peso Uruguayo
uzs:Uzbekistan Sum

veb:Bolivar
vnd:Dong
vuv:Vatu

wst:Tala

xaf:CFA Franc BEAC
xag:Silver
xau:Gold
xba:European Composite Unit
xbb:European Monetary Unit
xbc:European Unit of Account 9
xb5:European Unit of Account 17
xcd:East Caribbean Dollar
xdr:SDR
xeu:ECU (until 1998-12-31)
xfu:UIC-Franc
xfo:Gold-Franc
xof:CFA Franc BCEAO
xpd:Palladium
xpf:CFP Franc
xpt:Platinum

yer:Yemeni Rial
yum:New Dinar

zal:Financial Rand
zar:Rand
zmk:Kwacha
zrn:New Zaire
zwd:Zimbabwe Dollar
