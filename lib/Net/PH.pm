#
# Copyright (c) 1995-1997 Graham Barr <gbarr@pobox.com> and
# Alex Hristov <hristov@slb.com>. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package Net::PH;

require 5.001;

use strict;
use vars qw(@ISA $VERSION);
use Carp;

use Socket 1.3;
use IO::Socket;
use Net::Cmd;
use Net::Config;

$VERSION = "2.20"; # $Id: //depot/libnet/Net/PH.pm#7$
@ISA     = qw(Exporter Net::Cmd IO::Socket::INET);

sub new
{
 my $pkg  = shift;
 my $host = shift if @_ % 2;
 my %arg  = @_; 
 my $hosts = defined $host ? [ $host ] : $NetConfig{ph_hosts};
 my $ph;

 my $h;
 foreach $h (@{$hosts})
  {
   $ph = $pkg->SUPER::new(PeerAddr => ($host = $h), 
			  PeerPort => $arg{Port} || 'csnet-ns(105)',
			  Proto    => 'tcp',
			  Timeout  => defined $arg{Timeout}
					? $arg{Timeout}
					: 120
			 ) and last;
  }

 return undef
	unless defined $ph;

 ${*$ph}{'net_ph_host'} = $host;

 $ph->autoflush(1);

 $ph->debug(exists $arg{Debug} ? $arg{Debug} : undef);

 $ph;
}

sub status
{
 my $ph = shift;

 $ph->command('status')->response;
 $ph->code;
}

sub login
{
 my $ph = shift;
 my($user,$pass,$encrypted) = @_;
 my $resp;

 $resp = $ph->command("login",$user)->response;

 if(defined($pass) && $resp == CMD_MORE)
  {
   if($encrypted)
    {
     my $challenge_str = $ph->message;
     chomp($challenge_str);
     Net::PH::crypt::crypt_start($pass);
     my $cryptstr = Net::PH::crypt::encryptit($challenge_str);

     $ph->command("answer", $cryptstr);
    }
   else
    {
     $ph->command("clear", $pass);
    }
   $resp = $ph->response;
  }

 $resp == CMD_OK;
}

sub logout
{
 my $ph = shift;

 $ph->command("logout")->response == CMD_OK;
}

sub id
{
 my $ph = shift;
 my $id = @_ ? shift : $<;

 $ph->command("id",$id)->response == CMD_OK;
}

sub siteinfo
{
 my $ph = shift;

 $ph->command("siteinfo");

 my $ln;
 my %resp;
 my $cur_num = 0;

 while(defined($ln = $ph->getline))
  {
   $ph->debug_print(0,$ln)
     if ($ph->debug & 2);
   chomp($ln);
   my($code,$num,$tag,$data);

   if($ln =~ /^-(\d+):(\d+):(?:\s*([^:]+):)?\s*(.*)/o)
    {
     ($code,$num,$tag,$data) = ($1, $2, $3 || "",$4);
     $resp{$tag} = bless [$code, $num, $tag, $data], "Net::PH::Result";
    }
   else
    {
     $ph->set_status($ph->parse_response($ln));
     return \%resp;
    }
  }

 return undef;
}

sub query
{
 my $ph = shift;
 my $search = shift;

 my($k,$v);

 my @args = ('query', _arg_hash($search));

 push(@args,'return',_arg_list( shift ))
	if @_;

 unless($ph->command(@args)->response == CMD_INFO)
  {
   return $ph->code == 501
	? []
	: undef;
  }

 my $ln;
 my @resp;
 my $cur_num = 0;

 my($last_tag);

 while(defined($ln = $ph->getline))
  {
   $ph->debug_print(0,$ln)
     if ($ph->debug & 2);
   chomp($ln);
   my($code,$idx,$num,$tag,$data);

   if($ln =~ /^-(\d+):(\d+):\s*([^:]*):\s*(.*)/o)
    {
     ($code,$idx,$tag,$data) = ($1,$2,$3,$4);
     my $num = $idx - 1;

     $resp[$num] ||= {};

     $tag = $last_tag
	unless(length($tag));

     $last_tag = $tag;

     if(exists($resp[$num]->{$tag}))
      {
       $resp[$num]->{$tag}->[3] .= "\n" . $data;
      }
     else
      {
       $resp[$num]->{$tag} = bless [$code, $idx, $tag, $data], "Net::PH::Result";
      }
    }
   else
    {
     $ph->set_status($ph->parse_response($ln));
     return \@resp;
    }
  }

 return undef;
}

sub change
{
 my $ph = shift;
 my $search = shift;
 my $make = shift;

 $ph->command(
	"change", _arg_hash($search),
	"make",   _arg_hash($make)
 )->response == CMD_OK;
}

sub _arg_hash
{
 my $hash = shift;

 return $hash
	unless(ref($hash));

 my($k,$v);
 my @r;

 while(($k,$v) = each %$hash)
  {
   my $a = $v;
   $a =~ s/\n/\\n/sog;
   $a =~ s/\t/\\t/sog;
   $a = '"' . $a . '"'
	if $a =~ /\W/;
   $a = '""'
	unless length $a;

   push(@r, "$k=$a");   
  }
 join(" ", @r);
}

sub _arg_list
{
 my $arr = shift;

 return $arr
	unless(ref($arr));

 my $v;
 my @r;

 foreach $v (@$arr)
  {
   my $a = $v;
   $a =~ s/\n/\\n/sog;
   $a =~ s/\t/\\t/sog;
   $a = '"' . $a . '"'
	if $a =~ /\W/;
   push(@r, $a);   
  }

 join(" ",@r);
}

sub add
{
 my $ph = shift;
 my $arg = @_ > 1 ? { @_ } : shift;

 $ph->command('add', _arg_hash($arg))->response == CMD_OK;
}

sub delete
{
 my $ph = shift;
 my $arg = @_ > 1 ? { @_ } : shift;

 $ph->command('delete', _arg_hash($arg))->response == CMD_OK;
}

sub force
{
 my $ph = shift; 
 my $search = shift;
 my $force = shift;

 $ph->command(
	"change", _arg_hash($search),
	"force",  _arg_hash($force)
 )->response == CMD_OK;
}


sub fields
{
 my $ph = shift;

 $ph->command("fields", _arg_list(\@_));

 my $ln;
 my %resp;
 my $cur_num = 0;
 my @tags = ();
 
 while(defined($ln = $ph->getline))
  {
   $ph->debug_print(0,$ln)
     if ($ph->debug & 2);
   chomp($ln);

   my($code,$num,$tag,$data,$last_tag);

   if($ln =~ /^-(\d+):(\d+):\s*([^:]*):\s*(.*)/o)
    {
     ($code,$num,$tag,$data) = ($1,$2,$3,$4);

     $tag = $last_tag
	unless(length($tag));

     $last_tag = $tag;

     if(exists $resp{$tag})
      {
       $resp{$tag}->[3] .= "\n" . $data;
      }
     else
      {
       $resp{$tag} = bless [$code, $num, $tag, $data], "Net::PH::Result";
       push @tags, $tag;
      }
    }
   else
    {
     $ph->set_status($ph->parse_response($ln));
     return wantarray ? (\%resp, \@tags) : \%resp;
    }
  }

 return;
}

sub quit
{
 my $ph = shift;

 $ph->close
	if $ph->command("quit")->response == CMD_OK;
}

##
## Net::Cmd overrides
##

sub parse_response
{
 return ()
    unless $_[1] =~ s/^(-?)(\d\d\d):?//o;
 ($2, $1 eq "-");
}

sub debug_text { $_[2] =~ /^(clear)/i ? "$1 ....\n" : $_[2]; }

package Net::PH::Result;

sub code  { shift->[0] }
sub value { shift->[1] }
sub field { shift->[2] }
sub text  { shift->[3] }

package Net::PH::crypt;

#  The code in this package is based upon 'cryptit.c', Copyright (C) 1988 by
#  Steven Dorner, and Paul Pomes, and the University of Illinois Board
#  of Trustees, and by CSNET.

use integer;
use strict;
 
sub ROTORSZ () { 256 }
sub MASK () { 255 }

my(@t1,@t2,@t3,$n1,$n2);

sub crypt_start {
    my $pass = shift;
    $n1 = 0;
    $n2 = 0;
    crypt_init($pass);
}

sub crypt_init {
    my $pw = shift;
    my $i;

    @t2 = @t3 = (0) x ROTORSZ;

    my $buf = crypt($pw,$pw);
    return -1 unless length($buf) > 0;
    $buf = substr($buf . "\0" x 13,0,13);
    my @buf = map { ord $_ } split(//, $buf);


    my $seed = 123;
    for($i = 0 ; $i < 13 ; $i++) {
	$seed = $seed * $buf[$i] + $i;
    }
    @t1 = (0 .. ROTORSZ-1);
    
    for($i = 0 ; $i < ROTORSZ ; $i++) {
	$seed = 5 * $seed + $buf[$i % 13];
	my $random = $seed % 65521;
	my $k = ROTORSZ - 1 - $i;
	my $ic = ($random & MASK) % ($k + 1);
	$random >>= 8;
	@t1[$k,$ic] = @t1[$ic,$k];
	next if $t3[$k] != 0;
	$ic = ($random & MASK) % $k;
	while($t3[$ic] != 0) {
	    $ic = ($ic + 1) % $k;
	}
	$t3[$k] = $ic;
	$t3[$ic] = $k;
    }
    for($i = 0 ; $i < ROTORSZ ; $i++) {
	$t2[$t1[$i] & MASK] = $i
    }
}

sub encode {
    my $sp = shift;
    my $ch;
    my $n = scalar(@$sp);
    my @out = ($n);
    my $i;

    for($i = 0 ; $i < $n ; ) {
	my($f0,$f1,$f2) = splice(@$sp,0,3);
	push(@out,
	    $f0 >> 2,
	    ($f0 << 4) & 060 | ($f1 >> 4) & 017,
	    ($f1 << 2) & 074 | ($f2 >> 6) & 03,
	    $f2 & 077);
	$i += 3;
   }
   join("", map { chr((($_ & 077) + 35) & 0xff) } @out);  # ord('#') == 35
}

sub encryptit {
    my $from = shift;
    my @from = map { ord $_ } split(//, $from);
    my @sp = ();
    my $ch;
    while(defined($ch = shift @from)) {
	push(@sp,
	    $t2[($t3[($t1[($ch + $n1) & MASK] + $n2) & MASK] - $n2) & MASK] - $n1);

	$n1++;
	if($n1 == ROTORSZ) {
	    $n1 = 0;
	    $n2++;
	    $n2 = 0 if $n2 == ROTORSZ;
	}
    }
    encode(\@sp);
}

1;

__END__

=head1 NAME

Net::PH - CCSO Nameserver Client class

=head1 SYNOPSIS

    use Net::PH;
    
    $ph = Net::PH->new("some.host.name",
                       Port    => 105,
                       Timeout => 120,
                       Debug   => 0);

    if($ph) {
        $q = $ph->query({ field1 => "value1" },
                        [qw(name address pobox)]);
    
        if($q) {
        }
    }
    
    # Alternative syntax
    
    if($ph) {
        $q = $ph->query('field1=value1',
                        'name address pobox');
    
        if($q) {
        }
    }

=head1 DESCRIPTION

C<Net::PH> is a class implementing a simple Nameserver/PH client in Perl
as described in the CCSO Nameserver -- Server-Client Protocol. Like other
modules in the Net:: family the C<Net::PH> object inherits methods from
C<Net::Cmd>.

=head1 CONSTRUCTOR

=over 4

=item new ( [ HOST ] [, OPTIONS ])

    $ph = Net::PH->new("some.host.name",
                       Port    => 105,
                       Timeout => 120,
                       Debug   => 0
                      );

This is the constructor for a new Net::PH object. C<HOST> is the
name of the remote host to which a PH connection is required.

If C<HOST> is not given, then the C<SNPP_Host> specified in C<Net::Config>
will be used.

C<OPTIONS> is an optional list of named options which are passed in
a hash like fashion, using key and value pairs. Possible options are:-

B<Port> - Port number to connect to on remote host.

B<Timeout> - Maximum time, in seconds, to wait for a response from the
Nameserver, a value of zero will cause all IO operations to block.
(default: 120)

B<Debug> - Enable the printing of debugging information to STDERR

=back

=head1 METHODS

Unless otherwise stated all methods return either a I<true> or I<false>
value, with I<true> meaning that the operation was a success. When a method
states that it returns a value, failure will be returned as I<undef> or an
empty list.

=over 4

=item query( SEARCH [, RETURN ] )

    $q = $ph->query({ name => $myname },
		    [qw(name email schedule)]);
    
    foreach $handle (@{$q}) {
	foreach $field (keys %{$handle}) {
            $c = ${$handle}{$field}->code;
            $v = ${$handle}{$field}->value;
            $f = ${$handle}{$field}->field;
            $t = ${$handle}{$field}->text;
            print "field:[$field] [$c][$v][$f][$t]\n" ;
	}
    }

    

Search the database and return fields from all matching entries.

The C<SEARCH> argument is a reference to a HASH which contains field/value
pairs which will be passed to the Nameserver as the search criteria.

C<RETURN> is optional, but if given it should be a reference to a list which
contains field names to be returned.

The alternative syntax is to pass strings instead of references, for example

    $q = $ph->query('name=myname',
		    'name email schedule');

The C<SEARCH> argument is a string that is passed to the Nameserver as the 
search criteria. The strings being passed should B<not> contain any carriage
returns, or else the query command might fail or return invalid data.

C<RETURN> is optional, but if given it should be a string which will
contain field names to be returned.

Each match from the server will be returned as a HASH where the keys are the
field names and the values are C<Net::PH:Result> objects (I<code>, I<value>, 
I<field>, I<text>).

Returns a reference to an ARRAY which contains references to HASHs, one
per match from the server.

=item change( SEARCH , MAKE )

    $r = $ph->change({ email => "*.domain.name" },
                     { schedule => "busy");

Change field values for matching entries.

The C<SEARCH> argument is a reference to a HASH which contains field/value
pairs which will be passed to the Nameserver as the search criteria.

The C<MAKE> argument is a reference to a HASH which contains field/value
pairs which will be passed to the Nameserver that
will set new values to designated fields.

The alternative syntax is to pass strings instead of references, for example

    $r = $ph->change('email="*.domain.name"',
                     'schedule="busy"');

The C<SEARCH> argument is a string to be passed to the Nameserver as the 
search criteria. The strings being passed should B<not> contain any carriage
returns, or else the query command might fail or return invalid data.


The C<MAKE> argument is a string to be passed to the Nameserver that
will set new values to designated fields.

Upon success all entries that match the search criteria will have
the field values, given in the Make argument, changed.

=item login( USER, PASS [, ENCRYPT ])

    $r = $ph->login('username','password',1);

Enter login mode using C<USER> and C<PASS>. If C<ENCRYPT> is given and
is I<true> then the password will be used to encrypt a challenge text 
string provided by the server, and the encrypted string will be sent back
to the server. If C<ENCRYPT> is not given, or I<false> then the password 
will be sent in clear text (I<this is not recommended>)

=item logout()

    $r = $ph->logout();

Exit login mode and return to anonymous mode.

=item fields( [ FIELD_LIST ] )

    $fields = $ph->fields();
    foreach $field (keys %{$fields}) {
        $c = ${$fields}{$field}->code;
        $v = ${$fields}{$field}->value;
        $f = ${$fields}{$field}->field;
        $t = ${$fields}{$field}->text;
        print "field:[$field] [$c][$v][$f][$t]\n";
    }

In a scalar context, returns a reference to a HASH. The keys of the HASH are
the field names and the values are C<Net::PH:Result> objects (I<code>,
I<value>, I<field>, I<text>).

In an array context, returns a two element array. The first element is a
reference to a HASH as above, the second element is a reference to an array
which contains the tag names in the order that they were returned from the
server.

C<FIELD_LIST> is a string that lists the fields for which info will be
returned.

=item add( FIELD_VALUES )

    $r = $ph->add( { name => $name, phone => $phone });

This method is used to add new entries to the Nameserver database. You
must successfully call L<login> before this method can be used.

B<Note> that this method adds new entries to the database. To modify
an existing entry use L<change>.

C<FIELD_VALUES> is a reference to a HASH which contains field/value
pairs which will be passed to the Nameserver and will be used to 
initialize the new entry.

The alternative syntax is to pass a string instead of a reference, for example

    $r = $ph->add('name=myname phone=myphone');

C<FIELD_VALUES> is a string that consists of field/value pairs which the
new entry will contain. The strings being passed should B<not> contain any
carriage returns, or else the query command might fail or return invalid data.


=item delete( FIELD_VALUES )

    $r = $ph->delete('name=myname phone=myphone');

This method is used to delete existing entries from the Nameserver database.
You must successfully call L<login> before this method can be used.

B<Note> that this method deletes entries to the database. To modify
an existing entry use L<change>.

C<FIELD_VALUES> is a string that serves as the search criteria for the
records to be deleted. Any entry in the database which matches this search 
criteria will be deleted.

=item id( [ ID ] )

    $r = $ph->id('709');

Sends C<ID> to the Nameserver, which will enter this into its
logs. If C<ID> is not given then the UID of the user running the
process will be sent.

=item status()

Returns the current status of the Nameserver.

=item siteinfo()

    $siteinfo = $ph->siteinfo();
    foreach $field (keys %{$siteinfo}) {
        $c = ${$siteinfo}{$field}->code;
        $v = ${$siteinfo}{$field}->value;
        $f = ${$siteinfo}{$field}->field;
        $t = ${$siteinfo}{$field}->text;
        print "field:[$field] [$c][$v][$f][$t]\n";
    }

Returns a reference to a HASH containing information about the server's 
site. The keys of the HASH are the field names and values are
C<Net::PH:Result> objects (I<code>, I<value>, I<field>, I<text>).

=item quit()

    $r = $ph->quit();

Quit the connection

=back

=head1 Q&A

How do I get the values of a Net::PH::Result object?

    foreach $handle (@{$q}) {
        foreach $field (keys %{$handle}) {
            $my_code  = ${$q}{$field}->code;
            $my_value = ${$q}{$field}->value;
            $my_field = ${$q}{$field}->field;
            $my_text  = ${$q}{$field}->text;
        }
    }

How do I get a count of the returned matches to my query?

    $my_count = scalar(@{$query_result});

How do I get the status code and message of the last C<$ph> command?

    $status_code    = $ph->code;
    $status_message = $ph->message;

=head1 SEE ALSO

L<Net::Cmd>

=head1 AUTHORS

Graham Barr <gbarr@pobox.com>
Alex Hristov <hristov@slb.com>

=head1 ACKNOWLEDGMENTS

Password encryption code ported to perl by Broc Seib <bseib@purdue.edu>,
Purdue University Computing Center.

Otis Gospodnetic <otisg@panther.middlebury.edu> suggested
passing parameters as string constants. Some queries cannot be 
executed when passing parameters as string references.

        Example: query first_name last_name email="*.domain"

=head1 COPYRIGHT

The encryption code is based upon cryptit.c, Copyright (C) 1988 by
Steven Dorner, and Paul Pomes, and the University of Illinois Board
of Trustees, and by CSNET.

All other code is Copyright (c) 1996-1997 Graham Barr <gbarr@pobox.com>
and Alex Hristov <hristov@slb.com>. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
