

print "\nGenerating automated scripts for NetWare...\n\n\n";


use File::Basename;
use File::Copy;

chdir '/perl/scripts/';
$DirName = "t";


# These scripts have problems (either abend or hang) as of now (11 May 2001).
# So, they are commented out in the corresponding auto scripts, io.pl and lib.pl
@ScriptsNotUsed = ("t/io/argv.t", "t/io/openpid.t", "t/lib/filehand.t");


print "Generating  t/auto.pl ...\n\n\n";

open(FHWA, "> t/auto.pl") or die "Unable to open the file,  t/auto.pl  for writing.\n";
seek(FHWA, 0 ,0);
flock(FHWA, LOCK_EX);		# Lock the file for safety purposes.

$version = sprintf("%vd",$^V);
print FHWA "\n\nprint \"Automated Unit Testing of Perl$version\\n\\n\\n\"\;\n\n\n";


opendir(DIR, $DirName) or die "Unable to open the directory, $DirName  for reading.\n";
@Dirs = readdir(DIR);

foreach $DirItem(@Dirs)
{
	$DirItem = $DirName."/".$DirItem;
	push @DirNames, $DirItem;	# All items under  $DirName  directory is copied into an array.
}

foreach $FileName(@DirNames)
{
	if(-d $FileName)
	{	# If an item is a directory, then open it further.

		opendir(SUBDIR, $FileName) or die "Unable to open the directory, $FileName  for reading.\n";
		@SubDirs = readdir(SUBDIR);
		close(SUBDIR);


		$base = basename($FileName);	# Get the base name
		$dir = dirname($FileName);		# Get the directory name
		($base, $dir, $ext) = fileparse($FileName, '\..*');	# Get the extension of the file passed.

		# Intemediary automated script like base.pl, lib.pl, cmd.pl etc.
		$IntAutoScript = "t/".$base.".pl";


		# Write into auto.pl
		print FHWA "print \`perl $IntAutoScript\`\;\n";
		print FHWA "print \"\\n\\n\\n\"\;\n\n";

		
		print "Generating  $IntAutoScript...\n";
		# Write into the intermediary auto script.
		open(FHW, "> $IntAutoScript") or die "Unable to open the file,  $IntAutoScript  for writing.\n";
		seek(FHW, 0 ,0);
		flock(FHW, LOCK_EX);		# Lock the file for safety purposes.

		print FHW "\n\nprint \"Testing  $base  directory:\\n\\n\\n\"\;\n\n\n";


		foreach $SubFileName(@SubDirs)
		{
			if(-d $SubFileName)
			{
				$SubFileName = $FileName."/".$SubFileName;
				push @DirNames, $SubFileName;	# If sub-directory, push it into the array.
			}
			else
			{
				$SubFileName = $FileName."/".$SubFileName;
				&Process_File($SubFileName);	# If file, process it.
			}
		}

		# Write into the intermediary auto script.
		print FHW "\nprint \"Testing of  $base  directory done!\\n\\n\"\;\n\n";

		flock(FHW, LOCK_UN);	# unlock the file.
		close FHW;			# close the file.
		print "$IntAutoScript Done!\n\n";
	}
}

close(DIR);


# Write into  auto.pl
print FHWA "\nprint \"Automated Unit Testing of Perl$version  done!\\n\\n\"\;\n\n";

flock(FHWA, LOCK_UN);	# unlock the file.
close FHWA;			# close the file.

print "\nt/auto.pl Done!\n\n";


print "\nGeneration of automated scripts for NetWare  DONE!\n";



# Process the file.
sub Process_File
{
	local($FileToProcess) = @_;		# File name.
	local($Script) = 0;
	local($HeadCut) = 0;


	$base1 = basename($FileToProcess);	# Get the base name
	$dir1 = dirname($FileToProcess);		# Get the directory name
	($base1, $dir1, $ext1) = fileparse($FileToProcess, '\..*');	# Get the extension of the file passed.

	## If the value of $FileToProcess is '/perl/scripts/t/pragma/warnings.t', then
		## $dir1 = '/perl/scripts/t/pragma/'
		## $base1 = 'warnings'
		## $ext1 = '.t'


	# Do the processing only if the file has '.t' extension.
	if($ext1 eq '.t')
	{
		foreach $Script(@ScriptsNotUsed)
		{
			if($Script eq $FileToProcess)
			{
				$HeadCut = 1;
			}
		}

		if($HeadCut)
		{
			# Write into the intermediary auto script.
			print FHW "=head\n";
		}

		# Write into the intermediary auto script.
		print FHW "print \"Testing  $base1"."$ext1:\\n\\n\"\;\n";
		print FHW "print \`perl $FileToProcess\`\;\n";	# Write the changed array into the file.
		print FHW "print \"\\n\\n\\n\"\;\n";

		if($HeadCut)
		{
			# Write into the intermediary auto script.
			print FHW "=cut\n";
		}

		$HeadCut = 0;
		print FHW "\n";
	}
}

