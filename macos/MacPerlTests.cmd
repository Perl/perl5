# ::macos:perl -I::lib -e 'for(<:*:*.t>){open my $fh,"<$_";$t=<$fh>=~/(T)/?"-T":"  ";$s="$^X -I::lib $t $_"; print qq[echo "$s"\n$s\n]}'
set -e MACPERL ""
set -e PERL5LIB ""
perl -e '`set -e MACPERL_OLD "{{MACPERL}}"` if `echo {{MACPERL}}`'
perl -e '`set -e PERL5LIB_OLD "{{PERL5LIB}}"` if `echo {{PERL5LIB}}`'
perl -e '`set -e MACPERL ""`'
perl -e '`set -e PERL5LIB ""`'
echo "# When finished, execute these lines to restore your ToolServer environment:"
echo "perl -e '¶`set -e MACPERL  ¶"¶{¶{MACPERL_OLD¶}¶}¶"¶`  if ¶`echo ¶{¶{MACPERL_OLD¶}¶}¶`'"
echo "perl -e '¶`set -e PERL5LIB ¶"¶{¶{PERL5LIB_OLD¶}¶}¶"¶` if ¶`echo ¶{¶{PERL5LIB_OLD¶}¶}¶`'"
echo ""

perl -e 'open F, ">::macos:MacPerlTests.out"'
open ::macos:MacPerlTests.out

echo "::macos:perl -I::lib    :base:cond.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:cond.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :base:if.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:if.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :base:lex.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:lex.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :base:pat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:pat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :base:rs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:rs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :base:term.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :base:term.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:elsif.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:elsif.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:for.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:for.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:mod.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:mod.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:subval.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:subval.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:switch.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:switch.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :cmd:while.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :cmd:while.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:bproto.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:bproto.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:cmdopt.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:cmdopt.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:colon.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:colon.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:cpp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:cpp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:decl.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:decl.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:multiline.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:multiline.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:package.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:package.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:proto.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:proto.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:redef.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:redef.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:require.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:require.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:script.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:script.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:term.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:term.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :comp:use.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :comp:use.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:argv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:argv.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:dup.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:dup.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:fs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:fs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:inplace.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:inplace.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:iprefix.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:iprefix.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:nargv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:nargv.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:open.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:open.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:openpid.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:openpid.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:pipe.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:pipe.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:print.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:print.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:read.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:read.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :io:tell.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :io:tell.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:abbrev.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:abbrev.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:ansicolor.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:ansicolor.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:anydbm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:anydbm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:attrs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:attrs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:autoloader.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:autoloader.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:b.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:b.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :lib:basename.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :lib:basename.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:bigfloat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:bigfloat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:bigfltpm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:bigfltpm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:bigint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:bigint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:bigintpm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:bigintpm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-esc.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-esc.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-form.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-form.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-function.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-function.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-html.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-html.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-pretty.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-pretty.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:cgi-request.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:cgi-request.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:charnames.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:charnames.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:checktree.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:checktree.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:class-struct.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:class-struct.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:complex.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:complex.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:db-btree.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:db-btree.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:db-hash.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:db-hash.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:db-recno.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:db-recno.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:dirhand.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:dirhand.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:dosglob.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:dosglob.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:dprof.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:dprof.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:dumper-ovl.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:dumper-ovl.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:dumper.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:dumper.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:english.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:english.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:env-array.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:env-array.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:env.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:env.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:errno.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:errno.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:fatal.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:fatal.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:fields.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:fields.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filecache.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filecache.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filecopy.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filecopy.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :lib:filefind-taint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :lib:filefind-taint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filefind.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filefind.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filefunc.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filefunc.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filehand.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filehand.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filepath.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filepath.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:filespec.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:filespec.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:findbin.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:findbin.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:ftmp-mktemp.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:ftmp-mktemp.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:ftmp-posix.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:ftmp-posix.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:ftmp-security.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:ftmp-security.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :lib:ftmp-tempfile.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :lib:ftmp-tempfile.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:gdbm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:gdbm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:getopt.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:getopt.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:glob-basic.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:glob-basic.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:glob-case.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:glob-case.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:glob-global.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:glob-global.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :lib:glob-taint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :lib:glob-taint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:gol-basic.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:gol-basic.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:gol-compat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:gol-compat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:gol-linkage.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:gol-linkage.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:gol-oo.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:gol-oo.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:h2ph.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:h2ph.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:hostname.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:hostname.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_const.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_const.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_dir.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_dir.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_dup.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_dup.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_linenum.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_linenum.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_multihomed.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_multihomed.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_pipe.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_pipe.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_poll.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_poll.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_sel.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_sel.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_sock.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_sock.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :lib:io_taint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :lib:io_taint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_tell.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_tell.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_udp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_udp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_unix.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_unix.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:io_xs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:io_xs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:ipc_sysv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:ipc_sysv.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:ndbm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:ndbm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:odbm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:odbm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:opcode.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:opcode.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:open2.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:open2.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:open3.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:open3.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:ops.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:ops.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:parsewords.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:parsewords.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:peek.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:peek.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:ph.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:ph.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:posix.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:posix.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:safe1.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:safe1.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:safe2.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:safe2.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:sdbm.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:sdbm.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:searchdict.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:searchdict.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:selectsaver.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:selectsaver.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:selfloader.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:selfloader.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:socket.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:socket.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:soundex.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:soundex.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:symbol.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:symbol.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:syslfs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:syslfs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:syslog.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:syslog.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:textfill.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:textfill.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:texttabs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:texttabs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:textwrap.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:textwrap.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:thr5005.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:thr5005.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-push.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-push.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-refhash.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-refhash.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-splice.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-splice.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-stdarray.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-stdarray.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-stdhandle.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-stdhandle.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-stdpush.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-stdpush.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:tie-substrhash.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:tie-substrhash.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:timelocal.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:timelocal.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :lib:trig.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :lib:trig.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:64bitint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:64bitint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:anonsub.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:anonsub.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:append.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:append.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:args.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:args.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:arith.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:arith.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:array.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:array.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:assignwarn.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:assignwarn.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:attrs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:attrs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:auto.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:auto.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:avhv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:avhv.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:bop.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:bop.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:chars.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:chars.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:chop.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:chop.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:closure.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:closure.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:cmp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:cmp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:concat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:concat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:cond.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:cond.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:context.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:context.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:defins.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:defins.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:delete.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:delete.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:die.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:die.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :op:die_exit.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :op:die_exit.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:do.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:do.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:each.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:each.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:eval.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:eval.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:exec.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:exec.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:exists_sub.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:exists_sub.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:exp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:exp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:fh.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:fh.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:filetest.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:filetest.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:flip.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:flip.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:fork.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:fork.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:glob.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:glob.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:goto.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:goto.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:goto_xs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:goto_xs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:grent.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:grent.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:grep.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:grep.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:groups.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:groups.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:gv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:gv.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:hashwarn.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:hashwarn.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:inc.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:inc.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:index.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:index.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:int.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:int.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:join.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:join.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:length.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:length.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:lex_assign.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:lex_assign.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:lfs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:lfs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:list.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:list.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:local.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:local.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:lop.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:lop.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :op:magic.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :op:magic.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:method.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:method.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :op:misc.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :op:misc.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:mkdir.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:mkdir.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:my.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:my.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:my_stash.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:my_stash.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:nothr5005.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:nothr5005.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:numconvert.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:numconvert.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:oct.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:oct.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:ord.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:ord.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:pack.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:pack.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:pat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:pat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:pos.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:pos.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:push.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:push.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:pwent.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:pwent.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:quotemeta.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:quotemeta.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:rand.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:rand.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:range.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:range.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:read.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:read.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:readdir.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:readdir.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:recurse.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:recurse.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:ref.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:ref.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:regexp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:regexp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:regexp_noamp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:regexp_noamp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:regmesg.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:regmesg.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:repeat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:repeat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:reverse.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:reverse.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:runlevel.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:runlevel.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:sleep.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:sleep.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:sort.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:sort.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:splice.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:splice.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:split.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:split.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :op:sprintf.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :op:sprintf.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:stat.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:stat.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:study.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:study.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:subst.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:subst.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:subst_amp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:subst_amp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:subst_wamp.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:subst_wamp.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:substr.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:substr.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:sysio.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:sysio.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :op:taint.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :op:taint.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:tie.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:tie.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:tiearray.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:tiearray.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:tiehandle.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:tiehandle.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:time.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:time.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:tr.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:tr.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:undef.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:undef.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:universal.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:universal.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:unshift.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:unshift.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:utf8decode.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:utf8decode.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:vec.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:vec.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:ver.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:ver.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:wantarray.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:wantarray.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :op:write.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :op:write.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:emptycmd.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:emptycmd.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:find.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:find.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:for.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:for.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:headings.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:headings.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:include.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:include.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:included.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:included.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:lref.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:lref.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:multiline_items.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:multiline_items.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:nested_items.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:nested_items.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:nested_seqs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:nested_seqs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:oneline_cmds.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:oneline_cmds.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:pod2usage.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:pod2usage.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:poderrs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:poderrs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:podselect.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:podselect.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pod:special_seqs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pod:special_seqs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:constant.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:constant.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:diagnostics.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:diagnostics.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib -T :pragma:locale.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib -T :pragma:locale.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:overload.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:overload.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:strict.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:strict.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:sub_lval.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:sub_lval.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:subs.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:subs.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :pragma:utf8.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :pragma:utf8.t >> ::macos:MacPerlTests.out
# echo "::macos:perl -I::lib    :pragma:warnings.t" >> ::macos:MacPerlTests.out
# ::macos:perl -I::lib    :pragma:warnings.t >> ::macos:MacPerlTests.out
echo "::macos:perl -I::lib    :run:runenv.t" >> ::macos:MacPerlTests.out
::macos:perl -I::lib    :run:runenv.t >> ::macos:MacPerlTests.out

::macos:perl -I::lib ::macos:MacPerlTests.plx ::macos:MacPerlTests.out >> ::macos:MacPerlTests.out

echo "The following tests mostly work, but fail because of known"
echo "IO problems.  Feel free to run them, and note the failures."
echo "These tests are known to fail.  Run if you want to, but beware"
echo "because crashes are possible."
echo ""
echo "# DB is broken in a few different ways"
echo "::macos:perl -I::lib    :lib:db-hash.t >> ::macos:MacPerlTests.out"
echo "::macos:perl -I::lib    :lib:db-recno.t >> ::macos:MacPerlTests.out"
echo ""
echo "# DOS::Glob doesn't work ... do we care?"
echo "::macos:perl -I::lib    :lib:dosglob.t >> ::macos:MacPerlTests.out"
echo ""
echo "# Devel::DProf seems to work, but test needs major work :/"
echo "::macos:perl -I::lib    :lib:dprof.t >> ::macos:MacPerlTests.out"
echo ""
echo "# I have no idea about these ..."
echo "::macos:perl -I::lib    :lib:ftmp-mktemp.t >> ::macos:MacPerlTests.out"
echo "::macos:perl -I::lib    :lib:ftmp-posix.t >> ::macos:MacPerlTests.out"
echo "::macos:perl -I::lib    :lib:ftmp-security.t >> ::macos:MacPerlTests.out"
echo "::macos:perl -I::lib    :lib:ftmp-tempfile.t >> ::macos:MacPerlTests.out"
echo ""
echo "# system() fails to return a good value"
echo "::macos:perl -I::lib    :op:die_exit.t >> ::macos:MacPerlTests.out"
echo ""
echo "# I dunno here"
echo "::macos:perl -I::lib    :op:magic.t >> ::macos:MacPerlTests.out"
echo ""
echo "# fails test  48 (known problem in IO redirection)"
echo "::macos:perl -I::lib    :op:misc.t >> ::macos:MacPerlTests.out"
echo ""
echo "# fails tests 129, 130, 142, 161 (known problem in sfio)"
echo "::macos:perl -I::lib    :op:sprintf.t >> ::macos:MacPerlTests.out"
echo ""
echo "# fails tests 319, 329 (known problem in IO redirection)"
echo "::macos:perl -I::lib    :pragma:warnings.t >> ::macos:MacPerlTests.out"
