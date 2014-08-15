package Test::Builder::Result::Finish;
use strict;
use warnings;

use base 'Test::Builder::Result';

use Test::Builder::Util qw/accessors/;
accessors qw/tests_run tests_failed/;

1;

__END__

=head1 NAME

Test::Builder::Result::Finish - The finish result type

=head1 DESCRIPTION

Sent after testing is finished.

=head1 METHODS

See L<Test::Builder::Result> which is the base class for this module.

=head2 CONSTRUCTORS

=over 4

=item $r = $class->new(...)

Create a new instance

=back

=head2 SIMPLE READ/WRITE ACCESSORS

=over 4

=item $r->tests_run

How many tests were run.

=item $r->tests_failed

How many tests failed.

=item $r->trace

Get the test trace info, including where to report errors.

=item $r->pid

PID in which the result was created.

=item $r->depth

Builder depth of the result (0 for normal, 1 for subtest, 2 for nested, etc).

=item $r->in_todo

True if the result was generated inside a todo.

=item $r->source

Builder that created the result, usually $0, but the name of a subtest when
inside a subtest.

=item $r->constructed

Package, File, and Line in which the result was built.

=back

=head2 INFORMATION

=over 4

=item $r->type

Type of result. Usually this is the lowercased name from the end of the
package. L<Test::Builder::Result::Ok> = 'ok'.

=item $r->indent

Returns the indentation that should be used to display the result ('    ' x
depth).

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 COPYRIGHT

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
