package perlio;
1;
__END__

=head1 NAME

perlio - perl pragma to configure C level IO

=head1 SYNOPSIS

  Shell:
    PERLIO=perlio perl ....

    print "Have ",join(',',keys %perlio::layers),"\n";
    print "Using ",join(',',@perlio::layers),"\n";


=head1 DESCRIPTION

Mainly a Place holder for now.

The C<%perlio::layers> hash is a record of the available "layers" that may be pushed
onto a C<PerlIO> stream.

The C<@perlio::layers> array is the current set of layers that are used when
a new C<PerlIO> stream is opened. The C code looks are the array each time
a stream is opened so the "stack" can be manipulated by messing with the array :

    pop(@perlio::layers);
    push(@perlio::layers,$perlio::layers{'stdio'});

The values if both the hash and the array are perl objects, of class C<perlio::Layer>
which are created by the C code in C<perlio.c>. As yet there is nothing useful you
can do with the objects at the perl level.

There are three layers currently defined:

=over 4

=item unix

Low level layer which calls C<read>, C<write> and C<lseek> etc.

=item stdio

Layer which calls C<fread>, C<fwrite> and C<fseek>/C<ftell> etc.
Note that as this is "real" stdio it will ignore any layers beneath it and
got straight to the operating system via the C library as usual.

=item perlio

This is a re-implementation of "stdio-like" buffering written as a PerlIO "layer".
As such it will call whatever layer is below it for its operations.

=back

=head2 Defaults and how to override them

If C<Configure> found out how to do "fast" IO using system's stdio, then
the default layers are :

  unix stdio

Otherwise the default layers are

  unix perlio

(STDERR will have just unix in this case as that is optimal way to make it
"unbuffered" - do not add a buffering layer!)

The default may change once perlio has been better tested and tuned.

The default can be overridden by setting the environment variable PERLIO
to a space separated list of layers (unix is always pushed first).
This can be used to see the effect of/bugs in the various layers e.g.

  cd .../perl/t
  PERLIO=stdio  ./perl harness
  PERLIO=perlio ./perl harness

=head1 AUTHOR

Nick Ing-Simmons E<lt>nick@ing-simmons.netE<gt>

=cut


