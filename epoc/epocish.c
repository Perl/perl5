/*
 *    Copyright (c) 1999 Olaf Flebbe o.flebbe@gmx.de
 *    
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/* This is C++ Code !! */

#include <e32std.h>

extern "C" { 

epoc_spawn( char *cmd, char *cmdline) {
  RProcess p;
  TRequestStatus status;
  TInt rc;

  rc = p.Create( _L( cmd), _L( cmdline));
  if (rc != KErrNone)
    return -1;

  p.Resume();
  
  p.Logon( status);
  User::WaitForRequest( status);
  if (status!=KErrNone) {
    return -1;
  }
  return 0;
}


  /* Workaround for defect atof(), see java defect list for epoc */
  double epoc_atof( char* str) {
    TReal64 aRes;
    
    while (TChar( *str).IsSpace()) {
      str++;
    }

    TLex lex( _L( str));
    TInt err = lex.Val( aRes, TChar( '.'));
    return aRes;
  }

  void epoc_gcvt( double x, int digits, unsigned char *buf) {
    TRealFormat trel;

    trel.iPlaces = digits;
    trel.iPoint = TChar( '.');

    TPtr result( buf, 80);

    result.Num( x, trel);
    result.Append( TChar( 0));
  }
}
