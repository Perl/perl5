@rem = '
@echo off
perl -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';

$head = <<'--end--';
@rem = '--*-Perl-*--';
@rem = '
@echo off
perl -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
--end--

$tail = "__END__\n:endofperl\n";

if ( @ARGV ) {
   LOOP:
    foreach ( @ARGV ) {
        open( FILE, $_ );
        @file = <FILE>;
        if ( grep( /:endofperl/, @file ) ) {
            warn "$_ has already been converted to a batch file!!\n";
            next LOOP;
        }            
        close( FILE, $_ );
        s/\.pl//;
        s/\.bat//;
        open( FILE, ">$_.bat" );
        print FILE $head, @file, $tail;
        close( FILE );
    }
} else {
    @file = <STDIN>;
    print $head, @file, $tail;
}

__END__
:endofperl
