@rem = '--*-Perl-*--
@echo off
perl -x -S %0 %*
goto endofperl
@rem ';
#!perl -w
#line 8
(my $head = <<'--end--') =~ s/^\t//gm;
	@rem = '--*-Perl-*--
	@echo off
	perl -x -S %0 %*
	goto endofperl
	@rem ';
--end--
my $headlines = 2 + ($head =~ tr/\n/\n/);
my $tail = "__END__\n:endofperl\n";

@ARGV = ('-') unless @ARGV;

process(@ARGV);

sub process {
   LOOP:
    foreach ( @_ ) {
    	my $myhead = $head;
    	my $linedone = 0;
	my $linenum = $headlines;
	my $line;
        open( FILE, $_ ) or die "Can't open $_: $!";
        @file = <FILE>;
        foreach $line ( @file ) {
	    $linenum++;
            if ( $line =~ /^:endofperl/) {
                warn "$_ has already been converted to a batch file!\n";
                next LOOP;
	    }
	    if ( not $linedone and $line =~ /^#!.*perl/ ) {
		$line .= "#line $linenum\n";
		$linedone++;
	    }
        }
        close( FILE );
        s/\.pl$//;
        $_ .= '.bat' unless /\.bat$/ or /^-$/;
        open( FILE, ">$_" ) or die "Can't open $_: $!";
	print FILE $myhead;
	print FILE "#!perl\n#line " . ($headlines+1) . "\n" unless $linedone;
        print FILE @file, $tail;
        close( FILE );
    }
}
__END__

=head1 NAME

pl2bat.bat - a batch file to wrap perl code into a batch file

=head1 SYNOPSIS

	C:\> pl2bat foo.pl bar 
	[..creates foo.bat, bar.bat..]
	
	C:\> pl2bat < somefile > another.bat
	
	C:\> pl2bat > another.bat
	print scalar reverse "rekcah lrep rehtona tsuj\n";
	^Z
	[..another.bat is now a certified japh application..]

=head1 DESCRIPTION

This utility converts a perl script into a batch file that can be
executed on DOS-like operating systems.

Note that the ".pl" suffix will be stripped before adding a
".bat" suffix to the supplied file names.

The batch file created makes use of the C<%*> construct to refer
to all the command line arguments that were given to the batch file,
so you'll need to make sure that works on your variant of the
command shell.  It is known to work in the cmd.exe shell under
WindowsNT.  4DOS/NT users will want to put a C<ParameterChar = *>
line in their initialization file, or execute C<setdos /p*> in
the shell startup file.

=head1 BUGS

C<$0> will contain the full name, including the ".bat" suffix.
If you don't like this, see runperl.bat for an alternative way to
invoke perl scripts.

Perl is invoked with the -S flag, so it will search the PATH to find
the script.  This may have undesirable effects.

=head1 SEE ALSO

perl, perlwin32, runperl.bat

=cut

__END__
:endofperl

