#!./perl

use strict;
use Test::More;
plan tests => 11;

my $DICT = <<EOT;
Aarhus
Aaron
Ababa
aback
abaft
abandon
abandoned
abandoning
abandonment
abandons
abase
abased
abasement
abasements
abases
abash
abashed
abashes
abashing
abasing
abate
abated
abatement
abatements
abater
abates
abating
Abba
EOT

use Search::Dict;

open(DICT, "+>dict-$$") or die "Can't create dict-$$: $!";
binmode DICT;			# To make length expected one.
print DICT $DICT;

my $word;

my $pos = look *DICT, "Ababa";
chomp($word = <DICT>);
cmp_ok $pos, ">=", 0;
is $word, "Ababa";

if (ord('a') > ord('A') ) {  # ASCII

    $pos = look *DICT, "foo";
    $word = <DICT>;

    is $pos, length($DICT);  # will search to end of file

    my $pos = look *DICT, "abash";
    chomp($word = <DICT>);
    cmp_ok $pos, ">=", 0;
    is $word, "abash";
}
else { # EBCDIC systems e.g. os390

    $pos = look *DICT, "FOO";
    $word = <DICT>;

    is $pos, length($DICT);  # will search to end of file

    my $pos = look *DICT, "Abba";
    chomp($word = <DICT>);
    cmp_ok $pos, ">=", 0;
    is $word, "Abba";
}

$pos = look *DICT, "aarhus", 1, 1;
chomp($word = <DICT>);

cmp_ok $pos, ">=", 0;
is $word, "Aarhus";

close DICT or die "cannot close";
unlink "dict-$$";

{
    open my $strfh, "<", \$DICT or die $!;

    {
	my $pos = look $strfh, 'Ababa';
	chomp($word = <$strfh>);
	cmp_ok $pos, ">=", 0;
	is $word, "Ababa";
    }

    {
	my $pos = look $strfh, "aarhus", 1, 1;
	chomp($word = <$strfh>);
	cmp_ok $pos, ">=", 0;
	is $word, "Aarhus";
    }

    close $strfh;
}
