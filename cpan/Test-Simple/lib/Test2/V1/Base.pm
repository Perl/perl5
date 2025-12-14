package Test2::V1::Base;
use strict;
use warnings;

our $VERSION = '1.302219';

use Test2::API qw/intercept context/;

use Test2::Tools::Event qw/gen_event/;

use Test2::Tools::Defer qw/def do_def/;

use Test2::Tools::Basic qw{
    ok pass fail diag note todo skip
    plan skip_all done_testing bail_out
};

use Test2::Tools::Compare qw{
    is like isnt unlike
    match mismatch validator
    hash array bag object meta meta_check number float rounded within string subset bool check_isa
    number_lt number_le number_ge number_gt
    in_set not_in_set check_set
    item field call call_list call_hash prop check all_items all_keys all_vals all_values
    etc end filter_items
    T F D DF E DNE FDNE U L
    event fail_events
    exact_ref
};

use Test2::Tools::Warnings qw{
    warns warning warnings no_warnings
};

use Test2::Tools::ClassicCompare qw/cmp_ok/;

use Test2::Util::Importer 'Test2::Tools::Subtest' => (
    subtest_buffered => { -as => 'subtest' },
);

use Test2::Tools::Class     qw/can_ok isa_ok DOES_ok/;
use Test2::Tools::Encoding  qw/set_encoding/;
use Test2::Tools::Exports   qw/imported_ok not_imported_ok/;
use Test2::Tools::Ref       qw/ref_ok ref_is ref_is_not/;
use Test2::Tools::Mock      qw/mock mocked/;
use Test2::Tools::Exception qw/try_ok dies lives/;
use Test2::Tools::Refcount  qw/is_refcount is_oneref refcount/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::V1::Base - Base namespace used for L<Test2::Handle> objects created via
L<Test2::V1>.

=head1 DESCRIPTION

This is the default set of functions/methods available in L<Test2::V1>.

=head1 SYNOPSIS

See L<Test2::V1>. This module is not typically used directly.

=head1 INCLUDED FUNCTIONALITY

See L<Test2::V1/TOOLS> for documentation about the tools included here, and
when they were added.

Documentation is not duplicated here as that would mean maintaining 2
locations for every change.

=head1 SOURCE

The source code repository for Test2-Suite can be found at
F<https://github.com/Test-More/test-more/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
