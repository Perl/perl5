# Add explicit link to deb.o to pick up _Perl_deb symbol which is not
# mentioned in perl56.lib in non DEBUGGING builds
# Taken lock, stock, and barrel from hints/aix.pl
#  -- BKS, 11-11-2000

if ($^O =~ /MSWin32/) {
    $self->{OBJECT} .= ' ../../deb$(OBJ_EXT)';
}

# Add explicit link to deb.o to pick up _Perl_deb symbol which is not
# mentioned in perl56.lib in non DEBUGGING builds
# Taken lock, stock, and barrel from hints/aix.pl
#  -- BKS, 11-11-2000

if ($^O =~ /MSWin32/) {
    $self->{OBJECT} .= ' ../../deb$(OBJ_EXT)';
}

