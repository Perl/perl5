#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(. ../lib);
    require "test.pl";
    skip_all_without_dynamic_extension('B');
    $^P |= 0x100;
}

use B::Deparse;
my $bd = new B::Deparse;

my %unsupported = map +($_=>1), qw (CORE and cmp dump eq ge gt le
                                    getprotobynumber lt ne not or x xor);
my %args_for = (
  dbmopen  => '%1,$2,$3',
  dbmclose => '%1',
);

use File::Spec::Functions;
my $keywords_file = catfile(updir,'regen','keywords.pl');
open my $kh, $keywords_file
   or die "$0 cannot open $keywords_file: $!";
while(<$kh>) {
  if (m?__END__?..${\0} and /^[+-]/) {
    chomp(my $word = $');
    if($& eq '+' || $unsupported{$word}) {
      $tests ++;
      ok !defined &{\&{"CORE::$word"}}, "no CORE::$word";
    }
    else {
      $tests += 3;

      my $proto = prototype "CORE::$word";
      *{"my$word"} = \&{"CORE::$word"};
      is prototype \&{"my$word"}, $proto, "prototype of &CORE::$word";

      CORE::state $protochar = qr/\G([^\\]|\\(?:[^[]|\[[^]]+\]))/;
      my $numargs =
            () = $proto =~ s/;.*//r =~ /$protochar/g;
      my $code =
         "#line 1 This-line-makes-__FILE__-easier-to-test.
          sub { () = (my$word("
             . ($args_for{$word} || join ",", map "\$$_", 1..$numargs)
       . "))}";
      my $core = $bd->coderef2text(eval $code =~ s/my/CORE::/r or die);
      my $my   = $bd->coderef2text(eval $code or die);
      is $my, $core, "inlinability of CORE::$word with parens";

      $code =
         "#line 1 This-line-makes-__FILE__-easier-to-test.
          sub { () = (my$word "
             . ($args_for{$word} || join ",", map "\$$_", 1..$numargs)
       . ")}";
      $core = $bd->coderef2text(eval $code =~ s/my/CORE::/r or die);
      $my   = $bd->coderef2text(eval $code or die);
      is $my, $core, "inlinability of CORE::$word without parens";

      next if ($proto =~ /\@/);
      # These ops currently accept any number of args, despite their
      # prototypes, if they have any:
      next if $word =~ /^(?:chom?p|exec|keys|each|read(?:lin|pip)e|reset
                           |system|values|l?stat)/x;

      $tests ++;
      $code =
         "sub { () = (my$word("
             . (
                $args_for{$word}
                 ? $args_for{$word}.',$7'
                 : join ",", map "\$$_", 1..$numargs+5+(
                      $proto =~ /;/
                       ? () = $' =~ /$protochar/g
                       : 0
                   )
               )
       . "))}";
      eval $code;
      like $@, qr/^Too many arguments for $word/,
          "inlined CORE::$word with too many args"
        or warn $code;

    }
  }
}

is curr_test, $tests+1, 'right number of tests';
done_testing;

CORE::__END__
