#!perl -w
# p2as
# pudge@pobox.com
# 1999.03.12

use File::Basename;
use Mac::OSA::Simple 0.50 qw(:all);
use Mac::Resources;
use Mac::Memory;
use strict;

die "Need at least one Perl script!\n" unless @ARGV;

# select which type of compiled script you want ... hardcode this
# if you like:	Text = 1, Alias = 0
my $switch = MacPerl::Answer('For all scripts, save script text or ' .
	 'alias to script on disk?', 'Text', 'Alias');

# drop as many scripts as you can handle
for my $f (@ARGV) {
	my($comp, $data, $res, $script, $len, $file, $dir, $text);

	# get AppleScript text
	$text = ($switch ? get_text($f) : get_alias($f))
		or (warn("No text for '$f'") && next);

	# get new name of file
	($file, $dir) = fileparse($f, '\..+$');
	$file = "$dir$file.scr";

	# get compiled AppleScript and save it to the file
	$comp = compile_applescript($text) or die $^E;
	$comp->save($file);
}

sub get_alias {
	my($file, $text) = @_;
	
	fix_text($file);

	$text = qq'tell application "MacPerl"\n	 activate\n	 Do Script alias "$file"\nend tell';
}

sub get_text {
	my($file, $script, $text) = @_;
	local($/, *F);

	open F, $file or die "Can't open '$file': $!";
	$script = <F>;
	close F or die "Can't close '$file': $!";

	fix_text($script);

	$text = qq'tell application "MacPerl"\n	 activate\n	 Do Script "\n$script\n"\nend tell';
}

sub fix_text {
	my $text = shift;
	
	# more to do than just fix " marks and \ ?
	$$text =~ s/\\/\\\\/g;
	$$text =~ s/"/\\"/g;

	1;
}

__END__
