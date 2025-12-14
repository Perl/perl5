package Test2::Handle;
use strict;
use warnings;

our $VERSION = '1.302219';

require Carp;
require Test2::Util;

use Test2::Util::HashBase qw{
    +namespace
    +base
    +include
    +import
    +stomp
};

my $NS = 1;

# Things we do not want to import automagically
my %EXCLUDE_SYMBOLS = (
    BEGIN   => 1,
    DESTROY => 1,
    DOES    => 1,
    END     => 1,
    VERSION => 1,
    does    => 1,
    can     => 1,
    isa     => 1,
    import  => 1,
);

sub DEFAULT_HANDLE_BASE { Carp::croak("Not Implemented") }

sub HANDLE_BASE { $_[0]->{+BASE} }

sub HANDLE_NAMESPACE { $_[0]->{+NAMESPACE} }

sub _HANDLE_INCLUDE {
    my $self = shift;

    return $self->{+IMPORT} if $self->{+IMPORT};

    my $ns = $self->{+NAMESPACE};

    my $line = __LINE__ + 3;
    $self->{+IMPORT} = eval <<"    EOT" or die $@;
#line $line ${ \__FILE__ }
        package $ns;
        sub {
            my (\$module, \$caller, \@imports) = \@_;
            unless (eval { require(Test2::Util::pkg_to_file(\$module)); 1 }) {
                my \$err = \$@;
                chomp(\$err);
                \$err =~ s/\.\$//;
                die "\$err (called from \$caller->[1] line \$caller->[2]).\n";
            }
            \$module->import(\@imports);
        };
    EOT
}

sub HANDLE_INCLUDE {
    my $self = shift;
    my ($mod, @imports) = @_;
    @imports = @{$imports[0]} if @imports == 1 && ref($imports[0]) eq 'ARRAY';

    my $caller = [caller];

    $self->_HANDLE_INCLUDE->($mod, $caller, @imports);
    $self->_HANDLE_WRAP($_) for @imports;
}

sub HANDLE_SUBS {
    my $self = shift;

    my @out;

    my $seen = {class => {}, export => {}};
    my @todo = ($self->{+NAMESPACE});

    while (my $check = shift @todo) {
        next if $seen->{class}->{$check}++;

        no strict 'refs';
        my $stash = \%{"$check\::"};
        push @out => grep { !$seen->{export}->{$_}++ && !$EXCLUDE_SYMBOLS{$_} && $_ !~ m/^_/ && $check->can($_) } keys %$stash;
        push @todo => @{"$check\::ISA"};
    }

    return @out;
}

sub _HANDLE_WRAP {
    my $self = shift;
    my ($name) = @_;

    return if $self->SUPER::can($name);

    my $wrap = sub {
        my $handle = shift;
        my $ns = $handle->{+NAMESPACE};
        my @caller = caller;
        my $sub = $ns->can($name) or die qq{"$name" is not provided by this T2 handle at $caller[1] line $caller[2].\n};
        goto &$sub;
    };

    {
        no strict 'refs';
        *$name = $wrap;
    }

    return $wrap;
}

sub import {
    my $class = shift;
    my ($name, %params) = @_;

    my $self = $class->new(%params);

    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$name"} = sub() { $self };
}

sub init {
    my $self = shift;

    my $stomp = $self->{+STOMP}   ||= 0;
    my $inc   = $self->{+INCLUDE} ||= [];
    my $base  = $self->{+BASE}    ||= $self->DEFAULT_HANDLE_BASE;

    require(Test2::Util::pkg_to_file($base));

    my $new;
    my $ns = $self->{+NAMESPACE} ||= do { $new = 1; __PACKAGE__ . '::GEN_' . $NS++ };

    my $stash = do { no strict 'refs'; \%{"$ns\::"} };

    Carp::croak("Namespace '$ns' already appears to be populated") if !$stomp && keys %$stash;

    $INC{Test2::Util::pkg_to_file($ns)} ||= __FILE__ if $new;

    {
        no strict 'refs';
        push @{"$ns\::ISA"} => $self->{+BASE};
    }

    if (my $include = $self->{+INCLUDE}) {
        my $r = ref($include);
        if ($r eq 'ARRAY') {
            $self->HANDLE_INCLUDE(ref($_) ? @{$_} : $_) for @$include;
        }
        elsif ($r eq 'HASH') {
            $self->HANDLE_INCLUDE($_ => $include->{$_}) for keys %$include;
        }
        else {
            die "Not sure what to do with '$r'";
        }
    }
}

sub can {
    my $self = shift;
    my ($name) = @_;

    my $sub = $self->SUPER::can($name);
    return $sub if $sub;

    return undef unless ref $self;

    $self->{+NAMESPACE}->can($name) or return undef;
    return $self->_HANDLE_WRAP($name);
}

sub AUTOLOAD {
    my ($self) = @_;

    my ($name) = (our $AUTOLOAD =~ m/^(?:.*::)?([^:]+)$/);
    return if $EXCLUDE_SYMBOLS{$name};

    my $wrap = $self->_HANDLE_WRAP($name);
    goto &$wrap;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Handle - Base class for Test2 handles used in V# bundles.

=head1 DESCRIPTION

This is what you interact with when you use the C<T2()> function in a test that
uses L<Test2::V1>.

=head1 SYNOPSIS

=head2 RECOMMENDED

    use Test2::V1;

    my $handle = T2();

    $handle->ok(1, "Passing Test");

=head2 WITHOUT SUGAR

    use Test2::Handle();

    my $handle = Test2::Handle->new(base => 'Test2::V1::Base');

    $handle->ok(1, "Passing test");

=head1 METHODS

Most methods are delegated to the base class provided at construction. There
are however a few methods that are defined by this package itself.

=over 4

=item $base = $class_or_inst->DEFAULT_HANDLE_BASE

Get the default handle base. This throws an exception on the base handle class,
you should override it in a subclass.

=item $base = $inst->HANDLE_BASE

In this base class this method always throws an exception. In a subclass it
should return the default base class to use for that subclass.

=item $namespace = $inst->HANDLE_NAMESPACE

Get the namespace used to store function we wrap as methods.

=item @sub_names = $inst->HANDLE_SUBS

Get a list of all subs available in the handle namespace.

=item $inst->HANDLE_INCLUDE($package, @subs)

Import the specified subs from the specified package into our internal
namespace.

=item $inst = $class->import()

Used to create a C<T2()> sub in your namsepace at import.

=item $inst->init()

Internally used to intialize and validate the handle object.

=item AUTOLOAD

Internally used to wrap functions as methods.

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
