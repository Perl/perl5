# 
# # Copyright (c) 1999 David Schooley.  All rights reserved.  This program is 
# free software; you can redistribute it and/or modify it under the same 
# terms as Perl itself.

# Data structures based on Chris Nandor's modifications to the original aeteconvert.

=head1 NAME

Mac::AETE::Parser - parses Macintosh AETE and AEUT resources.


=head1 SYNOPSIS

     use Mac::AETE::Parser;
     use Mac::AETE::Format::Dictionary;

     $aete = Parser->new($aete_handle, $name);
     $formatter = Dictionary->new;
     $aete->set_format($formatter);
     $aete->read;
     $aete->write;


=head1 DESCRIPTION

The Parser module serves as a base class for the Mac::AETE::App and Mac::AETE::Dialect modules.

=head2 Methods

=over 10

=item new

Example: ($aete_handle is a handle containing a valid AETE resource. $name is the name of the application.)

     use Mac::AETE::Parser;
     use Mac::AETE::Format::Dictionary;

     $aete = Parser->new($aete_handle, $name);

=item read

Reads the data contained in the AETE resource or handle. Example:
     
     $aete->read;
     
     
=item set_format

Sets the output formatter used during by the 'write' subroutine. Example:

     $formatter = Dictionary->new;
     $aete->set_format($formatter);
     

=item copy

Copies all suites from one Parser object into another. Example:
     
     $aete2 = Parser->new($aete_handle2, $another_name);
     $aete->copy($aete2);
     
copies the suites from $aete2 into $aete.

=item merge

Merges suites from one Parser object into another. Only the suites that exist in
both objects will be replaced. Example:

     $aete3 = Parser->new($aete_handle2, $another_name);
     $aete->merge($aete3);

=item write

Prints the contents of the AETE or AEUT resource using the current formatter.

     $aete->write;

=back

=head1 INHERITANCE

Parser does not inherit from any other modules.

=head1 AUTHOR

David Schooley <F<dcschooley@mediaone.net>>

The data structures are adapted from modifications made to the original 
aeteconvert script by Chris Nandor.

=cut

package Mac::AETE::Parser;

use Data::Dumper;
use strict;
use Mac::Memory;
use Carp;

sub new {
    my ($class, $handle, $target) = @_;
    my $self = {};
    bless $self, $class;
    
    croak("Invalid Resource") if !defined $handle || !$handle;
    
    if (ref($handle) eq 'ARRAY') {
        $self->{_handles} = $handle;
    } else {
        $self->{_handles} = [$handle];
    }
    $self->{_target} = $target;
    $self->{_suite_list} = ();

    return $self;
}

sub set_format
{
    my ($self, $format) = @_;
    
    $self->{_formatter} = $format;
}


# Copy suites from aete
sub copy
{
    my ($self, $aete) = @_;
    my ($suite_src, $suite_dest);
    
        
    foreach $suite_src (@{$aete->{_suite_list}}) {
        push @{$self->{_suite_list}}, $suite_src;
    }
}

# Replace existing suites with suites from aete2
sub merge
{
    my ($self, $aete) = @_;
    my ($suite_src, $suite_dest);
            
    foreach $suite_src (@{$aete->{_suite_list}}) {
        foreach $suite_dest (@{$self->{_suite_list}}) {
            if ($suite_dest->{_SIZE} == 0 && $suite_src->{_ID} eq $suite_dest->{_ID}) {
                %$suite_dest = %$suite_src;
            }
        }
    }
}


sub write {
    my $self = shift;

    croak("You have to assign a formatter before writing!")
        if !defined $self->{_formatter};

    my $form = $self->{_formatter};
    
    $form->write_intro if $form->can('write_intro');
    $form->write_title($self->{_target}) if $form->can('write_title');
    $form->write_version($self->{_version}) if $form->can('write_version');

    foreach my $suite (@{$self->{_suite_list}}) {
        $form->start_suite(@$suite{qw[_NAME _DESC _ID]})
            if $form->can('start_suite');
        
        foreach my $event (@{$suite->{_event_list}}) {
            my $reply = $event->{_REPLY};
            my $dobj = $event->{_DOBJ};

            $form->start_event(@{$event}{qw[_NAME _DESC _CLASS _ID]})
                     if $form->can('start_event');

            $form->write_reply(@{$reply}{qw[_TYPE _DESC _REQ _LIST _ENUM]})
                    if $form->can('write_reply');

            $form->write_dobj(@{$dobj}{qw[_TYPE _DESC _REQ _LIST _ENUM _CHANGE]})
                    if $form->can('write_dobj');

            foreach my $param (@{$event->{_param_list}}) {
                $form->write_param(
                    @{$param}{qw[_NAME _ID _TYPE _DESC _REQ _LIST _ENUM]}
                ) if $form->can('write_param');
            }
            $form->end_event if $form->can('end_event');
        }
        foreach my $class (@{$suite->{_class_list}}) {
            $form->begin_class(@{$class}{qw[_NAME _ID _DESC]})
                if $form->can('begin_class');
            $form->begin_properties if $form->can('begin_properties');
            foreach my $prop (@{$class->{_property_list}}) {
                $form->write_property(
                    @{$prop}{qw[_NAME _ID _CLASS _DESC _LIST _ENUM _RDWR]}
                ) if $form->can('write_property');
            }
            $form->end_properties if $form->can('end_properties');
            foreach my $element (@{$class->{_element_list}}) {
                $form->write_element($element->{_CLASS}, @{$element->{_ID}})
                    if $form->can('write_element');
            }
            $form->end_class if $form->can('end_class');
        }
        foreach my $comp (@{$suite->{_comparison_list}}) {
            $form->write_comparison(@{$comp}{qw[_NAME _ID _DESC]})
                if $form->can('write_comparison');
        }

        foreach my $enumeration (@{$suite->{_enumeration_list}}) {
            $form->begin_enumeration($enumeration->{_ID})
                if $form->can('begin_enumeration');
            foreach my $enum (@{$enumeration->{_enum_list}}) {
                $form->write_enum(@{$enum}{qw[_NAME _ID _COMMENT]})
                    if $form->can('write_enum');
            }
            $form->end_enumeration if $form->can('end_enumeration');
        }
        $form->end_suite if $form->can('end_suite');
    }
    $form->write_finale if $form->can('write_finale');
}

sub read {
    my $self = shift;

    for my $handle (@{$self->{_handles}}) {

        $self->{_handle} = $handle;
        $self->{_handle_index} = 0;

        my $header_data = $self->_scan(8);
        my($version, $subVersion, $language, $script, $suiteCount)
            = unpack("C C S S S", $header_data);
    
        $self->{_version}     = "$version.$subVersion"
            unless exists $self->{_version};
        $self->{_language}    = $language unless exists $self->{_language};
        $self->{_script}      = $script unless exists $self->{_script};
        $self->{_suite_count} += $suiteCount;

        for (my $i = 1; $i <= $suiteCount; $i++) {
            my($flags, %suite);
            my($suite_name, $suite_description) = $self->_get_paired_string;

            # Get the rest of the suite information
            my $suiteInfo = $self->_scan(8);
            my($suiteID, $suiteVersion, $suiteMinor) = unpack("A4 S S", $suiteInfo);

            @suite{qw[_NAME _DESC _ID _VERSION _SIZE
                _event_list _class_list _comparison_list _enum_list]} = (
                $suite_name, $suite_description, $suiteID,
                "$suiteVersion.$suiteMinor", 0
            );

            # Get the events
            my $event_count = unpack("S", $self->_scan(2));
            for (my $i = 1; $i <= $event_count; $i++) {
                my(%event, %reply, %dobj);

                $event{_param_list} = ();
                my($event_name, $event_description) = $self->_get_paired_string;

                # Get the rest of the event info
                @event{qw[_NAME _DESC _CLASS _ID]} = (
                    $event_name, $event_description, $self->_get_ID,
                    $self->_get_ID
                );
                @reply{qw[_TYPE _DESC]} = (
                    $self->_get_ID, $self->_get_string
                );

                $flags = $self->_get_binary;
                @reply{qw[_REQ _LIST _ENUM]} = (
                    ($flags & 0x8000 ? 0 : 1),
                    ($flags & 0x4000 ? 1 : 0),
                    ($flags & 0x2000 ? 1 : 0)
                );

                $event{_REPLY} = \%reply;

                # Direct object data
                @dobj{qw[_TYPE _DESC]} = (
                    $self->_get_ID, $self->_get_string
                );

                $flags = $self->_get_binary;
                @dobj{qw[_REQ _LIST _ENUM _CHANGE]} = (
                    ($flags & 0x8000 ? 0 : 1),
                    ($flags & 0x4000 ? 1 : 0),
                    ($flags & 0x2000 ? 1 : 0),
                    ($flags & 0x1000 ? 1 : 0)
                );

                $event{_DOBJ} = \%dobj;

                # Other parameter data
                my $other_count = $self->_get_item_count;
                for (my $i = 1; $i <= $other_count; $i++) {
                    my %param;

                    @param{qw[_NAME _ID _TYPE _DESC]} = (
                        $self->_get_string, $self->_get_ID,
                        $self->_get_ID, $self->_get_string
                    );

                    $flags = $self->_get_binary;
                    @param{qw[_REQ _LIST _ENUM]} = (
                        ($flags & 0x8000 ? 0 : 1),
                        ($flags & 0x4000 ? 1 : 0),
                        ($flags & 0x2000 ? 1 : 0)
                    );

                    push @{$event{_param_list}}, \%param;
                }

                push @{$suite{_event_list}}, \%event;
            }

            # Get the classes and properties
            my $class_count = $self->_get_item_count;
            for (my $i = 1; $i <= $class_count; $i++) {
                my %class;

                @class{qw[_NAME _ID _DESC
                    _property_list _element_list]} = (
                    $self->_get_string, $self->_get_ID,
                    $self->_get_string
                );

                # properties
                my $property_count = $self->_get_item_count;
                for (my $i = 1; $i <= $property_count; $i++) {
                    my %property;

                    @property{qw[_NAME _ID _CLASS _DESC]} = (
                        $self->_get_string, $self->_get_ID,
                        $self->_get_ID, $self->_get_string
                    );

                    $flags = $self->_get_binary;
                    @property{qw[_LIST _ENUM _RDWR]} = (
                        ($flags & 0x4000 ? 1 : 0),
                        ($flags & 0x2000 ? 1 : 0),
                        ($flags & 0x1000 ? 1 : 0)
                    );

                    push @{$class{_property_list}}, \%property;
                }
                
                # elements
                my $element_count = $self->_get_item_count;
                for (my $i = 1; $i <= $element_count; $i++) {
                    my(%element, @kforms);

                    $element{_CLASS} = $self->_get_ID;
                    my $kform_count = $self->_get_item_count;
                    for (my $i = 1; $i <= $kform_count; $i++) {
                        push @kforms, $self->_get_ID;
                    }
                    $element{_ID} = \@kforms;

                    push @{$class{_element_list}}, \%element;
                }

                push @{$suite{_class_list}}, \%class;
            }
        
            #comparisons
            my $compare_count = $self->_get_item_count;
            for (my $i = 1; $i <= $compare_count; $i++) {
                my %comparison;

                @comparison{qw[_NAME _ID _DESC]} = (
                    $self->_get_string, $self->_get_ID,
                    $self->_get_string
                );

                push @{$suite{_comparison_list}}, \%comparison;
            }

            #enumerations
            my $enum_count = $self->_get_item_count;
            for (my $i = 1; $i <= $enum_count; $i++) {
                my %enumeration;

                $enumeration{_ID} = $self->_get_ID;
                $enumeration{_enum_list} = ();
                my $eenum_count = $self->_get_item_count;
                for (my $i = 1; $i <= $eenum_count; $i++) {
                    my %enum;

                    @enum{qw[_NAME _ID _COMMENT]} = (
                        $self->_get_string, $self->_get_ID, 
                        $self->_get_string
                    );

                    push @{$enumeration{_enum_list}}, \%enum;
                }

                push @{$suite{_enumeration_list}}, \%enumeration;
            }

            $suite{_SIZE} += $event_count + $class_count +
                $compare_count + $enum_count;
            push @{$self->{_suite_list}}, \%suite;
        }
    }
}


#
#############################################################################
#                         Private Subroutines                               #                         
#############################################################################

sub _get_binary() {
    my $self = shift;
    my $binary = $self->_scan(2);
    $binary = hex(unpack('H4', $binary));
}

sub _get_ID() {
    my $self = shift;
    my $myID = $self->_scan(4);
    $myID;
}

sub _get_item_count() {
    my $self = shift;
    my $count = $self->_scan(2);
    $count = unpack("S", $count);
}


sub _get_string() {
    my $self = shift;
    my $length;
    $length = $self->_scan(1);
    $length = unpack("C", $length);
    my $string = $self->_scan($length);
    # Take care of alignment
    if ($self->{_handle_index} % 2 == 1) { 
        $self->{_handle_index} += 1;
    }
    $string;
}

sub _get_paired_string() {
    my $self = shift;
    my $length;
    $length = $self->_scan(1);
    $length = unpack("C", $length);
    my $string1 = $self->_scan($length);
    $length = $self->_scan(1);
    $length = unpack("C", $length);
    my $string2 = $self->_scan($length);
    # Take care of alignment
    if ($self->{_handle_index} % 2 == 1) { 
        $self->{_handle_index} += 1;
    }
    ($string1, $string2);
}

sub _scan {
    my($self, $byte_count) = @_;
    my $handle = $self->{_handle};
    my $result = $handle->get($self->{_handle_index}, $byte_count);
    $self->{_handle_index} += $byte_count;
    $result;
}

1;

__END__
