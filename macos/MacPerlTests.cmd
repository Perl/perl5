# Test suite for MacPerl
# pudge@pobox.com

echo "# `Date -t` ----- Begin MacPerl tests."
echo ""

perl -le 'symlink "::macos:perl", ":perl" unless -e ":perl"'

# set up environment
set -e MACPERL ""
set -e PERL5LIB ""
set -e PERL_CORE 1

# create/open file for dumping tests to
perl -e 'open F, ">::macos:MacPerlTests.out"'
open ::macos:MacPerlTests.out

echo ":perl -I::lib    :base:cond.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:cond.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:if.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:if.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:lex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:lex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:num.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:num.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:pat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:pat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :base:term.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :base:term.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :cmd:elsif.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:elsif.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :cmd:for.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:for.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :cmd:mod.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:mod.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :cmd:subval.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:subval.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :cmd:switch.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:switch.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :cmd:while.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :cmd:while.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :comp:bproto.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:bproto.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:cmdopt.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:cmdopt.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:colon.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:colon.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:cpp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:cpp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:decl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:decl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:hints.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:hints.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:multiline.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:multiline.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:our.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:our.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:package.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:package.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:parser.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:parser.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:proto.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:proto.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:redef.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:redef.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:require.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:require.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:script.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:script.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:term.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:term.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :comp:use.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :comp:use.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :io:argv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:argv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:binmode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:binmode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:crlf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:crlf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:dup.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:dup.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:fflush.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:fflush.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:fs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:fs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:inplace.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:inplace.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:iprefix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:iprefix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:nargv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:nargv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:open.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:open.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:openpid.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:openpid.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:pipe.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:pipe.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:print.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:print.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:read.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:read.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:tell.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:tell.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :io:utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :io:utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :japh:abigail.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :japh:abigail.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :lib:1_compile.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :lib:1_compile.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :lib:commonsense.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :lib:commonsense.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :op:64bitint.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:64bitint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:alarm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:alarm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:anonsub.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:anonsub.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:append.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:append.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:args.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:args.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:arith.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:arith.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:array.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:array.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:assignwarn.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:assignwarn.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:attrs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:attrs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:auto.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:auto.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:avhv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:avhv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:bless.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:bless.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:bop.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:bop.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:caller.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:caller.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:chars.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:chars.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:chdir.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:chdir.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:chop.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:chop.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:closure.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:closure.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:cmp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:cmp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:concat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:concat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:cond.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:cond.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:context.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:context.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:crypt.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:crypt.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:defins.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:defins.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:delete.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:delete.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:die.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:die.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:die_exit.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:die_exit.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:do.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:do.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:each.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:each.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:eval.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:eval.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:exec.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:exec.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:exists_sub.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:exists_sub.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:exp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:exp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:fh.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:fh.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:filetest.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:filetest.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:flip.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:flip.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:fork.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:fork.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:getpid.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:getpid.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:glob.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:glob.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:gmagic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:gmagic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:goto.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:goto.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:goto_xs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:goto_xs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:grent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:grent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:grep.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:grep.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:groups.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:groups.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:gv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:gv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:hashassign.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:hashassign.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:hashwarn.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:hashwarn.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:inc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:inc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:inccode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:inccode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:index.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:index.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:int.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:int.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:join.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:join.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:lc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:lc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:lc_user.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:lc_user.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:length.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:length.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:lex_assign.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:lex_assign.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T :op:lfs.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T :op:lfs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:list.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:list.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:local.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:local.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:localref.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:localref.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:loopctl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:loopctl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:lop.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:lop.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:magic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:magic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:method.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:method.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:mkdir.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:mkdir.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:my.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:my.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:my_stash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:my_stash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:nothr5005.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:nothr5005.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:numconvert.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:numconvert.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:oct.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:oct.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:or.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:or.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:ord.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:ord.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:override.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:override.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:pack.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:pack.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:pat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:pat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:pos.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:pos.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:pow.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:pow.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:push.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:push.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:pwent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:pwent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:qq.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:qq.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:quotemeta.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:quotemeta.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:rand.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:rand.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:range.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:range.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:read.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:read.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:readdir.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:readdir.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:readline.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:readline.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:recurse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:recurse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:ref.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:ref.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:regexp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:regexp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:regexp_noamp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:regexp_noamp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:regmesg.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:regmesg.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:repeat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:repeat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:reverse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:reverse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:runlevel.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:runlevel.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:sleep.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:sleep.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:sort.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:sort.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:splice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:splice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:split.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:split.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:sprintf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:sprintf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:srand.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:srand.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:stash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:stash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:stat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:stat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:study.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:study.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t :op:sub_lval.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t :op:sub_lval.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T :op:subst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T :op:subst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:subst_amp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:subst_amp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:subst_wamp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:subst_wamp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:substr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:substr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:sysio.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:sysio.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T :op:taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T :op:taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:tie.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:tie.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:tiearray.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:tiearray.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:tiehandle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:tiehandle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:time.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:time.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t :op:tr.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t :op:tr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:undef.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:undef.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:universal.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:universal.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:unshift.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:unshift.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:utf8decode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:utf8decode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:utfhash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:utfhash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:vec.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:vec.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:ver.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:ver.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:wantarray.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:wantarray.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :op:write.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :op:write.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :pod:emptycmd.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:emptycmd.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:find.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:find.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:for.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:for.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:headings.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:headings.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:include.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:include.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:included.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:included.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:lref.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:lref.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:multiline_items.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:multiline_items.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:nested_items.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:nested_items.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:nested_seqs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:nested_seqs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:oneline_cmds.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:oneline_cmds.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:plainer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:plainer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:pod2usage.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:pod2usage.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:poderrs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:poderrs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:podselect.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:podselect.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :pod:special_seqs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :pod:special_seqs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :run:exit.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:exit.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:fresh_perl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:fresh_perl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:noswitch.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:noswitch.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:runenv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:runenv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switcha.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switcha.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switches.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switches.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchC.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchC.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchF.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchF.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchI.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchI.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchn.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchn.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchPx.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchPx.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t :run:switcht.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t :run:switcht.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :run:switchx.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :run:switchx.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :uni:fold.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:fold.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:lower.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:lower.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:sprintf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:sprintf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:title.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:title.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:tr_7jis.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:tr_7jis.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:tr_eucjp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:tr_eucjp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:tr_sjis.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:tr_sjis.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:tr_utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:tr_utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:upper.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:upper.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :uni:write.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :uni:write.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :win32:longpath.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :win32:longpath.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    :win32:system.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :win32:system.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    :x2p:s2p.t" >> ::macos:MacPerlTests.out
:perl -I::lib    :x2p:s2p.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::ext:attrs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:attrs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:B:t:asmdata.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:B:t:asmdata.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:assembler.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:assembler.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:b.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:b.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:B:t:bblock.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:B:t:bblock.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:concise.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:concise.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:debug.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:debug.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:deparse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:deparse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:lint.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:lint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:o.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:o.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:showlex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:showlex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:stash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:stash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:terse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:terse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:B:t:xref.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:B:t:xref.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Cwd:t:cwd.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Cwd:t:cwd.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:Cwd:t:taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:Cwd:t:taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Data:Dumper:t:dumper.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Data:Dumper:t:dumper.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Data:Dumper:t:overload.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Data:Dumper:t:overload.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:DB_File:t:db-btree.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:DB_File:t:db-btree.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:DB_File:t:db-hash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:DB_File:t:db-hash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:DB_File:t:db-recno.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:DB_File:t:db-recno.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Devel:DProf:DProf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Devel:DProf:DProf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:Devel:Peek:Peek.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:Devel:Peek:Peek.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Devel:PPPort:t:test.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Devel:PPPort:t:test.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Digest:MD5:t:align.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Digest:MD5:t:align.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::ext:Digest:MD5:t:badfile.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::ext:Digest:MD5:t:badfile.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Digest:MD5:t:files.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Digest:MD5:t:files.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Digest:MD5:t:md5-aaa.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Digest:MD5:t:md5-aaa.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Digest:MD5:t:utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Digest:MD5:t:utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:Aliases.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:Aliases.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:at-cn.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:at-cn.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:at-tw.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:at-tw.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:CJKT.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:CJKT.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:Encode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:Encode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:Encoder.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:Encoder.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:enc_data.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:enc_data.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:enc_eucjp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:enc_eucjp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:enc_module.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:enc_module.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:enc_utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:enc_utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:encoding.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:encoding.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:fallback.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:fallback.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:grow.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:grow.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:guess.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:guess.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:jperl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:jperl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:mime-header.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:mime-header.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:perlio.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:perlio.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Encode:t:Unicode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Encode:t:Unicode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Errno:Errno.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Errno:Errno.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Fcntl:t:fcntl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Fcntl:t:fcntl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:Fcntl:t:syslfs.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:Fcntl:t:syslfs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:File:Glob:t:basic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:File:Glob:t:basic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:File:Glob:t:case.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:File:Glob:t:case.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:File:Glob:t:global.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:File:Glob:t:global.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:File:Glob:t:taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:File:Glob:t:taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Filter:t:call.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Filter:t:call.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:GDBM_File:gdbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:GDBM_File:gdbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:I18N:Langinfo:Langinfo.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:I18N:Langinfo:Langinfo.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_const.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_const.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_dir.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_dir.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_dup.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_dup.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_linenum.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_linenum.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_multihomed.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_multihomed.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_pipe.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_pipe.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_poll.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_poll.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_sel.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_sel.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_sock.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_sock.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:IO:lib:IO:t:io_taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:IO:lib:IO:t:io_taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_tell.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_tell.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_udp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_udp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_unix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_unix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:io_xs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:io_xs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IO:lib:IO:t:IO.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IO:lib:IO:t:IO.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IPC:SysV:ipcsysv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IPC:SysV:ipcsysv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IPC:SysV:t:msg.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IPC:SysV:t:msg.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:IPC:SysV:t:sem.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:IPC:SysV:t:sem.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:blessed.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:blessed.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:dualvar.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:dualvar.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:first.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:first.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:isvstring.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:isvstring.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:lln.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:lln.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:max.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:max.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:maxstr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:maxstr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:min.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:min.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:minstr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:minstr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:openhan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:openhan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:proto.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:proto.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:readonly.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:readonly.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:reduce.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:reduce.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:refaddr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:reftype.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:refaddr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:reftype.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:shuffle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:shuffle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:sum.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:sum.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:List:Util:t:tainted.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:List:Util:t:tainted.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:List:Util:t:weak.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:List:Util:t:weak.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:MIME:Base64:t:base64.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:MIME:Base64:t:base64.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:MIME:Base64:t:quoted-print.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:MIME:Base64:t:quoted-print.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:MIME:Base64:t:unicode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:MIME:Base64:t:unicode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:NDBM_File:ndbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:NDBM_File:ndbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:ODBM_File:odbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:ODBM_File:odbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Opcode:Opcode.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Opcode:Opcode.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Opcode:ops.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Opcode:ops.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:PerlIO.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:PerlIO.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:t:encoding.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:t:encoding.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:t:fail.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:t:fail.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:t:fallback.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:t:fallback.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:t:scalar.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:t:scalar.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:PerlIO:t:via.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:PerlIO:t:via.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:POSIX:t:is.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:POSIX:t:is.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:POSIX:t:posix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:POSIX:t:posix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:POSIX:t:sigaction.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:POSIX:t:sigaction.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::ext:POSIX:t:taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::ext:POSIX:t:taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:POSIX:t:waitpid.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:POSIX:t:waitpid.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:re:re.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:re:re.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Safe:safe1.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Safe:safe1.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Safe:safe2.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Safe:safe2.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Safe:safe3.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Safe:safe3.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:SDBM_File:sdbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:SDBM_File:sdbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Socket:Socket.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Socket:Socket.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Socket:socketpair.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Socket:socketpair.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:blessed.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:blessed.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:canonical.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:canonical.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:code.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:code.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:compat06.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:compat06.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:croak.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:croak.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:dclone.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:dclone.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:downgrade.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:downgrade.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:forgive.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:forgive.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:freeze.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:freeze.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:integer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:integer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:interwork56.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:interwork56.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:lock.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:lock.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:malice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:malice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:overload.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:overload.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:recurse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:recurse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:restrict.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:restrict.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:retrieve.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:retrieve.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:store.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:store.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:tied.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:tied.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:tied_hook.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:tied_hook.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:tied_items.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:tied_items.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Storable:t:utf8hash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Storable:t:utf8hash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Sys:Hostname:Hostname.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Sys:Hostname:Hostname.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Sys:Syslog:syslog.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Sys:Syslog:syslog.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Thread:thr5005.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Thread:thr5005.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::ext:threads:shared:t:0nothread.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::ext:threads:shared:t:0nothread.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:av_refs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:av_refs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:av_simple.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:av_simple.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:cond.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:cond.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib -T ::ext:threads:shared:t:disabled.t" >> ::macos:MacPerlTests.out
#:perl -I::lib -T ::ext:threads:shared:t:disabled.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::ext:threads:shared:t:hv_refs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:hv_refs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:hv_simple.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:hv_simple.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:no_share.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:no_share.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:shared_attr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:shared_attr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:sv_refs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:sv_refs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:shared:t:sv_simple.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:shared:t:sv_simple.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:basic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:basic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:end.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:end.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:join.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:join.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:libc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:libc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:list.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:list.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:problems.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:problems.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:stress_cv.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:stress_cv.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:stress_re.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:stress_re.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:stress_string.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:stress_string.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:threads:t:thread.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:threads:t:thread.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:Time:HiRes:HiRes.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:Time:HiRes:HiRes.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::ext:Unicode:Normalize:t:func.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::ext:Unicode:Normalize:t:func.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::ext:Unicode:Normalize:t:norm.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::ext:Unicode:Normalize:t:norm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::ext:Unicode:Normalize:t:test.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::ext:Unicode:Normalize:t:test.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:XS:APItest:t:printf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:XS:APItest:t:printf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::ext:XS:Typemap:Typemap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::ext:XS:Typemap:Typemap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:AnyDBM_File.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:AnyDBM_File.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Attribute:Handlers:t:multi.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Attribute:Handlers:t:multi.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:AutoLoader.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:AutoLoader.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:AutoSplit.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:AutoSplit.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:autouse.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:autouse.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Benchmark.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Benchmark.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bigfloatpl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bigfloatpl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bigintpl.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bigintpl.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:bigint.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:bigint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:bignum.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:bignum.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:bigrat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:bigrat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:biinfnan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:biinfnan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:bn_lite.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:bn_lite.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:bninfnan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:bninfnan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:br_lite.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:br_lite.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:brinfnan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:brinfnan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:option_a.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:option_a.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:option_l.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:option_l.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bignum:t:option_p.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bignum:t:option_p.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:blib.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:blib.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:bytes.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:bytes.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Carp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Carp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:apache.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:apache.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:CGI:t:carp.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:CGI:t:carp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:cookie.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:cookie.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:fast.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:fast.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:form.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:form.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:function.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:function.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:html.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:html.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:pretty.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:pretty.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:CGI:t:push.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:CGI:t:push.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:request.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:request.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:switch.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:switch.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CGI:t:util.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CGI:t:util.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:charnames.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:charnames.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Class:ISA:test.pl" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Class:ISA:test.pl >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Class:Struct.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Class:Struct.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Config.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Config.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:constant.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:constant.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CPAN:t:loadme.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CPAN:t:loadme.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CPAN:t:mirroredby.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CPAN:t:mirroredby.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:CPAN:t:Nox.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:CPAN:t:Nox.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:CPAN:t:vcmp.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:CPAN:t:vcmp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:DB.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:DB.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Devel:SelfStubber.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Devel:SelfStubber.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:diagnostics.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:diagnostics.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Digest.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Digest.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:DirHandle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:DirHandle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Dumpvalue.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Dumpvalue.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:English.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:English.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Env:t:array.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Env:t:array.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Env:t:env.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Env:t:env.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Exporter.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Exporter.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:ExtUtils:t:00setup_dummy.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:00setup_dummy.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:backwards.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:backwards.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib    ::lib:ExtUtils:t:basic.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:basic.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:ExtUtils:t:Command.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:Command.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib    ::lib:ExtUtils:t:Constant.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:Constant.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:Embed.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:Embed.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:hints.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:hints.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:INST.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:INST.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:Installed.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:Installed.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:INST_PREFIX.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:INST_PREFIX.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:Manifest.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:Manifest.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:ExtUtils:t:Mkbootstrap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:Mkbootstrap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_BeOS.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_BeOS.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_Cygwin.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_Cygwin.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_NW5.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_NW5.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_OS2.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_OS2.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_Unix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_Unix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_VMS.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_VMS.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:MM_Win32.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:MM_Win32.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:Packlist.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:Packlist.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ExtUtils:t:prefixify.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ExtUtils:t:prefixify.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib -T ::lib:ExtUtils:t:problems.t" >> ::macos:MacPerlTests.out
#:perl -I::lib -T ::lib:ExtUtils:t:problems.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib -T ::lib:ExtUtils:t:testlib.t" >> ::macos:MacPerlTests.out
#:perl -I::lib -T ::lib:ExtUtils:t:testlib.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:VERSION_FROM.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:VERSION_FROM.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:writemakefile_args.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:writemakefile_args.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:ExtUtils:t:zz_cleanup_dummy.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:ExtUtils:t:zz_cleanup_dummy.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:Fatal.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Fatal.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:fields.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:fields.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:File:Basename.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:File:Basename.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:CheckTree.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:CheckTree.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Compare.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Compare.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Copy.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Copy.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:DosGlob.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:DosGlob.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Find:t:find.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Find:t:find.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:File:Find:t:taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:File:Find:t:taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:File:Path.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:File:Path.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Spec:t:Functions.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Spec:t:Functions.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Spec:t:rel2abs2rel.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Spec:t:rel2abs2rel.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Spec:t:Spec.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Spec:t:Spec.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:stat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:stat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Temp:t:mktemp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Temp:t:mktemp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Temp:t:posix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Temp:t:posix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Temp:t:security.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Temp:t:security.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:File:Temp:t:tempfile.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:File:Temp:t:tempfile.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:FileCache.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:FileCache.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:FileHandle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:FileHandle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:filetest.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:filetest.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Filter:Simple:t:data.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Filter:Simple:t:data.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Filter:Simple:t:export.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Filter:Simple:t:export.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Filter:Simple:t:filter.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Filter:Simple:t:filter.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Filter:Simple:t:filter_only.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Filter:Simple:t:filter_only.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Filter:Simple:t:import.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Filter:Simple:t:import.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:FindBin.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:FindBin.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Getopt:Long:t:gol-basic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Getopt:Long:t:gol-basic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Getopt:Long:t:gol-compat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Getopt:Long:t:gol-compat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Getopt:Long:t:gol-linkage.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Getopt:Long:t:gol-linkage.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Getopt:Long:t:gol-oo.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Getopt:Long:t:gol-oo.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Getopt:Std.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Getopt:Std.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib    ::lib:h2ph.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:h2ph.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:h2xs.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:h2xs.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib -T ::lib:Hash:Util.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Hash:Util.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:I18N:Collate.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:I18N:Collate.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:I18N:LangTags:test.pl" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:I18N:LangTags:test.pl >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_const.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_const.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_dir.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_dir.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_dup.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_dup.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_linenum.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_linenum.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_multihomed.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_multihomed.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_pipe.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_pipe.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_poll.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_poll.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_sel.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_sel.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_sock.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_sock.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:IO:t:io_taint.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:IO:t:io_taint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_tell.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_tell.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_udp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_udp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_unix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_unix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:io_xs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:io_xs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IO:t:IO.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IO:t:IO.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:if.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:if.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:integer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:integer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Internals.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Internals.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IPC:Open2.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IPC:Open2.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IPC:Open3.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IPC:Open3.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:IPC:SysV.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:IPC:SysV.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:less.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:less.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:lib.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:lib.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:locale.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:locale.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:all.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:all.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:constants.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:constants.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:country.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:country.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:currency.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:currency.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:languages.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:languages.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:rename.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:rename.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:script.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:script.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Locale:Codes:t:uk.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Locale:Codes:t:uk.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Locale:Maketext:test.pl" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Locale:Maketext:test.pl >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bare_mbf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bare_mbf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bare_mbi.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bare_mbi.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bare_mif.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bare_mif.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bigfltpm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bigfltpm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bigintc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bigintc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bigintpm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bigintpm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:bigints.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:bigints.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:calling.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:calling.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:config.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:config.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:constant.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:constant.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:downgrade.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:downgrade.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:inf_nan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:inf_nan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:isa.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:isa.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:mbimbf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:mbimbf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:mbi_rand.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:mbi_rand.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:require.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:require.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:sub_mbf.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:sub_mbf.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:sub_mbi.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:sub_mbi.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:sub_mif.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:sub_mif.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:upgrade.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:upgrade.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:upgradef.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:upgradef.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:use.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:use.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:use_lib1.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:use_lib1.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:use_lib2.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:use_lib2.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:use_lib3.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:use_lib3.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:use_lib4.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:use_lib4.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigInt:t:with_sub.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigInt:t:with_sub.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigRat:t:big_ap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigRat:t:big_ap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigRat:t:bigfltrt.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigRat:t:bigfltrt.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigRat:t:bigrat.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigRat:t:bigrat.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:BigRat:t:bigratpm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:BigRat:t:bigratpm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:Complex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:Complex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Math:Trig.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Math:Trig.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:array.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:array.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:array_confusion.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:array_confusion.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:correctness.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:correctness.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:errors.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:errors.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:expfile.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:expfile.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:expire.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:expire.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:expmod_n.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:expmod_n.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:expmod_t.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:expmod_t.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:flush.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:flush.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:normalize.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:normalize.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:prototype.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:prototype.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:speed.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:speed.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tie.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tie.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tiefeatures.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tiefeatures.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tie_gdbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tie_gdbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tie_ndbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tie_ndbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tie_sdbm.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tie_sdbm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:tie_storable.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:tie_storable.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Memoize:t:unmemoize.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Memoize:t:unmemoize.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:hostent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:hostent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:netent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:netent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Net:Ping:t:100_load.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Net:Ping:t:100_load.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:110_icmp_inst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:110_icmp_inst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:120_udp_inst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:120_udp_inst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:130_tcp_inst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:130_tcp_inst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:140_stream_inst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:140_stream_inst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:150_syn_inst.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:150_syn_inst.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:190_alarm.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:190_alarm.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:200_ping_tcp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:200_ping_tcp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Net:Ping:t:250_ping_hires.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Net:Ping:t:250_ping_hires.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:300_ping_stream.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:300_ping_stream.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:400_ping_syn.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:400_ping_syn.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:410_syn_host.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:410_syn_host.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:450_service.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:450_service.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:Ping:t:500_ping_icmp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:Ping:t:500_ping_icmp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:protoent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:protoent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:servent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:servent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:config.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:config.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:ftp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:ftp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:hostname.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:hostname.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:netrc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:netrc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:nntp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:nntp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:require.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:require.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:smtp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:smtp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Net:t:time.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Net:t:time.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:NEXT:t:actual.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:NEXT:t:actual.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:NEXT:t:actuns.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:NEXT:t:actuns.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:NEXT:t:next.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:NEXT:t:next.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:NEXT:t:unseen.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:NEXT:t:unseen.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:open.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:open.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:overload.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:overload.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:PerlIO:via:t:QuotedPrint.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:PerlIO:via:t:QuotedPrint.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:ph.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:ph.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:basic.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:basic.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:eol.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:eol.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:Functions.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:Functions.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:htmlescp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:htmlescp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:htmlview.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:htmlview.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Pod:t:InputObjects.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Pod:t:InputObjects.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:latex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:latex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:man.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:man.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:parselink.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:parselink.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:Select.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:Select.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:text.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:text.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:text-errors.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:text-errors.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:text-options.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:text-options.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:Usage.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:Usage.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Pod:t:utils.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Pod:t:utils.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Search:Dict.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Search:Dict.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:SelectSaver.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:SelectSaver.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:SelfLoader.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:SelfLoader.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Shell.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Shell.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:sigtrap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:sigtrap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:sort.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:sort.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:strict.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:strict.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:subs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:subs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Switch:t:given.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Switch:t:given.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Switch:t:nested.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Switch:t:nested.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Switch:t:switch.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Switch:t:switch.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Symbol.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Symbol.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Term:ANSIColor:test.pl" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Term:ANSIColor:test.pl >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Term:Cap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Term:Cap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Term:Complete.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Term:Complete.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Term:ReadLine.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Term:ReadLine.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Test:Harness:t:00compile.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Test:Harness:t:00compile.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Test:Harness:t:assert.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Test:Harness:t:assert.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Harness:t:base.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Harness:t:base.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Harness:t:callback.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Harness:t:callback.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Test:Harness:t:nonumbers.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Test:Harness:t:nonumbers.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Harness:t:ok.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Harness:t:ok.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Harness:t:strap-analyze.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Harness:t:strap-analyze.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Test:Harness:t:strap.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Test:Harness:t:strap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Harness:t:test-harness.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Harness:t:test-harness.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:bad_plan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:bad_plan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:buffer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:buffer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:Builder.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:Builder.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:curr_test.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:curr_test.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:details.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:details.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:diag.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:diag.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Test:Simple:t:exit.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Test:Simple:t:exit.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:extra.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:extra.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -t ::lib:Test:Simple:t:fail-like.t" >> ::macos:MacPerlTests.out
:perl -I::lib -t ::lib:Test:Simple:t:fail-like.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:fail-more.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:fail-more.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:fail.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:fail.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:filehandles.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:filehandles.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:fork.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:fork.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:has_plan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:has_plan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:has_plan2.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:has_plan2.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:import.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:import.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:is_deeply.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:is_deeply.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:maybe_regex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:maybe_regex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:missing.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:missing.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:More.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:More.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib -T ::lib:Test:Simple:t:no_ending.t" >> ::macos:MacPerlTests.out
:perl -I::lib -T ::lib:Test:Simple:t:no_ending.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:no_header.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:no_header.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:no_plan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:no_plan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:ok_obj.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:ok_obj.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:output.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:output.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:plan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:plan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:plan_is_noplan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:plan_is_noplan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:plan_no_plan.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:plan_no_plan.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:plan_skip_all.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:plan_skip_all.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:simple.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:simple.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:skip.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:skip.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:skipall.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:skipall.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:strays.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:strays.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:threads.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:threads.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:todo.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:todo.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:undef.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:undef.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:useing.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:useing.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:Simple:t:use_ok.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:Simple:t:use_ok.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:fail.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:fail.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:mix.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:mix.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:onfail.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:onfail.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:qr.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:qr.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:skip.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:skip.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:success.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:success.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Test:t:todo.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Test:t:todo.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Abbrev.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Abbrev.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extbrk.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extbrk.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extcbk.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extcbk.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extdel.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extdel.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extmul.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extmul.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extqlk.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extqlk.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:exttag.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:exttag.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:extvar.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:extvar.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Balanced:t:gentag.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Balanced:t:gentag.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:ParseWords.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:ParseWords.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:Soundex.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:Soundex.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:TabsWrap:t:fill.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:TabsWrap:t:fill.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:TabsWrap:t:tabs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:TabsWrap:t:tabs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Text:TabsWrap:t:wrap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Text:TabsWrap:t:wrap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

#echo ":perl -I::lib    ::lib:Thread:Queue.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:Tie:Array:push.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out
#echo ":perl -I::lib    ::lib:Thread:Semaphore.t" >> ::macos:MacPerlTests.out
#:perl -I::lib    ::lib:Tie:Array:push.t >> ::macos:MacPerlTests.out
#save ::macos:MacPerlTests.out

echo ":perl -I::lib    ::lib:Tie:Array:push.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Array:push.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Array:splice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Array:splice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Array:std.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Array:std.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Array:stdpush.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Array:stdpush.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:00_version.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:00_version.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:01_gen.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:01_gen.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:02_fetchsize.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:02_fetchsize.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:03_longfetch.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:03_longfetch.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:04_splice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:04_splice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:05_size.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:05_size.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:06_fixrec.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:06_fixrec.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:07_rv_splice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:07_rv_splice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:08_ro.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:08_ro.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:09_gen_rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:09_gen_rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:10_splice_rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:10_splice_rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:11_rv_splice_rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:11_rv_splice_rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:12_longfetch_rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:12_longfetch_rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:13_size_rs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:13_size_rs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:14_lock.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:14_lock.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:15_pushpop.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:15_pushpop.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:16_handle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:16_handle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:17_misc_meth.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:17_misc_meth.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:18_rs_fixrec.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:18_rs_fixrec.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:19_cache.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:19_cache.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:20_cache_full.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:20_cache_full.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:21_win32.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:21_win32.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:22_autochomp.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:22_autochomp.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:23_rv_ac_splice.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:23_rv_ac_splice.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:24_cache_loop.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:24_cache_loop.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:25_gen_nocache.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:25_gen_nocache.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:26_twrite.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:26_twrite.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:30_defer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:30_defer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:31_autodefer.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:31_autodefer.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:32_defer_misc.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:32_defer_misc.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:33_defer_vs.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:33_defer_vs.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:40_abs_cache.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:40_abs_cache.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:File:t:41_heap.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:File:t:41_heap.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Handle:stdhandle.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Handle:stdhandle.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Memoize.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Memoize.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:RefHash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:RefHash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:Scalar.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:Scalar.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Tie:SubstrHash.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Tie:SubstrHash.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Time:gmtime.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Time:gmtime.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Time:Local.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Time:Local.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Time:localtime.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Time:localtime.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Unicode:Collate:t:index.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Unicode:Collate:t:index.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Unicode:Collate:t:test.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Unicode:Collate:t:test.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:Unicode:UCD.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:Unicode:UCD.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:User:grent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:User:grent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:User:pwent.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:User:pwent.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:utf8.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:utf8.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:vars.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:vars.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:vmsish.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:vmsish.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
echo ":perl -I::lib    ::lib:warnings.t" >> ::macos:MacPerlTests.out
:perl -I::lib    ::lib:warnings.t >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out

echo ""
echo "# `Date -t` ----- End MacPerl tests."
echo ""

# we know some things will fail
echo "The following tests mostly work, but fail because of known"
echo "IO problems.  Feel free to run them, and note the failures."
echo "These tests are known to fail.  Run if you want to, but beware"
echo "because crashes are possible."
echo ""
echo "# Devel::DProf seems to work, but test needs major work :/"
echo ":perl -I::lib    ::ext:Devel:DProf:DProf.t"
echo ""
echo "# fails one test, 21, related to tainting"
echo ":perl -I::lib    ::ext:Devel:Peek:Peek.t"
echo ""
echo "# fails tests 10 and 11 sometimes, when run with test suite, but is really OK"
echo ":perl -I::lib    ::lib:Devel:SelfStubber.t"
echo ""
echo "# fails tests 373 (known problem in sysopen warning)"
echo ":perl -I::lib    ::lib:warnings.t"
echo ""
echo "# fails all tests (system() fails to return a good value)"
echo ":perl -I::lib    :op:die_exit.t"
echo ""
echo "# fails tests 131, 132, 148, 167 (known problem in sfio)"
echo ":perl -I::lib    :op:sprintf.t"
echo ""
echo "# fails tests 158 164 170 (O_RDWR issues)"
echo ":perl -I::lib -T :op:taint.t"
echo ""
echo "# fails tests 47 and 48 (no idea why)"
echo ":perl -I::lib    :x2p:s2p.t"
echo ""

# see how we did
:perl -I::lib ::macos:MacPerlTests.plx ::macos:MacPerlTests.out >> ::macos:MacPerlTests.out
save ::macos:MacPerlTests.out
