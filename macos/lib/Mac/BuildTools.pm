package Mac::BuildTools;

use AutoSplit;
use Cwd;
use File::Copy;
use File::Find;
use File::Path;
use Mac::Files;
use Mac::MoreFiles qw(%Application);
use ExtUtils::MakeMaker;
use ExtUtils::MM_MacOS;

# much of this package must be used in conjunction with
# ExtUtils::MM_MacOS

sub make {
	my($self, $make_data, $name, $prefix, %copy, $file, @files, %mkpath, $cwd);
	$self = shift;
	$self->{'make'} = 'YES';
	$cwd = cwd();

	undef $@;
	unless (eval { package main; do ":Makefile.PL" }) {
		warn "Can't do ${cwd}Makefile.PL: $@\n";
	}
	warn $@ if $@;

	$make_data = $ExtUtils::MM_MacOS::make_data{$cwd}
		or die "No $cwd package data";

	@files = ((sort keys %{$make_data->{PM}}),
		(sort keys %{$make_data->{XS}}));

	# taken from InstallBLIB
	$name = $make_data->{NAME};
	if (($prefix) = $name =~ /(.*::)/) {
		$prefix =~ s/::/:/g;
	}
	$prefix ||= "";

	FILE:
	for $file (@files) {
		$file = ":$file" unless $file =~ /^:/;

#		this doesn't seem to be right: if something is in :lib:,
#		should we assume it already has the right prefxies?
#		(my $new = $file) =~ s|^:(lib:)?|:blib:lib:$prefix|;
		(my $new = $file) =~ s/^:(lib:|$prefix)?/':blib:lib:' .
			($1 && $1 eq 'lib:' ? '' : $prefix)/e;

		XSCHECK: {
			if ($file =~ /\.xs$/) {
				open(F, $file) || die;
				while (<F>) {
					last XSCHECK if /^=/; 
				}
				print STDERR "Skipping $file, which doesn't contain any pod.\n";
				next FILE;
			}
		}
		$copy{$file} = $new;
		$new =~ /^(.*:)/; 
		$mkpath{$1} = 1;
	}
	mkpath([sort keys %mkpath], 1);

	foreach my $file (keys %copy) {
		print "copying $file -> $copy{$file}\n";
		copy($file, $copy{$file});
	}
}

sub make_test {
	my $self = shift;
	$self->{'make_test'} = 'YES';
}

sub make_clean {}

sub make_install {
	# taken from PerlInstall
	my(%dirs, $dir, $d);
	$dirs{lib} = "$ENV{MACPERL}site_perl";
	while (-l $dirs{lib}) {
		$dirs{lib} = readlink $dirs{lib};
	}
	$dirs{lib} =~ s/:$//;
	chomp($dir = `pwd`);

	$dir .= ":" unless ($dir =~ /:$/);
	$dir .= "blib";

	my($fromdir, $todir);
	my $make_copyit = sub {
		local($_) = $_;

		my($newdir,$auto,$name) = ($File::Find::dir,
			$File::Find::dir, $File::Find::name);

		$newdir =~ s/\Q$fromdir\E/$todir/;
		$auto   =~ s/.*\Q$fromdir\E.*$/$todir:auto/;
		$name   =~ s/.*\Q$fromdir\E//;
		return if -d $_;
		$newdir =~ s/:$//;

		printf("    %-20s -> %s\n", $name, $newdir);
		mkpath($newdir, 1);

		if (!copy($_, "$newdir:$_")) {
			die "'$newdir:$_' does not exist" unless -e "$newdir:$_";
			printf("    Moving %-20s -> %s\nDelete old file manually\n",
				"$newdir:$_", "$newdir:$_ old");
			move "$newdir:$_", "$newdir:$_ old";
			copy($_, "$newdir:$_") or die $^E;
		}

		autosplit("$newdir:$_", $auto, 0, 1, 0) if /\.pm$/;
	};

	opendir(DIR, $dir);
	while (defined($d = readdir(DIR))) {
		next unless -d "$dir:$d";
		$fromdir = "$dir:$d";
		$todir   = $dirs{$d};
		print "  $fromdir\n";
		find($make_copyit, $fromdir);
	}
	closedir(DIR);

	$self->{'make_install'} = 'YES';
}


sub convert_files {
	require Mac::Conversions;
	require Mac::InternetConfig;
	Mac::InternetConfig->import;

	my @def = (GetICHelper('editor') || 'ttxt', 'TEXT');

	my($files, $verbose) = @_;
	my $conv = Mac::Conversions->new(Remove => 1);
	foreach my $file (@$files) {
		$file = ':' . Archive::Tar::_munge_file($file);
		if (-e $file) {
			chmod 0666, $file or warn "$file: $!\n";
		}

		my @info;
		if (ref(my $map = $InternetConfigMap{$file}) eq 'ICMapEntry') {
			@info = ($map->file_creator, $map->file_type);
		}
		@info = @def unless $info[0] && $info[1];
		MacPerl::SetFileInfo(@info, $file);

		if (! -e $file) {
			print "  Can't find '$file'\n";
		} elsif (-T _) {
			chmod 0666, $file or die $!;
			local(*FILE, $/);

			open(FILE, "< $file\0") or die $!;
			my $text = <FILE>;
			next unless $text;
			$text =~ s/\015?\012/\n/g;
			close(FILE);

			open(FILE, "> $file\0") or die $!;
			print FILE $text;
			close(FILE);

			print "  LF->CR translate  $file\n" if $verbose;

		} elsif (-B _ && $file =~ /\.bin$/ && $conv->is_macbinary($file)) {
			$conv->demacbinary($file);
			print "  convert MacBinary $file\n" if $verbose;
		} elsif (-f _) {
			print "  left alone        $file\n" if $verbose;
		}
	}
}

sub launch_file {
	require Mac::AppleEvents::Simple;
	Mac::AppleEvents::Simple->import;
	my($file, $use_cwd, $wait) = @_;
	my($editor, @editors);

	$wait ||= 0;
	if ($use_cwd) {
		chomp(my $cwd = `pwd`);
		$file =~ s/^://;
		$file = "$cwd:$file";
	}

	@editors = qw(R*ch ALFA ttxt);  #  others?
	unshift @editors, $ENV{EDITOR} if $ENV{EDITOR};
	unshift @editors, $CPAN::Config->{pager}
		if $CPAN::Config->{pager} && length ($CPAN::Config->{pager}) == 4;
	foreach (@editors) {
		$editor = $Application{$_};
		last if $editor;
	}

	do_event(qw/aevt odoc MACS/,
		q"'----':alis(@@), usin:alis(@@)",
		map {NewAliasMinimal $_} $file, $editor);
}

sub look {
	require Mac::AppleEvents::Simple;
	Mac::AppleEvents::Simple->import;

	my($self, $cwd) = @_;
	$cwd = $self->dir or $self->get;
	$cwd = $self->dir;

	local $Mac::AppleEvents::Simple::SWITCH = 1;
	do_event(qw/aevt odoc MACS/,
		q"'----':alis(@@)",
		NewAliasMinimal($cwd));
}

1;

__END__
