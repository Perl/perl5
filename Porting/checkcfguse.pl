#!/usr/bin/perl -w

#
# checkcfguse.pl
#
# (1) finds all the Configure/config symbols
#
# (2) greps for their use in the core files and shows which ones.
#

use strict;
use warnings;

my %SYM;

my @PAT =
    (
     [
      # The format is:
      # (1) aref of filename glob patterns
      # (2) aref of qr patterns, the submatch $1 is the symbol name
      [
       "config_h.SH",
      ],
      [
       qr/^#\$(\w+)\s+(\w+)/,
      ],
     ],
     [
      [
       "Porting/config.sh",
       "plan9/config_h.sample",
       "win32/config_H.??",
      ],
      qr{^(?:\Q/*\E)?#(?:define|undef)\s+(\w+)},
     ],
     [
      [
       "configure.com",
      ],
      qr{^(\w+)="(?:define|undef)"},
     ],
    );

{
  print STDERR "$0: Looking for symbols...\n";
  for my $pat (@PAT) {
    for my $fn (map { glob($_) } @{ $pat->[0] }) {
      if (open(my $fh, '<', $fn)) {
        while (<$fh>) {
          for my $p (@$pat) {
            for my $sym (/$p/g) {
              $SYM{$sym}{$fn}++;
            }
          }
        }
      }
    }
  }
}

printf(STDERR "$0: Found %d symbols\n", scalar keys %SYM);

print STDERR "$0: Looking for their uses...\n";

# Much too noisy grepping.
delete $SYM{'_'};
delete $SYM{'const'};

my $SYM = join("|", sort { length($b) <=> length($a) || $a cmp $b } keys %SYM);

my %found;
foreach my $manifest_file ('MANIFEST', 'Porting/MANIFEST.dev') {
  open(my $mani, '<', $manifest_file)
    or die "$0: Failed to open '$manifest_file'\n";

  while (<$mani>) {
    if (/^(\S+)\s+/) {
      my $fn = $1;
      # Skip matches from the config files themselves,
      # from metaconfig generated files that refer to
      # the config symbols, and from pods.
      next if $fn =~ m{^(?:config_h\.SH
                          |Configure
                          |configure\.com
                          |Porting/(?:config|Glossary)
                          |(?:plan9|win32)/(?:config|(?:GNU)?[Mm]akefile)
                          |uconfig)
                          |\.pod$}x;
      open my $fh, '<', $fn or die qq[$0: Failed to open $fn: $!];
      while (<$fh>) {
        while (/\b($SYM)\b/go) {
          $found{$1}{$fn}++;
        }
      }
    }
  }
}
for my $sym (sort keys %SYM) {
  if (exists $found{$sym}) {
    my @found = keys %{$found{$sym}};
    print "$sym\t", join(" ", sort @found), "\n";
  } else {
    print "$sym\n";
  }
}
