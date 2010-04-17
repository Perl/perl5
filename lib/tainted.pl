warn "Legacy library @{[(caller(0))[6]]} will be removed from the Perl core distribution in the next major release. Please install it from the CPAN distribution Perl4::CoreLibs. It is being used at @{[(caller)[1]]}, line @{[(caller)[2]]}.\n";

# This legacy library is deprecated and will be removed in a future
# release of perl.
# This subroutine returns true if its argument is tainted, false otherwise.
#

sub tainted {
    local($@);
    eval { kill 0 * $_[0] };
    $@ =~ /^Insecure/;
}

1;
