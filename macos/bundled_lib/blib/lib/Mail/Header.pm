# Mail::Header.pm
#
# Copyright (c) 1995-7 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

#
# The internals of this package are implemented in terms of a list of lines
# and a hash indexed by the tags. The hash contains a list of references to
# the actual SV's in the list. We therefore do our upmost to preserve this.
# anyone who delves into these structures deserve all they get.
#

package Mail::Header;

require 5.002;

use strict;
use Carp;
use vars qw($VERSION $FIELD_NAME);

$VERSION = "1.19";

my $MAIL_FROM = 'KEEP';
my %HDR_LENGTHS = ();

#
# Pattern to match a RFC822 Field name ( Extract from RFC #822)
#
#     field       =  field-name ":" [ field-body ] CRLF
#
#     field-name  =  1*<any CHAR, excluding CTLs, SPACE, and ":">
#
#     CHAR        =  <any ASCII character>        ; (  0-177,  0.-127.)
#     CTL         =  <any ASCII control           ; (  0- 37,  0.- 31.)
#		      character and DEL>          ; (    177,     127.)
# I have included the trailing ':' in the field-name
#
$FIELD_NAME = '[^\x00-\x1f\x7f-\xff :]+:';

##
## Private functions
##

sub _error { warn @_; return (wantarray ? () : undef) }

# tidy up internal hash table and list

sub _tidy_header
{
 my $me = shift;
 my($ref,$key);
 my $i;
 my $d = 0;

 for($i = 0 ; $i < scalar(@{$me->{'mail_hdr_list'}}) ; $i++)
  {
   unless(defined $me->{'mail_hdr_list'}[$i])
    {
     splice(@{$me->{'mail_hdr_list'}},$i,1);
     $d++;
     $i--;
    }
  }

 if($d)
  {
   local $_;
   my @del = ();

   while(($key,$ref) = each %{$me->{'mail_hdr_hash'}} )
    {
     push(@del, $key)
	unless @$ref = grep { ref($_) && defined $$_ } @$ref;
    }

   map { delete $me->{'mail_hdr_hash'}{$_} } @del;
  }
}

# fold the line to the given length

my %STRUCTURE;
@STRUCTURE{ map { lc } qw{
  To Cc Bcc From Date Reply-To Sender
  Resent-Date Resent-From Resent-Sender Resent-To Return-Path
  list-help list-post list-unsubscribe Mailing-List
  Received References Message-ID In-Reply-To
  Content-Length Content-Type
  Delivered-To
  Lines
  MIME-Version
  Precedence
  Status
}} = ();

sub _fold_line
{
 my($ln,$maxlen) = @_;

 $maxlen = 20
    if($maxlen < 20);

 my $max = int($maxlen - 5);         # 4 for leading spcs + 1 for [\,\;]
 my $min = int($maxlen * 4 / 5) - 4;
 my $ml = $maxlen;

 $_[0] =~ s/\s*[\r\n]+\s*/ /og; # Compress any white space around a newline
 $_[0] =~ s/\s*\Z/\n/so;        # End line with a EOLN

 return if $_[0] =~ /^From\s/io;

 if(length($_[0]) > $ml)
  {
   if ($_[0] =~ /^([-\w]+)/ and exists $STRUCTURE{ lc $1 } )
    {
     #Split the line up
     # first bias towards splitting at a , or a ; >4/5 along the line
     # next split a whitespace
     # else we are looking at a single word and probably don't want to split
     my $x = "";

     $x .= "$1\n    "
	while($_[0] =~ s/^\s*(
			   [^"]{$min,$max}?[\,\;]
			  |[^"]{1,$max}\s
			  |[^\s"]*(?:"[^"]*"[^\s"]*)+\s
			  |[^\s"]+\s
			  )
			//x);
     $x .= $_[0];
     $_[0] = $x;
     $_[0] =~ s/(\A\s+|[\t ]+\Z)//sog;
     $_[0] =~ s/\s+\n/\n/sog;
    }
   else
    {
      my $dif = $max-$min;

      $_[0] =~ s/(?:^|\G)
		(?:
		  (.{$min,$max})\s+
		 |(.{$min,$max})
		)
                /$+\n    /xg;
    }
  }

 $_[0] =~ s/\A(\S+)\n\s*(?=\S)/$1 /so; 
}

# attempt to change the case of a tag to that required by RFC822. That
# being all characters are lowercase except the first of each word. Also
# if the word is an `acronym' then all characters are uppercase. We decide
# a word is an acronym if it does not contain a vowel.

sub _tag_case
{
 my $tag = shift;

 $tag =~ s/:\Z//o;

 # Change the case of the tag
 # eq Message-Id
 $tag =~ s/\b([a-z]+)/\L\u$1/gio;
 $tag =~ s/\b([b-df-hj-np-tv-z]+|MIME)\b/\U$1/gio
	if $tag =~ /-/;

 $tag;
}

# format a complete line
#  ensure line starts with the given tag
#  ensure tag is correct case
#  change the 'From ' tag as required
#  fold the line

sub _fmt_line
{
 my $me = shift;
 my $tag = shift;
 my $line = shift;
 my $modify = shift || $me->{'mail_hdr_modify'};
 my $ctag = undef;

 ($tag) = $line =~ /\A($FIELD_NAME|From )/oi
    unless(defined $tag);

 if($tag =~ /\AFrom /io && $me->{'mail_hdr_mail_from'} ne 'KEEP')
  {
   if ($me->{'mail_hdr_mail_from'} eq 'COERCE')
    {
     $line =~ s/^From /Mail-From: /o;
     $tag = "Mail-From:";
    }
   elsif ($me->{'mail_hdr_mail_from'} eq 'IGNORE')
    {
     return ();
    }
   elsif ($me->{'mail_hdr_mail_from'} eq 'ERROR')
    {
     return _error "unadorned 'From ' ignored: <$line>"
    }
  }

 if(defined $tag)
  {
   $tag = _tag_case($ctag = $tag);

   $ctag = $tag
   	if($modify);

   $ctag =~ s/([^ :])\Z/$1:/o if defined $ctag;
  }

 croak( "Bad RFC822 field name '$tag'\n")
   unless(defined $ctag && $ctag =~ /\A($FIELD_NAME|From )/oi);

 # Ensure the line starts with tag
 if(defined($ctag) && ($modify || $line !~ /\A\Q$ctag\E/i))
  {
   my $xtag;
   ($xtag = $ctag) =~ s/\s*\Z//o;
   $line =~ s/\A(\Q$ctag\E)?\s*/$xtag /i;
  }

 my $maxlen = $me->{'mail_hdr_lengths'}{$tag}
		|| $HDR_LENGTHS{$tag}
		|| $me->fold_length;

 _fold_line($line,$maxlen)
    if $modify && defined $maxlen;

 $line =~ s/\n*\Z/\n/so;

 ($tag, $line);
}

sub _insert
{
 my($me,$tag,$line,$where) = @_;

 if($where < 0)
  {
   $where = scalar(@{$me->{'mail_hdr_list'}}) + $where + 1;

   $where = 0
	if($where < 0);
  }
 elsif($where >= scalar(@{$me->{'mail_hdr_list'}}))
  {
   $where = scalar(@{$me->{'mail_hdr_list'}});
  }

 my $atend = $where == scalar(@{$me->{'mail_hdr_list'}});

 splice(@{$me->{'mail_hdr_list'}},$where,0,$line);

 $me->{'mail_hdr_hash'}{$tag} ||= [];
 my $ref = \${$me->{'mail_hdr_list'}}[$where];

 if(scalar($me->{'mail_hdr_hash'}{$tag}) && $where)
  {
   if($atend)
    {
     push(@{$me->{'mail_hdr_hash'}{$tag}}, $ref);
    }
   else
    {
     my($ln,$i,$ref);
     $i = 0;
     foreach $ln (@{$me->{'mail_hdr_list'}})
      {
       my $r = \$ln;
       last if($r == $ref);
       $i++ if($r == $me->{'mail_hdr_hash'}{$tag}[$i]);
      }
     splice(@{$me->{'mail_hdr_hash'}{$tag}},$i,0,$ref);
    }
  }
 else
  {
   unshift(@{$me->{'mail_hdr_hash'}{$tag}}, $ref);
  }
}

##
## Constructor
##

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;
 my $arg = @_ % 2 ? shift : undef;
 my %arg = @_;

 $arg{Modify} = delete $arg{Reformat} unless exists $arg{Modify};

 my %hash = (
	mail_hdr_list     => [],
	mail_hdr_hash     => {},
	mail_hdr_modify   => delete $arg{Modify} || 0,
	mail_hdr_foldlen  => 79,
	mail_hdr_lengths  => {}
	);

 my $me = bless \%hash, $type;

 $me->mail_from( uc($arg{'MailFrom'} || $MAIL_FROM) );

 $me->fold_length($arg{FoldLength})
    if exists $arg{FoldLength};

 if(ref $arg)
  {
   if(ref($arg) eq 'ARRAY')
    {
     $me->extract([ @{$arg} ]);
    }
   elsif(defined fileno($arg))
    {
     $me->read($arg);
    }
  }

 $me;
}

sub modify
{
 my $me = shift;
 my $old = $me->{'mail_hdr_modify'};

 $me->{'mail_hdr_modify'} = 0 + shift
	if @_;

 $old;
}

sub mail_from
{
 my $me = shift;
 my $choice = uc(shift);

 $choice =~ /^(IGNORE|ERROR|COERCE|KEEP)$/ 
	or die "bad Mail-From choice: '$choice'";

 if(ref($me))
  {
   $me->{'mail_hdr_mail_from'} = $choice;
  }
 else
  {
   $MAIL_FROM = $choice;
  }

 $me;
}

sub fold
{
 my $me = shift;
 my $maxlen = shift;
 my($tag,$list,$ln);

 while(($tag,$list) = each %{$me->{'mail_hdr_hash'}})
  {
   my $len = $maxlen
		|| $me->{'mail_hdr_lengths'}{$tag}
		|| $HDR_LENGTHS{$tag}
		|| $me->fold_length;

   foreach $ln (@$list)
    {
     _fold_line($$ln,$len)
        if defined $ln;
    }
  }

 $me;
}

sub unfold
{
 my $me = shift;
 my($tag,$list,$ln);

 if(@_)
  {
   $tag = _tag_case(shift);
   return $me unless exists $me->{'mail_hdr_hash'}{$tag};
   $list = $me->{'mail_hdr_hash'}{$tag};
   foreach $ln (@$list)
    {
     $$ln =~ s/\r?\n\s+/ /sog
	if defined $ln && defined $$ln;
    }
  }
 else
  {
   while(($tag,$list) = each %{$me->{'mail_hdr_hash'}})
    {
     foreach $ln (@$list)
      {
       $$ln =~ s/\r?\n\s+/ /sog
	if defined $ln && defined $$ln;
      }
    }
  }
 $me;
}

sub extract
{
 my $me = shift;
 my $arr = shift;
 my $line;

 $me->empty;

 while(scalar(@{$arr}) && $arr->[0] =~ /\A($FIELD_NAME|From )/o)
  {
   my $tag = $1;

   $line = shift @{$arr};
   $line .= shift @{$arr}
       while(scalar(@{$arr}) && $arr->[0] =~ /\A[ \t]+/o);

   ($tag,$line) = _fmt_line($me,$tag,$line);

   _insert($me,$tag,$line,-1)
      if defined $line;
  }

 shift @{$arr}
  if(scalar(@{$arr}) && $arr->[0] =~ /\A\s*\Z/o);

 $me;
}

sub read
{
 my $me = shift;
 my $fd = shift;

 $me->empty;

 my $line = undef;
 my $ln = "";
 my $tag = undef;

 while(1)
  {
   $ln = <$fd>;

   if(defined $ln && defined $line && $ln =~ /\A[ \t]+/o)
    {
     $line .= $ln;
     next;
    }

   if(defined $line)
    {
     ($tag,$line) = _fmt_line($me,$tag,$line);
      _insert($me,$tag,$line,-1)
	if defined $line;
    }

   last
     unless(defined $ln && $ln =~ /\A($FIELD_NAME|From )/o);

   $tag  = $1;
   $line = $ln;
  }

 $me;
}

sub empty
{
 my $me = shift;

 $me->{'mail_hdr_list'} = [];
 $me->{'mail_hdr_hash'} = {};

 $me;
}

sub header
{
 my $me = shift;

 $me->extract(@_)
	if(@_);

 $me->fold
    if $me->{'mail_hdr_modify'};

 # Must protect ourself against corruption as the hash contains refs to the
 # SV's in the list, if the user modifies this list we are really screwed :-

 [ @{$me->{'mail_hdr_list'}} ];
}

# Return/set headers by hash reference.  This can probably be
# optimized. I didn't want to mess much around with the internal
# implementation as for now...
# -- Tobias Brox <tobix@cpan.org>

sub header_hashref {
 my $me = shift;
 my $hashref = shift;

 # Extract the input data
 for my $hdrkey (keys %$hashref) {
   for (ref $hashref->{$hdrkey} 
	? @{$hashref->{$hdrkey}} 
	: $hashref->{$hdrkey}) {
     $me->add($hdrkey, $_);
   }
 }

 $me->fold
    if $me->{'mail_hdr_modify'};

 # Build a hash
 my $hash={ map { $_ => [ $me->get($_) ] } keys %{$me->{'mail_hdr_hash'}} }; 

 return $hash;
}

sub add
{
 my $me = shift;
 my($tag,$text,$where) = @_;
 my $line;
 ($tag,$line) = _fmt_line($me,$tag,$text);

 # Must have a tag and text to add
 return undef
	unless(defined $tag && defined $line);

 $where = -1
	unless defined $where;

 _insert($me,$tag,$line,$where);

 $line =~ /^\S+\s(.*)/os;
 return $1;
}

sub replace
{
 my $me = shift;
 my $idx = 0;
 my($tag,$line);

 $idx = pop @_
    if(@_ % 2);

TAG:
 while(@_)
  {
   ($tag,$line) = _fmt_line($me,splice(@_,0,2));

   return undef
        unless(defined $tag && defined $line);

   if(exists $me->{'mail_hdr_hash'}{$tag} &&
      defined $me->{'mail_hdr_hash'}{$tag}[$idx])
    {
     ${$me->{'mail_hdr_hash'}{$tag}[$idx]} = $line;
    }
   else
    {
     _insert($me,$tag,$line,-1);
    }
  }

 $line =~ /^\S+\s*(.*)/os;
 return $1;
}

sub combine
{
 my $me  = shift;
 my $tag = _tag_case(shift);
 my $with = shift || ' ';
 my $line;

 return _error "unadorned 'From ' ignored"
	if($tag =~ /^From /io && $me->{'mail_hdr_mail_from'} ne 'KEEP');

 return undef
    unless exists $me->{'mail_hdr_hash'}{$tag};

 if(scalar(@{$me->{'mail_hdr_hash'}{$tag}}) > 1)
  {
   my @lines = $me->get($tag);

   chomp(@lines);

   map { $$_ = undef } @{$me->{'mail_hdr_hash'}{$tag}};

   $line = ${$me->{'mail_hdr_hash'}{$tag}[0]} = 
        (_fmt_line($me,$tag, join($with,@lines),1))[1];

   _tidy_header($me);
  }
 else
  {
   return $me->{'mail_hdr_hash'}{$tag}[0];
  }

 return $line;		# post-match
}

sub get
{
 my $me = shift;
 my $tag = _tag_case(shift);
 my $idx = shift;

 return wantarray ? () : undef
    unless exists $me->{'mail_hdr_hash'}{$tag};

 my $l = length($tag);
 $l += 1 unless $tag =~ / \Z/o;

 $idx = 0
    unless defined $idx || wantarray;

 if(defined $idx)
  { 
   return defined $me->{'mail_hdr_hash'}{$tag}[$idx]
        ?  eval { # why won't do work here ??
	       my $tmp = substr(${$me->{'mail_hdr_hash'}{$tag}[$idx]}, $l);
	      $tmp =~ s/^\s+//;
	      $tmp;
	  }
        : undef;
  }

 return  map {
		my $tmp = substr($$_,$l);
		$tmp =~ s/^\s+//;
		$tmp
	     } @{$me->{'mail_hdr_hash'}{$tag}};
}

sub count
{
 my $me = shift;
 my $tag = _tag_case(shift);

 exists $me->{'mail_hdr_hash'}{$tag}
	? scalar(@{$me->{'mail_hdr_hash'}{$tag}})
	: 0;
}

sub exists
{
 carp "Depriciated use of Mail::Header::exists, use count" if $^W;
 count(@_);
}

sub delete
{
 my $me  = shift;
 my $tag = _tag_case(shift);
 my $idx = shift;
 my @val = ();

 if(defined $me->{'mail_hdr_hash'}{$tag})
  {
   my $l = length($tag);
   $l += 2 unless $tag =~ / \Z/o;

   if(defined $idx)
    {
     if(defined $me->{'mail_hdr_hash'}{$tag}[$idx])
      {
       push(@val, substr(${$me->{'mail_hdr_hash'}{$tag}[$idx]},$l));
       undef ${$me->{'mail_hdr_hash'}{$tag}[$idx]};
      }
    }
   else
    {
     local $_;
     @val = map {
                 my $x = substr($$_,$l);
                 undef $$_;
                 $x
                } @{$me->{'mail_hdr_hash'}{$tag}};
    }

   _tidy_header($me);
  }

 return @val;
}

sub print
{
 my $me = shift;
 my $fd = shift || \*STDOUT;
 my $ln;

 foreach $ln (@{$me->{'mail_hdr_list'}})
  {
   next
    unless defined $ln;
   print $fd $ln or
    return 0;
  }

 1;
}

sub as_string
{
 my $me = shift;

 join('', grep { defined } @{$me->{'mail_hdr_list'}});
}

sub fold_length
{
 my $me  = shift;
 my $old;

 if(@_ == 2)
  {
   my($tag,$len) = @_;

   my $hash = ref($me) ? $me->{'mail_hdr_lengths'} : \%HDR_LENGTHS;

   $tag = _tag_case($tag);

   $old = $hash->{$tag} || undef;
   $hash->{$tag} = $len > 20 ? $len : 20;
  }
 else
  {
   my $len = shift;

   $old = $me->{'mail_hdr_foldlen'};

   if(defined $len)
    {
     $me->{'mail_hdr_foldlen'} = $len > 20 ? $len : 20;
     $me->fold;
    }
  }

 $old;
}

sub tags
{
 my $me = shift;

 keys %{$me->{'mail_hdr_hash'}};
}

sub dup
{
 my $me = shift;
 my $type = ref($me) || croak "Cannot dup without an object";
 my $dup = new $type;

 %$dup = %$me;
 $dup->empty;

 $dup->{'mail_hdr_list'} = [ @{$me->{'mail_hdr_list'}} ];

 my $ln;
 foreach $ln ( @{$dup->{'mail_hdr_list'}} )
  {
   my $tag = _tag_case(($ln =~ /\A($FIELD_NAME|From )/oi)[0]);

   $dup->{'mail_hdr_hash'}{$tag} ||= [];
   push(@{$dup->{'mail_hdr_hash'}{$tag}}, \$ln);
  }

 $dup;
}

sub cleanup
{
 my $me = shift;
 my $d = 0;
 my $key;

 foreach $key (@_ ? @_ : keys %{$me->{'mail_hdr_hash'}})
  {
   my $arr = $me->{'mail_hdr_hash'}{$key};
   my $ref;
   foreach $ref (@$arr)
    {
     unless($$ref =~ /\A\S+\s+\S/soi)
      {
       $$ref = undef;
       $d++;
      }
    }
  }

 _tidy_header($me)
	if $d;

 $me;  
}

1; # keep require happy


=head1 NAME

Mail::Header - manipulate mail RFC822 compliant headers

=head1 SYNOPSIS

    use Mail::Header;
    
    $head = new Mail::Header;
    $head = new Mail::Header \*STDIN;
    $head = new Mail::Header [<>], Modify => 0;

=head1 DESCRIPTION

This package provides a class object which can be used for reading, creating,
manipulating and writing RFC822 compliant headers.

=head1 CONSTRUCTOR

=over 4

=item new ( [ ARG ], [ OPTIONS ] )

C<ARG> may be either a file descriptor (reference to a GLOB)
or a reference to an array. If given the new object will be
initialized with headers either from the array of read from 
the file descriptor.

C<OPTIONS> is a list of options given in the form of key-value
pairs, just like a hash table. Valid options are

=over 8

=item B<Modify>

If this value is I<true> then the headers will be re-formatted,
otherwise the format of the header lines will remain unchanged.

=item B<MailFrom>

This option specifies what to do when a header in the form `From '
is encountered. Valid values are C<IGNORE> - ignore and discard the header,
C<ERROR> - invoke an error (call die), C<COERCE> - rename them as Mail-From
and C<KEEP> - keep them.

=item B<FoldLength>

The default length of line to be used when folding header lines

=back

=back

=head1 METHODS

=over 4

=item modify ( [ VALUE ] )

If C<VALUE> is I<false> then C<Mail::Header> will not do any automatic
reformatting of the headers, other than to ensure that the line
starts with the tags given.

=item mail_from ( OPTION )

C<OPTION> specifies what to do when a C<`From '> line is encountered.
Valid values are C<IGNORE> - ignore and discard the header,
C<ERROR> - invoke an error (call die), C<COERCE> - rename them as Mail-From
and C<KEEP> - keep them.

=item fold ( [ LENGTH ] )

Fold the header. If C<LENGTH> is not given then C<Mail::Header> uses the
following rules to determine what length to fold a line.

The fold length for the tag that is begin processed

The default fold length for the tag that is being processed

The default fold length for the object

=item extract ( ARRAY_REF )

Extract a header from the given array. C<extract> B<will modify> this array.
Returns the object that the method was called on.

=item read ( FD )

Read a header from the given file descriptor.

=item empty ()

Empty the C<Mail::Header> object of all lines.

=item header ( [ ARRAY_REF ] )

C<header> does multiple operations. First it will extract a header from
the array, if given. It will the reformat the header, if reformatting
is permitted, and finally return a reference to an array which
contains the header in a printable form.

=item header_hashref ( [ HASH_REF ] )

As C<header>, but it will eventually set headers from a hash
reference, and it will return the headers as a hash reference.

The values in the hash might either be a scalar or an array reference,
as an example:

    $hashref->{From}='Tobias Brox <tobix@cpan.org>';
    $hashref->{To}=['you@somewhere', 'me@localhost'];

=item add ( TAG, LINE [, INDEX ] )

Add a new line to the header. If C<TAG> is I<undef> the the tag will be
extracted from the beginning of the given line. If C<INDEX> is given
the new line will be inserted into the header at the given point, otherwise
the new line will be appended to the end of the header.

=item replace ( TAG, LINE [, INDEX ] )

Replace a line in the header.  If C<TAG> is I<undef> the the tag will be
extracted from the beginning of the given line. If C<INDEX> is given
the new line will replace the Nth instance of that tag, otherwise the
first instance of the tag is replaced. If the tag does not appear in the
header then a new line will be appended to the header.

=item combine ( TAG [, WITH ] )

Combine all instances of C<TAG> into one. The lines will be
joined togther with C<WITH>, or a single space if not given. The new
item will be positioned in the header where the first instance was, all
other instances of <TAG> will be removed.

=item get ( TAG [, INDEX ] )

Get the text form a line. If C<INDEX> is given then the text of the Nth
instance will be returned. If it is not given the return value depends on the
context in which C<get> was called. In an array context a list of all the
text from all the instances of C<TAG> will be returned. In a scalar context
the text for the first instance will be returned.

=item delete ( TAG [, INDEX ] )

Delete a tag from the header. If C<INDEX> id given then the Nth instance
of the tag will be removed. If C<INDEX> is not given all instances
of tag will be removed.

=item count ( TAG )

Returns the number of times the given atg appears in the header

=item print ( [ FD ] )

Print the header to the given file descriptor, or C<STDOUT> if no
file descriptor is given.

=item as_string ()

Returns the header as a single string.

=item fold_length ( [ TAG ], [ LENGTH ] )

Set the default fold length for all tags or just one. With no arguments
the default fold length is returned. With two arguments it sets the fold
length for the given tag and returns the previous value. If only C<LENGTH>
is given it sets the default fold length for the current object.

In the two argument form C<fold_length> may be called as a static method,
setting default fold lengths for tags that will be used by B<all>
C<Mail::Header> objects. See the C<fold> method for
a description on how C<Mail::Header> uses these values.

=item tags ()

Retruns an array of all the tags that exist in the header. Each tag will
only appear in the list once. The order of the tags is not specified.

=item dup ()

Create a duplicate of the current object.

=item cleanup ()

Remove any header line that, other than the tag, only contains whitespace

=item unfold ( [ TAG ] )

Unfold all instances of the given tag so that they do not spread across
multiple lines. IF C<TAG> is not given then all lines are unfolded.

=back

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1995-7 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
