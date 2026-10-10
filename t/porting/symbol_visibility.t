#!perl

use strict;
use warnings;

chdir 't' if -d 't';

require './test.pl';

plan(1);

my $regen = '../regen/embed.pl';

# Make sure the sum of the lengths of the contents of the lists hasn't
# changed.
my %list_names = (
 '%unresolved_visibility_overrides' => 1,
 '@unresolved_visibility_overrides_but_extensions_definitely_need_these' => 1,
);
my $list_re = join '|', keys %list_names;

open my $regen_fh, '<', $regen or die "Can't open $regen: $!";

my $string = "";

LIST:
while (keys %list_names) {
    while (defined (my $line = <$regen_fh>)) {
        next unless $line =~ /my \s+ ($list_re) \s+ = \s+ /x;
        delete $list_names{$1};

        <$regen_fh>;    # Don't include the header

        while (defined ($line = <$regen_fh>)) {
            next LIST if $line =~ / ^ \s* \); /x;
            $string .= $line;
        }

        last;
    }
}
die "Could not parse $regen" if keys %list_names;

close $regen_fh or die "Couldn't close $regen: $!";

my $new_length = length $string;

my $length_file = 'porting/symbol_visibility.dat';

open my $data_fh, '<', $length_file or die "Can't open $length_file: $!";
my $stored_length = join "", <$data_fh>;
close $data_fh or die "Couldn't close $length_file: $!";
chomp $stored_length;

if ($stored_length eq "") {
    fail("$length_file shouldn't be empty");
    exit 1;
}

# If there was a conflict, remove all but the final numeric value.  This makes
# rebasing more convenient 
$stored_length =~ s/^<<<<<<< HEAD\n\d+\n=======\n//;
$stored_length =~ s/\n>>>>>>> .*//;
if ($stored_length !~ /\d/ || $stored_length =~ /\D/) {
    fail("Unexpected syntax in $length_file:\n$stored_length");
    exit 1;
}

if (! is($new_length, $stored_length,
         "regen/embed.pl: unresolved lists length unchanged"))
{
    if ($new_length < $stored_length) {
        open my $data_fh, '>', $length_file
                                         or die "Can't open $length_file: $!";
        diag(<<~"EOT");
            Thank you for removing unresolved symbols.
            Now you must commit the change.
            EOT

        print $data_fh $new_length, "\n";
        close $data_fh or die "Couldn't close $length_file: $!";
    }
    else {
        my $msg = "Thou shalt not add any symbols to any of: "
                . join " or ", keys(%list_names)
                . "\nin $regen.  See \"Symbol visibility\" in perlhacktips.";
        $msg .= <<EOT;
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
