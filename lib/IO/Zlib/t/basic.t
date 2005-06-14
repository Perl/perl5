use IO::Zlib;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}

$name="test.gz";

print "1..15\n";

$hello = <<EOM ;
hello world
this is a test
EOM

ok(1, $file = IO::Zlib->new($name, "wb"));
ok(2, $file->print($hello));
ok(3, $file->opened());
ok(4, $file->close());
ok(5, !$file->opened());

ok(6, $file = IO::Zlib->new());
ok(7, $file->open($name, "rb"));
ok(8, !$file->eof());
ok(9, $file->read($uncomp, 1024) == length($hello));
ok(10, $file->eof());
ok(11, $file->opened());
ok(12, $file->close());
ok(13, !$file->opened());

unlink($name);

ok(14, $hello eq $uncomp);

ok(15, !defined(IO::Zlib->new($name, "rb")));
