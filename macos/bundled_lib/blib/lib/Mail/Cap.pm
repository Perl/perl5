#

package Mail::Cap;
use strict;

use vars qw($VERSION $useCache);

$VERSION = "1.07";
sub Version { $VERSION; }

=head1 NAME

Mail::Cap - Parse mailcap files

=head1 SYNOPSIS

    my $mc = new Mail::Cap;

    $desc = $mc->description('image/gif');

    print "GIF desc: $desc\n";

    $cmd = $mc->viewCmd('text/plain; charset=iso-8859-1', 'file.txt');

=head1 DESCRIPTION

Parse mailcap files as specified in RFC 1524 - I<A User Agent
Configuration Mechanism For Multimedia Mail Format Information>.  In
the description below C<$type> refers to the MIME type as specified in
the I<Content-Type> header of mail or HTTP messages.  Examples of
types are:

  image/gif
  text/html
  text/plain; charset=iso-8859-1

=cut

$useCache = 1;  # don't evaluate tests every time

my @path;

if($^O eq "MacOS") {
    @path = split(/,/, $ENV{MAILCAPS} ||
	"$ENV{HOME}mailcap");
} else {
    @path = split(/:/, $ENV{MAILCAPS} ||
	# this path is specified under RFC 1524 appendix A 
	( defined($ENV{HOME})
	  ? "$ENV{HOME}/.mailcap:/etc/mailcap:/usr/etc/mailcap:/usr/local/etc/mailcap"
	  : "/etc/mailcap:/usr/etc/mailcap:/usr/local/etc/mailcap"));
}


=head1 METHODS

=head2 new()

  $mcap = new Mail::Cap;
  $mcap = new Mail::Cap "/mydir/mailcap";

Create and initialize a new Mail::Cap object.  If you give it an
argument it will try to parse the specified file.  Without any
arguments it will search for the mailcap file using the standard
mailcap path, or the MAILCAPS environment variable if it is defined.

=cut

sub new
{
    my($class, $file) = @_;
    unless (defined $file) {
	for (@path) {
	    if (-r $_) {
		$file = $_;
		last;
	    }
	}
    }
    my $self = bless {}, $class;
    local *MAILCAP;
    if (defined $file && open(MAILCAP, $file)) {
	$self->{'_file'} = $file;
      local($_);
	while (<MAILCAP>) {
	    next if /^\s*#/; # comment
	    next if /^\s*$/; # blank line
	    while (s/\\\s*$//) {  # continuation line
		$_ .= <MAILCAP>;
	    }
	    chomp;
	    s/\0//g;            # ensure no NULs in the line
	    s/([^\\]);/$1\0/g;  # make field separator NUL
	    my @parts = split(/\s*\0\s*/, $_);
	    my $type = shift(@parts);
	    $type .= "/*" unless $type =~ m,/,;
	    my $view = shift(@parts);
	    $view =~ s/\\;/;/g;
	    my %field = ('view' => $view);
	    for (@parts) {
		my($key,$val) = split(/\s*=\s*/, $_, 2);
		if (defined $val) {
		    $val =~ s/\\;/;/g;
		} else {
		    $val = 1;
		}
		$field{$key} = $val;
	    }
	    if ($field{'test'}) {
		my $test = $field{'test'};
		unless ($test =~ /%/) {
		    # No parameters in test, can perform it right away
		    system $test;
		    next if $?;
		}
	    }
	    # record this entry
	    unless (exists $self->{$type}) {
		$self->{$type} = [];
	    }
	    push(@{$self->{$type}}, \%field);
	}
	close(MAILCAP);
    } else {
	# Set up default mailcap
      $self->{'audio/*'} = [{'view' => "showaudio %s"}];
      $self->{'image/*'} = [{'view' => "xv %s"}];
      $self->{'message/rfc822'} = [{'view' => "xterm -e metamail %s"}];
    }
    $self;
}

=head2 view($type, $file)

=head2 compose($type, $file)

=head2 edit($type, $file)

=head2 print($type, $file)

These methods invoke a suitable progam presenting or manipulating the
media object in the specified file.  They all return C<1> if a command
was found, and C<0> otherwise.  You might test C<$?> for the outcome
of the command.

=cut

sub view       { my $self = shift; $self->_run($self->viewCmd(@_));    }
sub compose    { my $self = shift; $self->_run($self->composeCmd(@_)); }
sub edit       { my $self = shift; $self->_run($self->editCmd(@_));    }
sub print      { my $self = shift; $self->_run($self->printCmd(@_));   }

=head2 viewCmd($type, $file)

=head2 composeCmd($type, $file)

=head2 editCmd($type, $file)

=head2 printCmd($type, $file)

These methods return a string that is suitable for feeding to system()
in order to invoke a suitable progam presenting or manipulating the
media object in the specified file.  It will return C<undef> if no
suitable specification exists.

=cut

sub viewCmd    { shift->_createCommand('view', @_);    }
sub composeCmd { shift->_createCommand('compose', @_); }
sub editCmd    { shift->_createCommand('edit', @_);    }
sub printCmd   { shift->_createCommand('print', @_);   }

sub _createCommand
{
    my($self, $method, $type, $file) = @_;
    my $entry = $self->getEntry($type, $file);
    return undef unless $entry;
    if (exists $entry->{$method}) {
	return $self->expandPercentMacros($entry->{$method}, $type, $file);
    } else {
	return undef;
    }
}

sub _run
{
    my($self, $cmd) = @_;
    if (defined $cmd) {
	system $cmd;
	return 1;
    }
    0;
}

sub makeName
{
    my($self, $type, $basename) = @_;
    my $template = $self->nametemplate($type);
    return $basename unless $template;
    $template =~ s/%s/$basename/g;
    $template;
}

=head2 field($type, $field)

Returns the specified field for the type.  Returns undef if no
specification exsists.

=cut

sub field
{
    my($self, $type, $field) = @_;
    my $entry = $self->getEntry($type);
    $entry->{$field};
}

=head2 description($type)

=head2 textualnewlines($type)

=head2 x11_bitmap($type)

=head2 nametemplate($type)

These methods return the corresponding mailcap field for the type.
These methods should be more convenient to use than the field() method
for the same fields.

=cut

sub description     { shift->field(shift, 'description');     }
sub textualnewlines { shift->field(shift, 'textualnewlines'); }
sub x11_bitmap      { shift->field(shift, 'x11-bitmap');      }
sub nametemplate    { shift->field(shift, 'nametemplate');    }

sub getEntry
{
    my($self, $origtype, $file) = @_;

    if ($useCache) {
	if (exists $self->{'_cache'}{$origtype}) {
	    return $self->{'_cache'}{$origtype};
	}
    }

    my($fulltype, @params) = split(/\s*;\s*/, $origtype);
    my($type, $subtype) = split(/\//, $fulltype, 2);
    $subtype = "" unless defined $subtype;

    my $entry;
    for (@{$self->{"$type/$subtype"}}, @{$self->{"$type/*"}}) {
	if (exists $_->{'test'}) {
	    # must run test to see if it applies
	    my $test = $self->expandPercentMacros($_->{'test'},
						  $origtype, $file);
	    system $test;
	    next if $?;
	}
	$entry = { %$_ };  # make copy
        last;
    }
    $self->{'_cache'}{$origtype} = $entry if $useCache;
    $entry;
}


sub expandPercentMacros
{
    my($self,$text,$type,$file) = @_;
    return $text unless defined $type;
    $file = "" unless defined $file;
    my($fulltype, @params) = split(/\s*;\s*/, $type);
    my $subtype;
    ($type, $subtype) = split(/\//, $fulltype, 2);
    my %params;
    for (@params) {
	my($key,$val) = split(/\s*=\s*/, $_, 2);
	$params{$key} = $val;
    }
    $text =~ s/\\%/\0/g;  # hide all escaped %'s
    $text =~ s/%t/$fulltype/g;  # expand %t
    $text =~ s/%s/$file/g;      # expand %s
    {                           # expand %{field}
	local($^W) = 0;  # avoid warnings when expanding %params
	$text =~ s/%\{\s*(.*?)\s*\}/$params{$1}/g;
    }
    $text =~ s/\0/%/g;
    $text;
}

# This following procedures can be useful for debugging purposes

sub dumpEntry
{
    my($hash, $prefix) = @_;
    $prefix = "" unless defined $prefix;
    for (sort keys %$hash) {
	print "$prefix$_ = $hash->{$_}\n";
    }
}

sub dump
{
    my($self) = @_;
    for (keys %$self) {
	next if /^_/;
	print "$_\n";
	for (@{$self->{$_}}) {
	    dumpEntry($_, "\t");
	    print "\n";
	}
    }
    if (exists $self->{'_cache'}) {
	print "Cached types\n";
	for (keys %{$self->{'_cache'}}) {
	    print "\t$_\n";
	}
    }
}

=head1 COPYRIGHT

Copyright (c) 1995 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Gisle Aas <aas@oslonett.no> 

Maintained by Graham Barr <gbarr@pobox.com>

=cut


1;
