
#ifndef PERL__platform_defaults__H
#	define PERL__platform_defaults__H

#	ifndef PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS
#		if defined(Direntry_t) && defined(HAS_READDIR)
#			define PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS 1
#		else
#			define PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS 0
#		endif
#	endif

#	define PERL_PLATFORM_closedir_default     "pp/closedir_default.inc"
#	define PERL_PLATFORM_open_dir_default     "pp/open_dir_default.inc"
#	define PERL_PLATFORM_readdir_default      "pp/readdir_default.inc"

#	define PERL_PLATFORM_closedir_unavailable "pp/closedir_unavailable.inc"
#	define PERL_PLATFORM_open_dir_unavailable "pp/open_dir_unavailable.inc"
#	define PERL_PLATFORM_readdir_unavailable  "pp/readdir_unavailable.inc"

/* dir handle functions */
#	if PERL_PLATFORM_HAS_DIR_HANDLE_FUNCTIONS
#		define PERL_PLATFORM_closedir PERL_PLATFORM_closedir_default
#		define PERL_PLATFORM_open_dir PERL_PLATFORM_open_dir_default
#		define PERL_PLATFORM_readdir  PERL_PLATFORM_readdir_default
#	else
#		define PERL_PLATFORM_closedir PERL_PLATFORM_closedir_unavailable
#		define PERL_PLATFORM_open_dir PERL_PLATFORM_open_dir_unavailable
#		define PERL_PLATFORM_readdir  PERL_PLATFORM_readdir_unavailable
#	endif

#endif
