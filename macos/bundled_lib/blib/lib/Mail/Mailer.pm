#

package Mail::Mailer;

=head1 NAME

Mail::Mailer - Simple interface to electronic mailing mechanisms 

=head1 SYNOPSIS

    use Mail::Mailer;
    use Mail::Mailer qw(mail);

    $mailer = new Mail::Mailer;

    $mailer = new Mail::Mailer $type, @args;

    $mailer->open(\%headers);

    print $mailer $body;

    $mailer->close;


=head1 DESCRIPTION

Sends mail using any of the built-in methods.  You can alter the
behaviour of a method by passing C<$command> to the C<new> method.

=over 4

=item C<mail>

Use the Unix system C<mail> program to deliver the mail.  C<$command>
is the path to C<mail>.  Mail::Mailer will search for C<mailx>, C<Mail>
and C<mail> (in this order).

=item C<sendmail>

Use the C<sendmail> program to deliver the mail.  C<$command> is the
path to C<sendmail>.

=item C<smtp>

Use the C<smtp> protocol via Net::SMTP to deliver the mail. The server
to use can be specified in C<@args> with

    $mailer = new Mail::Mailer 'smtp', Server => $server;

=item C<test>

Used for debugging, this calls C</bin/echo> to display the data.  No
mail is ever sent.  C<$command> is ignored.

=back

C<Mail::Mailer> will search for executables in the above order. The
default mailer will be the first one found.

=head2 ARGUMENTS

C<new> can optionally be given a C<$command> and C<$type>.  C<$type>
is one C<sendmail>, C<mail>, ... given above.  The meaning of
C<$command> depends on C<$type>.

C<open> is given a reference to a hash.  The hash consists of key and
value pairs, the key being the name of the header field (eg, C<To>),
and the value being the corresponding contents of the header field.
The value can either be a scalar (eg, C<gnat@frii.com>) or a reference
to an array of scalars (C<eg, ['gnat@frii.com', 'Tim.Bunce@ig.co.uk']>).

=head1 TO DO

Assist formatting of fields in ...::rfc822:send_headers to ensure
valid in the face of newlines and longlines etc.

Secure all forms of send_headers() against hacker attack and invalid
contents. Especially "\n~..." in ...::mail::send_headers.

=head1 ENVIRONMENT VARIABLES

=over 4

=item PERL_MAILERS

Augments/override the build in choice for binary used to send out
our mail messages.

Format:

    "type1:mailbinary1;mailbinary2;...:type2:mailbinaryX;...:..."

Example: assume you want you use private sendmail binary instead
of mailx, one could set C<PERL_MAILERS> to:

    "mail:/does/not/exists:sendmail:$HOME/test/bin/sendmail"

=back

=head1 SEE ALSO

Mail::Send

=head1 AUTHORS

Maintained by Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

Original code written by Tim Bunce E<lt>F<Tim.Bunce@ig.co.uk>E<gt>,
with a kick start from Graham Barr E<lt>F<gbarr@pobox.com>E<gt>. With
contributions by Gerard Hickey E<lt>F<hickey@ctron.com>E<gt> Small fix
and documentation by Nathan Torkington E<lt>F<gnat@frii.com>E<gt>.

For support please contact comp.lang.perl.misc or Graham Barr
E<lt>F<gbarr@pobox.com>E<gt>

=cut

use Carp;
use IO::Handle;
use vars qw(@ISA $VERSION $MailerBinary $MailerType %Mailers @Mailers);
use Config;
use strict;

$VERSION = "1.21"; # $Id: //depot/MailTools/Mail/Mailer.pm#13 $

sub Version { $VERSION }

@ISA = qw(IO::Handle);

# Suggested binaries for types?  Should this be handled in the object class?
@Mailers = (

    # Body on stdin with tilde escapes
    'mail'	=> 	'mail',

    # Headers-blank-Body all on stdin
    'sendmail'  =>      '/usr/lib/sendmail;/usr/sbin/sendmail;/usr/ucblib/sendmail',

    'smtp'	=> 	undef,
    'test'	=> 	'test'
);

# There are several flavours of mail, which do we have ????

{
    my $cmd = is_exe('mailx;Mail;mail');
    my $osname = $Config{'osname'};

    if($osname =~ /(?:dgux)|(?:solaris)/io) {
	$cmd .= " -~";
    }
    elsif($osname =~ /(?:linux)|(?:bsdos)|(?:freebsd)/io) {
	$cmd .= " -I";
    }
    push @Mailers, 'mail', $cmd;
}

push(@Mailers, split(/:/,$ENV{PERL_MAILERS})) if $ENV{PERL_MAILERS};

%Mailers = @Mailers;

$MailerBinary = undef;

# does this really need to be done? or should a default mailer be specfied?

if($^O eq 'MacOS' || $^O eq 'VMS' || $^O eq 'MSWin32') {
    $MailerType = 'smtp';
    $MailerBinary = $Mailers{$MailerType};
}
else {
    my $i;
    for($i = 0 ; $i < @Mailers ; $i += 2) {
	$MailerType = $Mailers[$i];
	my $binary;
	if($binary = is_exe($Mailers{$MailerType})) {
	    $MailerBinary = $binary;
	    last;
	}
    }
}

sub import {
    shift;

    if(@_) {
	my $type = shift;
	my $exe = shift || $Mailers{$type};

        carp "Cannot locate '$exe'"
            unless is_exe($exe);

        $MailerType = $type;
        $Mailers{$MailerType} = $exe;
    }
}

sub to_array {
    my($self, $thing) = @_;
    if (ref($thing)) {
	return @$thing;
    } else {
	return ($thing);
    }
}

sub is_exe {
    my $exe = shift;
    my $cmd;

    foreach $cmd (split /;/, $exe) {
	$cmd =~ s/^\s+//;

	# remove any options
	my $name = ($cmd =~ /^(\S+)/)[0];

	# check for absolute or relative path
	return ($cmd)
	    if (-x $name and ! -d $name and $name =~ m:/:);

	if (defined $ENV{PATH}) {
	    my $dir;
	    foreach $dir (split(/:/, $ENV{PATH})) {
		return "$dir/$cmd"
		    if (-x "$dir/$name" && ! -d "$dir/$name");
	    }
	}
    }
    0;
}

sub new {
    my($class, $type, @args) = @_;

    $type = $MailerType unless $type;
    croak "Mailer '$type' not known, please specify correct type"
	unless $type;

    my $exe = $Mailers{$type};

    if(defined($exe)) {
	$exe = is_exe ($exe) if defined $type;

	$exe  = $MailerBinary  unless $exe;
	croak "No mailer type specified (and no default available), thus can not find executable program."
	    unless $exe;
    }

    $class = "Mail::Mailer::$type";
    eval "require $class" or die $@;
    my $glob = $class->SUPER::new; # local($glob) = gensym;	# Make glob for FileHandle and attributes

    %{*$glob} = (Exe 	=> $exe,
		 Args	=> [ @args ]
		);
    
    $glob; # bless $glob, $class;
}


sub open {
    my($self, $hdrs) = @_;
    my $exe = *$self->{Exe}; # || Carp::croak "$self->open: bad exe";
    my $args = *$self->{Args};
    _cleanup_hdrs($hdrs);
    my @to = $self->who_to($hdrs);
    
    $self->close;	# just in case;

    # Fork and start a mailer
    (defined($exe) && open($self,"|-"))
	|| $self->exec($exe, $args, \@to)
	|| die $!;

    # Set the headers
    $self->set_headers($hdrs);

    # return self (a FileHandle) ready to accept the body
    $self;
}


sub _cleanup_hdrs {
  my $hdrs = shift;
  my $h;
  foreach $h (values %$hdrs) {
    foreach (ref($h) ? @{$h} : $h) {
      s/\n//;
    }
  }
}


sub exec {
    my($self, $exe, $args, $to) = @_;
    # Fork and exec the mailer (no shell involved to avoid risks)
    my @exe = split(/\s+/,$exe);

    exec(@exe, @$args, @$to);
}

sub can_cc { 1 }	# overridden in subclass for mailer that can't

sub who_to {
    my($self, $hdrs) = @_;
    my @to = $self->to_array($hdrs->{To});
    if (!$self->can_cc) {  # Can't cc/bcc so add them to @to
	push(@to, $self->to_array($hdrs->{Cc})) if $hdrs->{Cc};
	push(@to, $self->to_array($hdrs->{Bcc})) if $hdrs->{Bcc};
    }
    @to;
}

sub epilogue {
    # This could send a .signature, also see ::smtp subclass
}

sub close {
    my($self, @to) = @_;
    if (fileno($self)) {
	$self->epilogue;
	close($self)
    }
}


sub DESTROY {
    my $self = shift;
    $self->close;
}

1;

