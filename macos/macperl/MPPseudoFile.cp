/*********************************************************************
Project	:	MacPerl				-	Standalone Perl
File		:	MPPseudoFile.cp	-	Pseudo files for GUSI
Author	:	Matthias Neeracher
Language	:	MPW C/C++
$Log: MPPseudoFile.cp,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:58:04  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:55  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:05:08  neeri
Initial revision

*********************************************************************/

#define GUSI_SOURCE
#define GUSI_INTERNAL

#include <GUSISocket.h>
#include <GUSIDevice.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <Resources.h>
#include <TextUtils.h>

extern "C" {
#include "MPGlobals.h"
}

#include <algorithm>

#include "MPPseudoFile.h"

#undef open

GUSI_USING_STD_NAMESPACE

class MPPseudoSocket : public GUSISocket	{		
	friend class MPPseudoDevice;	
	
				MPPseudoSocket(Handle hdl);
					
	virtual 	~MPPseudoSocket();
	
	Handle		data;
	long		readEnd;
	long		readPtr;
public:
	virtual bool 	Supports(ConfigOption config);
	virtual ssize_t	read(const GUSIScatterer & buf);
	virtual bool 	select(bool * canRead, bool * canWrite, bool * exception);
	virtual int		ioctl(unsigned int request, va_list args);
	virtual off_t 	lseek(off_t offset, int whence);
	virtual int 	fstat(struct stat * buf);
};	

class MPPseudoDevice : public GUSIDevice {
public:
	virtual bool				Want(GUSIFileToken & file);
	virtual GUSISocket * 		open(GUSIFileToken & file, int flags);

	static MPPseudoDevice *		Instance();
private:
	static MPPseudoDevice *		sInstance;	
};

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPPseudo
#endif

/************************ MPPseudoSocket members ************************/

void InitPseudo()
{
	GUSIDeviceRegistry::Instance()->AddDevice(MPPseudoDevice::Instance());
}

MPPseudoSocket::MPPseudoSocket(Handle hdl)
	: data(hdl)
{
	readPtr	=	0;
	readEnd	=	GetHandleSize(data);
}

MPPseudoSocket::~MPPseudoSocket()
{
	DisposeHandle(data);
}

bool MPPseudoSocket::Supports(ConfigOption config)
{
	return config == kSimpleCalls;
}

int MPPseudoSocket::ioctl(unsigned int request, va_list args)
{
	switch (request)	{
	case FIONREAD:
		*va_arg(args, long *)	= readEnd - readPtr;
		
		return 0;
	default:
		return GUSISetPosixError(EOPNOTSUPP);
	}
}

ssize_t MPPseudoSocket::read(const GUSIScatterer & buf)
{
	int buflen = min(int(readEnd - readPtr), buf.Length());
	
	memcpy(buf.Buffer(), (*data) + readPtr, buflen);
	
	readPtr += buflen;
	
	return buflen;
}

bool MPPseudoSocket::select(bool * canRead, bool * canWrite, bool * exception)
{
	bool	selectOK = false;
		
	if (canRead)
		selectOK = *canRead = readEnd > readPtr;
	
	if (canWrite)
		*canWrite = false;
	
	if (exception)
		*exception = false;
	
	return selectOK;
}

off_t MPPseudoSocket::lseek(off_t offset, int whence)
{
	long	nuReadPtr;
	
	switch (whence) {
	case SEEK_END:
		nuReadPtr = readEnd + offset;
		break;
	case SEEK_CUR:
		nuReadPtr = readPtr + offset;
		break;
	case SEEK_SET:
		nuReadPtr = offset;
		break;
	default:
		return GUSISetPosixError(EINVAL);
	}
	
	if (nuReadPtr > readEnd)
		return GUSISetPosixError(ESPIPE);
	if (nuReadPtr < 0)
		return GUSISetPosixError(EINVAL);
	
	return readPtr = nuReadPtr;
}

int MPPseudoSocket::fstat(struct stat * buf)
{
	GUSISocket::fstat(buf);
	buf->st_mode	=	S_IFREG | 0555;
	buf->st_size	=	readEnd;	
	
	return 0;
}

/********************* MPPseudoSocketDomain member **********************/

MPPseudoDevice *	MPPseudoDevice::sInstance;	

MPPseudoDevice * MPPseudoDevice::Instance()
{ 
	if (!sInstance) sInstance = new MPPseudoDevice(); 
	
	return sInstance;
}

bool MPPseudoDevice::Want(GUSIFileToken & file)
{
	if (file.WhichRequest() != GUSIFileToken::kWillOpen || !file.IsDevice())
		return false;

	return (GUSIFileToken::StrFragEqual(file.Path()+4, "pseudo") && (file.Path()[10] == ':' || !file.Path()[10]));
}

GUSISocket * MPPseudoDevice::open(GUSIFileToken & file, int flags)
{
	GUSISocket *			sock = nil;

	if ((flags & O_ACCMODE) != O_RDONLY)
		return GUSISetPosixError(EPERM), static_cast<GUSISocket *>(nil);
		
	if (!file.Path()[10]) {
		sock = new MPPseudoSocket(gPseudoFile);
		
		gPseudoFile = nil;
	} else {
		short	res	=	CurResFile();
		Handle	data;
		
		UseResFile(gScriptFile);
		
		data = getnamedresource('TEXT', (char *) file.Path()+11);
		
		if (data) {
			DetachResource(data);
			
			sock = new MPPseudoSocket(data); 
		}
		
		UseResFile(res);
	}

	return sock;
}
