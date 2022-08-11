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
);

sub main {
    local $Data::Dumper::Sortkeys= 1;
    my %opts= (
        authors_file => "AUTHORS",
        mailmap_file => ".mailmap",
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
    pod2usage(1)             if $opts{help};
    pod2usage(-verbose => 2) if $opts{man};

    my $self= Porting::updateAUTHORS->new(%opts);

    my $changed= $self->read_and_update();

    return $changed;    # 0 means nothing changed
}

exit(main()) unless caller;

1;
__END__

=head1 NAME

F<Porting/updateAUTHORS.pl> - Automatically update F<AUTHORS> and F<.mailmap>
based on commit data.

=head1 SYNOPSIS

Porting/updateAUTHORS.pl

 Options:
   --help               brief help message
   --man                full documentation
   --verbose            be verbose

 File Locations:
   --authors-file=FILE  override default of 'AUTHORS'
   --mailmap-file=FILE  override default of '.mailmap'

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
