package ExtUtils::testlib;
$VERSION = 1.13_01;

use Cwd;
use File::Spec;

# So the tests can chdir around and not break @INC.
# We use getcwd() because otherwise rel2abs will blow up under taint
# mode pre-5.8
use lib map File::Spec->rel2abs($_, getcwd()), qw(blib/arch blib/lib);
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

