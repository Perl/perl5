#!/usr/bin/perl
#
# t/pod-spelling.t -- Test POD spelling.

# Called to skip all tests with a reason.
sub skip_all {
    print "1..1\n";
    print "ok 1 # skip - @_\n";
    exit;
}

# Make sure we have prerequisites.  hunspell is currently not supported due to
# lack of support for contractions.
eval 'use Test::Pod 1.00';
skip_all "Test::Pod 1.00 required for testing POD" if $@;
eval 'use Pod::Spell';
skip_all "Pod::Spell required to test POD spelling" if $@;
my @spell;
for my $dir (split ':', $ENV{PATH}) {
    if (-x "$dir/ispell") {
        @spell = ("$dir/ispell", '-d', 'american', '-l');
    }
    last if @spell;
}
skip_all "ispell required to test POD spelling" unless @spell;

# Run the test, one for each POD file.
$| = 1;
my @pod = all_pod_files ();
my $count = scalar @pod;
print "1..$count\n";
my $n = 1;
for my $pod (@pod) {
    my $child = open (CHILD, '-|');
    if (not defined $child) {
        die "Cannot fork: $!\n";
    } elsif ($child == 0) {
        my $pid = open (SPELL, '|-', @spell) or die "Cannot run @spell: $!\n";
        open (POD, '<', $pod) or die "Cannot open $pod: $!\n";
        my $parser = Pod::Spell->new;
        $parser->parse_from_filehandle (\*POD, \*SPELL);
        close POD;
        close SPELL;
        exit ($? >> 8);
    } else {
        my @words = <CHILD>;
        close CHILD;
        if ($? != 0) {
            print "ok $n # skip - @spell failed\n";
        } elsif (@words) {
            for (@words) {
                s/^\s+//;
                s/\s+$//;
            }
            print "not ok $n\n";
            print " - Misspelled words found in $pod\n";
            print "   @words\n";
        } else {
            print "ok $n\n";
        }
        $n++;
    }
}
