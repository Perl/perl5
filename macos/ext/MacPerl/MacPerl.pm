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

	$Version
	$Architecture
	$Compiler

	Reply
	DoAppleScript
	
	LoadExternals
);

%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# bootstrap MacPerl is already implicitly done by your MacPerl binary

sub kMacPerlNeverQuit ()		{ 0; }
sub kMacPerlQuitIfRuntime ()		{ 1; }
sub kMacPerlAlwaysQuit ()		{ 2; }
sub kMacPerlQuitIfFirstScript ()	{ 3; }

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

=head1 FUNCTIONS

=over 8

=item MacPerl::Answer(PROMPT)

=item MacPerl::Answer(PROMPT,BUTTON1)

=item MacPerl::Answer(PROMPT,BUTTON1,BUTTON2)

=item MacPerl::Answer(PROMPT,BUTTON1,BUTTON2,BUTTON3)

Presents to the user a dialog with 1, 2, or 3 buttons. 

Examples:

    MacPerl::Answer("Nunc et in hora mortis nostrae", "Amen");

always returns 0.

    MacPerl::Answer("I refuse");

is equivalent to C<MacPerl'Answer("I refuse", "OK");>

    MacPerl::Answer("Delete hard disk ?", "OK", "Cancel");

returns 1 for OK, 0 for Cancel

    MacPerl::Answer("Overwrite existig file", "Overwrite", "Skip", "Cancel");

returns 2 for Overwrite, 1 for Skip, 0 for Cancel

=item MacPerl::Ask(PROMPT, DEFAULT)

=item MacPerl::Ask(PROMPT)

Asks the user for a string. A default value may be given. Returns
undef if the dialog is cancelled.

Example:

    $phone = MacPerl::Ask("Enter your phone number:");
    $name  = MacPerl::Ask("Enter your first name", "Bruce");

Useful for Australian database applications

=item MacPerl::Pick(PROMPT, VALUES)

Asks the user to pick a choice from a list. VALUES is a list of choices. 
Returns undef if the dialog is cancelled.

Examples:

    $color = MacPerl::Pick("What's your favorite color baby ?", "Red", "Green", "Gold");

=item MacPerl::SetFileInfo(CREATOR,TYPE,FILE...)

Changes the file types and creators of the file(s).

Examples:

    MacPerl::SetFileInfo("MPS ", "TEXT", yin, yang);

Turn yin and yang into MPW text files

=item MacPerl::GetFileInfo(FILE)

In scalar context, returns the file type. In array context, returns (creator,type).

Examples:

    MacPerl::GetFileInfo(yin);

Returns "TEXT" or ("MPS ", "TEXT").

=item MacPerl::DoAppleScript(SCRIPT)

Execute an AppleScript script.

Example:

    MacPerl::DoAppleScript(<<END_SCRIPT);
    tell application "MacPerl"
        make new Window
        copy "Inserting text the hard way." to character 1 of front Window
    end tell
    END_SCRIPT

=item MacPerl::Reply(ANSWER)

Reply to current DoScript request. Useful if you are calling Perl 
scripts from other applications.

=item MacPerl::Quit(LEVEL)

If LEVEL is 0, don't quit after ending the script. If 1, quit if 
running under a runtime version, if 2, always quit. If LEVEL is 3,
quit if this was the first script to be run since starting MacPerl.

=item MacPerl::LoadExternals(LIBFILE)

Load XCMD and XFCN extensions contained in file LIBFILE, which is searched
along the same path as it would be for a require. The extensions are made
accessible in the current package, unless they containing an explicit package
name.

=item MacPerl::FAccess(FILE, CMD, ARGS)

When called from the tool, manipulate various information of files. To 
get the command constants, it's convenient to require "FAccess.ph".

=over 8

=item $TAB = MacPerl::FAccess(FILE, F_GTABINFO)

=item MacPerl::FAccess(FILE, F_STABINFO, TAB)

Manipulate tabulator setting (in spaces per tab).

=item ($FONTNAME, $FONTSIZE) = MacPerl::FAccess(FILE, F_GFONTINFO)

=item $FONTNUM = MacPerl::FAccess(FILE, F_GFONTINFO)

=item MacPerl::FAccess(FILE, F_SFONTINFO, FONT [, SIZE])

Manipulate font and size information. Both font names and font numbers
are accepted for F_SFONTINFO; F_GFONTINFO returns a font name in an
array context, a font number in a scalar context.

=item ($STARTSEL, $ENDSEL, $DISPLAYTOP) = MacPerl::FAccess(FILE, F_GSELINFO)

=item $STARTSEL = MacPerl::FAccess(FILE, F_GSELINFO)

=item MacPerl::FAccess(FILE, F_SSELINFO, $STARTSEL, $ENDSEL [, $DISPLAYTOP])

Manipulate the MPW selection of a file.

=item ($LEFT, $TOP, $RIGHT, $BOTTOM) = MacPerl::FAccess(FILE, F_GWININFO)
=item $TOP = MacPerl::FAccess(FILE, F_GWININFO)
=item MacPerl::FAccess(FILE, F_SWININFO, LEFT, TOP [, RIGHT, BOTTOM])

Manipulate the window position.

=back

=item MacPerl::MakeFSSpec(PATH)

This command encodes a path name into an encoding (volume #, directory #,
File name) which is guaranteed to be unique for every file. Don't store
this encoding between runs of MacPerl!

=item MacPerl::MakePath(FSSPEC)

The inverse of MacPerl::MakeFSSpec(): turn an encoding into a path name.

=item MacPerl::Volumes()

In scalar context, return the FSSPEC of the startup volume. In list context, 
return FSSPECs of all volumes.

=back


=head1 SEE ALSO

L<macperl>

=cut


    