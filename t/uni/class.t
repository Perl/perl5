BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib .);
    require "test.pl";
}

plan tests => 4;

sub MyUniClass {
  <<END;
0030	004F
END
}

sub Other::Class {
  <<END;
0040	005F
END
}

sub A::B::Intersection {
  <<END;
+main::MyUniClass
&Other::Class
END
}


my $str = join "", map chr($_), 0x20 .. 0x6F;

# make sure it finds built-in class
is(($str =~ /(\p{Letter}+)/)[0], 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

# make sure it finds user-defined class
is(($str =~ /(\p{MyUniClass}+)/)[0], '0123456789:;<=>?@ABCDEFGHIJKLMNO');

# make sure it finds class in other package
is(($str =~ /(\p{Other::Class}+)/)[0], '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_');

# make sure it finds class in other OTHER package
is(($str =~ /(\p{A::B::Intersection}+)/)[0], '@ABCDEFGHIJKLMNO');
