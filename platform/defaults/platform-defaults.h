
#ifndef PERL__platform_defaults__H
#	define PERL__platform_defaults__H

#	ifndef PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS
#		if defined(Direntry_t) && defined(HAS_READDIR)
#			define PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS 1
#		else
#			define PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS 0
#		endif
#	endif

#endif
