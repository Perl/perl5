#!/usr/bin/perl -w

# t/xhtml20.t - test subclassing of Pod::Simple::XHTML

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    package MyXHTML;
    use base 'Pod::Simple::XHTML';

    sub handle_code {
	my($self, $code) = @_;
	$code = "[$code]";
	$self->SUPER::handle_code($code);
    }
}



my ($parser, $results);

initialize();
$parser->parse_string_document(<<'EOT');
=head1 Foo

This is C<$code> and so is:

  my $foo = 1;
EOT

like $results, qr/<code>\[\$code]<\/code>/;
like $results , qr/<pre><code>\[  my \$foo = 1;/;


sub initialize {
    $parser = MyXHTML->new;
    $parser->output_string( \$results );
    $results = '';
}
