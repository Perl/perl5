case "$cc" in
*gcc*)	usevfork=false ;;
*)	usevfork=true ;;
esac
d_tzname='undef'
# check if user is in a bsd or system 5 type environment
if cat -b /dev/null 2>/dev/null
then # bsd
      groupstype='int'
else # sys5
      groupstype='gid_t'
fi
# we don't set gidtype because unistd.h says gid_t getgid() but man
# page says int getgid() for bsd. utils.c includes unistd.h :-(
