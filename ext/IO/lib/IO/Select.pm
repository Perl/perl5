# IO::Select.pm

package IO::Select;

=head1 NAME

IO::Select - OO interface to the system select call

=head1 SYNOPSYS

    use IO::Select;

    $s = IO::Select->new();

    $s->add(\*STDIN);
    $s->add($some_handle);

    @ready = $s->can_read($timeout);

    @ready = IO::Select->new(@handles)->read(0);

=head1 DESCRIPTION

The C<IO::Select> package implements an object approach to the system C<select>
function call. It allows the user to see what IO handles, see L<IO::Handle>,
are ready for reading, writing or have an error condition pending.

=head1 CONSTRUCTOR

=over 4

=item new ( [ HANDLES ] )

The constructor create a new object and optionally initialises it with a set
of handles.

=back

=head1 METHODS

=over 4

=item add ( HANDLES )

Add the list of handles to the C<IO::Select> object. It is these values that
will be returned when an event occurs. C<IO::Select> keeps these values in a
cache which is indexed by the C<fileno> of the handle, so if more than one
handle with the same C<fileno> is specified then only the last one is cached.

=item remove ( HANDLES )

Remove all the given handles from the object.

=item can_read ( [ TIMEOUT ] )

Return an array of handles that are ready for reading. C<TIMEOUT> is the maximum
amount of time to wait before returning an empty list. If C<TIMEOUT> is
not given then the call will block.

=item can_write ( [ TIMEOUT ] )

Same as C<can_read> except check for handles that can be written to.

=item has_error ( [ TIMEOUT ] )

Same as C<can_read> except check for handles that have an error condition, for
example EOF.

=item select ( READ, WRITE, ERROR [, TIMEOUT ] )

C<select> is a static method, that is you call it with the package name
like C<new>. C<READ>, C<WRITE> and C<ERROR> are either C<undef> or
C<IO::Select> objects. C<TIMEOUT> is optional and has the same effect as
before.

The result will be an array of 3 elements, each a reference to an array
which will hold the handles that are ready for reading, writing and have
error conditions respectively. Upon error an empty array is returned.

=back

=head1 EXAMPLE

Here is a short example which shows how C<IO::Select> could be used
to write a server which communicates with several sockets while also
listening for more connections on a listen socket

    use IO::Select;
    use IO::Socket;

    $lsn = new IO::Socket::INET(Listen => 1, LocalPort => 8080);
    $sel = new IO::Select( $lsn );
    
    while(@ready = $sel->can_read) {
        foreach $fh (@ready) {
            if($fh == $lsn) {
                # Create a new socket
                $new = $lsn->accept;
                $sel->add($new);
            }
            else {
                # Process socket

                # Maybe we have finished with the socket
                $sel->remove($fh);
                $fh->close;
            }
        }
    }

=head1 AUTHOR

Graham Barr <Graham.Barr@tiuk.ti.com>

=head1 REVISION

$Revision: 1.2 $

=head1 COPYRIGHT

Copyright (c) 1995 Graham Barr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

use     strict;
use     vars qw($VERSION @ISA);
require Exporter;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

@ISA = qw(Exporter); # This is only so we can do version checking

sub new
{
 my $self = shift;
 my $type = ref($self) || $self;

 my $vec = bless [''], $type;

 $vec->add(@_)
    if @_;

 $vec;
}

sub add
{
 my $vec = shift;
 my $f;

 foreach $f (@_)
  {
   my $fn = $f =~ /^\d+$/ ? $f : fileno($f);
   next
    unless defined $fn;
   vec($vec->[0],$fn++,1) = 1;
   $vec->[$fn] = $f;
  }
}

sub remove
{
 my $vec = shift;
 my $f;

 foreach $f (@_)
  {
   my $fn = $f =~ /^\d+$/ ? $f : fileno($f);
   next
    unless defined $fn;
   vec($vec->[0],$fn++,1) = 0;
   $vec->[$fn] = undef;
  }
}

sub can_read
{
 my $vec = shift;
 my $timeout = shift;

 my $r = $vec->[0];

 select($r,undef,undef,$timeout) > 0
    ? _handles($vec, $r)
    : ();
}

sub can_write
{
 my $vec = shift;
 my $timeout = shift;

 my $w = $vec->[0];

 select(undef,$w,undef,$timeout) > 0
    ? _handles($vec, $w)
    : ();
}

sub has_error
{
 my $vec = shift;
 my $timeout = shift;

 my $e = $vec->[0];

 select(undef,undef,$e,$timeout) > 0
    ? _handles($vec, $e)
    : ();
}

sub _max
{
 my($a,$b,$c) = @_;
 $a > $b
    ? $a > $c
        ? $a
        : $c
    : $b > $c
        ? $b
        : $c;
}

sub select
{
 shift
   if defined $_[0] && !ref($_[0]);

 my($r,$w,$e,$t) = @_;
 my @result = ();

 my $rb = defined $r ? $r->[0] : undef;
 my $wb = defined $w ? $e->[0] : undef;
 my $eb = defined $e ? $w->[0] : undef;

 if(select($rb,$wb,$eb,$t) > 0)
  {
   my @r = ();
   my @w = ();
   my @e = ();
   my $i = _max(defined $r ? scalar(@$r) : 0,
                defined $w ? scalar(@$w) : 0,
                defined $e ? scalar(@$e) : 0);

   for( ; $i > 0 ; $i--)
    {
     my $j = $i - 1;
     push(@r, $r->[$i])
        if defined $r->[$i] && vec($rb, $j, 1);
     push(@w, $w->[$i])
        if defined $w->[$i] && vec($wb, $j, 1);
     push(@e, $e->[$i])
        if defined $e->[$i] && vec($eb, $j, 1);
    }

   @result = (\@r, \@w, \@e);
  }
 @result;
}

sub _handles
{
 my $vec = shift;
 my $bits = shift;
 my @h = ();
 my $i;

 for($i = scalar(@$vec) - 1 ; $i > 0 ; $i--)
  {
   next unless defined $vec->[$i];
   push(@h, $vec->[$i])
      if vec($bits,$i - 1,1);
  }
 
 @h;
}

1;
