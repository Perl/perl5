#!../../miniperl

#
# We use the "two rows of 8" perspective to map the syllables onto the
# expected forms as per the various asundry Ethiopic locales...
#
open (GEEZ, ">Is/Y0.pl");
open (KAIB, ">Is/Y1.pl");
open (SALS, ">Is/Y2.pl");
open (RABI, ">Is/Y3.pl");
open (HAMS, ">Is/Y4.pl");
open (SADS, ">Is/Y5.pl");
open (SABI, ">Is/Y6.pl");

open (DIQALA_GEEZ, ">Is/Y8.pl");
open (DIQALA_SALS, ">Is/Y10.pl");
open (DIQALA_RABI, ">Is/Y11.pl");  # which is sometimes just DIQALA
open (DIQALA_HAMS, ">Is/Y12.pl");
open (DIQALA_SADS, ">Is/Y13.pl");  # though people outside of unicode.org 
                                   #  might say DIQALA_KAIB...

@fh = qw(
          GEEZ KAIB SALS RABI HAMS SADS SABI none
          DIQALA_GEEZ none DIQALA_SALS DIQALA_RABI DIQALA_HAMS DIQALA_SADS
	);


for $form (0..$#fh) {
	$FILE = $fh[$form];
	print $FILE "return <<'END'\n" if ($FILE ne "none");
}


open (ETHIOPIC, "EthiopicSyllables.txt");
while (<ETHIOPIC>) {
	($uni, $form) = split (/\s+/ );
	$FILE = $fh[$form];
	print $FILE "$uni\n";
}
close (ETHIOPIC);


for $form (0..$#fh) {
	$FILE = $fh[$form];
	print $FILE "END\n" if ($FILE ne "none");
}

close (GEEZ);
close (KAIB);
close (SALS);
close (RABI);
close (HAMS);
close (SADS);
close (SABI);

close (DIQALA_GEEZ);
close (DIQALA_SALS);
close (DIQALA_RABI);
close (DIQALA_HAMS);
close (DIQALA_SADS);

symlink ( "Is/Y11.pl", "Is/Y7.pl" );
symlink ( "Is/Y13.pl", "Is/Y9.pl" );
