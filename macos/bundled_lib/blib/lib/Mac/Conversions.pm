#!/usr/local/bin/perl

package Mac::Conversions;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(binhex debinhex macbinary demacbinary hex2macb macb2hex is_macbinary);

$VERSION = "1.04";
sub Version { $VERSION; }

use strict;
use Convert::BinHex;
use POSIX;
use Fcntl;
use File::Basename;
use Carp;
use FileHandle;

sub new {
    my $class = shift;
    my %arg = @_;
    my %self = ();
    
    $self{Debug} = exists $arg{Debug} ? $arg{Debug} : 0;
    $self{Remove} = exists $arg{Remove} ? $arg{Remove} : 0;
    bless \%self, $class;
}

sub binhex {
#
# Native Mac to BinHex, using Convert::BinHex
#
    use Mac::Files;
    my $bhex;
    my ($lname, $ldir, $has, $size, $rsize, $finfo, $outname, $flags, $i);
    
    my $self = shift;
    my $file = shift || croak("No filename given $!");

    my $hqx = Convert::BinHex->new;
    ($lname,$ldir) = fileparse($file);
    $hqx->filename($lname);
    $outname = uniqify($ldir,$lname,"hqx");

    $has = FSpGetCatInfo($file);
    $finfo = $has->ioFlFndrInfo;
    $size = $has->ioFlLgLen;
    $rsize = $has->ioFlRLgLen;
    $hqx->type($finfo->fdType);
    $hqx->creator($finfo->fdCreator);
    $flags = $finfo->fdFlags;
    $flags &= 0xfeff; #turn off inited bit
    $hqx->flags($flags);
    $hqx->data(Path => $file);
    $hqx->resource(Path => $file, Fork => "RSRC");
    $hqx->data->length($size);
    $hqx->resource->length($rsize);
    if($self->{Debug}) {
        print "About to Binhex $file\n";
        print "Resource size $rsize, data size $size\n";
    }
    $bhex = FileHandle->new;
    $bhex->open($outname,"w") or croak("Unable to open $outname");
    $hqx->encode($bhex);
    $bhex->close;
}

sub debinhex {
#
# BinHex to native Mac
#
    
    use Mac::Files;
    my $bhex;
    my ($data, $testlength, $length,$lname,$ldir,$fd,$i);
    
    my $self = shift;
    my $file = shift || croak("No filename given $!");
    $bhex = FileHandle->new;
    $bhex->open($file,"r") || croak("Unable to open $file: $!");
    my $hqx = Convert::BinHex->open(FH => $bhex);
    $hqx->read_header;
    print $hqx->header_as_string if $self->{Debug};
    my $outname = $hqx->filename;
    ($lname,$ldir) = fileparse($file);

    $outname = uniqify($ldir,$outname);

    FSpCreate($outname, $hqx->creator, $hqx->type)
       or croak("Unable to create Mac file $outname");
    my $reslength = $hqx->resource_length;
    my $datalength = $hqx->data_length;
    $fd = POSIX::open($outname,&POSIX::O_WRONLY|&POSIX::O_CREAT,0755);
    $testlength = 0;
    while(defined($data = $hqx->read_data)) {
        $length = length($data);
        POSIX::write($fd,$data,$length)
          or croak("Couldn't write $length bytes: $!");
        $testlength += $length;
    }
    POSIX::close($fd) or croak "Unable to close $outname";
    croak("Data fork length mismatch, expected $datalength, wrote $testlength")
        if $datalength != $testlength;
    if($reslength) {
        $fd = POSIX::open($outname,
              &Fcntl::O_RSRC | &POSIX::O_WRONLY | &POSIX::O_CREAT,0755);
        $testlength = 0;
        while(defined($data = $hqx->read_resource)) {
            $length = length($data);
            POSIX::write($fd,$data,$length)
                  or croak "Couldn't write $length bytes: $!";
            $testlength += $length;
        }
        POSIX::close($fd) or croak "Unable to close $outname";
        croak("Resource fork length mismatch, expected $reslength, wrote $testlength")
            if $testlength != $reslength;
    }
    my $has = FSpGetCatInfo($outname);
    my $finfo = $has->ioFlFndrInfo;
    $finfo->fdFlags($hqx->flags & 0xfeff); #turn off inited bit
    $finfo->fdType($hqx->type || "????");
    $finfo->fdCreator($hqx->creator || "????");
    if($self->{Debug}) {
        printf "Finder flags: %x\n",$finfo->fdFlags;
        print "File type: ",$finfo->fdType,"\n";
        print "File creator: ",$finfo->fdCreator,"\n";
    }
    $has->ioFlFndrInfo($finfo);
    FSpSetCatInfo($outname,$has)
        or croak "Unable to set catalog info $^E";
    if($self->{Debug}) {
        $has = FSpGetCatInfo ($outname);
        printf "Finder flags for decoded file: %x\n",$has->ioFlFndrInfo->fdFlags;
        print "File type for decoded file: ",$has->ioFlFndrInfo->fdType,"\n";
        print "File creator for decoded file: ",$has->ioFlFndrInfo->fdCreator,"\n";
    }
    $bhex->close;
    if($self->{Remove}) {
        unlink($file) or warn("Unable to remove $file");
    }
}

sub macbinary {
#
# Native Mac to MacBinary II
#
    use Mac::Files;

    my ($macb,$in);
    my ($lname, $ldir, $has, $size, $rsize, $finfo, $outname, $flags,$buf, $n, $i);
    my $total;
    my $self = shift;
    my $file = shift || die "No filename given $!";

    ($lname,$ldir) = fileparse($file);
    $outname = uniqify ($ldir,$lname,"bin");

    $has = FSpGetCatInfo($file);
    $finfo = $has->ioFlFndrInfo;
    $size = $has->ioFlLgLen;
    $rsize = $has->ioFlRLgLen;
    $flags = $finfo->fdFlags;
    if($self->{Debug}) {
        print "About to MacBinary $file\n";
        print "Resource size $rsize, data size $size\n";
    }
    $macb = FileHandle->new;
    $macb->open($outname,"w") or croak("Unable to open $outname");
    my $len = length($lname);
    $buf = pack("xCa63a4a4CxNnCxNNNNnCx14NnCC",
                $len,
                $lname,
                $finfo->fdType,
                $finfo->fdCreator,
                ($finfo->fdFlags & 0xff00) >> 8,
                $finfo->fdLocation,
                0, # $finfo->fdFldr,
                0,
                $size,
                $rsize,
                $has->ioFlCrDat,
                $has->ioFlMdDat,
                0,
                $finfo->fdFlags & 0x00ff,
                0,
                0,
                129,
                129);
    syswrite $macb, $buf, 124;
    my $crc = 0;
    $crc = Convert::BinHex::macbinary_crc($buf,$crc);
    $crc &= 0xffff;
    $crc <<= 16;
    syswrite $macb, pack("N",$crc), 4;
    if($size) {
        $total = 0;
        print "Data Fork\n\n" if $self->{Debug};
        $in = FileHandle->new;
        $in->open($file,"r") or die "Unable to open $file $!";
        while($n = read $in,$buf,2048) {
            if ($n < 2048) {  #assuming here that a file read from the file
                              #system will always return the number of bytes
                              #asked for.  Probably true for local files, but
                              #maybe not for networked disks.
                $n = syswrite $macb, $buf, length($buf);
                $total += $n;
                $n %= 128;
                if($n) {
                    $n = 128 - $n;
                    $buf = pack("x$n");
                    $n = syswrite $macb, $buf, $n;
                    print "Writing $n nulls in last block, $total bytes already written\n"
                                if $self->{Debug};
                }
            } else {
                $n = syswrite $macb, $buf, 2048;
                $total += $n;
            }
        }
        $in->close;
        unless ($size == $total) {
            croak("Size mismatch in data fork: $total, $size");
        }
    }
    if($rsize) {
        $total = 0;
        print "Resource Fork\n\n" if $self->{Debug};
        my $fd = POSIX::open($file,&POSIX::O_RDONLY | &Fcntl::O_RSRC);
        while (($n = POSIX::read($fd, $buf, 2048)) > 0) {
            last unless defined $n;
            if ($n < 2048) {
                $n = syswrite $macb, $buf, length($buf);
                $total += $n;
                $n %= 128;
                if($n) {
                    $n = 128 - $n;
                    $buf = pack("x$n");
                    $n = syswrite $macb, $buf, $n;
                }
            } else {
                $n = syswrite $macb, $buf, 2048;
                $total += $n;
            }
        }
      POSIX::close($fd);
        unless ($rsize == $total) {
            croak("Size mismatch in resource fork: $total, $rsize");
        }
    }
   $macb->close;

}

sub demacbinary {
#
#  Take a MacBinary file and convert it to a native Mac file.
#
    use Mac::Files;
    
    my ($macb,$data);
    my ($buf,$n,$i,$ldir,$lname);
    
    my $self = shift;   
    my $file = shift or croak("No filename given $!");
    $macb = FileHandle->new;
    $macb->open($file,"r") || croak("Unable to open $file: $!");
    $n = read($macb,$buf,128);
	croak("Headerless MacBinary file, that shouldn't be!") unless $n == 128;
    my($namelength,
       $filename,
       $type,
       $creator,
       $highflag,
       $dum1,
       $dum2,
       $dum3,
       $datalength,
       $reslength,
       $dum4,
       $dum5,
       $dum6,
       $lowflag,
       $dum7,
       $dum8,
       $dum9,
       $dum10,
       $crc) = unpack("xCa63a4a4CxNnCxNNNNnCx14NnCCN",$buf);
    $filename = substr $filename, 0, $namelength;
    $crc >>= 16;  #the CRC itself is in the first two bytes
    if($self->{Debug}) {
        print "Filename = $filename\nType = $type\nCreator = $creator\n";
        print "Data Fork Length = $datalength\nResource Fork Length = $reslength\n";
        printf("CRC = %x\n",$crc);
    }
    my $testcrc = Convert::BinHex::macbinary_crc(substr($buf,0,124));
    $testcrc &= 0xffff;
    printf "Warning: checksum mismatch, %x, %x\n", $crc, $testcrc
        unless $crc == $testcrc;
    ($lname,$ldir) = fileparse($file);

    my $outname = uniqify($ldir,$filename);

    $data = FileHandle->new;
    $data->open($outname,"w") or croak("Unable to open the data fork of $outname");
    my $counter = 0;
    my $tdatalength = $datalength;
#
#  Since both the data and resouce forks are null padded to 128 byte boundaries,
#  I need to be careful to read a multiple of 128 from the MacBinary file, but
#  write only what is actually necessary to the native Mac file
#
    if($datalength) {
#
#  This complexity is here only for speed.  The file could actually be read
#  128 bytes at a time by the while loop alone.  block_read is used because
#  of the padding of the MacBinary file.  I don't want to get off a block
#  boundary, even though most of the time read() should just work.  There's
#  no guarantee that you get what you ask for with read, though.
#
        my $datacount = int($datalength/2048);
        for($i = 0;$i < $datacount;$i++) {
            $n = block_read($macb,\$buf,2048);
            syswrite($data,$buf,$n);  #There should also be a safe_write
            $counter += $n;
            $tdatalength -= $n;
        }
        while ($tdatalength) {
	    $n = block_read($macb,\$buf,128);
	    $n = ($tdatalength > 128) ? 128 : $tdatalength;
	    syswrite($data,$buf,$n);
	    $tdatalength -= $n;
	    $counter += $n;
	}
    }
    $data->close;
    croak("Data length written $counter != MacBinary data length $datalength")
        unless $counter == $datalength;
#
# Now do the resource fork
#
    my $resfork = POSIX::open($outname,
        &POSIX::O_WRONLY|&Fcntl::O_RSRC |&POSIX::O_CREAT)
        or croak("Unable to open the resource fork of $outname");
    $counter = 0;
#
#  There's no need to worry about the null padding of the resource fork
#  because the resource fork is the last thing in the MacBinary file.
#  Simply read as many bytes as I need.
#
    my $treslength = $reslength;
    if($reslength) {
        my $rescount = int($reslength/2048);
        for($i = 0;$i < $rescount;$i++) {
            $n = read($macb,$buf,2048);
            POSIX::write($resfork,$buf,$n);
            $counter += $n;
            $treslength -= $n;
        }
        read($macb,$buf,$treslength);
        POSIX::write($resfork,$buf,$treslength);
        $counter += $treslength;
    }
    POSIX::close($resfork) or croak("Unable to close $outname");
    croak("Resource length written $counter != MacBinary resource length $reslength")
        unless $counter == $reslength;
    my $has = FSpGetCatInfo($outname);
    my $finfo = $has->ioFlFndrInfo;
    my $flag = (($highflag & 0xffff) << 8) + $lowflag;
    $finfo->fdFlags($flag & 0xfeff); #turn off inited bit
    $finfo->fdType($type || "????");
    $finfo->fdCreator($creator || "????");
    $has->ioFlFndrInfo($finfo);
    FSpSetCatInfo($outname,$has)
        or croak "Unable to set catalog info $^E";
    $macb->close;
    if($self->{Remove}) {
        unlink($file) or warn("Unable to remove $file");
    }
}

sub hex2macb {
#
# BinHex to MacBinary
#
    my ($bhex,$macb);
    my ($data, $testlength, $length,$lname,$ldir,$fd,$buf,$i);

    my $self = shift;
    my $file = shift || croak("No filename given $!");

    $bhex = FileHandle->new;
    $bhex->open($file,"r") || croak("Unable to open $file: $!");

    my $hqx = Convert::BinHex->open(FH => $bhex);

    $hqx->read_header;
    my $outname = $hqx->filename;
    ($lname,$ldir) = fileparse($file);
    $outname = uniqify($ldir,$outname,"bin");

    my $reslength = $hqx->resource_length;
    my $datalength = $hqx->data_length;

    $macb = FileHandle->new;
    $macb->open($outname,"w")  or croak("Unable to open $outname");
    $buf = pack("xCa63a4a4CxNnCxNNNNnCx14NnCC",
                length($hqx->filename),
                $hqx->filename,
                $hqx->type,
                $hqx->creator,
                ($hqx->flags & 0xfe00) >> 8,
                0,
                0,
                0,
                $datalength,
                $reslength,
                0,
                0,
                0,
                $hqx->flags & 0x00ff,
                0,
                0,
                129,
                129);
    syswrite $macb, $buf, 124;
    my $crc = 0;
    $crc = Convert::BinHex::macbinary_crc($buf,$crc);
    $crc &= 0xffff;
    printf("MacBinary CRC: %x\n",$crc) if $self->{Debug};
    $crc <<= 16;
    syswrite $macb, pack("N",$crc), 4;

    $testlength = 0;
    while(defined($data = $hqx->read_data)) {
        $length = length($data);
        syswrite($macb,$data,$length)
          or croak("Couldn't write $length bytes: $!");
        $testlength += $length;
    }
    croak("Data fork length mismatch, expected $datalength, wrote $testlength")
        if $datalength != $testlength;
    my $excess = $testlength % 128;
    if($excess) {
        $excess = 128 - $excess;
        $buf = pack("x$excess");
        $length = syswrite $macb, $buf, $excess;
    }

    $testlength = 0;
    if($reslength) {
        while(defined($data = $hqx->read_resource)) {
            $length = length($data);
            syswrite($macb,$data,$length)
                  or croak "Couldn't write $length bytes: $!";
            $testlength += $length;
        }
        croak("Resource fork length mismatch, expected $reslength, wrote $testlength")
            if $testlength != $reslength;
    }
    $excess = $testlength % 128;
    if($excess) {
        $excess = 128 - $excess;
        $buf = pack("x$excess");
        $length = syswrite $macb, $buf, $excess;
    }

    $macb->close;
    $bhex->close;

    if($self->{Remove}) {
        unlink($file) or warn("Unable to remove $file");
    }
}

sub macb2hex {
#
#  Take a MacBinary file and convert it to BinHex using Convert::BinHex.
#
    my ($bhex,$macb,$tdata,$tres);
    my ($buf,$n,$i,$ldir,$lname);

    my $self = shift;
    my $file = shift or croak("No filename given $!");

    $macb = FileHandle->new;
    $macb->open($file,"r") || croak("Unable to open $file: $!");
    $n = read($macb,$buf,128);
	croak("Headerless MacBinary file, that shouldn't be!") unless $n == 128;
    my($namelength,
       $filename,
       $type,
       $creator,
       $highflag,
       $dum1,
       $dum2,
       $dum3,
       $datalength,
       $reslength,
       $dum4,
       $dum5,
       $dum6,
       $lowflag,
       $dum7,
       $dum8,
       $dum9,
       $dum10,
       $crc) = unpack("xCa63a4a4CxNnCxNNNNnCx14NnCCN",$buf);
    $filename = substr $filename, 0, $namelength;
       
    $crc >>= 16;  #the CRC itself is in the first two bytes
    if($self->{Debug}) {
        print "Filename = $filename\nType = $type\nCreator = $creator\n";
        print "Data Fork Length = $datalength\nResource Fork Length = $reslength\n";
        printf("CRC = %x\n",$crc);
    }
    my $testcrc = Convert::BinHex::macbinary_crc(substr($buf,0,124));
    $testcrc &= 0xffff;
    printf "Warning: checksum mismatch, %x, %x\n",$crc, $testcrc
        unless $crc == $testcrc;
    my $hqx = Convert::BinHex->new;
    ($lname,$ldir) = fileparse($file);
    my $outname = uniqify($ldir,$filename,"hqx");

#
#  Simplest way to do this with the tools available is to first create
#  two temporary files, one with the data fork, one with the resource fork
#
    my $tdataname = uniqify($ldir,$filename,"datat");
    $tdata = FileHandle->new;
    $tdata->open($tdataname,"w") or croak("Unable to open $tdataname");
    my $counter = 0;
    my $tdatalength = $datalength;
#
#  Since both the data and resouce forks are null padded to 128 byte boundaries,
#  I need to be careful to read a multiple of 128 from the MacBinary file, but
#  write only what is actually necessary to the temporary.
#
    if($datalength) {
#
#  This complexity is here only for speed.  The file could actually be read
#  128 bytes at a time by the while loop alone.  block_read is used because
#  of the padding of the MacBinary file.  I don't want to get off a block
#  boundary.
#
        my $datacount = int($datalength/2048);
        for($i = 0;$i < $datacount;$i++) {
            $n = block_read($macb,\$buf,2048);
            syswrite($tdata,$buf,$n);  #There should also be a safe_write
            $counter += $n;
            $tdatalength -= $n;
        }
        while ($tdatalength) {
	    $n = block_read($macb,\$buf,128);
	    $n = ($tdatalength > 128) ? 128 : $tdatalength;
	    syswrite($tdata,$buf,$n);
	    $tdatalength -= $n;
	    $counter += $n;
	}
    }
    $tdata->close;
    croak("Data length written $counter != MacBinary data length $datalength")
        unless $counter == $datalength;
    my $tresname = uniqify($ldir,$filename,"rsrct");
    $tres = FileHandle->new;
    $tres->open($tresname,"w");
    $counter = 0;
#
#  There's no need to worry about the null padding of the resource fork
#  because the resource fork is the last thing in the MacBinary file.
#  Simply read as many bytes as I need.
#
    my $treslength = $reslength;
    if($reslength) {
        my $rescount = int($reslength/2048);
        for($i = 0;$i < $rescount;$i++) {
            $n = read($macb,$buf,2048);
            syswrite($tres,$buf,$n);
            $counter += $n;
            $treslength -= $n;
        }
        read($macb,$buf,$treslength);
        syswrite($tres,$buf,$treslength);
        $counter += $treslength;
    }
    $tres->close;
    croak("Resource length written $counter != MacBinary resource length $reslength")
        unless $counter == $reslength;

    $hqx->filename($filename);
    $hqx->creator($creator);
    $hqx->type($type);
    my $flag = (($highflag & 0xffff) << 8) + $lowflag;
    $hqx->flags($flag);
    $hqx->data->length($datalength);
    $hqx->resource->length($reslength);
    $hqx->resource(Path => $tresname);
    $hqx->data(Path => $tdataname);
    $bhex = FileHandle->new;
    $bhex->open($outname,"w");
    $hqx->encode($bhex);

    unlink($tresname);
    unlink($tdataname);
    $bhex->close;
    $macb->close;

    if($self->{Remove}) {
        unlink($file) or warn("Unable to remove $file");
    }
}

sub is_macbinary {
#
#  Use a crude heuristic to decide whether or not a file is MacBinary.  The
#  first byte of any MacBinary file must be zero.  The second has to be
#  <= 63 according to the MacBinary II standard.  The 122nd and 123rd 
#  each have to be >= 129.  This has about a 1/8000 chance of failing on
#  random bytes.  This seems to be all that mcvert does.  Unfortunately
#  we can't also check the checksum because the standard software (Stuffit
#  Deluxe, etc.) doesn't seem to checksum.
#  
#
    my $buf;
    my $self = shift;
    my $file = shift;
    my $macb = FileHandle->new;
    $macb->open($file,"r") || croak("Unable to open $file: $!");
    my $bytes = read($macb,$buf,128);
    $macb->close;
    if ($self->{Debug}  && $bytes < 128) {
	print "is_macbinary only read $bytes header bytes\n";
    }
    return 0 unless $bytes == 128;
    my($zero,
       $namelength,
       $filename,
       $type,
       $creator,
       $highflag,
       $dum1,
       $dum2,
       $dum3,
       $datalength,
       $reslength,
       $dum4,
       $dum5,
       $dum6,
       $lowflag,
       $dum7,
       $dum8,
       $version_this,
       $version_needed,
       $crc) = unpack("CCA63a4a4CxNnCxNNNNnCx14NnCCN",$buf);
    if ($self->{Debug}) {
	print "is_macbinary check bytes: $zero, $namelength, $version_this, $version_needed\n";
    }
    if (!$zero && (($namelength -1 )< 63)
	&& $version_this >= 129 && $version_needed >= 129) {
	return 1;
    } else {
	return 0;
    }
}

sub uniqify ($$;$) {
    my ($dir,$name,$ext) = @_;
    my $i;
    my $j = defined($ext) ? (length($ext) + 1) : 0;
    $name = substr($name,(-31 + $j)) if (length($name) > (31 - $j));
    my $fullname = $j ? $dir.$name.".$ext" : $dir.$name;
    if(-e $fullname) {
        my $newname;
        for($i = 1;$i <= 100;$i++) {
            $newname = $j ? "$name.$i.$ext" : "$name.$i";
            $newname = substr($newname,-31) if length($newname) > 31;
            last unless (-e $dir.$newname);
        }
        return $dir.$newname;
    }
    return $fullname;
}

sub block_read {
#
#  Make sure that exactly the requested number of bytes gets read from a file,
#  and no less.  If less get read, it's an error.  MacBinary files are guaranteed
#  to be padded to 128 byte boundaries, so this prevents any data corruption
#  if the number of bytes requested are not obtained.
#
    my($fh,$buf,$number) = @_;
    my $n = $number;
    my $m;
    
    $$buf = "";
    my $buff  = "";
    my $count = 0;
    
    while($n) {
        $m = read($fh,$buff,$n);
	croak ("block_read: End of file reached prematurely") unless defined($m);
	$$buf .= $buff;
	$n -= $m;
	$count++;
	if($count > 100 ) {
	    croak("block_read: Unable to read exactly $number bytes after 100 tries");
	}
    }
    
     return $number;
}
   

    
1;
__END__

=head1 NAME

Mac::Conversions - A package for common MacOS file encoding/decoding tasks

=head1 SYNOPSIS

    use Mac::Conversions qw(binhex debinhex macbinary demacbinary macb2hex hex2macb);
    $converter = Mac::Conversions->new;

    $converter->binhex("path:to:MacPerl");
    $converter->debinhex("path:to:MacPerl.hqx");

    $converter->macbinary("path:to:Shuck");
    $converter->demacbinary("path:to:Shuck.bin");

    $converter->macb2hex("path:to:MacPerl.hqx");
    $converter->hex2macb("path:to:MacPerl.bin");

=head1 DESCRIPTION

C<Mac::Conversions> is a class implementing converters for the types
of file encoding/decoding routinely done when using MacOS.  All of these rely
on the presence of the C<Convert::BinHex> module, and C<Mac::Conversions> will
not run if C<Convert::BinHex> is not installed.

The conversions are:

=over 4

=item C<binhex($path)>

Take the native Macintosh file pointed to by $path and create a BinHex file 
in the same folder.  If the native Macintosh file is named "name", the 
BinHex file is named "name.hqx", unless "name.hqx" already exists.  Then 
C<binhex> will attempt to find a unique name by inserting integers in the 
name, "name.0.hqx", "name.1.hqx", etc.

=item C<debinhex($path)>

Take the BinHex file pointed to by $path and decode it to reconstruct the 
native Macintosh file.  The name of the file will be that encoded into the 
BinHex file if a file of that name doesn't exist.  Otherwise, a unique name 
will be constructed by adding integers after the name.

=item C<macbinary($path)>

Take the native Macintosh file pointed to by $path and create a MacBinaryII 
file.  The name of the MacBinary file will be "name.bin" if the native file 
is called "name", but C<macbinary> will try to find a unique name in the 
same way that C<binhex> does if a file "name.bin" already exists.

=item C<demacbinary($path)>

The MacBinary II file pointed to by $path will be decoded to a native 
Macintosh file.  The name of the file will be that encoded into the 
MacBinary file, except a unique name will be constructed if a file of
that name already exists.

=item C<hex2macb($path)>

The BinHex file $path is converted to a MacBinary file.  The name will be 
"name.bin", where name is the name of the file encoded in the BinHex file,
with the usual caveat.

=item C<macb2hex($path)>

The MacBinary II file $path is converted to BinHex.

=item C<is_macbinary($path)>

This routine uses a simple test to find out if a file is a MacBinary or not.
Returns 1 if it is, 0 otherwise.  This routine can be fooled, but should be
correct almost all of the time.

=item C<new>

The constructor for the class.  If new is called with Debug => 1

$c = Mac::Conversions->new(Debug => 1);

then semi-useful debugging information will be printed to standard output.  
If Remove => 1 is set, then the original BinHex or MacBinary (but never a 
native Mac file) will be unlinked.  (Note this means that it doesn't simply 
get moved to the Trash but disappears forever.)

=back

=head1 SEE ALSO

See the documentation for C<Convert::BinHex>, where all the heavy lifting is really done.

=head1 COPYRIGHT

  Copyright 1999, Paul J. Schinder

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
