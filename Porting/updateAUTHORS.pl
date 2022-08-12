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

    from_commit|from=s
    to_commit|to=s
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
   --exclude-missing    Add new names to the exclude file so they never
                        appear in AUTHORS or .mailmap.

 Details Changes
    Update canonical name or email in AUTHORS and .mailmap properly.
    --exclude-contrib       NAME_AND_EMAIL
    --exclude-me

=head1 OPTIONS

=over 4

=item C<--help>

Print a brief help message and exits.

=item C<--man>

Prints the manual page and exits.

=item C<--verbose>

Be verbose about what is happening. Can be repeated more than once.

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
