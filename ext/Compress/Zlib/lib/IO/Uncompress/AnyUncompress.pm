package IO::Uncompress::AnyUncompress ;

use strict;
use warnings;

use Compress::Zlib::Common qw(createSelfTiedObject);

#use IO::Uncompress::Base ;
use IO::Uncompress::Gunzip ;
use IO::Uncompress::Inflate ;
use IO::Uncompress::RawInflate ;
use IO::Uncompress::Unzip ;

BEGIN
{
   eval { require UncompressPlugin::Bunzip2; import UncompressPlugin::Bunzip2 };
   eval { require UncompressPlugin::LZO;     import UncompressPlugin::LZO     };
   eval { require IO::Uncompress::Bunzip2;   import IO::Uncompress::Bunzip2 };
   eval { require IO::Uncompress::UnLzop;    import IO::Uncompress::UnLzop };
}

require Exporter ;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, $AnyUncompressError);

$VERSION = '2.000_05';
$AnyUncompressError = '';

@ISA = qw( Exporter IO::Uncompress::Base );
@EXPORT_OK = qw( $AnyUncompressError anyuncompress ) ;
%EXPORT_TAGS = %IO::Uncompress::Base::DEFLATE_CONSTANTS ;
push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');

# TODO - allow the user to pick a set of the three formats to allow
#        or just assume want to auto-detect any of the three formats.

sub new
{
    my $class = shift ;
    my $obj = createSelfTiedObject($class, \$AnyUncompressError);
    $obj->_create(undef, 0, @_);
}

sub anyuncompress
{
    my $obj = createSelfTiedObject(undef, \$AnyUncompressError);
    return $obj->_inf(@_) ;
}

sub getExtraParams
{
    return ();
}

sub ckParams
{
    my $self = shift ;
    my $got = shift ;

    # any always needs both crc32 and adler32
    $got->value('CRC32' => 1);
    $got->value('ADLER32' => 1);

    return 1;
}

sub mkUncomp
{
    my $self = shift ;
    my $class = shift ;
    my $got = shift ;

    # try zlib first
    my ($obj, $errstr, $errno) = UncompressPlugin::Inflate::mkUncompObject();

    return $self->saveErrorString(undef, $errstr, $errno)
        if ! defined $obj;

    *$self->{Uncomp} = $obj;
    
     my $magic = $self->ckMagic( qw( RawInflate Inflate Gunzip Unzip ) ); 

     if ($magic) {
        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        return 1;
     }

     #foreach my $type ( qw( Bunzip2 UnLzop ) ) {
     if (defined $IO::Uncompress::Bunzip2::VERSION and
         $magic = $self->ckMagic('Bunzip2')) {
        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) = UncompressPlugin::Bunzip2::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }
     elsif (defined $IO::Uncompress::UnLzop::VERSION and
            $magic = $self->ckMagic('UnLzop')) {

        *$self->{Info} = $self->readHeader($magic)
            or return undef ;

        my ($obj, $errstr, $errno) = UncompressPlugin::LZO::mkUncompObject();

        return $self->saveErrorString(undef, $errstr, $errno)
            if ! defined $obj;

        *$self->{Uncomp} = $obj;

         return 1;
     }

     return 0 ;
}



sub ckMagic
{
    my $self = shift;
    my @names = @_ ;

    my $keep = ref $self ;
    for my $class ( map { "IO::Uncompress::$_" } @names)
    {
        bless $self => $class;
        my $magic = $self->ckMagic();

        if ($magic)
        {
            #bless $self => $class;
            return $magic ;
        }

        $self->pushBack(*$self->{HeaderPending})  ;
        *$self->{HeaderPending} = ''  ;
    }    

    bless $self => $keep;
    return undef;
}

1 ;

__END__


