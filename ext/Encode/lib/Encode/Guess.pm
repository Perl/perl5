package Encode::Guess;
use strict;
use Carp;
use Encode qw(:fallbacks find_encoding);
our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $Canon = 'Guess';
$Encode::Encoding{$Canon} = bless { Name => $Canon } => __PACKAGE__;
our $DEBUG = 0;
our %DEF_CANDIDATES = 
    map { $_ => find_encoding($_) } qw(ascii utf8);
our %CANDIDATES;


sub import{
    my $class = shift;
    %CANDIDATES = %DEF_CANDIDATES;
    for my $c (@_){
	my $e = find_encoding($c) or die "Unknown encoding: $c";
	$CANDIDATES{$e->name} = $e;
	$DEBUG and warn "Added: ", $e->name;
    }
}

sub name { shift->{'Name'} }
sub new_sequence { $_[0] }
sub needs_lines { 1 }
sub perlio_ok { 0 }

sub decode($$;$){
    my ($obj, $octet, $chk) = @_;
    my $utf8 = $obj->guess($octet)->decode($octet, $chk);
    $_[1] = $octet if $chk;
    return $utf8;
}

sub encode{
    croak "Tsk, tsk, tsk.  You can't be too lazy here here!";
}

sub guess {
    my ($obj, $octet) = @_;
    # cheat 1: utf8 flag;
    Encode::is_utf8($octet) and return find_encoding('utf8');
    my %try = %CANDIDATES;
    my $nline = 1;
    for my $line (split /\r|\n|\r\n/, $octet){
	# cheat 2 -- escape
	if ($line =~ /\e/o){
	    my @keys = keys %try;
	    delete @try{qw/utf8 ascii/};
	    for my $k (@keys){
		ref($try{$k}) eq 'Encode::XS' and delete $try{$k};
	    }
	}
	my %ok = %try;
	# warn join(",", keys %try);
	for my $k (keys %try){
	    my $scratch = $line;
	    $try{$k}->decode($scratch, FB_QUIET);
	    if ($scratch eq ''){
		$DEBUG and warn sprintf("%4d:%-24s ok\n", $nline, $k);
	    }else{
		use bytes ();
		$DEBUG and 
		    warn sprintf("%4d:%-24s not ok; %d bytes left\n", 
				 $nline, $k, bytes::length($scratch));
		delete $ok{$k};
		
	    }
	}
	%ok or croak "No appropriate encodings found!";
	if (scalar(keys(%ok)) == 1){
	    my ($retval) = values(%ok);
	    return $retval;
	}
	%try = %ok; $nline++;
    }
    unless ($try{ascii}){
	croak "Encodings too ambiguous: ", 
	    join(" or ", keys %try);
    }
    return $try{ascii};
}


1;
__END__

=head1 NAME

Encode::Guess -- guesscoding!

=cut

