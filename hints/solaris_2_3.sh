d_vfork='undef'
set `echo $libpth | sed -e 's@/usr/ucblib@@'`
libpth="$*"
case $PATH in
*/usr/ucb*:/usr/bin:*) cat <<END
NOTE:  Some people have reported problems with /usr/ucb/cc.  
Remove /usr/ucb from your PATH if you have difficulties.
END
;;
esac
