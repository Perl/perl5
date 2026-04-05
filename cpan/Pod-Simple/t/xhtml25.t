use strict;
use warnings;
use Test::More;

BEGIN {
    package MyXHTML;
    use base 'Pod::Simple::XHTML';

    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->html_header('');
        $self->html_footer('');
        $self->index(1);
        $self->anchor_items(1);
        return $self;
    }

    sub parse_to_string {
        my $self = shift;
        my $pod = shift;
        my $output = '';
        $self->output_string( \$output );
        $self->parse_string_document($pod);
        return $output;
    }

    sub idify {
        my ($self, $t, $not_unique) = @_;
        for ($t) {
            $t =~ s/\A\s+//;
            $t =~ s/\s+\z//;
            $t =~ s/[\s-]+/-/g;
        }
        return $t if $not_unique;
        my $i = '';
        $i++ while $self->{ids}{"$t$i"}++;
        return "$t$i";
    }
}

local $Pod::Simple::XHTML::HAS_HTML_ENTITIES = 0;

my @tests = (
    # Pod                   id                        link (url encoded)
    [ 'Foo',                'Foo',                    'Foo'                       ],
    [ '$@',                 '$@',                     '%24%40'                    ],
    [ 'With C<Formatting>', 'With-Formatting',        'With-Formatting'           ],
    [ '$obj->method($foo)', '$obj->method($foo)',     '%24obj-%3Emethod(%24foo)'  ],
    [ 'bjørn',              'bjørn',                  'bj%C3%B8rn',  'ISO-8859-1' ],
    [ 'bjørn',              'bjørn',                  'bj%C3%B8rn',       'UTF-8' ],
    [ '🌐',                 '🌐',                     '%F0%9F%8C%90',     'UTF-8' ],
);

plan tests => 5 * scalar @tests;

my $parser = MyXHTML->new;

for my $names (@tests) {
    my ($heading, $id, $link, $encoding) = @$names;

    my $heading_name = "for '$heading'" . ($encoding ? " ($encoding)" : '');

    my $encoding_dir = '';
    if ($encoding) {
        if (!Pod::Simple::XHTML::HAVE_UTF8_ENCODE) {
            skip 'no encoding support', 5;
        }
        elsif ($encoding eq 'ISO-8859-1') {
            utf8::decode($heading);
            utf8::downgrade($heading);
        }
        elsif ($encoding eq 'UTF-8') {
            # source is already UTF-8 encoded
        }
        else {
            die "this test only supports ISO-8859-1 and UTF-8";
        }

        utf8::decode($id);

        $encoding_dir = "=encoding $encoding\n\n";
    }

    is $parser->encode_url($id), $link,
        "assert correct encoding of url fragment $heading_name";

    my $html_id = $parser->encode_entities($id);

    {
        my $pod = <<"EOT";
    =head1 $heading

    L<< /$heading >>

EOT
        $pod =~ s/^    //gm;

        my $result = MyXHTML->new->parse_to_string("$encoding_dir$pod");

        like $result, qr{<h1 id="\Q$html_id\E">},
            "heading id generated correctly $heading_name";
        like $result, qr{<li><a href="\#\Q$link\E">},
            "index link generated correctly $heading_name";
        like $result, qr{<p><a href="\#\Q$link\E">},
            "L<> link generated correctly $heading_name";
    }
    {
        my $pod = <<"EOT";
    =over 4

    =item $heading

    =back

EOT
        $pod =~ s/^    //gm;

        my $result = MyXHTML->new->parse_to_string("$encoding_dir$pod");
        like $result, qr{<dt id="\Q$html_id\E">},
            "item id generated correctly for $heading_name";
    }
}
