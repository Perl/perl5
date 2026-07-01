MODULE = XS::APItest::PtrTable  PACKAGE = XS::APItest::PtrTable PREFIX = ptr_table_

void
ptr_table_new(classname)
const char * classname
    PPCODE:
    PUSHs(sv_setref_pv(sv_newmortal(), classname, (void*)ptr_table_new()));

void
DESTROY(table)
XS::APItest::PtrTable table
    CODE:
    ptr_table_free(table);

void
ptr_table_store(table, from, to)
XS::APItest::PtrTable table
SVREF from
SVREF to
   CODE:
   ptr_table_store(table, from, to);

UV
ptr_table_fetch(table, from)
XS::APItest::PtrTable table
SVREF from
   CODE:
   RETVAL = PTR2UV(ptr_table_fetch(table, from));
   OUTPUT:
   RETVAL

void
ptr_table_split(table)
XS::APItest::PtrTable table
