package byte;

sub length ($) {
    BEGIN { byte::import() }
    return CORE::length($_[0]);
}

1;
