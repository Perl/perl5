package AutoLoader;
use Carp;

=head1 NAME

AutoLoader - load functions only on demand

=head1 SYNOPSIS

    package FOOBAR;
    use Exporter;
    use AutoLoader;
    @ISA = (Exporter, AutoLoader);

=head1 DESCRIPTION

This module tells its users that functions in the FOOBAR package are to be
autoloaded from F<auto/$AUTOLOAD.al>.  See L<perlsub/"Autoloading">.

=cut

AUTOLOAD {
    my $name = "auto/$AUTOLOAD.al";
    $name =~ s#::#/#g;
    eval {require $name};
    if ($@) {
	# The load might just have failed because the filename was too
	# long for some old SVR3 systems which treat long names as errors.
	# If we can succesfully truncate a long name then it's worth a go.
	# There is a slight risk that we could pick up the wrong file here
	# but autosplit should have warned about that when splitting.
	if ($name =~ s/(\w{12,})\.al$/substr($1,0,11).".al"/e){
	    eval {require $name};
	}
	elsif ($AUTOLOAD =~ /::DESTROY$/) {
	    eval "sub $AUTOLOAD {}";
	}
	if ($@){
	    $@ =~ s/ at .*\n//;
	    croak $@;
	}
    }
    goto &$AUTOLOAD;
}
                            
sub import
{
 my ($callclass, $callfile, $callline,$path,$callpack) = caller(0);
 ($callpack = $callclass) =~ s#::#/#;
 if (defined($path = $INC{$callpack . '.pm'}))
  {
   if ($path =~ s#^(.*)$callpack\.pm$#$1auto/$callpack/autosplit.ix# && -e $path) 
    {
     eval {require $path}; 
     carp $@ if ($@);  
    } 
   else 
    {
     croak "Have not loaded $callpack.pm";
    }
  }
}

1;
