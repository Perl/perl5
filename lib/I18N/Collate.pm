package I18N::Collate;

# Collate.pm
#
# Author:	Jarkko Hietaniemi <Jarkko.Hietaniemi@hut.fi>
#		Helsinki University of Technology, Finland
#
# Acks:		Guy Decoux <decoux@moulon.inra.fr> understood
#		overloading magic much deeper than I and told
#		how to cut the size of this code by more than half.
#		(my first version did overload all of lt gt eq le ge cmp)
#
# Purpose:      compare 8-bit scalar data according to the current locale
#
# Requirements:	Perl5 POSIX::setlocale() and POSIX::strxfrm()
#
# Exports:	setlocale 1)
#		collate_xfrm 2)
#
# Overloads:	cmp # 3)
#
# Usage:	use Collate;
#	        setlocale(&LC_COLLATE, 'locale-of-your-choice'); # 4)
#		$s1 = new Collate "scalar_data_1";
#		$s2 = new Collate "scalar_data_2";
#		
#		now you can compare $s1 and $s2: $s1 le $s2
#		to extract the data itself, you need to deref: $$s1
#		
# Notes:	
#		1) this uses POSIX::setlocale
#		2) the basic collation conversion is done by strxfrm() which
#		   terminates at NUL characters being a decent C routine.
#		   collate_xfrm handles embedded NUL characters gracefully.
#		3) due to cmp and overload magic, lt le eq ge gt work also
#		4) the available locales depend on your operating system;
#		   try whether "locale -a" shows them or the more direct
#		   approach "ls /usr/lib/nls/loc" or "ls /usr/lib/nls".
#		   The locale names are probably something like
#		   'xx_XX.(ISO)?8859-N'.
#
# Updated:	19940913 1341 GMT
#
# ---

use POSIX qw(strxfrm LC_COLLATE);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(collate_xfrm setlocale LC_COLLATE);
@EXPORT_OK = qw();

%OVERLOAD = qw(
fallback	1
cmp		collate_cmp
);

sub new { my $new = $_[1]; bless \$new }

sub setlocale {
 my ($category, $locale) = @_[0,1];

 POSIX::setlocale($category, $locale) if (defined $category);
 # the current $LOCALE 
 $LOCALE = $locale || $ENV{'LC_COLLATE'} || $ENV{'LC_ALL'} || '';
}

sub C {
  my $s = ${$_[0]};

  $C->{$LOCALE}->{$s} = collate_xfrm($s)
    unless (defined $C->{$LOCALE}->{$s}); # cache when met

  $C->{$LOCALE}->{$s};
}

sub collate_xfrm {
  my $s = $_[0];
  my $x = '';
  
  for (split(/(\000+)/, $s)) {
    $x .= (/^\000/) ? $_ : strxfrm("$_\000");
  }

  $x;
}

sub collate_cmp {
  &C($_[0]) cmp &C($_[1]);
}

# init $LOCALE

&I18N::Collate::setlocale();

1; # keep require happy
