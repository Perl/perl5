
=head1 NAME

Mac::InternetConfig - Interface to Peter Lewis' and Quinns Internet Config system

=head1 SYNOPSIS


=head1 DESCRIPTION

Access to the original Internet Config documentation is essential for proper use 
of these functions.

=cut

use strict;

package Mac::InternetConfig;

BEGIN {
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw(
		$VERSION @ISA @EXPORT @EXPORT_OK 
		%RawInternetConfig %InternetConfig %InternetConfigMap $ICInstance);
	$VERSION = '1.00';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		ICStart
		ICStop
		ICFindConfigFile
		ICFindUserConfigFile
		ICGeneralFindConfigFile
		ICChooseConfig
		ICChooseNewConfig
		ICGetConfigName
		ICGetConfigReference
		ICSetConfigReference
		ICGetSeed
		ICGetComponentInstance
		ICBegin
		ICGetPref
		ICSetPref
		ICCountPref
		ICGetIndPref
		ICDeletePref
		ICEnd
		ICEditPreferences
		ICParseURL
		ICLaunchURL
		ICMapFilename
		ICMapTypeCreator
		ICMapEntriesFilename
		ICMapEntriesTypeCreator
		ICCountMapEntries
		ICGetIndMapEntry
		ICGetMapEntry
		ICSetMapEntry
		ICDeleteMapEntry
		ICAddMapEntry
		
		%RawInternetConfig 
		%InternetConfig
		%InternetConfigMap
		
		kICRealName
		kICEmail
		kICMailAccount
		kICMailPassword
		kICNewsAuthUsername
		kICNewsAuthPassword
		kICArchiePreferred
		kICArchieAll
		kICUMichPreferred
		kICUMichAll
		kICInfoMacPreferred
		kICInfoMacAll
		kICPhHost
		kICWhoisHost
		kICFingerHost
		kICFTPHost
		kICTelnetHost
		kICSMTPHost
		kICNNTPHost
		kICGopherHost
		kICLDAPServer
		kICLDAPSearchbase
		kICWWWHomePage
		kICWAISGateway
		kICListFont
		kICScreenFont
		kICPrinterFont
		kICTextCreator
		kICBinaryTypeCreator
		kICDownloadFolder
		kICSignature
		kICOrganization
		kICPlan
		kICQuotingString
		kICMailHeaders
		kICNewsHeaders
		kICMapping
		kICCharacterSet
		kICHelper
		kICServices
		kICNewMailFlashIcon
		kICNewMailDialog
		kICNewMailPlaySound
		kICNewMailSoundName
		kICWebBackgroundColour
		kICNoProxyDomains
		kICUseSocks
		kICSocksHost
		kICUseHTTPProxy
		kICHTTPProxyHost
		kICUseFTPProxy
		kICFTPProxyHost
		kICFTPProxyUser
		kICFTPProxyPassword
		kICFTPProxyAccount
		ICmap_binary
		ICmap_resource_fork
		ICmap_data_fork
		ICmap_post
		ICmap_not_incoming
		ICmap_not_outgoing
		ICservices_tcp
		ICservices_udp
		icNoPerm
		icReadOnlyPerm
		icReadWritePerm
		GetURL
		GetICHelper
);
	@EXPORT_OK = qw(
		$ICInstance
	);
}

=head2 Constants

=over 4

=item kICRealName

=item kICEmail

=item kICMailAccount

=item kICMailPassword

=item kICNewsAuthUsername

=item kICNewsAuthPassword

=item kICArchiePreferred

=item kICArchieAll

=item kICUMichPreferred

=item kICUMichAll

=item kICInfoMacPreferred

=item kICInfoMacAll

=item kICPhHost

=item kICWhoisHost

=item kICFingerHost

=item kICFTPHost

=item kICTelnetHost

=item kICSMTPHost

=item kICNNTPHost

=item kICGopherHost

=item kICLDAPServer

=item kICLDAPSearchbase

=item kICWWWHomePage

=item kICWAISGateway

=item kICListFont

=item kICScreenFont

=item kICPrinterFont

=item kICTextCreator

=item kICBinaryTypeCreator

=item kICDownloadFolder

=item kICSignature

=item kICOrganization

=item kICPlan

=item kICQuotingString

=item kICMailHeaders

=item kICNewsHeaders

=item kICMapping

=item kICCharacterSet

=item kICHelper

=item kICServices

=item kICNewMailFlashIcon

=item kICNewMailDialog

=item kICNewMailPlaySound

=item kICNewMailSoundName

=item kICWebBackgroundColour

=item kICNoProxyDomains

=item kICUseSocks

=item kICSocksHost

=item kICUseHTTPProxy

=item kICHTTPProxyHost

=item kICUseFTPProxy

=item kICFTPProxyHost

=item kICFTPProxyUser

=item kICFTPProxyPassword

=item kICFTPProxyAccount

Internet Config settings.

=cut
sub kICRealName ()                 { "RealName"; }
sub kICEmail ()                    { "Email"; }
sub kICMailAccount ()              { "MailAccount"; }
sub kICMailPassword ()             { "MailPassword"; }
sub kICNewsAuthUsername ()         { "NewsAuthUsername"; }
sub kICNewsAuthPassword ()         { "NewsAuthPassword"; }
sub kICArchiePreferred ()          { "ArchiePreferred"; }
sub kICArchieAll ()                { "ArchieAll"; }
sub kICUMichPreferred ()           { "UMichPreferred"; }
sub kICUMichAll ()                 { "UMichAll"; }
sub kICInfoMacPreferred ()         { "InfoMacPreferred"; }
sub kICInfoMacAll ()               { "InfoMacAll"; }
sub kICPhHost ()                   { "PhHost"; }
sub kICWhoisHost ()                { "WhoisHost"; }
sub kICFingerHost ()               { "FingerHost"; }
sub kICFTPHost ()                  { "FTPHost"; }
sub kICTelnetHost ()               { "TelnetHost"; }
sub kICSMTPHost ()                 { "SMTPHost"; }
sub kICNNTPHost ()                 { "NNTPHost"; }
sub kICGopherHost ()               { "GopherHost"; }
sub kICLDAPServer ()               { "LDAPServer"; }
sub kICLDAPSearchbase ()           { "LDAPSearchbase"; }
sub kICWWWHomePage ()              { "WWWHomePage"; }
sub kICWAISGateway ()              { "WAISGateway"; }
sub kICListFont ()                 { "ListFont"; }
sub kICScreenFont ()               { "ScreenFont"; }
sub kICPrinterFont ()              { "PrinterFont"; }
sub kICTextCreator ()              { "TextCreator"; }
sub kICBinaryTypeCreator ()        { "BinaryTypeCreator"; }
sub kICDownloadFolder ()           { "DownloadFolder"; }
sub kICSignature ()                { "Signature"; }
sub kICOrganization ()             { "Organization"; }
sub kICPlan ()                     {  "Plan"; }
sub kICQuotingString ()            { "QuotingString"; }
sub kICMailHeaders ()              { "MailHeaders"; }
sub kICNewsHeaders ()              { "NewsHeaders"; }
sub kICMapping ()                  { "Mapping"; }
sub kICCharacterSet ()             { "CharacterSet"; }
sub kICHelper ()                   { "Helper¥"; }
sub kICServices ()                 { "Services"; }
sub kICNewMailFlashIcon ()         { "NewMailFlashIcon"; }
sub kICNewMailDialog ()            { "NewMailDialog"; }
sub kICNewMailPlaySound ()         { "NewMailPlaySound"; }
sub kICNewMailSoundName ()         { "NewMailSoundName"; }
sub kICWebBackgroundColour ()      { "WebBackgroundColour"; }
sub kICNoProxyDomains ()           { "NoProxyDomains"; }
sub kICUseSocks ()                 { "UseSocks"; }
sub kICSocksHost ()                { "SocksHost"; }
sub kICUseHTTPProxy ()             { "UseHTTPProxy"; }
sub kICHTTPProxyHost ()            { "HTTPProxyHost"; }
sub kICUseFTPProxy ()              { "UseFTPProxy"; }
sub kICFTPProxyHost ()             { "FTPProxyHost"; }
sub kICFTPProxyUser ()             { "FTPProxyUser"; }
sub kICFTPProxyPassword ()         { "FTPProxyPassword"; }
sub kICFTPProxyAccount ()          { "FTPProxyAccount"; }


=item ICmap_binary

=item ICmap_resource_fork

=item ICmap_data_fork

=item ICmap_post

=item ICmap_not_incoming

=item ICmap_not_outgoing

=item ICservices_tcp

=item ICservices_udp

=item icNoPerm

=item icReadOnlyPerm

=item icReadWritePerm

Various constants.

=cut
sub ICmap_binary ()           	  { 0x00000001; }
sub ICmap_resource_fork ()    	  { 0x00000002; }
sub ICmap_data_fork ()       	     { 0x00000004; }
sub ICmap_post ()             	  { 0x00000008; }
sub ICmap_not_incoming ()     	  { 0x00000010; }
sub ICmap_not_outgoing ()     	  { 0x00000020; }
sub ICservices_tcp ()        	     { 0x00000001; }
sub ICservices_udp ()        	     { 0x00000002; }
sub icNoPerm ()					  	  { 0; }
sub icReadOnlyPerm ()			     { 1; }
sub icReadWritePerm ()				  { 2; }

=back

=cut

bootstrap Mac::InternetConfig;

sub ICFindConfigFile {
	my($inst, @folders) = @_;
	ICGeneralFindConfigFile($inst, 1, 0, @folders);
}

sub ICFindUserConfigFile {
	my($inst, @folders) = @_;
	ICGeneralFindConfigFile($inst, 0, 0, @folders);
}

package Mac::InternetConfig::_Raw;

BEGIN {
	use Tie::Hash  ();
	import Mac::InternetConfig;
	import Mac::InternetConfig qw($ICInstance);

	use vars qw(@ISA);
	
	@ISA = qw(Tie::Hash);
}

sub TIEHASH {
	my($package) = @_;
	
	my($enum) = 0;
	ICFindConfigFile($ICInstance);
	
	bless \$enum, $package;
}

sub DESTROY {
}

sub FETCH {
	my($me, $key) = @_;
	
	ICGetPref($ICInstance, $key);
}

sub STORE {
	my($me, $key, @value) = @_;
	
	ICSetPref($ICInstance, $key, @value);
}

sub DELETE {
	my($me, $key) = @_;
	
	ICDeletePref($ICInstance, $key);
}

sub FIRSTKEY {
	my($me) = @_;
	
	$$me = 0;
	
	NEXTKEY $me;
}

sub NEXTKEY {
	my($me) = @_;

	++$$me;
	
	ICBegin($ICInstance, icReadOnlyPerm());
	my($key) = ICGetIndPref($ICInstance, $$me);
	ICEnd($ICInstance);
	
	$key;
}

package Mac::InternetConfig::_Map;

BEGIN {
	use Tie::Hash  ();
	use Mac::Types;
	use Mac::Memory qw(DisposeHandle);
	import Mac::InternetConfig;
	import Mac::InternetConfig qw($ICInstance);

	use vars qw(@ISA %ictypes %ICPack %ICUnpack);
	
	@ISA = qw(Tie::Hash);
}

sub new {
	my($package,$blob) = @_;
	
	bless { entries => new Handle($blob) }, $package;
}

sub TIEHASH {
	my($package,$blob) = @_;
	
	if (ref($blob)) {
		return $blob;
	} else {
		return new($package, $blob);
	}
}

sub DESTROY {
	my($my) = @_;
	
	DisposeHandle($my->{entries}) if $my->{entries};
}

sub FETCH {
	my($my, $key) = @_;
	
	if (ref($key) eq "ICMapEntry") { # dummy case
		return $key;
	} elsif (ref($key)) { 	# [type, creator, optionally name]
		return ICMapEntriesTypeCreator($ICInstance, $my->{entries}, @$key);
	} else {    		# File name
		return ICMapEntriesFilename($ICInstance, $my->{entries}, $key);
	}
}

sub STORE {
	my($my, $key, $value) = @_;
	
	$key = $my->FETCH($key) unless ref($key) eq "ICMapEntry";
	my($pos) = Mac::InternetConfig::_ICMapFind($ICInstance, $my->{entries}, $key);
	if (defined $pos) {
		ICSetMapEntry($ICInstance, $my->{entries}, $pos, $value);
	} else {
		ICAddMapEntry($ICInstance, $my->{entries}, $value);
	}
}

sub DELETE {
	my($my, $key) = @_;
	
	$key = $my->FETCH($key) unless ref($key) eq "ICMapEntry";
	my($pos) = Mac::InternetConfig::_ICMapFind($ICInstance, $my->{entries}, $key);
	if (defined $pos) {
		ICDeleteMapEntry($ICInstance, $my->{entries}, $pos);
	} 
}

sub FIRSTKEY {
	my($my) = @_;
	
	$my->{'index'} = 0;
	
	return scalar(ICGetIndMapEntry($ICInstance, $my->{entries}, $my->{'index'}));
}

sub NEXTKEY {
	my($my) = @_;
	
	return scalar(ICGetIndMapEntry($ICInstance, $my->{entries}, ++$my->{'index'}));
}

package Mac::InternetConfig::_Cooked;

BEGIN {
	use Tie::Hash  ();
	use Mac::Types;
	use Mac::Memory();
	import Mac::InternetConfig;
	import Mac::InternetConfig qw($ICInstance);

	use vars qw(@ISA %ictypes %ICPack %ICUnpack);
	
	@ISA = qw(Tie::Hash);
}

%ictypes = (
	kICRealName() 				=> 'STR ',
	kICEmail() 					=> 'STR ',
	kICMailAccount() 			=> 'STR ',
	kICMailPassword() 		=> 'STR ',
	kICNewsAuthUsername() 	=> 'STR ',
	kICNewsAuthPassword() 	=> 'STR ',
	kICArchiePreferred() 	=> 'STR ',
	kICArchieAll() 			=> 'STR#',
	kICUMichPreferred() 		=> 'STR ',
	kICUMichAll() 				=> 'STR#',
	kICInfoMacPreferred() 	=> 'STR ',
	kICInfoMacAll() 			=> 'STR#',
	kICPhHost() 				=> 'STR ',
	kICWhoisHost() 			=> 'STR ',
	kICFingerHost() 			=> 'STR ',
	kICFTPHost() 				=> 'STR ',
	kICTelnetHost() 			=> 'STR ',
	kICSMTPHost() 				=> 'STR ',
	kICNNTPHost() 				=> 'STR ',
	kICGopherHost() 			=> 'STR ',
	kICLDAPServer() 			=> 'STR ',
	kICLDAPSearchbase() 		=> 'STR ',
	kICWWWHomePage() 			=> 'STR ',
	kICWAISGateway() 			=> 'STR ',
	kICListFont() 				=> 'ICFontRecord',
	kICScreenFont() 			=> 'ICFontRecord',
	kICPrinterFont() 			=> 'ICFontRecord',
	kICTextCreator() 			=> 'ICAppSpec',
	kICBinaryTypeCreator() 	=> 'ICFileInfo',
	kICDownloadFolder() 		=> 'ICFileSpec',
	kICSignature() 			=> 'TEXT',
	kICOrganization() 		=> 'STR ',
	kICPlan() 					=> 'TEXT',
	kICQuotingString() 		=> 'STR ',
	kICMailHeaders() 			=> 'TEXT',
	kICNewsHeaders() 			=> 'TEXT',
	kICMapping() 				=> 'ICMapEntries',
	kICCharacterSet() 		=> 'ICCharTable',
	kICHelper() 				=> 'ICAppSpec',
	kICServices() 				=> 'ICServices',
	kICNewMailFlashIcon() 	=> 'bool',
	kICNewMailDialog() 		=> 'bool',
	kICNewMailPlaySound() 	=> 'bool',
	kICNewMailSoundName() 	=> 'STR ',
	kICWebBackgroundColour()=> 'RGBColor',
	kICNoProxyDomains() 		=> 'STR#',
	kICUseSocks() 				=> 'bool',
	kICSocksHost() 			=> 'STR ',
	kICUseHTTPProxy() 		=> 'bool',
	kICHTTPProxyHost() 		=> 'STR ',
	kICUseFTPProxy() 			=> 'bool',
	kICFTPProxyHost() 		=> 'STR ',
	kICFTPProxyUser() 		=> 'STR ',
	kICFTPProxyPassword() 	=> 'STR ',
	kICFTPProxyAccount() 	=> 'STR ',
);

# should accept only one item for tied interface
sub _PackICFontRecord {
	my($size,$face,$font) = @_;
	return pack("sCx", $size, $face) . MacPack('STR ', $font);
}

# should return only one item for tied interface
sub _UnpackICFontRecord {
	my($blob) = @_;

	return (unpack("sC", $blob), MacUnpack('STR ', substr($blob, 4)));
}

# should accept only one item for tied interface
sub _PackICAppSpec {
	my($type,$name) = @_;
	return MacPack('type', $type) . MacPack('STR ', $name);
}

# should return only one item for tied interface
sub _UnpackICAppSpec {
	my $blob = shift or return;
	return (MacUnpack('type', $blob), MacUnpack('STR ', substr($blob, 4)));
}

# should accept only one item for tied interface
sub _PackICFileInfo {
	my($type,$creator,$name) = @_;
	return MacPack('type', $type) . MacPack('type', $creator) . MacPack('STR ', $name);
}

# should return only one item for tied interface
sub _UnpackICFileInfo {
	my $blob = shift or return;
	return (MacUnpack('type', $blob), MacUnpack('type', substr($blob, 4, 4)), MacUnpack('STR ', substr($blob, 8)));
}

# should accept only one item for tied interface
sub _PackICFileSpec {
	my($vol, $creation, $spec, $alias) = @_;
	$vol = substr(MacPack('STR ', $vol) . ('\0' x 32), 0, 32);
	return $vol . MacPack('long', $creation) . $spec . $alias->get;
}

# should return only one item for tied interface
sub _UnpackICFileSpec {
	my($blob) = @_;

	return (
		MacUnpack('STR ', $blob), 
		MacUnpack('long', substr($blob, 32, 4)), 
		MacUnpack('fss ', substr($blob, 36, 70)),
		new Handle(substr($blob, 106)));
}

sub _UnpackICMapEntries {
	my($blob) = @_;

	return new Mac::InternetConfig::_Map $blob;
}

%ICPack = (
	ICFileInfo		=> \&_PackICFileInfo,
	ICFontRecord	=> \&_PackICFontRecord,
	ICAppSpec		=> \&_PackICAppSpec,
	ICFileSpec		=> \&_PackICFileSpec,
);

%ICUnpack = (
	ICFileInfo		=> \&_UnpackICFileInfo,
	ICFontRecord	=> \&_UnpackICFontRecord,
	ICAppSpec		=> \&_UnpackICAppSpec,
	ICFileSpec		=> \&_UnpackICFileSpec,
	ICMapEntries	=> \&_UnpackICMapEntries,
);

sub TIEHASH {
	my($package) = @_;
	
	bless {}, $package;
}

sub DESTROY {
	# Do *not* inherit _Raw::DESTROY
}

sub FETCH {
	my($me, $key) = @_;
	
	my($data) = $RawInternetConfig{$key};
	my $type = $ictypes{$key};
	if ($type && (exists $ICUnpack{$type} || exists $MacUnpack{$type})) {
		return MacUnpack(\%ICUnpack, $type, $data);
	} else {
		return $data;
	}
}

sub STORE {
	my($me, $key, @value) = @_;
	my $type = $ictypes{$key};
	if ($type && (exists $ICPack{$type} || exists $MacPack{$type})) {
		$RawInternetConfig{$key} = MacPack(\%ICPack, $type, @value);
	} else {
		$RawInternetConfig{$key} = $value[0];
	}
}

sub FIRSTKEY {
	 Mac::InternetConfig::_Raw::FIRSTKEY(tied(%RawInternetConfig));
}

sub NEXTKEY {
	Mac::InternetConfig::_Raw::NEXTKEY(tied(%RawInternetConfig));
}

package Mac::InternetConfig;

=head2 Variables

=over 4

=item $ICInstance

The instance of the Internet Config database.

=item %RawInternetConfig

Access the raw, uninterpreted value of an Internet Config setting.

=item %InternetConfig

Access a sane Perl version of one of the more common Internet Config settings.

=item %InternetConfigMap

Access the Internet Config file map to:

=over 4

=item 

Determine the file type and creator for a newly created file:

	$map = $InternetConfigMap{"output.html"};	
	
=item

Determine the extension to use for some type/creator combination:

	$map = $InternetConfigMap{["WDBN", "MSWD"]};

=back

=back

=cut

$ICInstance = ICStart();

tie %RawInternetConfig, q(Mac::InternetConfig::_Raw);
tie %InternetConfig,    q(Mac::InternetConfig::_Cooked);
tie %InternetConfigMap, q(Mac::InternetConfig::_Map), $InternetConfig{kICMapping()};

=include InternetConfig.xs

=item GetURL URL

Launch helper app with URL.  Returns undef on error.

=item GetICHelper PROTOCOL

Return list of creator ID and name for helper app assigned
to PROTOCOL.  Returns only creator ID in scalar context.
Returns undef on error.

=cut

sub GetURL {
    my $url = shift or return;
	ICGeneralFindConfigFile($ICInstance);
    ICLaunchURL($ICInstance, 0, $url);
}

sub GetICHelper {
    my $proto    = shift or return;
    my $helper   = $InternetConfig{kICHelper() . $proto} or return;
    my $app_id   = substr($helper, 0, 4);
    my $app_name = substr($helper, 5, ord(substr($helper, 4, 1)));
    return wantarray ? ($app_id, $app_name) : $app_id;
}

END {
	ICStop($ICInstance);
}

1;

__END__
