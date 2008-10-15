package TieOut;
# $Id: /mirror/googlecode/test-more-trunk/t/lib/TieOut.pm 67132 2008-10-01T01:11:04.501643Z schwern  $

sub TIEHANDLE {
    my $scalar = '';
    bless( \$scalar, $_[0] );
}

sub PRINT {
    my $self = shift;
    $$self .= join( '', @_ );
}

sub PRINTF {
    my $self = shift;
    my $fmt  = shift;
    $$self .= sprintf $fmt, @_;
}

sub FILENO { }

sub read {
    my $self = shift;
    my $data = $$self;
    $$self = '';
    return $data;
}

1;
