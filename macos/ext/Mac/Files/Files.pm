=head1 NAME

Mac::Files - Macintosh Toolbox Interface to the File and Alias Manager

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut

use strict;

package Mac::Files;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw(@ISA @EXPORT $VERSION);

	$VERSION = '1.01';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		FSpGetCatInfo
		FSpSetCatInfo
		FSMakeFSSpec
		FSpCreate
		FSpDirCreate
		FSpDelete
		FSpGetFInfo
		FSpSetFInfo
		FSpSetFLock
		FSpRstFLock
		FSpRename
		FSpCatMove
		FSpExchangeFiles
		NewAlias
		NewAliasRelative
		NewAliasMinimal
		NewAliasMinimalFromFullPath
		UpdateAlias
		UpdateAliasRelative
		ResolveAlias
		ResolveAliasRelative
		GetAliasInfo
		UnmountVol
		Eject
		FlushVol
		FindFolder
		kOnSystemDisk
		kCreateFolder
		kDontCreateFolder
		kSystemFolderType
		kDesktopFolderType
		kTrashFolderType
		kWhereToEmptyTrashFolderType
		kPrintMonitorDocsFolderType
		kStartupFolderType
		kShutdownFolderType
		kAppleMenuFolderType
		kControlPanelFolderType
		kExtensionFolderType
		kFontsFolderType
		kPreferencesFolderType
		kTemporaryFolderType
		asiZoneName
		asiServerName
		asiVolumeName
		asiAliasName
		asiParentName

		kSystemFolderType
		kDesktopFolderType
		kTrashFolderType
		kWhereToEmptyTrashFolderType
		kPrintMonitorDocsFolderType
		kStartupFolderType
		kShutdownFolderType
		kFontsFolderType
		kAppleMenuFolderType
		kControlPanelFolderType
		kExtensionFolderType
		kPreferencesFolderType
		kTemporaryFolderType
		kExtensionDisabledFolderType
		kControlPanelDisabledFolderType
		kSystemExtensionDisabledFolderType
		kStartupItemsDisabledFolderType
		kShutdownItemsDisabledFolderType
		kApplicationsFolderType
		kDocumentsFolderType
		kVolumeRootFolderType
		kChewableItemsFolderType
		kApplicationSupportFolderType
		kTextEncodingsFolderType
		kStationeryFolderType
		kOpenDocFolderType
		kOpenDocShellPlugInsFolderType
		kEditorsFolderType
		kOpenDocEditorsFolderType
		kOpenDocLibrariesFolderType
		kGenEditorsFolderType
		kHelpFolderType
		kInternetPlugInFolderType
		kModemScriptsFolderType
		kPrinterDescriptionFolderType
		kPrinterDriverFolderType
		kScriptingAdditionsFolderType
		kSharedLibrariesFolderType
		kVoicesFolderType
		kControlStripModulesFolderType
		kAssistantsFolderType
		kUtilitiesFolderType
		kAppleExtrasFolderType
		kContextualMenuItemsFolderType
		kMacOSReadMesFolderType
		kALMModulesFolderType
		kALMPreferencesFolderType
		kALMLocationsFolderType
		kColorSyncProfilesFolderType
		kThemesFolderType
		kFavoritesFolderType
		kInternetFolderType
		kAppearanceFolderType
		kSoundSetsFolderType
		kDesktopPicturesFolderType
		kInternetSearchSitesFolderType
		kFindSupportFolderType
		kFindByContentFolderType
		kInstallerLogsFolderType
		kScriptsFolderType
		kFolderActionsFolderType
		kLauncherItemsFolderType
		kRecentApplicationsFolderType
		kRecentDocumentsFolderType
		kRecentServersFolderType
		kSpeakableItemsFolderType
	);
}

bootstrap Mac::Files;


=head2 Constants

=over 4

=item kOnSystemDisk

=item kCreateFolder

=item kDontCreateFolder

Constants for Folder Manager.

=cut

sub kOnSystemDisk			() { 0x8000 }
sub kCreateFolder			() {      1 }
sub kDontCreateFolder			() {      0 }

=item kSystemFolderType

Specifies the System Folder.

=cut

sub kSystemFolderType			() { 'macs' }

=item kDesktopFolderType

Specifies the Desktop Folder.

=cut

sub kDesktopFolderType			() { 'desk' }

=item kTrashFolderType

Specifies the single-user Trash folder.

=cut

sub kTrashFolderType			() { 'trsh' }

=item kWhereToEmptyTrashFolderType

Specifies the shared Trash folder; on a file server, this indicates the parent directory of all logged-on users' Trash subdirectories.

=cut

sub kWhereToEmptyTrashFolderType	() { 'empt' }

=item kPrintMonitorDocsFolderType

Specifies the PrintMonitor Documents folder in the System Folder.

=cut

sub kPrintMonitorDocsFolderType		() { 'prnt' }

=item kStartupFolderType

Specifies the Startup Items folder in the System Folder.

=cut

sub kStartupFolderType			() { 'strt' }

=item kShutdownFolderType

Specifies the Shutdown Items folder in the System Folder.

=cut

sub kShutdownFolderType			() { 'shdf' }

=item kFontsFolderType

Specifies the Fonts folder in the System Folder.

=cut

sub kFontsFolderType			() { 'font' }

=item kAppleMenuFolderType

Specifies the Apple Menu Items folder in the System Folder.

=cut

sub kAppleMenuFolderType		() { 'amnu' }

=item kControlPanelFolderType

Specifies the Control Panels folder in the System Folder.

=cut

sub kControlPanelFolderType		() { 'ctrl' }

=item kExtensionFolderType

Specifies the Extensions folder in the System Folder.

=cut

sub kExtensionFolderType		() { 'extn' }

=item kPreferencesFolderType

Specifies the Preferences folder in the System Folder.

=cut

sub kPreferencesFolderType		() { 'pref' }

=item kTemporaryFolderType

Specifies the Temporary folder. This folder exists as an invisible folder at the volume root.

=cut

sub kTemporaryFolderType		() { 'temp' }

=item kExtensionDisabledFolderType

Specifies the Extensions (Disabled) folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kExtensionDisabledFolderType	() { 'extD' }

=item kControlPanelDisabledFolderType

Specifies the Control Panels (Disabled) folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kControlPanelDisabledFolderType	() { 'ctrD' }

=item kSystemExtensionDisabledFolderType

Specifies the System Extensions (Disabled) folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kSystemExtensionDisabledFolderType	() { 'macD' }

=item kStartupItemsDisabledFolderType

Specifies the Startup Items (Disabled) folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kStartupItemsDisabledFolderType	() { 'strD' }

=item kShutdownItemsDisabledFolderType

Specifies the Shutdown Items (Disabled) folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kShutdownItemsDisabledFolderType	() { 'shdD' }

=item kApplicationsFolderType

Specifies the Applications folder installed at the root level of the volume. Supported with Mac OS 8 and later.

=cut

sub kApplicationsFolderType		() { 'apps' }

=item kDocumentsFolderType

Specifies the Documents folder. This folder is created at the volume root. Supported with Mac OS 8 and later.

=cut

sub kDocumentsFolderType		() { 'docs' }

=item kVolumeRootFolderType

Specifies the root folder of a volume. Supported with Mac OS 8 and later.

=cut

sub kVolumeRootFolderType		() { 'root' }

=item kChewableItemsFolderType

Specifies the invisible folder on the system disk called "Cleanup at Startup" whose contents are deleted when the system is restarted, instead of merely being moved to the Trash. When the FindFolder function indicates this folder is available (by returning noErr ), developers should usually use this folder for their temporary items, in preference to the Temporary Folder. Supported with Mac OS 8 and later.

=cut

sub kChewableItemsFolderType		() { 'flnt' }

=item kApplicationSupportFolderType

Specifies the Application Support folder in the System Folder. This folder contains code and data files needed by third-party applications. These files should usually not be written to after they are installed. In general, files deleted from this folder remove functionality from an application, unlike files in the Preferences folder, which should be non-essential. One type of file that could be placed here would be plug-ins that the user might want to maintain separately from any application, such as for an image-processing application that has many "fourth-party" plug-ins that the user might want to upgrade separately from the host application. Another type of file that might belong in this folder would be application-specific data files that are not preferences, such as for a scanner application that needs to read description files for specific scanner models according to which are currently available on the SCSI bus or network. Supported with Mac OS 8 and later.

=cut

sub kApplicationSupportFolderType	() { 'asup' }

=item kTextEncodingsFolderType

Specifies the Text Encodings folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kTextEncodingsFolderType		() { 'ƒtex' }

=item kStationeryFolderType

Specifies the OpenDoc stationery folder. Supported with Mac OS 8 and later.

=cut

sub kStationeryFolderType		() { 'odst' }

=item kOpenDocFolderType

Specifies the OpenDoc root folder. Supported with Mac OS 8 and later.

=cut

sub kOpenDocFolderType			() { 'odod' }

=item kOpenDocShellPlugInsFolderType

Specifies the OpenDoc shell plug-ins folder in the OpenDoc folder. Supported with Mac OS 8 and later.

=cut

sub kOpenDocShellPlugInsFolderType	() { 'odsp' }

=item kEditorsFolderType

Specifies the OpenDoc editors folder in the Mac OS folder. Supported with Mac OS 8 and later.

=cut

sub kEditorsFolderType			() { 'oded' }

=item kOpenDocEditorsFolderType

Specifies the OpenDoc subfolder in the Editors folder. Supported with Mac OS 8 and later.

=cut

sub kOpenDocEditorsFolderType		() { 'ƒodf' }

=item kOpenDocLibrariesFolderType

Specifies the OpenDoc libraries folder. Supported with Mac OS 8 and later.

=cut

sub kOpenDocLibrariesFolderType		() { 'odlb' }

=item kGenEditorsFolderType

Specifies a general editors folder. Supported with Mac OS 8 and later.

=cut

sub kGenEditorsFolderType		() { 'ƒedi' }

=item kHelpFolderType

Specifies the Help folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kHelpFolderType			() { 'ƒhlp' }

=item kInternetPlugInFolderType

Specifies the Browser Plug-ins folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kInternetPlugInFolderType		() { 'ƒnet' }

=item kModemScriptsFolderType

Specifies the Modem Scripts folder in the Extensions folder. Supported with Mac OS 8 and later.

=cut

sub kModemScriptsFolderType		() { 'ƒmod' }

=item kPrinterDescriptionFolderType

Specifies the Printer Descriptions folder in the Extensions folder. Supported with Mac OS 8 and later.

=cut

sub kPrinterDescriptionFolderType	() { 'ppdf' }

=item kPrinterDriverFolderType

Specifies the printer drivers folder. This constant is not currently supported.

=cut

sub kPrinterDriverFolderType		() { 'ƒprd' }

=item kScriptingAdditionsFolderType

Specifies the Scripting Additions folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kScriptingAdditionsFolderType	() { 'ƒscr' }

=item kSharedLibrariesFolderType

Specifies the general shared libraries folder. This constant is not currently supported.

=cut

sub kSharedLibrariesFolderType		() { 'ƒlib' }

=item kVoicesFolderType

Specifies the Voices folder in the Extensions folder. Supported with Mac OS 8 and later.

=cut

sub kVoicesFolderType			() { 'fvoc' }

=item kControlStripModulesFolderType

Specifies the Control Strip Modules folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kControlStripModulesFolderType	() { 'sdev' }

=item kAssistantsFolderType

Specifies the Assistants folder installed at the root level of the volume. Supported with Mac OS 8 and later.

=cut

sub kAssistantsFolderType		() { 'astƒ' }

=item kUtilitiesFolderType

Specifies the Utilities folder installed at the root level of the volume. Supported with Mac OS 8 and later.

=cut

sub kUtilitiesFolderType		() { 'utiƒ' }

=item kAppleExtrasFolderType

Specifies the Apple Extras folder installed at the root level of the volume. Supported with Mac OS 8 and later.

=cut

sub kAppleExtrasFolderType		() { 'aexƒ' }

=item kContextualMenuItemsFolderType

Specifies the Contextual Menu Items folder in the System Folder. Supported with Mac OS 8 and later.

=cut

sub kContextualMenuItemsFolderType	() { 'cmnu' }

=item kMacOSReadMesFolderType

Specifies the Mac OS Read Me Files folder installed at the root level of the volume. Supported with Mac OS 8 and later.

=cut

sub kMacOSReadMesFolderType		() { 'morƒ' }

=item kALMModulesFolderType

Specifies the Location Manager Modules folder in the Extensions Folder. Supported with Mac OS 8.1 and later.

=cut

sub kALMModulesFolderType		() { 'walk' }

=item kALMPreferencesFolderType

Specifies the Location Manager Prefs folder in the Preferences folder. Supported with Mac OS 8.1 and later.

=cut

sub kALMPreferencesFolderType		() { 'trip' }

=item kALMLocationsFolderType

Specifies the Locations folder in the Location Manager Prefs folder. Files containing configuration information for different locations are stored here. Supported with Mac OS 8.1 and later.

=cut

sub kALMLocationsFolderType		() { 'fall' }

=item kColorSyncProfilesFolderType

Specifies the ColorSync Profiles folder in the System Folder. Supported with Mac OS 8.1 and later.

=cut

sub kColorSyncProfilesFolderType	() { 'prof' }

=item kThemesFolderType

Specifies the Theme Files folder in the Appearance folder. Supported with Mac OS 8.1 and later.

=cut

sub kThemesFolderType			() { 'thme' }

=item kFavoritesFolderType

Specifies the Favorites folder in the System Folder. This folder is for storing Internet location files, aliases, and aliases to other frequently used items. Facilities for adding items into this folder are found in Contextual Menus, the Finder, Navigation Services, and others. Supported with Mac OS 8.1 and later.

=cut

sub kFavoritesFolderType		() { 'favs' }

=item kInternetFolderType

Specifies the Internet folder installed at the root level of the volume. This folder is a location for saving Internet-related applications, resources, and tools. Supported with Mac OS 8.5 and later.

=cut

sub kInternetFolderType			() { 'intƒ' }

=item kAppearanceFolderType

Specifies the Appearance folder in the System Folder. Supported with Mac OS 8.5 and later.

=cut

sub kAppearanceFolderType		() { 'appr' }

=item kSoundSetsFolderType

Specifies the Sound Sets folder in the Appearance folder. Supported with Mac OS 8.5 and later.

=cut

sub kSoundSetsFolderType		() { 'snds' }

=item kDesktopPicturesFolderType

Specifies the Desktop Pictures folder in the Appearance folder. This folder is used for storing desktop picture files. Files of type 'JPEG' are auto-routed into this folder when dropped into the System Folder. Supported with Mac OS 8.5 and later.

=cut

sub kDesktopPicturesFolderType		() { 'dtpƒ' }

=item kInternetSearchSitesFolderType

Specifies the Internet Search Sites folder in the System Folder. This folder contains Internet search site specification files used by the Find application when it accesses Internet search sites. Files of type 'issp' are auto-routed to this folder. Supported with Mac OS 8.5 and later.

=cut

sub kInternetSearchSitesFolderType	() { 'issf' }

=item kFindSupportFolderType

Specifies the Find folder in the Extensions folder. This folder contains files used by the Find application. Supported with Mac OS 8.5 and later.

=cut

sub kFindSupportFolderType		() { 'fnds' }

=item kFindByContentFolderType

Specifies the Find By Content folder installed at the root level of the volume. This folder is invisible and its use is private to Find By Content. Supported with Mac OS 8.5 and later.

=cut

sub kFindByContentFolderType		() { 'fbcf' }

=item kInstallerLogsFolderType

Specifies the Installer Logs folder installed at the root level of the volume. You can use this folder to save installer log files. Supported with Mac OS 8.5 and later.

=cut

sub kInstallerLogsFolderType		() { 'ilgf' }

=item kScriptsFolderType

Specifies the Scripts folder in the System Folder. This folder is for saving AppleScript scripts. Supported with Mac OS 8.5 and later.

=cut

sub kScriptsFolderType			() { 'scrƒ' }

=item kFolderActionsFolderType

Specifies the Folder Action Scripts folder in the Scripts folder. Supported with Mac OS 8.5 and later.

=cut

sub kFolderActionsFolderType		() { 'fasf' }

=item kLauncherItemsFolderType

Specifies the Launcher Items folder in the System Folder. Items in this folder appear in the Launcher control panel. Items included in folders with names beginning with a bullet (Option-8) character will appear as a separate panel in the Launcher window. Supported with Mac OS 8.5 and later.

=cut

sub kLauncherItemsFolderType		() { 'laun' }

=item kRecentApplicationsFolderType

Specifies the Recent Applications folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recent applications here. Supported with Mac OS 8.5 and later.

=cut

sub kRecentApplicationsFolderType	() { 'rapp' }

=item kRecentDocumentsFolderType

Specifies the Recent Documents folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recently opened documents here. Supported with Mac OS 8.5 and later.

=cut

sub kRecentDocumentsFolderType		() { 'rdoc' }

=item kRecentServersFolderType

Specifies the Recent Servers folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recently mounted servers here. Supported with Mac OS 8.5 and later.

=cut

sub kRecentServersFolderType		() { 'rsvr' }

=item kSpeakableItemsFolderType

Specifies the Speakable Items folder. This folder is for storing scripts and items recognized by speech recognition. Supported with Mac OS 8.5 and later.

=cut

sub kSpeakableItemsFolderType		() { 'spki' }

=item asiZoneName

Return AppleTalk zone name from GetAliasInfo.

=cut

sub asiZoneName				() { -3 }

=item asiServerName

Return AppleTalk server name from GetAliasInfo.

=cut

sub asiServerName			() { -2 }

=item asiVolumeName

Return volume name from GetAliasInfo.

=cut

sub asiVolumeName			() { -1 }

=item asiAliasName

Return last component of target file name from GetAliasInfo.

=cut

sub asiAliasName			() { 0 }

=item asiParentName

Return name of enclosing folder from GetAliasInfo. This index value is 1.
Higher indices will return folder names higher up the hierarchy.

=cut

sub asiParentName			() { 1 }

=back

=cut

# 
# Translate volume name or number
#
sub _VolumeID {
	my ($id) = @_;
	my ($name, $vRef);
	if ($id =~ /^[^:]+:$/) {
		($name, $vRef) = ($id, 0);
	} else {
		($name, $vRef) = ("", $id);
	}
	return ($name, $vRef);
}

sub UnmountVol 	{	_UnmountVol(&_VolumeID);	}
sub Eject		{	_Eject     (&_VolumeID);	}
sub FlushVol 	{	_FlushVol  (&_VolumeID);	}

=include Files.xs

=head1 AUTHOR

Matthias Ulrich Neeracher <neeri@iis.ee.ethz.ch>

=cut

1;

__END__
