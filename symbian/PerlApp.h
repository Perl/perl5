/* Copyright (c) 2004-2005 Nokia. All rights reserved. */

/* The PerlApp application is licensed under the same terms as Perl itself. */

#ifndef __PerlApp_h__
#define __PerlApp_h__

#include <aknapp.h>
#include <aknappui.h>
#include <akndoc.h>
#include <coecntrl.h>
#include <f32file.h>

class CPerlAppDocument : public CAknDocument
{
  public:
    CPerlAppDocument(CEikApplication& aApp):CAknDocument(aApp) {;}
    CFileStore* OpenFileL(TBool aDoOpen, const TDesC& aFilename, RFs& aFs);
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
    void HandleCommandL(TInt aCommand);
    void OpenFileL(const TDesC& aFileName);
    TBool ProcessCommandParametersL(TApaCommand aCommand, TFileName& aDocumentName, const TDesC8& aTail);
    void InstallOrRunL(const TFileName& aFileName);
    void SetFs(const RFs& aFs);
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
