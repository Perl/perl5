package CGI::Pretty;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

use CGI ();

$VERSION = '1.0';
$CGI::DefaultClass = __PACKAGE__;
$AutoloadClass = 'CGI';
@ISA = 'CGI';

#    These tags should not be prettify'd.  If we did prettify them, the
#    browser would output text that would have extraneous spaces
@AS_IS = qw( A PRE );
my $NON_PRETTIFY_ENDTAGS =  join "", map { "</$_>" } @AS_IS;

sub _make_tag_func {
    my ($self,$tagname) = @_;
    return $self->SUPER::_make_tag_func($tagname) if $tagname=~/^(start|end)_/;

    return qq{
	sub $tagname { 
	    # handle various cases in which we're called
	    # most of this bizarre stuff is to avoid -w errors
	    shift if \$_[0] && 
#		(!ref(\$_[0]) && \$_[0] eq \$CGI::DefaultClass) ||
		    (ref(\$_[0]) &&
		     (substr(ref(\$_[0]),0,3) eq 'CGI' ||
		    UNIVERSAL::isa(\$_[0],'CGI')));
	    
	    my(\$attr) = '';
	    if (ref(\$_[0]) && ref(\$_[0]) eq 'HASH') {
		my(\@attr) = make_attributes('',shift);
		\$attr = " \@attr" if \@attr;
	    }

	    my(\$tag,\$untag) = ("\U<$tagname\E\$attr>","\U</$tagname>\E");
	    return \$tag unless \@_;

	    my \@result;
	    if ( "$NON_PRETTIFY_ENDTAGS" =~ /\$untag/ ) {
		\@result = map { "\$tag\$_\$untag\\n" } 
		 (ref(\$_[0]) eq 'ARRAY') ? \@{\$_[0]} : "\@_";
	    }
	    else {
		\@result = map { 
		    chomp; 
		    if ( \$_ !~ /<\\// ) {
			s/\\n/\\n   /g; 
		    } 
		    else {
			my \$text = "";
			my ( \$pretag, \$thistag, \$posttag );
			while ( /<\\/.*>/si ) {
			    if ( (\$pretag, \$thistag, \$posttag ) = 
				/(.*?)<(.*?)>(.*)/si ) {
				\$pretag =~ s/\\n/\\n   /g;
				\$text .= "\$pretag<\$thistag>";
			
				( \$thistag ) = split ' ', \$thistag;
				my \$endtag = "</" . uc(\$thistag) . ">";
				if ( "$NON_PRETTIFY_ENDTAGS" =~ /\$endtag/ ) {
				    if ( ( \$pretag, \$posttag ) = 
					\$posttag =~ /(.*?)\$endtag(.*)/si ) {
					\$text .= "\$pretag\$endtag";
				    }
				}
				
				\$_ = \$posttag;
			    }
			}
			\$_ = \$text;
			if ( defined \$posttag ) {
			    \$posttag =~ s/\\n/\\n   /g;
			    \$_ .= \$posttag;
			}
		    }
		    "\$tag\\n   \$_\\n\$untag\\n" } 
		(ref(\$_[0]) eq 'ARRAY') ? \@{\$_[0]} : "\@_";
	    }
	    return "\@result";
	}
    };
}

sub new {
    my $class = shift;
    my $this = $class->SUPER::new( @_ );

    return bless $this, $class;
}

1;

=head1 NAME

CGI::Pretty - module to produce nicely formatted HTML code

=head1 SYNOPSIS

    use CGI::Pretty qw( :html3 );

    # Print a table with a single data element
    print table( TR( td( "foo" ) ) );

=head1 DESCRIPTION

CGI::Pretty is a module that derives from CGI.  It's sole function is to
allow users of CGI to output nicely formatted HTML code.

When using the CGI module, the following code:
    print table( TR( td( "foo" ) ) );

produces the following output:
    <TABLE><TR><TD>foo</TD></TR></TABLE>

If a user were to create a table consisting of many rows and many columns,
the resultant HTML code would be quite difficult to read since it has no
carriage returns or indentation.

CGI::Pretty fixes this problem.  What it does is add a carriage
return and indentation to the HTML code so that one can easily read
it.

    print table( TR( td( "foo" ) ) );

now produces the following output:
    <TABLE>
       <TR>
          <TD>
             foo
          </TD>
       </TR>
    </TABLE>


=head2 Tags that won't be formatted

The <A> and <PRE> tags are not formatted.  If these tags were formatted, the
user would see the extra indentation on the web browser causing the page to
look different than what would be expected.  If you wish to add more tags to
the list of tags that are not to be touched, push them onto the C<@AS_IS> array:

    push @CGI::Pretty::AS_IS,qw(CODE XMP);

=head1 BUGS

This section intentionally left blank.

=head1 AUTHOR

Brian Paulsen <bpaulsen@lehman.com>, with minor modifications by
Lincoln Stein <lstein@cshl.org> for incorporation into the CGI.pm
distribution.

Copyright 1998, Brian Paulsen.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to bpaulsen@lehman.com.  You can also write
to lstein@cshl.org, but this code looks pretty hairy to me and I'm not
sure I understand it!

=head1 SEE ALSO

L<CGI>

=cut

