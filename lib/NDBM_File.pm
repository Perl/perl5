package NDBM_File;

require Exporter;
@ISA = (Exporter, DynamicLoader);
@EXPORT = split(' ', 'new fetch store delete firstkey nextkey error clearerr');

bootstrap NDBM_File;

1;
