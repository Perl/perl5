# Copyright (c) 1999 David Schooley.  All rights reserved.  This program is 
# free software; you can redistribute it and/or modify it under the same 
# terms as Perl itself.


package Mac::AETE::Dialect;

=head1 NAME

Mac::AETE::Dialect - reads the Macintosh Apple event dictionary from an 
Applescript dialect file.


=head1 SYNOPSIS

     use Mac::AETE::App;
     use Mac::AETE::Dialect;
     use Mac::AETE::Format::Dictionary;

     $aeut = Dialect->new();
     $aeut->read();
     
     $app = App->new("My Application");
     $formatter = Dictionary->new;
     $app->set_format($formatter);
     $app->read;
     $app->merge($aeut);
     $app->write;


=head1 DESCRIPTION

The data in Dialect objects can be merged into a Parser or App object 
to make a complete Apple event dictionary. The module will locate the proper
AppleScript dialect file in the system folder.

See Mac::AETE::Parser and Mac::AETE::App for more details.

=head2 Methods

=over 10

=item new

Example:

     use Mac::AETE::Dialect;
     
     $app = Dialect->new;

=item read

(Inherited from Mac::AETE::Parser.)

Reads the data contained in the AETE resource or handle. Example:
     
     $app->read;

=back

=head1 INHERITANCE

Inherits from Mac::AETE::Parser.

=head1 AUTHOR

David Schooley <F<dcschooley@mediaone.net>>

=cut

use strict;
use Mac::AETE::Parser;
use Mac::Memory;
use Mac::Resources;
use Mac::MoreFiles;
use Mac::Files;

use Carp;

@Mac::AETE::Dialect::ISA = qw (Mac::AETE::Parser);

sub _filter
{
    my ($spec, $data) = @_;
    my ($creator, $type);
    my $return_value = 0;
    
    ($creator, $type) = MacPerl::GetFileInfo($spec);
    
    if ($creator && $type && $creator eq 'ascr' && $type eq 'dlct') {
        $$data = $spec;
	$return_value = 1;
    }
    $return_value;
}

sub new {
    my ($type, $dialect_file) = @_;
    my ($data, $path, $ref);
    my $self;
    
    if (!defined $dialect_file) {
        $path = FindFolder(kOnSystemDisk, kExtensionFolderType , kDontCreateFolder) || croak("Couldn't find the extensions folder");	
	$ref = \&_filter;
	FSpIterateDirectory($path, 2, $ref, \$dialect_file);

	if (!$dialect_file) {
	     $path = FindFolder(kOnSystemDisk, kSystemFolderType , kDontCreateFolder) || croak("Couldn't find the system folder");
	     FSpIterateDirectory($path, 3, $ref, \$dialect_file);
	}
    }
    if ($dialect_file) {
	my $RF = OpenResFile($dialect_file);
	if (!defined($RF) || $RF == 0) {
	    croak("No Resource Fork available for $dialect_file");
	}
	my $aete_handle = Get1Resource("aeut", 0);
	if (!defined($aete_handle) || $aete_handle == 0) {
	    croak("Application is not scriptable");
	}
        $self = Mac::AETE::Parser->new($aete_handle, $dialect_file);
	$self->{_resource_fork} = $RF;
    } else {
	croak("Couldn't find a dialect file");
    }
    return bless $self, $type;
}

sub DESTROY {
    my $self = shift;
    CloseResFile $self->{_resource_fork} if defined $self->{_resource_fork};
}


sub init
{
    my ($self) = @_;
    
    $self->{_handle_index} = 0;
    my $RF = OpenResFile($self->{_target});
    if ( !defined($RF) || $RF == 0) {
	croak("No Resource Fork available for $self->{_target}");
    }
    $self->{_resource_fork} = $RF;
    my $aete_handle = GetResource("aeut", 0);
    if (!defined($aete_handle) || $aete_handle == 0) {
	croak("Application is not scriptable");
    }
    $self->{_resource} = $aete_handle;
    $self->{_inited} = 1;

    $DB::single = 1;
}


1;
