package Encode::CN::HZ;

use strict;

use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Encode ();
use Encode::CN;
use base 'Encode::Encoding';

# HZ is but escaped GB, so we implement it with the
# GB2312(raw) encoding here. Cf. RFC 1842 & 1843.

my $canon = 'hz';
my $obj = bless {name => $canon}, __PACKAGE__;
$obj->Define($canon);

sub decode
{
    my ($obj,$str,$chk) = @_;
    my $gb = Encode::find_encoding('gb2312-raw');

    $str =~ s{~			# starting tilde
	(?:
	    (~)			# another tilde - escaped (set $1)
		|		#     or
	    \n			# \n - output nothing
		|		#     or
	    \{			# opening brace of GB data
		(		#  set $2 to any number of...
		    (?:	
			[^~]	#  non-tilde GB character
			    |   #     or
			~(?!\}) #  tilde not followed by a closing brace
		    )*
		)
	    ~\}			# closing brace of GB data
		|		# XXX: invalid escape - maybe die on $chk?
	)
    }{
	(defined $1)	? '~'			# two tildes make one tilde
	    :
	(defined $2)	? $gb->decode($2, $chk)	# decode the characters
	    :
	''					# ~\n and invalid escape = ''
    }egx;

    return $str;
}

sub encode
{
    my ($obj,$str,$chk) = @_;
    my ($out, $in_gb);
    my $gb = Encode::find_encoding('gb2312-raw');

    $str =~ s/~/~~/g;

    # XXX: Since CHECK and partial decoding has not been implemented yet,
    #      we'll use a very crude way to test for GB2312ness.

    for my $index (0 .. length($str) - 1) {
	no warnings 'utf8';

	my $char = substr($str, $index, 1);
	my $try  = $gb->encode($char);	# try to encode this character

	if (defined($try)) {		# is a GB character:
	    if ($in_gb) {
		$out .= $try;		#  in GB mode - just append it
	    }
	    else {
		$in_gb = 1;		#  enter GB mode, then append it
		$out .= "~{$try";
	    }
	}				# not a GB character:
	elsif ($in_gb) {
	    $in_gb = 0;			#  leave GB mode, then append it
	    $out .= "~}$char";
	}
	else {
	    $out .= $char;		#  not in GB mode - just append it
	}
    }

    $out .= '~}' if $in_gb;		# add closing brace if needed

    return $out;
}

1;
__END__


=head1 NAME

Encode::CN::HZ -- internally used by Encode::CN

=cut
