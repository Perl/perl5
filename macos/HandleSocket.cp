/*********************************************************************
Project	:	GUSI				-	Grand Unified Socket Interface
File		:	HandleSocket.cp-	Handle sockets
Author	:	Matthias Neeracher <neeri@iis.ee.ethz.ch>
Language	:	MPW C++

$Log: HandleSocket.cp,v $
Revision 1.1  2001/12/19 22:57:11  pudge
Start to make Mac::Memory::_open work.  HandleSocket.cp still needs some lovin ' ... the entire thing is a bit unstable.

Revision 1.1  1997/04/07 20:46:13  neeri
Synchronized with MacPerl 5.1.4a1

*********************************************************************/

#define GUSI_SOURCE
#define GUSI_INTERNAL

#include <GUSISocket.h>
#include <GUSIDevice.h>
#include <GUSISocketMixins.h>
#include <GUSIDescriptor.h>
#include <GUSIConfig.h>

extern "C" int OpenHandle(Handle h, int oflag);

class HandleSocket : public GUSISocket {
	friend int OpenHandle(Handle h, int oflag);
protected:
	HandleSocket(Handle h, int oflag);
public:
	virtual bool		Supports(ConfigOption config);
	virtual ssize_t	read(const GUSIScatterer & buf);
	virtual ssize_t	write(const GUSIGatherer & buf);
	virtual int			ioctl(unsigned int request, va_list argp);
	virtual long		lseek(long offset, int whence);
	virtual int			ftruncate(long offset);
private:
	Handle	data;
	long		pos;
	Boolean	append;
};

/************************ HandleSocket members ************************/

HandleSocket::HandleSocket(Handle h, int oflag)
 : GUSISocket(), data(h), pos(0)
{
	if (oflag & O_TRUNC)
		SetHandleSize(data, 0);
	append	=	(oflag & O_APPEND) != 0; 
}

ssize_t HandleSocket::read(const GUSIScatterer & scatterer)
{
	int	length 	= 	scatterer.Length();
	int	left		=	GetHandleSize(data)-pos;

	if (length > left)
		length = left;

	if (length) {
		HLock(data);
		memcpy(scatterer.Buffer(), *data+pos, length);
		pos += length;
		HUnlock(data);
	}

	return length;
}

ssize_t HandleSocket::write(const GUSIGatherer & gatherer)
{
	char * 	buffer 	= reinterpret_cast<char *>(gatherer.Buffer());
	int		buflen	= gatherer.Length();
	char *	dork;

	if (append)
		pos = GetHandleSize(data);
	
	long size = GetHandleSize(data);
	if (pos+buflen > size) {
		SetHandleSize(data, pos+buflen);
		while (size < pos)
			(*data)[size++] = 0;
	}
	if (buflen) {		
		HLock(data);
		memcpy(*data+pos, gatherer.Buffer(), buflen);
		pos += buflen;
		HUnlock(data);
	}
	
	return buflen;
}

int HandleSocket::ioctl(unsigned int request, va_list argp)
{
	switch (request) {
	case FIONREAD:
		*va_arg(argp, long *) = GetHandleSize(data) - pos;
		
		return 0;
	default :
		return GUSISocket::ioctl(request, argp);
	}

	GUSI_ASSERT_CLIENT(false, ("ioctl: illegal request %d\n", request));
	
	return GUSISetPosixError(EOPNOTSUPP);
}

long HandleSocket::lseek(long offset, int whence)
{	
	long newPos;
	
	switch (whence) {
	case SEEK_CUR:
		newPos = pos+offset;
		break;
	case SEEK_END:
		newPos = GetHandleSize(data)+offset;
		break;
	case SEEK_SET:
		newPos = offset;
		break;
	default:
		return GUSISetPosixError(EINVAL);
	}
	if (newPos < 0)
		return GUSISetPosixError(EINVAL);
	else
		return pos = newPos;
}

int HandleSocket::ftruncate(long offset)
{	
long size = GetHandleSize(data);
	if (offset > GetHandleSize(data)) {
		lseek(offset, SEEK_SET);
		write(GUSIGatherer(nil, 0));
	} else
		SetHandleSize(data, offset);

	return 0;
}

bool HandleSocket::Supports(ConfigOption config)
{
	return config == kSimpleCalls;
}

int OpenHandle(Handle h, int oflag)
{	
	int		fd;
	GUSISocket * sock = new HandleSocket(h, oflag);
	GUSIDescriptorTable * table = GUSIDescriptorTable::Instance();

	if (sock)
		if ((fd = table->InstallSocket(sock)) > -1)
			return fd;
		else
			delete sock;

	if (!errno)
		return GUSISetPosixError(ENOMEM);
	else
		return -1;
}

