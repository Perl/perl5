package integer;

sub import {
    $^H |= 1;
}

sub unimport {
    $^H &= ~1;
}

1;
