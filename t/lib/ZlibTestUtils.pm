package ZlibTestUtils;

package main ;

use strict ;
use warnings;

use Carp ;


sub title
{
    #diag "" ; 
    ok 1, $_[0] ;
    #diag "" ;
}

sub like_eval
{
    like $@, @_ ;
}

{
    package LexFile ;

    our ($index);
    $index = '00000';
    
    sub new
    {
        my $self = shift ;
        foreach (@_)
        {
            # autogenerate the name unless if none supplied
            $_ = "tst" . $index ++ . ".tmp"
                unless defined $_;
        }
        chmod 0777, @_;
        unlink @_ ;
        bless [ @_ ], $self ;
    }

    sub DESTROY
    {
        my $self = shift ;
        chmod 0777, @{ $self } ;
        unlink @{ $self } ;
    }

}

{
    package LexDir ;

    use File::Path;
    sub new
    {
        my $self = shift ;
        foreach (@_) { rmtree $_ }
        bless [ @_ ], $self ;
    }

    sub DESTROY
    {
        my $self = shift ;
        foreach (@$self) { rmtree $_ }
    }
}
sub readFile
{
    my $f = shift ;

    my @strings ;

    if (Compress::Zlib::Common::isaFilehandle($f))
    {
        my $pos = tell($f);
        seek($f, 0,0);
        @strings = <$f> ;	
        seek($f, 0, $pos);
    }
    else
    {
        open (F, "<$f") 
            or die "Cannot open $f: $!\n" ;
        @strings = <F> ;	
        close F ;
    }

    return @strings if wantarray ;
    return join "", @strings ;
}

sub touch
{
    foreach (@_) { writeFile($_, '') }
}

sub writeFile
{
    my($filename, @strings) = @_ ;
    open (F, ">$filename") 
        or die "Cannot open $filename: $!\n" ;
    binmode F;
    foreach (@strings) {
        no warnings ;
        print F $_ ;
    }
    close F ;
}

sub GZreadFile
{
    my ($filename) = shift ;

    my ($uncomp) = "" ;
    my $line = "" ;
    my $fil = gzopen($filename, "rb") 
        or die "Cannopt open '$filename': $Compress::Zlib::gzerrno" ;

    $uncomp .= $line 
        while $fil->gzread($line) > 0;

    $fil->gzclose ;
    return $uncomp ;
}

sub hexDump
{
    my $d = shift ;

    if (Compress::Zlib::Common::isaFilehandle($d))
    {
        $d = readFile($d);
    }
    elsif (Compress::Zlib::Common::isaFilename($d))
    {
        $d = readFile($d);
    }
    else
    {
        $d = $$d ;
    }

    my $offset = 0 ;

    $d = '' unless defined $d ;
    #while (read(STDIN, $data, 16)) {
    while (my $data = substr($d, 0, 16)) {
        substr($d, 0, 16) = '' ;
        printf "# %8.8lx    ", $offset;
        $offset += 16;

        my @array = unpack('C*', $data);
        foreach (@array) {
            printf('%2.2x ', $_);
        }
        print "   " x (16 - @array)
            if @array < 16 ;
        $data =~ tr/\0-\37\177-\377/./;
        print "  $data\n";
    }

}

sub readHeaderInfo
{
    my $name = shift ;
    my %opts = @_ ;

    my $string = <<EOM;
some text
EOM

    ok my $x = new IO::Compress::Gzip $name, %opts 
        or diag "GzipError is $IO::Compress::Gzip::GzipError" ;
    ok $x->write($string) ;
    ok $x->close ;

    ok GZreadFile($name) eq $string ;

    ok my $gunz = new IO::Uncompress::Gunzip $name, Strict => 0
        or diag "GunzipError is $IO::Uncompress::Gunzip::GunzipError" ;
    ok my $hdr = $gunz->getHeaderInfo();
    my $uncomp ;
    ok $gunz->read($uncomp) ;
    ok $uncomp eq $string;
    ok $gunz->close ;

    return $hdr ;
}

sub cmpFile
{
    my ($filename, $uue) = @_ ;
    return readFile($filename) eq unpack("u", $uue) ;
}

sub uncompressBuffer
{
    my $compWith = shift ;
    my $buffer = shift ;

    my %mapping = ( 'IO::Compress::Gzip'                    => 'IO::Uncompress::Gunzip',
                    'IO::Compress::Gzip::gzip'               => 'IO::Uncompress::Gunzip',
                    'IO::Compress::Deflate'                  => 'IO::Uncompress::Inflate',
                    'IO::Compress::Deflate::deflate'         => 'IO::Uncompress::Inflate',
                    'IO::Compress::RawDeflate'               => 'IO::Uncompress::RawInflate',
                    'IO::Compress::RawDeflate::rawdeflate'   => 'IO::Uncompress::RawInflate',
                );

    my $out ;
    my $obj = $mapping{$compWith}->new( \$buffer, -Append => 1);
    1 while $obj->read($out) > 0 ;
    return $out ;

}

my %ErrorMap = (    'IO::Compress::Gzip'        => \$IO::Compress::Gzip::GzipError,
                    'IO::Compress::Gzip::gzip'  => \$IO::Compress::Gzip::GzipError,
                    'IO::Uncompress::Gunzip'  => \$IO::Uncompress::Gunzip::GunzipError,
                    'IO::Uncompress::Gunzip::gunzip'  => \$IO::Uncompress::Gunzip::GunzipError,
                    'IO::Uncompress::Inflate'  => \$IO::Uncompress::Inflate::InflateError,
                    'IO::Uncompress::Inflate::inflate'  => \$IO::Uncompress::Inflate::InflateError,
                    'IO::Compress::Deflate'  => \$IO::Compress::Deflate::DeflateError,
                    'IO::Compress::Deflate::deflate'  => \$IO::Compress::Deflate::DeflateError,
                    'IO::Uncompress::RawInflate'  => \$IO::Uncompress::RawInflate::RawInflateError,
                    'IO::Uncompress::RawInflate::rawinflate'  => \$IO::Uncompress::RawInflate::RawInflateError,
                    'IO::Uncompress::AnyInflate'  => \$IO::Uncompress::AnyInflate::AnyInflateError,
                    'IO::Uncompress::AnyInflate::anyinflate'  => \$IO::Uncompress::AnyInflate::AnyInflateError,
                    'IO::Compress::RawDeflate'  => \$IO::Compress::RawDeflate::RawDeflateError,
                    'IO::Compress::RawDeflate::rawdeflate'  => \$IO::Compress::RawDeflate::RawDeflateError,
               );

my %TopFuncMap = (  'IO::Compress::Gzip'        => 'IO::Compress::Gzip::gzip',
                    'IO::Uncompress::Gunzip'      => 'IO::Uncompress::Gunzip::gunzip',
                    'IO::Compress::Deflate'     => 'IO::Compress::Deflate::deflate',
                    'IO::Uncompress::Inflate'     => 'IO::Uncompress::Inflate::inflate',
                    'IO::Compress::RawDeflate'  => 'IO::Compress::RawDeflate::rawdeflate',
                    'IO::Uncompress::RawInflate'  => 'IO::Uncompress::RawInflate::rawinflate',
                    'IO::Uncompress::AnyInflate'  => 'IO::Uncompress::AnyInflate::anyinflate',
                 );

   %TopFuncMap = map { ($_              => $TopFuncMap{$_}, 
                        $TopFuncMap{$_} => $TopFuncMap{$_}) } 
                 keys %TopFuncMap ;

 #%TopFuncMap = map { ($_              => \&{ $TopFuncMap{$_} ) } 
                 #keys %TopFuncMap ;


my %inverse  = ( 'IO::Compress::Gzip'                    => 'IO::Uncompress::Gunzip',
                 'IO::Compress::Gzip::gzip'              => 'IO::Uncompress::Gunzip::gunzip',
                 'IO::Compress::Deflate'                 => 'IO::Uncompress::Inflate',
                 'IO::Compress::Deflate::deflate'        => 'IO::Uncompress::Inflate::inflate',
                 'IO::Compress::RawDeflate'              => 'IO::Uncompress::RawInflate',
                 'IO::Compress::RawDeflate::rawdeflate'  => 'IO::Uncompress::RawInflate::rawinflate',
             );

%inverse  = map { ($_ => $inverse{$_}, $inverse{$_} => $_) } keys %inverse;

sub getInverse
{
    my $class = shift ;

    return $inverse{$class} ;
}

sub getErrorRef
{
    my $class = shift ;

    return $ErrorMap{$class} ;
}

sub getTopFuncRef
{
    my $class = shift ;

    return \&{ $TopFuncMap{$class} } ;
}

sub getTopFuncName
{
    my $class = shift ;

    return $TopFuncMap{$class}  ;
}

sub compressBuffer
{
    my $compWith = shift ;
    my $buffer = shift ;

    my %mapping = ( 'IO::Uncompress::Gunzip'                  => 'IO::Compress::Gzip',
                    'IO::Uncompress::Gunzip::gunzip'          => 'IO::Compress::Gzip',
                    'IO::Uncompress::Inflate'                 => 'IO::Compress::Deflate',
                    'IO::Uncompress::Inflate::inflate'        => 'IO::Compress::Deflate',
                    'IO::Uncompress::RawInflate'              => 'IO::Compress::RawDeflate',
                    'IO::Uncompress::RawInflate::rawinflate'  => 'IO::Compress::RawDeflate',
                    'IO::Uncompress::AnyInflate'              => 'IO::Compress::Gzip',
                    'IO::Uncompress::AnyInflate::anyinflate'  => 'IO::Compress::Gzip',
                );

    my $out ;
    my $obj = $mapping{$compWith}->new( \$out);
    $obj->write($buffer) ;
    $obj->close();
    return $out ;

}

use IO::Uncompress::AnyInflate qw($AnyInflateError);
sub anyUncompress
{
    my $buffer = shift ;
    my $already = shift;

    my @opts = ();
    if (ref $buffer && ref $buffer eq 'ARRAY')
    {
        @opts = @$buffer;
        $buffer = shift @opts;
    }

    if (ref $buffer)
    {
        croak "buffer is undef" unless defined $$buffer;
        croak "buffer is empty" unless length $$buffer;

    }


    my $data ;
    if (Compress::Zlib::Common::isaFilehandle($buffer))
    {
        $data = readFile($buffer);
    }
    elsif (Compress::Zlib::Common::isaFilename($buffer))
    {
        $data = readFile($buffer);
    }
    else
    {
        $data = $$buffer ;
    }

    if (defined $already && length $already)
    {

        my $got = substr($data, 0, length($already));
        substr($data, 0, length($already)) = '';

        is $got, $already, '  Already OK' ;
    }

    my $out = '';
    my $o = new IO::Uncompress::AnyInflate \$data, -Append => 1, Transparent => 0, @opts
        or croak "Cannot open buffer/file: $AnyInflateError" ;

    1 while $o->read($out) > 0 ;

    croak "Error uncompressing -- " . $o->error()
        if $o->error() ;

    return $out ;

}

sub mkErr
{
    my $string = shift ;
    my ($dummy, $file, $line) = caller ;
    -- $line ;

    $file = quotemeta($file);

    return "/$string\\s+at $file line $line/" ;
}

sub mkEvalErr
{
    my $string = shift ;

    return "/$string\\s+at \\(eval /" ;
}

sub dumpObj
{
    my $obj = shift ;

    my ($dummy, $file, $line) = caller ;

    if (@_)
    {
        print "#\n# dumpOBJ from $file line $line @_\n" ;
    }
    else
    {
        print "#\n# dumpOBJ from $file line $line \n" ;
    }

    my $max = 0 ;;
    foreach my $k (keys %{ *$obj })
    {
        $max = length $k if length $k > $max ;
    }

    foreach my $k (sort keys %{ *$obj })
    {
        my $v = $obj->{$k} ;
        $v = '-undef-' unless defined $v;
        my $pad = ' ' x ($max - length($k) + 2) ;
        print "# $k$pad: [$v]\n";
    }
    print "#\n" ;
}


package ZlibTestUtils;

1;
