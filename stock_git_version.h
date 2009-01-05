/***************************************************************************
This is: stock_git_config.h - temporary git_config.h file.
This file is used at the very start of the build process when we don't have
a miniperl available to make the real thing.  It is copied in place during
the build process, and then later on replaced.
****************************************************************************/
#define PERL_PATCHNUM "UNKNOWN"
#define PERL_GIT_UNCOMMITTED_CHANGES ,"UNKNOWN"
#define PERL_GIT_UNPUSHED_COMMITS /*leave-this-comment*/
