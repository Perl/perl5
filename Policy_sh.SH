case $CONFIG in
'') . ./config.sh ;;
esac
echo "Extracting Policy.sh (with variable substitutions)"
$spitshell <<!GROK!THIS! >Policy.sh
$startsh
#
#  This file was produced by running the Policy_sh.SH script, which
#  gets its values from config.sh, which is generally produced by
#  running Configure.
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
# A full Glossary of all these config.sh variables is in the
# Porting/Glossary file.

# Installation Prefix.
prefix='$prefix'

bin='$bin'
installbin='$installbin'

scriptdir='$scriptdir'
installscript='$installscript'

privlib='$privlib'
installprivlib='$installprivlib'

archlib='$archlib'
installarchlib='$installarchlib'

sitearch='$sitearch'
installsitearch='$installsitearch'

sitelib='$sitelib'
installsitelib='$installsitelib'

# man1 and man3 manpage directories and extensions.
man1dir='$man1dir'
man1ext='$man1ext'
installman1dir='$installman1dir'
man3dir='$man3dir'
man3ext='$man3ext'
installman3dir='$installman3dir'

#  You may add additional items here, for example, to set the pager
#  to your local favorite value, uncomment
#  #pager='$pager'

!GROK!THIS!
