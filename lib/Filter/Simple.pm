package Filter::Simple;

use vars qw{ $VERSION };

$VERSION = '0.61';

use Filter::Util::Call;
use Carp;

sub import {
	if (@_>1) { shift; goto &FILTER }
	else      { *{caller()."::FILTER"} = \&FILTER }
}

sub FILTER (&;$) {
	my $caller = caller;
	my ($filter, $terminator) = @_;
	*{"${caller}::import"} = gen_filter_import($caller,$filter,$terminator);
	*{"${caller}::unimport"} = \*filter_unimport;
}

sub gen_filter_import {
    my ($class, $filter, $terminator) = @_;
    return sub {
	my ($imported_class, @args) = @_;
	$terminator = qr/^\s*no\s+$imported_class\s*;\s*$/
		unless defined $terminator;
	filter_add(
		sub {
			my ($status, $off);
			my $count = 0;
			my $data = "";
			while ($status = filter_read()) {
				return $status if $status < 0;
				if ($terminator && m/$terminator/) {
					$off=1;
					last;
				}
				$data .= $_;
				$count++;
				$_ = "";
			}
			$_ = $data;
			$filter->(@args) unless $status < 0;
			$_ .= "no $imported_class;\n" if $off;
			return $count;
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

	 use Filter::Simple;
	 
	 FILTER { ... };

	 # or just:
	 #
	 # use Filter::Simple sub { ... };

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
(If you have Perl 5.7.1 or later, this is already done for you.)

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
                        if (/^\s*no\s+$caller\s*;\s*?$/) {
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

Download and install the Filter::Simple module.
(If you have Perl 5.7.1 or later, this is already done for you.)

=item 2.

Set up a module that does a C<use Filter::Simple> and then
calls C<FILTER { ... }>.

=item 3.

Within the anonymous subroutine or block that is passed to
C<FILTER>, process the contents of $_ to change the source code in
the desired manner.

=back

In other words, the previous example, would become:

        package BANG;
        use Filter::Simple;
	
	FILTER {
            s/BANG\s+BANG/die 'BANG' if \$BANG/g;
        };

        1 ;


=head2 Disabling or changing <no> behaviour

By default, the installed filter only filters to a line of the form:

        no ModuleName;

but this can be altered by passing a second argument to C<use Filter::Simple>.

That second argument may be either a C<qr>'d regular expression (which is then
used to match the terminator line), or a defined false value (which indicates
that no terminator line should be looked for).

For example, to cause the previous filter to filter only up to a line of the
form:

        GNAB esu;

you would write:

        package BANG;
        use Filter::Simple;
	
	FILTER {
                s/BANG\s+BANG/die 'BANG' if \$BANG/g;
        }
        => qr/^\s*GNAB\s+esu\s*;\s*?$/;

and to prevent the filter's being turned off in any way:

        package BANG;
        use Filter::Simple;
	
	FILTER {
                s/BANG\s+BANG/die 'BANG' if \$BANG/g;
        }
              => "";
	# or: => 0;


=head2 All-in-one interface

Separating the loading of Filter::Simple:

        use Filter::Simple;

from the setting up of the filtering:

        FILTER { ... };

is useful because it allows other code (typically parser support code
or caching variables) to be defined before the filter is invoked.
However, there is often no need for such a separation.

In those cases, it is easier to just append the filtering subroutine and
any terminator specification directly to the C<use> statement that loads
Filter::Simple, like so:

        use Filter::Simple sub {
                s/BANG\s+BANG/die 'BANG' if \$BANG/g;
        };

This is exactly the same as:

        use Filter::Simple;
	BEGIN {
		Filter::Simple::FILTER {
			s/BANG\s+BANG/die 'BANG' if \$BANG/g;
		};
	}

except that the C<FILTER> subroutine is not exported by Filter::Simple.

=head2 Using Filter::Simple and Exporter together

You can't directly use Exporter when Filter::Simple.

Filter::Simple generates an C<import> subroutine for your module
(which hides the one inherited from Exporter).

The C<FILTER> code you specify will, however, receive the C<import>'s argument
list, so you can use that filter block as your C<import> subroutine.

You'll need to call C<Exporter::export_to_level> from your C<FILTER> code
to make it work correctly.

For example:

        use Filter::Simple;

        use base Exporter;
        @EXPORT    = qw(foo);
        @EXPORT_OK = qw(bar);

        sub foo { print "foo\n" }
        sub bar { print "bar\n" }

        FILTER {
                # Your filtering code here
                __PACKAGE__->export_to_level(2,undef,@_);
        }


=head2 How it works

The Filter::Simple module exports into the package that calls C<FILTER>
(or C<use>s it directly) -- such as package "BANG" in the above example --
two automagically constructed
subroutines -- C<import> and C<unimport> -- which take care of all the
nasty details.

In addition, the generated C<import> subroutine passes its own argument
list to the filtering subroutine, so the BANG.pm filter could easily 
be made parametric:

        package BANG;
 
        use Filter::Simple;
        
        FILTER {
            my ($die_msg, $var_name) = @_;
            s/BANG\s+BANG/die '$die_msg' if \${$var_name}/g;
        };

        # and in some user code:

        use BANG "BOOM", "BAM";  # "BANG BANG" becomes: die 'BOOM' if $BAM


The specified filtering subroutine is called every time a C<use BANG> is
encountered, and passed all the source code following that call, up to
either the next C<no BANG;> (or whatever terminator you've set) or the
end of the source file, whichever occurs first. By default, any C<no
BANG;> call must appear by itself on a separate line, or it is ignored.


=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 COPYRIGHT

    Copyright (c) 2000-2001, Damian Conway. All Rights Reserved.
    This module is free software. It may be used, redistributed
        and/or modified under the same terms as Perl itself.
