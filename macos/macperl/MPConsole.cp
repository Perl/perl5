/*********************************************************************
Project	:	MacPerl			-	Standalone Perl
File		:	MPConsole.cp	-	Console interface for GUSI
Author	:	Matthias Neeracher
Language	:	MPW C/C++

$Log: MPConsole.cp,v $
Revision 1.3  2001/04/13 05:28:13  neeri
Forgot to install MPConsoleSpin (MacPerl bug #230880)

Revision 1.2  2000/12/22 08:35:45  neeri
PPC, MrC, and SC builds work

Revision 1.5  1999/01/24 05:08:22  neeri
Adjustments to event/port handling

Revision 1.4  1998/04/07 01:46:32  neeri
MacPerl 5.2.0r4b1

Revision 1.3  1997/11/18 00:53:50  neeri
MacPerl 5.1.5

Revision 1.2  1997/08/08 16:57:53  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:36  neeri
Checked into CVS

Revision 1.2  1994/05/04  02:49:57  neeri
Safer Interrupts.

Revision 1.1  1994/02/27  23:04:58  neeri
Initial revision

Revision 0.2  1993/08/30  00:00:00  neeri
ShowWindow -> DoShowWindow

Revision 0.1  1993/08/14  00:00:00  neeri
Remember rectangles	

*********************************************************************/

#define GUSI_SOURCE
#define GUSI_INTERNAL

#include <GUSISocket.h>
#include <GUSIDevice.h>
#include <GUSISocketMixins.h>
#include <GUSIDescriptor.h>
#include <GUSIConfig.h>

#include "MPConsole.h"

extern "C" {
#include "MPGlobals.h"
#include "MPAppleEvents.h"
#include "MPWindow.h"
#include "MPFile.h"
#include "MPMain.h"
}

#include <Resources.h>
#include <Windows.h>
#include <Errors.h>
#include <Folders.h>
#include <PLStringFuncs.h>
#include <LowMem.h>
#include <Events.h>
#include <Sound.h>
#include <StringCompare.h>

#include <sys/types.h>
#include <Signal.h>
#include <ctype.h>
#include <algorithm>

#undef open

GUSI_USING_STD_NAMESPACE

Boolean	gWantConsoleInput = false;

class MPConsoleSocket : public GUSISocket, protected GUSISMBlocking	{		
	friend class MPConsoleDevice;	
	friend void CloseConsole(Ptr cookie);
	friend Boolean DoRawConsole(Ptr cookie, char theChar);
	friend void HarvestConsole(DPtr doc, MPConsoleSocket * sock);
	friend bool MPConsoleSpin(bool wait);
	
					MPConsoleSocket(DPtr window);
					
	virtual 		~MPConsoleSocket();
	
	DPtr					window;
	Handle				input;
	Boolean				eof;
	Boolean				raw;
	Boolean				echo;
public:
	virtual bool 		Supports(ConfigOption config);
	void 					SetRaw(Boolean newRaw, Boolean newEcho);
	virtual ssize_t	read(const GUSIScatterer & buf);
	virtual ssize_t 	write(const GUSIGatherer & buf);
	virtual int			fcntl(int cmd, va_list args);
	virtual bool 		pre_select(bool wantRead, bool wantWrite, bool wantExcept);
	virtual bool 		select(bool * canRead, bool * canWrite, bool * exception);
	virtual void 		post_select(bool wantRead, bool wantWrite, bool wantExcept);
	virtual int			ioctl(unsigned int request, va_list args);
	virtual int			isatty();
	
	void					Write(char * buffer, int buflen);
};	

class MPConsoleDevice : public GUSIDevice {
public:
	virtual bool				Want(GUSIFileToken & file);
	virtual GUSISocket * 		open(GUSIFileToken & file, int flags);
	
	static MPConsoleDevice *	Instance();
private:
	static MPConsoleDevice *	sInstance;	
};

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPConsole
#endif

/************************ MPConsoleSocket members ************************/

void HarvestConsole(DPtr doc, MPConsoleSocket * sock)
{				
	HLock((*doc->theText)->hText);
	
	char * chr = *(*doc->theText)->hText + (*doc->theText)->teLength;
	char * end = *(*doc->theText)->hText + doc->u.cons.fence;

	if (gGotEof == doc) {
		PtrAndHand(end, sock->input, chr - end);
		
		doc->u.cons.fence = (*doc->theText)->teLength;
		sock->eof			= true;
	} else 
		while (chr-- > end)
			if (*chr == '\n') {
				if (!(sock->raw && sock->echo)) {
					PtrAndHand(end, sock->input, ++chr - end);
					doc->u.cons.fence = chr - *(*doc->theText)->hText;
				}
				
				break;
			}
	
	HUnlock((*doc->theText)->hText);
}

MPConsoleSocket::MPConsoleSocket(DPtr window)
	: window(window)
{
	eof							=	false;
	raw							= 	false;
	input							=	NewHandle(0);
	
	if (window)
		window->u.cons.cookie	=	Ptr(this);
}

void CloseConsole(Ptr cookie)
{
	if (cookie)
		((MPConsoleSocket *) cookie)->window = nil;
}

MPConsoleSocket::~MPConsoleSocket()
{
	DisposeHandle(input);
	
	if (window) {
		window->u.cons.cookie	= nil;
		
		if (!((WindowPeek) window->theWindow)->visible)
			CloseMyWindow(window->theWindow);
	}
}

bool MPConsoleSocket::Supports(ConfigOption config)
{
	return config == kSimpleCalls;
}

int MPConsoleSocket::fcntl(int cmd, va_list arg)
{
	int	result;
	
	if (GUSISMBlocking::DoFcntl(&result, cmd, arg))
		return result;
	
	GUSI_ASSERT_CLIENT(false, ("fcntl: illegal request %d\n", cmd));
	
	return GUSISetPosixError(EOPNOTSUPP);
}

int MPConsoleSocket::ioctl(unsigned int request, va_list arg)
{
	int		result;
	
	if (GUSISMBlocking::DoIoctl(&result, request, arg))
		return result;

	switch (request)	{
	case FIONREAD:
		*va_arg(arg, long *) = GetHandleSize(input);
		
		return 0;
	case FIOINTERACTIVE:
		return 0;
	case WIOSELECT:
		if (window)
			SelectWindow(window->theWindow);
			
		return 0;
	}
	
	GUSI_ASSERT_CLIENT(false, ("ioctl: illegal request %d\n", request));
	
	return GUSISetPosixError(EOPNOTSUPP);
}

ssize_t MPConsoleSocket::read(const GUSIScatterer & scatterer)
{
	int	avail;
	
	GUSIStdioFlush();
	
	if (!fBlocking || raw) {
		gWantConsoleInput	= true;
		GUSIContext::Yield(kGUSIPoll);
		gWantConsoleInput	= false;
	}
	
	avail = int(GetHandleSize(input));
	
	if (!avail)	{
		if (eof) {
			eof = false;
			
			return 0;
		}
		if (!window)
			return 0;
		else if (!fBlocking || raw)
			return GUSISetPosixError(EWOULDBLOCK);
		else {
			if (!((WindowPeek) window->theWindow)->visible)
				DoShowWindow(window->theWindow);
			if (!((WindowPeek) window->theWindow)->hilited)
				SelectWindow(window->theWindow);
				
			window->u.cons.selected = true;
			ShowWindowStatus();
			
			GUSIErrorSaver saveError;
			
			gWantConsoleInput	= true;
			while(!(avail = int(GetHandleSize(input))) && !eof && window)
				GUSIContext::Yield(kGUSIPoll);
			gWantConsoleInput	= false;
	
			if (!avail && eof)
				eof = false;
				
			window->u.cons.selected = false;
			ShowWindowStatus();
			
			if (errno == EINTR)
				errno = EIO; // sfio won't take EINTR seriously
		}
	}
		
	int buflen = min(avail, scatterer.Length());
	
	HLock(input);
	memcpy(scatterer.Buffer(), *input, buflen);
	if (avail -= buflen)
		memcpy(*input, *input+buflen, avail);
	HUnlock(input);
	SetHandleSize(input, avail);
	
	return buflen;
}

ssize_t MPConsoleSocket::write(const GUSIGatherer & gatherer)
{
	char * 	buffer 	= reinterpret_cast<char *>(gatherer.Buffer());
	int		buflen	= gatherer.Length();
	
	if (!window)
		return GUSISetPosixError(ESHUTDOWN);

	char *buf;
	int	trylen = buflen;

	for (buf = buffer; trylen--; ++buf)
		switch (*buf) {
		case 7:	/* Meep meep */
			if (buf > buffer)
				Write(buffer, buf - buffer);
			SysBeep(1);
			
			buffer = buf+1;
			
			break;
		case 8:	/* Delete */
			switch (buf - buffer) {
			case 1:
				/* Nothing to do, cancel last character */
				break;
			default:
				Write(buffer, buf - buffer-1);
				break;
			case 0:
				/* Real delete */
				if (AllSelected(window->theText)) {
					if (window->u.cons.fence < 32767)
						window->u.cons.fence = 0;
				} else if ((*window->theText)->selStart == (*window->theText)->selEnd)
					if ((*window->theText)->selStart <= window->u.cons.fence)
						--window->u.cons.fence;
				TEKey(8, window->theText);
				AdjustScrollbars(window, false);
				ShowSelect(window);
				break;
			}			
			buffer = buf+1;
			
			break;
		}
	Write(buffer, buf-buffer);
	
	return buflen;
}

void MPConsoleSocket::Write(char * buffer, int buflen)
{
	HarvestConsole(window, this);
	
	if (buflen > window->u.cons.memory) {
		buffer = buffer + buflen - window->u.cons.memory;
		buflen = window->u.cons.memory;
	}
	
	window->u.cons.memory -= buflen;
	EnforceMemory(window, window->theText);
	window->u.cons.memory += buflen;
	
	short oldStart	=	(*window->theText)->selStart;
	short oldEnd	=	(*window->theText)->selEnd;
	
	if (oldStart >= window->u.cons.fence)
		oldStart += buflen;
	if (oldEnd >= window->u.cons.fence)
		oldEnd += buflen;
		
	TESetSelect(window->u.cons.fence, window->u.cons.fence, window->theText);
	TEInsert(buffer, buflen, window->theText);

	if (!((WindowPeek) window->theWindow)->visible) {
		HideControl(window->vScrollBar);
		HideControl(window->hScrollBar);
		
		DoShowWindow(window->theWindow);
		if (!((WindowPeek) window->theWindow)->hilited)
			SelectWindow(window->theWindow);
	}

	ShowSelect(window);
	DrawPageExtras(window);
	
	TESetSelect(oldStart, oldEnd, window->theText);

	if (window->u.cons.fence < 32767)
		window->u.cons.fence += buflen;
}

static bool sStatusNeedsUpdate = false;

bool MPConsoleSocket::pre_select(bool wantRead, bool, bool)
{
	if (wantRead && window) {
		gWantConsoleInput	= true;
		sStatusNeedsUpdate = window->u.cons.selected = true;
		
		if (!((WindowPeek) window->theWindow)->visible)
			DoShowWindow(window->theWindow);
	}
		
	return false;
}

void MPConsoleSocket::post_select(bool wantRead, bool, bool)
{
	if (wantRead && window) {
		gWantConsoleInput	= false;
		sStatusNeedsUpdate = window->u.cons.selected = false;
	}
}

bool MPConsoleSocket::select(bool * canRead, bool * canWrite, bool * exception)
{
	bool success = false;

	if (sStatusNeedsUpdate) {
		ShowWindowStatus();
		
		sStatusNeedsUpdate = false;
	}
		
	if (canRead)
		if (*canRead = (GetHandleSize(input) > 0 || eof))
			success	= true;
	
	if (canWrite) {
		*canWrite 	= true;
		success		= true;
	}
	
	if (exception)
		*exception = false;
	
	return success;
}

int MPConsoleSocket::isatty()
{
	return 1;
}

void MPConsoleSocket::SetRaw(Boolean newRaw, Boolean newEcho)
{
	if (raw && !newRaw) {
		HLock(input);
		char *	checkInput		=	*input;
		char *	checkedInput	=	*input;
		
		for (int len = GetHandleSize(input); len--; ++checkInput)
			switch (*checkInput) {
			case 8:
				if (checkedInput > *input)
					--checkedInput;
				break;
			case '\t':
			case '\n':
				*checkedInput++ = *checkInput;
				break;
			case 0x7F:
				break;
			default:
				if (*checkInput >= 32)
					*checkedInput++ = *checkInput;
				break;
			}
		window->u.cons.fence = (*window->theText)->teLength;
		write(GUSIGatherer(*input, checkedInput - *input));
		HUnlock(input);
		SetHandleSize(input, 0);
	} else if (!raw && newRaw)
		HarvestConsole(window, this);
		
	raw = newRaw;
	echo = newEcho;
}

Boolean DoRawConsole(Ptr cookie, char theChar)
{
	if (cookie) {
		MPConsoleSocket *	sock	= reinterpret_cast<MPConsoleSocket *>(cookie);
		if (sock->raw) {
			PtrAndHand(&theChar, sock->input, 1);
			
			return !sock->echo;
		}
	}
	return false;
}

/********************* MPConsoleDevice members **********************/

MPConsoleDevice *	MPConsoleDevice::sInstance;	

MPConsoleDevice * MPConsoleDevice::Instance()
{ 
	if (!sInstance) sInstance = new MPConsoleDevice(); 
	
	return sInstance;
}

bool MPConsoleDevice::Want(GUSIFileToken & file)
{
	if (file.WhichRequest() != GUSIFileToken::kWillOpen || !file.IsDevice())
		return false;
	
	if (file.StrStdStream(file.Path()) > -1)
		return true;
		
	if (GUSIFileToken::StrFragEqual(file.Path()+4, "console") && file.Path()[11] == ':')
		return true;
	
	return false;
}

GUSISocket * MPConsoleDevice::open(GUSIFileToken & file, int flags)
{
	DPtr				doc;
	GUSISocket *	sock = nil;
	char 				title[256];
	bool				nudoc 		= false;
	bool				userConsole	= false;
	
	switch (file.StrStdStream(file.Path())) {
	case GUSIFileToken::kStdin:
		flags = O_RDONLY;
		
		break;
	case GUSIFileToken::kStdout:
		flags = O_WRONLY;
		
		break;
	case GUSIFileToken::kStderr:
		flags = O_WRONLY;
		
		break;
	case GUSIFileToken::kConsole:
		break;
	default:
		userConsole	= true;
		break;
	}

	if (userConsole) {
		for (doc = gConsoleList; doc; doc = doc->u.cons.next)
			if (doc->kind == kConsoleWindow) {
				getwtitle(doc->theWindow, title);
				
				if (equalstring(title, (char *) file.Path()+12, false, true)) {
					if (doc->u.cons.cookie)
						sock = reinterpret_cast<GUSISocket *>(doc->u.cons.cookie);

					goto found;
				}
			}
			
		nudoc	= true;				
		doc	= NewDocument(false, kConsoleWindow);
		
		setwtitle(doc->theWindow, (char *) file.Path()+12);
		
		RestoreConsole(doc);
	} else {
		for (doc = gConsoleList; doc; doc = doc->u.cons.next)
			if (doc->kind == kWorksheetWindow) {
				if (doc->u.cons.cookie)
					sock = reinterpret_cast<GUSISocket *>(doc->u.cons.cookie);

				goto found;
			}

		nudoc = true;
		doc	= NewDocument(false, kWorksheetWindow);
		SetWTitle(doc->theWindow, LMGetCurApName());

		RestoreConsole(doc);
	}

found:	
	if (!sock) {
		errno = 0;
		sock 	= new MPConsoleSocket(doc);
		
		if (sock && errno) {
			if (nudoc)
				CloseMyWindow(doc->theWindow);

			sock->close();
			
			return nil;
		}
	} else
		static_cast<MPConsoleSocket *>(sock)->eof = false;

	if (!(flags & 1) && doc)
		doc->u.cons.fence = (*doc->theText)->teLength;
	else if (nudoc)
		doc->u.cons.fence = 32767;

	return sock;
}

/********************* A kinder, gentler, spin **********************/

extern "C" void Perl_my_exit(int status);

bool MPConsoleSpin(bool /* wait */)
{
#if NOT_YET
	if ((gAborting || (!gInBackground && GUSIConfiguration::Instance()->CheckInterrupt())) 
		&& gRunningPerl) {
		FlushEvents(-1, 0);

		if (spin == SP_AUTO_SPIN || spin == SP_SLEEP) {
			ResetConsole();

			Perl_my_exit(-128);
		} else {
			raise(SIGINT);
			
			return true;
		}
	}
#endif
		
	// 
	// It would be nightmarish for MacPerl drawing code if a cursor spin altered the
	// current port. However, to "restore" a port that is gone in the meantime is even 
	// worse. To complicate matters further, the port may have been an offscreen 
	// GrafPort. We try to handle this with a number of probabilistic sanity checks.
	//
	CGrafPtr	savePort;
	GDHandle	saveDevice;
	GetGWorld(&savePort, &saveDevice);
	Size		savePortSize	= GetPtrSize((Ptr)savePort);
	Size		saveDeviceSize = GetHandleSize((Handle) saveDevice);

	//
	// If the port was an offscreen port, set up a sane onscreen device
	//
	GDHandle dev;
	for (dev = GetDeviceList(); dev; dev = GetNextDevice(dev))
		if (dev == saveDevice)
			break; // Onscreen device
	if (!dev) {
		GrafPtr wport;
		
		GetWMgrPort(&wport);
		SetGWorld((CGrafPtr)wport, GetMainDevice());
	}
	
	MainEvent(!gWantConsoleInput, -1, nil);
	
	if (*saveDevice && GetPtrSize((Ptr)savePort)==savePortSize 
	 && GetHandleSize((Handle)saveDevice)==saveDeviceSize
	) 
		SetGWorld(savePort, saveDevice);

	for (DPtr doc = gConsoleList; doc; doc = doc->u.cons.next)
		if (doc->dirty) {
			if (doc->u.cons.cookie) 
				HarvestConsole(doc, (MPConsoleSocket *) doc->u.cons.cookie);
			doc->dirty = false;
		}
	
	return false;
}

/********************* Raw I/O **********************/

static int EmulateStty(FILE * tempFile, char * command)
{
	Boolean	setRaw	=	false;
	Boolean	setEcho	=	false;
	Boolean	flip;
	
	while (*command) {
		flip = false;
		if (isspace(*command)) {
			do {
				++command;
			} while (*command && isspace(*command));
			continue;
		}
		if (*command == '-') {
			++command;
			flip = true;
		}
		if (!strncmp(command, "raw", 3) && (!command[3] || isspace(command[3]))) {
			command += 3;
			setRaw = !flip;
		} else if (!strncmp(command, "sane", 4) && (!command[4] || isspace(command[4]))) {
			command += 4;
			setRaw = flip;
		} else if (!strncmp(command, "echo", 4) && (!command[4] || isspace(command[4]))) {
			command += 4;
			setEcho = !flip;
		} else
			break;
	}
	
	if (!*command)
		command 	= 	"Dev:Console";

	MPConsoleSocket * console = 
		dynamic_cast<MPConsoleSocket *>(GUSIDeviceRegistry::Instance()->open(command, O_RDWR));
	
	console->SetRaw(setRaw, setEcho);
	
	return 0;
}

void InitConsole()
{
	GUSIDeviceRegistry::Instance()->AddDevice(MPConsoleDevice::Instance());
	
	GUSISetHook(GUSI_SpinHook, (GUSIHook)MPConsoleSpin);
	
#if NOT_YET
	AddWriteEmulationProc("stty", EmulateStty);
#endif
}

void ResetConsole()
{
	for (DPtr doc = gConsoleList; doc; doc = doc->u.cons.next)
		if (doc->u.cons.selected)
			doc->u.cons.selected = false;
			
	gWantConsoleInput	= false;
	ShowWindowStatus();
}
