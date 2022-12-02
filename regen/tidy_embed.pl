use lib "regen";
use HeaderParser;
use strict;
use warnings;

my $parser= HeaderParser->new(
        pre_process_content => sub {
            my ($self,$line_data)= @_;
            $self->tidy_embed_fnc_entry($line_data);
            my $embed= $line_data->{embed}
                or return;
        },
        _post_process_grouped_content => sub {
            my ($self,$group_ary)= @_;
            @{$group_ary}=
                sort {
                    $a->{embed}{name} cmp $b->{embed}{name}
                } @{$group_ary};
        },
    );
my $tap;
if (@ARGV and $ARGV[0] eq "--tap") {
    $tap = shift @ARGV;
}
my $file= "embed.fnc";
if (@ARGV) {
    $file= shift @ARGV;
}
my $new= "$file.new";
my $bak= "$file.bak";
$parser->read_file($file);
my $lines= $parser->lines;
my @tail;
while ($lines->[-1]{type} eq "content" and
    ($lines->[-1]{line} eq "\n" or $lines->[-1]{line}=~/^\s*:/)
) {
    unshift @tail, pop @$lines;
}

my $grouped_content_ary= $parser->group_content();
push @$grouped_content_ary, @tail;
my $grouped_content_txt= $parser->normalized_content($grouped_content_ary);
if ($grouped_content_txt ne $parser->{orig_content}) {
    if ($tap) {
        print "not ok - $0 $file\n";
    } elsif (-t) {
        print "Updating $file\n";
    }
    open my $fh,">",$new
        or die "Failed to open '$new' for write: $!";
    print $fh $grouped_content_txt
        or die "Failed to print to '$new': $!";
    close $fh
        or die "Failed to close '$new': $!";
    rename $file, $bak
        or die "Couldn't move '$file' to '$bak': $!";
    rename $new, $file
        or die "Couldn't move embed.fnc.new to embed.fnc: $!";
} elsif ($tap) {
    print "ok - $0 $file\n";
}
