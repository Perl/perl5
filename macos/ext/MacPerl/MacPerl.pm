package MacPerl;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
    kMacPerlNeverQuit
    kMacPerlQuitIfRuntime
    kMacPerlAlwaysQuit
    kMacPerlQuitIfFirstScript
);
@EXPORT_OK = qw(
	SetFileInfo
	GetFileInfo
	Ask
	Answer
	Choose
	Pick
	Quit
	FAccess
	MakeFSSpec
	MakePath
	Volumes
	Version
	Architecture
	
	Reply
	DoAppleScript
	
	LoadExternals
);
	
# bootstrap MacPerl is already implicitly done by your MacPerl binary

sub kMacPerlNeverQuit ()		{ 0; }
sub kMacPerlQuitIfRuntime ()	{ 1; }
sub kMacPerlAlwaysQuit ()		{ 2; }
sub kMacPerlQuitIfFirstScript (){ 3; }

1;

__END__

=cut

=head1 NAME

MacPerl - Built-in Macintosh specific routines.

=head1 SYNOPSIS

    $phone = MacPerl::Ask("Enter your phone number:");
    MacPerl::Answer("Nunc et in hora mortis nostrae", "Amen");
    $color = MacPerl::Pick("What's your favorite color baby ?", "Red", "Green", "Gold");

    MacPerl::SetFileInfo("MPS ", "TEXT", yin, yang);
    MacPerl::GetFileInfo(yin);
    
    MacPerl::Quit(kMacPerlAlwaysQuit);

=head1 SEE ALSO

L<macperl>

=cut


    