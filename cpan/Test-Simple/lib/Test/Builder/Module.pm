package Test::Builder::Module;

use strict;

use Test::Stream 1.301001 '-internal';
use Test::Builder 0.99;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '1.301001_097';
$VERSION = eval $VERSION;      ## no critic (BuiltinFunctions::ProhibitStringyEval)


=head1 NAME

Test::Builder::Module - *DEPRECATED* Base class for test modules

=head1 DEPRECATED

B<This module is deprecated> See L<Test::Stream::Toolset> for what you should
use instead.

=head1 SYNOPSIS

  # Emulates Test::Simple
  package Your::Module;

  my $CLASS = __PACKAGE__;

  use base 'Test::Builder::Module';
  @EXPORT = qw(ok);

  sub ok ($;$) {
      my $tb = $CLASS->builder;
      return $tb->ok(@_);
  }

  1;


=head1 DESCRIPTION

B<This module is deprecated> See L<Test::Stream::Toolset> for what you should
use instead.

This is a superclass for L<Test::Builder>-based modules.  It provides a
handful of common functionality and a method of getting at the underlying
L<Test::Builder> object.


=head2 Importing

Test::Builder::Module is a subclass of L<Exporter> which means your
module is also a subclass of Exporter.  @EXPORT, @EXPORT_OK, etc...
all act normally.

A few methods are provided to do the C<< use Your::Module tests => 23 >> part
for you.

=head3 import

Test::Builder::Module provides an C<import()> method which acts in the
same basic way as L<Test::More>'s, setting the plan and controlling
exporting of functions and variables.  This allows your module to set
the plan independent of L<Test::More>.

All arguments passed to C<import()> are passed onto
C<< Your::Module->builder->plan() >> with the exception of
C<< import =>[qw(things to import)] >>.

    use Your::Module import => [qw(this that)], tests => 23;

says to import the functions C<this()> and C<that()> as well as set the plan
to be 23 tests.

C<import()> also sets the C<exported_to()> attribute of your builder to be
the caller of the C<import()> function.

Additional behaviors can be added to your C<import()> method by overriding
C<import_extra()>.

=cut

sub import {
    my($class) = shift;

    my $test = $class->builder;
    my $caller = caller;

    warn __PACKAGE__ . " is deprecated!\n" if $caller->can('TB_INSTANCE') && $caller->TB_INSTANCE->modern;

    # Don't run all this when loading ourself.
    return 1 if $class eq 'Test::Builder::Module';


    $test->exported_to($caller);

    $class->import_extra( \@_ );
    my(@imports) = $class->_strip_imports( \@_ );

    $test->plan(@_);

    $class->export_to_level( 1, $class, @imports );
}

sub _strip_imports {
    my $class = shift;
    my $list  = shift;

    my @imports = ();
    my @other   = ();
    my $idx     = 0;
    while( $idx <= $#{$list} ) {
        my $item = $list->[$idx];

        if( defined $item and $item eq 'import' ) {
            push @imports, @{ $list->[ $idx + 1 ] };
            $idx++;
        }
        else {
            push @other, $item;
        }

        $idx++;
    }

    @$list = @other;

    return @imports;
}

=head3 import_extra

    Your::Module->import_extra(\@import_args);

C<import_extra()> is called by C<import()>.  It provides an opportunity for you
to add behaviors to your module based on its import list.

Any extra arguments which shouldn't be passed on to C<plan()> should be
stripped off by this method.

See L<Test::More> for an example of its use.

B<NOTE> This mechanism is I<VERY ALPHA AND LIKELY TO CHANGE> as it
feels like a bit of an ugly hack in its current form.

=cut

sub import_extra { }

=head2 Builder

Test::Builder::Module provides some methods of getting at the underlying
Test::Builder object.

=head3 builder

  my $builder = Your::Class->builder;

This method returns the L<Test::Builder> object associated with Your::Class.
It is not a constructor so you can call it as often as you like.

This is the preferred way to get the L<Test::Builder> object.  You should
I<not> get it via C<< Test::Builder->new >> as was previously
recommended.

The object returned by C<builder()> may change at runtime so you should
call C<builder()> inside each function rather than store it in a global.

  sub ok {
      my $builder = Your::Class->builder;

      return $builder->ok(@_);
  }


=cut

sub builder {
    return Test::Builder->new;
}

1;

__END__

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
