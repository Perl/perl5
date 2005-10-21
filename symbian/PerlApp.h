/* Copyright (c) 2004-2005 Nokia. All rights reserved. */

/* The PerlApp application is licensed under the same terms as Perl itself. */

#ifndef __PerlApp_h__
#define __PerlApp_h__

#ifdef __SERIES60__
# include <aknapp.h>
# include <aknappui.h>
# include <akndoc.h>
#endif /* #ifdef __SERIES60__ */

#ifdef __SERIES80__
# include <eikapp.h>
# include <eikappui.h>
# include <eikdoc.h>
# include <eikbctrl.h>
# include <eikgted.h>
#endif /* #ifdef __SERIES60__ */

#include <coecntrl.h>
#include <f32file.h>

/* The source code can be compiled into "PerlApp" which is the simple
 * launchpad application/demonstrator, or into "PerlMin", which is the
 * minimal Perl launchpad application.  Define the cpp symbols
 * PerlMin (a boolean), PerlMinUid (the Symbian application uid in
 * the 0x... format), and PerlMinName (a C wide string, with the L prefix)
 * to compile as "PerlMin". */

#define PerlMinSample

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

#ifdef __SERIES60__
# define CMyDocument    CAknDocument
# define CMyApplication CAknApplication
# define CMyAppUi       CAknAppUi
# define CMyNoteDialog  CAknNoteDialog
# define CMyAppView     CCoeControl
#endif /* #ifdef __SERIES60__ */

#ifdef __SERIES80__
# define CMyDocument    CEikDocument
# define CMyApplication CEikApplication
# define CMyAppUi       CEikAppUi
# define CMyNoteDialog  CCknFlashingDialog
# define CMyAppView     CEikBorderedControl
#endif /* #ifdef __SERIES60__ */

class CPerlAppDocument : public CMyDocument
{
  public:
    CPerlAppDocument(CEikApplication& aApp):CMyDocument(aApp) {;}
#ifndef PerlMin
    CFileStore* OpenFileL(TBool aDoOpen, const TDesC& aFilename, RFs& aFs);
#endif // #ifndef PerlMin
  private: // from CEikDocument
    CEikAppUi* CreateAppUiL();
};

class CPerlAppApplication : public CMyApplication
{
  private:
    CApaDocument* CreateDocumentL();
    TUid AppDllUid() const;
};

const TUint KPerlAppPromptSize   = 20;
const TUint KPerlAppOneLinerSize = 128;

class CPerlAppView;

class CPerlAppUi : public CMyAppUi
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
    TBuf<KPerlAppOneLinerSize> iOneLiner; // Perl source code to evaluate.
    CPerlAppView* iAppView;
  private:
    RFs* iFs;
};

class CPerlAppView : public CMyAppView
{
  public:
    static CPerlAppView* NewL(const TRect& aRect);
    static CPerlAppView* NewLC(const TRect& aRect);
    ~CPerlAppView();
    void Draw(const TRect& aRect) const;
#ifdef __SERIES80__
    void HandleCommandL(TInt aCommand);
#endif /* #ifdef __SERIES80__ */
  private:
    void ConstructL(const TRect& aRect);
};

#endif // __PerlApp_h__
