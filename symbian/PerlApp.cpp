/* Copyright (c) 2004-2005 Nokia. All rights reserved. */

/* The PerlApp application is licensed under the same terms as Perl itself.
 * Note that this PerlApp is for Symbian/Series 60/80 smartphones and it has
 * nothing whatsoever to do with the ActiveState PerlApp. */

#include "PerlApp.h"

#ifdef __SERIES60__
# include <avkon.hrh>
# include <aknnotewrappers.h> 
# include <AknCommonDialogs.h>
# ifndef __SERIES60_1X__
#  include <CAknFileSelectionDialog.h>
# endif
#endif /* #ifdef __SERIES60__ */

#ifdef __SERIES80__
# include <eikon.hrh>
# include <cknflash.h>
# include <ckndgopn.h>
#endif /* #ifdef __SERIES80__ */

#include <apparc.h>
#include <e32base.h>
#include <e32cons.h>
#include <eikenv.h>
#include <bautils.h>
#include <eikappui.h>
#include <utf.h>
#include <f32file.h>

#include <coemain.h>

#ifndef PerlMin

#include "PerlApp.hrh"

#include "PerlApp.rsg"

#endif //#ifndef PerlMin

#include "EXTERN.h"
#include "perl.h"
#include "PerlBase.h"

const TUid KPerlAppUid = {
#ifdef PerlMinUid
  PerlMinUid
#else
  0x102015F6
#endif
};

_LIT(KDefaultScript, "default.pl");

// This is like the Symbian _LIT() but without the embedded L prefix,
// which enables using #defined constants (which need to carry their
// own L prefix).
#ifndef _LIT_NO_L
# define _LIT_NO_L(n, s) static const TLitC<sizeof(s)/2> n={sizeof(s)/2-1,s}
#endif // #ifndef _LIT_NO_L

#ifdef PerlMinName
_LIT_NO_L(KAppName, PerlMinName);
#else
_LIT(KAppName, "PerlApp");
#endif

#ifndef PerlMin

_LIT_NO_L(KFlavor, PERL_SYMBIANSDK_FLAVOR);
_LIT(KAboutFormat,
     "Perl %d.%d.%d, Symbian port %d.%d.%d, built for %S SDK %d.%d");
_LIT(KCopyrightFormat,
     "Copyright 1987-2005 Larry Wall and others, Symbian port Copyright Nokia 2004-2005");
_LIT(KInboxPrefix, "\\System\\Mail\\");
_LIT(KScriptPrefix, "\\Perl\\");

_LIT8(KModulePrefix, SITELIB); // SITELIB from Perl config.h

typedef TBuf<256>  TMessageBuffer;
typedef TBuf8<256> TPeekBuffer;
typedef TBuf8<256> TFileName8;

#endif // #ifndef PerlMin

// Usage: DEBUG_PRINTF((_L("%S"), &aStr))
#if 1
#define DEBUG_PRINTF(s) {TMessageBuffer message; message.Format s; YesNoDialogL(message);}
#endif

static void DoRunScriptL(TFileName aScriptName);

TUid CPerlAppApplication::AppDllUid() const
{
    return KPerlAppUid;
}

enum TPerlAppPanic 
{
    EPerlAppCommandUnknown = 1
};

void Panic(TPerlAppPanic aReason)
{
    User::Panic(KAppName, aReason);
}

void CPerlAppUi::ConstructL()
{
    BaseConstructL();
    iAppView = CPerlAppView::NewL(ClientRect());
    AddToStackL(iAppView);
    iFs = NULL;
    CEikonEnv::Static()->DisableExitChecks(ETrue); // Symbian FAQ-0577.
}

CPerlAppUi::~CPerlAppUi()
{
    if (iAppView) {
        iEikonEnv->RemoveFromStack(iAppView);
        delete iAppView;
        iAppView = NULL;
    }
    if (iFs) {
        delete iFs;
        iFs = NULL;
    }
    if (iDoorObserver) // Otherwise the embedding application waits forever.
        iDoorObserver->NotifyExit(MApaEmbeddedDocObserver::EEmpty);
}

#ifndef PerlMin

#ifdef __SERIES60__

static TBool DlgOk(CAknNoteDialog* dlg)
{
    return dlg && dlg->RunDlgLD() == EAknSoftkeyOk;
}

#endif /* #ifdef __SERIES60__ */

static TBool OkCancelDialogL(TDesC& aMessage)
{
#ifdef __SERIES60__
    CAknNoteDialog* dlg =
        new (ELeave) CAknNoteDialog(CAknNoteDialog::EConfirmationTone);
    dlg->PrepareLC(R_OK_CANCEL_DIALOG);
    dlg->SetTextL(aMessage);
    return DlgOk(dlg);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    return CCknFlashingDialog::RunDlgLD(_L("OK/Cancel"), aMessage, NULL,
                                        CCknFlashingDialog::EShort,
                                        NULL);
#endif /* #ifdef __SERIES80__ */
}

static TBool YesNoDialogL(TDesC& aMessage)
{
#ifdef __SERIES60__
    CAknNoteDialog* dlg =
        new (ELeave) CAknNoteDialog(CAknNoteDialog::EConfirmationTone);
    dlg->PrepareLC(R_YES_NO_DIALOG);
    dlg->SetTextL(aMessage);
    return DlgOk(dlg);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    return CCknFlashingDialog::RunDlgLD(_L("Yes/No"), aMessage, NULL,
                                        CCknFlashingDialog::EShort,
                                        NULL);
#endif /* #ifdef __SERIES80__ */
}

static TInt InformationNoteL(TDesC& aMessage)
{
#ifdef __SERIES60__
    CAknInformationNote* note = new (ELeave) CAknInformationNote;
    return note->ExecuteLD(aMessage);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    return CCknFlashingDialog::RunDlgLD(_L("Info"), aMessage, NULL,
                                        CCknFlashingDialog::ENormal,
                                        NULL);
#endif /* #ifdef __SERIES80__ */
}

static TInt ConfirmationNoteL(TDesC& aMessage)
{
#ifdef __SERIES60__
    CAknConfirmationNote* note = new (ELeave) CAknConfirmationNote;
    return note->ExecuteLD(aMessage);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    return CCknFlashingDialog::RunDlgLD(_L("Confirmation"), aMessage, NULL,
                                        CCknFlashingDialog::ENormal,
                                        NULL);
#endif /* #ifdef __SERIES80__ */
}

static TInt WarningNoteL(TDesC& aMessage)
{
#ifdef __SERIES60__
    CAknWarningNote* note = new (ELeave) CAknWarningNote;
    return note->ExecuteLD(aMessage);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    CEikonEnv::Static()->AlertWin(aMessage);
    return ETrue;
#endif /* #ifdef __SERIES80__ */
}

static TInt TextQueryDialogL(const TDesC& aPrompt, TDes& aData, const TInt aMaxLength)
{
#ifdef __SERIES60__
    CAknTextQueryDialog* dlg =
        new (ELeave) CAknTextQueryDialog(aData);
    dlg->SetPromptL(aPrompt);
    dlg->SetMaxLength(aMaxLength);
    return dlg->ExecuteLD(R_TEXT_QUERY_DIALOG);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
    /* TODO */
    return ETrue;
#endif
}

// The isXXX() come from the Perl headers.
#define FILENAME_IS_ABSOLUTE(n) \
        (isALPHA(((n)[0])) && ((n)[1]) == ':' && ((n)[2]) == '\\')

static TBool IsInPerl(TFileName aFileName)
{
    TInt offset = aFileName.FindF(KScriptPrefix);
    return ((offset == 0 && // \foo
             aFileName[0] == '\\')
            ||
            (offset == 2 && // x:\foo
             FILENAME_IS_ABSOLUTE(aFileName)));
}

static TBool IsInInbox(TFileName aFileName)
{
    TInt offset = aFileName.FindF(KInboxPrefix);
    return ((offset == 0 && // \foo
             aFileName[0] == '\\')
            ||
            (offset == 2 && // x:\foo
             FILENAME_IS_ABSOLUTE(aFileName)));
}

static TBool IsPerlModule(TParsePtrC aParsed)
{
    return aParsed.Ext().CompareF(_L(".pm")) == 0; 
}

static TBool IsPerlScript(TParsePtrC aParsed)
{
    return aParsed.Ext().CompareF(_L(".pl")) == 0; 
}

static void CopyFromInboxL(RFs aFs, const TFileName& aSrc, const TFileName& aDst)
{
    TBool proceed = ETrue;
    TMessageBuffer message;

    message.Format(_L("%S is untrusted. Install only if you trust provider."), &aDst);
    if (OkCancelDialogL(message)) {
        message.Format(_L("Install as %S?"), &aDst);
        if (OkCancelDialogL(message)) {
            if (BaflUtils::FileExists(aFs, aDst)) {
                message.Format(_L("Replace old %S?"), &aDst);
                if (!OkCancelDialogL(message))
                    proceed = EFalse;
            }
            if (proceed) {
                // Create directory?
                TInt err = BaflUtils::CopyFile(aFs, aSrc, aDst);
                if (err == KErrNone) {
                    message.Format(_L("Installed %S"), &aDst);
                    ConfirmationNoteL(message);
                }
                else {
                    message.Format(_L("Failure %d installing %S"), err, &aDst);
                    WarningNoteL(message);
                }
            }
        }
    }
}

static TBool FindPerlPackageName(TPeekBuffer aPeekBuffer, TInt aOff, TFileName& aFn)
{
    aFn.SetMax();
    TInt m = aFn.MaxLength();
    TInt n = aPeekBuffer.Length();
    TInt i = 0;
    TInt j = aOff;

    aFn.SetMax();
    // The following is a little regular expression
    // engine that matches Perl package names.
    if (j < n && isSPACE(aPeekBuffer[j])) {
        while (j < n && isSPACE(aPeekBuffer[j])) j++;
        if (j < n && isALPHA(aPeekBuffer[j])) {
            while (j < n && isALNUM(aPeekBuffer[j])) {
                while (j < n &&
                       isALNUM(aPeekBuffer[j]) &&
                       i < m)
                    aFn[i++] = aPeekBuffer[j++];
                if (j + 1 < n &&
                    aPeekBuffer[j    ] == ':' &&
                    aPeekBuffer[j + 1] == ':' &&
                    i < m) {
                    aFn[i++] = '\\';
                    j += 2;
                    if (j < n &&
                        isALPHA(aPeekBuffer[j])) {
                        while (j < n &&
                               isALNUM(aPeekBuffer[j]) &&
                               i < m) 
                            aFn[i++] = aPeekBuffer[j++];
                    }
                }
            }
            while (j < n && isSPACE(aPeekBuffer[j])) j++;
            if (j < n && aPeekBuffer[j] == ';' && i + 3 < m) {
                aFn.SetLength(i);
                aFn.Append(_L(".pm"));
                return ETrue;
            }
        }
    }
    return EFalse;
}

static void GuessPerlModule(TFileName& aGuess, TPeekBuffer aPeekBuffer, TParse aDrive)
{
   TInt offset = aPeekBuffer.Find(_L8("package"));
   if (offset != KErrNotFound) {
       const TInt KPackageLen = 7;
       TFileName q;

       if (!FindPerlPackageName(aPeekBuffer, offset + KPackageLen, q))
           return;

       TFileName8 p;
       p.Copy(aDrive.Drive());
       p.Append(KModulePrefix);

       aGuess.SetMax();
       if (p.Length() + 1 + q.Length() < aGuess.MaxLength()) {
           TInt i = 0, j;

           for (j = 0; j < p.Length(); j++)
               aGuess[i++] = p[j];
           aGuess[i++] = '\\';
           for (j = 0; j < q.Length(); j++)
               aGuess[i++] = q[j];
           aGuess.SetLength(i);
       }
       else
           aGuess.SetLength(0);
   }
}

static TBool LooksLikePerlL(TPeekBuffer aPeekBuffer)
{
    return aPeekBuffer.Left(2).Compare(_L8("#!")) == 0 &&
           aPeekBuffer.Find(_L8("perl")) != KErrNotFound;
}

static TBool InstallStuffL(const TFileName &aSrc, TParse aDrive, TParse aFile, TPeekBuffer aPeekBuffer, RFs aFs)
{
    TFileName aDst;
    TPtrC drive  = aDrive.Drive();
    TPtrC namext = aFile.NameAndExt(); 

    aDst.Format(_L("%S%S%S"), &drive, &KScriptPrefix, &namext);
    if (!IsPerlScript(aDst) && !LooksLikePerlL(aPeekBuffer)) {
        aDst.SetLength(0);
        if (IsPerlModule(aDst))
            GuessPerlModule(aDst, aPeekBuffer, aDrive);
    }
    if (aDst.Length() > 0) {
        CopyFromInboxL(aFs, aSrc, aDst);
        return ETrue;
    }

    return EFalse;
}

static TBool RunStuffL(const TFileName& aScriptName, TPeekBuffer aPeekBuffer)
{
    TBool isModule = EFalse;

    if (IsInPerl(aScriptName) &&
        (IsPerlScript(aScriptName) ||
         (isModule = IsPerlModule(aScriptName)) ||
         LooksLikePerlL(aPeekBuffer))) {
        TMessageBuffer message;

        if (isModule)
            message.Format(_L("Really run module %S?"), &aScriptName);
        else 
            message.Format(_L("Run %S?"), &aScriptName);
        if (YesNoDialogL(message))
            DoRunScriptL(aScriptName);

        return ETrue;
    }

    return EFalse;
}

void CPerlAppUi::InstallOrRunL(const TFileName& aFileName)
{
    TParse aFile;
    TParse aDrive;
    TMessageBuffer message;

    aFile.Set(aFileName, NULL, NULL);
    if (FILENAME_IS_ABSOLUTE(aFileName)) {
        aDrive.Set(aFileName, NULL, NULL);
    } else {
        TFileName appName =
          CEikonEnv::Static()->EikAppUi()->Application()->AppFullName();
        aDrive.Set(appName, NULL, NULL);
    }
    if (!iFs)
        iFs = &CEikonEnv::Static()->FsSession();
    RFile f;
    TInt err = f.Open(*iFs, aFileName, EFileRead);
    if (err == KErrNone) {
        TPeekBuffer aPeekBuffer;
        err = f.Read(aPeekBuffer);
        f.Close();  // Release quickly.
        if (err == KErrNone) {
            if (!(IsInInbox(aFileName) ?
                  InstallStuffL(aFileName, aDrive, aFile, aPeekBuffer, *iFs) :
                  RunStuffL(aFileName, aPeekBuffer))) {
                message.Format(_L("Failed for file %S"), &aFileName);
                WarningNoteL(message);
            }
        } else {
            message.Format(_L("Error %d reading %S"), err, &aFileName);
            WarningNoteL(message);
        }
    } else {
        message.Format(_L("Error %d opening %S"), err, &aFileName);
        WarningNoteL(message);
    }
    if (iDoorObserver)
        delete CEikonEnv::Static()->EikAppUi();
    else
        Exit();
}

#endif // #ifndef PerlMin

static void DoRunScriptL(TFileName aScriptName)
{
    CPerlBase* perl = CPerlBase::NewInterpreterLC();
    TRAPD(error, perl->RunScriptL(aScriptName));
#ifndef PerlMin
    if (error != KErrNone) {
        TMessageBuffer message;
        message.Format(_L("Error %d"), error);
        YesNoDialogL(message);
    }
#endif // #ifndef PerlMin
    CleanupStack::PopAndDestroy(perl);
}

#ifndef PerlMin

void CPerlAppUi::OpenFileL(const TDesC& aFileName)
{
    InstallOrRunL(aFileName);
    return;
}

#endif // #ifndef PerlMin

TBool CPerlAppUi::ProcessCommandParametersL(TApaCommand aCommand, TFileName& /* aDocumentName */, const TDesC8& /* aTail */)
{
    if (aCommand == EApaCommandRun) {
        TFileName appName = Application()->AppFullName();
        TParse p;
        p.Set(KDefaultScript, &appName, NULL);
        TEntry aEntry;
        RFs aFs;
        aFs.Connect();
        if (aFs.Entry(p.FullName(), aEntry) == KErrNone) {
            DoRunScriptL(p.FullName());
            Exit();
        }
    }
    return aCommand == EApaCommandOpen ? ETrue : EFalse;
}

#ifndef PerlMin

void CPerlAppUi::SetFs(const RFs& aFs)
{
    iFs = (RFs*) &aFs;
}

#endif // #ifndef PerlMin

static void DoHandleCommandL(TInt aCommand) {
#ifndef PerlMin
    TMessageBuffer message;
#endif // #ifndef PerlMin

    switch(aCommand)
    {
#ifndef PerlMin
    case EPerlAppCommandAbout:
        {
            message.Format(KAboutFormat,
                           PERL_REVISION,
                           PERL_VERSION,
                           PERL_SUBVERSION,
                           PERL_SYMBIANPORT_MAJOR,
                           PERL_SYMBIANPORT_MINOR,
                           PERL_SYMBIANPORT_PATCH,
                           &KFlavor,
                           PERL_SYMBIANSDK_MAJOR,
                           PERL_SYMBIANSDK_MINOR
                           );
            InformationNoteL(message);
        }
        break;
    case EPerlAppCommandTime:
        {
            CPerlBase* perl = CPerlBase::NewInterpreterLC();
            const char *const argv[] =
              { "perl", "-le",
                "print 'Running in ', $^O, \"\\n\", scalar localtime" };
            perl->ParseAndRun(sizeof(argv)/sizeof(char*), (char **)argv, 0);
            CleanupStack::PopAndDestroy(perl);
        }
        break;
     case EPerlAppCommandRunFile:
        {
            TFileName aScriptUtf16;
#ifdef __SERIES60__
            if (AknCommonDialogs::RunSelectDlgLD(aScriptUtf16,
                                                 R_MEMORY_SELECTION_DIALOG))
                DoRunScriptL(aScriptUtf16);
#endif /* #ifdef __SERIES60__ */
#ifdef __SERIES80__
	    aScriptUtf16.Copy(_L("C:\\"));
	    if (CCknOpenFileDialog::RunDlgLD(aScriptUtf16,
		CCknOpenFileDialog::EShowSystemFilesAndFolders |
		CCknOpenFileDialog::EShowHiddenFilesAndFolders |
		CCknOpenFileDialog::EShowAllDrives             |
		CCknOpenFileDialog::EShowExtendedView          |
		CCknOpenFileDialog::EShowNoFilesText) {
	      /* TODO: despite all the above flags still does not seem
	       * to allow navigating outside the default directory. */
	      TEntry aEntry;
	      RFs aFs;
	      aFs.Connect();
	      if (aFs.Entry(aScriptUtf16, aEntry) == KErrNone)
                DoRunScriptL(aScriptUtf16);
	      /* else show error message? */
	    }
#endif /* #ifdef __SERIES80__ */
	}
        break;
     case EPerlAppCommandOneLiner:
        {
            _LIT(prompt, "Oneliner:");
            CPerlAppUi* cAppUi =
              STATIC_CAST(CPerlAppUi*, CEikonEnv::Static()->EikAppUi());
            if (TextQueryDialogL(prompt,
				 cAppUi->iOneLiner,
                                 KPerlAppOneLinerSize)) {
               const TUint KPerlAppUtf8Multi = 3;
                TBuf8<KPerlAppUtf8Multi * KPerlAppOneLinerSize> utf8;

                CnvUtfConverter::ConvertFromUnicodeToUtf8(utf8, cAppUi->iOneLiner);
                CPerlBase* perl = CPerlBase::NewInterpreterLC();
                int argc = 3;
                char **argv = (char**) malloc(argc * sizeof(char *));
                User::LeaveIfNull(argv);

                TCleanupItem argvCleanupItem = TCleanupItem(free, argv);
                CleanupStack::PushL(argvCleanupItem);
                argv[0] = (char *) "perl";
                argv[1] = (char *) "-le";
                argv[2] = (char *) utf8.PtrZ();
                perl->ParseAndRun(argc, argv);
                CleanupStack::PopAndDestroy(2, perl);
            }
        }
        break;
     case EPerlAppCommandCopyright:
        {
            message.Format(KCopyrightFormat);
            InformationNoteL(message);
        }
        break;
     case EPerlAppCommandAboutCopyright:
        {
	    TMessageBuffer m1;
	    TMessageBuffer m2;
            m1.Format(KAboutFormat,
		      PERL_REVISION,
		      PERL_VERSION,
		      PERL_SUBVERSION,
		      PERL_SYMBIANPORT_MAJOR,
		      PERL_SYMBIANPORT_MINOR,
		      PERL_SYMBIANPORT_PATCH,
		      &KFlavor,
		      PERL_SYMBIANSDK_MAJOR,
		      PERL_SYMBIANSDK_MINOR
		      );
            InformationNoteL(message);
            m2.Format(KCopyrightFormat);
	    message.Format(_L("%S %S"), &m1, &m2);
            InformationNoteL(message);
        }
        break;
#endif // #ifndef PerlMin
    default:
        Panic(EPerlAppCommandUnknown);
    }
}

#ifdef __SERIES60__

void CPerlAppUi::HandleCommandL(TInt aCommand)
{
    switch(aCommand)
    {
    case EEikCmdExit:
    case EAknSoftkeyExit:
        Exit();
        break;
    default:
        DoHandleCommandL(aCommand);
        break;
    }
}

#endif /* #ifdef __SERIES60__ */

#ifdef __SERIES80__

void CPerlAppView::HandleCommandL(TInt aCommand) {
    DoHandleCommandL(aCommand);
}

void CPerlAppUi::HandleCommandL(TInt aCommand) {
    switch(aCommand)
    {
    case EEikCmdExit:
        Exit();
        break;
    default:
        iAppView->HandleCommandL(aCommand);
        break;
    }
}

#endif /* #ifdef __SERIES80__ */

CPerlAppView* CPerlAppView::NewL(const TRect& aRect)
{
    CPerlAppView* self = CPerlAppView::NewLC(aRect);
    CleanupStack::Pop(self);
    return self;
}

CPerlAppView* CPerlAppView::NewLC(const TRect& aRect)
{
    CPerlAppView* self = new (ELeave) CPerlAppView;
    CleanupStack::PushL(self);
    self->ConstructL(aRect);
    return self;
}

void CPerlAppView::ConstructL(const TRect& aRect)
{
    CreateWindowL();
    SetRect(aRect);
    ActivateL();
}

CPerlAppView::~CPerlAppView()
{
}

void CPerlAppView::Draw(const TRect& /*aRect*/) const
{
    CWindowGc& gc = SystemGc();
    TRect rect = Rect();
    gc.Clear(rect);
}

CApaDocument* CPerlAppApplication::CreateDocumentL() 
{
    CPerlAppDocument* document = new (ELeave) CPerlAppDocument(*this);
    return document;
}

CEikAppUi* CPerlAppDocument::CreateAppUiL()
{
    CPerlAppUi* appui = new (ELeave) CPerlAppUi();
    return appui;
}


#ifndef PerlMin

CFileStore* CPerlAppDocument::OpenFileL(TBool aDoOpen, const TDesC& aFileName, RFs& aFs)
{
    CPerlAppUi* appui =
      STATIC_CAST(CPerlAppUi*, CEikonEnv::Static()->EikAppUi());
    appui->SetFs(aFs);
    if (aDoOpen)
        appui->OpenFileL(aFileName);
    return NULL;
}

#endif // #ifndef PerlMin

EXPORT_C CApaApplication* NewApplication() 
{
    return new CPerlAppApplication;
}

GLDEF_C TInt E32Dll(TDllReason /*aReason*/)
{
    return KErrNone;
}

