#!/usr/bin/perl
use strict;
use warnings;
use File::Find qw(find);
use File::Spec;

my $root = '.agents/skills';
my $skills_pod = 'pod/perlagentskills.pod';
my $ok = 1;
my $file_index = 0;

for my $arg (@ARGV) {
    if ($arg eq '--file-index') {
        $file_index = 1;
    }
    elsif ($arg eq '--help') {
        print <<"EOF";
Usage: $0 [--file-index]

  --file-index   Print a Markdown index of repo files mentioned by skills.
EOF
        exit 0;
    }
    else {
        die "Unknown option: $arg\n";
    }
}

sub fail {
    my ($msg) = @_;
    print STDERR "$msg\n";
    $ok = 0;
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open $file: $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    return $text;
}

sub mention_candidates {
    my ($text) = @_;
    my %seen;

    while ($text =~ /\]\(([^)]+)\)/g) {
        my $link = $1;
        $link =~ s/#.*\z//;
        $seen{$link}++ if length $link;
    }

    while ($text =~ /`([^`\n]+)`/g) {
        my $span = $1;
        next if $span =~ m{://};
        while ($span =~ m{([.]?/?[A-Za-z0-9][A-Za-z0-9_.+*/?@-]*(?:/[A-Za-z0-9][A-Za-z0-9_.+*/?@-]*)+)}g) {
            $seen{$1}++;
        }
        while ($span =~ m{\b([A-Za-z0-9][A-Za-z0-9_.+-]*[.](?:c|h|pm|pl|pod|t|xs|y|SH|PL|md|inc|sym|fnc|com|txt|dat|json|yml))\b}g) {
            $seen{$1}++;
        }
        while ($span =~ m{\b([A-Z][A-Z0-9_]*(?:\.[A-Z0-9_]+)*)\b}g) {
            $seen{$1}++ if -e $1;
        }
    }

    return sort keys %seen;
}

sub normalize_mention {
    my ($source, $candidate) = @_;
    return if $candidate =~ /\A(?:https?:|mailto:|#)\b/;
    return if $candidate =~ /\A(?:\.\.|~)\b/;
    return if $candidate =~ /\A-[A-Za-z]/;

    $candidate =~ s{\A[.]/}{};

    if ($candidate =~ m{[*?\[]}) {
        return ($candidate, 'pattern') if $candidate =~ m{/};
        return;
    }

    return ($candidate, 'file') if -e $candidate;

    my (undef, $dir) = File::Spec->splitpath($source);
    my $relative = File::Spec->catfile($dir, $candidate);
    return ($relative, 'file') if -e $relative;

    return;
}

sub print_file_index {
    my (%index);

    find(
        {
            no_chdir => 1,
            wanted => sub {
                my $path = $File::Find::name;
                return unless -f $path;
                return unless $path =~ /\.(?:md|markdown)\z/ || $path =~ /\/SKILL\.md\z/;

                my $text = slurp($path);
                for my $candidate (mention_candidates($text)) {
                    my ($mention, $kind) = normalize_mention($path, $candidate);
                    next unless defined $mention;
                    $index{$mention}{$kind}{$path} = 1;
                }
            },
        },
        $root
    );

    print "# Skill Mentioned File Index\n\n";
    print "Generated from `$root`.\n\n";
    for my $mention (sort keys %index) {
        my @kinds = sort keys %{ $index{$mention} };
        my $label = join ', ', @kinds;
        print "## `$mention` ($label)\n\n";
        my %sources;
        for my $kind (@kinds) {
            $sources{$_} = 1 for keys %{ $index{$mention}{$kind} };
        }
        for my $source (sort keys %sources) {
            print "- `$source`\n";
        }
        print "\n";
    }
}

sub documented_skills {
    my ($file) = @_;
    my $text = slurp($file);
    my %documented;

    while ($text =~ /F<([a-z0-9]+(?:-[a-z0-9]+)+)>/g) {
        $documented{$1} = 1;
    }

    return %documented;
}

opendir my $dh, $root or die "Cannot open $root: $!";
my @skills = sort grep { !/^\./ && -d "$root/$_" } readdir $dh;
closedir $dh;

if (-f $skills_pod) {
    my %actual = map { $_ => 1 } @skills;
    my %documented = documented_skills($skills_pod);

    for my $skill (@skills) {
        fail("$skills_pod: missing documentation for skill $skill")
            unless $documented{$skill};
    }

    for my $skill (sort keys %documented) {
        fail("$skills_pod: documents missing skill directory $skill")
            unless $actual{$skill};
    }
}
else {
    fail("$skills_pod: missing agent skills documentation");
}

my %seen;
for my $skill (@skills) {
    my $dir = "$root/$skill";
    my $file = "$dir/SKILL.md";
    fail("$skill: missing SKILL.md") unless -f $file;
    fail("$skill: directory name is not kebab-case") unless $skill =~ /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/;

    my $text = eval { slurp($file) };
    do { fail("$file: $@"); next } if $@;

    fail("$file: too long for a top-level skill") if (() = $text =~ /\n/g) > 500;
    unless ($text =~ /\A---\n(.*?)\n---\n/s) {
        fail("$file: missing YAML frontmatter");
        next;
    }

    my $fm = $1;
    my ($name) = $fm =~ /^name:\s*([a-z0-9-]+)\s*$/m;
    my ($desc_double, $desc_single, $desc_plain) =
        $fm =~ /^description:\s*(?:"([^"]*)"|'([^']*)'|(.+?))\s*$/m;
    my $desc = defined $desc_double ? $desc_double
             : defined $desc_single ? $desc_single
             : $desc_plain;
    fail("$file: missing name") unless defined $name;
    fail("$file: name does not match directory") if defined $name && $name ne $skill;
    fail("$file: duplicate name $name") if defined $name && $seen{$name}++;
    fail("$file: missing description") unless defined $desc && length $desc;
    fail("$file: description is too long") if defined $desc && length($desc) > 280;

    while ($text =~ /\]\(([^)]+)\)/g) {
        my $link = $1;
        next if $link =~ /\A(?:https?:|mailto:|#)/;
        my $target = File::Spec->catfile($dir, $link);
        $target =~ s/#.*\z//;
        fail("$file: missing relative link $link") unless -e $target;
    }

    my $refdir = "$dir/references";
    if (-d $refdir) {
        opendir my $rdh, $refdir or do { fail("$refdir: $!"); next };
        for my $ref (grep { !/^\./ && -f "$refdir/$_" } readdir $rdh) {
            fail("$refdir/$ref: reference file must be Markdown")
                unless $ref =~ /[.]md\z/;
        }
        closedir $rdh;
    }
}

find(
    sub {
        return unless -f $_;
        return if $File::Find::name =~ m{/\.(?:git|svn)/};
        open my $fh, '<', $_ or return;
        my $sample = do { local $/; <$fh> };
        close $fh;
        fail("$File::Find::name: possible secret marker") if $sample =~ /(?:password|api[_-]?key|secret)\s*[:=]\s*\S/i;
    },
    '.agents/skills'
);

print_file_index() if $file_index;

exit($ok ? 0 : 1);
