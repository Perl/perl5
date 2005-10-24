
package Compress::Zlib;

require 5.004 ;
require Exporter;
use AutoLoader;
use Carp ;
use IO::Handle ;
use Scalar::Util qw(dualvar);

use Compress::Zlib::Common;
use Compress::Zlib::ParseParameters;

use strict ;
use warnings ;
use bytes ;
our ($VERSION, $XS_VERSION, @ISA, @EXPORT, $AUTOLOAD);

$VERSION = '2.000_06';
$XS_VERSION = $VERSION; 
$VERSION = eval $VERSION;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
        deflateInit inflateInit

        compress uncompress

        gzopen $gzerrno

        adler32 crc32

        ZLIB_VERSION
        ZLIB_VERNUM

        DEF_WBITS
        OS_CODE

        MAX_MEM_LEVEL
        MAX_WBITS

        Z_ASCII
        Z_BEST_COMPRESSION
        Z_BEST_SPEED
        Z_BINARY
        Z_BLOCK
        Z_BUF_ERROR
        Z_DATA_ERROR
        Z_DEFAULT_COMPRESSION
        Z_DEFAULT_STRATEGY
        Z_DEFLATED
        Z_ERRNO
        Z_FILTERED
        Z_FIXED
        Z_FINISH
        Z_FULL_FLUSH
        Z_HUFFMAN_ONLY
        Z_MEM_ERROR
        Z_NEED_DICT
        Z_NO_COMPRESSION
        Z_NO_FLUSH
        Z_NULL
        Z_OK
        Z_PARTIAL_FLUSH
        Z_RLE
        Z_STREAM_END
        Z_STREAM_ERROR
        Z_SYNC_FLUSH
        Z_UNKNOWN
        Z_VERSION_ERROR
);

sub AUTOLOAD {
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my ($error, $val) = constant($constname);
    Carp::croak $error if $error;
    no strict 'refs';
    *{$AUTOLOAD} = sub { $val };
    goto &{$AUTOLOAD};
}

use constant FLAG_APPEND             => 1 ;
use constant FLAG_CRC                => 2 ;
use constant FLAG_ADLER              => 4 ;
use constant FLAG_CONSUME_INPUT      => 8 ;

eval {
    require XSLoader;
    XSLoader::load('Compress::Zlib', $XS_VERSION);
    1;
} 
or do {
    require DynaLoader;
    local @ISA = qw(DynaLoader);
    bootstrap Compress::Zlib $XS_VERSION ; 
};
 
# Preloaded methods go here.

require IO::Compress::Gzip;
require IO::Uncompress::Gunzip;

our (@my_z_errmsg);

@my_z_errmsg = (
    "need dictionary",     # Z_NEED_DICT     2
    "stream end",          # Z_STREAM_END    1
    "",                    # Z_OK            0
    "file error",          # Z_ERRNO        (-1)
    "stream error",        # Z_STREAM_ERROR (-2)
    "data error",          # Z_DATA_ERROR   (-3)
    "insufficient memory", # Z_MEM_ERROR    (-4)
    "buffer error",        # Z_BUF_ERROR    (-5)
    "incompatible version",# Z_VERSION_ERROR(-6)
    );


sub _set_gzerr
{
    my $value = shift ;

    if ($value == 0) {
        $Compress::Zlib::gzerrno = 0 ;
    }
    elsif ($value == Z_ERRNO() || $value > 2) {
        $Compress::Zlib::gzerrno = $! ;
    }
    else {
        $Compress::Zlib::gzerrno = dualvar($value+0, $my_z_errmsg[2 - $value]);
    }

    return $value ;
}

sub _save_gzerr
{
    my $gz = shift ;
    my $test_eof = shift ;

    my $value = $gz->errorNo() || 0 ;

    if ($test_eof) {
        #my $gz = $self->[0] ;
        # gzread uses Z_STREAM_END to denote a successful end
        $value = Z_STREAM_END() if $gz->eof() && $value == 0 ;
    }

    _set_gzerr($value) ;
}

sub gzopen($$)
{
    my ($file, $mode) = @_ ;

    my $gz ;
    my %defOpts = (Level    => Z_DEFAULT_COMPRESSION(),
                   Strategy => Z_DEFAULT_STRATEGY(),
                  );

    my $writing ;
    $writing = ! ($mode =~ /r/i) ;
    $writing = ($mode =~ /[wa]/i) ;

    $defOpts{Level}    = $1               if $mode =~ /(\d)/;
    $defOpts{Strategy} = Z_FILTERED()     if $mode =~ /f/i;
    $defOpts{Strategy} = Z_HUFFMAN_ONLY() if $mode =~ /h/i;

    my $infDef = $writing ? 'deflate' : 'inflate';
    my @params = () ;

    croak "gzopen: file parameter is not a filehandle or filename"
        unless isaFilehandle $file || isaFilename $file ;

    return undef unless $mode =~ /[rwa]/i ;

    _set_gzerr(0) ;

    if ($writing) {
        $gz = new IO::Compress::Gzip($file, Minimal => 1, AutoClose => 1, 
                                            BinModeOut => 1, %defOpts) 
            or $Compress::Zlib::gzerrno = $IO::Compress::Gzip::GzipError;
    }
    else {
        $gz = new IO::Uncompress::Gunzip($file, 
                                            Transparent => 1,
                                            BinModeIn => 1, Append => 0, 
                                            AutoClose => 1, Strict => 0) 
            or $Compress::Zlib::gzerrno = $IO::Uncompress::Gunzip::GunzipError;
    }

    return undef
        if ! defined $gz ;

    bless [$gz, $infDef], 'Compress::Zlib::gzFile';
}

sub Compress::Zlib::gzFile::gzread
{
    my $self = shift ;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'inflate';

    return 0 if $self->gzeof();

    my $gz = $self->[0] ;
    my $status = $gz->read($_[0], defined $_[1] ? $_[1] : 4096) ; 
    $_[0] = "" if ! defined $_[0] ;
    _save_gzerr($gz, 1);
    return $status ;
}

sub Compress::Zlib::gzFile::gzreadline
{
    my $self = shift ;

    my $gz = $self->[0] ;
    $_[0] = $gz->getline() ; 
    _save_gzerr($gz, 1);
    return defined $_[0] ? length $_[0] : 0 ;
}

sub Compress::Zlib::gzFile::gzwrite
{
    my $self = shift ;
    my $gz = $self->[0] ;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'deflate';

    my $status = $gz->write($_[0]) ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gztell
{
    my $self = shift ;
    my $gz = $self->[0] ;
    my $status = $gz->tell() ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzseek
{
    my $self   = shift ;
    my $offset = shift ;
    my $whence = shift ;

    my $gz = $self->[0] ;
    my $status ;
    eval { $status = $gz->seek($offset, $whence) ; };
    if ($@)
    {
        my $error = $@;
        $error =~ s/^.*: /gzseek: /;
        $error =~ s/ at .* line \d+\s*$//;
        croak $error;
    }
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzflush
{
    my $self = shift ;
    my $f    = shift ;

    my $gz = $self->[0] ;
    my $status = $gz->flush($f) ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzclose
{
    my $self = shift ;
    my $gz = $self->[0] ;

    my $status = $gz->close() ;
    _save_gzerr($gz);
    return ! $status ;
}

sub Compress::Zlib::gzFile::gzeof
{
    my $self = shift ;
    my $gz = $self->[0] ;

    return 0
        if $self->[1] ne 'inflate';

    my $status = $gz->eof() ;
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzsetparams
{
    my $self = shift ;
    croak "Usage: Compress::Zlib::gzFile::gzsetparams(file, level, strategy)"
        unless @_ eq 2 ;

    my $gz = $self->[0] ;
    my $level = shift ;
    my $strategy = shift;

    return _set_gzerr(Z_STREAM_ERROR())
        if $self->[1] ne 'deflate';
 
    my $status = *$gz->{Deflate}->deflateParams(-Level    => $level, 
                                                -Strategy => $strategy);
    _save_gzerr($gz);
    return $status ;
}

sub Compress::Zlib::gzFile::gzerror
{
    my $self = shift ;
    my $gz = $self->[0] ;
    
    return $Compress::Zlib::gzerrno ;
}

sub Compress::Zlib::Deflate::new
{
    my $pkg = shift ;
    my ($got) = ParseParameters(0,
            {
                'AppendOutput'  => [Parse_boolean,  0],
                'CRC32'         => [Parse_boolean,  0],
                'ADLER32'       => [Parse_boolean,  0],
                'Bufsize'       => [Parse_unsigned, 4096],
 
                'Level'         => [Parse_signed,   Z_DEFAULT_COMPRESSION()],
                'Method'        => [Parse_unsigned, Z_DEFLATED()],
                'WindowBits'    => [Parse_signed,   MAX_WBITS()],
                'MemLevel'      => [Parse_unsigned, MAX_MEM_LEVEL()],
                'Strategy'      => [Parse_unsigned, Z_DEFAULT_STRATEGY()],
                'Dictionary'    => [Parse_any,      ""],
            }, @_) ;


    croak "Compress::Zlib::Deflate::new: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my $flags = 0 ;
    $flags |= FLAG_APPEND if $got->value('AppendOutput') ;
    $flags |= FLAG_CRC    if $got->value('CRC32') ;
    $flags |= FLAG_ADLER  if $got->value('ADLER32') ;

    _deflateInit($flags,
                $got->value('Level'), 
                $got->value('Method'), 
                $got->value('WindowBits'), 
                $got->value('MemLevel'), 
                $got->value('Strategy'), 
                $got->value('Bufsize'),
                $got->value('Dictionary')) ;

}

sub Compress::Zlib::Inflate::new
{
    my $pkg = shift ;
    my ($got) = ParseParameters(0,
                    {
                        'AppendOutput'  => [Parse_boolean,  0],
                        'CRC32'         => [Parse_boolean,  0],
                        'ADLER32'       => [Parse_boolean,  0],
                        'ConsumeInput'  => [Parse_boolean,  1],
                        'Bufsize'       => [Parse_unsigned, 4096],
                 
                        'WindowBits'    => [Parse_signed,   MAX_WBITS()],
                        'Dictionary'    => [Parse_any,      ""],
            }, @_) ;


    croak "Compress::Zlib::Inflate::new: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my $flags = 0 ;
    $flags |= FLAG_APPEND if $got->value('AppendOutput') ;
    $flags |= FLAG_CRC    if $got->value('CRC32') ;
    $flags |= FLAG_ADLER  if $got->value('ADLER32') ;
    $flags |= FLAG_CONSUME_INPUT if $got->value('ConsumeInput') ;

    _inflateInit($flags, $got->value('WindowBits'), $got->value('Bufsize'), 
                 $got->value('Dictionary')) ;
}

sub Compress::Zlib::InflateScan::new
{
    my $pkg = shift ;
    my ($got) = ParseParameters(0,
                    {
                        'CRC32'         => [Parse_boolean,  0],
                        'ADLER32'       => [Parse_boolean,  0],
                        'Bufsize'       => [Parse_unsigned, 4096],
                 
                        'WindowBits'    => [Parse_signed,   -MAX_WBITS()],
                        'Dictionary'    => [Parse_any,      ""],
            }, @_) ;


    croak "Compress::Zlib::InflateScan::new: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my $flags = 0 ;
    #$flags |= FLAG_APPEND if $got->value('AppendOutput') ;
    $flags |= FLAG_CRC    if $got->value('CRC32') ;
    $flags |= FLAG_ADLER  if $got->value('ADLER32') ;
    #$flags |= FLAG_CONSUME_INPUT if $got->value('ConsumeInput') ;

    _inflateScanInit($flags, $got->value('WindowBits'), $got->value('Bufsize'), 
                 '') ;
}

sub Compress::Zlib::inflateScanStream::createDeflateStream
{
    my $pkg = shift ;
    my ($got) = ParseParameters(0,
            {
                'AppendOutput'  => [Parse_boolean,  0],
                'CRC32'         => [Parse_boolean,  0],
                'ADLER32'       => [Parse_boolean,  0],
                'Bufsize'       => [Parse_unsigned, 4096],
 
                'Level'         => [Parse_signed,   Z_DEFAULT_COMPRESSION()],
                'Method'        => [Parse_unsigned, Z_DEFLATED()],
                'WindowBits'    => [Parse_signed,   - MAX_WBITS()],
                'MemLevel'      => [Parse_unsigned, MAX_MEM_LEVEL()],
                'Strategy'      => [Parse_unsigned, Z_DEFAULT_STRATEGY()],
            }, @_) ;

    croak "Compress::Zlib::InflateScan::createDeflateStream: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my $flags = 0 ;
    $flags |= FLAG_APPEND if $got->value('AppendOutput') ;
    $flags |= FLAG_CRC    if $got->value('CRC32') ;
    $flags |= FLAG_ADLER  if $got->value('ADLER32') ;

    $pkg->_createDeflateStream($flags,
                $got->value('Level'), 
                $got->value('Method'), 
                $got->value('WindowBits'), 
                $got->value('MemLevel'), 
                $got->value('Strategy'), 
                $got->value('Bufsize'),
                ) ;

}


sub Compress::Zlib::deflateStream::deflateParams
{
    my $self = shift ;
    my ($got) = ParseParameters(0, {
                'Level'      => [Parse_signed,   undef],
                'Strategy'   => [Parse_unsigned, undef],
                'Bufsize'    => [Parse_unsigned, undef],
                }, 
                @_) ;

    croak "Compress::Zlib::deflateParams needs Level and/or Strategy"
        unless $got->parsed('Level') + $got->parsed('Strategy') +
            $got->parsed('Bufsize');

    croak "Compress::Zlib::Inflate::deflateParams: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        if $got->parsed('Bufsize') && $got->value('Bufsize') <= 1;

    my $flags = 0;
    $flags |= 1 if $got->parsed('Level') ;
    $flags |= 2 if $got->parsed('Strategy') ;
    $flags |= 4 if $got->parsed('Bufsize') ;

    $self->_deflateParams($flags, $got->value('Level'), 
                          $got->value('Strategy'), $got->value('Bufsize'));

}

sub compress($;$)
{
    my ($x, $output, $err, $in) =('', '', '', '') ;

    if (ref $_[0] ) {
        $in = $_[0] ;
        croak "not a scalar reference" unless ref $in eq 'SCALAR' ;
    }
    else {
        $in = \$_[0] ;
    }

    my $level = (@_ == 2 ? $_[1] : Z_DEFAULT_COMPRESSION() );

    $x = new Compress::Zlib::Deflate -AppendOutput => 1, -Level => $level
            or return undef ;

    $err = $x->deflate($in, $output) ;
    return undef unless $err == Z_OK() ;

    $err = $x->flush($output) ;
    return undef unless $err == Z_OK() ;
    
    return $output ;

}

sub uncompress($)
{
    my ($x, $output, $err, $in) =('', '', '', '') ;

    if (ref $_[0] ) {
        $in = $_[0] ;
        croak "not a scalar reference" unless ref $in eq 'SCALAR' ;
    }
    else {
        $in = \$_[0] ;
    }

    $x = new Compress::Zlib::Inflate -ConsumeInput => 0 or return undef ;
 
    $err = $x->inflate($in, $output) ;
    return undef unless $err == Z_STREAM_END() ;
 
    return $output ;
}


### This stuff is for backward compat. with Compress::Zlib 1.x

 
sub deflateInit(@)
{
    my ($got) = ParseParameters(0,
                {
                'Bufsize'       => [Parse_unsigned, 4096],
                'Level'         => [Parse_signed,   Z_DEFAULT_COMPRESSION()],
                'Method'        => [Parse_unsigned, Z_DEFLATED()],
                'WindowBits'    => [Parse_signed,   MAX_WBITS()],
                'MemLevel'      => [Parse_unsigned, MAX_MEM_LEVEL()],
                'Strategy'      => [Parse_unsigned, Z_DEFAULT_STRATEGY()],
                'Dictionary'    => [Parse_any,      ""],
                }, @_ ) ;

    croak "Compress::Zlib::deflateInit: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my (%obj) = () ;
 
    my $status = 0 ;
    ($obj{def}, $status) = 
      _deflateInit(0,
                $got->value('Level'), 
                $got->value('Method'), 
                $got->value('WindowBits'), 
                $got->value('MemLevel'), 
                $got->value('Strategy'), 
                $got->value('Bufsize'),
                $got->value('Dictionary')) ;

    my $x = ($status == Z_OK() ? bless \%obj, "Zlib::OldDeflate"  : undef) ;
    return wantarray ? ($x, $status) : $x ;
}
 
sub inflateInit(@)
{
    my ($got) = ParseParameters(0,
                {
                'Bufsize'       => [Parse_unsigned, 4096],
                'WindowBits'    => [Parse_signed,   MAX_WBITS()],
                'Dictionary'    => [Parse_any,      ""],
                }, @_) ;


    croak "Compress::Zlib::inflateInit: Bufsize must be >= 1, you specified " . 
            $got->value('Bufsize')
        unless $got->value('Bufsize') >= 1;

    my $status = 0 ;
    my (%obj) = () ;
    ($obj{def}, $status) = _inflateInit(FLAG_CONSUME_INPUT,
                                $got->value('WindowBits'), 
                                $got->value('Bufsize'), 
                                $got->value('Dictionary')) ;

    my $x = ($status == Z_OK() ? bless \%obj, "Zlib::OldInflate"  : undef) ;

    wantarray ? ($x, $status) : $x ;
}

package Zlib::OldDeflate ;

sub deflate
{
    my $self = shift ;
    my $output ;
    #my (@rest) = @_ ;

    my $status = $self->{def}->deflate($_[0], $output) ;

    wantarray ? ($output, $status) : $output ;
}

sub flush
{
    my $self = shift ;
    my $output ;
    my $flag = shift || Compress::Zlib::Z_FINISH();
    my $status = $self->{def}->flush($output, $flag) ;
    
    wantarray ? ($output, $status) : $output ;
}

sub deflateParams
{
    my $self = shift ;
    $self->{def}->deflateParams(@_) ;
}

sub msg
{
    my $self = shift ;
    $self->{def}->msg() ;
}

sub total_in
{
    my $self = shift ;
    $self->{def}->total_in() ;
}

sub total_out
{
    my $self = shift ;
    $self->{def}->total_out() ;
}

sub dict_adler
{
    my $self = shift ;
    $self->{def}->dict_adler() ;
}

sub get_Level
{
    my $self = shift ;
    $self->{def}->get_Level() ;
}

sub get_Strategy
{
    my $self = shift ;
    $self->{def}->get_Strategy() ;
}

#sub DispStream
#{
#    my $self = shift ;
#    $self->{def}->DispStream($_[0]) ;
#}

package Zlib::OldInflate ;

sub inflate
{
    my $self = shift ;
    my $output ;
    my $status = $self->{def}->inflate($_[0], $output) ;
    wantarray ? ($output, $status) : $output ;
}

sub inflateSync
{
    my $self = shift ;
    $self->{def}->inflateSync($_[0]) ;
}

sub msg
{
    my $self = shift ;
    $self->{def}->msg() ;
}

sub total_in
{
    my $self = shift ;
    $self->{def}->total_in() ;
}

sub total_out
{
    my $self = shift ;
    $self->{def}->total_out() ;
}

sub dict_adler
{
    my $self = shift ;
    $self->{def}->dict_adler() ;
}

#sub DispStream
#{
#    my $self = shift ;
#    $self->{def}->DispStream($_[0]) ;
#}

package Compress::Zlib ;

use Compress::Gzip::Constants;

sub memGzip($)
{
  my $x = new Compress::Zlib::Deflate(
                      -AppendOutput  => 1,
                      -CRC32         => 1,
                      -ADLER32       => 0,
                      -Level         => Z_BEST_COMPRESSION(),
                      -WindowBits    => - MAX_WBITS(),
                     )
      or return undef ;
 
  # write a minimal gzip header
  my $output = GZIP_MINIMUM_HEADER ;
 
  # if the deflation buffer isn't a reference, make it one
  my $string = (ref $_[0] ? $_[0] : \$_[0]) ;

  my $status = $x->deflate($string, \$output) ;
  $status == Z_OK()
      or return undef ;
 
  $status = $x->flush(\$output) ;
  $status == Z_OK()
      or return undef ;
 
  return $output . pack("V V", $x->crc32(), $x->total_in()) ;
 
}


sub _removeGzipHeader($)
{
    my $string = shift ;

    return Z_DATA_ERROR() 
        if length($$string) < GZIP_MIN_HEADER_SIZE ;

    my ($magic1, $magic2, $method, $flags, $time, $xflags, $oscode) = 
        unpack ('CCCCVCC', $$string);

    return Z_DATA_ERROR()
        unless $magic1 == GZIP_ID1 and $magic2 == GZIP_ID2 and
           $method == Z_DEFLATED() and !($flags & GZIP_FLG_RESERVED) ;
    substr($$string, 0, GZIP_MIN_HEADER_SIZE) = '' ;

    # skip extra field
    if ($flags & GZIP_FLG_FEXTRA)
    {
        return Z_DATA_ERROR()
            if length($$string) < GZIP_FEXTRA_HEADER_SIZE ;

        my ($extra_len) = unpack ('v', $$string);
        $extra_len += GZIP_FEXTRA_HEADER_SIZE;
        return Z_DATA_ERROR()
            if length($$string) < $extra_len ;

        substr($$string, 0, $extra_len) = '';
    }

    # skip orig name
    if ($flags & GZIP_FLG_FNAME)
    {
        my $name_end = index ($$string, GZIP_NULL_BYTE);
        return Z_DATA_ERROR()
           if $name_end == -1 ;
        substr($$string, 0, $name_end + 1) =  '';
    }

    # skip comment
    if ($flags & GZIP_FLG_FCOMMENT)
    {
        my $comment_end = index ($$string, GZIP_NULL_BYTE);
        return Z_DATA_ERROR()
            if $comment_end == -1 ;
        substr($$string, 0, $comment_end + 1) = '';
    }

    # skip header crc
    if ($flags & GZIP_FLG_FHCRC)
    {
        return Z_DATA_ERROR()
            if length ($$string) < GZIP_FHCRC_SIZE ;
        substr($$string, 0, GZIP_FHCRC_SIZE) = '';
    }
    
    return Z_OK();
}


sub memGunzip($)
{
    # if the buffer isn't a reference, make it one
    my $string = (ref $_[0] ? $_[0] : \$_[0]);
 
    _removeGzipHeader($string) == Z_OK() 
        or return undef;
     
    my $bufsize = length $$string > 4096 ? length $$string : 4096 ;
    my $x = new Compress::Zlib::Inflate({-WindowBits => - MAX_WBITS(),
                         -Bufsize => $bufsize}) 

              or return undef;

    my $output = "" ;
    my $status = $x->inflate($string, $output);
    return undef 
        unless $status == Z_STREAM_END();

    if (length $$string >= 8)
    {
        my ($crc, $len) = unpack ("VV", substr($$string, 0, 8));
        substr($$string, 0, 8) = '';
        return undef 
            unless $len == length($output) and
                   $crc == crc32($output);
    }
    else
    {
        $$string = '';
    }
    return $output;   
}

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Compress::Zlib - Interface to zlib compression library

=head1 SYNOPSIS

    use Compress::Zlib 2 ;

    ($d, $status) = new Compress::Zlib::Deflate( [OPT] ) ;
    $status = $d->deflate($input, $output) ;
    $status = $d->flush($output [, $flush_type]) ;
    $d->deflateParams(OPTS) ;
    $d->deflateTune(OPTS) ;
    $d->dict_adler() ;
    $d->crc32() ;
    $d->adler32() ;
    $d->total_in() ;
    $d->total_out() ;
    $d->msg() ;
    $d->get_Strategy();
    $d->get_Level();
    $d->get_BufSize();

    ($i, $status) = new Compress::Zlib::Inflate( [OPT] ) ;
    $status = $i->inflate($input, $output) ;
    $status = $i->inflateSync($input) ;
    $i->dict_adler() ;
    $d->crc32() ;
    $d->adler32() ;
    $i->total_in() ;
    $i->total_out() ;
    $i->msg() ;
    $d->get_BufSize();

    $dest = compress($source) ;
    $dest = uncompress($source) ;

    $gz = gzopen($filename or filehandle, $mode) ;
    $bytesread = $gz->gzread($buffer [,$size]) ;
    $bytesread = $gz->gzreadline($line) ;
    $byteswritten = $gz->gzwrite($buffer) ;
    $status = $gz->gzflush($flush) ;
    $offset = $gz->gztell() ;
    $status = $gz->gzseek($offset, $whence) ;
    $status = $gz->gzclose() ;
    $status = $gz->gzeof() ;
    $status = $gz->gzsetparams($level, $strategy) ;
    $errstring = $gz->gzerror() ; 
    $gzerrno

    $dest = Compress::Zlib::memGzip($buffer) ;
    $dest = Compress::Zlib::memGunzip($buffer) ;

    $crc = adler32($buffer [,$crc]) ;
    $crc = crc32($buffer [,$crc]) ;

    $crc = adler32_combine($crc1, $crc2, $len2)l
    $crc = crc32_combine($adler1, $adler2, $len2)

    ZLIB_VERSION
    ZLIB_VERNUM

    # Compress::Zlib 1.x legacy interface

    ($d, $status) = deflateInit( [OPT] ) ;
    ($out, $status) = $d->deflate($buffer) ;
    $status = $d->deflateParams([OPT]) ;
    ($out, $status) = $d->flush() ;
    $d->dict_adler() ;
    $d->total_in() ;
    $d->total_out() ;
    $d->msg() ;

    ($i, $status) = inflateInit( [OPT] ) ;
    ($out, $status) = $i->inflate($buffer) ;
    $status = $i->inflateSync($buffer) ;
    $i->dict_adler() ;
    $i->total_in() ;
    $i->total_out() ;
    $i->msg() ;


=head1 DESCRIPTION

The I<Compress::Zlib> module provides a Perl interface to the I<zlib>
compression library (see L</AUTHOR> for details about where to get
I<zlib>). 
The I<zlib> library allows reading and writing of
compressed data streams that conform to RFC1950, RFC1951 and RFC1952
(aka gzip).
Most of the I<zlib> functionality is available in I<Compress::Zlib>. 

Unless you are working with legacy code, or you need to work directly
with the low-level zlib interface, it is recommended that applications
use one of the newer C<IO::*> interfaces provided with this module.

The C<Compress::Zlib> module can be split into two general areas of
functionality, namely a low-level in-memory compression/decompression
interface and a simple read/write interface to I<gzip> files.

Each of these areas will be discussed separately below.


=head1 GZIP INTERFACE

A number of functions are supplied in I<zlib> for reading and writing
I<gzip> files that conform to RFC1952. This module provides an interface
to most of them. 

If you are upgrading from C<Compress::Zlib> 1.x, the following enhancements
have been made to the C<gzopen> interface:

=over 5

=item 1

If you want to to open either STDIN or STDOUT with C<gzopen>, you can
optionally use the special filename "C<->" as a synonym for C<\*STDIN> and
C<\*STDOUT>.

=item 2 

In C<Compress::Zlib> version 1.x, C<gzopen> used the zlib library to open the
underlying file. This made things especially tricky when a Perl filehandle was
passed to C<gzopen>. Behind the scenes the numeric C file descriptor had to be
extracted from the Perl filehandle and this passed to the zlib library.

Apart from being non-portable to some operating systems, this made it difficult
to use C<gzopen> in situations where you wanted to extract/create a gzip data
stream that is embedded in a larger file, without having to resort to opening
and closing the file multiple times. 

In C<Compress::Zlib> version 2.x, the C<gzopen> interface has been completely
rewritten to use the L<IO::Compress::Gzip|IO::Compress::Gzip> for writing gzip files and
L<IO::Uncompress::Gunzip|IO::Uncompress::Gunzip> for reading gzip files.

=item 3

Addition of C<gzseek> to provide a restricted C<seek> interface.

=item 4.

Added C<gztell>.

=back

A more complete and flexible interface for reading/writing gzip files/buffers
is included with this module.  See L<IO::Compress::Gzip|IO::Compress::Gzip> and
L<IO::Uncompress::Gunzip|IO::Uncompress::Gunzip> for more details.

=over 5

=item B<$gz = gzopen($filename, $mode)>

=item B<$gz = gzopen($filehandle, $mode)>

This function opens either the I<gzip> file C<$filename> for reading or writing
or attaches to the opened filehandle, C<$filehandle>. It returns an object on
success and C<undef> on failure.

When writing a gzip file this interface will always create the smallest
possible gzip header (exactly 10 bytes). If you want control over the
information stored in the gzip header (like the original filename or a comment)
use L<IO::Compress::Gzip|IO::Compress::Gzip> instead.

The second parameter, C<$mode>, is used to specify whether the file is
opened for reading or writing and to optionally specify a compression
level and compression strategy when writing. The format of the C<$mode>
parameter is similar to the mode parameter to the 'C' function C<fopen>,
so "rb" is used to open for reading and "wb" for writing.

To specify a compression level when writing, append a digit between 0
and 9 to the mode string -- 0 means no compression and 9 means maximum
compression.
If no compression level is specified Z_DEFAULT_COMPRESSION is used.

To specify the compression strategy when writing, append 'f' for filtered
data, 'h' for Huffman only compression, or 'R' for run-length encoding.
If no strategy is specified Z_DEFAULT_STRATEGY is used.

So, for example, "wb9" means open for writing with the maximum compression
using the default strategy and "wb4R" means open for writing with compression
level 4 and run-length encoding.

Refer to the I<zlib> documentation for the exact format of the C<$mode>
parameter.


=item B<$bytesread = $gz-E<gt>gzread($buffer [, $size]) ;>

Reads C<$size> bytes from the compressed file into C<$buffer>. If
C<$size> is not specified, it will default to 4096. If the scalar
C<$buffer> is not large enough, it will be extended automatically.

Returns the number of bytes actually read. On EOF it returns 0 and in
the case of an error, -1.

=item B<$bytesread = $gz-E<gt>gzreadline($line) ;>

Reads the next line from the compressed file into C<$line>. 

Returns the number of bytes actually read. On EOF it returns 0 and in
the case of an error, -1.

It is legal to intermix calls to C<gzread> and C<gzreadline>.

In addition, C<gzreadline> fully supports the use of of the variable C<$/>
(C<$INPUT_RECORD_SEPARATOR> or C<$RS> when C<English> is in use) to
determine what constitutes an end of line. Both paragraph mode and file
slurp mode are supported. 


=item B<$byteswritten = $gz-E<gt>gzwrite($buffer) ;>

Writes the contents of C<$buffer> to the compressed file. Returns the
number of bytes actually written, or 0 on error.

=item B<$status = $gz-E<gt>gzflush($flush_type) ;>

Flushes all pending output into the compressed file.

This method takes an optional parameter, C<$flush_type>, that controls
how the flushing will be carried out. By default the C<$flush_type>
used is C<Z_FINISH>. Other valid values for C<$flush_type> are
C<Z_NO_FLUSH>, C<Z_SYNC_FLUSH>, C<Z_FULL_FLUSH> and C<Z_BLOCK>. It is
strongly recommended that you only set the C<flush_type> parameter if
you fully understand the implications of what it does - overuse of C<flush>
can seriously degrade the level of compression achieved. See the C<zlib>
documentation for details.

Returns 1 on success, 0 on failure.


=item B<$offset = $gz-E<gt>gztell() ;>

Returns the uncompressed file offset.

=item B<$status = $gz-E<gt>gzseek($offset, $whence) ;>

Sets the file position of the 

Provides a sub-set of the C<seek> functionality, with the restriction
that it is only legal to seek forward in the compressed file.
It is a fatal error to attempt to seek backward.

When opened for writing, empty parts of the file will have NULL (0x00)
bytes written to them.

The C<$whence> parameter should be one of SEEK_SET, SEEK_CUR or SEEK_END.

Returns 1 on success, 0 on failure.

=item B<$gz-E<gt>gzclose>

Closes the compressed file. Any pending data is flushed to the file
before it is closed.

Returns 1 on success, 0 on failure.

=item B<$gz-E<gt>gzsetparams($level, $strategy>

Change settings for the deflate stream C<$gz>.

The list of the valid options is shown below. Options not specified
will remain unchanged.

Note: This method is only available if you are running zlib 1.0.6 or better.

=over 5

=item B<$level>

Defines the compression level. Valid values are 0 through 9,
C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>, C<Z_BEST_COMPRESSION>, and
C<Z_DEFAULT_COMPRESSION>.

=item B<$strategy>

Defines the strategy used to tune the compression. The valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED> and C<Z_HUFFMAN_ONLY>. 

=back

=item B<$gz-E<gt>gzerror>

Returns the I<zlib> error message or number for the last operation
associated with C<$gz>. The return value will be the I<zlib> error
number when used in a numeric context and the I<zlib> error message
when used in a string context. The I<zlib> error number constants,
shown below, are available for use.

    Z_OK
    Z_STREAM_END
    Z_ERRNO
    Z_STREAM_ERROR
    Z_DATA_ERROR
    Z_MEM_ERROR
    Z_BUF_ERROR

=item B<$gzerrno>

The C<$gzerrno> scalar holds the error code associated with the most
recent I<gzip> routine. Note that unlike C<gzerror()>, the error is
I<not> associated with a particular file.

As with C<gzerror()> it returns an error number in numeric context and
an error message in string context. Unlike C<gzerror()> though, the
error message will correspond to the I<zlib> message when the error is
associated with I<zlib> itself, or the UNIX error message when it is
not (i.e. I<zlib> returned C<Z_ERRORNO>).

As there is an overlap between the error numbers used by I<zlib> and
UNIX, C<$gzerrno> should only be used to check for the presence of
I<an> error in numeric context. Use C<gzerror()> to check for specific
I<zlib> errors. The I<gzcat> example below shows how the variable can
be used safely.

=back


=head2 Examples

Here is an example script which uses the interface. It implements a
I<gzcat> function.

    use strict ;
    use warnings ;
    
    use Compress::Zlib ;
    
    # use stdin if no files supplied
    @ARGV = '-' unless @ARGV ;
    
    foreach my $file (@ARGV) {
        my $buffer ;
    
        my $gz = gzopen($file, "rb") 
             or die "Cannot open $file: $gzerrno\n" ;
    
        print $buffer while $gz->gzread($buffer) > 0 ;
    
        die "Error reading from $file: $gzerrno" . ($gzerrno+0) . "\n" 
            if $gzerrno != Z_STREAM_END ;
        
        $gz->gzclose() ;
    }

Below is a script which makes use of C<gzreadline>. It implements a
very simple I<grep> like script.

    use strict ;
    use warnings ;
    
    use Compress::Zlib ;
    
    die "Usage: gzgrep pattern [file...]\n"
        unless @ARGV >= 1;
    
    my $pattern = shift ;
    
    # use stdin if no files supplied
    @ARGV = '-' unless @ARGV ;
    
    foreach my $file (@ARGV) {
        my $gz = gzopen($file, "rb") 
             or die "Cannot open $file: $gzerrno\n" ;
    
        while ($gz->gzreadline($_) > 0) {
            print if /$pattern/ ;
        }
    
        die "Error reading from $file: $gzerrno\n" 
            if $gzerrno != Z_STREAM_END ;
        
        $gz->gzclose() ;
    }

This script, I<gzstream>, does the opposite of the I<gzcat> script
above. It reads from standard input and writes a gzip data stream to
standard output.

    use strict ;
    use warnings ;
    
    use Compress::Zlib ;
    
    binmode STDOUT;  # gzopen only sets it on the fd
    
    my $gz = gzopen(\*STDOUT, "wb")
          or die "Cannot open stdout: $gzerrno\n" ;
    
    while (<>) {
        $gz->gzwrite($_) 
          or die "error writing: $gzerrno\n" ;
    }

    $gz->gzclose ;

=head2 Compress::Zlib::memGzip

This function is used to create an in-memory gzip file with the minimum
possible gzip header (exactly 10 bytes).

    $dest = Compress::Zlib::memGzip($buffer) ;

If successful, it returns the in-memory gzip file, otherwise it returns
undef.

The C<$buffer> parameter can either be a scalar or a scalar reference.

See L<IO::Compress::Gzip|IO::Compress::Gzip> for an alternative way to carry out in-memory gzip
compression.

=head2 Compress::Zlib::memGunzip

This function is used to uncompress an in-memory gzip file.

    $dest = Compress::Zlib::memGunzip($buffer) ;

If successful, it returns the uncompressed gzip file, otherwise it
returns undef.

The C<$buffer> parameter can either be a scalar or a scalar reference. The
contents of the C<$buffer> parameter are destroyed after calling this function.

See L<IO::Uncompress::Gunzip|IO::Uncompress::Gunzip> for an alternative way to carry out in-memory gzip
uncompression.

=head1 COMPRESS/UNCOMPRESS

Two functions are provided to perform in-memory compression/uncompression of
RFC 1950 data streams. They are called C<compress> and C<uncompress>.

=over 5

=item B<$dest = compress($source [, $level] ) ;>

Compresses C<$source>. If successful it returns the compressed
data. Otherwise it returns I<undef>.

The source buffer, C<$source>, can either be a scalar or a scalar
reference.

The C<$level> parameter defines the compression level. Valid values are
0 through 9, C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>,
C<Z_BEST_COMPRESSION>, and C<Z_DEFAULT_COMPRESSION>.
If C<$level> is not specified C<Z_DEFAULT_COMPRESSION> will be used.


=item B<$dest = uncompress($source) ;>

Uncompresses C<$source>. If successful it returns the uncompressed
data. Otherwise it returns I<undef>.

The source buffer can either be a scalar or a scalar reference.

=back

Please note: the two functions defined above are I<not> compatible with
the Unix commands of the same name.

See L<IO::Compress::Deflate|IO::Compress::Deflate> and L<IO::Uncompress::Inflate|IO::Uncompress::Inflate> included with
this distribution for an alternative interface for reading/writing RFC 1950
files/buffers.

=head1 CHECKSUM FUNCTIONS

Two functions are provided by I<zlib> to calculate checksums. For the
Perl interface, the order of the two parameters in both functions has
been reversed. This allows both running checksums and one off
calculations to be done.

    $crc = adler32($buffer [,$crc]) ;
    $crc = crc32($buffer [,$crc]) ;

The buffer parameters can either be a scalar or a scalar reference.

If the $crc parameters is C<undef>, the crc value will be reset.

If you have built this module with zlib 1.2.3 or better, two more
CRC-related functions are available.

    $crc = adler32_combine($crc1, $crc2, $len2)l
    $crc = crc32_combine($adler1, $adler2, $len2)

These functions allow checksums to be merged.

=head1 Compress::Zlib::Deflate

This section defines an interface that allows in-memory compression using
the I<deflate> interface provided by zlib.

Note: The interface defined in this section is different from version
1.x of this module. The original deflate interface is still available
for backward compatibility and is documented in the section
L<Compress::Zlib 1.x Deflate Interface>.

Here is a definition of the interface available:


=head2 B<($d, $status) = new Compress::Zlib::Deflate( [OPT] ) >

Initialises a deflation object. 

If you are familiar with the I<zlib> library, it combines the
features of the I<zlib> functions C<deflateInit>, C<deflateInit2>
and C<deflateSetDictionary>.

If successful, it will return the initialised deflation object, C<$d>
and a C<$status> of C<Z_OK> in a list context. In scalar context it
returns the deflation object, C<$d>, only.

If not successful, the returned deflation object, C<$d>, will be
I<undef> and C<$status> will hold the a I<zlib> error code.

The function optionally takes a number of named options specified as
C<-Name =E<gt> value> pairs. This allows individual options to be
tailored without having to specify them all in the parameter list.

For backward compatibility, it is also possible to pass the parameters
as a reference to a hash containing the name=>value pairs.

Below is a list of the valid options:

=over 5

=item B<-Level>

Defines the compression level. Valid values are 0 through 9,
C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>, C<Z_BEST_COMPRESSION>, and
C<Z_DEFAULT_COMPRESSION>.

The default is C<-Level =E<gt> Z_DEFAULT_COMPRESSION>.

=item B<-Method>

Defines the compression method. The only valid value at present (and
the default) is C<-Method =E<gt> Z_DEFLATED>.

=item B<-WindowBits>

For a definition of the meaning and valid values for C<WindowBits>
refer to the I<zlib> documentation for I<deflateInit2>.

Defaults to C<-WindowBits =E<gt> MAX_WBITS>.

=item B<-MemLevel>

For a definition of the meaning and valid values for C<MemLevel>
refer to the I<zlib> documentation for I<deflateInit2>.

Defaults to C<-MemLevel =E<gt> MAX_MEM_LEVEL>.

=item B<-Strategy>

Defines the strategy used to tune the compression. The valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED>, C<Z_RLE>, C<Z_FIXED> and
C<Z_HUFFMAN_ONLY>.

The default is C<-Strategy =E<gt>Z_DEFAULT_STRATEGY>.

=item B<-Dictionary>

When a dictionary is specified I<Compress::Zlib> will automatically
call C<deflateSetDictionary> directly after calling C<deflateInit>. The
Adler32 value for the dictionary can be obtained by calling the method 
C<$d-E<gt>dict_adler()>.

The default is no dictionary.

=item B<-Bufsize>

Sets the initial size for the output buffer used by the C<$d-E<gt>deflate>
and C<$d-E<gt>flush> methods. If the buffer has to be
reallocated to increase the size, it will grow in increments of
C<Bufsize>.

The default buffer size is 4096.

=item B<-AppendOutput>

This option controls how data is written to the output buffer by the
C<$d-E<gt>deflate> and C<$d-E<gt>flush> methods.

If the C<AppendOutput> option is set to false, the output buffers in the
C<$d-E<gt>deflate> and C<$d-E<gt>flush>  methods will be truncated before
uncompressed data is written to them.

If the option is set to true, uncompressed data will be appended to the
output buffer in the C<$d-E<gt>deflate> and C<$d-E<gt>flush> methods.

This option defaults to false.

=item B<-CRC32>

If set to true, a crc32 checksum of the uncompressed data will be
calculated. Use the C<$d-E<gt>crc32> method to retrieve this value.

This option defaults to false.


=item B<-ADLER32>

If set to true, an adler32 checksum of the uncompressed data will be
calculated. Use the C<$d-E<gt>adler32> method to retrieve this value.

This option defaults to false.


=back

Here is an example of using the C<Compress::Zlib::Deflate> optional
parameter list to override the default buffer size and compression
level. All other options will take their default values.

    my $d = new Compress::Zlib::Deflate ( -Bufsize => 300, 
                                          -Level   => Z_BEST_SPEED ) ;


=head2 B<$status = $d-E<gt>deflate($input, $output)>

Deflates the contents of C<$input> and writes the compressed data to
C<$output>.

The C<$input> and C<$output> parameters can be either scalars or scalar
references.

When finished, C<$input> will be completely processed (assuming there
were no errors). If the deflation was successful it writes the deflated
data to C<$output> and returns a status value of C<Z_OK>.

On error, it returns a I<zlib> error code.

If the C<AppendOutput> option is set to true in the constructor for
the C<$d> object, the compressed data will be appended to C<$output>. If
it is false, C<$output> will be truncated before any compressed data is
written to it.

B<Note>: This method will not necessarily write compressed data to
C<$output> every time it is called. So do not assume that there has been
an error if the contents of C<$output> is empty on returning from
this method. As long as the return code from the method is C<Z_OK>,
the deflate has succeeded.

=head2 B<$status = $d-E<gt>flush($output [, $flush_type]) >

Typically used to finish the deflation. Any pending output will be
written to C<$output>.

Returns C<Z_OK> if successful.

Note that flushing can seriously degrade the compression ratio, so it
should only be used to terminate a decompression (using C<Z_FINISH>) or
when you want to create a I<full flush point> (using C<Z_FULL_FLUSH>).

By default the C<flush_type> used is C<Z_FINISH>. Other valid values
for C<flush_type> are C<Z_NO_FLUSH>, C<Z_PARTIAL_FLUSH>, C<Z_SYNC_FLUSH>
and C<Z_FULL_FLUSH>. It is strongly recommended that you only set the
C<flush_type> parameter if you fully understand the implications of
what it does. See the C<zlib> documentation for details.

If the C<AppendOutput> option is set to true in the constructor for
the C<$d> object, the compressed data will be appended to C<$output>. If
it is false, C<$output> will be truncated before any compressed data is
written to it.

=head2 B<$status = $d-E<gt>deflateParams([OPT])>

Change settings for the deflate object C<$d>.

The list of the valid options is shown below. Options not specified
will remain unchanged.


=over 5

=item B<-Level>

Defines the compression level. Valid values are 0 through 9,
C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>, C<Z_BEST_COMPRESSION>, and
C<Z_DEFAULT_COMPRESSION>.

=item B<-Strategy>

Defines the strategy used to tune the compression. The valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED> and C<Z_HUFFMAN_ONLY>. 

=item B<-BufSize>

Sets the initial size for the output buffer used by the C<$d-E<gt>deflate>
and C<$d-E<gt>flush> methods. If the buffer has to be
reallocated to increase the size, it will grow in increments of
C<Bufsize>.


=back

=head2 B<$status = $d-E<gt>deflateTune($good_length, $max_lazy, $nice_length, $max_chain)>

Tune the internal settings for the deflate object C<$d>. This option is
only available if you are running zlib 1.2.2.3 or better.

Refer to the documentation in zlib.h for instructions on how to fly
C<deflateTune>.

=head2 B<$d-E<gt>dict_adler()>

Returns the adler32 value for the dictionary.

=head2 B<$d-E<gt>crc32()>

Returns the crc32 value for the uncompressed data to date. 

If the C<CRC32> option is not enabled in the constructor for this object,
this method will always return 0;

=head2 B<$d-E<gt>adler32()>

Returns the adler32 value for the uncompressed data to date. 

=head2 B<$d-E<gt>msg()>

Returns the last error message generated by zlib.

=head2 B<$d-E<gt>total_in()>

Returns the total number of bytes uncompressed bytes input to deflate.

=head2 B<$d-E<gt>total_out()>

Returns the total number of compressed bytes output from deflate.

=head2 B<$d-E<gt>get_Strategy()>

Returns the deflation strategy currently used. Valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED> and C<Z_HUFFMAN_ONLY>. 


=head2 B<$d-E<gt>get_Level()>

Returns the compression level being used. 

=head2 B<$d-E<gt>get_BufSize()>

Returns the buffer size used to carry out the compression.

=head2 Example


Here is a trivial example of using C<deflate>. It simply reads standard
input, deflates it and writes it to standard output.

    use strict ;
    use warnings ;

    use Compress::Zlib 2 ;

    binmode STDIN;
    binmode STDOUT;
    my $x = new Compress::Zlib::Deflate
       or die "Cannot create a deflation stream\n" ;

    my ($output, $status) ;
    while (<>)
    {
        $status = $x->deflate($_, $output) ;
    
        $status == Z_OK
            or die "deflation failed\n" ;
    
        print $output ;
    }
    
    $status = $x->flush($output) ;
    
    $status == Z_OK
        or die "deflation failed\n" ;
    
    print $output ;

=head1 Compress::Zlib::Inflate

This section defines an interface that allows in-memory uncompression using
the I<inflate> interface provided by zlib.

Note: The interface defined in this section is different from version
1.x of this module. The original inflate interface is still available
for backward compatibility and is documented in the section
L<Compress::Zlib 1.x Inflate Interface>.

Here is a definition of the interface:


=head2 B< ($i, $status) = new Compress::Zlib::Inflate( [OPT] ) >

Initialises an inflation object. 

In a list context it returns the inflation object, C<$i>, and the
I<zlib> status code (C<$status>). In a scalar context it returns the
inflation object only.

If successful, C<$i> will hold the inflation object and C<$status> will
be C<Z_OK>.

If not successful, C<$i> will be I<undef> and C<$status> will hold the
I<zlib> error code.

The function optionally takes a number of named options specified as
C<-Name =E<gt> value> pairs. This allows individual options to be
tailored without having to specify them all in the parameter list.

For backward compatibility, it is also possible to pass the parameters
as a reference to a hash containing the name=E<gt>value pairs.

Here is a list of the valid options:

=over 5

=item B<-WindowBits>

For a definition of the meaning and valid values for C<WindowBits>
refer to the I<zlib> documentation for I<inflateInit2>.

Defaults to C<-WindowBits =E<gt>MAX_WBITS>.

=item B<-Bufsize>

Sets the initial size for the output buffer used by the C<$i-E<gt>inflate>
method. If the output buffer in this method has to be reallocated to
increase the size, it will grow in increments of C<Bufsize>.

Default is 4096.

=item B<-Dictionary>

The default is no dictionary.

=item B<-AppendOutput>

This option controls how data is written to the output buffer by the
C<$i-E<gt>inflate> method.

If the option is set to false, the output buffer in the C<$i-E<gt>inflate>
method will be truncated before uncompressed data is written to it.

If the option is set to true, uncompressed data will be appended to the
output buffer by the C<$i-E<gt>inflate> method.

This option defaults to false.


=item B<-CRC32>

If set to true, a crc32 checksum of the uncompressed data will be
calculated. Use the C<$i-E<gt>crc32> method to retrieve this value.

This option defaults to false.

=item B<-ADLER32>

If set to true, an adler32 checksum of the uncompressed data will be
calculated. Use the C<$i-E<gt>adler32> method to retrieve this value.

This option defaults to false.

=item B<-ConsumeInput>

If set to true, this option will remove compressed data from the input
buffer of the the C< $i-E<gt>inflate > method as the inflate progresses.

This option can be useful when you are processing compressed data that is
embedded in another file/buffer. In this case the data that immediately
follows the compressed stream will be left in the input buffer.

This option defaults to true.

=back

Here is an example of using an optional parameter to override the default
buffer size.

    my ($i, $status) = new Compress::Zlib::Inflate( -Bufsize => 300 ) ;

=head2 B< $status = $i-E<gt>inflate($input, $output) >

Inflates the complete contents of C<$input> and writes the uncompressed
data to C<$output>. The C<$input> and C<$output> parameters can either be
scalars or scalar references.

Returns C<Z_OK> if successful and C<Z_STREAM_END> if the end of the
compressed data has been successfully reached. 

If not successful C<$status> will hold the I<zlib> error code.

If the C<ConsumeInput> option has been set to true when the
C<Compress::Zlib::Inflate> object is created, the C<$input> parameter
is modified by C<inflate>. On completion it will contain what remains
of the input buffer after inflation. In practice, this means that when
the return status is C<Z_OK> the C<$input> parameter will contain an
empty string, and when the return status is C<Z_STREAM_END> the C<$input>
parameter will contains what (if anything) was stored in the input buffer
after the deflated data stream.

This feature is useful when processing a file format that encapsulates
a compressed data stream (e.g. gzip, zip) and there is useful data
immediately after the deflation stream.

If the C<AppendOutput> option is set to true in the constructor for
this object, the uncompressed data will be appended to C<$output>. If
it is false, C<$output> will be truncated before any uncompressed data
is written to it.

=head2 B<$status = $i-E<gt>inflateSync($input)>

This method can be used to attempt to recover good data from a compressed
data stream that is partially corrupt.
It scans C<$input> until it reaches either a I<full flush point> or the
end of the buffer.

If a I<full flush point> is found, C<Z_OK> is returned and C<$input>
will be have all data up to the flush point removed. This data can then be
passed to the C<$i-E<gt>inflate> method to be uncompressed.

Any other return code means that a flush point was not found. If more
data is available, C<inflateSync> can be called repeatedly with more
compressed data until the flush point is found.

Note I<full flush points> are not present by default in compressed
data streams. They must have been added explicitly when the data stream
was created by calling C<Compress::Deflate::flush>  with C<Z_FULL_FLUSH>.


=head2 B<$i-E<gt>dict_adler()>

Returns the adler32 value for the dictionary.

=head2 B<$i-E<gt>crc32()>

Returns the crc32 value for the uncompressed data to date.

If the C<CRC32> option is not enabled in the constructor for this object,
this method will always return 0;

=head2 B<$i-E<gt>adler32()>

Returns the adler32 value for the uncompressed data to date.

If the C<ADLER32> option is not enabled in the constructor for this object,
this method will always return 0;

=head2 B<$i-E<gt>msg()>

Returns the last error message generated by zlib.

=head2 B<$i-E<gt>total_in()>

Returns the total number of bytes compressed bytes input to inflate.

=head2 B<$i-E<gt>total_out()>

Returns the total number of uncompressed bytes output from inflate.

=head2 B<$d-E<gt>get_BufSize()>

Returns the buffer size used to carry out the decompression.

=head2 Example

Here is an example of using C<inflate>.

    use strict ;
    use warnings ;
    
    use Compress::Zlib 2 ;
    
    my $x = new Compress::Zlib::Inflate()
       or die "Cannot create a inflation stream\n" ;
    
    my $input = '' ;
    binmode STDIN;
    binmode STDOUT;
    
    my ($output, $status) ;
    while (read(STDIN, $input, 4096))
    {
        $status = $x->inflate(\$input, $output) ;
    
        print $output 
            if $status == Z_OK or $status == Z_STREAM_END ;
    
        last if $status != Z_OK ;
    }
    
    die "inflation failed\n"
        unless $status == Z_STREAM_END ;

=head1 Compress::Zlib 1.x Deflate Interface

This section defines the interface available in C<Compress::Zlib> version
1.x that allows in-memory compression using the I<deflate> interface
provided by zlib.

Here is a definition of the interface available:


=head2 B<($d, $status) = deflateInit( [OPT] )>

Initialises a deflation stream. 

It combines the features of the I<zlib> functions C<deflateInit>,
C<deflateInit2> and C<deflateSetDictionary>.

If successful, it will return the initialised deflation stream, C<$d>
and C<$status> of C<Z_OK> in a list context. In scalar context it
returns the deflation stream, C<$d>, only.

If not successful, the returned deflation stream (C<$d>) will be
I<undef> and C<$status> will hold the exact I<zlib> error code.

The function optionally takes a number of named options specified as
C<-Name=E<gt>value> pairs. This allows individual options to be
tailored without having to specify them all in the parameter list.

For backward compatibility, it is also possible to pass the parameters
as a reference to a hash containing the name=>value pairs.

The function takes one optional parameter, a reference to a hash.  The
contents of the hash allow the deflation interface to be tailored.

Here is a list of the valid options:

=over 5

=item B<-Level>

Defines the compression level. Valid values are 0 through 9,
C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>, C<Z_BEST_COMPRESSION>, and
C<Z_DEFAULT_COMPRESSION>.

The default is C<-Level =E<gt>Z_DEFAULT_COMPRESSION>.

=item B<-Method>

Defines the compression method. The only valid value at present (and
the default) is C<-Method =E<gt>Z_DEFLATED>.

=item B<-WindowBits>

For a definition of the meaning and valid values for C<WindowBits>
refer to the I<zlib> documentation for I<deflateInit2>.

Defaults to C<-WindowBits =E<gt>MAX_WBITS>.

=item B<-MemLevel>

For a definition of the meaning and valid values for C<MemLevel>
refer to the I<zlib> documentation for I<deflateInit2>.

Defaults to C<-MemLevel =E<gt>MAX_MEM_LEVEL>.

=item B<-Strategy>

Defines the strategy used to tune the compression. The valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED> and C<Z_HUFFMAN_ONLY>. 

The default is C<-Strategy =E<gt>Z_DEFAULT_STRATEGY>.

=item B<-Dictionary>

When a dictionary is specified I<Compress::Zlib> will automatically
call C<deflateSetDictionary> directly after calling C<deflateInit>. The
Adler32 value for the dictionary can be obtained by calling the method 
C<$d->dict_adler()>.

The default is no dictionary.

=item B<-Bufsize>

Sets the initial size for the deflation buffer. If the buffer has to be
reallocated to increase the size, it will grow in increments of
C<Bufsize>.

The default is 4096.

=back

Here is an example of using the C<deflateInit> optional parameter list
to override the default buffer size and compression level. All other
options will take their default values.

    deflateInit( -Bufsize => 300, 
                 -Level => Z_BEST_SPEED  ) ;


=head2 B<($out, $status) = $d-E<gt>deflate($buffer)>


Deflates the contents of C<$buffer>. The buffer can either be a scalar
or a scalar reference.  When finished, C<$buffer> will be
completely processed (assuming there were no errors). If the deflation
was successful it returns the deflated output, C<$out>, and a status
value, C<$status>, of C<Z_OK>.

On error, C<$out> will be I<undef> and C<$status> will contain the
I<zlib> error code.

In a scalar context C<deflate> will return C<$out> only.

As with the I<deflate> function in I<zlib>, it is not necessarily the
case that any output will be produced by this method. So don't rely on
the fact that C<$out> is empty for an error test.


=head2 B<($out, $status) = $d-E<gt>flush([flush_type])>

Typically used to finish the deflation. Any pending output will be
returned via C<$out>.
C<$status> will have a value C<Z_OK> if successful.

In a scalar context C<flush> will return C<$out> only.

Note that flushing can seriously degrade the compression ratio, so it
should only be used to terminate a decompression (using C<Z_FINISH>) or
when you want to create a I<full flush point> (using C<Z_FULL_FLUSH>).

By default the C<flush_type> used is C<Z_FINISH>. Other valid values
for C<flush_type> are C<Z_NO_FLUSH>, C<Z_PARTIAL_FLUSH>, C<Z_SYNC_FLUSH>
and C<Z_FULL_FLUSH>. It is strongly recommended that you only set the
C<flush_type> parameter if you fully understand the implications of
what it does. See the C<zlib> documentation for details.

=head2 B<$status = $d-E<gt>deflateParams([OPT])>

Change settings for the deflate stream C<$d>.

The list of the valid options is shown below. Options not specified
will remain unchanged.

=over 5

=item B<-Level>

Defines the compression level. Valid values are 0 through 9,
C<Z_NO_COMPRESSION>, C<Z_BEST_SPEED>, C<Z_BEST_COMPRESSION>, and
C<Z_DEFAULT_COMPRESSION>.

=item B<-Strategy>

Defines the strategy used to tune the compression. The valid values are
C<Z_DEFAULT_STRATEGY>, C<Z_FILTERED> and C<Z_HUFFMAN_ONLY>. 

=back

=head2 B<$d-E<gt>dict_adler()>

Returns the adler32 value for the dictionary.

=head2 B<$d-E<gt>msg()>

Returns the last error message generated by zlib.

=head2 B<$d-E<gt>total_in()>

Returns the total number of bytes uncompressed bytes input to deflate.

=head2 B<$d-E<gt>total_out()>

Returns the total number of compressed bytes output from deflate.

=head2 Example


Here is a trivial example of using C<deflate>. It simply reads standard
input, deflates it and writes it to standard output.

    use strict ;
    use warnings ;

    use Compress::Zlib ;

    binmode STDIN;
    binmode STDOUT;
    my $x = deflateInit()
       or die "Cannot create a deflation stream\n" ;

    my ($output, $status) ;
    while (<>)
    {
        ($output, $status) = $x->deflate($_) ;
    
        $status == Z_OK
            or die "deflation failed\n" ;
    
        print $output ;
    }
    
    ($output, $status) = $x->flush() ;
    
    $status == Z_OK
        or die "deflation failed\n" ;
    
    print $output ;

=head1 Compress::Zlib 1.x Inflate Interface

This section defines the interface available in C<Compress::Zlib> version
1.x that allows in-memory uncompression using the I<deflate> interface
provided by zlib.

Here is a definition of the interface:


=head2 B<($i, $status) = inflateInit()>

Initialises an inflation stream. 

In a list context it returns the inflation stream, C<$i>, and the
I<zlib> status code (C<$status>). In a scalar context it returns the
inflation stream only.

If successful, C<$i> will hold the inflation stream and C<$status> will
be C<Z_OK>.

If not successful, C<$i> will be I<undef> and C<$status> will hold the
I<zlib> error code.

The function optionally takes a number of named options specified as
C<-Name=E<gt>value> pairs. This allows individual options to be
tailored without having to specify them all in the parameter list.
 
For backward compatibility, it is also possible to pass the parameters
as a reference to a hash containing the name=>value pairs.
 
The function takes one optional parameter, a reference to a hash.  The
contents of the hash allow the deflation interface to be tailored.
 
Here is a list of the valid options:

=over 5

=item B<-WindowBits>

For a definition of the meaning and valid values for C<WindowBits>
refer to the I<zlib> documentation for I<inflateInit2>.

Defaults to C<-WindowBits =E<gt>MAX_WBITS>.

=item B<-Bufsize>

Sets the initial size for the inflation buffer. If the buffer has to be
reallocated to increase the size, it will grow in increments of
C<Bufsize>. 

Default is 4096.

=item B<-Dictionary>

The default is no dictionary.

=back

Here is an example of using the C<inflateInit> optional parameter to
override the default buffer size.

    inflateInit( -Bufsize => 300 ) ;

=head2 B<($out, $status) = $i-E<gt>inflate($buffer)>

Inflates the complete contents of C<$buffer>. The buffer can either be
a scalar or a scalar reference.

Returns C<Z_OK> if successful and C<Z_STREAM_END> if the end of the
compressed data has been successfully reached. 
If not successful, C<$out> will be I<undef> and C<$status> will hold
the I<zlib> error code.

The C<$buffer> parameter is modified by C<inflate>. On completion it
will contain what remains of the input buffer after inflation. This
means that C<$buffer> will be an empty string when the return status is
C<Z_OK>. When the return status is C<Z_STREAM_END> the C<$buffer>
parameter will contains what (if anything) was stored in the input
buffer after the deflated data stream.

This feature is useful when processing a file format that encapsulates
a  compressed data stream (e.g. gzip, zip).

=head2 B<$status = $i-E<gt>inflateSync($buffer)>

Scans C<$buffer> until it reaches either a I<full flush point> or the
end of the buffer.

If a I<full flush point> is found, C<Z_OK> is returned and C<$buffer>
will be have all data up to the flush point removed. This can then be
passed to the C<deflate> method.

Any other return code means that a flush point was not found. If more
data is available, C<inflateSync> can be called repeatedly with more
compressed data until the flush point is found.


=head2 B<$i-E<gt>dict_adler()>

Returns the adler32 value for the dictionary.

=head2 B<$i-E<gt>msg()>

Returns the last error message generated by zlib.

=head2 B<$i-E<gt>total_in()>

Returns the total number of bytes compressed bytes input to inflate.

=head2 B<$i-E<gt>total_out()>

Returns the total number of uncompressed bytes output from inflate.

=head2 Example

Here is an example of using C<inflate>.

    use strict ;
    use warnings ;
    
    use Compress::Zlib ;
    
    my $x = inflateInit()
       or die "Cannot create a inflation stream\n" ;
    
    my $input = '' ;
    binmode STDIN;
    binmode STDOUT;
    
    my ($output, $status) ;
    while (read(STDIN, $input, 4096))
    {
        ($output, $status) = $x->inflate(\$input) ;
    
        print $output 
            if $status == Z_OK or $status == Z_STREAM_END ;
    
        last if $status != Z_OK ;
    }
    
    die "inflation failed\n"
        unless $status == Z_STREAM_END ;

=head1 ACCESSING ZIP FILES

Although it is possible (with some effort on your part) to use this
module to access .zip files, there is a module on CPAN that will do all
the hard work for you. Check out the C<Archive::Zip> module on CPAN at

    http://www.cpan.org/modules/by-module/Archive/Archive-Zip-*.tar.gz    


=head1 CONSTANTS

All the I<zlib> constants are automatically imported when you make use
of I<Compress::Zlib>.


=head1 SEE ALSO

L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>, L<IO::Compress::Deflate>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Uncompress::AnyInflate>

L<Compress::Zlib::FAQ|Compress::Zlib::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Tar|Archive::Zip>,
L<IO::Zlib|IO::Zlib>

For RFC 1950, 1951 and 1952 see 
F<http://www.faqs.org/rfcs/rfc1950.html>,
F<http://www.faqs.org/rfcs/rfc1951.html> and
F<http://www.faqs.org/rfcs/rfc1952.html>

The primary site for the gzip program is F<http://www.gzip.org>.

=head1 AUTHOR

The I<Compress::Zlib> module was written by Paul Marquess,
F<pmqs@cpan.org>. The latest copy of the module can be
found on CPAN in F<modules/by-module/Compress/Compress-Zlib-x.x.tar.gz>.

The I<zlib> compression library was written by Jean-loup Gailly
F<gzip@prep.ai.mit.edu> and Mark Adler F<madler@alumni.caltech.edu>.

The primary site for the I<zlib> compression library is
F<http://www.zlib.org>.

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE
 

Copyright (c) 1995-2005 Paul Marquess. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.





