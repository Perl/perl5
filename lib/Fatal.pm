package Fatal;

use Carp;
use strict;
use vars qw( $AUTOLOAD $Debug );

$Debug = 0;

sub import {
    my $self = shift(@_);
    my($sym, $pkg);
    $pkg = (caller)[0];
    foreach $sym (@_) {
	&_make_fatal($sym, $pkg);
    }
};

sub AUTOLOAD {
    my $cmd = $AUTOLOAD;
    $cmd =~ s/.*:://;
    &_make_fatal($cmd, (caller)[0]);
    goto &$AUTOLOAD;
}

sub _make_fatal {
    my($sub, $pkg) = @_;
    my($name, $code, $sref);

    $sub = "${pkg}::$sub" unless $sub =~ /::/;
    $name = $sub;
    $name =~ s/.*::// or $name =~ s/^&//;
    print "# _make_fatal: sub=$sub pkg=$pkg name=$name\n" if $Debug;
    croak "Bad subroutine name for Fatal: $name" unless $name =~ /^\w+$/;
    $code = "sub $name {\n\tlocal(\$\", \$!) = (', ', 0);\n";
    if (defined(&$sub)) {
	# user subroutine
	$sref = \&$sub;
	$code .= "\t&\$sref";
    } else {
	# CORE subroutine
	$code .= "\tCORE::$name";
    }
    $code .= "\(\@_\) || croak \"Can't $name\(\@_\): \$!\";\n}\n";
    print $code if $Debug;
    eval($code);
    die($@) if $@;
    local($^W) = 0;   # to avoid: Subroutine foo redefined ...
    no strict 'refs'; # to avoid: Can't use string (...) as a symbol ref ...
    *{$sub} = \&{"Fatal::$name"};
}

1;

__END__

=head1 NAME

Fatal - replace functions with equivalents which succeed or die

=head1 SYNOPSIS

    use Fatal qw(open print close);

    sub juggle { . . . }
    import Fatal 'juggle';

=head1 DESCRIPTION

C<Fatal> provides a way to conveniently replace functions which normally
return a false value when they fail with equivalents which halt execution
if they are not successful.  This lets you use these functions without
having to test their return values explicitly on each call.   Errors are
reported via C<die>, so you can trap them using C<$SIG{__DIE__}> if you
wish to take some action before the program exits.

The do-or-die equivalents are set up simply by calling Fatal's C<import>
routine, passing it the names of the functions to be replaced.  You may
wrap both user-defined functions and CORE operators in this way.

=head1 AUTHOR

Lionel.Cons@cern.ch
