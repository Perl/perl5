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
# include <eikdialg.h>
#endif /* #ifdef __SERIES60__ */

#include <coecntrl.h>
#include <f32file.h>

/* The source code can be compiled into "PerlApp" which is the simple
 * launchpad application/demonstrator, or into "PerlAppMinimal", which
 * is the minimal Perl launchpad application.  Define the cpp symbols
 * CreatePerlAppMinimal (a boolean), PerlAppMinimalUid (the Symbian
 * application uid in the 0x... format), and PerlAppMinimalName (a C
 * wide string, with the L prefix) to compile as "PerlAppMinimal". */

// #define CreatePerlAppMinimal

#ifdef CreatePerlAppMinimal
# define PerlAppMinimal
# ifndef PerlAppMinimalUid // PerlApp is ...F6, PerlRecog is ...F7
#  define PerlAppMinimalUid 0x102015F8
# endif
# ifndef PerlAppMinimalName
#  define PerlAppMinimalName L"PerlAppMinimal"
# endif
#endif

#ifdef PerlAppMinimal
# ifndef PerlAppMinimalUid
#   error PerlAppMinimal defined but PerlAppMinimalUid undefined
# endif
# ifndef PerlAppMinimalName
#  error PerlAppMinimal defined but PerlAppMinimalName undefined
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
#ifndef PerlAppMinimal
    CFileStore* OpenFileL(TBool aDoOpen, const TDesC& aFilename, RFs& aFs);
#endif // #ifndef PerlAppMinimal
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
#ifndef PerlAppMinimal
    void OpenFileL(const TDesC& aFileName);
    void InstallOrRunL(const TFileName& aFileName);
    void SetFs(const RFs& aFs);
#endif // #ifndef PerlAppMinimal
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

#ifdef __SERIES80__

class CPerlAppTextQueryDialog : public CEikDialog
{
  public:
    CPerlAppTextQueryDialog(HBufC*& aBuffer);
    /* TODO: OfferKeyEventL() so that newline can be seen as 'OK'. */
    HBufC*& iData;
    TPtrC iTitle;  // used in S80 but not in S60
    TPtrC iPrompt; // used in S60 and S80
    TInt iMaxLength;
  protected:
    void PreLayoutDynInitL();
  private:
    TBool OkToExitL(TInt aKeycode);
};

#endif /* #ifdef __SERIES80__ */

#endif // __PerlApp_h__
