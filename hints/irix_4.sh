optimize='-O1'
usemymalloc='y'
d_voidsig=define
usevfork=false
d_charsprf=undef
ccflags="-ansiposix -signed"
#
# This hint due thanks Hershel Walters <walters@smd4d.wes.army.mil>
# Date: Tue, 31 Jan 1995 16:32:53 -0600 (CST)
# Subject: IRIX4.0.4(.5? 5.0?) problems
# I don't know if they affect versions of perl other than 5.000 or
# versions of IRIX other than 4.0.4.
#
cat <<'EOM'
If you have problems, you might have try including
	-DSTANDARD_C -cckr 
in ccflags.
EOM
