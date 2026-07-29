#!perl

use strict;
use warnings;

chdir 't' if -d 't';

require './test.pl';

plan(1);

my $regen = '../regen/embed.pl';
my $array_name = '@unresolved_visibility_overrides';

open my $regen_fh, '<', $regen or die "Can't open $regen: $!";

my $string = "";

while (<$regen_fh>) {
    next unless /my \s+ $array_name \s+ = \s+ qw\(/x;

    while (<$regen_fh>) {
        goto found if / ^ \s* \); /x;
        $string .= $_;
    }
    
    last;
}

die "Could not parse $regen";

found:

close $regen_fh or die "Couldn't close $regen: $!";

my $new_length = length $string;

my $length_file = 'porting/symbol_visibility.dat';

open my $data_fh, '<', $length_file or die "Can't open $length_file: $!";
my $stored_length = <$data_fh>;
close $data_fh or die "Couldn't close $length_file: $!";
chomp $stored_length;

if (! is($new_length, $stored_length,
         "regen/embed.pl: '$array_name' length unchanged"))
{
    if ($new_length < $stored_length) {
        open my $data_fh, '>', $length_file
                                         or die "Can't open $length_file: $!";
        diag(<<~"EOT");
            Thank you for removing symbol(s) from '$array_name'.
            Now you must commit the change.
            EOT

        print $data_fh $new_length, "\n";
        close $data_fh or die "Couldn't close $length_file: $!";
    }
    else {
        diag(<<EOT);
Thou shalt not add anything to $array_name in
$regen.  See "Symbol visibility" in perlhacktips.

The preferred solution is to document the symbols, as described in
'embed.fnc'.  If you don't have time for that immediately, add them instead
to '\@pending_documentation_symbols' for now.

If the symbol(s) need to be visible only to the regex engine, add them
instead to '\@needed_by_ext_re'.

If the symbol(s) need to be visible only to some other perl extension, add
them instead to '\@needed_by_ext'.

If the symbol(s) need to be visible everywhere, and there is no plan to
document them, add them instead to '\@undocumented_always_visible'.
EOT
    }
}
