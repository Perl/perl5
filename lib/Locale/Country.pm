#-----------------------------------------------------------------------

=head1 NAME

Locale::Country - ISO codes for country identification (ISO 3166)

=head1 SYNOPSIS

    use Locale::Country;
    
    $country = code2country('jp');               # $country gets 'Japan'
    $code    = country2code('Norway');           # $code gets 'no'
    
    @codes   = all_country_codes();
    @names   = all_country_names();
    
    # add "uk" as a pseudo country code for United Kingdom
    Locale::Country::_alias_code('uk' => 'gb');

=cut

#-----------------------------------------------------------------------

package Locale::Country;
use strict;
require 5.002;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Locale::Country> module provides access to the ISO
codes for identifying countries, as defined in ISO 3166.
You can either access the codes via the L<conversion routines>
(described below), or with the two functions which return lists
of all country codes or all country names.

There are three different code sets you can use for identifying
countries:

=over 4

=item B<alpha-2>

Two letter codes, such as 'tv' for Tuvalu.
This code set is identified with the symbol C<LOCALE_CODE_ALPHA_2>.

=item B<alpha-3>

Three letter codes, such as 'brb' for Barbados.
This code set is identified with the symbol C<LOCALE_CODE_ALPHA_3>.

=item B<numeric>

Numeric codes, such as 064 for Bhutan.
This code set is identified with the symbol C<LOCALE_CODE_NUMERIC>.

=back

All of the routines take an optional additional argument
which specifies the code set to use.
If not specified, it defaults to the two-letter codes.
This is partly for backwards compatibility (previous versions
of this module only supported the alpha-2 codes), and
partly because they are the most widely used codes.

The alpha-2 and alpha-3 codes are not case-dependent,
so you can use 'BO', 'Bo', 'bO' or 'bo' for Bolivia.
When a code is returned by one of the functions in
this module, it will always be lower-case.

As of version 2.00, Locale::Country supports variant
names for countries. So, for example, the country code for "United States"
is "us", so country2code('United States') returns 'us'.
Now the following will also return 'us':

    country2code('United States of America') 
    country2code('USA') 

=cut

#-----------------------------------------------------------------------

require Exporter;
use Carp;
use Locale::Constants;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION   = sprintf("%d.%02d", q$Revision: 2.0 $ =~ /(\d+)\.(\d+)/);
@ISA       = qw(Exporter);
@EXPORT    = qw(code2country country2code
                all_country_codes all_country_names
		country_code2code
		LOCALE_CODE_ALPHA_2 LOCALE_CODE_ALPHA_3 LOCALE_CODE_NUMERIC);

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my $CODES     = [];
my $COUNTRIES = [];


#=======================================================================

=head1 CONVERSION ROUTINES

There are three conversion routines: C<code2country()>, C<country2code()>,
and C<country_code2code()>.

=over 8

=item code2country( CODE, [ CODESET ] )

This function takes a country code and returns a string
which contains the name of the country identified.
If the code is not a valid country code, as defined by ISO 3166,
then C<undef> will be returned:

    $country = code2country('fi');

=item country2code( STRING, [ CODESET ] )

This function takes a country name and returns the corresponding
country code, if such exists.
If the argument could not be identified as a country name,
then C<undef> will be returned:

    $code = country2code('Norway', LOCALE_CODE_ALPHA_3);
    # $code will now be 'nor'

The case of the country name is not important.
See the section L<KNOWN BUGS AND LIMITATIONS> below.

=item country_code2code( CODE, CODESET, CODESET )

This function takes a country code from one code set,
and returns the corresponding code from another code set.

    $alpha2 = country_code2code('fin',
		 LOCALE_CODE_ALPHA_3 => LOCALE_CODE_ALPHA_2);
    # $alpha2 will now be 'fi'

If the code passed is not a valid country code in
the first code set, or if there isn't a code for the
corresponding country in the second code set,
then C<undef> will be returned.

=back

=cut

#=======================================================================
sub code2country
{
    my $code = shift;
    my $codeset = @_ > 0 ? shift : LOCALE_CODE_DEFAULT;


    return undef unless defined $code;

    #-------------------------------------------------------------------
    # Make sure the code is in the right form before we use it
    # to look up the corresponding country.
    # We have to sprintf because the codes are given as 3-digits,
    # with leading 0's. Eg 052 for Barbados.
    #-------------------------------------------------------------------
    if ($codeset == LOCALE_CODE_NUMERIC)
    {
	return undef if ($code =~ /\D/);
	$code = sprintf("%.3d", $code);
    }
    else
    {
	$code = lc($code);
    }

    if (exists $CODES->[$codeset]->{$code})
    {
        return $CODES->[$codeset]->{$code};
    }
    else
    {
        #---------------------------------------------------------------
        # no such country code!
        #---------------------------------------------------------------
        return undef;
    }
}

sub country2code
{
    my $country = shift;
    my $codeset = @_ > 0 ? shift : LOCALE_CODE_DEFAULT;


    return undef unless defined $country;
    $country = lc($country);
    if (exists $COUNTRIES->[$codeset]->{$country})
    {
        return $COUNTRIES->[$codeset]->{$country};
    }
    else
    {
        #---------------------------------------------------------------
        # no such country!
        #---------------------------------------------------------------
        return undef;
    }
}

sub country_code2code
{
    (@_ == 3) or croak "country_code2code() takes 3 arguments!";

    my $code = shift;
    my $inset = shift;
    my $outset = shift;
    my $outcode = shift;
    my $country;


    return undef if $inset == $outset;
    $country = code2country($code, $inset);
    return undef if not defined $country;
    $outcode = country2code($country, $outset);
    return $outcode;
}

#=======================================================================

=head1 QUERY ROUTINES

There are two function which can be used to obtain a list of all codes,
or all country names:

=over 8

=item C<all_country_codes( [ CODESET ] )>

Returns a list of all two-letter country codes.
The codes are guaranteed to be all lower-case,
and not in any particular order.

=item C<all_country_names( [ CODESET ] )>

Returns a list of all country names for which there is a corresponding
country code in the specified code set.
The names are capitalised, and not returned in any particular order.

Not all countries have alpha-3 and numeric codes -
some just have an alpha-2 code,
so you'll get a different number of countries
depending on which code set you specify.

=back

=cut

#=======================================================================
sub all_country_codes
{
    my $codeset = @_ > 0 ? shift : LOCALE_CODE_DEFAULT;

    return keys %{ $CODES->[$codeset] };
}

sub all_country_names
{
    my $codeset = @_ > 0 ? shift : LOCALE_CODE_DEFAULT;

    return values %{ $CODES->[$codeset] };
}

#-----------------------------------------------------------------------

=head1 CODE ALIASING

This module supports a semi-private routine for specifying two letter
code aliases.

    Locale::Country::_alias_code( ALIAS => CODE [, CODESET ] )

This feature was added as a mechanism for handling
a "uk" code. The ISO standard says that the two-letter code for
"United Kingdom" is "gb", whereas domain names are all .uk.

By default the module does not understand "uk", since it is implementing
an ISO standard. If you would like 'uk' to work as the two-letter
code for United Kingdom, use the following:

    use Locale::Country;
    
    Locale::Country::_alias_code('uk' => 'gb');

With this code, both "uk" and "gb" are valid codes for United Kingdom,
with the reverse lookup returning "uk" rather than the usual "gb".

=cut

#-----------------------------------------------------------------------

sub _alias_code
{
    my $alias = shift;
    my $real  = shift;
    my $codeset = @_ > 0 ? shift : LOCALE_CODE_DEFAULT;

    my $country;


    if (not exists $CODES->[$codeset]->{$real})
    {
        carp "attempt to alias \"$alias\" to unknown country code \"$real\"\n";
        return undef;
    }
    $country = $CODES->[$codeset]->{$real};
    $CODES->[$codeset]->{$alias} = $country;
    $COUNTRIES->[$codeset]->{"\L$country"} = $alias;

    return $alias;
}

#-----------------------------------------------------------------------

=head1 EXAMPLES

The following example illustrates use of the C<code2country()> function.
The user is prompted for a country code, and then told the corresponding
country name:

    $| = 1;   # turn off buffering
    
    print "Enter country code: ";
    chop($code = <STDIN>);
    $country = code2country($code, LOCALE_CODE_ALPHA_2);
    if (defined $country)
    {
        print "$code = $country\n";
    }
    else
    {
        print "'$code' is not a valid country code!\n";
    }

=head1 DOMAIN NAMES

Most top-level domain names are based on these codes,
but there are certain codes which aren't.
If you are using this module to identify country from hostname,
your best bet is to preprocess the country code.

For example, B<edu>, B<com>, B<gov> and friends would map to B<us>;
B<uk> would map to B<gb>. Any others?

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item *

When using C<country2code()>, the country name must currently appear
exactly as it does in the source of the module. The module now supports
a small number of variants.

Possible extensions to this are: an interface for getting at the
list of variant names, and regular expression matches.

=item *

In the current implementation, all data is read in when the
module is loaded, and then held in memory.
A lazy implementation would be more memory friendly.

=item *

Support for country names in different languages.

=back

=head1 SEE ALSO

=over 4

=item Locale::Language

ISO two letter codes for identification of language (ISO 639).

=item Locale::Script

ISO codes for identification of scripts (ISO 15924).

=item Locale::Currency

ISO three letter codes for identification of currencies
and funds (ISO 4217).

=item ISO 3166

The ISO standard which defines these codes.

=item http://www.din.de/gremien/nas/nabd/iso3166ma/

Official home page for ISO 3166

=item http://www.egt.ie/standards/iso3166/iso3166-1-en.html

Another useful, but not official, home page.

=item http://www.cia.gov/cia/publications/factbook/docs/app-f.html

An appendix in the CIA world fact book which lists country codes
as defined by ISO 3166, FIPS 10-4, and internet domain names.

=back


=head1 AUTHOR

Neil Bowers E<lt>neil@bowers.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2002, Neil Bowers.

Copyright (c) 1997-2001 Canon Research Centre Europe (CRE).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the ALPHA2 hash
#=======================================================================
{
    my ($alpha2, $alpha3, $numeric);
    my ($country, @countries);


    while (<DATA>)
    {
        next unless /\S/;
        chop;
        ($alpha2, $alpha3, $numeric, @countries) = split(/:/, $_);

        $CODES->[LOCALE_CODE_ALPHA_2]->{$alpha2} = $countries[0];
	foreach $country (@countries)
	{
	    $COUNTRIES->[LOCALE_CODE_ALPHA_2]->{"\L$country"} = $alpha2;
	}

	if ($alpha3)
	{
            $CODES->[LOCALE_CODE_ALPHA_3]->{$alpha3} = $countries[0];
	    foreach $country (@countries)
	    {
		$COUNTRIES->[LOCALE_CODE_ALPHA_3]->{"\L$country"} = $alpha3;
	    }
	}

	if ($numeric)
	{
            $CODES->[LOCALE_CODE_NUMERIC]->{$numeric} = $countries[0];
	    foreach $country (@countries)
	    {
		$COUNTRIES->[LOCALE_CODE_NUMERIC]->{"\L$country"} = $numeric;
	    }
	}

    }
}

1;

__DATA__
ad:and:020:Andorra
ae:are:784:United Arab Emirates
af:afg:004:Afghanistan
ag:atg:028:Antigua and Barbuda
ai:aia:660:Anguilla
al:alb:008:Albania
am:arm:051:Armenia
an:ant:530:Netherlands Antilles
ao:ago:024:Angola
aq:::Antarctica
ar:arg:032:Argentina
as:asm:016:American Samoa
at:aut:040:Austria
au:aus:036:Australia
aw:abw:533:Aruba
az:aze:031:Azerbaijan
ba:bih:070:Bosnia and Herzegovina
bb:brb:052:Barbados
bd:bgd:050:Bangladesh
be:bel:056:Belgium
bf:bfa:854:Burkina Faso
bg:bgr:100:Bulgaria
bh:bhr:048:Bahrain
bi:bdi:108:Burundi
bj:ben:204:Benin
bm:bmu:060:Bermuda
bn:brn:096:Brunei Darussalam
bo:bol:068:Bolivia
br:bra:076:Brazil
bs:bhs:044:Bahamas
bt:btn:064:Bhutan
bv:::Bouvet Island
bw:bwa:072:Botswana
by:blr:112:Belarus
bz:blz:084:Belize
ca:can:124:Canada
cc:::Cocos (Keeling) Islands
cd:cod:180:Congo, The Democratic Republic of the:Congo, Democratic Republic of the
cf:caf:140:Central African Republic
cg:cog:178:Congo
ch:che:756:Switzerland
ci:civ:384:Cote D'Ivoire
ck:cok:184:Cook Islands
cl:chl:152:Chile
cm:cmr:120:Cameroon
cn:chn:156:China
co:col:170:Colombia
cr:cri:188:Costa Rica
cu:cub:192:Cuba
cv:cpv:132:Cape Verde
cx:::Christmas Island
cy:cyp:196:Cyprus
cz:cze:203:Czech Republic
de:deu:276:Germany
dj:dji:262:Djibouti
dk:dnk:208:Denmark
dm:dma:212:Dominica
do:dom:214:Dominican Republic
dz:dza:012:Algeria
ec:ecu:218:Ecuador
ee:est:233:Estonia
eg:egy:818:Egypt
eh:esh:732:Western Sahara
er:eri:232:Eritrea
es:esp:724:Spain
et:eth:231:Ethiopia
fi:fin:246:Finland
fj:fji:242:Fiji
fk:flk:238:Falkland Islands (Malvinas):Falkland Islands (Islas Malvinas)
fm:fsm:583:Micronesia, Federated States of
fo:fro:234:Faroe Islands
fr:fra:250:France
fx:::France, Metropolitan
ga:gab:266:Gabon
gb:gbr:826:United Kingdom:Great Britain
gd:grd:308:Grenada
ge:geo:268:Georgia
gf:guf:254:French Guiana
gh:gha:288:Ghana
gi:gib:292:Gibraltar
gl:grl:304:Greenland
gm:gmb:270:Gambia
gn:gin:324:Guinea
gp:glp:312:Guadeloupe
gq:gnq:226:Equatorial Guinea
gr:grc:300:Greece
gs:::South Georgia and the South Sandwich Islands
gt:gtm:320:Guatemala
gu:gum:316:Guam
gw:gnb:624:Guinea-Bissau
gy:guy:328:Guyana
hk:hkg:344:Hong Kong
hm:::Heard Island and McDonald Islands
hn:hnd:340:Honduras
hr:hrv:191:Croatia
ht:hti:332:Haiti
hu:hun:348:Hungary
id:idn:360:Indonesia
ie:irl:372:Ireland
il:isr:376:Israel
in:ind:356:India
io:::British Indian Ocean Territory
iq:irq:368:Iraq
ir:irn:364:Iran, Islamic Republic of:Iran
is:isl:352:Iceland
it:ita:380:Italy
jm:jam:388:Jamaica
jo:jor:400:Jordan
jp:jpn:392:Japan
ke:ken:404:Kenya
kg:kgz:417:Kyrgyzstan
kh:khm:116:Cambodia
ki:kir:296:Kiribati
km:com:174:Comoros
kn:kna:659:Saint Kitts and Nevis
kp:prk:408:Korea, Democratic People's Republic of:Korea, North:North Korea
kr:kor:410:Korea, Republic of:Korea, South:South Korea
kw:kwt:414:Kuwait
ky:cym:136:Cayman Islands
kz:kaz:398:Kazakstan
la:lao:418:Lao People's Democratic Republic
lb:lbn:422:Lebanon
lc:lca:662:Saint Lucia
li:lie:438:Liechtenstein
lk:lka:144:Sri Lanka
lr:lbr:430:Liberia
ls:lso:426:Lesotho
lt:ltu:440:Lithuania
lu:lux:442:Luxembourg
lv:lva:428:Latvia
ly:lby:434:Libyan Arab Jamahiriya:Libya
ma:mar:504:Morocco
mc:mco:492:Monaco
md:mda:498:Moldova, Republic of
mg:mdg:450:Madagascar
mh:mhl:584:Marshall Islands
mk:mkd:807:Macedonia, the Former Yugoslav Republic of:Macedonia, Former Yugoslav Republic of:Macedonia
ml:mli:466:Mali
mm:mmr:104:Myanmar
mn:mng:496:Mongolia
mo:mac:446:Macau
mp:mnp:580:Northern Mariana Islands
mq:mtq:474:Martinique
mr:mrt:478:Mauritania
ms:msr:500:Montserrat
mt:mlt:470:Malta
mu:mus:480:Mauritius
mv:mdv:462:Maldives
mw:mwi:454:Malawi
mx:mex:484:Mexico
my:mys:458:Malaysia
mz:moz:508:Mozambique
na:nam:516:Namibia
nc:ncl:540:New Caledonia
ne:ner:562:Niger
nf:nfk:574:Norfolk Island
ng:nga:566:Nigeria
ni:nic:558:Nicaragua
nl:nld:528:Netherlands
no:nor:578:Norway
np:npl:524:Nepal
nr:nru:520:Nauru
nu:niu:570:Niue
nz:nzl:554:New Zealand
om:omn:512:Oman
pa:pan:591:Panama
pe:per:604:Peru
pf:pyf:258:French Polynesia
pg:png:598:Papua New Guinea
ph:phl:608:Philippines
pk:pak:586:Pakistan
pl:pol:616:Poland
pm:spm:666:Saint Pierre and Miquelon
pn:pcn:612:Pitcairn:Pitcairn Island
pr:pri:630:Puerto Rico
ps:pse:275:Palestinian Territory, Occupied
pt:prt:620:Portugal
pw:plw:585:Palau
py:pry:600:Paraguay
qa:qat:634:Qatar
re:reu:638:Reunion
ro:rom:642:Romania
ru:rus:643:Russian Federation:Russia
rw:rwa:646:Rwanda
sa:sau:682:Saudi Arabia
sb:slb:090:Solomon Islands
sc:syc:690:Seychelles
sd:sdn:736:Sudan
se:swe:752:Sweden
sg:sgp:702:Singapore
sh:shn:654:Saint Helena
si:svn:705:Slovenia
sj:sjm:744:Svalbard and Jan Mayen:Jan Mayen:Svalbard
sk:svk:703:Slovakia
sl:sle:694:Sierra Leone
sm:smr:674:San Marino
sn:sen:686:Senegal
so:som:706:Somalia
sr:sur:740:Suriname
st:stp:678:Sao Tome and Principe
sv:slv:222:El Salvador
sy:syr:760:Syrian Arab Republic:Syria
sz:swz:748:Swaziland
tc:tca:796:Turks and Caicos Islands
td:tcd:148:Chad
tf:::French Southern Territories
tg:tgo:768:Togo
th:tha:764:Thailand
tj:tjk:762:Tajikistan
tk:tkl:772:Tokelau
tm:tkm:795:Turkmenistan
tn:tun:788:Tunisia
to:ton:776:Tonga
tp:tmp:626:East Timor
tr:tur:792:Turkey
tt:tto:780:Trinidad and Tobago
tv:tuv:798:Tuvalu
tw:twn:158:Taiwan, Province of China:Taiwan
tz:tza:834:Tanzania, United Republic of:Tanzania
ua:ukr:804:Ukraine
ug:uga:800:Uganda
um:::United States Minor Outlying Islands
us:usa:840:United States:USA:United States of America
uy:ury:858:Uruguay
uz:uzb:860:Uzbekistan
va:vat:336:Holy See (Vatican City State):Hole See (Vatican City)
vc:vct:670:Saint Vincent and the Grenadines
ve:ven:862:Venezuela
vg:vgb:092:Virgin Islands, British:British Virgin Islands
vi:vir:850:Virgin Islands, U.S.
vn:vnm:704:Vietnam
vu:vut:548:Vanuatu
wf:wlf:876:Wallis and Futuna
ws:wsm:882:Samoa
ye:yem:887:Yemen
yt:::Mayotte
yu:yug:891:Yugoslavia
za:zaf:710:South Africa
zm:zmb:894:Zambia
zr:::Zaire
zw:zwe:716:Zimbabwe
