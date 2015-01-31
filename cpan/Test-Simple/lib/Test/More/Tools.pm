package Test::More::Tools;
use strict;
use warnings;

use Test::Stream::Context;

use Test::Stream::Exporter;
default_exports qw/tmt/;
Test::Stream::Exporter->cleanup;

use Test::Stream::Util qw/try protect is_regex unoverload_str unoverload_num/;
use Scalar::Util qw/blessed reftype/;

sub tmt() { __PACKAGE__ }

# Bad, these are not comparison operators. Should we include more?
my %CMP_OK_BL    = map { ( $_, 1 ) } ( "=", "+=", ".=", "x=", "^=", "|=", "||=", "&&=", "...");
my %NUMERIC_CMPS = map { ( $_, 1 ) } ( "<", "<=", ">", ">=", "==", "!=", "<=>" );

sub _cmp_eval {
    my ($line, $name, $file, $got, $type, $expect) = @_;
    my $test;
    # This is so that warnings come out at the caller's level
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    eval qq[
#line $line "(eval in $name) $file"
\$test = (\$got $type \$expect);
1;
    ] || die $@;
    return $test;
}

sub cmp_check {
    my($class, $got, $type, $expect) = @_;

    my $ctx = context();
    my $name = $ctx->subname;
    $name =~ s/^.*:://g;
    $name = 'cmp_check' if $name eq '__ANON__';
    $ctx->throw("$type is not a valid comparison operator in $name\()")
        if $CMP_OK_BL{$type};

    my ($p, $file, $line) = $ctx->call;

    my $test = 0;
    my ($success, $error) = try {
        $test = _cmp_eval($line, $name, $file, $got, $type, $expect);
    };

    my @diag;
    push @diag => <<"    END" unless $success;
An error occurred while using $type:
------------------------------------
$error
------------------------------------
    END

    unless($test) {
        # Treat overloaded objects as numbers if we're asked to do a
        # numeric comparison.
        my $unoverload = $NUMERIC_CMPS{$type}
            ? \&unoverload_num
            : \&unoverload_str;

        $unoverload->(\$got, \$expect);

        if( $type =~ /^(eq|==)$/ ) {
            push @diag => $class->_is_diag( $got, $type, $expect );
        }
        elsif( $type =~ /^(ne|!=)$/ ) {
            push @diag => $class->_isnt_diag( $got, $type );
        }
        else {
            push @diag => $class->_cmp_diag( $got, $type, $expect );
        }
    }

    return($test, @diag);
}

sub is_eq {
    my($class, $got, $expect) = @_;

    if( !defined $got || !defined $expect ) {
        # undef only matches undef and nothing else
        my $test = !defined $got && !defined $expect;
        return ($test, $test ? () : $class->_is_diag($got, 'eq', $expect));
    }

    return $class->cmp_check($got, 'eq', $expect);
}

sub is_num {
    my($class, $got, $expect) = @_;

    if( !defined $got || !defined $expect ) {
        # undef only matches undef and nothing else
        my $test = !defined $got && !defined $expect;
        return ($test, $test ? () : $class->_is_diag($got, '==', $expect));
    }

    return $class->cmp_check($got, '==', $expect);
}

sub isnt_eq {
    my($class, $got, $dont_expect) = @_;

    if( !defined $got || !defined $dont_expect ) {
        # undef only matches undef and nothing else
        my $test = defined $got || defined $dont_expect;
        return ($test, $test ? () : $class->_isnt_diag($got, 'ne'));
    }

    return $class->cmp_check($got, 'ne', $dont_expect);
}

sub isnt_num {
    my($class, $got, $dont_expect) = @_;

    if( !defined $got || !defined $dont_expect ) {
        # undef only matches undef and nothing else
        my $test = defined $got || defined $dont_expect;
        return ($test, $test ? () : $class->_isnt_diag($got, '!='));
    }

    return $class->cmp_check($got, '!=', $dont_expect);
}

sub regex_check {
    my($class, $thing, $got_regex, $cmp) = @_;

    my $regex = is_regex($got_regex);
    return (0, "    '$got_regex' doesn't look much like a regex to me.")
        unless defined $regex;

    my $ctx = context();
    my ($p, $file, $line) = $ctx->call;

    my $test;
    my $mock = qq{#line $line "$file"\n};

    my @warnings;
    my ($success, $error) = try {
        # No point in issuing an uninit warning, they'll see it in the diagnostics
        no warnings 'uninitialized';
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        protect { eval $mock . q{$test = $thing =~ /$regex/ ? 1 : 0; 1} || die $@ };
    };

    return (0, "Exception: $error") unless $success;

    my $negate = $cmp eq '!~';

    $test = !$test if $negate;

    unless($test) {
        $thing = defined $thing ? "'$thing'" : 'undef';
        my $match = $negate ? "matches" : "doesn't match";
        my $diag = sprintf(qq{                  \%s\n    \%13s '\%s'\n}, $thing, $match, $got_regex);
        return (0, $diag);
    }

    return (1);
}

sub can_check {
    my ($us, $proto, $class, @methods) = @_;

    my @diag;
    for my $method (@methods) {
        my $ok;
        my ($success, $error) = try { $ok = $proto->can($method) };
        if ($success) {
            push @diag => "    $class\->can('$method') failed" unless $ok;
        }
        else {
            my $file = __FILE__;
            $error =~ s/ at \Q$file\E line \d+//;
            push @diag => "    $class\->can('$method') failed with an exception:\n    $error";
        }
    }

    return (!@diag, @diag)
}

sub isa_check {
    my($us, $thing, $class, $thing_name) = @_;

    my ($whatami, $try_isa, $diag, $type);
    if( !defined $thing ) {
        $whatami = 'undef';
        $$thing_name = "undef" unless defined $$thing_name;
        $diag = defined $thing ? "$$thing_name isn't a '$class'" : "$$thing_name isn't defined";
    }
    elsif($type = blessed $thing) {
        $whatami = 'object';
        $try_isa = 1;
        $$thing_name = "An object of class '$type'" unless defined $$thing_name;
        $diag = "$$thing_name isn't a '$class'";
    }
    elsif($type = ref $thing) {
        $whatami = 'reference';
        $$thing_name = "A reference of type '$type'" unless defined $$thing_name;
        $diag = "$$thing_name isn't a '$class'";
    }
    else {
        $whatami = 'class';
        $try_isa = $thing && $thing !~ m/^\d+$/;
        $$thing_name = "The class (or class-like) '$thing'" unless defined $$thing_name;
        $diag = "$$thing_name isn't a '$class'";
    }

    my $ok;
    if ($try_isa) {
        # We can't use UNIVERSAL::isa because we want to honor isa() overrides
        my ($success, $error) = try {
            my $ctx = context();
            my ($p, $f, $l) = $ctx->call;
            eval qq{#line $l "$f"\n\$ok = \$thing\->isa(\$class); 1} || die $@;
        };

        die <<"        WHOA" unless $success;
WHOA! I tried to call ->isa on your $whatami and got some weird error.
Here's the error.
$error
        WHOA
    }
    else {
        # Special case for isa_ok( [], "ARRAY" ) and like
        $ok = UNIVERSAL::isa($thing, $class);
    }

    return ($ok) if $ok;
    return ($ok, "    $diag\n");
}

sub new_check {
    my($us, $class, $args, $object_name) = @_;

    $args ||= [];

    my $obj;
    my($success, $error) = try {
        my $ctx = context();
        my ($p, $f, $l) = $ctx->call;
        eval qq{#line $l "$f"\n\$obj = \$class\->new(\@\$args); 1} || die $@;
    };
    if($success) {
        $object_name = "'$object_name'" if $object_name;
        my ($ok, @diag) = $us->isa_check($obj, $class, \$object_name);
        my $name = "$object_name isa '$class'";
        return ($obj, $name, $ok, @diag);
    }
    else {
        $class = 'undef' unless defined $class;
        return (undef, "$class->new() died", 0, "    Error was:  $error");
    }
}

sub explain {
    my ($us, @args) = @_;
    protect { require Data::Dumper };

    return map {
        ref $_
          ? do {
            my $dumper = Data::Dumper->new( [$_] );
            $dumper->Indent(1)->Terse(1);
            $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
            $dumper->Dump;
          }
          : $_
    } @args;
}

sub _diag_fmt {
    my( $class, $type, $val ) = @_;

    if( defined $$val ) {
        if( $type eq 'eq' or $type eq 'ne' ) {
            # quote and force string context
            $$val = "'$$val'";
        }
        else {
            # force numeric context
            unoverload_num($val);
        }
    }
    else {
        $$val = 'undef';
    }

    return;
}

sub _is_diag {
    my( $class, $got, $type, $expect ) = @_;

    $class->_diag_fmt( $type, $_ ) for \$got, \$expect;

    return <<"DIAGNOSTIC";
         got: $got
    expected: $expect
DIAGNOSTIC
}

sub _isnt_diag {
    my( $class, $got, $type ) = @_;

    $class->_diag_fmt( $type, \$got );

    return <<"DIAGNOSTIC";
         got: $got
    expected: anything else
DIAGNOSTIC
}


sub _cmp_diag {
    my( $class, $got, $type, $expect ) = @_;

    $got    = defined $got    ? "'$got'"    : 'undef';
    $expect = defined $expect ? "'$expect'" : 'undef';

    return <<"DIAGNOSTIC";
    $got
        $type
    $expect
DIAGNOSTIC
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::More::Tools - Generic form of tools from Test::More.

=head1 DESCRIPTION

People used to call L<Test::More> tools within other testing tools. This mostly
works, but it generates events for each call. This package gives you access to
the implementations directly, without generating events for you. This allows
you to create a composite tool without generating extra events.

=head1 SYNOPSYS

    use Test::More::Tools qw/tmt/;
    use Test::Stream::Toolset qw/context/;

    # This is how Test::More::is is implemented
    sub my_is {
        my ($got, $want, $name) = @_;

        my $ctx = context;

        my ($ok, @diag) = tmt->is_eq($got, $want);

        $ctx->ok($ok, $name, \@diag);
    }

=head1 EXPORTS

=over 4

=item $pkg = tmt()

Simply returns the string 'Test::More::Tools';

=back

=head1 CLASS METHODS

Not all methods are listed. The ones that have been omitted are not intuitive,
and probably should not be used at all.

=over 4

=item ($bool, @diag) = tmt->cmp_check($got, $op, $want)

Check 2 values using the operator specified example: C<$got == $want>

=item ($bool, @diag) = tmt->is_eq($got, $want)

String compare.

=item ($bool, @diag) = tmt->is_num($got, $want)

Numeric compare.

=item ($bool, @diag) = tmt->isnt_eq($got, $dont_want)

String inequality compare.

=item ($bool, @diag) = tmt->isnt_num($got, $dont_want)

Numeric inequality compare.

=item ($bool, @diag) = tmt->regex_check($got, $regex, $op)

Regex compare. C<$op> may be C<=~> or C<!~>.

=back

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
