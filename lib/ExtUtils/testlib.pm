package ExtUtils::testlib;
$VERSION = 1.12_01;

# So the tests can chdir around and not break @INC.
use File::Spec;
use lib map File::Spec->rel2abs($_), qw(blib/arch blib/lib);
1;
__END__

=head1 NAME

ExtUtils::testlib - add blib/* directories to @INC

=head1 SYNOPSIS

  use ExtUtils::testlib;

=head1 DESCRIPTION

After an extension has been built and before it is installed it may be
desirable to test it bypassing C<make test>. By adding

    use ExtUtils::testlib;

to a test program the intermediate directories used by C<make> are
added to @INC.

