package SDBM_File;

require Exporter;
@ISA = (Exporter, DynamicLoader);
@EXPORT = split(' ', 'new fetch store delete firstkey nextkey error clearerr');

bootstrap SDBM_File;

1;
