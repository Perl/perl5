use re Debug=>qw(DUMP EXECUTE TRIEC TEST);
require '../../t/charset_tools.pl';
my @tests=(
  XY     =>  'X(A|[B]Q||C|D)Y' ,
  foobar =>  '[f][o][o][b][a][r]',
  x  =>  '.[XY].',
  'ABCD' => '(?:ABCP|ABCG|ABCE|ABCB|ABCA|ABCD)',
  'D:\\dev/perl/ver/28321_/perl.exe'=>
  '/(\\.COM|\\.EXE|\\.BAT|\\.CMD|\\.VBS|\\.VBE|\\.JS|\\.JSE|\\.WSF|\\.WSH|\\.pyo|\\.pyc|\\.pyw|\\.py)$/i',
  'q'=>'[q]',
  "path_sep:\t8490" => '^(\\S{1,9}):\\s*(\\d+)$',
  '' => '(?(DEFINE)(?<foo>foo))(?(DEFINE)(?<bar>(?&foo)bar))(?(DEFINE)(?<baz>(?&bar)baz))(?(DEFINE)(?<bop>(?&baz)bop))',
  'xfoo_bar_bazfoo_bar_baz' => '/x(?:foo_bar_baz|bloop_er)foo_bar_baz/i',
  'xfoo_bar_bazfoo_bar_baz' => 'x(?:foo_bar_baz|bloop_er)foo_bar_baz',
  'a_word' => '/foo|bar|a_word|_qux/i',
  '_' => '/_|#/i',
  uni_to_native("\x{00DF}") . '_' => '/(?a:[\x{1E9E}_]_)/i',
  '_a' => '/_a|_b/i',
);
while (@tests) {
    my ($str,$pat)=splice @tests,0,2;
    warn "\n";
    $pat="/$pat/" if substr($pat,0,1) ne '/';
    # string eval to get the free regex message in the right place.
    eval qq[
        warn "$str"=~$pat ? "%MATCHED%" : "%FAILED%","\n";
    ];
    die $@ if $@;
}
