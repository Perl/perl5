package Test2::V1;
use strict;
use warnings;

our $VERSION = '1.302219';

use Carp qw/croak/;

use Test2::V1::Base();
use Test2::V1::Handle();

use Test2::Plugin::ExitSummary();
use Test2::Plugin::SRand();
use Test2::Plugin::UTF8();
use Test2::Tools::Target();

# Magic reference to check against later
my $SET = \'set';

# Lists of pragmas and plugins
my @PRAGMAS = qw/strict warnings/;
my @PLUGINS = qw/utf8 srand summary target/;

sub import {
    my $class = shift;

    my $caller = caller;

    croak "Got One or more undefined arguments, this usually means you passed in a single-character flag like '-p' without quoting it, which conflicts with the -p builtin"
        if grep { !defined($_) } @_;

    my ($requested_exports, $options) = $class->_parse_args(\@_);

    my $pragmas = $class->_compute_pragmas($options);
    my $plugins = $class->_compute_plugins($options);

    my ($handle_name, $handle) = $class->_build_handle($options);
    my $ns = $handle->HANDLE_NAMESPACE;

    unshift @$requested_exports => $handle->HANDLE_SUBS() if delete $options->{'-import'};

    unshift @$requested_exports => grep { my $p = prototype($ns->can($_)); $p && $p =~ '&' } $handle->HANDLE_SUBS() if delete $options->{'-x'};

    my $exports = $class->_build_exports($handle, $requested_exports);
    unless (delete $options->{'-no-T2'}) {
        my $h = $handle;
        $exports->{$handle_name} = sub() { $h };
    }

    croak "Unknown option(s): " . join(', ', sort keys %$options) if keys %$options;

    strict->import()                     if $pragmas->{strict};
    'warnings'->import()                 if $pragmas->{warnings};
    Test2::Plugin::UTF8->import()        if $plugins->{utf8};
    Test2::Plugin::ExitSummary->import() if $plugins->{summary};

    if (my $set = $plugins->{srand}) {
        Test2::Plugin::SRand->import((ref($set) && "$set" ne "$SET") ? $set->{seed} : ());
    }

    if (my $target = $plugins->{target}) {
        Test2::Tools::Target->import_into($caller, $plugins->{target}) unless "$target" eq "$SET";
    }

    for my $exp (keys %$exports) {
        no strict 'refs';
        *{"$caller\::$exp"} = $exports->{$exp};
    }
}

sub _build_exports {
    my $class = shift;
    my ($handle, $requested) = @_;

    my %exports;

    while (my $exp = shift @$requested) {
        if ($exp =~ m/^!(.+)$/) {
            delete $exports{$1};
            next;
        }

        my $code = $handle->HANDLE_NAMESPACE->can($exp) or croak "requested export '$exp' is not available";

        my $args = shift @$requested if @$requested && ref($requested->[0]) eq 'HASH';

        my $name = $exp;
        if ($args) {
            $name = delete $args->{-as}               if $args->{-as};
            $name = delete($args->{-prefix}) . $name  if $args->{-prefix};
            $name = $name . delete($args->{-postfix}) if $args->{-postfix};
        }

        $exports{$name} = $code;
    }

    return \%exports;
}

sub _build_handle {
    my $class = shift;
    my ($options) = @_;

    my $handle_opts = delete $options->{'-T2'} || {};
    my $handle_name = delete $handle_opts->{'-as'} || delete $handle_opts->{'as'} || 'T2';
    my $handle      = Test2::V1::Handle->new(%$handle_opts);

    return ($handle_name, $handle);
}

sub _compute_plugins {
    my $class = shift;
    my ($options) = @_;

    my $plugins = { summary => $SET };

    if (my $plug = delete $options->{'-plugins'}) {
        if (ref($plug)) {
            $plugins = $plug;
        }
        else {
            $plugins = { map { $_ => $SET } @PLUGINS };
        }
    }

    for my $plug (@PLUGINS) {
        my $set = delete $options->{"-$plug"};
        $plugins->{$plug} = $set if $set && "$set" ne "$SET";
        $plugins->{$plug} = $set unless defined $plugins->{$plug};
    }

    return $plugins;
}

sub _compute_pragmas {
    my $class = shift;
    my ($options) = @_;

    my $pragmas = {};
    if (my $prag = delete $options->{'-pragmas'}) {
        if (ref($prag) && "$prag" ne "$SET") {
            $pragmas = $prag;
        }
        else {
            $pragmas = { map { $_ => $SET } @PRAGMAS };
        }
    }

    for my $prag (@PRAGMAS) {
        my $set = delete $options->{"-$prag"};
        $pragmas->{$prag} = $set if $set && "$set" ne "$SET";
        $pragmas->{$prag} = $set unless defined $pragmas->{$prag};
    }

    return $pragmas
}

sub _parse_args {
    my $class = shift;
    my ($args) = @_;

    my (@exports, %options);

    while (my $arg = shift @$args) {
        $arg = '-T2' if $arg eq 'T2';
        push @exports => $arg and next unless substr($arg, 0, 1) eq '-';
        $options{$arg} = shift @$args and next if $arg eq '-target';
        $options{$arg} = (@$args && (ref($args->[0]) || "$args->[0]" eq "1" || "$args->[0]" eq "0")) ? shift @$args : $SET;
    }

    if (my $inc = delete $options{'-include'}) {
        $options{'-T2'}->{include} = $inc;
    }

    for my $key (keys %options) {
        next unless $key =~ m/^-([ipP]{1,3})$/;
        delete $options{$key};
        for my $flag (split //, $1) {
            $options{"-$flag"} = 1;
        }
    }

    $options{'-import'}  ||= 1 if delete $options{'-i'};
    $options{'-pragmas'} ||= 1 if delete $options{'-p'};
    $options{'-plugins'} ||= 1 if delete $options{'-P'};

    return (\@exports, \%options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::V1 - V1 edition of the Test2 recommended bundle.

=head1 DESCRIPTION

This is the first sequel to L<Test2::V0>. This module is recommended over
L<Test2::V0> for new tests.

=head2 Key differences from L<Test2::V0>

=over 4

=item Only 1 export by default: T2()

=item No pragmas by default

=item srand and utf8 are not enabled by default

=item Easy to still import everything

=item East to still enable pragmas

=back

=head1 NAMING, USING, DEPENDING

This bundle should not change in a I<severely> incompatible way. Some minor
breaking changes, specially bugfixes, may be allowed. If breaking changes are
needed then a new C<Test2::V#> module should be released instead.

Adding new optional exports, and new methods on the T2() handle are not
considered breaking changes, and are allowed without bumping the V# number.
Adding new plugin shortcuts is also allowed, but they cannot be added to the
C<-P> or C<-plugins> shortcuts without a bump in V# number.

As new C<V#> modules are released old ones I<may> be moved to different cpan
distributions. You should always use a specific bundle version and list that
version in your distributions testing requirements. You should never simply
list L<Test2::Suite> as your modules dep, instead list the specific bundle, or
tools and plugins you use directly in your metadata.

See the L</JUSTIFICATION> section for an explanation of why L<Test2::V1> was
created.

=head1 SYNOPSIS

=head2 RECOMMENDED

    use Test2::V1 -utf8;

    T2->ok(1, "pass");

    T2->is({1 => 1}, {1 => 1}, "Structures Match");

    # Note that prototypes do not work in method form:
    my @foo = (1, 2, 3);
    T2->is(scalar(@foo), 3, "Needed to force scalar context");

    T2->done_testing;

=head2 WORK LIKE V0 DID

    use Test2::V1 -ipP;

    ok(1, "pass");

    is({1 => 1}, {1 => 1}, "Structures Match");

    my @foo = (1, 2, 3);
    is(@foo, 3, "Prototype forces @foo into scalar context");

    # You still have access to T2
    T2->ok(1, "Another Pass");

    done_testing;

The C<-ipP> argument is short for C<-include, -pragmas, -plugins> which together enable all
pragmas, plugins, and import all symbols.

B<Note:> The order in which C<i>, C<p>, and C<P> appear is not important;
C<-Ppi> and C<-piP> and any other order are all perfectly valid.

=head2 IMPORT ARGUMENT GUIDE

=over 4

=item C<-P> or C<-plugins>

Shortcut to include the following plugins: L<Test2::Plugin::UTF8>,
L<Test2::Plugin::SRand>, L<Test2::Plugin::ExitSummary>.

=item C<-p> or C<-pragmas>

Shortcut to enable the following pragmas: C<strict>, C<warnings>.

=item C<-i> or C<-import>

Shortcut to import all possible exports.

=item C<-x>

Shortcut to import any sub that has '&' in its prototype, things like
C<< dies { ... } >>, C<< warns { ... } >>, etc.

While these can be used in method form: C<< T2->dies(sub { ... }) >> it is a
little less convenient than having them imported. '-x' will import all of
these, and any added in the future or included via an C<< -include => ... >>
import argument.

=item C<-ipP>, C<-pPi>, C<-pP>, C<-Pix>, etc..

The C<i>, C<p>, C<P>, and C<x> short options may all be grouped in any order
following a single dash.

=item C<@EXPORT_LIST>

Any arguments provided that are not prefixed with a C<-> will be assumed to be
export requests. If there is an exported sub by the given name it will be
imported into your namespace. If there is no such sub an exception will be
thrown.

=item C<!EXPORT_NAME>

You can prefix an export name with C<!> to exclude it at import time. This is
really only usedul when combined with C<-import> or C<-i>.

=item C<< EXPORT_NAME => { -as => "ALT_NAME" } >>

=item C<< EXPORT_NAME => { -prefix => "PREFIX_" } >>

=item C<< EXPORT_NAME => { -postfix => "_POSTFIX" } >>

You may specify a hashref after an export name to rename it, or add a
prefix/postfix to the name.

=back

=head2 RENAMING IMPORTS

    use Test2::V1 '-import', '!ok', ok => {-as => 'my_ok'};

Explanation:

=over 4

=item '-import'

Bring in ALL imports, no need to list them all by hand.

=item '!ok'

Do not import C<ok()> (remove it from the list added by '-import')

=item ok => {-as => 'my_ok'}

Actually, go ahead and import C<ok()> but under the name C<my_ok()>.

=back

If you did not add the C<'!ok'> argument then you would have both C<ok()> and
C<my_ok()>

=head1 PRAGMAS AND PLUGINS

B<NO PRAGMAS ARE ENABLED BY DEFAULT>
B<ONLY THE EXIT SUMMARY PLUGIN IS STILL ENABLED BY DEFAULT>

This is a significant departure from L<Test2::V0>.

You can enable all of these with the C<-pP> argument, which is short for
C<-plugins, -pragmas>. C<P> is short for plugins, and C<p> is short for
pragmas. When using the single-letter form they may both be together following
a single dash, and can be in any order. They may also be combined with C<i> to
bring in all imports. C<-p> or C<-P> ont heir own are also perfectly valid.

=over 4

=item strict

You can enable this with any of these arguments: C<-strict>, C<-p>, C<-pragmas>.

This enables strict for you.

=item warnings

You can enable this with any of these arguments: C<-warnings>, C<-p>, C<-pragmas>.

This enables warnings for you.

=item srand

You can enable this in multiple ways:

    use Test2::V1 -srand
    use Test2::V1 -P
    use Test2::V1 -plugins

See L<Test2::Plugin::SRand>.

This will set the random seed to today's date.

You can also set a random seed:

    use Test2::V1 -srand => { seed => 'my seed' };

=item utf8

You can enable this in multiple ways:

    use Test2::V1 -utf8
    use Test2::V1 -P
    use Test2::V1 -plugins

See L<Test2::Plugin::UTF8>.

This will set the file, and all output handles (including formatter handles), to
utf8. This will turn on the utf8 pragma for the current scope.

=item summary

This is turned on by default.

You can avoid enabling it at import this way:

    use Test2::V1 -summary => 0;

See L<Test2::Plugin::ExitSummary>.

This plugin has no configuration.

=back

=head1 ENVIRONMENT VARIABLES

See L<Test2::Env> for a list of meaningful environment variables.

=head1 API FUNCTIONS

See L<Test2::API> for these

=over 4

=item $ctx = T2->context()

=item $events = T2->intercept(sub { ... });

=back

=head1 THE T2() HANDLE

The C<T2()> subroutine imported into your namespace returns an instance of
L<Test2::V1::Handle>. This gives you a handle on all the tools included by
default. It also creates a completely new namespace for use by your test that
can have additional tools added to it.

=head2 ADDING/OVERRIDING TOOLS IN YOUR T2 HANDLE

    # Method 1
    use Test2::V1 T2 => {
        include => [
            ['Test2::Tools::MyTool', 'my_tool', 'my_other_tool'],
            ['Data::Dumper', 'Dumper'],
        ],
    };

    # Method 2
    use Test2::V1 T2 => {
        include => {
            'Test2::Tools::MyTool' => ['my_tool', 'my_other_tool'],
            'Data::Dumper'         => 'Dumper',
        },
    };

    # Method 3 (This also works with a hashref instead of an arrayref)
    use Test2::V1 -include => [
        ['Test2::Tools::MyTool', 'my_tool', 'my_other_tool'],
        ['Data::Dumper', 'Dumper'],
    ];

    # Method 4
    T2->include('Test2::Tools::MyTool', 'my_tool', 'my_other_tool');
    T2->include('Data::Dumper', 'Dumper');

    # Using them:

    T2->my_tool(...);

    T2->Dumper({hi => 'there'});

Note that you MAY override original tools such as ok(), note(), etc. by
importing different copies this way. The first time you do this there should be
no warnings or errors. If you pull in multiple tools of the same name an
redefine warning is likely.

This also effects exports:

    use Test2::V1 -import, -include => ['Data::Dumper'];

    print Dumper("Dumper can be imported from your include!");

=head2 OTHER HANDLE OPTIONS

    use Test2::V1 T2 => {
        include   => $ARRAYREF_OR_HASHREF,
        namespace => $NAMESPACE,
        base      => $BASE_PACKAGE // 'Test2::V1::Base',
        stomp     => $BOOL,
    };

=over 4

=item include => $ARRAYREF_OR_HASHREF

See L</ADDING TOOLS TO YOUR T2 HANDLE>.

=item namespace => $NAMESPACE

Normally a new namespace will be generated for you. You B<CANNOT> rely on the
package name being anything specific unless you provide your own.

The namespace here will be where any tools you 'include' will be imported into.
It will also have its base class set to the base class you specify, or the
L<Test2::V1::Base> module if you do not provide any.

If this namespace already has any symbols defined in it an exception will be
thrown unless the C<stomp> argument is set to true (not recommended).

=item stomp => $BOOL

Used to allow the handle to stomp on an existing namespace (NOT RECOMMENDED).

=item base => $BASE

Set the base class from which functions should be inherited. Normally this is
set to L<Test2::V1::Base>.

Another interesting use case is to have multiple handles that use eachothers
namespaces as base classes:

    use Test2::V1;

    use Test2::V1::Handle(
        'T3',
        base    => T2->HANDLE_NAMESPACE,
        include => {'Alt::Ok' => 'ok'};
    );

    T3->ok(1, "This uses ok() from Alt::Ok, but all other -> methods are the original");
    T3->done_testing(); # Uses the original done_testing

=back

=head1 EXAMPLE USE CASES

=head2 OVERRIDING INCLUDED TOOLS WITH ALTERNATES

Lets say you want to use the L<Test2::Warnings> version of C<warning()>,
C<warnings()> instead of the L<Test2::Tools::Warnings> versions, and also
wanted to import everything else L<Test2::Warnings> provides.

    use Test2::V1 -import, -include => ['Test2::Warnings'];

The C<< -include => ['Test2::Warnings'] >> option means we want to import the
default set of imports from L<Test2::Warnings> into our C<T2()> handle's
private namespace. This will override any methods that were also previously
defined by default.

The C<-import> option means we want to import all subs into the current namespace.
This includes anything we got from L<Test2::Warnings>, and we will get the
L<Test2::Warnings> version of those subs.

    like(
        warning { warn 'xxx' }, # This is the Test2::Warnings version of 'warning'
        qr/xxx/,
        "Got expected warning"
    );

=head1 TOOLS

=head2 TARGET

I<Added to Test::V1 in 1.302217.>

See L<Test2::Tools::Target>.

You can specify a target class with the C<-target> import argument. If you do
not provide a target then C<$CLASS> and C<CLASS()> will not be imported.

    use Test2::V1 -target => 'My::Class';

    print $CLASS;  # My::Class
    print CLASS(); # My::Class

Or you can specify names:

    use Test2::V1 -target => { pkg => 'Some::Package' };

    pkg()->xxx; # Call 'xxx' on Some::Package
    $pkg->xxx;  # Same

=over 4

=item $CLASS

Package variable that contains the target class name.

=item $class = CLASS()

Constant function that returns the target class name.

=back

=head2 DEFER

See L<Test2::Tools::Defer>.

=over 4

=item def $func => @args;

I<Added to Test::V1 in 1.302217.>

=item do_def()

I<Added to Test::V1 in 1.302217.>

=back

=head2 BASIC

See L<Test2::Tools::Basic>.

=over 4

=item ok($bool, $name)

=item ok($bool, $name, @diag)

I<Added to Test::V1 in 1.302217.>

=item pass($name)

=item pass($name, @diag)

I<Added to Test::V1 in 1.302217.>

=item fail($name)

=item fail($name, @diag)

I<Added to Test::V1 in 1.302217.>

=item diag($message)

I<Added to Test::V1 in 1.302217.>

=item note($message)

I<Added to Test::V1 in 1.302217.>

=item $todo = todo($reason)

=item todo $reason => sub { ... }

I<Added to Test::V1 in 1.302217.>

=item skip($reason, $count)

I<Added to Test::V1 in 1.302217.>

=item plan($count)

I<Added to Test::V1 in 1.302217.>

=item skip_all($reason)

I<Added to Test::V1 in 1.302217.>

=item done_testing()

I<Added to Test::V1 in 1.302217.>

=item bail_out($reason)

I<Added to Test::V1 in 1.302217.>

=back

=head2 COMPARE

See L<Test2::Tools::Compare>.

=over 4

=item is($got, $want, $name)

I<Added to Test::V1 in 1.302217.>

=item isnt($got, $do_not_want, $name)

I<Added to Test::V1 in 1.302217.>

=item like($got, qr/match/, $name)

I<Added to Test::V1 in 1.302217.>

=item unlike($got, qr/mismatch/, $name)

I<Added to Test::V1 in 1.302217.>

=item $check = match(qr/pattern/)

I<Added to Test::V1 in 1.302217.>

=item $check = mismatch(qr/pattern/)

I<Added to Test::V1 in 1.302217.>

=item $check = validator(sub { return $bool })

I<Added to Test::V1 in 1.302217.>

=item $check = hash { ... }

I<Added to Test::V1 in 1.302217.>

=item $check = array { ... }

I<Added to Test::V1 in 1.302217.>

=item $check = bag { ... }

I<Added to Test::V1 in 1.302217.>

=item $check = object { ... }

I<Added to Test::V1 in 1.302217.>

=item $check = meta { ... }

I<Added to Test::V1 in 1.302217.>

=item $check = number($num)

I<Added to Test::V1 in 1.302217.>

=item $check = string($str)

I<Added to Test::V1 in 1.302217.>

=item $check = bool($bool)

I<Added to Test::V1 in 1.302217.>

=item $check = check_isa($class_name)

I<Added to Test::V1 in 1.302217.>

=item $check = in_set(@things)

I<Added to Test::V1 in 1.302217.>

=item $check = not_in_set(@things)

I<Added to Test::V1 in 1.302217.>

=item $check = check_set(@things)

I<Added to Test::V1 in 1.302217.>

=item $check = item($thing)

I<Added to Test::V1 in 1.302217.>

=item $check = item($idx => $thing)

I<Added to Test::V1 in 1.302217.>

=item $check = field($name => $val)

I<Added to Test::V1 in 1.302217.>

=item $check = call($method => $expect)

I<Added to Test::V1 in 1.302217.>

=item $check = call_list($method => $expect)

I<Added to Test::V1 in 1.302217.>

=item $check = call_hash($method => $expect)

I<Added to Test::V1 in 1.302217.>

=item $check = prop($name => $expect)

I<Added to Test::V1 in 1.302217.>

=item $check = check($thing)

I<Added to Test::V1 in 1.302217.>

=item $check = T()

I<Added to Test::V1 in 1.302217.>

=item $check = F()

I<Added to Test::V1 in 1.302217.>

=item $check = D()

I<Added to Test::V1 in 1.302217.>

=item $check = DF()

I<Added to Test::V1 in 1.302217.>

=item $check = E()

I<Added to Test::V1 in 1.302217.>

=item $check = DNE()

I<Added to Test::V1 in 1.302217.>

=item $check = FDNE()

I<Added to Test::V1 in 1.302217.>

=item $check = U()

I<Added to Test::V1 in 1.302217.>

=item $check = L()

I<Added to Test::V1 in 1.302217.>

=item $check = exact_ref($ref)

I<Added to Test::V1 in 1.302217.>

=item end()

I<Added to Test::V1 in 1.302217.>

=item etc()

I<Added to Test::V1 in 1.302217.>

=item filter_items { grep { ... } @_ }

I<Added to Test::V1 in 1.302217.>

=item $check = event $type => ...

I<Added to Test::V1 in 1.302217.>

=item @checks = fail_events $type => ...

I<Added to Test::V1 in 1.302217.>

=back

=head2 CLASSIC COMPARE

See L<Test2::Tools::ClassicCompare>.

=over 4

=item cmp_ok($got, $op, $want, $name)

I<Added to Test::V1 in 1.302217.>

=back

=head2 SUBTEST

See L<Test2::Tools::Subtest>.

=over 4

=item subtest $name => sub { ... };

I<Added to Test::V1 in 1.302217.>

(Note: This is called C<subtest_buffered()> in the Tools module.)

=back

=head2 CLASS

See L<Test2::Tools::Class>.

=over 4

=item can_ok($thing, @methods)

I<Added to Test::V1 in 1.302217.>

=item isa_ok($thing, @classes)

I<Added to Test::V1 in 1.302217.>

=item DOES_ok($thing, @roles)

I<Added to Test::V1 in 1.302217.>

=back

=head2 ENCODING

See L<Test2::Tools::Encoding>.

=over 4

=item set_encoding($encoding)

I<Added to Test::V1 in 1.302217.>

=back

=head2 EXPORTS

See L<Test2::Tools::Exports>.

=over 4

=item imported_ok('function', '$scalar', ...)

I<Added to Test::V1 in 1.302217.>

=item not_imported_ok('function', '$scalar', ...)

I<Added to Test::V1 in 1.302217.>

=back

=head2 REF

See L<Test2::Tools::Ref>.

=over 4

=item ref_ok($ref, $type)

I<Added to Test::V1 in 1.302217.>

=item ref_is($got, $want)

I<Added to Test::V1 in 1.302217.>

=item ref_is_not($got, $do_not_want)

I<Added to Test::V1 in 1.302217.>

=back

See L<Test2::Tools::Refcount>.

=over 4

=item is_refcount($ref, $count, $description)

I<Added to Test::V1 in 1.302217.>

=item is_oneref($ref, $description)

I<Added to Test::V1 in 1.302217.>

=item $count = refcount($ref)

I<Added to Test::V1 in 1.302217.>

=back

=head2 MOCK

See L<Test2::Tools::Mock>.

=over 4

=item $control = mock ...

I<Added to Test::V1 in 1.302217.>

=item $bool = mocked($thing)

I<Added to Test::V1 in 1.302217.>

=back

=head2 EXCEPTION

See L<Test2::Tools::Exception>.

=over 4

=item $exception = dies { ... }

I<Added to Test::V1 in 1.302217.>

=item $bool = lives { ... }

I<Added to Test::V1 in 1.302217.>

=item $bool = try_ok { ... }

I<Added to Test::V1 in 1.302217.>

=back

=head2 WARNINGS

See L<Test2::Tools::Warnings>.

=over 4

=item $count = warns { ... }

I<Added to Test::V1 in 1.302217.>

=item $warning = warning { ... }

I<Added to Test::V1 in 1.302217.>

=item $warnings_ref = warnings { ... }

I<Added to Test::V1 in 1.302217.>

=item $bool = no_warnings { ... }

I<Added to Test::V1 in 1.302217.>

=back

=head1 JUSTIFICATION

L<Test2::V0> is a rich set of tools. But it made several assumptions about how
it would be used. The assumptions are fairly good for new users writing simple
scripts, but they can get in the way in many cases.

=head2 PROBLEMS WITH V0

=over 4

=item Assumptions of strict/warnings

Many people would put custom strict/warnings settings at the top of their
tests, only to have them wiped out when they use L<Test2::V0>.

=item Assumptions of UTF8

Occasionally you do not want this assumption. The way it impacts all your
regular and test handles, as well as how your source is read, can be a problem
if you are not working with UTF8, or have other plans entirly.

=item Huge default set of exports, which can grow

Sometimes you want to keep your namespace clean.

Sometimes you import a tool that does not conflict with anything in
L<Test2::V0>, then we go and add a new tool which conflicts with yours! We make
a point not to break/remove exports, but there is no such commitment about
adding new ones.

Now the only default export is C<T2()> which gives you a handle where all the
tools we expose are provided as methods. You can also use the L<T2> module (Not
bundled with Test-Simple) for use with an identical number of keystrokes, which
allow you to leverage the prototypes on the original tool subroutines.

=back

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
