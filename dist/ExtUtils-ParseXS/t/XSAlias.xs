MODULE = My PACKAGE = My

void
do(dbh)
   SV *dbh
ALIAS:
    dox = 1
    lox => dox
    pox = 1
    pox = 2
    docks = 1
    dachs => lox
CODE:
{
   int x;
   ++x;
}
