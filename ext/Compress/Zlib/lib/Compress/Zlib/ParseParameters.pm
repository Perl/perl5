
package Compress::Zlib::ParseParameters ;

use strict;
use warnings;
use Carp;

require Exporter;
our ($VERSION, @ISA, @EXPORT);
$VERSION = '2.000_05';
@ISA = qw(Exporter);

use constant Parse_any      => 0x01;
use constant Parse_unsigned => 0x02;
use constant Parse_signed   => 0x04;
use constant Parse_boolean  => 0x08;
use constant Parse_string   => 0x10;
use constant Parse_custom   => 0x12;

use constant Parse_store_ref => 0x100 ;

use constant OFF_PARSED     => 0 ;
use constant OFF_TYPE       => 1 ;
use constant OFF_DEFAULT    => 2 ;
use constant OFF_FIXED      => 3 ;

push @EXPORT, qw( ParseParameters 
                  Parse_any Parse_unsigned Parse_signed 
                  Parse_boolean Parse_custom Parse_string
                  Parse_store_ref
              );

sub ParseParameters
{
    my $level = shift || 0 ; 

    my $sub = (caller($level + 1))[3] ;
    local $Carp::CarpLevel = 1 ;
    my $p = new Compress::Zlib::ParseParameters() ;
    $p->parse(@_)
        or croak "$sub: $p->{Error}" ;

    return $p;
}

sub new
{
    my $class = shift ;
    my $obj = { Error => '',
                Got   => {},
              } ;

    #return bless $obj, ref($class) || $class || __PACKAGE__ ;
    return bless $obj ;
}

sub setError
{
    my $self = shift ;
    my $error = shift ;
    my $retval = @_ ? shift : undef ;

    $self->{Error} = $error ;
    return $retval;
}
          
#sub getError
#{
#    my $self = shift ;
#    return $self->{Error} ;
#}
          
sub parse
{
    my $self = shift ;

    my $default = shift ;

    my (@Bad) ;
    my @entered = () ;

    # Allow the options to be passed as a hash reference or
    # as the complete hash.
    if (@_ == 0) {
        @entered = () ;
    }
    elsif (@_ == 1) {
        my $href = $_[0] ;    
        return $self->setError("Expected even number of parameters, got 1")
            if ! defined $href or ! ref $href or ref $href ne "HASH" ;
 
        foreach my $key (keys %$href) {
            push @entered, $key ;
            push @entered, \$href->{$key} ;
        }
    }
    else {
        my $count = @_;
        return $self->setError("Expected even number of parameters, got $count")
            if $count % 2 != 0 ;
        
        for my $i (0.. $count / 2 - 1) {
            push @entered, $_[2* $i] ;
            push @entered, \$_[2* $i+1] ;
        }
    }


    my %got = () ;
    while (my ($key, $v) = each %$default)
    {
        my ($type, $value) = @$v ;
        my $x ;
        $self->_checkType($key, \$value, $type, 0, \$x) 
            or return undef ;
        $got{lc $key} = [0, $type, $value, $x] ;
    }

    for my $i (0.. @entered / 2 - 1) {
        my $key = $entered[2* $i] ;
        my $value = $entered[2* $i+1] ;

        #print "Key [$key] Value [$value]" ;
        #print defined $$value ? "[$$value]\n" : "[undef]\n";

        $key =~ s/^-// ;
 
        if ($got{lc $key})
        {
            my $type = $got{lc $key}[OFF_TYPE] ;
            my $s ;
            $self->_checkType($key, $value, $type, 1, \$s)
                or return undef ;
            #$value = $$value unless $type & Parse_store_ref ;
            $value = $$value ;
            $got{lc $key} = [1, $type, $value, $s] ;
        }
        else
          { push (@Bad, $key) }
    }
 
    if (@Bad) {
        my ($bad) = join(", ", @Bad) ;
        return $self->setError("unknown key value(s) @Bad") ;
    }

    $self->{Got} = { %got } ;

    return 1;
}

sub _checkType
{
    my $self = shift ;

    my $key   = shift ;
    my $value = shift ;
    my $type  = shift ;
    my $validate  = shift ;
    my $output  = shift;

    #local $Carp::CarpLevel = $level ;
    #print "PARSE $type $key $value $validate $sub\n" ;
    if ( $type & Parse_store_ref)
    {
        #$value = $$value
        #    if ref ${ $value } ;

        $$output = $value ;
        return 1;
    }

    $value = $$value ;

    if ($type & Parse_any)
    {
        $$output = $value ;
        return 1;
    }
    elsif ($type & Parse_unsigned)
    {
        return $self->setError("Parameter '$key' must be an unsigned int, got undef")
            if $validate && ! defined $value ;
        return $self->setError("Parameter '$key' must be an unsigned int, got '$value'")
            if $validate && $value !~ /^\d+$/;

        $$output = defined $value ? $value : 0 ;    
        return 1;
    }
    elsif ($type & Parse_signed)
    {
        return $self->setError("Parameter '$key' must be a signed int, got undef")
            if $validate && ! defined $value ;
        return $self->setError("Parameter '$key' must be a signed int, got '$value'")
            if $validate && $value !~ /^-?\d+$/;

        $$output = defined $value ? $value : 0 ;    
        return 1 ;
    }
    elsif ($type & Parse_boolean)
    {
        $$output =  defined $value ? $value != 0 : 0 ;    
        return 1;
    }
    elsif ($type & Parse_string)
    {
        $$output = defined $value ? $value : "" ;    
        return 1;
    }

    $$output = $value ;
    return 1;
}



sub parsed
{
    my $self = shift ;
    my $name = shift ;

    return $self->{Got}{lc $name}[OFF_PARSED] ;
}

sub value
{
    my $self = shift ;
    my $name = shift ;

    if (@_)
    {
        $self->{Got}{lc $name}[OFF_PARSED]  = 1;
        $self->{Got}{lc $name}[OFF_DEFAULT] = $_[0] ;
        $self->{Got}{lc $name}[OFF_FIXED]   = $_[0] ;
    }

    return $self->{Got}{lc $name}[OFF_FIXED] ;
}

sub valueOrDefault
{
    my $self = shift ;
    my $name = shift ;
    my $default = shift ;

    my $value = $self->{Got}{lc $name}[OFF_DEFAULT] ;

    return $value if defined $value ;
    return $default ;
}

sub wantValue
{
    my $self = shift ;
    my $name = shift ;

    return defined $self->{Got}{lc $name}[OFF_DEFAULT] ;

}

1;

