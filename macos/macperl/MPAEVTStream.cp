/*********************************************************************
Project	:	MacPerl			-	Standalone Perl
File		:	MPConsole.cp	-	Console interface for GUSI
Author	:	Matthias Neeracher
Language	:	MPW C/C++

$Log: MPAEVTStream.cp,v $
Revision 1.3  2001/04/28 23:28:01  neeri
Need to register MPAEVTStreamDevice (MacPerl Bug #418932)

Revision 1.2  2000/12/22 08:35:45  neeri
PPC, MrC, and SC builds work

Revision 1.1  1997/06/23 17:10:30  neeri
Checked into CVS

*********************************************************************/

#define GUSI_SOURCE
#define GUSI_INTERNAL

#include <GUSISocket.h>
#include <GUSIDevice.h>
#include <GUSISocketMixins.h>

#include "MPAEVTStream.h"

#include <AEBuild.h>

#include "MPGlobals.h"
#include "MPConsole.h"

extern "C" {
#include <AESubDescs.h>
#include <AEStream.h>
}

#include <algorithm>
#include <sys/ioctl.h>

#undef open

GUSI_USING_STD_NAMESPACE

//
// The version in AEStream_CPlus was slightly buggy
//
struct MPAEStream : public AEStream {		// A (write-only) stream on an AE descriptor
	public:
	
	inline MPAEStream( )							{AEStream_Open(this);}
	inline MPAEStream( AppleEvent &aevt )			{AEStream_OpenEvent(this,&aevt);}
	inline MPAEStream( AEEventClass Class, AEEventID id,
					 DescType targetType, const void *targetData, long targetLength,
					 short returnID =kAutoGenerateReturnID,
					 long transactionID =kAnyTransactionID )
					 							{AEStream_CreateEvent(this,Class,id,
					 									targetType,targetData,targetLength,
					 									returnID,transactionID);}
	inline ~MPAEStream()							{AEStream_Close(this, NULL);}
	// I'm having doubts about these constructors, since constructors can't
	// return error results .... Hmm?
	
	OSErr Close		( AEDesc *desc =NULL )
												{return AEStream_Close(this,desc);}

	OSErr OpenDesc	( DescType type )
												{return AEStream_OpenDesc(this,type);}
	OSErr WriteData	( const void *data, Size length )
												{return AEStream_WriteData(this,data,length);}
	OSErr CloseDesc	( void )
												{return AEStream_CloseDesc(this);}

	OSErr WriteDesc	( DescType type, const void *data, Size length )
												{return AEStream_WriteDesc(this,type,data,length);}
	OSErr WriteDesc	( const AEDesc &desc )
												{return AEStream_WriteAEDesc(this,&desc);}

	OSErr OpenList	( void )
												{return AEStream_OpenList(this);}
	OSErr CloseList	( void )
												{return AEStream_CloseList(this);}

	OSErr OpenRecord	( DescType type )
												{return AEStream_OpenRecord(this,type);}
	OSErr SetRecordType( DescType type )
												{return AEStream_SetRecordType(this,type);}
	OSErr CloseRecord	( void )
												{return AEStream_CloseRecord(this);}

	OSErr WriteKeyDesc( AEKeyword key, DescType type, void *data, Size length )
										{return AEStream_WriteKeyDesc(this,key,type,data,length);}
	OSErr OpenKeyDesc	( AEKeyword key, DescType type )
												{return AEStream_OpenKeyDesc(this,key,type);}
	OSErr WriteKey	( AEKeyword key )
												{return AEStream_WriteKey(this,key);}
	private:
		Handle	data;					// The data
		Size	size;					// Current size of handle [same as GetHandleSize(data)]
		Size	index;					// Current index (into data handle) to write to
		Size	headIndex;				// Offset of header [type field] of open descriptor
		char	context;				// What context am I in? [enum]
		char	isEvent;				// Is this an Apple Event? [Boolean]
};

class MPAEVTSocket : public GUSISocket, protected GUSISMBlocking	{		
	friend class MPAEVTDevice;	
	
					MPAEVTSocket(OSType key, Boolean input, Boolean output);
					
	virtual 		~MPAEVTSocket();
	
	OSType						key;
	Handle						inData;
	Handle						outData;
	Boolean						eof;
	Boolean						needy;
	MPAEVTSocket *				next;
	MPAEVTSocket * 			prev;
public:
	virtual bool 		Supports(ConfigOption config);
	virtual ssize_t	read(const GUSIScatterer & buf);
	virtual ssize_t 	write(const GUSIGatherer & buf);
	virtual int			fcntl(int cmd, va_list args);
	virtual bool 		pre_select(bool wantRead, bool wantWrite, bool wantExcept);
	virtual bool 		select(bool * canRead, bool * canWrite, bool * exception);
	virtual int			ioctl(unsigned int request, va_list args);
	virtual int			isatty();
};	

class MPAEVTDevice : public GUSIDevice {
	MPAEVTSocket *			Lookup(OSType key, Boolean input, Boolean output);
	
	MPAEVTSocket *			first;
	OSType					key;
	OSType					mode;
	DescType					saseClass;
	DescType					saseID;
	AppleEvent				sase;
	AEDesc					target;
	MPAEStream				outputData;
	AEDesc					outputDirect;
	short						outputDataCount;

	MPAEVTDevice();

	static MPAEVTDevice *		sInstance;	
public:
	friend class MPAEVTSocket;
	
	static MPAEVTDevice *	Instance();
	
	virtual bool					Want(GUSIFileToken & file);
	virtual GUSISocket * 		open(GUSIFileToken & file, int flags);
	
	void CollectOutput(AppleEvent * output);
	void DistributeInput(const AppleEvent * input, long mode);
	void KillInput();
	void FlushInput();

	void	Enqueue(MPAEVTSocket * sock);
	void	Dequeue(MPAEVTSocket * sock);
	
	void 		DoRead();
	Boolean	MayRead();
	
	Boolean					finish;
	long						received;
};

#if !defined(powerc) && !defined(__powerc)
#pragma segment MPAEVT
#endif

/************************ MPAEVTSocket members ************************/

MPAEVTSocket::MPAEVTSocket(OSType key, Boolean input, Boolean output)
	: key(key), needy(false)
{
	eof		=	!input || MPAEVTDevice::Instance()->mode == 'BATC';
	inData	=	input ? NewHandle(0) : nil;
	outData	=	output ? NewHandle(0) : nil;
	
	MPAEVTDevice::Instance()->Enqueue(this);
}

MPAEVTSocket::~MPAEVTSocket()
{
	if (outData)
		if (GetHandleSize(outData)) {
			AEDesc	desc ;
			
			desc.descriptorType = 'TEXT';
			desc.dataHandle     = outData;
			
			if (key == '----')
				MPAEVTDevice::Instance()->outputDirect	=	desc;
			else {
				MPAEVTDevice::Instance()->outputData.WriteKey(key);
				MPAEVTDevice::Instance()->outputData.WriteDesc(desc);
				++MPAEVTDevice::Instance()->outputDataCount;
				AEDisposeDesc(&desc);
			}
		} else
			DisposeHandle(outData);
			
	if (inData)
		DisposeHandle(inData);

	MPAEVTDevice::Instance()->Dequeue(this);
}

bool MPAEVTSocket::Supports(ConfigOption config)
{
	return config == kSimpleCalls;
}

int MPAEVTSocket::fcntl(int cmd, va_list arg)
{
	int	result;
	
	if (GUSISMBlocking::DoFcntl(&result, cmd, arg))
		return result;
	
	GUSI_ASSERT_CLIENT(false, ("fcntl: illegal request %d\n", cmd));
	
	return GUSISetPosixError(EOPNOTSUPP);
}

int MPAEVTSocket::ioctl(unsigned int request, va_list arg)
{
	int		result;
	
	if (GUSISMBlocking::DoIoctl(&result, request, arg))
		return result;

	switch (request)	{
	case FIONREAD:
		*va_arg(arg, long *) = GetHandleSize(inData);
		
		return 0;
	case FIOINTERACTIVE:
		return 0;
	}
	
	GUSI_ASSERT_CLIENT(false, ("ioctl: illegal request %d\n", request));
	
	return GUSISetPosixError(EOPNOTSUPP);
}

ssize_t MPAEVTSocket::read(const GUSIScatterer & scatterer)
{
	if (!inData)
		return GUSISetPosixError(ESHUTDOWN);

	int	avail;
	
	while (1) {	
		avail = int(GetHandleSize(inData));
		
		if (!avail)
			if (eof)
				return 0;
			else {
				needy = true;
				if (!fBlocking)
					return GUSISetPosixError(EWOULDBLOCK);
				else
					MPAEVTDevice::Instance()->DoRead();
			}
		else
			break;
	}
	
	needy	 			= false;
	ssize_t buflen = min(avail, scatterer.Length());
	
	HLock(inData);
	memcpy(scatterer.Buffer(), *inData, buflen);
	if (avail -= buflen)
		memcpy(*inData, *inData+buflen, avail);
	HUnlock(inData);
	SetHandleSize(inData, avail);
	
	return buflen;
}

ssize_t MPAEVTSocket::write(const GUSIGatherer & gatherer)
{
	if (!outData)
		return GUSISetPosixError(ESHUTDOWN);
	else if (PtrAndHand(gatherer.Buffer(), outData, gatherer.Length()))
		return GUSISetPosixError(ENOMEM);
	
	return gatherer.Length();
}

bool MPAEVTSocket::pre_select(bool, bool, bool)
{
	needy = false;
	
	return false;
}

bool MPAEVTSocket::select(bool * canRead, bool * canWrite, bool * exception)
{
	bool success = false;
		
	if (canRead)
		if (inData)
			if (*canRead = (GetHandleSize(inData) > 0 || eof))
				success = true;
			else if (needy) {
				MPAEVTDevice::Instance()->DoRead();
				if (*canRead = (GetHandleSize(inData) > 0 || eof))
					success = true;
			} else
				needy = true;
		else
			*canRead = false;
	
	if (canWrite)
		if (*canWrite = (outData != nil))
			success = true;
	
	if (exception)
		*exception = false;
	
	return success;
}

int MPAEVTSocket::isatty()
{
	return 1;
}

/********************* MPAEVTSocketDomain members **********************/

MPAEVTDevice *	MPAEVTDevice::sInstance;	

MPAEVTDevice * MPAEVTDevice::Instance()
{ 
	if (!sInstance) sInstance = new MPAEVTDevice(); 
	
	return sInstance;
}

MPAEVTDevice::MPAEVTDevice()
	:	finish(false), first(nil), received(0)
{
	outputData.OpenRecord(typeAERecord);
}

bool MPAEVTDevice::Want(GUSIFileToken & file)
{
	if (file.WhichRequest() != GUSIFileToken::kWillOpen || !file.IsDevice())
		return false;
	
	if (file.StrStdStream(file.Path()) > -1)
		return gRemoteControl;
		
	if (GUSIFileToken::StrFragEqual(file.Path()+4, "aevt"))
		switch (file.Path()[8]) {
		case ':':
			return file.Path()[9] != 0;
		case 0:
			return true;
		}
	return false;
}


GUSISocket * MPAEVTDevice::open(GUSIFileToken & file, int flags)
{
	switch (file.StrStdStream(file.Path())) {
	case GUSIFileToken::kStdin:
	case GUSIFileToken::kStdout:
		key = '----';
		
		break;
	case GUSIFileToken::kStderr:
		key = 'diag';
		
		break;
	default:
		if (file.Path()[8]) {
			key = '    ';
			memcpy(&key, file.Path()+9, min((unsigned long)strlen(file.Path()+9), 4UL));
		} else
			key = '----';
	}
	
	return Lookup(key, !(flags & O_WRONLY), (flags & 3) != 0);
}

Boolean MPAEVTDevice::MayRead()
{
	return (mode == 'RCTL') || (mode == 'DPLX');
}

void MPAEVTDevice::DoRead()
{
	if (!MayRead())
		KillInput();
	else {	
		long	oldReceived = received;
		
		if (sase.dataHandle) {
			/* Send tickle event. */
			OSErr			err;
			AppleEvent	tickle;
			AppleEvent	tickleReply;
			
			if (AECreateAppleEvent(saseClass, saseID, &target, 0, 0, &tickle))
				goto waitForData;
			
			AEKeyword	key;
			AEDesc		desc;
			
			for (long index = 1; !AEGetNthDesc(&sase, index++, typeWildCard, &key, &desc);) {
				AEPutParamDesc(&tickle, key, &desc);
				AEDisposeDesc(&desc);
			}
			
			if (mode == 'DPLX') {
				CollectOutput(&tickle);
				err = AESend(&tickle, &tickleReply, kAEWaitReply, kAENormalPriority, kAEDefaultTimeout, nil, nil);
				DistributeInput(&tickleReply, 0);
				++received;
				AEDisposeDesc(&tickleReply);
			} else {
				err = AESend(&tickle, &tickleReply, kAENoReply, kAENormalPriority, kAEDefaultTimeout, nil, nil);
			}
			
			AEDisposeDesc(&tickle);
			
			if (err) {
				KillInput();
				return;
			}
		}
	waitForData:
		while (oldReceived == received)
			GUSIContext::Yield(kGUSIBlock);
	}
}

static void AEGetAttrOrParam(AEDesc * from, DescType keyword, void * into)
{
	Size 		size;
	DescType	type;

	if (AEGetAttributePtr(from, keyword, typeWildCard, &type, into, 4, &size))
		if (!AEGetParamPtr(from, keyword, typeWildCard, &type, into, 4, &size))
			AEDeleteParam(from, keyword);
}

void MPAEVTDevice::DistributeInput(const AppleEvent * input, long mode)
{
	AEDesc		desc;
	AESubDesc	aes;
	AESubDesc	item;
	DescType		keyword;
	
	if (mode)
		this->mode = mode;
		
	if (!AEGetParamDesc(input, 'INPT', typeAERecord, &desc)) {
		AEDescToSubDesc(&desc, &aes);

		HLock(aes.dataHandle);
		
		long maxIndex = AECountSubDescItems(&aes);
		
		for (long index = 0; index++ < maxIndex; ) {
			if (AEGetNthSubDesc(&aes, index, &keyword, &item))
				continue;
				
			long				length;
			
			void * 			data = AEGetSubDescData(&item, &length);
			MPAEVTSocket * sock = Lookup(keyword, true, false);
			
			if (sock) {
				if (AEGetSubDescType(&item) == typeNull)
					sock->eof = true;
				else if (sock->inData && length)
					PtrAndHand(data, sock->inData, length);
				sock->Wakeup();
			}
		}
		
		AEDisposeDesc(&desc);
	}
	
	if (!mode) {
		if (!AEGetParamDesc(input, '----', typeWildCard, &desc)) {
			MPAEVTSocket * sock = Lookup('----', true, false);
		
			if (sock)
				if (desc.descriptorType == typeNull)
					sock->eof = true;
				else if (sock->inData) {
					HLock(desc.dataHandle);
					HandAndHand(desc.dataHandle, sock->inData);
				}
		
			AEDisposeDesc(&desc);
		}
	} else {
		AEDesc	doneDesc;
		
		if (AEGetParamDesc(input, 'SASE', typeAERecord, &sase))
			if (mode = 'DPLX')
				AEBuild(&sase, "{evcl: McPL, evid: SASE}");
		if (sase.dataHandle) {
			AEGetAttributeDesc(input, keyAddressAttr, typeWildCard, &target);
			AEGetAttrOrParam(&sase, keyEventClassAttr, &saseClass);
			AEGetAttrOrParam(&sase, keyEventIDAttr, &saseID);
		}
		if (!AEGetParamDesc(input, 'DONE', typeBoolean, &doneDesc)
		 && **(Boolean **) doneDesc.dataHandle
		)
			this->mode = 'BATC';
	}
}

void MPAEVTDevice::KillInput()
{
	int				runs = 0;
	MPAEVTSocket * sock = first;

	if (sock)
		while ((runs += sock == first) < 2) {
			if (sock->needy) 
				sock->eof = true;
			
			sock = sock->next;
		}
}

void MPAEVTDevice::FlushInput()
{
	int				runs = 0;
	MPAEVTSocket * sock = first;

	if (sock)
		while ((runs += sock == first) < 2) {
			if (sock->inData) 
				SetHandleSize(sock->inData, 0);
			
			sock = sock->next;
		}
	AEDisposeDesc(&sase);
	AEDisposeDesc(&target);
}

void MPAEVTDevice::CollectOutput(AppleEvent * output)
{
	OSErr				err;
	MPAEStream 		want;
	AEDesc			desc;
	int				wantCount = 0;
	int				runs = 0;
	MPAEVTSocket * sock = first;
	
	desc.descriptorType = 'TEXT';
	
	want.OpenList();
	
	if (sock)
		while ((runs += sock == first) < 2) {
			if (sock->outData && GetHandleSize(sock->outData)) {
				desc.dataHandle = sock->outData;
				if (sock->key == '----')
					if (!AEPutParamDesc(output, '----', &desc))
						SetHandleSize(sock->outData, 0);
					else 
						return;							// This is sort of disastrous
				else if (outputData.WriteKey(sock->key) || outputData.WriteDesc(desc))				
					return;								// 	... so is this.
				else 
					++outputDataCount;
			}
			if (sock->inData && sock->needy)
				if (!want.WriteDesc(typeEnumerated, &sock->key, 4))
					++wantCount;
			
			sock = sock->next;
		}
	
	if (outputDirect.dataHandle) {
		err = AEPutParamDesc(output, '----', &outputDirect);
		AEDisposeDesc(&outputDirect);
	
		if (err)
			return;
	}
	
	if (!(err = outputData.CloseRecord()))
		err = outputData.Close(&desc);
	
	AEStream_Open(&outputData);
	outputData.OpenRecord(typeAERecord);
	
	if (outputDataCount) {
		outputDataCount = 0;
		if (!err) {
			err = AEPutParamDesc(output, 'OUTP', &desc);
			AEDisposeDesc(&desc);
			
			if (err)
				return;	// Death before Dishonour
		} else
			return;
	} else if (!err)
		AEDisposeDesc(&desc);
		
	if (!want.CloseList() && wantCount) {
		if (!want.Close(&desc)) {
			AEPutParamDesc(output, 'WANT', &desc);
			AEDisposeDesc(&desc);
		} 
	} else
		want.Close();
	
	AEPutParamPtr(output, 'DONE', typeBoolean, (Ptr) &finish, 1);
	
	if (sock)	
		for (runs = 0; (runs += sock == first) < 2; sock = sock->next) 
			if (sock->outData) 
				SetHandleSize(sock->outData, 0);
}

void MPAEVTDevice::Enqueue(MPAEVTSocket * sock)
{
	sock->prev = nil;
	sock->next = first;
	first = sock;
}

void MPAEVTDevice::Dequeue(MPAEVTSocket * sock)
{
	if (sock->prev)
		sock->prev->next = sock->next;
	else
		first = sock->next;
	if (sock->next)
		sock->next->prev = sock->prev;
}

MPAEVTSocket * MPAEVTDevice::Lookup(OSType key, Boolean input, Boolean output)
{
	int				runs = 0;
	MPAEVTSocket * sock = first;
	
	while (sock)
		if (sock->key == key) {
			if (input && !sock->inData)
				sock->inData = NewHandle(0);
			if (output && !sock->outData)
				sock->outData = NewHandle(0);
			
			return sock;
		} else
			sock = sock->next;
	
	return new MPAEVTSocket(key, input, output);
}

/********************* Interface routines **********************/

void InitAevtStream()
{
	GUSIDeviceRegistry::Instance()->AddDevice(MPAEVTDevice::Instance());
}

pascal OSErr Relay(const AppleEvent * inData, AppleEvent * outData, long refCon)
{
	++MPAEVTDevice::Instance()->received;
	
	if (inData)
		MPAEVTDevice::Instance()->DistributeInput(inData, refCon);
	if (outData)
		MPAEVTDevice::Instance()->CollectOutput(outData);
		
	return noErr;
}

pascal void FlushAEVTs(AppleEvent * outData)
{
	if (outData)
		MPAEVTDevice::Instance()->CollectOutput(outData);
	else {
		MPAEVTDevice::Instance()->finish = true;
		MPAEVTDevice::Instance()->DoRead();
		MPAEVTDevice::Instance()->finish = false;
	}
	MPAEVTDevice::Instance()->FlushInput();
}

