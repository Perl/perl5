#!./perl

# $RCSfile$    
$|  = 1;
$^W = 1;

print "1..32\n";

# my $file tests

{
unlink("afile") if -f "afile";     
print "$!\nnot " unless open(my $f,"+>afile");
print "ok 1\n";
binmode $f;
print "not " unless -f "afile";     
print "ok 2\n";
print "not " unless print $f "SomeData\n";
print "ok 3\n";
print "not " unless tell($f) == 9;
print "ok 4\n";
print "not " unless seek($f,0,0);
print "ok 5\n";
$b = <$f>;
print "not " unless $b eq "SomeData\n";
print "ok 6\n";
print "not " unless -f $f;     
print "ok 7\n";
eval  { die "Message" };   
# warn $@;
print "not " unless $@ =~ /<\$f> line 1/;
print "ok 8\n";
print "not " unless close($f);
print "ok 9\n";
unlink("afile");     
}
{
print "# \$!='$!'\nnot " unless open(my $f,'>', 'afile');
print "ok 10\n";
print $f "a row\n";
print "not " unless close($f);
print "ok 11\n";
print "not " unless -s 'afile' < 10;
print "ok 12\n";
}
{
print "# \$!='$!'\nnot " unless open(my $f,'>>', 'afile');
print "ok 13\n";
print $f "a row\n";
print "not " unless close($f);
print "ok 14\n";
print "not " unless -s 'afile' > 10;
print "ok 15\n";
}
{
print "# \$!='$!'\nnot " unless open(my $f, '<', 'afile');
print "ok 16\n";
@rows = <$f>;
print "not " unless @rows == 2;
print "ok 17\n";
print "not " unless close($f);
print "ok 18\n";
}
{
print "not " unless -s 'afile' < 20;
print "ok 19\n";
print "# \$!='$!'\nnot " unless open(my $f, '+<', 'afile');
print "ok 20\n";
@rows = <$f>;
print "not " unless @rows == 2;
print "ok 21\n";
seek $f, 0, 1;
print $f "yet another row\n";
print "not " unless close($f);
print "ok 22\n";
print "not " unless -s 'afile' > 20;
print "ok 23\n";

unlink("afile");     
}
{
print "# \$!='$!'\nnot " unless open(my $f, '-|', <<'EOC');
perl -e "print qq(a row\n); print qq(another row\n)"
EOC
print "ok 24\n";
@rows = <$f>;
print "not " unless @rows == 2;
print "ok 25\n";
print "not " unless close($f);
print "ok 26\n";
}
{
print "# \$!='$!'\nnot " unless open(my $f, '|-', <<'EOC');
perl -pe "s/^not //"
EOC
print "ok 27\n";
@rows = <$f>;
print $f "not ok 28\n";
print $f "not ok 29\n";
print "#\nnot " unless close($f);
sleep 1;
print "ok 30\n";
}

eval <<'EOE' and print "not ";
open my $f, '<&', 'afile';
1;
EOE
print "ok 31\n";
$@ =~ /Unknown open\(\) mode \'<&\'/ or print "not ";
print "ok 32\n";
