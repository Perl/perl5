package AutoLoader;
use Carp;

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

1;
