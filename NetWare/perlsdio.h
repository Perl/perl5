--- perlsdio.h.old	Sat Jun 30 14:42:22 2001
+++ perlsdio.h	Sat Jun 30 14:59:49 2001
@@ -1,4 +1,9 @@
 #ifdef PERLIO_IS_STDIO
+
+#ifdef NETWARE
+	#include "nwstdio.h"
+#else
+
 /*
  * This file #define-s the PerlIO_xxx abstraction onto stdio functions.
  * Make this as close to original stdio as possible.
@@ -136,4 +141,5 @@
 #define PerlIO_get_bufsiz(f)		(abort(),0)
 #endif
 
+#endif	/* NETWARE */
 #endif /* PERLIO_IS_STDIO */
