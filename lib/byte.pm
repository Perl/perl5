package byte;

sub import {
    $^H |= 0x00000010;
}

sub unimport {
    $^H &= ~0x00000010;
}

sub AUTOLOAD {
    require "byte_heavy.pl";
    goto &$AUTOLOAD;
}

sub length ($);

1;
__END__

=head1 NAME

byte - Perl pragma to turn force treating strings as bytes not UNICODE

=head1 SYNOPSIS

    use byte;
    no byte;

=head1 DESCRIPTION


=cut
