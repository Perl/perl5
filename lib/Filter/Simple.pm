package Filter::Simple;

use vars qw{ $VERSION };

$VERSION = '0.50';

use Filter::Util::Call;
use Carp;

sub import {
	my $caller = caller;
	my ($class, $filter) = @_;
	croak "Usage: use Filter::Simple sub {...}" unless ref $filter eq CODE;
	*{"${caller}::import"} = gen_filter_import($caller, $filter);
	*{"${caller}::unimport"} = \*filter_unimport;
}

sub gen_filter_import {
    my ($class, $filter) = @_;
    return sub {
	my ($imported_class, @args) = @_;
	filter_add(
		sub {
			my ($status, $off);
			my $data = "";
			while ($status = filter_read()) {
				if (m/^\s*no\s+$class\s*;\s*$/) {
					$off=1;
					last;
				}
				$data .= $_;
				$_ = "";
			}
			$_ = $data;
			$filter->(@args) unless $status < 0;
			$_ .= "no $class;\n" if $off;
			return length;
		}
	);
    }
}

sub filter_unimport {
	filter_del();
}

1;

__END__

=head1 NAME

Filter::Simple - Simplified source filtering

=head1 SYNOPSIS

 # in MyFilter.pm:

	 package MyFilter;

	 use Filter::Simple sub { ... };


 # in user's code:

	 use MyFilter;

	 # this code is filtered

	 no MyFilter;

	 # this code is not


=head1 DESCRIPTION

=head2 The Problem

Source filtering is an immensely powerful feature of recent versions of Perl.
It allows one to extend the language itself (e.g. the Switch module), to 
simplify the language (e.g. Language::Pythonesque), or to completely recast the
language (e.g. Lingua::Romana::Perligata). Effectively, it allows one to use
the full power of Perl as its own, recursively applied, macro language.

The excellent Filter::Util::Call module (by Paul Marquess) provides a
usable Perl interface to source filtering, but it is often too powerful
and not nearly as simple as it could be.

To use the module it is necessary to do the following:

=over 4

=item 1.

Download, build, and install the Filter::Util::Call module.
(If you are using Perl 5.7.1 or later, you already have Filter::Util::Call.)

=item 2.

Set up a module that does a C<use Filter::Util::Call>.

=item 3.

Within that module, create an C<import> subroutine.

=item 4.

Within the C<import> subroutine do a call to C<filter_add>, passing
it either a subroutine reference.

=item 5.

Within the subroutine reference, call C<filter_read> or C<filter_read_exact>
to "prime" $_ with source code data from the source file that will
C<use> your module. Check the status value returned to see if any
source code was actually read in.

=item 6.

Process the contents of $_ to change the source code in the desired manner.

=item 7.

Return the status value.

=item 8.

If the act of unimporting your module (via a C<no>) should cause source
code filtering to cease, create an C<unimport> subroutine, and have it call
C<filter_del>. Make sure that the call to C<filter_read> or
C<filter_read_exact> in step 5 will not accidentally read past the
C<no>. Effectively this limits source code filters to line-by-line
operation, unless the C<import> subroutine does some fancy
pre-pre-parsing of the source code it's filtering.

=back

For example, here is a minimal source code filter in a module named
BANG.pm. It simply converts every occurrence of the sequence C<BANG\s+BANG>
to the sequence C<die 'BANG' if $BANG> in any piece of code following a
C<use BANG;> statement (until the next C<no BANG;> statement, if any):

        package BANG;

        use Filter::Util::Call ;

        sub import {
            filter_add( sub {
                my $caller = caller;
                my ($status, $no_seen, $data);
                while ($status = filter_read()) {
                        if (/^\s*no\s+$caller\s*;\s*$/) {
                                $no_seen=1;
                                last;
                        }
                        $data .= $_;
                        $_ = "";
                }
                $_ = $data;
                s/BANG\s+BANG/die 'BANG' if \$BANG/g
                        unless $status < 0;
                $_ .= "no $class;\n" if $no_seen;
                return 1;
            })
        }

        sub unimport {
            filter_del();
        }

        1 ;

This level of sophistication puts filtering out of the reach of
many programmers.


=head2 A Solution

The Filter::Simple module provides a simplified interface to
Filter::Util::Call; one that is sufficient for most common cases.

Instead of the above process, with Filter::Simple the task of setting up
a source code filter is reduced to:

=over 4

=item 1.

Set up a module that does a C<use Filter::Simple sub { ... }>.

=item 2.

Within the anonymous subroutine passed to C<use Filter::Simple>, process the
contents of $_ to change the source code in the desired manner.

=back

In other words, the previous example, would become:

        package BANG;

        use Filter::Simple sub {
            s/BANG\s+BANG/die 'BANG' if \$BANG/g;
        };

        1 ;


=head2 How it works

The Filter::Simple module exports into the package that C<use>s it (e.g.
package "BANG" in the above example) two automagically constructed
subroutines -- C<import> and C<unimport> -- which take care of all the
nasty details.

In addition, the generated C<import> subroutine passes its own argument
list to the filtering subroutine, so the BANG.pm filter could easily 
be made parametric:

        package BANG;

        use Filter::Simple sub {
            my ($die_msg, $var_name) = @_;
            s/BANG\s+BANG/die '$die_msg' if \${$var_name}/g;
        };

        # and in some user code:

        use BANG "BOOM", "BAM;  # "BANG BANG" becomes: die 'BOOM' if $BAM


The specified filtering subroutine is called every time a C<use BANG>
is encountered, and passed all the source code following that call,
up to either the next C<no BANG;> call or the end of the source file
(whichever occurs first). Currently, any C<no BANG;> call must appear
by itself on a separate line, or it is ignored.


=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 COPYRIGHT

 Copyright (c) 2000, Damian Conway. All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
