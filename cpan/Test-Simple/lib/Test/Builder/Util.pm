package Test::Builder::Util;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/reftype blessed/;
use Test::Builder::Threads;

my $meta = {};
sub TB_EXPORT_META { $meta };

exports(qw/
    import export exports accessor accessors delta deltas export_to transform
    atomic_delta atomic_deltas try protect
    package_sub is_tester is_provider find_builder
/);

export(new => sub {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;

    $self->pre_init(\%params) if $self->can('pre_init');

    my @attrs = keys %params;
    @attrs = $self->init_order(@attrs) if @attrs && $self->can('init_order');

    for my $attr (@attrs) {
        croak "$class has no method named '$attr'" unless $self->can($attr);
        $self->$attr($params{$attr});
    }

    $self->init(%params) if $self->can('init');

    return $self;
});

sub import {
    my $class = shift;
    my $caller = caller;

    if (grep {$_ eq 'import'} @_) {
        my $meta = {};
        no strict 'refs';
        *{"$caller\::TB_EXPORT_META"} = sub { $meta };
    }

    $class->export_to($caller, @_) if @_;

    1;
}

sub export_to {
    my $from = shift;
    my ($to, @subs) = @_;

    croak "package '$from' is not a TB exporter"
        unless is_exporter($from);

    croak "No destination package specified."
        unless $to;

    return unless @subs;

    my $meta = $from->TB_EXPORT_META;

    for my $name (@subs) {
        my $ref = $meta->{$name} || croak "$from does not export '$name'";
        no strict 'refs';
        *{"$to\::$name"} = $ref;
    }

    1;
}

sub exports {
    my $caller = caller;

    my $meta = is_exporter($caller)
        || croak "$caller is not an exporter!";

    for my $name (@_) {
        my $ref = $caller->can($name);
        croak "$caller has no sub named '$name'" unless $ref;

        croak "Already exporting '$name'"
            if $meta->{$name};

        $meta->{$name} = $ref;
    }
}

sub export {
    my ($name, $ref) = @_;
    my $caller = caller;

    croak "The first argument to export() must be a symbol name"
        unless $name;

    $ref ||= $caller->can($name);
    croak "$caller has no sub named '$name', and no ref was provided"
        unless $ref;

    # Allow any type of ref, people can export scalars, hashes, etc.
    croak "The second argument to export() must be a reference"
        unless ref $ref;

    my $meta = is_exporter($caller)
        || croak "$caller is not an exporter!";

    croak "Already exporting '$name'"
        if $meta->{$name};

    $meta->{$name} = $ref;
}

sub accessor {
    my ($name, $default) = @_;
    my $caller = caller;

    croak "The second argument to accessor() must be a coderef, not '$default'"
        if $default && !(ref $default && reftype $default eq 'CODE');

    _accessor($caller, $name, $default);
}

sub accessors {
    my ($name) = @_;
    my $caller = caller;

    _accessor($caller, "$_") for @_;
}

sub _accessor {
    my ($caller, $attr, $default) = @_;
    my $name = lc $attr;

    my $sub = sub {
        my $self = shift;
        croak "$name\() must be called on a blessed instance, got: $self"
            unless blessed $self;

        $self->{$attr} = $self->$default if $default && !exists $self->{$attr};
        ($self->{$attr}) = @_ if @_;

        return $self->{$attr};
    };

    no strict 'refs';
    *{"$caller\::$name"} = $sub;
}

sub transform {
    my $name = shift;
    my $code = pop;
    my ($attr) = @_;
    my $caller = caller;

    $attr ||= $name;

    croak "name is mandatory"              unless $name;
    croak "takes a minimum of 2 arguments" unless $code;

    my $sub = sub {
        my $self = shift;
        croak "$name\() must be called on a blessed instance, got: $self"
            unless blessed $self;

        $self->{$attr} = $self->$code(@_) if @_ and defined $_[0];

        return $self->{$attr};
    };

    no strict 'refs';
    *{"$caller\::$name"} = $sub;
}

sub delta {
    my ($name, $initial) = @_;
    my $caller = caller;

    _delta($caller, $name, $initial || 0, 0);
}

sub deltas {
    my $caller = caller;
    _delta($caller, "$_", 0, 0) for @_;
}

sub atomic_delta {
    my ($name, $initial) = @_;
    my $caller = caller;

    _delta($caller, $name, $initial || 0, 1);
}

sub atomic_deltas {
    my $caller = caller;
    _delta($caller, "$_", 0, 1) for @_;
}

sub _delta {
    my ($caller, $attr, $initial, $atomic) = @_;
    my $name = lc $attr;

    my $sub = sub {
        my $self = shift;

        croak "$name\() must be called on a blessed instance, got: $self"
            unless blessed $self;

        lock $self->{$attr} if $atomic;
        $self->{$attr} = $initial unless defined $self->{$attr};
        $self->{$attr} += $_[0] if @_;

        return $self->{$attr};
    };

    no strict 'refs';
    *{"$caller\::$name"} = $sub;
}

sub protect(&) {
    my $code = shift;

    my ($ok, $error);
    {
        local $@;
        local $!;
        $ok = eval { $code->(); 1 } || 0;
        $error = $@ || "Error was squashed!\n";
    }
    die $error unless $ok;
    return $ok;
}

sub try(&) {
    my $code = shift;
    my $error;
    my $ok;

    {
        local $@;
        local $!;
        local $SIG{__DIE__};

        $ok = eval { $code->(); 1 } || 0;
        unless($ok) {
            $error = $@ || "Error was squashed!\n";
        }
    }

    return wantarray ? ($ok, $error) : $ok;
}

sub package_sub {
    my ($pkg, $sub) = @_;
    no warnings 'once';

    my $globref = do {
        no strict 'refs';
        \*{"$pkg\::$sub"};
    };

    return *$globref{CODE} || undef;
}

sub is_exporter {
    my $pkg = shift;
    return unless package_sub($pkg, 'TB_EXPORT_META');
    return $pkg->TB_EXPORT_META;
}

sub is_tester {
    my $pkg = shift;
    return unless package_sub($pkg, 'TB_TESTER_META');
    return $pkg->TB_TESTER_META;
}

sub is_provider {
    my $pkg = shift;
    return unless package_sub($pkg, 'TB_PROVIDER_META');
    return $pkg->TB_PROVIDER_META;
}

sub find_builder {
    my $trace = Test::Builder->trace_test;

    if ($trace && $trace->report) {
        my $pkg = $trace->report->package;
        return $pkg->TB_INSTANCE
            if $pkg && package_sub($pkg, 'TB_INSTANCE');
    }

    return Test::Builder->new;
}

1;

__END__

=head1 NAME

Test::Builder::Util - Internal tools for Test::Builder and friends

=head1 DESCRIPTION

Tools for generating accessors and other object bits and pieces.

=head1 SYNOPSYS

    #Imports a sub named 'new' and all the other tools.
    use Test::Builder::Util;

    # Define some exports
    export 'foo'; # Export the 'foo' sub
    export bar => sub { ... }; # export an anon sub named bar

    # Generate some accessors
    accessors qw/yabba dabba doo/;

=head1 EXPORTS

=over 4

=item $class->new(...)

Generic constructor method, can be used in almost any package. Takes key/value
pairs as arguments. Key is assumed to be the name of a method or accessor. The
method named for the key is called with the value as an argument. You can also
define an 'init' method which this will call for you on the newly created
object.

=item $class->import(@list)

Importing this method lets you define exports.

=item $class->export_to($dest_package, @names)

Export @names to the package $dest_package

=item exports(@names)

Export the subs named in @names.

=item export($name)

=item export($name => sub { ... })

Export a sub named $name. Optionally a coderef may be used.

=item accessor($name)

=item accessor($name, sub { return $DEFAULT })

Define an accessor. A default value can be specified via a coderef.

=item accessors(qw/sub1 sub2 .../)

Define several read/write accessors at once.

=item transform($name, sub { ($self, @args) = @_; ... })

=item transform($name, $attr, sub { ($self, @args) = @_; ... })

Define a read/write accessor that transforms whatever you assign to it via the
given coderef. $attr is optional and defaults to $name. $attr is the key inside
the blessed object hash used to store the field.

=item delta($name)

=item delta($name => $default)

=item deltas(qw/name1 name2 .../)

=item atomic_delta($name)

=item atomic_delta($name => $default)

=item atomic_deltas(qw/name1 name2 .../)

A delta accessor is an accessor that adds the numeric argument to the current
value. Optionally a default value can be specified, otherwise 0 is used.

The atomic variations are thread-safe.

=item $success = try { ... }

=item ($success, $error) = try { ... }

Eval the codeblock, return success or failure, and optionally the error
message. This code protects $@ and $!, they will be restored by the end of the
run. This code also temporarily blocks $SIG{DIE} handlers.

=item protect { ... }

Similar to try, except that it does not catch exceptions. The idea here is to
protect $@ and $! from changes. $@ and $! will be restored to whatever they
were before the run so long as it is successful. If the run fails $! will still
be restored, but $@ will contain the exception being thrown.

=item $coderef = package_sub($package, $subname)

Find a sub in a package, returns the coderef if it is present, otherwise it
returns undef. This is similar to C<< $package->can($subname) >> except that it
ignores inheritance.

=item $meta = is_tester($package)

Check if a package is a tester, return the metadata if it is.

=item $meta = is_provider($package)

Check if a package is a provider, return the metadata if it is.

=item $TB = find_builder()

Find the Test::Builder instance to use.

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
