# DB_File.pm -- Perl 5 interface to Berkeley DB 
#
# written by Paul Marquess (pmarquess@bfsec.bt.co.uk)
# last modified 23rd June 1994
# version 0.1

package DB_File::HASHINFO ;
use Carp;

sub TIEHASH
{
    bless {} ;
}

%elements = ( 'bsize'     => 0,
              'ffactor'   => 0,
              'nelem'     => 0,
              'cachesize' => 0,
              'hash'      => 0,
              'lorder'    => 0
            ) ;

sub FETCH 
{  
    return $_[0]{$_[1]} if defined $elements{$_[1]}  ;

    croak "DB_File::HASHINFO::FETCH - Unknown element '$_[1]'" ;
}


sub STORE 
{
    if ( defined $elements{$_[1]} )
    {
        $_[0]{$_[1]} = $_[2] ;
        return ;
    }
    
    croak "DB_File::HASHINFO::STORE - Unknown element '$_[1]'" ;
}

sub DELETE 
{
    if ( defined $elements{$_[1]} )
    {
        delete ${$_[0]}{$_[1]} ;
        return ;
    }
    
    croak "DB_File::HASHINFO::DELETE - Unknown element '$_[1]'" ;
}


sub DESTROY {undef %{$_[0]} }
sub FIRSTKEY { croak "DB_File::HASHINFO::FIRSTKEY is not implemented" }
sub NEXTKEY { croak "DB_File::HASHINFO::NEXTKEY is not implemented" }
sub EXISTS { croak "DB_File::HASHINFO::EXISTS is not implemented" }
sub CLEAR { croak "DB_File::HASHINFO::CLEAR is not implemented" }

package DB_File::BTREEINFO ;
use Carp;

sub TIEHASH
{
    bless {} ;
}

%elements = ( 'flags'	=> 0,
              'cachesize'  => 0,
              'maxkeypage' => 0,
              'minkeypage' => 0,
              'psize'      => 0,
              'compare'    => 0,
              'prefix'     => 0,
              'lorder'     => 0
            ) ;

sub FETCH 
{  
    return $_[0]{$_[1]} if defined $elements{$_[1]}  ;

    croak "DB_File::BTREEINFO::FETCH - Unknown element '$_[1]'" ;
}


sub STORE 
{
    if ( defined $elements{$_[1]} )
    {
        $_[0]{$_[1]} = $_[2] ;
        return ;
    }
    
    croak "DB_File::BTREEINFO::STORE - Unknown element '$_[1]'" ;
}

sub DELETE 
{
    if ( defined $elements{$_[1]} )
    {
        delete ${$_[0]}{$_[1]} ;
        return ;
    }
    
    croak "DB_File::BTREEINFO::DELETE - Unknown element '$_[1]'" ;
}


sub DESTROY {undef %{$_[0]} }
sub FIRSTKEY { croak "DB_File::BTREEINFO::FIRSTKEY is not implemented" }
sub NEXTKEY { croak "DB_File::BTREEINFO::NEXTKEY is not implemented" }
sub EXISTS { croak "DB_File::BTREEINFO::EXISTS is not implemented" }
sub CLEAR { croak "DB_File::BTREEINFO::CLEAR is not implemented" }

package DB_File::RECNOINFO ;
use Carp;

sub TIEHASH
{
    bless {} ;
}

%elements = ( 'bval'      => 0,
              'cachesize' => 0,
              'psize'     => 0,
              'flags'     => 0,
              'lorder'    => 0,
              'reclen'    => 0,
              'bfname'    => 0
            ) ;
sub FETCH 
{  
    return $_[0]{$_[1]} if defined $elements{$_[1]}  ;

    croak "DB_File::RECNOINFO::FETCH - Unknown element '$_[1]'" ;
}


sub STORE 
{
    if ( defined $elements{$_[1]} )
    {
        $_[0]{$_[1]} = $_[2] ;
        return ;
    }
    
    croak "DB_File::RECNOINFO::STORE - Unknown element '$_[1]'" ;
}

sub DELETE 
{
    if ( defined $elements{$_[1]} )
    {
        delete ${$_[0]}{$_[1]} ;
        return ;
    }
    
    croak "DB_File::RECNOINFO::DELETE - Unknown element '$_[1]'" ;
}


sub DESTROY {undef %{$_[0]} }
sub FIRSTKEY { croak "DB_File::RECNOINFO::FIRSTKEY is not implemented" }
sub NEXTKEY { croak "DB_File::RECNOINFO::NEXTKEY is not implemented" }
sub EXISTS { croak "DB_File::BTREEINFO::EXISTS is not implemented" }
sub CLEAR { croak "DB_File::BTREEINFO::CLEAR is not implemented" }



package DB_File ;
use Carp;

#typedef enum { DB_BTREE, DB_HASH, DB_RECNO } DBTYPE;
$DB_BTREE = TIEHASH DB_File::BTREEINFO ;
$DB_HASH  = TIEHASH DB_File::HASHINFO ;
$DB_RECNO = TIEHASH DB_File::RECNOINFO ;

require TieHash;
require Exporter;
require AutoLoader;
require DynaLoader;
@ISA = qw(TieHash Exporter DynaLoader);
@EXPORT = qw(
        $DB_BTREE $DB_HASH $DB_RECNO 
	BTREEMAGIC
	BTREEVERSION
	DB_LOCK
	DB_SHMEM
	DB_TXN
	HASHMAGIC
	HASHVERSION
	MAX_PAGE_NUMBER
	MAX_PAGE_OFFSET
	MAX_REC_NUMBER
	RET_ERROR
	RET_SPECIAL
	RET_SUCCESS
	R_CURSOR
	R_DUP
	R_FIRST
	R_FIXEDLEN
	R_IAFTER
	R_IBEFORE
	R_LAST
	R_NEXT
	R_NOKEY
	R_NOOVERWRITE
	R_PREV
	R_RECNOSYNC
	R_SETCURSOR
	R_SNAPSHOT
	__R_UNUSED
);

sub AUTOLOAD {
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    croak "Your vendor has not defined DB macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

@liblist = ();
@liblist = split ' ', $Config::Config{"DB_File_loadlibs"} 
    if defined $Config::Config{"DB_File_loadlibs"};

bootstrap DB_File @liblist;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
