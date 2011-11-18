#!/usr/bin/perl -w

use strict;

# make it clearer when we haven't run to completion, as we can be quite
# noisy when things are working ok

sub my_die {
    print STDERR "$0: ", @_;
    print STDERR "\n" unless $_[-1] =~ /\n\z/;
    print STDERR "ABORTED\n";
    exit 255;
}

sub open_or_die {
    my $filename = shift;
    open my $fh, '<', $filename or my_die "Can't open $filename: $!";
    return $fh;
}

sub slurp_or_die {
    my $filename = shift;
    my $fh = open_or_die($filename);
    binmode $fh;
    local $/;
    my $contents = <$fh>;
    die "Can't read $filename: $!" unless defined $contents and close $fh;
    return $contents;
}

sub write_or_die {
    my ($filename, $contents) = @_;
    open my $fh, '>', $filename or die "Can't open $filename for writing: $!";
    binmode $fh;
    print $fh $contents or die "Can't write to $filename: $!";
    close $fh or die "Can't close $filename: $!";
}

sub get_pod_metadata {
    # Do we expect to find generated pods on disk?
    my $permit_missing_generated = shift;
    my %BuildFiles;

    foreach my $path (@_) {
        $path =~ m!([^/]+)$!;
        ++$BuildFiles{$1};
    }

    my %state =
        (
         # Don't copy these top level READMEs
         ignore =>
         {
          micro => 1,
          # vms => 1,
         },
     );

    my $source = 'perldelta.pod';
    my $filename = "pod/$source";
    my $fh = open_or_die($filename);
    my $contents = do {local $/; <$fh>};
    my @want =
        $contents =~ /perldelta - what is new for perl v(5)\.(\d+)\.(\d+)\n/;
    die "Can't extract version from $filename" unless @want;
    $state{delta_target} = join '', 'perl', @want, 'delta.pod';
    $state{delta_version} = \@want;

    # This way round so that keys can act as a MANIFEST skip list
    # Targets will always be in the pod directory. Currently we can only cope
    # with sources being in the same directory.
    $state{copies}{$state{delta_target}} = $source;


    # process pod.lst
    my %Readmepods;
    my $master = open_or_die('pod.lst');

    foreach (<$master>) {
        next if /^\#/;

        # At least one upper case letter somewhere in the first group
        if (/^(\S+)\s(.*)/ && $1 =~ tr/h//) {
            # it's a heading
            my $flags = $1;
            $flags =~ tr/h//d;
            my %flags = (header => 1);
            $flags{toc_omit} = 1 if $flags =~ tr/o//d;
            $flags{aux} = 1 if $flags =~ tr/a//d;
            my_die "Unknown flag found in heading line: $_" if length $flags;

            push @{$state{master}}, [\%flags, $2];
        } elsif (/^(\S*)\s+(\S+)\s+(.*)/) {
            # it's a section
            my ($flags, $podname, $desc) = ($1, $2, $3);
            my $filename = "${podname}.pod";
            $filename = "pod/${filename}" if $filename !~ m{/};

            my %flags = (indent => 0);
            $flags{indent} = $1 if $flags =~ s/(\d+)//;
            $flags{toc_omit} = 1 if $flags =~ tr/o//d;
            $flags{aux} = 1 if $flags =~ tr/a//d;
            $flags{perlpod_omit} = "$podname.pod" eq $state{delta_target};

            $state{generated}{"$podname.pod"}++ if $flags =~ tr/g//d;

            if ($flags =~ tr/r//d) {
                my $readme = $podname;
                $readme =~ s/^perl//;
                $Readmepods{$podname} = $state{readmes}{$readme} = $desc;
                $flags{readme} = 1;
            } elsif ($flags{aux}) {
                $state{aux}{$podname} = $desc;
            } else {
                $state{pods}{$podname} = $desc;
            }
            my_die "Unknown flag found in section line: $_" if length $flags;
            my ($leafname) = $podname =~ m!([^/]+)$!;
            push @{$state{master}},
                [\%flags, $podname, $filename, $desc, $leafname];
        } elsif (/^$/) {
            push @{$state{master}}, undef;
        } else {
            my_die "Malformed line: $_" if $1 =~ tr/A-Z//;
        }
    }
    close $master or my_die "close pod.lst: $!";

    # Sanity cross check

    my (%disk_pods, %manipods, %manireadmes, %perlpods);
    my (%cpanpods, %cpanpods_leaf);
    my (%our_pods);

    # These are stub files for deleted documents. We don't want them to show up
    # in perl.pod, they just exist so that if someone types "perldoc perltoot"
    # they get some sort of pointer to the new docs.
    my %ignoredpods
        = map { ( "$_.pod" => 1 ) } qw( perlboot perlbot perltooc perltoot );

    # Convert these to a list of filenames.
    foreach (keys %{$state{pods}}, keys %Readmepods) {
        $our_pods{"$_.pod"}++;
    }

    opendir my $dh, 'pod';
    while (defined ($_ = readdir $dh)) {
        next unless /\.pod\z/;
        ++$disk_pods{$_};
    }

    # Things we copy from won't be in perl.pod
    # Things we copy to won't be in MANIFEST

    my $mani = open_or_die('MANIFEST');
    while (<$mani>) {
        chomp;
        s/\s+.*$//;
        if (m!^pod/([^.]+\.pod)!i) {
            ++$manipods{$1};
        } elsif (m!^README\.(\S+)!i) {
            next if $state{ignore}{$1};
            ++$manireadmes{"perl$1.pod"};
        } elsif (exists $our_pods{$_}) {
            ++$cpanpods{$_};
            m!([^/]+)$!;
            ++$cpanpods_leaf{$1};
            $disk_pods{$_}++
                if -e $_;
        }
    }
    close $mani or my_die "close MANIFEST: $!\n";

    my $perlpod = open_or_die('pod/perl.pod');
    while (<$perlpod>) {
        if (/^For ease of access, /../^\(If you're intending /) {
            if (/^\s+(perl\S*)\s+\w/) {
                ++$perlpods{"$1.pod"};
            }
        }
    }
    close $perlpod or my_die "close perlpod: $!\n";
    my_die "could not find the pod listing of perl.pod\n"
        unless %perlpods;

    # Are we running before known generated files have been generated?
    # (eg in a clean checkout)
    my %not_yet_there;
    if ($permit_missing_generated) {
        # If so, don't complain if these files aren't yet in place
        %not_yet_there = (%manireadmes, %{$state{generated}}, %{$state{copies}})
    }

    my @inconsistent;
    foreach my $i (sort keys %disk_pods) {
        push @inconsistent, "$0: $i exists but is unknown by buildtoc\n"
            unless $our_pods{$i};
        push @inconsistent, "$0: $i exists but is unknown by MANIFEST\n"
            if !$BuildFiles{'MANIFEST'} # Ignore if we're rebuilding MANIFEST
                && !$manipods{$i} && !$manireadmes{$i} && !$state{copies}{$i}
                    && !$state{generated}{$i} && !$cpanpods{$i};
        push @inconsistent, "$0: $i exists but is unknown by perl.pod\n"
            if !$BuildFiles{'perl.pod'} # Ignore if we're rebuilding perl.pod
                && !$perlpods{$i} && !exists $state{copies}{$i}
                    && !$cpanpods{$i} && !$ignoredpods{$i};
    }
    foreach my $i (sort keys %our_pods) {
        push @inconsistent, "$0: $i is known by buildtoc but does not exist\n"
            unless $disk_pods{$i} or $BuildFiles{$i} or $not_yet_there{$i};
    }
    unless ($BuildFiles{'MANIFEST'}) {
        # Again, ignore these if we're about to rebuild MANIFEST
        foreach my $i (sort keys %manipods) {
            push @inconsistent, "$0: $i is known by MANIFEST but does not exist\n"
                unless $disk_pods{$i};
            push @inconsistent, "$0: $i is known by MANIFEST but is marked as generated\n"
                if $state{generated}{$i};
        }
    }
    unless ($BuildFiles{'perl.pod'}) {
        # Again, ignore these if we're about to rebuild perl.pod
        foreach my $i (sort keys %perlpods) {
            push @inconsistent, "$0: $i is known by perl.pod but does not exist\n"
                unless $disk_pods{$i} or $BuildFiles{$i} or $cpanpods_leaf{$i}
                    or $not_yet_there{$i};
        }
    }
    $state{inconsistent} = \@inconsistent;
    return \%state;
}

1;

# Local variables:
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# ex: set ts=8 sts=4 sw=4 et:
