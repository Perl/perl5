#!perl
use v5.36;
use Pod::Simple::SimpleTree;

# POD NAVIGATION SUBROUTINES

sub header_pos ( $tree, $level, $title, $pos = 0 ) {
    while ( $pos < @$tree ) {
        next
          unless ref( $tree->[$pos] ) eq 'ARRAY'
          && $tree->[$pos][0] eq "head$level";
        return $pos if $tree->[$pos][2] eq $title;
    }
    continue { $pos++ }
    return;    # not found
}

sub next_header_pos ( $tree, $level, $pos = 0 ) {
    $pos++;
    while ( $pos < @$tree ) {
        next
          unless ref( $tree->[$pos] ) eq 'ARRAY';
        next unless $tree->[$pos][0] =~ /\Ahead([1-4])\z/;
        next if $1 > $level;
        last if $1 < $level;
        return $pos;
    }
    continue { $pos++ }
    return;    # not found
}

sub find_pos_in ( $master, $delta, $title ) {
    return
      map header_pos( $_, 1, $title ),
      $master, $delta;
}

# POD GENERATION SUBROUTINES

# NOTE: A Pod::Simple::SimpleTree "tree" is really just a list of
# directives.  The only parts that are really tree-like / recursive are
# the list directives, and pod formatting codes.

sub as_pod ( $tree ) {
    return $tree unless ref $tree;    # simple string
    state $handler = {
        Document => sub ( $name, $attr, @nodes ) {
            return map( as_pod($_), @nodes), "=cut\n";
        },
        Para => sub ( $name, $attr, @nodes ) {
            return map( as_pod($_), @nodes ), "\n\n";
        },
        Verbatim =>  sub ( $name, $attr, @nodes ) {
            return map( as_pod($_), @nodes ), "\n\n";
        },
        X => sub ( $name, $attr, @nodes ) {
            my ( $open, $spacer, $close ) =
              $attr->{'~bracket_count'}
              ? (
                '<' x $attr->{'~bracket_count'},
                ' ',
                '>' x $attr->{'~bracket_count'}
              )
              : ( '<', '', '>' );
            return "$name$open$spacer",
              map( as_pod($_), @nodes ),
              "$spacer$close";
        },
        L => sub ( $name, $attr, @nodes ) {
            return "$name<$attr->{raw}>";
        },
        # TODO: =begin / =for
        over => sub ( $name, $attr, @nodes ) {
            return "=over",
              $attr->{'~orig_content'} && " $attr->{'~orig_content'}", "\n\n",
              map( as_pod($_), @nodes ), "=back\n\n";
        },
        item => sub ( $name, $attr, @nodes ) {
            return "=item ",
              $attr->{'~orig_content'} ? "$attr->{'~orig_content'}\n\n" : '',
              map( as_pod($_), @nodes ), "\n\n";
        },
        '' => sub ( $name, $attr, @nodes ) {
            return "=$name", @nodes && ' ', map( as_pod($_), @nodes ), "\n\n";
        },
    };
    my ( $directive, $attr, @nodes ) = @$tree;
    my $name =
        exists $handler->{$directive} ? $directive
      : $directive =~ /\Aover-/       ? 'over'
      : $directive =~ /\Aitem-/       ? 'item'
      : length($directive) == 1       ? 'X'
      :                                 '';
    return join '', $handler->{$name}->( $directive, $attr, @nodes );
}

sub pod_excerpt ( $tree, $begin, $end ) {
    return as_pod( [ Document => {}, $tree->@[ $begin .. $end ] ] );
}

# CONTENT MANIPULATION SUBROUTINES

sub copy_section ( $master, $title, $delta ) {
    my ( $master_pos, $delta_pos ) = find_pos_in( $master, $delta, $title );

    # find the end of the section in the delta
    my $end_pos = next_header_pos( $delta, 1, $delta_pos ) - 1;

    # inject the whole section from the delta
    splice @$master, $master_pos + 1,
      0, $delta->@[ $delta_pos + 1 .. $end_pos ];
}

sub remove_identical ( $master, $title, $template ) {
    my ( $master_pos, $template_pos ) =
      find_pos_in( $master, $template, $title );

    # find the end of the section in both
    my $master_end_pos   = next_header_pos( $master,   1, $master_pos ) - 1;
    my $template_end_pos = next_header_pos( $template, 1, $template_pos ) - 1;

    # drop the section from the master if it's identical
    # to that in the template
    if ( pod_excerpt( $master, $master_pos, $master_end_pos ) eq
        pod_excerpt( $template, $template_pos, $template_end_pos ) )
    {
        splice @$master, $master_pos, $master_end_pos - $master_pos + 1;
    }
}

# map each section to an action
my %ACTION_FOR = (
    'NAME'                          => 'skip',
    'DESCRIPTION'                   => 'skip',
    'Notice'                        => 'copy',
    'Core Enhancements'             => 'copy',
    'Security'                      => 'copy',
    'Incompatible Changes'          => 'copy',
    'Deprecations'                  => 'copy',
    'Performance Enhancements'      => 'copy',
    'Modules and Pragmata'          => 'skip',
    'Documentation'                 => 'copy',
    'Diagnostics'                   => 'copy',
    'Utility Changes'               => 'copy',
    'Configuration and Compilation' => 'copy',
    'Testing'                       => 'copy',
    'Platform Support'              => 'copy',
    'Internal Changes'              => 'copy',
    'Selected Bug Fixes'            => 'copy',
    'Known Problems'                => 'copy',
    'Errata From Previous Releases' => 'copy',
    'Obituary'                      => 'copy',
    'Acknowledgements'              => 'skip',
    'Reporting Bugs'                => 'skip',
    'Give Thanks'                   => 'skip',
    'SEE ALSO'                      => 'skip',
);

# HELPER SUBROUTINES

# Note: the parser can only be used *once* per file
sub tree_for ($string) {
    my $parser = Pod::Simple::SimpleTree->new;
    $parser->keep_encoding_directive(1);
    $parser->preserve_whitespace(1);
    $parser->accept_targets('*');          # for & begin/end
    $parser->_output_is_for_JustPod(1);    # for ~bracket_count
    $parser->parse_string_document($string)->root;
}

sub loop_head1 ( $master, $tree, $file, $cb ) {
    for my $title (
        map $_->[2],                                  # grab the title
        grep ref eq 'ARRAY' && $_->[0] eq 'head1',    # of the =head1
        @$tree                                        # of the tree
      )
    {
        die "Unexpected section '=head1 $title' in $file\n"
          unless exists $ACTION_FOR{$title};
        next if $ACTION_FOR{$title} eq 'skip';
        $cb->( $master, $title, $tree );
    }
}

sub slurp ($file) {
    open my $fh, '<:utf8', $file
      or die "Can't open $file for reading: $!";
    return do { local $/; <$fh> };
}

# MAIN PROGRAM

sub main (@argv) {

    # compute the version
    my ($version) = `git describe` =~ /\Av(5\.[0-9]+)/g;
    die "$version does not look like a devel Perl version\n"
      unless $version =~ /\A5\.[0-9]{1,2}[13579]\z/;

    # the current, unfinished, delta will be used
    # as the master to produce the final document
    my $final_delta = 'pod/perldelta.pod';
    my $master      = tree_for( slurp($final_delta) );

    # loop over all the development deltas
    my $tag_devel = $version =~ tr/.//dr;
    for my $file_tree (
        map [ $_->[0], tree_for( slurp( $_->[0] ) ) ],
        sort { $b->[1] <=> $a->[1] }
        map [ $_, m{pod/perl$tag_devel([0-9]+)delta\.pod}g ],
        glob "pod/perl$tag_devel*delta.pod"
      )
    {
        my ( $file, $delta ) = @$file_tree;
        loop_head1(
            $master, $delta, $file,
            sub ( $master, $title, $delta ) {
                copy_section( $master, $title, $delta );
            }
        );
    }

    # find all sections in the template identical to those
    # in the master and remove them (from the master)
    my $template_file = 'Porting/perldelta_template.pod';
    my $template      = tree_for( slurp($template_file) );
    loop_head1(
        $master, $template, $template_file,
        sub ( $master, $title, $template ) {
            remove_identical( $master, $title, $template );
        }
    );

    # save the result
    open my $fh, '>:utf8', $final_delta
      or die "Can't open $final_delta for writing: $!";
    print $fh as_pod($master);

    return 0;
}

# make it easier to test
exit main( @ARGV ) unless caller;
