package AutoLoader;

AUTOLOAD {
    my $name = "auto/$AUTOLOAD.al";
    $name =~ s#::#/#g;
    eval {require $name};
    if ($@) {
	($p,$f,$l) = caller($AutoLevel);
	$@ =~ s/ at .*\n//;
	die "$@ at $f line $l\n";
    }
    goto &$AUTOLOAD;
}

1;
