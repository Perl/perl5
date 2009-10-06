#!/usr/bin/perl -w
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

# Somewhere we chdir and can't load any more modules...
BEGIN {
    if ($^O eq 'MSWin32') {
        require Win32;
    };
    require overload;
};

use Test::More;
use File::Find ();

{
    package My::Pod::Checker;
    use strict;
    use parent 'Pod::Checker';

    use vars '@errors'; # a bad, bad hack!

    sub poderror {
        my $self = shift;
        my $opts;
        if (ref $_[0]) {
            $opts = shift;
        };
        ++($self->{_NUM_ERRORS})
            if(!$opts || ($opts->{-severity} && $opts->{-severity} eq 'ERROR'));
        ++($self->{_NUM_WARNINGS})
            if(!$opts || ($opts->{-severity} && $opts->{-severity} eq 'WARNING'));
        push @errors, $opts;
    };
}

my @files = @ARGV;
if (! @files) {
    chdir '..'
        or die "Couldn't chdir to ..: $!";
    chomp( my @d = <DATA> );
    File::Find::find({
        no_chdir => 1,
        wanted   => sub {
                return unless $File::Find::name =~ /(\.(pod|pm|pl))$/;
                push @files, $File::Find::name;
            },
        }, grep { m!/$! } @d );
    push @files, map { chomp; glob($_) } grep { ! m!/$! } @d;
    @files = sort @files; # so we get consistent results
};

sub pod_ok {
    my ($filename) = @_;
    local @My::Pod::Checker::errors;
    my $checker = My::Pod::Checker->new(-quiet => 1);
    $checker->parse_from_file($filename, undef);
    my $error_count = $checker->num_errors();

    if(! ok $error_count <= 0, "POD of $filename") {
        diag( "'$filename' contains POD errors" );
        diag sprintf "%s %s: %s at line %s",
             $_->{-severity}, $_->{-file}, $_->{-msg}, $_->{-line}
            for @My::Pod::Checker::errors;
    };
};

plan tests => scalar @files;

pod_ok $_
    for @files;

__DATA__
lib/
ext/
pod/
AUTHORS
Changes
INSTALL
README*
*.pod
