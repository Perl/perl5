/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 * MacPerl 5.1.5
 * 
 * Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <ImageCompression.h>

MODULE = Mac::ImageCompression	PACKAGE = Mac::ImageCompression

=head2 Functions

=over 4

long
CodecManagerVersion()
	CODE:
	if (gMacPerl_OSErr = CodecManagerVersion(&RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

=begin ignore

MacOSRet
GetCodecNameList(list, showAll)
	CodecNameSpecListPtr *	list
	short	showAll

MacOSRet
DisposeCodecNameList(list)
	CodecNameSpecListPtr	list

MacOSRet
GetCodecInfo(info, cType, codec)
	CodecInfo *	info
	CodecType	cType
	CodecComponent	codec

=end ignore

=cut

long
GetMaxCompressionSize(src, srcRect, colorDepth, quality, cType, codec, size)
	PixMapHandle	src
	const Rect *	srcRect
	short	colorDepth
	CodecQ	quality
	CodecType	cType
	CompressorComponent	codec
	CODE:
	if (gMacPerl_OSErr = 
		GetMaxCompressionSize(
			src, srcRect, colorDepth, quality, cType, codec, &RETVAL)
	) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

long
GetCSequenceMaxCompressionSize(seqID, src)
	long			seqID
	PixMapHandle	src
	CODE:
	if (gMacPerl_OSErr = GetCSequenceMaxCompressionSize(seqID, src, &RETVAL)) {
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
GetCompressionTime(src, srcRect, colorDepth, cType, codec, spatialQuality=,temporalQuality=)
	PixMapHandle	src
	Rect 		   &srcRect
	short			colorDepth
	CodecType		cType
	Component		codec
	CodecQ			spatialQuality;
	CodecQ			temporalQuality;
	PPCODE:
	{
		unsigned long	compressTime;
		
		if (items < 7) 
			gMacPerl_OSErr = 
				GetCompressionTime(
					src, &srcRect, colorDepth, cType, codec, nil, nil, &compressTime);
		else
			gMacPerl_OSErr = 
				GetCompressionTime(
					src, &srcRect, colorDepth, cType, codec, 
					&spatialQuality, &temporalQuality, &compressTime);
		if (gMacPerl_OSErr) {
			XSRETURN_EMPTY;
		}
		if (items == 7 && GIMME == G_ARRAY) {
			XS_XPUSH(CodecQ, spatialQuality);
			XS_XPUSH(CodecQ, temporalQuality);
		} 
		XS_PUSH(U32, compressTime);
	}

void
CompressImage(src, srcRect, quality, cType)
	PixMapHandle	src
	Rect 		   &srcRect
	CodecQ			quality
	CodecType		cType
	PPCODE:
	{
		ImageDescriptionHandle	desc;
		SV *					data;
		long					size;
		
		if (gMacPerl_OSErr = 
			GetMaxCompressionSize(src, &srcRect, 0, quality, cType, anyCodec, &size)
		) {
			XSRETURN_EMPTY;
		}
		desc = (ImageDescriptionHandle)NewHandle(sizeof(ImageDescription));
		data = newSVpv("", size);
		gMacPerl_OSErr = 
			CompressImage(src, &srcRect, quality, cType, desc, SvPVX(RETVAL));
		if (!gMacPerl_OSErr) {
			SvLEN_set(data, desc[0]->dataSize);
			XS_XPUSH(ImageDescriptionHandle, desc);
			/* We do a copy since the result often shrinks */
			XPUSHs(sv_mortalcopy(data));
		} else {
			DisposeHandle((Handle)desc);
		}
		SvREFCNT_dec(data);
		if (gMacPerl_OSErr) {
			XSRETURN_EMPTY;
		}
	}

MacOSRet
FCompressImage(src, srcRect, colorDepth, quality, cType, codec, ctable, flags)
	PixMapHandle	src
	Rect 		   &srcRect
	short			colorDepth
	CodecQ			quality
	CodecType		cType
	Component		codec
	CTabHandle		ctable
	CodecFlags		flags
	PPCODE:
	{
		ImageDescriptionHandle	desc;
		SV *					data;
		long					size;
		
		if (gMacPerl_OSErr = 
			GetMaxCompressionSize(src, &srcRect, colorDepth, quality, cType, codec, &size)
		) {
			XSRETURN_EMPTY;
		}
		desc = (ImageDescriptionHandle)NewHandle(sizeof(ImageDescription));
		data = newSVpv("", size);
		gMacPerl_OSErr = 
			FCompressImage(src, &srcRect, colorDepth, quality, cType, codec, ctable, flags, size, nil, nil, desc, SvPVX(RETVAL));
		if (!gMacPerl_OSErr) {
			SvLEN_set(data, desc[0]->dataSize);
			XS_XPUSH(ImageDescriptionHandle, desc);
			/* We do a copy since the result often shrinks */
			XPUSHs(sv_mortalcopy(data));
		} else {
			DisposeHandle((Handle)desc);
		}
		SvREFCNT_dec(data);
		if (gMacPerl_OSErr) {
			XSRETURN_EMPTY;
		}
	}

MacOSRet
DecompressImage(data, desc, dst, srcRect, dstRect, mode, mask)
	char *			data
	ImageDescriptionHandle	desc
	PixMapHandle	dst
	Rect 		   &srcRect
	Rect 		   &dstRect
	short			mode
	RgnHandle		mask

MacOSRet
FDecompressImage(data, desc, dst, srcRect, matrix, mode, mask, matte, matteRect, accuracy, codec)
	char *			data
	ImageDescriptionHandle	desc
	PixMapHandle	dst
	Rect 		   &srcRect
	MatrixRecord   &matrix
	short			mode
	RgnHandle		mask
	PixMapHandle	matte
	Rect 		   &matteRect
	CodecQ			accuracy
	Component		codec
	CODE:
	RETVAL = 
		FDecompressImage(
			data, desc, dst, srcRect, matrix, mode, mask, matte, matteRect, 
			accuracy, codec, SvCUR(ST(0)), nil, nil);
	OUTPUT:
	RETVAL
	
MacOSRet
CompressSequenceBegin(seqID, src, prev, srcRect, prevRect, colorDepth, cType, codec, spatialQuality, temporalQuality, keyFrameRate, ctable, flags, desc)
	ImageSequence *	seqID
	PixMapHandle	src
	PixMapHandle	prev
	const Rect *	srcRect
	const Rect *	prevRect
	short	colorDepth
	CodecType	cType
	Component	codec
	CodecQ	spatialQuality
	CodecQ	temporalQuality
	long	keyFrameRate
	CTabHandle	ctable
	CodecFlags	flags
	ImageDescriptionHandle	desc

MacOSRet
CompressSequenceFrame(seqID, src, srcRect, flags, data, dataSize, similarity, asyncCompletionProc)
	ImageSequence	seqID
	PixMapHandle	src
	const Rect *	srcRect
	CodecFlags	flags
	Ptr	data
	long *	dataSize
	UInt8 *	similarity
	ICMCompletionProcRecordPtr	asyncCompletionProc

MacOSRet
DecompressSequenceBegin(seqID, desc, port, gdh, srcRect, matrix, mode, mask, flags, accuracy, codec)
	ImageSequence *	seqID
	ImageDescriptionHandle	desc
	CGrafPtr	port
	GDHandle	gdh
	const Rect *	srcRect
	MatrixRecordPtr	matrix
	short	mode
	RgnHandle	mask
	CodecFlags	flags
	CodecQ	accuracy
	DeComponent	codec

MacOSRet
DecompressSequenceBeginS(seqID, desc, data, dataSize, port, gdh, srcRect, matrix, mode, mask, flags, accuracy, codec)
	ImageSequence *	seqID
	ImageDescriptionHandle	desc
	Ptr	data
	long	dataSize
	CGrafPtr	port
	GDHandle	gdh
	const Rect *	srcRect
	MatrixRecordPtr	matrix
	short	mode
	RgnHandle	mask
	CodecFlags	flags
	CodecQ	accuracy
	DeComponent	codec

MacOSRet
DecompressSequenceFrame(seqID, data, inFlags, outFlags, asyncCompletionProc)
	ImageSequence	seqID
	Ptr	data
	CodecFlags	inFlags
	CodecFlags *	outFlags
	ICMCompletionProcRecordPtr	asyncCompletionProc

MacOSRet
DecompressSequenceFrameS(seqID, data, dataSize, inFlags, outFlags, asyncCompletionProc)
	ImageSequence	seqID
	Ptr	data
	long	dataSize
	CodecFlags	inFlags
	CodecFlags *	outFlags
	ICMCompletionProcRecordPtr	asyncCompletionProc

MacOSRet
DecompressSequenceFrameWhen(seqID, data, dataSize, inFlags, outFlags, asyncCompletionProc, frameTime)
	ImageSequence	seqID
	Ptr	data
	long	dataSize
	CodecFlags	inFlags
	CodecFlags *	outFlags
	ICMCompletionProcRecordPtr	asyncCompletionProc
	const ICMFrameTimeRecord *	frameTime

MacOSRet
CDSequenceFlush(seqID)
	ImageSequence	seqID

MacOSRet
SetDSequenceMatrix(seqID, matrix)
	ImageSequence	seqID
	MatrixRecordPtr	matrix

MacOSRet
SetDSequenceMatte(seqID, matte, matteRect)
	ImageSequence	seqID
	PixMapHandle	matte
	const Rect *	matteRect

MacOSRet
SetDSequenceMask(seqID, mask)
	ImageSequence	seqID
	RgnHandle	mask

MacOSRet
SetDSequenceTransferMode(seqID, mode, opColor)
	ImageSequence	seqID
	short	mode
	const RGBColor *	opColor

MacOSRet
SetDSequenceDataProc(seqID, dataProc, bufferSize)
	ImageSequence	seqID
	ICMDataProcRecordPtr	dataProc
	long	bufferSize

MacOSRet
SetDSequenceAccuracy(seqID, accuracy)
	ImageSequence	seqID
	CodecQ	accuracy

MacOSRet
SetDSequenceSrcRect(seqID, srcRect)
	ImageSequence	seqID
	const Rect *	srcRect

MacOSRet
GetDSequenceImageBuffer(seqID, gworld)
	ImageSequence	seqID
	GWorldPtr *	gworld

MacOSRet
GetDSequenceScreenBuffer(seqID, gworld)
	ImageSequence	seqID
	GWorldPtr *	gworld

MacOSRet
SetCSequenceQuality(seqID, spatialQuality, temporalQuality)
	ImageSequence	seqID
	CodecQ	spatialQuality
	CodecQ	temporalQuality

MacOSRet
SetCSequencePrev(seqID, prev, prevRect)
	ImageSequence	seqID
	PixMapHandle	prev
	const Rect *	prevRect

MacOSRet
SetCSequenceFlushProc(seqID, flushProc, bufferSize)
	ImageSequence	seqID
	ICMFlushProcRecordPtr	flushProc
	long	bufferSize

MacOSRet
SetCSequenceKeyFrameRate(seqID, keyFrameRate)
	ImageSequence	seqID
	long	keyFrameRate

MacOSRet
GetCSequenceKeyFrameRate(seqID, keyFrameRate)
	ImageSequence	seqID
	long *	keyFrameRate

MacOSRet
GetCSequencePrevBuffer(seqID, gworld)
	ImageSequence	seqID
	GWorldPtr *	gworld

MacOSRet
CDSequenceBusy(seqID)
	ImageSequence	seqID

MacOSRet
CDSequenceEnd(seqID)
	ImageSequence	seqID

MacOSRet
CDSequenceEquivalentImageDescription(seqID, newDesc, equivalent)
	ImageSequence	seqID
	ImageDescriptionHandle	newDesc
	Boolean *	equivalent

MacOSRet
GetCompressedImageSize(desc, data, bufferSize, dataProc, dataSize)
	ImageDescriptionHandle	desc
	Ptr	data
	long	bufferSize
	ICMDataProcRecordPtr	dataProc
	long *	dataSize

MacOSRet
GetSimilarity(src, srcRect, desc, data, similarity)
	PixMapHandle	src
	const Rect *	srcRect
	ImageDescriptionHandle	desc
	Ptr	data
	Fixed *	similarity

MacOSRet
GetImageDescriptionCTable(desc, ctable)
	ImageDescriptionHandle	desc
	CTabHandle *	ctable

MacOSRet
SetImageDescriptionCTable(desc, ctable)
	ImageDescriptionHandle	desc
	CTabHandle	ctable

MacOSRet
GetImageDescriptionExtension(desc, extension, idType, index)
	ImageDescriptionHandle	desc
	Handle *	extension
	long	idType
	long	index

MacOSRet
AddImageDescriptionExtension(desc, extension, idType)
	ImageDescriptionHandle	desc
	Handle	extension
	long	idType

MacOSRet
RemoveImageDescriptionExtension(desc, idType, index)
	ImageDescriptionHandle	desc
	long	idType
	long	index

MacOSRet
CountImageDescriptionExtensionType(desc, idType, count)
	ImageDescriptionHandle	desc
	long	idType
	long *	count

MacOSRet
GetNextImageDescriptionExtensionType(desc, idType)
	ImageDescriptionHandle	desc
	long *	idType

MacOSRet
FindCodec(cType, specCodec, compressor, decompressor)
	CodecType	cType
	CodecComponent	specCodec
	Component *	compressor
	DeComponent *	decompressor

MacOSRet
CompressPicture(srcPicture, dstPicture, quality, cType)
	PicHandle	srcPicture
	PicHandle	dstPicture
	CodecQ	quality
	CodecType	cType

MacOSRet
FCompressPicture(srcPicture, dstPicture, colorDepth, ctable, quality, doDither, compressAgain, progressProc, cType, codec)
	PicHandle	srcPicture
	PicHandle	dstPicture
	short	colorDepth
	CTabHandle	ctable
	CodecQ	quality
	short	doDither
	short	compressAgain
	ICMProgressProcRecordPtr	progressProc
	CodecType	cType
	Component	codec

MacOSRet
CompressPictureFile(srcRefNum, dstRefNum, quality, cType)
	short	srcRefNum
	short	dstRefNum
	CodecQ	quality
	CodecType	cType

MacOSRet
FCompressPictureFile(srcRefNum, dstRefNum, colorDepth, ctable, quality, doDither, compressAgain, progressProc, cType, codec)
	short	srcRefNum
	short	dstRefNum
	short	colorDepth
	CTabHandle	ctable
	CodecQ	quality
	short	doDither
	short	compressAgain
	ICMProgressProcRecordPtr	progressProc
	CodecType	cType
	Component	codec

MacOSRet
GetPictureFileHeader(refNum, frame, header)
	short	refNum
	Rect *	frame
	OpenCPicParams *	header

MacOSRet
DrawPictureFile(refNum, frame, progressProc)
	short	refNum
	const Rect *	frame
	ICMProgressProcRecordPtr	progressProc

MacOSRet
DrawTrimmedPicture(srcPicture, frame, trimMask, doDither, progressProc)
	PicHandle	srcPicture
	const Rect *	frame
	RgnHandle	trimMask
	short	doDither
	ICMProgressProcRecordPtr	progressProc

MacOSRet
DrawTrimmedPictureFile(srcRefnum, frame, trimMask, doDither, progressProc)
	short	srcRefnum
	const Rect *	frame
	RgnHandle	trimMask
	short	doDither
	ICMProgressProcRecordPtr	progressProc

MacOSRet
MakeThumbnailFromPicture(picture, colorDepth, thumbnail, progressProc)
	PicHandle	picture
	short	colorDepth
	PicHandle	thumbnail
	ICMProgressProcRecordPtr	progressProc

MacOSRet
MakeThumbnailFromPictureFile(refNum, colorDepth, thumbnail, progressProc)
	short	refNum
	short	colorDepth
	PicHandle	thumbnail
	ICMProgressProcRecordPtr	progressProc

MacOSRet
MakeThumbnailFromPixMap(src, srcRect, colorDepth, thumbnail, progressProc)
	PixMapHandle	src
	const Rect *	srcRect
	short	colorDepth
	PicHandle	thumbnail
	ICMProgressProcRecordPtr	progressProc

MacOSRet
TrimImage(desc, inData, inBufferSize, dataProc, outData, outBufferSize, flushProc, trimRect, progressProc)
	ImageDescriptionHandle	desc
	Ptr	inData
	long	inBufferSize
	ICMDataProcRecordPtr	dataProc
	Ptr	outData
	long	outBufferSize
	ICMFlushProcRecordPtr	flushProc
	Rect *	trimRect
	ICMProgressProcRecordPtr	progressProc

MacOSRet
ConvertImage(srcDD, srcData, colorDepth, ctable, accuracy, quality, cType, codec, dstDD, dstData)
	ImageDescriptionHandle	srcDD
	Ptr	srcData
	short	colorDepth
	CTabHandle	ctable
	CodecQ	accuracy
	CodecQ	quality
	CodecType	cType
	CodecComponent	codec
	ImageDescriptionHandle	dstDD
	Ptr	dstData

MacOSRet
GetCompressedPixMapInfo(pix, desc, data, bufferSize, dataProc, progressProc)
	PixMapPtr	pix
	ImageDescriptionHandle *	desc
	Ptr *	data
	long *	bufferSize
	ICMDataProcRecord *	dataProc
	ICMProgressProcRecord *	progressProc

MacOSRet
SetCompressedPixMapInfo(pix, desc, data, bufferSize, dataProc, progressProc)
	PixMapPtr	pix
	ImageDescriptionHandle	desc
	Ptr	data
	long	bufferSize
	ICMDataProcRecordPtr	dataProc
	ICMProgressProcRecordPtr	progressProc

void
StdPix(src, srcRect, matrix, mode, mask, matte, matteRect, flags)
	PixMapPtr	src
	const Rect *	srcRect
	MatrixRecordPtr	matrix
	short	mode
	RgnHandle	mask
	PixMapPtr	matte
	const Rect *	matteRect
	short	flags

MacOSRet
TransformRgn(matrix, rgn)
	MatrixRecordPtr	matrix
	RgnHandle	rgn

void
SFGetFilePreview(where, prompt, fileFilter, numTypes, typeList, dlgHook, reply)
	Point	where
	Str255	prompt
	FileFilterUPP	fileFilter
	short	numTypes
	ConstSFTypeListPtr	typeList
	DlgHookUPP	dlgHook
	SFReply *	reply

void
SFPGetFilePreview(where, prompt, fileFilter, numTypes, typeList, dlgHook, reply, dlgID, filterProc)
	Point	where
	Str255	prompt
	FileFilterUPP	fileFilter
	short	numTypes
	ConstSFTypeListPtr	typeList
	DlgHookUPP	dlgHook
	SFReply *	reply
	short	dlgID
	ModalFilterUPP	filterProc

void
StandardGetFilePreview(fileFilter, numTypes, typeList, reply)
	FileFilterUPP	fileFilter
	short	numTypes
	ConstSFTypeListPtr	typeList
	StandardFileReply *	reply

void
CustomGetFilePreview(fileFilter, numTypes, typeList, reply, dlgID, where, dlgHook, filterProc, activeList, activateProc, yourDataPtr)
	FileFilterYDUPP	fileFilter
	short	numTypes
	ConstSFTypeListPtr	typeList
	StandardFileReply *	reply
	short	dlgID
	Point	where
	DlgHookYDUPP	dlgHook
	ModalFilterYDUPP	filterProc
	ActivationOrderListPtr	activeList
	ActivateYDUPP	activateProc
	void *	yourDataPtr

MacOSRet
MakeFilePreview(resRefNum, progress)
	short	resRefNum
	ICMProgressProcRecordPtr	progress

MacOSRet
AddFilePreview(resRefNum, previewType, previewData)
	short	resRefNum
	OSType	previewType
	Handle	previewData

void
AlignScreenRect(rp, alignmentProc)
	Rect *	rp
	ICMAlignmentProcRecordPtr	alignmentProc

void
AlignWindow(wp, front, alignmentRect, alignmentProc)
	GrafPtr	wp
	Boolean	front
	const Rect *	alignmentRect
	ICMAlignmentProcRecordPtr	alignmentProc

void
DragAlignedWindow(wp, startPt, boundsRect, alignmentRect, alignmentProc)
	GrafPtr	wp
	Point	startPt
	Rect *	boundsRect
	Rect *	alignmentRect
	ICMAlignmentProcRecordPtr	alignmentProc

long
DragAlignedGrayRgn(theRgn, startPt, boundsRect, slopRect, axis, actionProc, alignmentRect, alignmentProc)
	RgnHandle	theRgn
	Point	startPt
	Rect *	boundsRect
	Rect *	slopRect
	short	axis
	UniversalProcPtr	actionProc
	Rect *	alignmentRect
	ICMAlignmentProcRecordPtr	alignmentProc

MacOSRet
SetCSequenceDataRateParams(seqID, params)
	ImageSequence	seqID
	DataRateParamsPtr	params

MacOSRet
SetCSequenceFrameNumber(seqID, frameNumber)
	ImageSequence	seqID
	long	frameNumber

MacOSRet
SetCSequencePreferredPacketSize(seqID, preferredPacketSizeInBytes)
	ImageSequence	seqID
	long	preferredPacketSizeInBytes

MacOSRet
NewImageGWorld(gworld, idh, flags)
	GWorldPtr *	gworld
	ImageDescriptionHandle	idh
	GWorldFlags	flags

MacOSRet
GetCSequenceDataRateParams(seqID, params)
	ImageSequence	seqID
	DataRateParamsPtr	params

MacOSRet
GetCSequenceFrameNumber(seqID, frameNumber)
	ImageSequence	seqID
	long *	frameNumber

MacOSRet
GetBestDeviceRect(gdh, rp)
	GDHandle *	gdh
	Rect *	rp

MacOSRet
SetSequenceProgressProc(seqID, progressProc)
	ImageSequence	seqID
	ICMProgressProcRecord *	progressProc

MacOSRet
GDHasScale(gdh, depth, scale)
	GDHandle	gdh
	short	depth
	Fixed *	scale

MacOSRet
GDGetScale(gdh, scale, flags)
	GDHandle	gdh
	Fixed *	scale
	short *	flags

MacOSRet
GDSetScale(gdh, scale, flags)
	GDHandle	gdh
	Fixed	scale
	short	flags

MacOSRet
ICMShieldSequenceCursor(seqID)
	ImageSequence	seqID

void
ICMDecompressComplete(seqID, err, flag, completionRtn)
	ImageSequence	seqID
	OSErr	err
	short	flag
	ICMCompletionProcRecordPtr	completionRtn

MacOSRet
SetDSequenceTimeCode(seqID, timeCodeFormat, timeCodeTime)
	ImageSequence	seqID
	void *	timeCodeFormat
	void *	timeCodeTime

MacOSRet
CDSequenceNewMemory(seqID, data, dataSize, dataUse, memoryGoneProc, refCon)
	ImageSequence	seqID
	Ptr *	data
	Size	dataSize
	long	dataUse
	ICMMemoryDisposedUPP	memoryGoneProc
	void *	refCon

MacOSRet
CDSequenceDisposeMemory(seqID, data)
	ImageSequence	seqID
	Ptr	data

MacOSRet
CDSequenceNewDataSource(seqID, sourceID, sourceType, sourceInputNumber, dataDescription, transferProc, refCon)
	ImageSequence	seqID
	ImageSequenceDataSource *	sourceID
	OSType	sourceType
	long	sourceInputNumber
	Handle	dataDescription
	void *	transferProc
	void *	refCon

MacOSRet
CDSequenceDisposeDataSource(sourceID)
	ImageSequenceDataSource	sourceID

MacOSRet
CDSequenceSetSourceData(sourceID, data, dataSize)
	ImageSequenceDataSource	sourceID
	void *	data
	long	dataSize

MacOSRet
CDSequenceChangedSourceData(sourceID)
	ImageSequenceDataSource	sourceID

MacOSRet
PtInDSequenceData(seqID, data, dataSize, where, hit)
	ImageSequence	seqID
	void *	data
	Size	dataSize
	Point	where
	Boolean *	hit

MacOSRet
GetGraphicsImporterForFile(theFile, gi)
	const FSSpec *	theFile
	ComponentInstance *	gi

MacOSRet
GetGraphicsImporterForDataRef(dataRef, dataRefType, gi)
	Handle	dataRef
	OSType	dataRefType
	ComponentInstance *	gi

MacOSRet
ImageTranscodeSequenceBegin(its, srcDesc, destType, dstDesc, data, dataSize)
	ImageTranscodeSequence *	its
	ImageDescriptionHandle	srcDesc
	OSType	destType
	ImageDescriptionHandle *	dstDesc
	void *	data
	long	dataSize

MacOSRet
ImageTranscodeSequenceEnd(its)
	ImageTranscodeSequence	its

MacOSRet
ImageTranscodeFrame(its, srcData, srcDataSize, dstData, dstDataSize)
	ImageTranscodeSequence	its
	void *	srcData
	long	srcDataSize
	void **	dstData
	long *	dstDataSize

MacOSRet
ImageTranscodeDisposeFrameData(its, dstData)
	ImageTranscodeSequence	its
	void *	dstData

MacOSRet
CDSequenceInvalidate(seqID, invalRgn)
	ImageSequence	seqID
	RgnHandle	invalRgn

MacOSRet
ImageFieldSequenceBegin(ifs, desc1, desc2, descOut)
	ImageFieldSequence *	ifs
	ImageDescriptionHandle	desc1
	ImageDescriptionHandle	desc2
	ImageDescriptionHandle	descOut

MacOSRet
ImageFieldSequenceExtractCombine(ifs, fieldFlags, data1, dataSize1, data2, dataSize2, outputData, outDataSize)
	ImageFieldSequence	ifs
	long	fieldFlags
	void *	data1
	long	dataSize1
	void *	data2
	long	dataSize2
	void *	outputData
	long *	outDataSize

MacOSRet
ImageFieldSequenceEnd(ifs)
	ImageFieldSequence	ifs

short
GetMatrixType(m)
	const MatrixRecord *	m

void
CopyMatrix(m1, m2)
	const MatrixRecord *	m1
	MatrixRecord *	m2

Boolean
EqualMatrix(m1, m2)
	const MatrixRecord *	m1
	const MatrixRecord *	m2

void
SetIdentityMatrix(matrix)
	MatrixRecord *	matrix

void
TranslateMatrix(m, deltaH, deltaV)
	MatrixRecord *	m
	Fixed	deltaH
	Fixed	deltaV

void
RotateMatrix(m, degrees, aboutX, aboutY)
	MatrixRecord *	m
	Fixed	degrees
	Fixed	aboutX
	Fixed	aboutY

void
ScaleMatrix(m, scaleX, scaleY, aboutX, aboutY)
	MatrixRecord *	m
	Fixed	scaleX
	Fixed	scaleY
	Fixed	aboutX
	Fixed	aboutY

void
SkewMatrix(m, skewX, skewY, aboutX, aboutY)
	MatrixRecord *	m
	Fixed	skewX
	Fixed	skewY
	Fixed	aboutX
	Fixed	aboutY

MacOSRet
TransformFixedPoints(m, fpt, count)
	const MatrixRecord *	m
	FixedPoint *	fpt
	long	count

MacOSRet
TransformPoints(mp, pt1, count)
	const MatrixRecord *	mp
	Point *	pt1
	long	count

Boolean
TransformFixedRect(m, fr, fpp)
	const MatrixRecord *	m
	FixedRect *	fr
	FixedPoint *	fpp

Boolean
TransformRect(m, r, fpp)
	const MatrixRecord *	m
	Rect *	r
	FixedPoint *	fpp

Boolean
InverseMatrix(m, im)
	const MatrixRecord *	m
	MatrixRecord *	im

void
ConcatMatrix(a, b)
	const MatrixRecord *	a
	MatrixRecord *	b

void
RectMatrix(matrix, srcRect, dstRect)
	MatrixRecord *	matrix
	const Rect *	srcRect
	const Rect *	dstRect

void
MapMatrix(matrix, fromRect, toRect)
	MatrixRecord *	matrix
	const Rect *	fromRect
	const Rect *	toRect

void
CompAdd(src, dst)
	wide *	src
	wide *	dst

void
CompSub(src, dst)
	wide *	src
	wide *	dst

void
CompNeg(dst)
	wide *	dst

void
CompShift(src, shift)
	wide *	src
	short	shift

void
CompMul(src1, src2, dst)
	long	src1
	long	src2
	wide *	dst

long
CompDiv(numerator, denominator, remainder)
	wide *	numerator
	long	denominator
	long *	remainder

void
CompFixMul(compSrc, fixSrc, compDst)
	wide *	compSrc
	Fixed	fixSrc
	wide *	compDst

void
CompMulDiv(co, mul, divisor)
	wide *	co
	long	mul
	long	divisor

void
CompMulDivTrunc(co, mul, divisor, remainder)
	wide *	co
	long	mul
	long	divisor
	long *	remainder

long
CompCompare(a, minusb)
	wide *	a
	wide *	minusb

Fixed
FixMulDiv(src, mul, divisor)
	Fixed	src
	Fixed	mul
	Fixed	divisor

Fixed
UnsignedFixMulDiv(src, mul, divisor)
	Fixed	src
	Fixed	mul
	Fixed	divisor

Fract
FracSinCos(degree, cosOut)
	Fixed	degree
	Fract *	cosOut

Fixed
FixExp2(src)
	Fixed	src

Fixed
FixLog2(src)
	Fixed	src

Fixed
FixPow(base, exp)
	Fixed	base
	Fixed	exp

ComponentResult
GraphicsImportSetDataReference(ci, dataRef, dataReType)
	GraphicsImportComponent	ci
	Handle	dataRef
	OSType	dataReType

ComponentResult
GraphicsImportGetDataReference(ci, dataRef, dataReType)
	GraphicsImportComponent	ci
	Handle *	dataRef
	OSType *	dataReType

ComponentResult
GraphicsImportSetDataFile(ci, theFile)
	GraphicsImportComponent	ci
	const FSSpec *	theFile

ComponentResult
GraphicsImportGetDataFile(ci, theFile)
	GraphicsImportComponent	ci
	FSSpec *	theFile

ComponentResult
GraphicsImportSetDataHandle(ci, h)
	GraphicsImportComponent	ci
	Handle	h

ComponentResult
GraphicsImportGetDataHandle(ci, h)
	GraphicsImportComponent	ci
	Handle *	h

ComponentResult
GraphicsImportGetImageDescription(ci, desc)
	GraphicsImportComponent	ci
	ImageDescriptionHandle *	desc

ComponentResult
GraphicsImportGetDataOffsetAndSize(ci, offset, size)
	GraphicsImportComponent	ci
	unsigned long *	offset
	unsigned long *	size

ComponentResult
GraphicsImportReadData(ci, dataPtr, dataOffset, dataSize)
	GraphicsImportComponent	ci
	void *	dataPtr
	unsigned long	dataOffset
	unsigned long	dataSize

ComponentResult
GraphicsImportSetClip(ci, clipRgn)
	GraphicsImportComponent	ci
	RgnHandle	clipRgn

ComponentResult
GraphicsImportGetClip(ci, clipRgn)
	GraphicsImportComponent	ci
	RgnHandle *	clipRgn

ComponentResult
GraphicsImportSetSourceRect(ci, sourceRect)
	GraphicsImportComponent	ci
	const Rect *	sourceRect

ComponentResult
GraphicsImportGetSourceRect(ci, sourceRect)
	GraphicsImportComponent	ci
	Rect *	sourceRect

ComponentResult
GraphicsImportGetNaturalBounds(ci, naturalBounds)
	GraphicsImportComponent	ci
	Rect *	naturalBounds

ComponentResult
GraphicsImportDraw(ci)
	GraphicsImportComponent	ci

ComponentResult
GraphicsImportSetGWorld(ci, port, gd)
	GraphicsImportComponent	ci
	CGrafPtr	port
	GDHandle	gd

ComponentResult
GraphicsImportGetGWorld(ci, port, gd)
	GraphicsImportComponent	ci
	CGrafPtr *	port
	GDHandle *	gd

ComponentResult
GraphicsImportSetMatrix(ci, matrix)
	GraphicsImportComponent	ci
	const MatrixRecord *	matrix

ComponentResult
GraphicsImportGetMatrix(ci, matrix)
	GraphicsImportComponent	ci
	MatrixRecord *	matrix

ComponentResult
GraphicsImportSetBoundsRect(ci, bounds)
	GraphicsImportComponent	ci
	const Rect *	bounds

ComponentResult
GraphicsImportGetBoundsRect(ci, bounds)
	GraphicsImportComponent	ci
	Rect *	bounds

ComponentResult
GraphicsImportSaveAsPicture(ci, fss, scriptTag)
	GraphicsImportComponent	ci
	const FSSpec *	fss
	ScriptCode	scriptTag

ComponentResult
GraphicsImportSetGraphicsMode(ci, graphicsMode, opColor)
	GraphicsImportComponent	ci
	long	graphicsMode
	const RGBColor *	opColor

ComponentResult
GraphicsImportGetGraphicsMode(ci, graphicsMode, opColor)
	GraphicsImportComponent	ci
	long *	graphicsMode
	RGBColor *	opColor

ComponentResult
GraphicsImportSetQuality(ci, quality)
	GraphicsImportComponent	ci
	CodecQ	quality

ComponentResult
GraphicsImportGetQuality(ci, quality)
	GraphicsImportComponent	ci
	CodecQ *	quality

ComponentResult
GraphicsImportSaveAsQuickTimeImageFile(ci, fss, scriptTag)
	GraphicsImportComponent	ci
	const FSSpec *	fss
	ScriptCode	scriptTag

ComponentResult
GraphicsImportSetDataReferenceOffsetAndLimit(ci, offset, limit)
	GraphicsImportComponent	ci
	unsigned long	offset
	unsigned long	limit

ComponentResult
GraphicsImportGetDataReferenceOffsetAndLimit(ci, offset, limit)
	GraphicsImportComponent	ci
	unsigned long *	offset
	unsigned long *	limit

ComponentResult
GraphicsImportGetAliasedDataReference(ci, dataRef, dataRefType)
	GraphicsImportComponent	ci
	Handle *	dataRef
	OSType *	dataRefType

ComponentResult
GraphicsImportValidate(ci, valid)
	GraphicsImportComponent	ci
	Boolean *	valid

ComponentResult
ImageTranscoderBeginSequence(itc, srcDesc, dstDesc, data, dataSize)
	ImageTranscoderComponent	itc
	ImageDescriptionHandle	srcDesc
	ImageDescriptionHandle *	dstDesc
	void *	data
	long	dataSize

ComponentResult
ImageTranscoderConvert(itc, srcData, srcDataSize, dstData, dstDataSize)
	ImageTranscoderComponent	itc
	void *	srcData
	long	srcDataSize
	void **	dstData
	long *	dstDataSize

ComponentResult
ImageTranscoderDisposeData(itc, dstData)
	ImageTranscoderComponent	itc
	void *	dstData

ComponentResult
ImageTranscoderEndSequence(itc)
	ImageTranscoderComponent	itc


=back

=cut
