/* VMS::stdio - VMS extensions to stdio routines 
 *
 * Version:  1.1
 * Author:   Charles Bailey  bailey@genetics.upenn.edu
 * Revised:  09-Mar-1995
 *
 *
 * Revision History:
 * 
 * 1.0  29-Nov-1994  Charles Bailey  bailey@genetics.upenn.edu
 *      original version - vmsfopen
 * 1.1  09-Mar-1995  Charles Bailey  bailey@genetics.upenn.edu
 *      changed calling sequence to return FH/undef - like POSIX::open
 *      added fgetname and tmpnam
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Use type for FILE * from Perl's XSUB typemap.  This is a bit
 * of a hack, since all Perl filehandles using this type will permit
 * both read & write operations, but it saves having to write the PPCODE
 * directly for updating the Perl filehandles.
 */
typedef FILE * InOutStream;

MODULE = VMS::stdio  PACKAGE = VMS::stdio

void
vmsfopen(name,...)
	char *	name
	CODE:
	    char *args[8],mode[5] = {'r','\0','\0','\0','\0'}, c;
	    register int i, myargc;
	    FILE *fp;
	    if (items > 9) {
	      croak("File::VMSfopen::vmsfopen - too many args");
	    }
	    /* First, set up name and mode args from perl's string */
	    if (*name == '+') {
	      mode[1] = '+';
	      name++;
	    }
	    if (*name == '>') {
	      if (*(name+1) == '>') *mode = 'a', name += 2;
	      else *mode = 'w',  name++;
	    }
	    else if (*name == '<') name++;
	    myargc = items - 1;
	    for (i = 0; i < myargc; i++) args[i] = SvPV(ST(i+1),na);
	    /* This hack brought to you by C's opaque arglist management */
	    switch (myargc) {
	      case 0:
	        fp = fopen(name,mode);
	        break;
	      case 1:
	        fp = fopen(name,mode,args[0]);
	        break;
	      case 2:
	        fp = fopen(name,mode,args[0],args[1]);
	        break;
	      case 3:
	        fp = fopen(name,mode,args[0],args[1],args[2]);
	        break;
	      case 4:
	        fp = fopen(name,mode,args[0],args[1],args[2],args[3]);
	        break;
	      case 5:
	        fp = fopen(name,mode,args[0],args[1],args[2],args[3],args[4]);
	        break;
	      case 6:
	        fp = fopen(name,mode,args[0],args[1],args[2],args[3],args[4],args[5]);
	        break;
	      case 7:
	        fp = fopen(name,mode,args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
	        break;
	      case 8:
	        fp = fopen(name,mode,args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
	        break;
	    }
	    ST(0) = sv_newmortal();
	    if (fp != NULL) {
	       GV *gv = newGVgen("VMS::stdio");
               c = mode[0]; name = mode;
               if (mode[1])  *(name++) = '+';
               if (c == 'r') *(name++) = '<';
               else {
                 *(name++) = '>';
                 if (c == 'a') *(name++) = '>';
               }
               *(name++) = '&';
	       if (do_open(gv,mode,name - mode,FALSE,0,0,fp))
	         sv_setsv(ST(0),newRV((SV*)gv));
	    }

char *
fgetname(fp)
	FILE *	fp
	CODE:
	  char fname[257];
	  ST(0) = sv_newmortal();
	  if (fgetname(fp,fname) != NULL) sv_setpv(ST(0),fname);

char *
tmpnam()
	CODE:
	  char fname[L_tmpnam];
	  ST(0) = sv_newmortal();
	  if (tmpnam(fname) != NULL) sv_setpv(ST(0),fname);
