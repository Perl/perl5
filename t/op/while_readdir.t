#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use warnings;

opendir my $dirhandle, '.' or die "Failed test: unable to open directory\n";

my @dir = readdir $dirhandle;
rewinddir $dirhandle;

plan 9;



{
    my @list;
    while(readdir $dirhandle){
	push @list, $_;
    }
    ok( eq_array( \@dir, \@list ), 'while(readdir){push}' );
    rewinddir $dirhandle;
}

{
    my @list;
    push @list, $_ while readdir $dirhandle;
    ok( eq_array( \@dir, \@list ), 'push while readdir' );
    rewinddir $dirhandle;
}

{
    my $tmp;
    my @list;
    push @list, $tmp while $tmp = readdir $dirhandle;
    ok( eq_array( \@dir, \@list ), 'push $dir while $dir = readdir' );
    rewinddir $dirhandle;
}

{
    my @list;
    while( my $dir = readdir $dirhandle){
	push @list, $dir;
    }
    ok( eq_array( \@dir, \@list ), 'while($dir=readdir){push}' );
    rewinddir $dirhandle;
}


{
    my @list;
    my $sub = sub{
	push @list, $_;
    };
    $sub->($_) while readdir $dirhandle;
    ok( eq_array( \@dir, \@list ), '$sub->($_) while readdir' );
    rewinddir $dirhandle;
}

SKIP:{
    skip ('No file named "0"',4) unless (scalar grep{ defined $_ && $_ eq '0' } @dir );
    
    {
	my $works = 0;
	while(readdir $dirhandle){
	    if( defined $_ && $_ eq '0'){
		$works = 1;
		last;
	    }
	}
	ok( $works, 'while(readdir){} with file named "0"' );
	rewinddir $dirhandle;
    }
    
    {
	my $works = 0;
	my $sub = sub{
	    if( defined $_ && $_ eq '0' ){
		$works = 1;
	    }
	};
	$sub->($_) while readdir $dirhandle;
	ok( $works, '$sub->($_) while readdir; with file named "0"' );
	rewinddir $dirhandle;
    }
    
    {
	my $works = 0;
	while( my $dir = readdir $dirhandle ){
	    if( defined $dir && $dir eq '0'){
		$works = 1;
		last;
	    }
	}
	ok( $works, 'while($dir=readdir){} with file named "0"');
	rewinddir $dirhandle;
    }

    {
        my $tmp;
        my $ok;
        my @list;
        defined($tmp)&& !$tmp && ($ok=1) while $tmp = readdir $dirhandle;
        ok( $ok, '$dir while $dir = readdir; with file named "0"'  );
        rewinddir $dirhandle;
    }

}

closedir $dirhandle;
