$* = 1;
undef $/;
$input = <>;
@records = split(/^--\n/, $input);
print @records + 0, "\n";
print $records[0], "\n";
