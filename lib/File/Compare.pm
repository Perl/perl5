package File::Compare;

require Exporter;
use Carp;
use UNIVERSAL qw(isa);

@ISA=qw(Exporter);
@EXPORT=qw(compare);
@EXPORT_OK=qw(compare cmp);

$File::Compare::VERSION = '1.0';
$File::Compare::Too_Big = 1024 * 1024 * 2;


use strict;
use vars qw($\ *FROM *TO);

sub VERSION {
    # Version of File::Compare
    return $File::Compare::VERSION;
}

sub compare {
    croak("Usage: compare( file1, file2 [, buffersize]) ")
      unless(@_ == 2 || @_ == 3);

    my $from = shift;
    my $to = shift;
    my $closefrom=0;
    my $closeto=0;
    my ($size, $status, $fr, $tr, $fbuf, $tbuf);
    local(*FROM, *TO);
    local($\) = '';

    croak("from undefined") unless (defined $from);
    croak("to undefined") unless (defined $to);

    if (ref($from) && (isa($from,'GLOB') || isa($from,'IO::Handle'))) {
	*FROM = *$from;
    } elsif (ref(\$from) eq 'GLOB') {
	*FROM = $from;
    } else {
	open(FROM,"<$from") or goto fail_open1;
	binmode FROM;
	$closefrom = 1;
    }

    if (ref($to) && (isa($to,'GLOB') || isa($to,'IO::Handle'))) {
	*TO = *$to;
    } elsif (ref(\$to) eq 'GLOB') {
	*TO = $to;
    } else {
	open(TO,"<$to") or goto fail_open2;
	binmode TO;
	$closeto = 1;
    }

    if (@_) {
	$size = shift(@_) + 0;
	croak("Bad buffer size for compare: $size\n") unless ($size > 0);
    } else {
	$size = -s FROM;
	$size = 1024 if ($size < 512);
	$size = $File::Compare::Too_Big if ($size > $File::Compare::Too_Big);
    }

    $fbuf = '';
    $tbuf = '';
    while(defined($fr = read(FROM,$fbuf,$size)) && $fr > 0) {
	unless (defined($tr = read(TO,$tbuf,$fr)) and $tbuf eq $fbuf) {
            goto fail_inner;
	}
    }
    goto fail_inner if (defined($tr = read(TO,$tbuf,$size)) && $tr > 0);

    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 0;
    
  # All of these contortions try to preserve error messages...
  fail_inner:
    close(TO) || goto fail_open2 if $closeto;
    close(FROM) || goto fail_open1 if $closefrom;

    return 1;

  fail_open2:
    if ($closefrom) {
	$status = $!;
	$! = 0;
	close FROM;
	$! = $status unless $!;
    }
  fail_open1:
    return -1;
}

*cmp = \&compare;

