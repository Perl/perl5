@rem = '--*-Perl-*--
@echo off
perl -x -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#!perl -w
#line 8
(my $head = <<'--end--') =~ s/^\t//gm;
	@rem = '--*-Perl-*--
	@echo off
	perl -x -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
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
	$myhead =~ s/perl -x/perl/ unless $linedone;
	print FILE $myhead;
	print FILE "#line $headlines\n" unless $linedone;
        print FILE @file, $tail;
        close( FILE );
    }
}
__END__
:endofperl
