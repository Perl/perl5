package Memoize::Saves;

$DEBUG = 0;

sub TIEHASH 
{
    my ($package, %args) = @_;
    my %cache;

    # Convert the CACHE to a referenced hash for quick lookup
    #
    if( $args{CACHE} )
    {
	my %hash;
	$args{CACHE} = [ $args{CACHE} ] unless ref $args{CACHE} eq "ARRAY";
	foreach my $value ( @{$args{CACHE}} )
	{
	    $hash{$value} = 1;
	}
	$args{CACHE} = \%hash;
    }

    # Convert the DUMP list to a referenced hash for quick lookup
    #
    if( $args{DUMP} )
    {
	my %hash;
	$args{DUMP} = [ $args{DUMP} ] unless ref $args{DUMP} eq "ARRAY";
	foreach my $value (  @{$args{DUMP}} )
	{
	    $hash{$value} = 1;
	}
	$args{DUMP} = \%hash;
    }

    if ($args{TIE}) 
    {
	my ($module, @opts) = @{$args{TIE}};
	my $modulefile = $module . '.pm';
	$modulefile =~ s{::}{/}g;
	eval { require $modulefile };
	if ($@) {
	    die "Memoize::Saves: Couldn't load hash tie module `$module': $@; aborting";
	}
	my $rc = (tie %cache => $module, @opts);
	unless ($rc) 	{
	    die "Memoize::Saves: Couldn't tie hash to `$module': $@; aborting";
	}
    }

    $args{C} = \%cache;
    bless \%args => $package;
}

sub EXISTS 
{
    my $self = shift;
    my $key  = shift;

    if( exists $self->{C}->{$key} )
    {
	return 1;
    }
    
    return 0;
}


sub FETCH 
{
    my $self = shift;
    my $key  = shift;

    return $self->{C}->{$key};
}

sub STORE 
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    
    # If CACHE defined and this is not in our list don't save it
    #  
    if(( defined $self->{CACHE} )&&
       ( ! defined $self->{CACHE}->{$value} ))
    {
	print "$value not in CACHE list.\n" if $DEBUG;
	return;
    }

    # If DUMP is defined and this is in our list don't save it
    #
    if(( defined $self->{DUMP} )&&
       ( defined $self->{DUMP}->{$value} ))
    {
	print "$value in DUMP list.\n" if $DEBUG;
	return;
    }

    # If REGEX is defined we will store it only if its true
    #
    if(( defined $self->{REGEX} )&&
       ( $value !~ /$self->{REGEX}/ ))
    {
	print "$value did not match regex.\n" if $DEBUG;
	return;
    }
	
    # If we get this far we should save the value
    #
    print "Saving $key:$value\n" if $DEBUG;
    $self->{C}->{$key} = $value;
}

1;

# Documentation
#

=head1 NAME

Memoize::Saves - Plug-in module to specify which return values should be memoized

=head1 SYNOPSIS

    use Memoize;

    memoize 'function',
      SCALAR_CACHE => [TIE, Memoize::Saves, 
                       CACHE => [ "word1", "word2" ],
		       DUMP  => [ "word3", "word4" ],
		       REGEX => "Regular Expression",
		       TIE      => [Module, args...],
		      ], 

=head1 DESCRIPTION

Memoize::Saves is a plug-in module for Memoize.  It allows the 
user to specify which values should be cached or which should be
dumped.  Please read the manual for Memoize for background 
information.

Use the CACHE option to specify a list of return values which should
be memoized.  All other values will need to be recomputed each time.

Use the DUMP option to specify a list of return values which should
not be memoized.  Only these values will need to be recomputed each 
time.

Use the REGEX option to specify a Regular Expression which must match
for the return value to be saved.  You can supply either a plain text
string or a compiled regular expression using qr//.  Obviously the 
second method is prefered.

Specifying multiple options will result in the least common denominator
being saved.  

You can use the TIE option to string multiple Memoize Plug-ins together:


memoize ('printme', 
          SCALAR_CACHE => 
             [TIE, Memoize::Saves,
              REGEX => qr/my/,
              TIE   => [Memoize::Expire,
                        LIFETIME => 5,
                        TIE => [ GDBM_File, $filename, 
                                 O_RDWR | O_CREAT, 0666]
                       ]
             ]
         );


=head1 CAVEATS

This module is experimental, and may contain bugs.  Please report bugs
to the address below.

If you are going to use Memoize::Saves with Memoize::Expire it is
import to use it in that order.  Memoize::Expire changes the return
value to include expire information and it may no longer match 
your CACHE, DUMP, or REGEX.


=head1 AUTHOR

Joshua Gerth <gerth@teleport.com>

=head1 SEE ALSO

perl(1)

The Memoize man page.



