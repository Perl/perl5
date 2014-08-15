package Test::Builder::Provider;
use strict;
use warnings;

use Test::Builder 1.301001;
use Test::Builder::Util qw/package_sub is_tester is_provider find_builder/;
use Test::Builder::Trace;
use Carp qw/croak/;
use Scalar::Util qw/reftype set_prototype/;
use B();

my %SIG_MAP = (
    '$' => 'SCALAR',
    '@' => 'ARRAY',
    '%' => 'HASH',
    '&' => 'CODE',
);

my $ID = 1;

sub import {
    my $class = shift;
    my $caller = caller;

    $class->export_into($caller, @_);
}

sub export_into {
    my $class = shift;
    my ($dest, @sym_list) = @_;

    my %subs;

    my $meta = $class->make_provider($dest);

    $subs{TB}      = \&find_builder;
    $subs{builder} = \&find_builder;
    $subs{anoint}  = \&anoint;
    $subs{import}  = \&provider_import;
    $subs{nest}    = \&nest;
    $subs{provide} = $class->_build_provide($dest, $meta);
    $subs{export}  = $class->_build_export($dest, $meta);
    $subs{modernize} = \&modernize;

    $subs{gives}         = sub { $subs{provide}->($_,    undef, give => 1) for @_ };
    $subs{give}          = sub { $subs{provide}->($_[0], $_[1], give => 1)        };
    $subs{provides}      = sub { $subs{provide}->($_)                      for @_ };

    @sym_list = keys %subs unless @sym_list;

    my %seen;
    for my $name (grep { !$seen{$_}++ } @sym_list) {
        no strict 'refs';
        my $ref = $subs{$name} || package_sub($class, $name);
        croak "$class does not export '$name'" unless $ref;
        *{"$dest\::$name"} = $ref ;
    }

    1;
}

sub nest(&) {
    return Test::Builder::Trace->nest(@_);
}

sub make_provider {
    my $class = shift;
    my ($dest) = @_;

    my $meta = is_provider($dest);

    unless ($meta) {
        $meta = {refs => {}, attrs => {}, export => []};
        no strict 'refs';
        *{"$dest\::TB_PROVIDER_META"} = sub { $meta };
    }

    return $meta;
}

sub _build_provide {
    my $class = shift;
    my ($dest, $meta) = @_;

    $meta->{provide} ||= sub {
        my ($name, $ref, %params) = @_;

        croak "$dest already provides or gives '$name'"
            if $meta->{attrs}->{$name};

        croak "The second argument to provide() must be a ref, got: $ref"
            if $ref && !ref $ref;

        $ref ||= package_sub($dest, $name);
        croak "$dest has no sub named '$name', and no ref was given"
            unless $ref;

        my $attrs = {%params, package => $dest, name => $name};
        $meta->{attrs}->{$name} = $attrs;

        push @{$meta->{export}} => $name;

        # If this is just giving, or not a coderef
        return $meta->{refs}->{$name} = $ref if $params{give} || reftype $ref ne 'CODE';

        my $o_name = B::svref_2object($ref)->GV->NAME;
        if ($o_name && $o_name ne '__ANON__') { #sub has a name
            $meta->{refs}->{$name} = $ref;
            $attrs->{named} = 1;
        }
        else {
            $attrs->{named} = 0;
            # Voodoo....
            # Insert an anonymous sub, and use a trick to make caller() think its
            # name is this string, which tells us how to find the thing that was
            # actually called.
            my $globname = __PACKAGE__ . '::__ANON' . ($ID++) . '__';

            my $code = sub {
                no warnings 'once';
                local *__ANON__ = $globname; # Name the sub so we can find it for real.
                $ref->(@_);
            };

            # The prototype on set_prototype blocks this usage, even though it
            # is valid. This is why we use the old-school &func() call.
            # Oh the irony.
            my $proto = prototype($ref);
            &set_prototype($code, $proto) if $proto;

            $meta->{refs}->{$name} = $code;

            no strict 'refs';
            *$globname = $code;
            *$globname = $attrs;
        }
    };

    return $meta->{provide};
}

sub _build_export {
    my $class = shift;
    my ($dest, $meta) = @_;

    return sub {
        my $class = shift;
        my ($caller, @args) = @_;

        my (%no, @list);
        for my $thing (@args) {
            if ($thing =~ m/^!(.*)$/) {
                $no{$1}++;
            }
            else {
                push @list => $thing;
            }
        }

        unless(@list) {
            my %seen;
            @list = grep { !($no{$_} || $seen{$_}++) } @{$meta->{export}};
        }

        for my $name (@list) {
            if ($name =~ m/^(\$|\@|\%)(.*)$/) {
                my ($sig, $sym) = ($1, $2);

                croak "$class does not export '$name'"
                    unless ($meta->{refs}->{$sym} && reftype $meta->{refs}->{$sym} eq $SIG_MAP{$sig});

                no strict 'refs';
                *{"$caller\::$sym"} = $meta->{refs}->{$name} || *{"$class\::$sym"}{$SIG_MAP{$sig}}
                    || croak "'$class' has no symbol named '$name'";
            }
            else {
                croak "$class does not export '$name'"
                    unless $meta->{refs}->{$name};

                no strict 'refs';
                *{"$caller\::$name"} = $meta->{refs}->{$name} || package_sub($class, $name)
                    || croak "'$class' has no sub named '$name'";
            }
        }
    };
}

sub provider_import {
    my $class = shift;
    my $caller = caller;

    $class->anoint($caller);
    $class->before_import(\@_, $caller) if $class->can('before_import');
    $class->export($caller, @_);
    $class->after_import(@_)   if $class->can('after_import');

    1;
}

sub anoint { Test::Builder::Trace->anoint($_[1], $_[0]) };

sub modernize {
    my $target = shift;

    if (package_sub($target, 'TB_INSTANCE')) {
        my $tb = $target->TB_INSTANCE;
        $tb->stream->use_fork;
        $tb->modern(1);
    }
    else {
        my $tb = Test::Builder->create(
            modern        => 1,
            shared_stream => 1,
            no_reset_plan => 1,
        );
        $tb->stream->use_fork;
        no strict 'refs';
        *{"$target\::TB_INSTANCE"} = sub {$tb};
    }
}

1;

=head1 NAME

Test::Builder::Provider - Helper for writing testing tools

=head1 TEST COMPONENT MAP

  [Test Script] > [Test Tool] > [Test::Builder] > [Test::Bulder::Stream] > [Result Formatter]
                       ^
                  You are here

A test script uses a test tool such as L<Test::More>, which uses Test::Builder
to produce results. The results are sent to L<Test::Builder::Stream> which then
forwards them on to one or more formatters. The default formatter is
L<Test::Builder::Fromatter::TAP> which produces TAP output.

=head1 DESCRIPTION

This package provides you with tools to write testing tools. It makes your job
of integrating with L<Test::Builder> and other testing tools much easier.

=head1 SYNOPSYS

Instead of use L<Exporter> or other exporters, you can use convenience
functions to define exports on the fly.

    package My::Tester
    use strict;
    use warnings;

    use Test::Builder::Provider;

    sub before_import {
        my $class = shift;
        my ($import_args_ref) = @_;

        ... Modify $import_args_ref ...
        # $import_args_ref should contain only what you want to pass as
        # arguments into export().
    }

    sub after_import {
        my $class = shift;
        my @args = @_;

        ...
    }

    # Provide (export) an 'ok' function (the anonymous function is the export)
    provide ok => sub { builder()->ok(@_) };

    # Provide some of our package functions as test functions.
    provides qw/is is_deeply/;
    sub is { ... }
    sub is_deeply { ... };

    # Provide a 'subtests' function. Functions that accept a block like this
    # that may run other tests should be use nest() to run the codeblocks they
    # recieve to mark them as nested providers.
    provide subtests => sub(&) {
        my $code = shift;
        nest { $code->() };       # OR: nest(\&$code)   OR: &nest($code);
    };

    # Provide a couple nested functions defined in our package
    provide qw/subtests_alt subtests_xxx/;
    sub subtests_alt(&) { ... }
    sub subtests_xxx(&) { ... }

    # Export a helper function that does not produce any results (regular
    # export).
    give echo => sub { print @_ };

    # Same for multiple functions in our package:
    gives qw/echo_stdout echo_stderr/;
    sub echo_stdout { ... }
    sub echo_stderr { ... }

=head2 IN A TEST FILE

    use Test::More;
    use My::Tester;

    ok(1, "blah");

    is(1, 1, "got 1");

    subtests {
        ok(1, "a subtest");
        ok(1, "another");
    };

=head2 USING EXTERNAL EXPORT LIBRARIES

Maybe you like L<Exporter> or another export tool. In that case you still need
the 'provides' and 'nest' functions from here to mark testing tools as such.

This is also a quick way to update an old library, but you also need to remove
any references to C<$Test::Builder::Level> which is now deprecated.

    package My::Tester
    use strict;
    use warnings;

    use base 'Exporter';
    use Test::Builder::Provider qw/provides nest/;

    our @EXPORT = qw{
        ok is is_deeply
        subtests subtests_alt subtests_xxx
        echo echo_stderr echo stdout
    };

    # *mark* the testing tools
    provides qw/ok is is_deeply/;
    sub ok { builder()->ok(@_) }
    sub is { ... }
    sub is_deeply { ... };

    # Remember to use nest()
    provide qw/subtests subtests_alt subtests_xxx/;
    sub subtests(&) { ... }
    sub subtests_alt(&) { ... }
    sub subtests_xxx(&) { ... }

    # No special marking needed for these as they do not produce results.
    sub echo { print @_ }
    sub echo_stdout { ... }
    sub echo_stderr { ... }

=head2 SUPPORTING OLD VERSIONS

See L<Test::Builder::Compat> which is a seperate dist that has no dependancies.
You can use it to write providers that make use of the new Test::Builder, while
also working fine on older versions of Test::Builder.

=head1 META-DATA

Importing this module will always mark your package as a test provider. It does
this by injecting a method into your package called 'TB_PROVIDER_META'. This
method simply returns the meta-data hash for your package.

To avoid this you can use 'require' instead of 'use', or you can use () in your import:

    # Load the module, but do not make this package a provider.
    require Test::Builder::Provider;
    use Test::Builder::Provider();

=head1 EXPORTS

All of these subs are injected into your package (unless you request a subset).

=over 4

=item my $tb = TB()

=item my $tb = builder()

Get the correct instance of L<Test::Builder>. Usually this is the instance used
in the test file calling a tool in your package. If no such instance can be
found the default Test::Builder instance will be used.

=item $class->anoint($target)

Used to mark the $target package as a test package that consumes your test
package for tools. This is done automatically for you if you use the default
'import' sub below.

=item $class->import()

=item $class->import(@list)

An import() function that exports your tools to any consumers of your class.

=item $class->export($dest)

=item $class->export($dest, @list)

Export the packages tools into the $dest package. @list me be specified to
restrict what is exported. Prefix any item in the list with '!' to prevent
exporting it.

=item provide $name

=item provide $name => sub { ... }

Provide a testing tool that will produce results. If no coderef is given it
will look for a coderef with $name in your package.

You may also use this to export refs of any type.

=item provides qw/sub1 sub2 .../

Like provide except you can specify multiple subs to export.

=item nest { ... }

=item nest(\&$code)

=item &nest($code)

Used as a tracing barrier, any results generated inside the nest will trace to
the nest as opposed to the call to your provided tool.

=item give $name

=item give $name => sub { ... }

Export a helper function that does not produce results.

=item gives qw/sub1 sub2 .../

Export helper functions.

=back

=head1 HOW DO I TEST MY TEST TOOLS?

See L<Test::Tester2>

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
