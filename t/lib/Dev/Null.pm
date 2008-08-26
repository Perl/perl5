package Dev::Null;

sub TIEHANDLE { bless {} }
sub PRINT { 1 }

1;
