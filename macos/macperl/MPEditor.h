/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPEditor.h			-	Delegate to external editor
Author	:	Matthias Neeracher

Language	:	MPW C

$Log: MPEditor.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:43  neeri
Checked into CVS

*********************************************************************/

#ifndef __MPEDITOR__
#define __MPEDITOR__

#include <Types.h>
#include <Files.h>
#include <AppleEvents.h>

extern OSErr	 		FindHelper(StringPtr helperName, ICAppSpecHandle * helperHdl, Boolean launch);
extern void 			InitExternalEditor();
extern void 			CloseExternalEditor();
extern Boolean			HasExternalEdits();
extern void				GetExternalEditorName(StringPtr name);
extern Boolean			GetExternalEditorDocumentName(StringPtr name);
extern OSErr			EditExternal(FSSpec * spec);
extern OSErr			StartExternalEditor(Boolean front);
extern OSErr 			UpdateExternalEditor(Boolean front);
extern pascal OSErr	DoExternalEditor(const AppleEvent *, AppleEvent *, long);

#endif