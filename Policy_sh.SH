case $CONFIG in
'') . ./config.sh ;;
esac
echo "Extracting Policy.sh (with variable substitutions)"
$spitshell <<!GROK!THIS! >Policy.sh
$startsh
#
#  This file was produced by running the Policy_sh.SH script, which
#  gets its values from config.sh, which is generally produced by
#  running Configure.  The Policy.sh file gets overwritten each time
#  Configure is run.  Any variables you add to Policy.sh will be lost
#  unless you copy Policy.sh somewhere else before running Configure.
#
#  The idea here is to distill in one place the common site-wide
#  "policy" answers (such as installation directories) that are
#  to be "sticky".  That is, if you keep the file Policy.sh around in
#  the same directory as you are building Perl, then Configure will
#  (by default) load up the Policy.sh file just before the
#  platform-specific hints file.
# 

#Credits:
#   The original design for this Policy.sh file came from Wayne Davison,
#   maintainer of trn.
#   This version for Perl5.004_61 originally written by 
#   Andy Dougherty <doughera@lafcol.lafayette.edu>.
#   This file may be distributed under the same terms as Perl itself.


#  Site-specific values 

perladmin='$perladmin'

# Installation directives.  Note that each one comes in three flavors.
# For example, we have privlib, privlibexp, and installprivlib.
# privlib is for private (to perl) library files.
# privlibexp is the same, expcept any '~' the user gave to Configure
#     is expanded to the user's home directory.  This is figured
#     out automatically by Configure, so you don't have to include it here.   
# installprivlib is for systems (such as those running AFS) that
#     need to distinguish between the place where things
#     get installed and where they finally will reside.

# Installation Prefix.
prefix='$prefix'

bin='$bin'
installbin='$installbin'

scriptdir='$scriptdir'
installscript='$installscript'

privlib='$privlib'
installprivlib='$installprivlib'

sitelib='$sitelib'
installsitelib='$installsitelib'

# man1 and man3 manpage directories and extensions.
man1dir='$man1dir'
man1ext='$man1ext'
installman1dir='$installman1dir'
man3dir='$man3dir'
man3ext='$man3ext'
installman3dir='$installman3dir'

# NOTE:  Be careful about architecture-dependent names.  If you have
# accepted the default, the following definitions will be commented out.
# That way you can carry this file to another architecture and this file
# won't mistakenly set architecture-dependent names to the wrong value.
#
# If you have not accepted the default, then be sure to check the
# following lines before copying this file to another system.

!GROK!THIS!

if test 0 -eq "$subversion"; then
    version=`LC_ALL=C; export LC_ALL; \
    echo $baserev $patchlevel | 
	$awk '{ printf "%.3f\n", $1 + $2/1000.0 }'`
else
    version=`LC_ALL=C; export LC_ALL; \
	echo $baserev $patchlevel $subversion | \
	$awk '{ printf "%.5f\n", $1 + $2/1000.0 + $3/100000.0 }'`
fi

dflt="$privlib/$archname/$version"
if test X"$archlib" = X"$dflt"; then
    echo "# archlib='$archlib'"
    echo "# installarchlib='$installarchlib'"
else
    echo '# NOTE:  Preserving your custom archlib.'
    echo "archlib='$archlib'"
    echo "installarchlib='$installarchlib'"
fi >> Policy.sh
echo >> Policy.sh

# Now consider sitearch.
dflt="$sitelib/$archname"
if test X"$sitearch" = X"$dflt"; then
    echo "# sitearch='$sitearch'"
    echo "# installsitearch='$installsitearch'"
else
    echo '# NOTE:  Preserving your custom sitearch.'
    echo "sitearch='$sitearch'"
    echo "installsitearch='$installsitearch'"
fi >> Policy.sh

$spitshell <<!GROK!THIS! >>Policy.sh

#  Lastly, you may add additional items here.  For example, to set the 
#  pager to your local favorite value, uncomment the following line in
#  the original Policy_sh.SH file and re-run   sh Policy_sh.SH.
# pager='$pager'
#
#  A full Glossary of all the config.sh variables is in the file
#  Porting/Glossary.

!GROK!THIS!
