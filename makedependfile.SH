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

# Below, we strip out all but preprocessor directives.  This has complications
# because of continuation lines and comments potentially spanning multiple
# lines.
#
# sed labels here use 7 characters max due to a solaris restriction
(     $echo "#line 2 \"$file\"";                                            \
      $sed  <$file                                                          \
        -e "/^${filebase}_init(/q"                                          \
                                                                            \
        -e ': tstcont'                                                      \
                                                                            \
        -e '# Replace non-empty /*...*/ comments (and surrounding white'    \
        -e '# space) by a single blank.  Note that this doesnt work'        \
        -e '# properly if the comment introducer is inside a literal'       \
        -e '# "string", but this is quite unlikely in a preprocessor'       \
        -e '# statement'                                                    \
                                                                            \
        -e '# We retain empty comments because in code like this:'          \
        -e '#   #define FOO(a,b)  a/**/b                         '          \
        -e '# the comment is important.                          '          \
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
                                                                            \
            -e '# Any remaining /* begins a comment that goes onto the'     \
            -e '# next line(s).  We want to convert things like'            \
            -e '#   #ifdef FOO /* comment line 1            '               \
            -e '#                 more comment lines        '               \
            -e '#                 final comment */  BAR /* trail comment */'\
            -e '# into                                            '         \
            -e '#   #ifdef FOO BAR                          '               \
            -e '\:/\*:{'                                                    \
                                                                            \
                -e '# Remove the trailing comment and save.  So the hold'   \
                -e '# buffer now contains "#ifdef FOO"'                     \
                -e 's:/\*.*::'                                              \
                -e h                                                        \
                                                                            \
                -e '# Loop, reading and deleting the succeeding lines'      \
                -e '# until find the closing "*/" '                         \
                -e ': in_mult'                                             \
                -e 'N'                                                      \
                -e '\:\*/:!{'                                               \
                    -e 's/.*//'                                             \
                    -e 'b in_mult'                                         \
                -e '}'                                                      \
                                                                            \
                -e '# Here at final line in comment.  Convert:'             \
                -e '#   final comment */  BAR /* trail comment */'          \
                -e '# to:'                                                  \
                -e '#   /* final comment */  BAR /* trail comment */'       \
                -e 's:^:/*:'                                                \
                                                                            \
                -e '# Append to the hold buffer, yielding there:'           \
                -e '#   #ifdef FOO /* final comment */ BAR /* trail comment */'\
                -e 'H'                                                      \
                                                                            \
                -e '# Bring the hold buffer into the working one.  We have' \
                -e '# now reduced this multi-line comment to a case'        \
                -e '# we already know how to handle, including any'         \
                -e '# complications such as if there are interior'          \
                -e '# asterisks and/or it ends with a continuation marker.' \
                -e '# Go there to handle'                                   \
                -e g                                                        \
                -e 'b tstcont'                                              \
            -e '}'                                                          \
        -e '}'                                                              \
                                                                            \
        -e '# Now that we have done /*...*/ comments, we can do //'         \
        -e '# ones.  The other way round doesnt work because of things'     \
        -e '# like /* ... // ... */'                                        \
        -e 's:[ 	]*//.*: :'                                          \
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
        -e '# We only output preprocessor control lines; now that the'      \
        -e '# current line has no continuations or multi-line comments,'    \
        -e '# we know enough to skip non-preprocessor lines'                \
        -e '/^[ 	]*#/!d'                                             \
                                                                            \
        -e '# Delete two styles of lines that specify the line number'      \
        -e '/^#line/d'                                                      \
        -e '/^#[    ]+[0-9][0-9]* /d'                                       \
                                                                            \
        -e '# Some preprocessors have a very finite limit of acceptable'    \
        -e '# line length.  Our joining may have exceeded that, so split'   \
        -e '# long lines.  This is painful in strict sed, as the'           \
        -e '# replacement string in an s/// need not recognize escape'      \
        -e '# sequences like \n '                                           \
        -e ': longs'                                                        \
                                                                            \
        -e '# Look for a line that has at least one char beyond the limit'  \
        -e '/.\{255\}./{'                                                   \
                                                                            \
            -e '# Save a copy of this line'                                 \
            -e h                                                            \
                                                                            \
            -e '# Change the working copy to have only the characters in'   \
            -e '# excess of the allowable length, allowing room for an'     \
            -e '# appended terminating backslash continuation marker'       \
            -e 's/.\{254\}//'                                               \
                                                                            \
            -e '# Swap the buffers so the excess is saved away, and we are' \
            -e '# working on the full line again'                           \
            -e x                                                            \
                                                                            \
            -e '# From the full line, delete the excess, replacing it with' \
            -e '# the backslash continuation marker'                        \
            -e 's/\(.\{254\}\).*/\1\\/'                                     \
                                                                            \
            -e '# Append the excess that has been saved.  The G inserts'    \
            -e '# our desired \n '                                          \
            -e G                                                            \
                                                                            \
            -e '# Print the initial, acceptable-length, portion'            \
            -e P                                                            \
                                                                            \
            -e '# Bring the excess into the working buffer; go see if it'   \
            -e '# needs further splitting'                                  \
            -e g                                                            \
            -e 'b longs'                                                    \
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
