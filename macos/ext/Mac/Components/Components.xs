/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Components/Components.xs,v 1.2 2000/09/09 22:18:26 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Components.xs,v $
 * Revision 1.2  2000/09/09 22:18:26  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:30:19  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:52:09  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:14  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Components.h>

static ComponentDescription * MakeComponentDesc(
	SV *				componentType,
	SV *				componentSubType,
	SV *				componentManufacturer,
	unsigned long	componentFlags,
	unsigned long	componentFlagsMask)
{
	static ComponentDescription	desc;
	
	if (SvTRUE(componentType))
		desc.componentType = *(OSType *)SvPV_nolen(componentType);
	else 
		desc.componentType = 0;
	if (SvTRUE(componentSubType))
		desc.componentSubType = *(OSType *)SvPV_nolen(componentSubType);
	else 
		desc.componentSubType = 0;
	if (SvTRUE(componentManufacturer))
		desc.componentManufacturer = *(OSType *)SvPV_nolen(componentManufacturer);
	else 
		desc.componentManufacturer = 0;
	desc.componentFlags		= componentFlags;
	desc.componentFlagsMask	= componentFlagsMask;
	
	return &desc;
}

static SV * MakeOSSV(OSType type)
{
	return type ? newSVpv((char *) &type, 4) : newSVpv("", 0);
}

MODULE = Mac::Components	PACKAGE = Mac::Components

=head1 EXTENSION

Mac::Components - Extension description

=head2 Mac::Components

=item RegisterComponentResource TR, GLOBAL

The RegisterComponentResource function makes a component available for use by
applications (or other clients). Once the Component Manager has registered a
component, applications can find and open the component using the standard
Component Manager routines. You provide information identifying the component and
specifying its capabilities. The Component Manager returns a component identifier
that uniquely identifies the component to the system.

=cut
Component
RegisterComponentResource(tr, global)
	Handle	tr 
	short		global
	CODE:
	RETVAL = RegisterComponentResource((ComponentResourceHandle) tr, global);
	OUTPUT:
	RETVAL

=item UnregisterComponent ACOMPONENT

The UnregisterComponent function removes a component from the Component Manager’s
registration list. Most components are registered at startup and remain
registered until the computer is shut down. However, you may want to provide some
services temporarily. In that case you dispose of the component that provides the
temporary service by using this function.
Returns zero on failure.

=cut
MacOSRet
UnregisterComponent(aComponent)
	Component aComponent

=item FindNextComponent ACOMPONENT, [COMPONENTTYPE, [COMPONENTSUBTYPE, [COMPONENTMANUFACTURER, [COMPONENTFLAGS, [COMPONENTFLAGSMASK]]]]]

The FindNextComponent function returns the component identifier of a component
that meets the search criteria. FindNextComponent returns a function result of 0
when there are no more matching components. 

=cut
Component
FindNextComponent(aComponent, componentType = &PL_sv_undef, componentSubType = &PL_sv_undef, componentManufacturer = &PL_sv_undef, componentFlags = 0, componentFlagsMask = 0)
	Component		aComponent
	SV *				componentType
	SV *				componentSubType
	SV *				componentManufacturer
	unsigned long	componentFlags
	unsigned long	componentFlagsMask
	CODE:
	RETVAL = 
		FindNextComponent(
			aComponent, 
			MakeComponentDesc(componentType, componentSubType, componentManufacturer, componentFlags, componentFlagsMask));
	OUTPUT:
	RETVAL

=item CountComponents [COMPONENTTYPE, [COMPONENTSUBTYPE, [COMPONENTMANUFACTURER, [COMPONENTFLAGS, [COMPONENTFLAGSMASK]]]]]

The CountComponents function returns a long integer containing the number of
components that meet the specified search criteria.

=cut
long
CountComponents(componentType = &PL_sv_undef, componentSubType = &PL_sv_undef, componentManufacturer = &PL_sv_undef, componentFlags = 0, componentFlagsMask = 0)
	SV *				componentType
	SV *				componentSubType
	SV *				componentManufacturer
	unsigned long	componentFlags
	unsigned long	componentFlagsMask
	CODE:
	RETVAL = 
		CountComponents(
			MakeComponentDesc(componentType, componentSubType, componentManufacturer, componentFlags, componentFlagsMask));
	OUTPUT:
	RETVAL

=item GetComponentInfo ACOMPONENT

The GetComponentInfo function returns information about the specified component.

	($info, $name, $mask, $flags, $manufacturer, $subtype, $type) =
		GetComponentInfo($Component);

=cut
void
GetComponentInfo(aComponent)
	Component	aComponent
	PREINIT:
	ComponentDescription	desc;
	Handle					name;
	Handle					info;
	PPCODE:
	name = NewEmptyHandle();
	info = NewEmptyHandle();
	gMacPerl_OSErr = GetComponentInfo(aComponent, &desc, name, info, nil);
	HLock(name);
	HLock(info);
	if (!gMacPerl_OSErr) 
		if (GIMME != G_ARRAY) {
			XS_XPUSH(Str255, (StringPtr)*name);
		} else {
			XPUSHs(sv_2mortal(MakeOSSV(desc.componentType)));
			XPUSHs(sv_2mortal(MakeOSSV(desc.componentSubType)));
			XPUSHs(sv_2mortal(MakeOSSV(desc.componentManufacturer)));
			XPUSHs(sv_2mortal(newSViv(desc.componentFlags)));
			XPUSHs(sv_2mortal(newSViv(desc.componentFlagsMask)));
			XS_XPUSH(Str255, (StringPtr)*name);
			XS_XPUSH(Str255, (StringPtr)*info);
		}
	DisposeHandle(name);
	DisposeHandle(info);

=item GetComponentListModSeed

The GetComponentListModSeed function allows you to determine if the list of
registered components has changed. This function returns the value of the
component registration seed number.

=cut
long 
GetComponentListModSeed()

=item OpenComponent ACOMPONENT

The OpenComponent function allows your application to gain access to the services
provided by a component. Your application must open a component before it can
call any component functions. You specify the component with a component
identifier that your application previously obtained from the FindNextComponent
function.
Returns ComponentInstance.

=cut
ComponentInstance
OpenComponent(aComponent)
	Component aComponent

=item CloseComponent ACOMPONENTINSTANCE

The CloseComponent function terminates your application’s access to the services
provided by a component. Your application specifies the connection to be closed
with the component instance returned by the OpenComponent() or OpenDefaultComponent()
function.
Returns zero on failure.

=cut
MacOSRet
CloseComponent(aComponentInstance)
	ComponentInstance	aComponentInstance

=item GetComponentInstanceError ACOMPONENTINSTANCE

The GetComponentInstanceError function returns the last error generated by a
specific connection to a component.
Returns zero on failure.

=cut
MacOSRet
GetComponentInstanceError(aComponentInstance)
	ComponentInstance	aComponentInstance

=item ComponentFunctionImplemented CI, FTNNUMBER

The ComponentFunctionImplemented function allows you to determine whether a
component supports a specified request. Your application can use this function to
determine a component’s capabilities. 
Returns 1 if supported.

=cut
long
ComponentFunctionImplemented(ci, ftnNumber)
	ComponentInstance ci
	short 				ftnNumber

=item GetComponentVersion CI

The GetComponentVersion function returns a component’s version number
as a coded integer.

=cut
long
GetComponentVersion(ci)
	ComponentInstance	ci

=item SetDefaultComponent ACOMPONENT, FLAGS

The SetDefaultComponent function allows your component to change the search order
for registered components. You specify a component that is to be placed at the
front of the search chain, along with control information that governs the
reordering operation. The order of the search chain influences which component
the Component Manager selects in response to an application’s use of the
OpenDefaultComponent() and FindNextComponent() functions.
Returns zero on failure.

=cut
MacOSRet
SetDefaultComponent(aComponent, flags)
	Component	aComponent
	short 		flags

=item OpenDefaultComponent COMPONENTTYPE, [COMPONENTSUBTYPE]

The OpenDefaultComponent function allows your application to gain access to the
services provided by a component. Your application must open a component before
it can call any component functions. You specify the component type and subtype
values of the component to open. The Component Manager searches for a component
that meets those criteria. If you want to exert more control over the selection
process, you can use the FindNextComponent() and OpenComponent() functions.
Returns ComponentInstance.

=cut
ComponentInstance
OpenDefaultComponent(componentType, componentSubType = 0)
	OSType componentType
	OSType componentSubType

=item RegisterComponentResourceFile RESREFNUM, GLOBAL

The RegisterComponentResourceFile function registers all component resources in
the given resource file according to the flags specified in the global parameter.
Returns an integer value.

=cut
long 
RegisterComponentResourceFile(resRefNum, global)
	short resRefNum
	short global
	CLEANUP:
	if (RETVAL < 0) {
		gMacPerl_OSErr = (short) RETVAL;
		XSRETURN_UNDEF;
	}

