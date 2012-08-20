
# heredoc.t
# tests for heredocs besides what is tested in base/lex.t
BEGIN {
   chdir 't' if -d 't';
   @INC = '../lib';
   require './test.pl';
}

plan (tests => 6);
#heredoc without newline (#65838)
$string = <<'HEREDOC';
testing for 65838
HEREDOC
$code = "<<'HEREDOC';\n${string}HEREDOC";  # HD w/o newline, in eval-string
$hd = eval $code or warn "$@ ---";
ok($hd eq $string, "no terminating newline in string-eval");

$redirect = <<\REDIR;
BEGIN {
   open STDERR, ">&STDOUT" or die "PROBLEM DUPING STDOUT: $!"
}
REDIR

chomp (my $chomped_string = $string);
fresh_perl_is(
   "print $code",
   $chomped_string,{},
   "heredoc at EOF without trailing newline"
);

# like test 18 from t/base/lex.t but at EOF
fresh_perl_is(
   "print <<;\n$string",
   $chomped_string,{},
   "blank-terminated heredoc at EOF"
);


# the next three are supposed to fail parsing
fresh_perl_like(
   "$redirect print <<HEREDOC;\n$string HEREDOC",
   qr/find string terminator/, {},
   "string terminator must start at newline"
);

fresh_perl_like(
   "$redirect print <<;\nno more newlines",
   qr/find string terminator/, {},
   "empty string terminator still needs a newline"
);

fresh_perl_like(
   "$redirect print <<ThisTerminatorIsLongerThanTheData;\nno more newlines",
   qr/find string terminator/, {},
   "long terminator fails correctly"
);

