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

                kALMLocationsFolderType
                kALMModulesFolderType
                kALMPreferencesFolderType
                kAppearanceFolderType
                kAppleExtrasFolderType
                kAppleMenuFolderType
                kApplicationSupportFolderType
                kApplicationsFolderType
                kAssistantsFolderType
                kChewableItemsFolderType
                kColorSyncProfilesFolderType
                kContextualMenuItemsFolderType
                kControlPanelDisabledFolderType
                kControlPanelFolderType
                kControlStripModulesFolderType
                kCurrentUserFolderType
                kCurrentUserRemoteFolderLocation
                kCurrentUserRemoteFolderType
                kDesktopFolderType
                kDesktopPicturesFolderType
                kDisplayExtensionsFolderType
                kDocumentsFolderType
                kEditorsFolderType
                kExtensionDisabledFolderType
                kExtensionFolderType
                kFavoritesFolderType
                kFindByContentFolderType
                kFindByContentPluginsFolderType
                kFindSupportFolderType
                kFolderActionsFolderType
                kFontsFolderType
                kGenEditorsFolderType
                kHelpFolderType
                kInstallerLogsFolderType
                kInternetFolderType
                kInternetPlugInFolderType
                kInternetSearchSitesFolderType
                kKeychainFolderType
                kLauncherItemsFolderType
                kLocalesFolderType
                kMacOSReadMesFolderType
                kModemScriptsFolderType
                kMultiprocessingFolderType
                kOpenDocEditorsFolderType
                kOpenDocFolderType
                kOpenDocLibrariesFolderType
                kOpenDocShellPlugInsFolderType
                kPreferencesFolderType
                kPrintMonitorDocsFolderType
                kPrinterDescriptionFolderType
                kPrinterDriverFolderType
                kPrintingPlugInsFolderType
                kQuickTimeExtensionsFolderType
                kRecentApplicationsFolderType
                kRecentDocumentsFolderType
                kRecentServersFolderType
                kScriptingAdditionsFolderType
                kScriptsFolderType
                kSharedLibrariesFolderType
                kSharedUserDataFolderType
                kShutdownFolderType
                kShutdownItemsDisabledFolderType
                kSoundSetsFolderType
                kSpeakableItemsFolderType
                kStartupFolderType
                kStartupItemsDisabledFolderType
                kStationeryFolderType
                kSystemControlPanelFolderType
                kSystemDesktopFolderType
                kSystemExtensionDisabledFolderType
                kSystemFolderType
                kSystemPreferencesFolderType
                kSystemTrashFolderType
                kTemporaryFolderType
                kTextEncodingsFolderType
                kThemesFolderType
                kTrashFolderType
                kUsersFolderType
                kUtilitiesFolderType
                kVoicesFolderType
                kVolumeRootFolderType
                kVolumeSettingsFolderType
                kWhereToEmptyTrashFolderType
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

=item kALMLocationsFolderType

Specifies the Locations folder in the Location Manager Prefs folder. Files containing configuration information for different locations are stored here. Supported with S<Mac OS> 8.1 and later.

=cut

sub kALMLocationsFolderType		() { 'fall' }

=item kALMModulesFolderType

Specifies the Location Manager Modules folder in the Extensions Folder. Supported with S<Mac OS> 8.1 and later.

=cut

sub kALMModulesFolderType		() { 'walk' }

=item kALMPreferencesFolderType

Specifies the Location Manager Prefs folder in the Preferences folder. Supported with S<Mac OS> 8.1 and later.

=cut

sub kALMPreferencesFolderType		() { 'trip' }

=item kAppearanceFolderType

Specifies the Appearance folder in the System Folder. Supported with S<Mac OS> 8.5 and later.

=cut

sub kAppearanceFolderType		() { 'appr' }

=item kAppleExtrasFolderType

Specifies the Apple Extras folder installed at the root level of the volume. Supported with S<Mac OS> 8 and later.

=cut

sub kAppleExtrasFolderType		() { 'aexÄ' }

=item kAppleMenuFolderType

Specifies the Apple Menu Items folder in the System Folder.

=cut

sub kAppleMenuFolderType		() { 'amnu' }

=item kApplicationSupportFolderType

Specifies the Application Support folder in the System Folder. This folder contains code and data files needed by third-party applications. These files should usually not be written to after they are installed. In general, files deleted from this folder remove functionality from an application, unlike files in the Preferences folder, which should be non-essential. One type of file that could be placed here would be plug-ins that the user might want to maintain separately from any application, such as for an image-processing application that has many "fourth-party" plug-ins that the user might want to upgrade separately from the host application. Another type of file that might belong in this folder would be application-specific data files that are not preferences, such as for a scanner application that needs to read description files for specific scanner models according to which are currently available on the SCSI bus or network. Supported with S<Mac OS> 8 and later.

=cut

sub kApplicationSupportFolderType	() { 'asup' }

=item kApplicationsFolderType

Specifies the Applications folder installed at the root level of the volume. Supported with S<Mac OS> 8 and later.

=cut

sub kApplicationsFolderType		() { 'apps' }

=item kAssistantsFolderType

Specifies the Assistants folder installed at the root level of the volume. Supported with S<Mac OS> 8 and later.

=cut

sub kAssistantsFolderType		() { 'astÄ' }

=item kChewableItemsFolderType

Specifies the invisible folder on the system disk called "Cleanup at Startup" whose contents are deleted when the system is restarted, instead of merely being moved to the Trash. When the FindFolder function indicates this folder is available (by returning noErr ), developers should usually use this folder for their temporary items, in preference to the Temporary Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kChewableItemsFolderType		() { 'flnt' }

=item kColorSyncProfilesFolderType

Specifies the ColorSync Profiles folder in the System Folder. Supported with S<Mac OS> 8.1 and later.

=cut

sub kColorSyncProfilesFolderType	() { 'prof' }

=item kContextualMenuItemsFolderType

Specifies the Contextual Menu Items folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kContextualMenuItemsFolderType	() { 'cmnu' }

=item kControlPanelDisabledFolderType

Specifies the Control Panels (Disabled) folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kControlPanelDisabledFolderType	() { 'ctrD' }

=item kControlPanelFolderType

Specifies the Control Panels folder in the System Folder.

=cut

sub kControlPanelFolderType		() { 'ctrl' }

=item kControlStripModulesFolderType

Specifies the Control Strip Modules folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kControlStripModulesFolderType	() { 'sdev' }

=item kCurrentUserFolderType

The folder for the currently logged on user.

=cut

sub kCurrentUserFolderType		() { 'cusr' }

=item kCurrentUserRemoteFolderLocation

The remote folder for the currently logged on user

=cut

sub kCurrentUserRemoteFolderLocation	() { 'rusf' }

=item kCurrentUserRemoteFolderType

The remote folder location for the currently logged on user

=cut

sub kCurrentUserRemoteFolderType	() { 'rusr' }

=item kDesktopFolderType

Specifies the Desktop Folder.

=cut

sub kDesktopFolderType			() { 'desk' }

=item kDesktopPicturesFolderType

Specifies the Desktop Pictures folder in the Appearance folder. This folder is used for storing desktop picture files. Files of type 'JPEG' are auto-routed into this folder when dropped into the System Folder. Supported with S<Mac OS> 8.5 and later.

=cut

sub kDesktopPicturesFolderType		() { 'dtpÄ' }

=item kDisplayExtensionsFolderType

Display Extensions Folder (in Extensions folder)

=cut

sub kDisplayExtensionsFolderType	() { 'dspl' }

=item kDocumentsFolderType

Specifies the Documents folder. This folder is created at the volume root. Supported with S<Mac OS> 8 and later.

=cut

sub kDocumentsFolderType		() { 'docs' }

=item kEditorsFolderType

Specifies the OpenDoc editors folder in the S<Mac OS> folder. Supported with S<Mac OS> 8 and later.

=cut

sub kEditorsFolderType			() { 'oded' }

=item kExtensionDisabledFolderType

Specifies the Extensions (Disabled) folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kExtensionDisabledFolderType	() { 'extD' }

=item kExtensionFolderType

Specifies the Extensions folder in the System Folder.

=cut

sub kExtensionFolderType		() { 'extn' }

=item kFavoritesFolderType

Specifies the Favorites folder in the System Folder. This folder is for storing Internet location files, aliases, and aliases to other frequently used items. Facilities for adding items into this folder are found in Contextual Menus, the Finder, Navigation Services, and others. Supported with S<Mac OS> 8.1 and later.

=cut

sub kFavoritesFolderType		() { 'favs' }

=item kFindByContentFolderType

Specifies the Find By Content folder installed at the root level of the volume. This folder is invisible and its use is private to Find By Content. Supported with S<Mac OS> 8.5 and later.

=cut

sub kFindByContentFolderType		() { 'fbcf' }

=item kFindByContentPluginsFolderType

Find By Content Plug-ins

=cut

sub kFindByContentPluginsFolderType	() { 'fbcp' }

=item kFindSupportFolderType

Specifies the Find folder in the Extensions folder. This folder contains files used by the Find application. Supported with S<Mac OS> 8.5 and later.

=cut

sub kFindSupportFolderType		() { 'fnds' }

=item kFolderActionsFolderType

Specifies the Folder Action Scripts folder in the Scripts folder. Supported with S<Mac OS> 8.5 and later.

=cut

sub kFolderActionsFolderType		() { 'fasf' }

=item kFontsFolderType

Specifies the Fonts folder in the System Folder.

=cut

sub kFontsFolderType			() { 'font' }

=item kGenEditorsFolderType

Specifies a general editors folder. Supported with S<Mac OS> 8 and later.

=cut

sub kGenEditorsFolderType		() { 'Äedi' }

=item kHelpFolderType

Specifies the Help folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kHelpFolderType			() { 'Ählp' }

=item kInstallerLogsFolderType

Specifies the Installer Logs folder installed at the root level of the volume. You can use this folder to save installer log files. Supported with S<Mac OS> 8.5 and later.

=cut

sub kInstallerLogsFolderType		() { 'ilgf' }

=item kInternetFolderType

Specifies the Internet folder installed at the root level of the volume. This folder is a location for saving Internet-related applications, resources, and tools. Supported with S<Mac OS> 8.5 and later.

=cut

sub kInternetFolderType			() { 'intÄ' }

=item kInternetPlugInFolderType

Specifies the Browser Plug-ins folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kInternetPlugInFolderType		() { 'Änet' }

=item kInternetSearchSitesFolderType

Specifies the Internet Search Sites folder in the System Folder. This folder contains Internet search site specification files used by the Find application when it accesses Internet search sites. Files of type 'issp' are auto-routed to this folder. Supported with S<Mac OS> 8.5 and later.

=cut

sub kInternetSearchSitesFolderType	() { 'issf' }

=item kKeychainFolderType

Keychain folder

=cut

sub kKeychainFolderType			() { 'kchn' }

=item kLauncherItemsFolderType

Specifies the Launcher Items folder in the System Folder. Items in this folder appear in the Launcher control panel. Items included in folders with names beginning with a bullet (Option-8) character will appear as a separate panel in the Launcher window. Supported with S<Mac OS> 8.5 and later.

=cut

sub kLauncherItemsFolderType		() { 'laun' }

=item kLocalesFolderType

PKE for Locales folder

=cut

sub kLocalesFolderType			() { 'Äloc' }

=item kMacOSReadMesFolderType

Specifies the S<Mac OS> Read Me Files folder installed at the root level of the volume. Supported with S<Mac OS> 8 and later.

=cut

sub kMacOSReadMesFolderType		() { 'morÄ' }

=item kModemScriptsFolderType

Specifies the Modem Scripts folder in the Extensions folder. Supported with S<Mac OS> 8 and later.

=cut

sub kModemScriptsFolderType		() { 'Ämod' }

=item kMultiprocessingFolderType

Multiprocessing Folder (in Extensions folder)

=cut

sub kMultiprocessingFolderType		() { 'mpxf' }

=item kOpenDocEditorsFolderType

Specifies the OpenDoc subfolder in the Editors folder. Supported with S<Mac OS> 8 and later.

=cut

sub kOpenDocEditorsFolderType		() { 'Äodf' }

=item kOpenDocFolderType

Specifies the OpenDoc root folder. Supported with S<Mac OS> 8 and later.

=cut

sub kOpenDocFolderType			() { 'odod' }

=item kOpenDocLibrariesFolderType

Specifies the OpenDoc libraries folder. Supported with S<Mac OS> 8 and later.

=cut

sub kOpenDocLibrariesFolderType		() { 'odlb' }

=item kOpenDocShellPlugInsFolderType

Specifies the OpenDoc shell plug-ins folder in the OpenDoc folder. Supported with S<Mac OS> 8 and later.

=cut

sub kOpenDocShellPlugInsFolderType	() { 'odsp' }

=item kPreferencesFolderType

Specifies the Preferences folder in the System Folder.

=cut

sub kPreferencesFolderType		() { 'pref' }

=item kPrintMonitorDocsFolderType

Specifies the PrintMonitor Documents folder in the System Folder.

=cut

sub kPrintMonitorDocsFolderType		() { 'prnt' }

=item kPrinterDescriptionFolderType

Specifies the Printer Descriptions folder in the Extensions folder. Supported with S<Mac OS> 8 and later.

=cut

sub kPrinterDescriptionFolderType	() { 'ppdf' }

=item kPrinterDriverFolderType

Specifies the printer drivers folder. This constant is not currently supported.

=cut

sub kPrinterDriverFolderType		() { 'Äprd' }

=item kPrintingPlugInsFolderType

Printing Plug-Ins Folder (in Extensions folder)

=cut

sub kPrintingPlugInsFolderType		() { 'pplg' }

=item kQuickTimeExtensionsFolderType

QuickTime Extensions Folder (in Extensions folder)

=cut

sub kQuickTimeExtensionsFolderType	() { 'qtex' }

=item kRecentApplicationsFolderType

Specifies the Recent Applications folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recent applications here. Supported with S<Mac OS> 8.5 and later.

=cut

sub kRecentApplicationsFolderType	() { 'rapp' }

=item kRecentDocumentsFolderType

Specifies the Recent Documents folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recently opened documents here. Supported with S<Mac OS> 8.5 and later.

=cut

sub kRecentDocumentsFolderType		() { 'rdoc' }

=item kRecentServersFolderType

Specifies the Recent Servers folder in the Apple Menu Items folder. Apple Menu Items saves aliases to recently mounted servers here. Supported with S<Mac OS> 8.5 and later.

=cut

sub kRecentServersFolderType		() { 'rsvr' }

=item kScriptingAdditionsFolderType

Specifies the Scripting Additions folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kScriptingAdditionsFolderType	() { 'Äscr' }

=item kScriptsFolderType

Specifies the Scripts folder in the System Folder. This folder is for saving AppleScript scripts. Supported with S<Mac OS> 8.5 and later.

=cut

sub kScriptsFolderType			() { 'scrÄ' }

=item kSharedLibrariesFolderType

Specifies the general shared libraries folder. This constant is not currently supported.

=cut

sub kSharedLibrariesFolderType		() { 'Älib' }

=item kSharedUserDataFolderType

A Shared "Documents" folder, readable & writeable by all users

=cut

sub kSharedUserDataFolderType		() { 'sdat' }

=item kShutdownFolderType

Specifies the Shutdown Items folder in the System Folder.

=cut

sub kShutdownFolderType			() { 'shdf' }

=item kShutdownItemsDisabledFolderType

Specifies the Shutdown Items (Disabled) folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kShutdownItemsDisabledFolderType	() { 'shdD' }

=item kSoundSetsFolderType

Specifies the Sound Sets folder in the Appearance folder. Supported with S<Mac OS> 8.5 and later.

=cut

sub kSoundSetsFolderType		() { 'snds' }

=item kSpeakableItemsFolderType

Specifies the Speakable Items folder. This folder is for storing scripts and items recognized by speech recognition. Supported with S<Mac OS> 8.5 and later.

=cut

sub kSpeakableItemsFolderType		() { 'spki' }

=item kStartupFolderType

Specifies the Startup Items folder in the System Folder.

=cut

sub kStartupFolderType			() { 'strt' }

=item kStartupItemsDisabledFolderType

Specifies the Startup Items (Disabled) folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kStartupItemsDisabledFolderType	() { 'strD' }

=item kStationeryFolderType

Specifies the OpenDoc stationery folder. Supported with S<Mac OS> 8 and later.

=cut

sub kStationeryFolderType		() { 'odst' }

=item kSystemControlPanelFolderType

System control panels folder - never the redirected one, always "Control Panels" inside the System Folder

=cut

sub kSystemControlPanelFolderType	() { 'sctl' }

=item kSystemDesktopFolderType

the desktop folder at the root of the hard drive, never the redirected user desktop folder

=cut

sub kSystemDesktopFolderType		() { 'sdsk' }

=item kSystemExtensionDisabledFolderType

Specifies the System Extensions (Disabled) folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kSystemExtensionDisabledFolderType	() { 'macD' }

=item kSystemFolderType

Specifies the System Folder.

=cut

sub kSystemFolderType			() { 'macs' }

=item kSystemPreferencesFolderType

System-type Preferences go here - this is always the system's preferences folder, never a logged in user's

=cut

sub kSystemPreferencesFolderType	() { 'sprf' }

=item kSystemTrashFolderType

the trash folder at the root of the drive, never the redirected user trash folder

=cut

sub kSystemTrashFolderType		() { 'strs' }

=item kTemporaryFolderType

Specifies the Temporary folder. This folder exists as an invisible folder at the volume root.

=cut

sub kTemporaryFolderType		() { 'temp' }

=item kTextEncodingsFolderType

Specifies the Text Encodings folder in the System Folder. Supported with S<Mac OS> 8 and later.

=cut

sub kTextEncodingsFolderType		() { 'Ätex' }

=item kThemesFolderType

Specifies the Theme Files folder in the Appearance folder. Supported with S<Mac OS> 8.1 and later.

=cut

sub kThemesFolderType			() { 'thme' }

=item kTrashFolderType

Specifies the single-user Trash folder.

=cut

sub kTrashFolderType			() { 'trsh' }

=item kUsersFolderType

"Users" folder, contains one folder for each user.

=cut

sub kUsersFolderType			() { 'usrs' }

=item kUtilitiesFolderType

Specifies the Utilities folder installed at the root level of the volume. Supported with S<Mac OS> 8 and later.

=cut

sub kUtilitiesFolderType		() { 'utiÄ' }

=item kVoicesFolderType

Specifies the Voices folder in the Extensions folder. Supported with S<Mac OS> 8 and later.

=cut

sub kVoicesFolderType			() { 'fvoc' }

=item kVolumeRootFolderType

Specifies the root folder of a volume. Supported with S<Mac OS> 8 and later.

=cut

sub kVolumeRootFolderType		() { 'root' }

=item kVolumeSettingsFolderType

Volume specific user information goes here

=cut

sub kVolumeSettingsFolderType		() { 'vsfd' }

=item kWhereToEmptyTrashFolderType

Specifies the shared Trash folder; on a file server, this indicates the parent directory of all logged-on users' Trash subdirectories.

=cut

sub kWhereToEmptyTrashFolderType	() { 'empt' }

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
sub Eject	{	_Eject     (&_VolumeID);	}
sub FlushVol 	{	_FlushVol  (&_VolumeID);	}

=include Files.xs

=head1 AUTHOR

Matthias Ulrich Neeracher <neeracher@mac.com>

=cut

1;

__END__
