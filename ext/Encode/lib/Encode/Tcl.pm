package Encode::Tcl;
BEGIN {
    if (ord("A") == 193) {
	die "Encode::JP not supported on EBCDIC\n";
    }
}
use strict;
our $VERSION = do {my @r=(q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r};
use Encode qw(find_encoding);
use base 'Encode::Encoding';
use Carp;

=head1 NAME

Encode::Tcl - Tcl encodings

=cut

    sub INC_search
{
    foreach my $dir (@INC)
    {
	if (opendir(my $dh,"$dir/Encode"))
	{
	    while (defined(my $name = readdir($dh)))
	    {
		if ($name =~ /^(.*)\.enc$/)
		{
		    my $canon = $1;
		    my $obj = find_encoding($canon);
		    if (!defined($obj))
		    {
			my $obj = bless { Name => $canon, File => "$dir/Encode/$name"},__PACKAGE__;
			$obj->Define( $canon );
			# warn "$canon => $obj\n";
		    }
		}
	    }
	    closedir($dh);
	}
    }
}

sub import
{
    INC_search();
}

sub no_map_in_encode ($$)
    # codepoint, enc-name;
{
    carp sprintf "\"\\N{U+%x}\" does not map to %s", @_;
# /* FIXME: Skip over the character, copy in replacement and continue
#  * but that is messy so for now just fail.
#  */
    return;
}

sub no_map_in_decode ($$)
    # enc-name, string beginning the malform char;
{
# /* UTF-8 is supposed to be "Universal" so should not happen */
    croak sprintf "%s '%s' does not map to UTF-8", @_;
}

sub encode
{
    my $obj = shift;
    my $new = $obj->loadEncoding;
    return undef unless (defined $new);
    return $new->encode(@_);
}

sub new_sequence
{
    my $obj = shift;
    my $new = $obj->loadEncoding;
    return undef unless (defined $new);
    return $new->new_sequence(@_);
}

sub decode
{
    my $obj = shift;
    my $new = $obj->loadEncoding;
    return undef unless (defined $new);
    return $new->decode(@_);
}

sub loadEncoding
{
    my $obj = shift;
    my $file = $obj->{'File'};
    my $name = $obj->name;
    if (open(my $fh,$file))
    {
	my $type;
	while (1)
	{
	    my $line = <$fh>;
	    $type = substr($line,0,1);
	    last unless $type eq '#';
	}
	my $subclass =
	    ($type eq 'X') ? 'Extended' :
		($type eq 'H') ? 'HanZi'    :
		    ($type eq 'E') ? 'Escape'   : 'Table';
	my $class = ref($obj) . '::' . $subclass;
	# carp "Loading $file";
	bless $obj,$class;
	return $obj if $obj->read($fh,$obj->name,$type);
    }
    else
    {
	croak("Cannot open $file for ".$obj->name);
    }
    $obj->Undefine($name);
    return undef;
}

sub INC_find
{
    my ($class,$name) = @_;
    my $enc;
    foreach my $dir (@INC)
    {
	last if ($enc = $class->loadEncoding($name,"$dir/Encode/$name.enc"));
    }
    return $enc;
}

require Encode::Tcl::Table;
require Encode::Tcl::Escape;
require Encode::Tcl::Extended;
require Encode::Tcl::HanZi;

1;
__END__
