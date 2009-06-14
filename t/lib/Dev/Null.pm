package Dev::Null;
# $Id$

sub TIEHANDLE { bless {} }
sub PRINT { 1 }

1;
