=head1 NAME

Mac::Navigation - Macintosh Toolbox Interface to Navigation Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut

use strict;

package Mac::Navigation;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		kNavDialogOptionsVersion
		kNavReplyRecordVersion
		kNavCBRecVersion
		kNavFileOrFolderVersion
		kNavMenuItemSpecVersion
		kNavSaveChangesClosingDocument
		kNavSaveChangesQuittingApplication
		kNavSaveChangesOther
		kNavAskSaveChangesSave
		kNavAskSaveChangesCancel
		kNavAskSaveChangesDontSave
		kNavAskDiscardChanges
		kNavAskDiscardChangesCancel
		kNavFilteringBrowserList
		kNavFilteringFavorites
		kNavFilteringRecents
		kNavFilteringShortCutVolumes
		kNavCBEvent
		kNavCBCustomize
		kNavCBStart
		kNavCBTerminate
		kNavCBAdjustRect
		kNavCBNewLocation
		kNavCBShowDesktop
		kNavCBSelectEntry
		kNavCBPopupMenuSelect
		kNavCBAccept
		kNavCBCancel
		kNavCBAdjustPreview
		kNavCtlShowDesktop
		kNavCtlSortBy
		kNavCtlSortOrder
		kNavCtlScrollHome
		kNavCtlScrollEnd
		kNavCtlPageUp
		kNavCtlPageDown
		kNavCtlGetLocation
		kNavCtlSetLocation
		kNavCtlGetSelection
		kNavCtlSetSelection
		kNavCtlShowSelection
		kNavCtlOpenSelection
		kNavCtlEjectVolume
		kNavCtlNewFolder
		kNavCtlCancel
		kNavCtlAccept
		kNavCtlIsPreviewShowing
		kNavCtlAddControl
		kNavCtlAddControlList
		kNavCtlGetFirstControlID
		kNavCtlSelectCustomType
		kNavCtlSelectAllType
		kNavCtlGetEditFileName
		kNavCtlSetEditFileName
		kNavAllKnownFiles
		kNavAllReadableFiles
		kNavAllFiles
		kNavSortNameField
		kNavSortDateField
		kNavSortAscending
		kNavSortDescending
		kNavDefaultNavDlogOptions
		kNavNoTypePopup
		kNavDontAutoTranslate
		kNavDontAddTranslateItems
		kNavAllFilesInPopup
		kNavAllowStationery
		kNavAllowPreviews
		kNavAllowMultipleFiles
		kNavAllowInvisibleFiles
		kNavDontResolveAliases
		kNavSelectDefaultLocation
		kNavSelectAllReadableItem
		kNavTranslateInPlace
		kNavTranslateCopy

		NavLoad
		NavUnload
		NavLibraryVersion
		NavGetDefaultDialogOptions
		NavGetFile
		NavPutFile
		NavAskSaveChanges
		NavCustomAskSaveChanges
		NavAskDiscardChanges
		NavChooseFile
		NavChooseFolder
		NavChooseVolume
		NavChooseObject
		NavNewFolder
		NavTranslateFile
		NavCompleteSave
		NavDisposeReply
		NavServicesCanRun
		NavServicesAvailable
	);
}

bootstrap Mac::Navigation;

=head2 Constants

=item kNavDialogOptionsVersion

=item kNavReplyRecordVersion

=item kNavCBRecVersion

=item kNavFileOrFolderVersion

=item kNavMenuItemSpecVersion

=item kNavSaveChangesClosingDocument

=item kNavSaveChangesQuittingApplication

=item kNavSaveChangesOther

=item kNavAskSaveChangesSave

=item kNavAskSaveChangesCancel

=item kNavAskSaveChangesDontSave

=item kNavAskDiscardChanges

=item kNavAskDiscardChangesCancel

=item kNavFilteringBrowserList

=item kNavFilteringFavorites

=item kNavFilteringRecents

=item kNavFilteringShortCutVolumes

=item kNavCBEvent

=item kNavCBCustomize

=item kNavCBStart

=item kNavCBTerminate

=item kNavCBAdjustRect

=item kNavCBNewLocation

=item kNavCBShowDesktop

=item kNavCBSelectEntry

=item kNavCBPopupMenuSelect

=item kNavCBAccept

=item kNavCBCancel

=item kNavCBAdjustPreview

=item kNavCtlShowDesktop

=item kNavCtlSortBy

=item kNavCtlSortOrder

=item kNavCtlScrollHome

=item kNavCtlScrollEnd

=item kNavCtlPageUp

=item kNavCtlPageDown

=item kNavCtlGetLocation

=item kNavCtlSetLocation

=item kNavCtlGetSelection

=item kNavCtlSetSelection

=item kNavCtlShowSelection

=item kNavCtlOpenSelection

=item kNavCtlEjectVolume

=item kNavCtlNewFolder

=item kNavCtlCancel

=item kNavCtlAccept

=item kNavCtlIsPreviewShowing

=item kNavCtlAddControl

=item kNavCtlAddControlList

=item kNavCtlGetFirstControlID

=item kNavCtlSelectCustomType

=item kNavCtlSelectAllType

=item kNavCtlGetEditFileName

=item kNavCtlSetEditFileName

=item kNavAllKnownFiles

=item kNavAllReadableFiles

=item kNavAllFiles

=item kNavSortNameField

=item kNavSortDateField

=item kNavSortAscending

=item kNavSortDescending

=item kNavDefaultNavDlogOptions

=item kNavNoTypePopup

=item kNavDontAutoTranslate

=item kNavDontAddTranslateItems

=item kNavAllFilesInPopup

=item kNavAllowStationery

=item kNavAllowPreviews

=item kNavAllowMultipleFiles

=item kNavAllowInvisibleFiles

=item kNavDontResolveAliases

=item kNavSelectDefaultLocation

=item kNavSelectAllReadableItem

=item kNavTranslateInPlace

=item kNavTranslateCopy

=cut
sub kNavDialogOptionsVersion ()    {          0; }
sub kNavReplyRecordVersion ()      {          0; }
sub kNavCBRecVersion ()            {          0; }
sub kNavFileOrFolderVersion ()     {          0; }
sub kNavMenuItemSpecVersion ()     {          0; }
sub kNavSaveChangesClosingDocument () {       1; }
sub kNavSaveChangesQuittingApplication () {   2; }
sub kNavSaveChangesOther ()        {          0; }
sub kNavAskSaveChangesSave ()      {          1; }
sub kNavAskSaveChangesCancel ()    {          2; }
sub kNavAskSaveChangesDontSave ()  {          3; }
sub kNavAskDiscardChanges ()       {          1; }
sub kNavAskDiscardChangesCancel () {          2; }
sub kNavFilteringBrowserList ()    {          0; }
sub kNavFilteringFavorites ()      {          1; }
sub kNavFilteringRecents ()        {          2; }
sub kNavFilteringShortCutVolumes (){          3; }
sub kNavCBEvent ()                 {          0; }
sub kNavCBCustomize ()             {          1; }
sub kNavCBStart ()                 {          2; }
sub kNavCBTerminate ()             {          3; }
sub kNavCBAdjustRect ()            {          4; }
sub kNavCBNewLocation ()           {          5; }
sub kNavCBShowDesktop ()           {          6; }
sub kNavCBSelectEntry ()           {          7; }
sub kNavCBPopupMenuSelect ()       {          8; }
sub kNavCBAccept ()                {          9; }
sub kNavCBCancel ()                {         10; }
sub kNavCBAdjustPreview ()         {         11; }
sub kNavCtlShowDesktop ()          {          0; }
sub kNavCtlSortBy ()               {          1; }
sub kNavCtlSortOrder ()            {          2; }
sub kNavCtlScrollHome ()           {          3; }
sub kNavCtlScrollEnd ()            {          4; }
sub kNavCtlPageUp ()               {          5; }
sub kNavCtlPageDown ()             {          6; }
sub kNavCtlGetLocation ()          {          7; }
sub kNavCtlSetLocation ()          {          8; }
sub kNavCtlGetSelection ()         {          9; }
sub kNavCtlSetSelection ()         {         10; }
sub kNavCtlShowSelection ()        {         11; }
sub kNavCtlOpenSelection ()        {         12; }
sub kNavCtlEjectVolume ()          {         13; }
sub kNavCtlNewFolder ()            {         14; }
sub kNavCtlCancel ()               {         15; }
sub kNavCtlAccept ()               {         16; }
sub kNavCtlIsPreviewShowing ()     {         17; }
sub kNavCtlAddControl ()           {         18; }
sub kNavCtlAddControlList ()       {         19; }
sub kNavCtlGetFirstControlID ()    {         20; }
sub kNavCtlSelectCustomType ()     {         21; }
sub kNavCtlSelectAllType ()        {         22; }
sub kNavCtlGetEditFileName ()      {         23; }
sub kNavCtlSetEditFileName ()      {         24; }
sub kNavAllKnownFiles ()           {          0; }
sub kNavAllReadableFiles ()        {          1; }
sub kNavAllFiles ()                {          2; }
sub kNavSortNameField ()           {          0; }
sub kNavSortDateField ()           {          1; }
sub kNavSortAscending ()           {          0; }
sub kNavSortDescending ()          {          1; }
sub kNavDefaultNavDlogOptions ()   { 0x000000E4; }
sub kNavNoTypePopup ()             { 0x00000001; }
sub kNavDontAutoTranslate ()       { 0x00000002; }
sub kNavDontAddTranslateItems ()   { 0x00000004; }
sub kNavAllFilesInPopup ()         { 0x00000010; }
sub kNavAllowStationery ()         { 0x00000020; }
sub kNavAllowPreviews ()           { 0x00000040; }
sub kNavAllowMultipleFiles ()      { 0x00000080; }
sub kNavAllowInvisibleFiles ()     { 0x00000100; }
sub kNavDontResolveAliases ()      { 0x00000200; }
sub kNavSelectDefaultLocation ()   { 0x00000400; }
sub kNavSelectAllReadableItem ()   { 0x00000800; }
sub kNavTranslateInPlace ()        {          0; }
sub kNavTranslateCopy ()           {          1; }

=head2 Types

=over 4

=cut
package NavTypeListHandle;

BEGIN {
	use Mac::Memory 	qw(NewHandle);
	use Mac::Resources 	qw(GetResource);
	use Carp;
}

=item NavTypeListHandle

A list of file types accepted by this application.

=over 4

=item new NavTypeListHandle [RSRCTYPE, ] RSRCID

=item new NavTypeListHandle APPSIG, [ TYPE ...]

=cut
sub new {
	my($handle);
	shift @_;
	
	if (scalar(@_) == 0) {
		croak "new NavTypeListHandle called without arguments";
	} elsif (scalar(@_) == 2 && ref($_[1]) eq "ARRAY") {
		$handle = new Handle($_[0] . pack("xxs", scalar(@{$_[1]})). "@{$_[1]}");
	} else {
		my($type) = scalar(@_) == 2 ? (shift @_) : "open";
		my($id) = @_;
		$handle = GetResource($type, $id);
	}
	bless $handle, "NavTypeListHandle";
}

=back

=include Navigation.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeracher@mac.com> 

=cut

1;

__END__
