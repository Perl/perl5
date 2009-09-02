# This legacy library is deprecated and will be removed in a future
# release of perl.
# This subroutine returns true if its argument is tainted, false otherwise.
#
warn( "The 'tainted.pl' legacy library is deprecated and will be"
      . " removed in the next major release of perl. Please use the"
      . " Scalar::Util module ('tainted' function) instead." );

sub tainted {
    local($@);
    eval { kill 0 * $_[0] };
    $@ =~ /^Insecure/;
}

1;
