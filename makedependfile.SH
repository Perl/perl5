#! /bin/sh
case $PERL_CONFIG_SH in
'')
        if test -f config.sh; then TOP=.;
        elif test -f ../config.sh; then TOP=..;
        elif test -f ../../config.sh; then TOP=../..;
        elif test -f ../../../config.sh; then TOP=../../..;
        elif test -f ../../../../config.sh; then TOP=../../../..;
        else
                echo "Can't find config.sh."; exit 1
        fi
        . $TOP/config.sh
        ;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

echo "Extracting makedependfile (with variable substitutions)"
rm -f makedependfile
$spitshell >makedependfile <<!GROK!THIS!
$startsh
# makedependfile.SH
#
MAKE=$make
trnl='$trnl'
!GROK!THIS!
$spitshell >>makedependfile <<'!NO!SUBS!'

file=$1
shift
outfile=$1
shift

case $PERL_CONFIG_SH in
'')
        if test -f config.sh; then TOP=.;
        elif test -f ../config.sh; then TOP=..;
        elif test -f ../../config.sh; then TOP=../..;
        elif test -f ../../../config.sh; then TOP=../../..;
        elif test -f ../../../../config.sh; then TOP=../../../..;
        else
                echo "Can't find config.sh."; exit 1
        fi
        . $TOP/config.sh
        ;;
esac

# Avoid localized gcc messages
case "$ccname" in
    gcc) LC_ALL=C ; export LC_ALL ;;
esac

# We need .. when we are in the x2p directory if we are using the
# cppstdin wrapper script.
# Put .. and . first so that we pick up the present cppstdin, not
# an older one lying about in /usr/local/bin.  Do not do this for a
# direct compiler command like "ccache gcc -E", or ccache may resolve
# gcc against an unrelated ./gcc or ../gcc path entry.
case "$cppstdin" in
cppstdin|*/cppstdin|cppstdin\ *|*/cppstdin\ *)
    PATH=".$path_sep..$path_sep$PATH"
    export PATH
    ;;
esac

case "$osname" in
    amigaos) cat=/bin/cat ;; # must be absolute
esac

case "$osname" in
    os2)      uwinfix="-e s,\\\\\\\\,/,g" ;;
    cygwin)   uwinfix="-e s,\\\\\\\\,/,g" ;;
    posix-bc) uwinfix="-e s/\\*POSIX(\\(.*\\))/\\1/" ;;
    vos)      uwinfix="-e s/\#/\\\#/" ;;
    *)        uwinfix="" ;;
esac
case "$file" in
    *.c) filebase=`basename $file .c` ;;
    *.y) filebase=`basename $file .y` ;;
esac
case "$file" in
    */*) finc="-I`echo $file | sed 's#/[^/]*$##'`" ;;
    *)   finc= ;;
esac

$echo "Finding dependencies for $filebase$_o"

# Below, we strip out all but preprocessor directives.
# We have to take care of situations like
#       #if defined(FOO) BAR   /* comment line 1
#                                 more comment lines */
# If we just delete text starting from the '/*' to the end of line, we will
# screw up cases like
#      #if defined(FOO)    /* comment */ \
#          && defined(BAR) /* comment */ \
#          && defined(BAZ) /* comment */ \
#               etc.
# Also, in lines like
#      #defined FOO(a,b)    a/**/b
# the comment may be important and so needs to be retained.
# This code processes the single-line comments first; it assumes there is
# at most one straightforward comment per continued preprocessor line,
# replacing each non-empty comment (and its surrounding white space) by a
# single space.  (sed only has a greedy '*' quantifier, so this doesn't
# work right if there are multiple comments per line, and strings can look
# like comments to it; both are unlikely in a preprocessor statement.) Any
# continuation line is joined, and the process repeated on the enlarged
# line as long as there are continuations.  At the end, if there are any
# comments remaining, they are either completely empty or are like the
# first situation.  The latter are just deleted by first deleting to the
# end of line (including preceding white space) things that start with '/*'
# and the next char isn't a '*'; then things that start with '/**', but the
# next char isn't a '/'.  (Subsequent lines of the comment are irrelevant
# and get dropped.)  At the end, we unjoin very long lines to avoid
# preprocessor limitations
#
# sed labels here use 7 characters max due to a solaris restriction

(     $echo "#line 2 \"$file\"";                                            \
      $sed -n <$file                                                        \
        -e "/^${filebase}_init(/q"                                          \
                                                                            \
        -e ': tstcont'                                                      \
                                                                            \
        -e '# Replace non-empty /*...*/ comments (and surrounding white'    \
        -e '# space) by a single blank.  Note that this doesnt work'        \
        -e '# properly if the comment introducer is inside a literal'       \
        -e '# "string", but this is quite unlikely in a preprocessor'       \
        -e '# statement'                                                    \
        -e '\:/\*:{'                                                        \
                                                                            \
            -e '# Ready to handle the comment(s).  We have to cope with'    \
            -e '# the fact that "*" is always greedy in sed.  First,'       \
            -e '# loop to change all interior asterisks like'               \
            -e '#   /* ... *** */                                        '  \
            -e '#                   somewhat arbitrarily to'                \
            -e '#   /* ... @@@ */'                                          \
            -e '\:/\*..*\*[^/]:{'                                           \
                -e '# Make sure t flag is cleared'                          \
                -e 't stars'                                                \
                                                                            \
                -e ': stars'                                                \
                -e 's:\(/\*[^*]*\)\*\([^/]\):\1@\2:'                        \
                -e 't stars'                                                \
            -e '}'                                                          \
                                                                            \
            -e '# Now that there are no interior asterisks, we can use a'   \
            -e '# pattern that avoids the greediness issues'                \
            -e 's:[ 	]*/\*[^*]\{1,\}\*/[ 	]*: :g'                     \
        -e '}'                                                              \
                                                                            \
                                                                            \
        -e '# If this line is continued, join the next one to it, and'      \
        -e '# loop.  The loop removes comments on this next joined segment' \
        -e '/\\$/{'                                                         \
            -e 'N'                                                          \
            -e 'b tstcont'                                                  \
        -e '}'                                                              \
                                                                            \
        -e '# Remove any embedded new lines to give an exact representation'\
        -e '# of the lines joined with their continuations'                 \
        -e 's/\\\n//g'                                                      \
                                                                            \
        -e '# Delete two styles of lines that specify the line number'      \
        -e '/^#line/d'                                                      \
        -e '/^#[    ]+[0-9][0-9]* /d'                                       \
                                                                            \
        -e '/^[ 	]*#/{'                                              \
            -e 's|[ 	]*/\*[^*].*$||'                                     \
            -e 's|[ 	]*/\*\*[^/].*$||'                                   \
            -e 's/.\{255\}/&\\\n/g'                                         \
            -e p                                                            \
        -e '}'                                                              \
        | $grep -v ":"                                                      \
) >UU/$file.c

# Some files include this header, which may not be present on this system.
# Some preprocessors abort at the point an #included file isn't found, giving
# incomplete results.  Make sure a file with this name does exist.  The cpp
# command looks in this directory..
touch UU/git_version.h

# Run the preprocess, and remove all the following irrelevant lines
$cppstdin -DPERL_CORE $finc -I. -IUU $cppflags $cppminus <UU/$file.c >$$.cout 2>$$.cerr
$sed -e '1d'                                                                \
     -e '/^#.*<stdin>/d'                                                    \
     -e '/^#.*<builtin>/d'                                                  \
     -e '/^#.*<built-in>/d'                                                 \
     -e '/^#.*<command line>/d'                                             \
     -e '/^#.*<command-line>/d'                                             \
     -e '/".*In file included from.*:/d'                                    \
     -e '/^#.*"-"/d'                                                        \
     -e '/^#.*"\/.*\/"/d'                                                   \
     -e '/: file path prefix .* never used$/d'                              \
                                                                            \
     -e '# This will be in the form of an #include, which isnt really a'    \
     -e '# dependency'                                                      \
     -e '/^#.*git_version\.h/d'                                             \
                                                                            \
     -e 's#\.[0-9][0-9]*\.c#'"$file.c#"                                     \
     -e 's/^[	 ]*#[	 ]*line/#/'                                         \
     -e '/^# *[0-9][0-9]* *[".\/]/!d'                                       \
     -e 's/^.*"\(.*\)".*$/'$filebase'\$(OBJ_EXT): \1/'                      \
     -e 's/^# *[0-9][0-9]* \(.*\)$/'$filebase'\$(OBJ_EXT): \1/'             \
     -e 's|: \./|: |'                                                       \
     -e 's|\.c\.c|.c|' $uwinfix $$.cout $$.cerr                             \
| $uniq | $sort | $uniq >> $outfile
rm $$.cout
rm $$.cerr
$echo "$filebase\$(OBJ_EXT): $@" >>$outfile

!NO!SUBS!
$eunicefix makedependfile
chmod +x makedependfile
