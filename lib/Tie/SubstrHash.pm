package SubstrHash;
use Carp;

sub TIEHASH {
    my $pack = shift;
    my ($klen, $vlen, $tsize) = @_;
    my $rlen = 1 + $klen + $vlen;
    $tsize = findprime($tsize * 1.1);	# Allow 10% empty.
    $self = bless ["\0", $klen, $vlen, $tsize, $rlen, 0, -1];
    $$self[0] x= $rlen * $tsize;
    $self;
}

sub FETCH {
    local($self,$key) = @_;
    local($klen, $vlen, $tsize, $rlen) = @$self[1..4];
    &hashkey;
    for (;;) {
	$offset = $hash * $rlen;
	$record = substr($$self[0], $offset, $rlen);
	if (ord($record) == 0) {
	    return undef;
	}
	elsif (ord($record) == 1) {
	}
	elsif (substr($record, 1, $klen) eq $key) {
	    return substr($record, 1+$klen, $vlen);
	}
	&rehash;
    }
}

sub STORE {
    local($self,$key,$val) = @_;
    local($klen, $vlen, $tsize, $rlen) = @$self[1..4];
    croak("Table is full") if $self[5] == $tsize;
    croak(qq/Value "$val" is not $vlen characters long./)
	if length($val) != $vlen;
    my $writeoffset;

    &hashkey;
    for (;;) {
	$offset = $hash * $rlen;
	$record = substr($$self[0], $offset, $rlen);
	if (ord($record) == 0) {
	    $record = "\2". $key . $val;
	    die "panic" unless length($record) == $rlen;
	    $writeoffset = $offset unless defined $writeoffset;
	    substr($$self[0], $writeoffset, $rlen) = $record;
	    ++$$self[5];
	    return;
	}
	elsif (ord($record) == 1) {
	    $writeoffset = $offset unless defined $writeoffset;
	}
	elsif (substr($record, 1, $klen) eq $key) {
	    $record = "\2". $key . $val;
	    die "panic" unless length($record) == $rlen;
	    substr($$self[0], $offset, $rlen) = $record;
	    return;
	}
	&rehash;
    }
}

sub DELETE {
    local($self,$key) = @_;
    local($klen, $vlen, $tsize, $rlen) = @$self[1..4];
    &hashkey;
    for (;;) {
	$offset = $hash * $rlen;
	$record = substr($$self[0], $offset, $rlen);
	if (ord($record) == 0) {
	    return undef;
	}
	elsif (ord($record) == 1) {
	}
	elsif (substr($record, 1, $klen) eq $key) {
	    substr($$self[0], $offset, 1) = "\1";
	    return substr($record, 1+$klen, $vlen);
	    --$$self[5];
	}
	&rehash;
    }
}

sub FIRSTKEY {
    local($self) = @_;
    $$self[6] = -1;
    &NEXTKEY;
}

sub NEXTKEY {
    local($self) = @_;
    local($klen, $vlen, $tsize, $rlen, $entries, $iterix) = @$self[1..6];
    for (++$iterix; $iterix < $tsize; ++$iterix) {
	next unless substr($$self[0], $iterix * $rlen, 1) eq "\2";
	$$self[6] = $iterix;
	return substr($$self[0], $iterix * $rlen + 1, $klen);
    }
    $$self[6] = -1;
    undef;
}

sub hashkey {
    croak(qq/Key "$key" is not $klen characters long.\n/)
	if length($key) != $klen;
    $hash = 2;
    for (unpack('C*', $key)) {
	$hash = $hash * 33 + $_;
    }
    $hash = $hash - int($hash / $tsize) * $tsize
	if $hash >= $tsize;
    $hash = 1 unless $hash;
    $hashbase = $hash;
}

sub rehash {
    $hash += $hashbase;
    $hash -= $tsize if $hash >= $tsize;
}

sub findprime {
    use integer;

    my $num = shift;
    $num++ unless $num % 2;

    $max = int sqrt $num;

  NUM:
    for (;; $num += 2) {
	for ($i = 3; $i <= $max; $i += 2) {
	    next NUM unless $num % $i;
	}
	return $num;
    }
}

1;
