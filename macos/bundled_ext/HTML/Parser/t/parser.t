print "1..7\n";

$HTML = <<'HTML';

<!DOCTYPE HTML>

<body>

Various entities.  The parser must never break them in the middle:

&#x2F
&#x2F;
&#200
&#3030;
&#XFFFF;
&aring-&Aring;

<ul>
<li><a href="foo 'bar' baz>" id=33>This is a link</a>
<li><a href='foo "bar" baz> &aring' id=34>This is another one</a>
</ul>

<p><div align="center"><img src="http://www.perl.com/perl.gif"
alt="camel"></div>

<!-- this is
a comment --> and this is not.

<!-- this is the kind of >comment< -- --> that Netscape hates -->

< this > was not a tag. <this is/not either>

</body>

HTML

#-------------------------------------------------------------------

{
    package P;
    require HTML::Parser;
    @ISA=qw(HTML::Parser);
    $OUT='';
    $COUNT=0;

    sub new
    {
	my $class = shift;
	my $self = $class->SUPER::new;
	$OUT = '';
        die "Can only have one" if $COUNT++;
	$self;
    }

    sub DESTROY
    {
	my $self = shift;
	eval { $self->SUPER::DESTROY; };
	$COUNT--;
    }

    sub declaration
    {
	my($self, $decl) = @_;
	$OUT .= "[[$decl]]|";
    }

    sub start
    {
	my($self, $tag, $attr) = @_;
	$attr = join("/", map "$_=$attr->{$_}", sort keys %$attr);
	$attr = "/$attr" if length $attr;
	$OUT .= "<<$tag$attr>>|";
    }

    sub end
    {
	my($self, $tag) = @_;
	$OUT .= ">>$tag<<|";
    }

    sub comment
    {
	my($self, $comment) = @_;
	$OUT .= "##$comment##|";
    }

    sub text
    {
	my($self, $text) = @_;
	#$text =~ s/\n/\\n/g;
	#$text =~ s/\t/\\t/g;
	#$text =~ s/ /·/g;
	$OUT .= "$text|";
    }

    sub result
    {
	$OUT;
    }
}

my $testno = 1;
for $chunksize (64*1024, 64, 13, 3, 1, "file", "filehandle") {
#for $chunksize (1) {
    print "\n";
    if ($chunksize =~ /^file/) {
        print "Parsing from $chunksize\n";
    } else {
        print "Parsing using $chunksize byte chunks\n";
    }
    my $p = P->new;

    if ($chunksize =~ /^file/) {
	# First we must create the file
	my $tmpfile = "tmp-$$.html";
	my $file = $tmpfile;
	die "$file already exists" if -e $file;
	open(FILE, ">$file") or die "Can't create $file: $!";
        binmode FILE;
        print FILE $HTML;
        close(FILE);

	if ($chunksize eq "filehandle") {
	    require FileHandle;
	    my $fh = FileHandle->new($file) || die "Can't open $file: $!";
	    $file = $fh;
	}

        # then we can parse it.
        $p->parse_file($file);
        close $file if $chunksize eq "filehandle";
        unlink($tmpfile) || warn "Can't unlink $tmpfile: $!";
    } else {
	my $copy = $HTML;
	while (length $copy) {
	    my $chunk = substr($copy, 0, $chunksize);
	    substr($copy, 0, $chunksize) = '';
	    $p->parse($chunk);
	}
	$p->eof;
    }

    my $res = $p->result;
    my $bad;
    
    # Then we start looking for things that should not happen
    if ($res =~ /\s\|\s/) {
	print "broken space\n";
	$bad++;
    }
    for (
	 # Make sure entities are not broken
	 '&#x2F', '&#x2F;', '&#200', '&#3030;', '&#XFFFF;', '&aring', '&Aring',

         # Some elements that should be produced
         "|[[DOCTYPE HTML]]|",
         "|## this is\na comment ##|",
         "|<<ul>>|\n|<<li>>|<<a/href=foo 'bar' baz>/id=33>>|",
	 '|<<li>>|<<a/href=foo "bar" baz> å/id=34>>',
         "|>>ul<<|", "|>>body<<|\n\n|",
        )
   {
        if (index($res, $_) < 0) {
	    print "Can't find '$_' in parsed document\n";
	    $bad++;
        }
    }

    print $res if $bad || $ENV{PRINT_RESULTS};

    # And we check that we get the same result all the time
    $res =~ s/\|//g;  # remove all break marks
    if ($last_res && $res ne $last_res) {
        print "The result is not the same as last time\n";
        $bad++
    }
    $last_res = $res;

    unless ($res =~ /Various entities/) {
	print "Some text must be missing\n";
	$bad++;
    }

    print "\nnot " if $bad;
    print "ok $testno\n";
    $testno++;

}
