
#ifndef PERL__platforms__H
#	define PERL__platforms__H

/* Intended usage:
 * - all platform specific includes will be included here
 * - platform specific include is responsible for detecting it's platform
 *
 * Example:
 * #include "platform/amigaos4/platform-amigaos4.h"
 * #include "platform/amigaos4/platform-defaults.h"
 *
 * where platform-amigaos4.h will contain:
 * #if defined(__amigaos4__) && ! defined(__guard__)
 *
 * Platform specific include will define platform specific implementations
 * of certain steps.
 *
 * platform-defaults.h will define default behaviour of platform specific steps
 */

#include "../platform/defaults/platform-defaults.h"

#endif
