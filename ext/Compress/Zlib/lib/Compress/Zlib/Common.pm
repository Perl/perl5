package Compress::Zlib::Common;

use strict ;
use warnings;
use bytes;

use Carp;
use Scalar::Util qw(blessed readonly);
use File::GlobMapper;

require Exporter;
our ($VERSION, @ISA, @EXPORT);
@ISA = qw(Exporter);
$VERSION = '2.000_05';

@EXPORT = qw( isaFilehandle isaFilename whatIsInput whatIsOutput ckInputParam 
              isaFileGlobString cleanFileGlobString oneTarget
              setBinModeInput setBinModeOutput
              ckOutputParam ckInOutParams 
              WANT_CODE
              WANT_EXT
              WANT_UNDEF
              WANT_HASH
          );  

our ($wantBinmode);
$wantBinmode = ($] >= 5.006 && eval ' ${^UNICODE} || ${^UTF8LOCALE} ')
                    ? 1 : 0 ;

sub setBinModeInput($$)
{
    my $handle = shift ;
    my $want   = defined $_[0] ? shift : $wantBinmode ;

    binmode $handle 
        if  $want;
}

sub setBinModeOutput($$)
{
    my $handle = shift ;
    my $want   = defined $_[0] ? shift : $wantBinmode ;

    binmode $handle 
        if  $want;
}

sub isaFilehandle($)
{
    use utf8; # Pragma needed to keep Perl 5.6.0 happy
    return (defined $_[0] and 
             (UNIVERSAL::isa($_[0],'GLOB') or UNIVERSAL::isa(\$_[0],'GLOB')) 
                 and defined fileno($_[0])  )
}

sub isaFilename($)
{
    return (defined $_[0] and 
           ! ref $_[0]    and 
           UNIVERSAL::isa(\$_[0], 'SCALAR'));
}

sub isaFileGlobString
{
    return defined $_[0] && $_[0] =~ /^<.*>$/;
}

sub cleanFileGlobString
{
    my $string = shift ;

    $string =~ s/^\s*<\s*(.*)\s*>\s*$/$1/;

    return $string;
}

use constant WANT_CODE  => 1 ;
use constant WANT_EXT   => 2 ;
use constant WANT_UNDEF => 4 ;
use constant WANT_HASH  => 8 ;

sub whatIsInput($;$)
{
    my $got = whatIs(@_);
    
    if (defined $got && $got eq 'filename' && defined $_[0] && $_[0] eq '-')
    {
        use IO::File;
        $got = 'handle';
        #$_[0] = \*STDIN;
        $_[0] = new IO::File("<-");
    }

    return $got;
}

sub whatIsOutput($;$)
{
    my $got = whatIs(@_);
    
    if (defined $got && $got eq 'filename' && defined $_[0] && $_[0] eq '-')
    {
        $got = 'handle';
        #$_[0] = \*STDOUT;
        $_[0] = new IO::File(">-");
    }
    
    return $got;
}

sub whatIs ($;$)
{
    return 'handle' if isaFilehandle($_[0]);

    my $wantCode = defined $_[1] && $_[1] & WANT_CODE ;
    my $extended = defined $_[1] && $_[1] & WANT_EXT ;
    my $undef    = defined $_[1] && $_[1] & WANT_UNDEF ;
    my $hash     = defined $_[1] && $_[1] & WANT_HASH ;

    return 'undef'  if ! defined $_[0] && $undef ;

    if (ref $_[0]) {
        return ''       if blessed($_[0]); # is an object
        #return ''       if UNIVERSAL::isa($_[0], 'UNIVERSAL'); # is an object
        return 'buffer' if UNIVERSAL::isa($_[0], 'SCALAR');
        return 'array'  if UNIVERSAL::isa($_[0], 'ARRAY')  && $extended ;
        return 'hash'   if UNIVERSAL::isa($_[0], 'HASH')   && $hash ;
        return 'code'   if UNIVERSAL::isa($_[0], 'CODE')   && $wantCode ;
        return '';
    }

    return 'fileglob' if $extended && isaFileGlobString($_[0]);
    return 'filename';
}

sub oneTarget
{
    return $_[0] =~ /^(code|handle|buffer|filename)$/;
}

sub ckInputParam ($$$;$)
{
    my $from = shift ;
    my $inType = whatIsInput($_[0], $_[2]);
    local $Carp::CarpLevel = 1;

    croak "$from: input parameter not a filename, filehandle, array ref or scalar ref"
        if ! $inType ;

    if ($inType  eq 'filename' )
    {
        croak "$from: input filename is undef or null string"
            if ! defined $_[0] || $_[0] eq ''  ;

        if ($_[0] ne '-' && ! -e $_[0] )
        {
            ${$_[1]} = "input file '$_[0]' does not exist";
            return undef;
        }
    }

    return 1;
}

sub ckOutputParam ($$$)
{
    my $from = shift ;
    my $outType = whatIsOutput($_[0]);
    local $Carp::CarpLevel = 1;

    croak "$from: output parameter not a filename, filehandle or scalar ref"
        if ! $outType ;

    croak "$from: output filename is undef or null string"
        if $outType eq 'filename' && (! defined $_[0] || $_[0] eq '')  ;

    croak("$from: output buffer is read-only")
        if $outType eq 'buffer' && readonly(${ $_[0] });
    
    return 1;    
}

sub Validator::new
{
    my $class = shift ;

    my $Class = shift ;
    my $type = shift ;
    my $error_ref = shift ;
    my $reportClass = shift ;

    my %data = (Class       => $Class, 
                Type        => $type,
                Error       => $error_ref,
                reportClass => $reportClass, 
               ) ;

    my $obj = bless \%data, $class ;

    local $Carp::CarpLevel = 1;

    my $inType    = $data{inType}    = whatIsInput($_[0], WANT_EXT|WANT_HASH);
    my $outType   = $data{outType}   = whatIsOutput($_[1], WANT_EXT|WANT_HASH);

    my $oneInput  = $data{oneInput}  = oneTarget($inType);
    my $oneOutput = $data{oneOutput} = oneTarget($outType);

    if (! $inType)
    {
        croak "$reportClass: illegal input parameter" ;
        #return undef ;
    }    

    if ($inType eq 'hash')
    {
        $obj->{Hash} = 1 ;
        $obj->{oneInput} = 1 ;
        return $obj->validateHash($_[0]);
    }

    if (! $outType)
    {
        croak "$reportClass: illegal output parameter" ;
        #return undef ;
    }    


    if ($inType ne 'fileglob' && $outType eq 'fileglob')
    {
        ${ $data{Error} } = "Need input fileglob for outout fileglob";
        return undef ;
    }    

    if ($inType ne 'fileglob' && $outType eq 'hash' && $inType ne 'filename' )
    {
        ${ $data{Error} } = "input must ne filename or fileglob when output is a hash";
        return undef ;
    }    

    if ($inType eq 'fileglob' && $outType eq 'fileglob')
    {
        $data{GlobMap} = 1 ;
        $data{inType} = $data{outType} = 'filename';
        my $mapper = new File::GlobMapper($_[0], $_[1]);
        if ( ! $mapper )
        {
            ${ $data{Error} } = $File::GlobMapper::Error ;
            return undef ;
        }
        $data{Pairs} = $mapper->getFileMap();

        return $obj;
    }
    
    croak("$reportClass: input and output $inType are identical")
        if $inType eq $outType && $_[0] eq $_[1] && $_[0] ne '-' ;

    if ($inType eq 'fileglob') # && $outType ne 'fileglob'
    {
        my $glob = cleanFileGlobString($_[0]);
        my @inputs = glob($glob);

        if (@inputs == 0)
        {
            # legal or die?
            die "legal or die???" ;
        }
        elsif (@inputs == 1)
        {
            $obj->validateInputFilenames($inputs[0])
                or return undef;
            $_[0] = $inputs[0]  ;
            $data{inType} = 'filename' ;
            $data{oneInput} = 1;
        }
        else
        {
            $obj->validateInputFilenames(@inputs)
                or return undef;
            $_[0] = [ @inputs ] ;
            $data{inType} = 'filenames' ;
        }
    }
    elsif ($inType eq 'filename')
    {
        $obj->validateInputFilenames($_[0])
            or return undef;
    }
    elsif ($inType eq 'array')
    {
        $obj->validateInputArray($_[0])
            or return undef ;
    }

    croak("$reportClass: output buffer is read-only")
        if $outType eq 'buffer' && Compress::Zlib::_readonly_ref($_[1]);

    if ($outType eq 'filename' )
    {
        croak "$reportClass: output filename is undef or null string"
            if ! defined $_[1] || $_[1] eq ''  ;
    }
    
    return $obj ;
}


sub Validator::validateInputFilenames
{
    my $self = shift ;

    foreach my $filename (@_)
    {
        croak "$self->{reportClass}: input filename is undef or null string"
            if ! defined $filename || $filename eq ''  ;

        next if $filename eq '-';

        if (! -e $filename )
        {
            ${ $self->{Error} } = "input file '$filename' does not exist";
            return undef;
        }

        if (! -r $filename )
        {
            ${ $self->{Error} } = "cannot open file '$filename': $!";
            return undef;
        }
    }

    return 1 ;
}

sub Validator::validateInputArray
{
    my $self = shift ;

    foreach my $element ( @{ $_[0] } )
    {
        my $inType  = whatIsInput($element);
    
        if (! $inType)
        {
            ${ $self->{Error} } = "unknown input parameter" ;
            return undef ;
        }    
    }

    return 1 ;
}

sub Validator::validateHash
{
    my $self = shift ;
    my $href = shift ;

    while (my($k, $v) = each %$href)
    {
        my $ktype = whatIsInput($k);
        my $vtype = whatIsOutput($v, WANT_EXT|WANT_UNDEF) ;

        if ($ktype ne 'filename')
        {
            ${ $self->{Error} } = "hash key not filename" ;
            return undef ;
        }    

        my %valid = map { $_ => 1 } qw(filename buffer array undef handle) ;
        if (! $valid{$vtype})
        {
            ${ $self->{Error} } = "hash value not ok" ;
            return undef ;
        }    
    }

    return $self ;
}

1;
