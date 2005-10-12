/* Copyright (c) 2004-2005 Nokia. All rights reserved. */

/* The PerlApp application is licensed under the same terms as Perl itself. */

#ifndef __PerlApp_h__
#define __PerlApp_h__

#include <aknapp.h>
#include <aknappui.h>
#include <akndoc.h>
#include <coecntrl.h>
#include <f32file.h>

/* The source code can be compiled into "PerlApp" which is the simple
 * launchpad application/demonstrator, or into "PerlMin", which is the
 * minimal Perl-on-Series-60 application.  Define the cpp symbols
 * PerlMin (a boolean), PerlMinUid (the Symbian application uid in
 * the 0x... format), and PerlMinName (a C wide string, with the L prefix)
 * to compile as "PerlMin". */

// #define PerlMinSample

#ifdef PerlMinSample
# define PerlMin
# define PerlMinUid 0x102015F6
# define PerlMinName L"PerlMin"
#endif

#ifdef PerlMin
# ifndef PerlMinUid
#   error PerlMin defined but PerlMinUid undefined
# endif
# ifndef PerlMinName
#  error PerlMin defined but PerlMinName undefined
# endif
#endif

class CPerlAppDocument : public CAknDocument
{
  public:
    CPerlAppDocument(CEikApplication& aApp):CAknDocument(aApp) {;}
#ifndef PerlMin
    CFileStore* OpenFileL(TBool aDoOpen, const TDesC& aFilename, RFs& aFs);
#endif // #ifndef PerlMin
  private: // from CEikDocument
    CEikAppUi* CreateAppUiL();
};

class CPerlAppApplication : public CAknApplication
{
  private:
    CApaDocument* CreateDocumentL();
    TUid AppDllUid() const;
};

const TUint KPerlAppOneLinerSize = 80;

class CPerlAppView;

class CPerlAppUi : public CAknAppUi
{
  public:
    void ConstructL();
     ~CPerlAppUi();
    TBool ProcessCommandParametersL(TApaCommand aCommand, TFileName& aDocumentName, const TDesC8& aTail);
    void HandleCommandL(TInt aCommand);
#ifndef PerlMin
    void OpenFileL(const TDesC& aFileName);
    void InstallOrRunL(const TFileName& aFileName);
    void SetFs(const RFs& aFs);
#endif // #ifndef PerlMin
  private:
    CPerlAppView* iAppView;
    RFs* iFs;
    TBuf<KPerlAppOneLinerSize> iOneLiner;
};

class CPerlAppView : public CCoeControl
{
  public:
    static CPerlAppView* NewL(const TRect& aRect);
    static CPerlAppView* NewLC(const TRect& aRect);
    void Draw(const TRect& aRect) const;
  private:
    void ConstructL(const TRect& aRect);
};

#endif // __PerlApp_h__
