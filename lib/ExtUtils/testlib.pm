package ExtUtils::testlib;
$VERSION = 1.12_01;

use lib qw(blib/arch blib/lib);
1;
__END__

=head1 NAME

ExtUtils::testlib - add blib/* directories to @INC

=head1 SYNOPSIS

  use ExtUtils::testlib;

=head1 DESCRIPTION

B<THIS MODULE IS OBSOLETE!>  Use blib instead.

After an extension has been built and before it is installed it may be
desirable to test it bypassing C<make test>. By adding

    use ExtUtils::testlib;

to a test program the intermediate directories used by C<make> are
added to @INC.

