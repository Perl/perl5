package Test::Stream::Util;
use strict;
use warnings;

use Scalar::Util qw/reftype blessed/;
use Test::Stream::Exporter qw/import export_to exports/;
use Test::Stream::Carp qw/croak/;

exports qw{
    try protect spoof is_regex is_dualvar
    unoverload unoverload_str unoverload_num
    translate_filename
};

Test::Stream::Exporter->cleanup();

sub _manual_protect(&) {
    my $code = shift;

    my ($ok, $error);
    {
        my ($msg, $no) = ($@, $!);
        $ok = eval { $code->(); 1 } || 0;
        $error = $@ || "Error was squashed!\n";
        ($@, $!) = ($msg, $no);
    }
    die $error unless $ok;
    return $ok;
}

sub _local_protect(&) {
    my $code = shift;

    my ($ok, $error);
    {
        local ($@, $!);
        $ok = eval { $code->(); 1 } || 0;
        $error = $@ || "Error was squashed!\n";
    }
    die $error unless $ok;
    return $ok;
}

sub _manual_try(&) {
    my $code = shift;
    my $error;
    my $ok;

    {
        my ($msg, $no) = ($@, $!);
        my $die = delete $SIG{__DIE__};

        $ok = eval { $code->(); 1 } || 0;
        unless($ok) {
            $error = $@ || "Error was squashed!\n";
        }

        ($@, $!) = ($msg, $no);
        $SIG{__DIE__} = $die;
    }

    return wantarray ? ($ok, $error) : $ok;
}

sub _local_try(&) {
    my $code = shift;
    my $error;
    my $ok;

    {
        local ($@, $!, $SIG{__DIE__});
        $ok = eval { $code->(); 1 } || 0;
        unless($ok) {
            $error = $@ || "Error was squashed!\n";
        }
    }

    return wantarray ? ($ok, $error) : $ok;
}

BEGIN {
    if ($^O eq 'MSWin32' && $] < 5.020002) {
        *protect = \&_manual_protect;
        *try     = \&_manual_try;
    }
    else {
        *protect = \&_local_protect;
        *try     = \&_local_try;
    }
}


sub spoof {
    my ($call, $code, @args) = @_;

    croak "The first argument to spoof must be an arrayref with package, filename, and line."
        unless $call && @$call == 3;

    croak "The second argument must be a string to run."
        if ref $code;

    my $error;
    my $ok;

    protect {
        $ok = eval <<"        EOT" || 0;
package $call->[0];
#line $call->[2] "$call->[1]"
$code;
1;
        EOT
        unless($ok) {
            $error = $@ || "Error was squashed!\n";
        }
    };

    return wantarray ? ($ok, $error) : $ok;
}

sub is_regex {
    my ($pattern) = @_;

    return undef unless defined $pattern;

    return $pattern if defined &re::is_regexp
                    && re::is_regexp($pattern);

    my $type = reftype($pattern) || '';

    return $pattern if $type =~ m/^regexp?$/i;
    return $pattern if $type eq 'SCALAR' && $pattern =~ m/^\(\?.+:.*\)$/s;
    return $pattern if !$type && $pattern =~ m/^\(\?.+:.*\)$/s;

    my ($re, $opts);

    if ($pattern =~ m{^ /(.*)/ (\w*) $ }sx) {
        protect { ($re, $opts) = ($1, $2) };
    }
    elsif ($pattern =~ m,^ m([^\w\s]) (.+) \1 (\w*) $,sx) {
        protect { ($re, $opts) = ($2, $3) };
    }
    else {
        return;
    }

    return length $opts ? "(?$opts)$re" : $re;
}

sub unoverload_str { unoverload(q[""], @_) }

sub unoverload_num {
    unoverload('0+', @_);

    for my $val (@_) {
        next unless is_dualvar($$val);
        $$val = $$val + 0;
    }

    return;
}

# This is a hack to detect a dualvar such as $!
sub is_dualvar($) {
    my($val) = @_;

    # Objects are not dualvars.
    return 0 if ref $val;

    no warnings 'numeric';
    my $numval = $val + 0;
    return ($numval != 0 and $numval ne $val ? 1 : 0);
}

## If Scalar::Util is new enough use it
# This breaks cmp_ok diagnostics
#if (my $sub = Scalar::Util->can('isdual')) {
#    no warnings 'redefine';
#    *is_dualvar = $sub;
#}

sub unoverload {
    my $type = shift;

    protect { require overload };

    for my $thing (@_) {
        if (blessed $$thing) {
            if (my $string_meth = overload::Method($$thing, $type)) {
                $$thing = $$thing->$string_meth();
            }
        }
    }
}

my $NORMALIZE = undef;
sub translate_filename {
    my ($encoding, $orig) = @_;

    return $orig if $encoding eq 'legacy';

    my $decoded;
    require Encode;
    try { $decoded = Encode::decode($encoding, "$orig", Encode::FB_CROAK()) };
    return $orig unless $decoded;

    unless (defined $NORMALIZE) {
        $NORMALIZE = try { require Unicode::Normalize; 1 };
        $NORMALIZE ||= 0;
    }
    $decoded = Unicode::Normalize::NFKC($decoded) if $NORMALIZE;
    return $decoded || $orig;
}

1;

__END__

=head1 NAME

Test::Stream::Util - Tools used by Test::Stream and friends.

=head1 DESCRIPTION

Collection of tools used by L<Test::Stream> and friends.

=head1 EXPORTS

=over 4

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

=item spoof([$package, $file, $line], "Code String", @args)

Eval the string provided as the second argument pretending to be the specified
package, file, and line number. The main purpose of this is to have warnings
and exceptions be thrown from the desired context.

Additional arguments will be added to an C<@args> variable that is available to
you inside your code string.

=item $usable_pattern = is_regex($PATTERN)

Check of the specified argument is a regex. This is mainly important in older
perls where C<qr//> did not work the way it does now.

=item is_dualvar

Do not use this, use Scalar::Util::isdual instead. This is kept around for
legacy support.

=item unoverload

=item unoverload_str

=item unoverload_num

Legacy tools for unoverloading things.

=item $proper = translate_filename($encoding, $raw)

Translate filenames from whatever perl has them stored as into the proper,
specified, encoding.

=back

=encoding utf8

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
