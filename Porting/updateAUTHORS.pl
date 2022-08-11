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

sub main {
    local $Data::Dumper::Sortkeys= 1;
    my $authors_file= "AUTHORS";
    my $mailmap_file= ".mailmap";
    my $show_man= 0;
    my $show_help= 0;

    ## Parse options and print usage if there is a syntax error,
    ## or if usage was explicitly requested.
    GetOptions(
        'help|?'                      => \$show_help,
        'man'                         => \$show_man,
        'authors_file|authors-file=s' => \$authors_file,
        'mailmap_file|mailmap-file=s' => \$mailmap_file,
    ) or pod2usage(2);
    pod2usage(1)             if $show_help;
    pod2usage(-verbose => 2) if $show_man;

    my $self= Porting::updateAUTHORS->new(
        authors_file => $authors_file,
        mailmap_file => $mailmap_file,
    );

    $self->read_and_update($authors_file, $mailmap_file);
    return 0;    # 0 for no error - intended for exit();
}

exit(main()) unless caller;

1;
__END__

=head1 NAME

Porting/updateAUTHORS.pl - Automatically update AUTHORS and .mailmap
based on commit data.

=head1 SYNOPSIS

Porting/updateAUTHORS.pl

 Options:
   --help               brief help message
   --man                full documentation
   --authors-file=FILE  override default location of AUTHORS
   --mailmap-file=FILE  override default location of .mailmap

=head1 OPTIONS

=over 4

=item --help

Print a brief help message and exits.

=item --man

Prints the manual page and exits.

=item --authors-file=FILE

=item --authors_file=FILE

Override the default location of the authors file, which is "AUTHORS" in
the current directory.

=item --mailmap-file=FILE

=item --mailmap_file=FILE

Override the default location of the mailmap file, which is ".mailmap"
in the current directory.

=back

=head1 DESCRIPTION

This program will automatically manage updates to the AUTHORS file and
.mailmap file based on the data in our commits and the data in the files
themselves. It uses no other sources of data. Expects to be run from
the root a git repo of perl.

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
