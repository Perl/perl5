#!/usr/bin/env perl
package App::Porting::updateAUTHORS;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Data::Dumper;
use Encode qw(encode_utf8 decode_utf8 decode);
use lib "./";
use Porting::updateAUTHORS;

# The style of this file is determined by:
#
# perltidy -w -ple -bbb -bbc -bbs -nolq -l=80 -noll -nola -nwls='=' \
#   -isbc -nolc -otr -kis -ci=4 -se -sot -sct -nsbl -pt=2 -fs  \
#   -fsb='#start-no-tidy' -fse='#end-no-tidy'

my @OPTSPEC= qw(
    help|?
    man
    authors_file=s
    mailmap_file=s

    verbose+
    exclude_missing|exclude
    exclude_contrib=s@
    exclude_me

    show_rank|rank
    show_applied|thanks_applied|applied
    show_stats|stats
    show_who|who
    show_files|files
    show_file_changes|activity
    show_file_chainsaw|chainsaw

    as_percentage|percentage
    as_cumulative|cumulative
    as_list|old_style

    in_reverse|reverse
    with_rank_numbers|numbered|num

    from_commit|from=s
    to_commit|to=s

    numstat
    no_update
);

my %implies_numstat= (
    show_files         => 1,
    show_file_changes  => 1,
    show_file_chainsaw => 1,
);

sub main {
    local $Data::Dumper::Sortkeys= 1;
    my %opts= (
        authors_file    => "AUTHORS",
        mailmap_file    => ".mailmap",
        exclude_file    => "Porting/exclude_contrib.txt",
        from            => "",
        to              => "",
        exclude_contrib => [],
    );

    ## Parse options and print usage if there is a syntax error,
    ## or if usage was explicitly requested.
    GetOptions(
        \%opts,
        map {
            # support hyphens as well as underbars,
            # underbars must be first. Only handles two
            # part words right now.
            s/\b([a-z]+)_([a-z]+)\b/${1}_${2}|${1}-${2}/gr
        } @OPTSPEC
    ) or pod2usage(2);
    $opts{commit_range}= join " ", @ARGV;
    if (!$opts{commit_range}) {
        if ($opts{from_commit}) {
            $opts{to_commit} ||= "HEAD";
            $opts{$_} =~ s/\.+\z// for qw(from_commit to_commit);
            $opts{commit_range}= "$opts{from_commit}..$opts{to_commit}";
        }
    }
    pod2usage(1)             if $opts{help};
    pod2usage(-verbose => 2) if $opts{man};

    foreach my $opt (keys %opts) {
        $opts{numstat}++   if $implies_numstat{$opt};
        $opts{no_update}++ if $opt =~ /^show_/;
    }

    if (delete $opts{exclude_me}) {
        my ($author_full)=
            Porting::updateAUTHORS->current_author_name_email("full");
        my ($committer_full)=
            Porting::updateAUTHORS->current_committer_name_email("full");

        push @{ $opts{exclude_contrib} }, $author_full
            if $author_full;
        push @{ $opts{exclude_contrib} }, $committer_full
            if $committer_full
            and (!$author_full
            or $committer_full ne $author_full);
    }

    my $self= Porting::updateAUTHORS->new(%opts);

    my $changed= $self->read_and_update();

    if ($self->{show_rank}) {
        $self->report_stats("who_stats", "author");
        return 0;
    }
    elsif ($self->{show_applied}) {
        $self->report_stats("who_stats", "applied");
        return 0;
    }
    elsif ($self->{show_stats}) {
        my @fields= ("author", "applied", "committer");
        push @fields,
            ("num_files", "lines_added", "lines_removed", "lines_delta")
            if $self->{numstat};
        $self->report_stats("who_stats", @fields);
        return 0;
    }
    elsif ($self->{show_files}) {
        $self->report_stats(
            "file_stats",  "commits", "lines_added", "lines_removed",
            "lines_delta", "binary_change"
        );
        return 0;
    }
    elsif ($self->{show_file_changes}) {
        $self->report_stats(
            "file_stats", "lines_delta", "lines_added", "lines_removed",
            "commits"
        );
        return 0;
    }
    elsif ($self->{show_file_chainsaw}) {
        $self->{in_reverse}= !$self->{in_reverse};
        $self->report_stats(
            "file_stats", "lines_delta", "lines_added", "lines_removed",
            "commits"
        );
        return 0;
    }
    elsif ($self->{show_who}) {
        $self->print_who();
        return 0;
    }
    return $changed;    # 0 means nothing changed
}

exit(main()) unless caller;

1;
__END__

=head1 NAME

F<Porting/updateAUTHORS.pl> - Automatically update F<AUTHORS> and F<.mailmap>
and F<Porting/exclude_contrib.txt> based on commit data.

=head1 SYNOPSIS

Porting/updateAUTHORS.pl [OPTIONS] [GIT_REF_RANGE]

By default scans the commit history specified (or the entire history from the
current commit) and then updates F<AUTHORS> and F<.mailmap> so all contributors
are properly listed.

 Options:
   --help               brief help message
   --man                full documentation
   --verbose            be verbose

 Commit Range:
   --from=GIT_REF       Select commits to use
   --to=GIT_REF         Select commits to use, defaults to HEAD

 File Locations:
   --authors-file=FILE  override default of 'AUTHORS'
   --mailmap-file=FILE  override default of '.mailmap'

 Action Modifiers
   --no-update          Do not update.
   --exclude-missing    Add new names to the exclude file so they never
                        appear in AUTHORS or .mailmap.

 Details Changes
    Update canonical name or email in AUTHORS and .mailmap properly.
    --exclude-contrib       NAME_AND_EMAIL
    --exclude-me

 Reports About People
    --stats             detailed report of authors and what they did
    --who               Sorted, wrapped list of who did what
    --thanks-applied    report who applied stuff for others
    --rank              report authors by number of commits created

 Reports About Files
    --files             detailed report files that were modified
    --activity          simple report of files that grew the most
    --chainsaw          simple report of files that shrank the most

 Report Modifiers
    --percentage        show percentages not counts
    --cumulative        show cumulative numbers not individual
    --reverse           show reports in reverse order
    --numstat           show additional file based data in some reports
                        (not needed for most reports)
    --as-list           show reports with names with common values
                        folded into a list like checkAUTHORS.pl used to
    --numbered          add rank numbers to reports where they are missing

=head1 OPTIONS

=over 4

=item C<--help>

Print a brief help message and exits.

=item C<--man>

Prints the manual page and exits.

=item C<--verbose>

Be verbose about what is happening. Can be repeated more than once.

=item C<--no-update>

Do not update files on disk even if they need to be changed.

=item C<--authors-file=FILE>

=item C<--authors_file=FILE>

Override the default location of the authors file, which is by default
the F<AUTHORS> file in the current directory.

=item C<--mailmap-file=FILE>

=item C<--mailmap_file=FILE>

Override the default location of the mailmap file, which is by default
the F<.mailmap> file in the current directory.

=item C<--exclude-file=FILE>

=item C<--exclude_file=FILE>

Override the default location of the exclude file, which is by default
the F<Porting/exclude_contrib.txt> file reachable from the current
directory.

=item C<--exclude-contrib=NAME_AND_EMAIL>

=item C<--exclude_contrib=NAME_AND_EMAIL>

Exclude a specific name/email combination from our contributor datasets.
Can be repeated multiple times on the command line to remove multiple
items at once. If the contributor details correspond to a canonical
identity of a contributor (one that is in the AUTHORS file or on the
left in the .mailmap file) then ALL records, including those linked to
that identity in .mailmap will be marked for exclusion. This is similar
to C<--exclude-missing> but it only affects the specifically named
users. Note that the format for NAME_AND_EMAIL is similar to that of the
.mailmap file, email addresses and C< @github > style identifiers should
be wrapped in angle brackets like this: C<< <@github> >>, users with no
email in the AUTHORS file should use C<< <unknown> >>.

For example:

  Porting/updateAUTHORS.pl --exclude-contrib="Joe B <b@joe.com>"

Would remove all references to "Joe B" from F<AUTHORS> and F<.mailmap>
and add the required entires to F<Porting/exclude_contrib.txt> such that
the contributor would never be automatically added back, and would be
automatically removed should someone read them manually.

=item C<--exclude-missing>

=item C<--exclude_missing>

=item C<--exclude>

Normally when the tool is run it *adds* missing data only. If this
option is set then the reverse will happen, any author data missing will
be marked as intentionally missing in such a way that future "normal"
runs of the script ignore the author(s) that were excluded.

The exclude data is stored in F<Porting/exclude_contrib.txt> as a SHA256
digest (in base 64) of the user name and email being excluded so that
the list itself doesnt contain the contributor details in plain text.

The general idea is that if you want to remove someone from F<AUTHORS>
and F<.mailmap> you delete their details manually, and then run this
tool with the C<--exclude> option. It is probably a good idea to run it
first without any arguments to make sure you dont exclude something or
someone you did not intend to.

=item C<--stats>

Show detailed stats about committers and the work they did in a tabular
form. If the C<--numstat> option is provided this report will provide
additional data about the files a developer worked on. May be slow the
first time it is used as git unpacks the relevant data.

=item C<--who>

Show a list of which committers and authors contributed to the project
in the selected range of commits. The list will contain the name only,
and will sorted according to unicode collation rules. This list is
suitable in release notes and similar contexts.

=item C<--thanks-applied>

Show a report of which committers applied work on behalf of
someone else, including counts. Modified by the C<--as-list> and
C<--display-rank>.

=item C<--rank>

Shows a report of which commits did the most work. Modified by the
C<--as-list> and C<--display-rank> options.

=item C<--files>

Show detailed stats about the files that have been modified in the
selected range of commits. Implies C<--numstat>. May be slow the first
time it is used as git unpacks the relevant data.

=item C<--activity>

Show simple stats about which files had the most additions. Implies
C<--numstat>. May be slow the first time it is used as git unpacks the
relevant data.


=item C<--chainsaw>

Show simple stats about whcih files had the most removals. Implies
C<--numstat>. May be slow the first time it is used as git unpacks the
relevant data.

=item C<--percentage>

Show numeric data as percentages of the total, not counts.

=item C<--cumulative>

Show numeric data as cumulative counts in the reports.

=item C<--reverse>

Show the reports in reverse order to normal.

=item C<--numstat>

Gather additional data about the files that were changed, not just the
authors who did the changes. This option currently is only necessary for
the C<--stats> option, which will display additional data when this
option is also provided.

=item C<--as-list>

Show the reports with name data rolled up together into a list like the
older checkAUTHORS.pl script would have.

=item C<--numbered>

Show an additional column with the rank number of a row in the report in
reports that do not normally show the rank number.

=back

=head1 DESCRIPTION

This program will automatically manage updates to the F<AUTHORS> file
and F<.mailmap> file based on the data in our commits and the data in
the files themselves. It uses no other sources of data. Expects to be
run from the root directory of a git repo of perl.

In simple, execute the script and it will either die with a helpful
message or it will update the files as necessary, possibly not at all if
there is no need to do so. Note it will actually rewrite the files at
least once, but it may not actually make any changes to their content.
Thus to use the script is currently required that the files are
modifiable.

Review the changes it makes to make sure they are sane. If they are
commit. If they are not then update the AUTHORS or .mailmap files as is
appropriate and run the tool again. Typically you shouldn't need to do
either unless you are changing the default name or email for a user. For
instance if a person currently listed in the AUTHORS file whishes to
change their preferred name or email then change it in the AUTHORS file
and run the script again. I am not sure when you might need to directly
modify .mailmap, usually modifying the AUTHORS file should suffice.

=head1 TODO

More documentation and testing.

=head1 SEE ALSO

F<Porting/checkAUTHORS.pl>

=head1 AUTHOR

Yves Orton <demerphq@gmail.com>

=cut
