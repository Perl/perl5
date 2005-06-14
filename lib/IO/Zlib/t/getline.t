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

print "1..19\n";

@text = (<<EOM, <<EOM, <<EOM, <<EOM) ;
this is line 1
EOM
the second line
EOM
the line after the previous line
EOM
the final line
EOM

$text = join("", @text) ;

ok(1, $file = IO::Zlib->new($name, "wb"));
ok(2, $file->print($text));
ok(3, $file->close());

ok(4, $file = IO::Zlib->new($name, "rb"));
ok(5, $file->getline() eq $text[0]);
ok(6, $file->getline() eq $text[1]);
ok(7, $file->getline() eq $text[2]);
ok(8, $file->getline() eq $text[3]);
ok(9, !defined($file->getline()));
ok(10, $file->close());

ok(11, $file = IO::Zlib->new($name, "rb"));
eval '$file->getlines';
ok(12, $@ =~ /^IO::Zlib::getlines: must be called in list context /);
ok(13, @lines = $file->getlines());
ok(14, @lines == @text);
ok(15, $lines[0] eq $text[0]);
ok(16, $lines[1] eq $text[1]);
ok(17, $lines[2] eq $text[2]);
ok(18, $lines[3] eq $text[3]);
ok(19, $file->close());

unlink($name);
