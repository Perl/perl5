=head1 NAME

Mac::Resources - Macintosh Toolbox Interface to the Resource Manager

=head1 SYNOPSIS

	use Mac::Memory;
	use Mac::Resources;

=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Resources;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		CloseResFile
		CurResFile
		HomeResFile
		CreateResFile
		OpenResFile
		UseResFile
		CountTypes
		Count1Types
		GetIndType
		Get1IndType
		SetResLoad
		CountResources
		Count1Resources
		GetIndResource
		Get1IndResource
		GetResource
		Get1Resource
		GetNamedResource
		Get1NamedResource
		LoadResource
		ReleaseResource
		DetachResource
		UniqueID
		Unique1ID
		GetResAttrs
		GetResInfo
		SetResInfo
		AddResource
		GetResourceSizeOnDisk
		GetMaxResourceSize
		RsrcMapEntry
		SetResAttrs
		ChangedResource
		RemoveResource
		UpdateResFile
		WriteResource
		SetResPurge
		GetResFileAttrs
		SetResFileAttrs
		RGetResource
		FSpOpenResFile
		FSpCreateResFile
		ReadPartialResource
		WritePartialResource
		SetResourceSize
	
		resSysHeap
		resPurgeable
		resLocked
		resProtected
		resPreload
		resChanged
		mapReadOnly
		mapCompact
		mapChanged
		kResFileNotOpened
		kSystemResFile
	);
}

bootstrap Mac::Resources;

=head2 Constants

=over 4

=item resSysHeap

=item resPurgeable

=item resLocked

=item resProtected

=item resPreload

=item resChanged 

Resource flags.

=cut
sub resSysHeap ()                  {         64; }
sub resPurgeable ()                {         32; }
sub resLocked ()                   {         16; }
sub resProtected ()                {          8; }
sub resPreload ()                  {          4; }
sub resChanged ()                  {          2; }

=item mapReadOnly

=item mapCompact

=item mapChanged

Resource map flags.

=cut
sub mapReadOnly ()                 {        128; }
sub mapCompact ()                  {         64; }
sub mapChanged ()                  {         32; }

=item kResFileNotOpened

Returned after an unsuccessful call to C<OpenResFile()>

=cut
sub kResFileNotOpened ()           {         -1; }

=item kSystemResFile

The resource file reference number of the system file.

=cut
sub kSystemResFile ()              {          0; }

=back

=include Resources.xs

=head1 AUTHOR

Matthias Ulrich Neeracher <neeracher@mac.com> "Programs"

Bob Dalgleish <bob.dalgleish@sasknet.sk.ca> "Documentation"

=cut

1;

__END__
