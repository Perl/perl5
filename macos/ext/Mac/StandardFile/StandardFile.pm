=head1 NAME

Mac::StandardFile - Macintosh Toolbox Interface to the standard file dialogs.

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to Inside Macintosh is essential for proper use of these functions.
Explanations of terms, processes and procedures are provided there.
Any attempt to use these functions without guidance can cause severe errors in 
your machine, including corruption of data. B<You have been warned.>

=cut
	
use strict;

package Mac::StandardFile;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		StandardPutFile
		StandardGetFile
		CustomPutFile
		CustomGetFile
		StandardOpenDialog
	
		putDlgID
		putSave
		putCancel
		putEject
		putDrive
		putName
		getDlgID
		getOpen
		getCancel
		getEject
		getDrive
		getNmList
		getScroll
		sfPutDialogID
		sfGetDialogID
		sfItemOpenButton
		sfItemCancelButton
		sfItemBalloonHelp
		sfItemVolumeUser
		sfItemEjectButton
		sfItemDesktopButton
		sfItemFileListUser
		sfItemPopUpMenuUser
		sfItemDividerLinePict
		sfItemFileNameTextEdit
		sfItemPromptStaticText
		sfItemNewFolderUser
		sfHookFirstCall
		sfHookCharOffset
		sfHookNullEvent
		sfHookRebuildList
		sfHookFolderPopUp
		sfHookOpenFolder
		sfHookOpenAlias
		sfHookGoToDesktop
		sfHookGoToAliasTarget
		sfHookGoToParent
		sfHookGoToNextDrive
		sfHookGoToPrevDrive
		sfHookChangeSelection
		sfHookSetActiveOffset
		sfHookLastCall
		sfMainDialogRefCon
		sfNewFolderDialogRefCon
		sfReplaceDialogRefCon
		sfStatWarnDialogRefCon
		sfLockWarnDialogRefCon
		sfErrorDialogRefCon
	);
}

bootstrap Mac::StandardFile;

=head2 Constants

=over 4

=item putDlgID

=item putSave

=item putCancel

=item putEject

=item putDrive

=item putName

The old put dialog and its items.

=cut
sub putDlgID ()                    {      -3999; }
sub putSave ()                     {          1; }
sub putCancel ()                   {          2; }
sub putEject ()                    {          5; }
sub putDrive ()                    {          6; }
sub putName ()                     {          7; }


=item getDlgID

=item getOpen

=item getCancel

=item getEject

=item getDrive

=item getNmList

=item getScroll

The old get dialog and its items.

=cut
sub getDlgID ()                    {      -4000; }
sub getOpen ()                     {          1; }
sub getCancel ()                   {          3; }
sub getEject ()                    {          5; }
sub getDrive ()                    {          6; }
sub getNmList ()                   {          7; }
sub getScroll ()                   {          8; }


=item sfPutDialogID

=cut
sub sfPutDialogID ()               {      -6043; }


=item sfGetDialogID

=item sfItemOpenButton

=item sfItemCancelButton

=item sfItemBalloonHelp

=item sfItemVolumeUser

=item sfItemEjectButton

=item sfItemDesktopButton

=item sfItemFileListUser

=item sfItemPopUpMenuUser

=item sfItemDividerLinePict

=item sfItemFileNameTextEdit

=item sfItemPromptStaticText

=item sfItemNewFolderUser

The new dialogs and their items.

=cut
sub sfGetDialogID ()               {      -6042; }
sub sfItemOpenButton ()            {          1; }
sub sfItemCancelButton ()          {          2; }
sub sfItemBalloonHelp ()           {          3; }
sub sfItemVolumeUser ()            {          4; }
sub sfItemEjectButton ()           {          5; }
sub sfItemDesktopButton ()         {          6; }
sub sfItemFileListUser ()          {          7; }
sub sfItemPopUpMenuUser ()         {          8; }
sub sfItemDividerLinePict ()       {          9; }
sub sfItemFileNameTextEdit ()      {         10; }
sub sfItemPromptStaticText ()      {         11; }
sub sfItemNewFolderUser ()         {         12; }


=item sfHookFirstCall

=item sfHookCharOffset

=item sfHookNullEvent

=item sfHookRebuildList

=item sfHookFolderPopUp

=item sfHookOpenFolder

=item sfHookOpenAlias

=item sfHookGoToDesktop

=item sfHookGoToAliasTarget

=item sfHookGoToParent

=item sfHookGoToNextDrive

=item sfHookGoToPrevDrive

=item sfHookChangeSelection

=item sfHookSetActiveOffset

=item sfHookLastCall

Pseudo-items for the dialog filters.

=cut
sub sfHookFirstCall ()             {         -1; }
sub sfHookCharOffset ()            {     0x1000; }
sub sfHookNullEvent ()             {        100; }
sub sfHookRebuildList ()           {        101; }
sub sfHookFolderPopUp ()           {        102; }
sub sfHookOpenFolder ()            {        103; }
sub sfHookOpenAlias ()             {        104; }
sub sfHookGoToDesktop ()           {        105; }
sub sfHookGoToAliasTarget ()       {        106; }
sub sfHookGoToParent ()            {        107; }
sub sfHookGoToNextDrive ()         {        108; }
sub sfHookGoToPrevDrive ()         {        109; }
sub sfHookChangeSelection ()       {        110; }
sub sfHookSetActiveOffset ()       {        200; }
sub sfHookLastCall ()              {         -2; }


=item sfMainDialogRefCon

=item sfNewFolderDialogRefCon

=item sfReplaceDialogRefCon

=item sfStatWarnDialogRefCon

=item sfLockWarnDialogRefCon

=item sfErrorDialogRefCon

Refcons to distinguish the dialogs.

=cut
sub sfMainDialogRefCon ()          {     0x73746466; } # 'stdf'
sub sfNewFolderDialogRefCon ()     {     0x6E666472; } # 'nfdr'
sub sfReplaceDialogRefCon ()       {     0x72706C63; } # 'rplc'
sub sfStatWarnDialogRefCon ()      {     0x73746174; } # 'stat'
sub sfLockWarnDialogRefCon ()      {     0x6C6F636B; } # 'lock'
sub sfErrorDialogRefCon ()         {     0x65727220; } # 'err '

=back

=include StandardFile.xs

=head1 BUGS/LIMITATIONS

=head1 FILES

=head1 AUTHOR(S)

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch> 

=cut

1;

__END__
