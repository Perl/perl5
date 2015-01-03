package Test::CanThread;
use strict;
use warnings;

use Config;

my $works = 1;
$works &&= $] >= 5.008001;
$works &&= $Config{'useithreads'};
$works &&= eval { require threads; 'threads'->import; 1 };

sub import {
    my $class = shift;

    unless ($works) {
        require Test::More;
        Test::More::plan(skip_all => "Skip no working threads");
    }

    if ($INC{'Devel/Cover.pm'}) {
        require Test::More;
        Test::More::plan(skip_all => "Devel::Cover does not work with threads yet");
    }

    while(my $var = shift(@_)) {
        next if $ENV{$var};

        require Test::More;
        Test::More::plan(skip_all => "This threaded test will only run when the '$var' environment variable is set.");
    }

    if ($] == 5.010000) {
        require File::Temp;
        require File::Spec;

        my $perl = File::Spec->rel2abs($^X);
        my ($fh, $fn) = File::Temp::tempfile();
        print $fh <<'        EOT';
            BEGIN { print STDERR "# Checking for thread segfaults\n# " }
            use threads;
            my $t = threads->create(sub { 1 });
            $t->join;
            print STDERR "Threads appear to work\n";
            exit 0;
        EOT
        close($fh);

        my $exit = system(qq{"$perl" "$fn"});

        if ($exit) {
            require Test::More;
            Test::More::plan(skip_all => "Threads segfault on this perl");
        }
    }

    my $caller = caller;
    eval "package $caller; use threads; 1" || die $@;
}

1;

__END__

=head1 NAME

Test::CanThread - Only run tests when threading is supported, optionally conditioned on ENV vars.

=head1 DESCRIPTION

Use this first thing in a test that should be skipped when threading is not
supported. You can also specify that the test should be skipped when specific
environment variables are not set.

=head1 SYNOPSYS

Skip the test if threading is unsupported:

    use Test::CanThread;
    use Test::More;
    ...

Skip the test if threading is unsupported, or any of the specified env vars are
not set:

    use Test::CanThread qw/AUTHOR_TESTING RUN_PROBLEMATIC_TESTS .../;
    use Test::More;
    ...

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
