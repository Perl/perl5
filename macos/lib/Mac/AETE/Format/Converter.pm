# Copyright (c) 1999 David Schooley.  All rights reserved.  This program is 
# free software; you can redistribute it and/or modify it under the same 
# terms as Perl itself.

package Mac::AETE::Format::Converter;

@req = qw(OPT REQ);

@list = qw(SINGLE LIST);
@enum = qw(NOENUM ENUM);
@rdonly = qw(RDONLY RDWR);
@change = qw(NOCHANGE CHANGE);

@suite_list = ();

sub new {
    my $type = shift;
    my $target = shift;
    my $self = {};
    return bless $self, $type;
}

sub write_title
{
    my ($self, $title) = @_;
   
    print "\@TITLE \"Events for $title\"\n";
}

sub write_version
{
    my ($self, $version) = @_;
    
    print "\@VERSION $version\n";
    
}

sub start_suite
{
    my ($self, $name, $desc, $id) = @_;
    
    print "\@SUITE \"$name\", \"$desc\", \'$id\'\n\n";

}

sub end_suite
{
    print "\n";
}

sub start_event
{
    my ($self, $name, $desc, $class, $id) = @_;
    
    print "\@EVENT \"$name\", \"$desc\", \'$class\', \'$id\'\n";


}

sub end_event
{
    print "\n";
}

sub write_reply
{
    my ($self, $type, $desc, $req, $list, $enum) = @_;
	    
    print "\@REPLY \'$type\', \"$desc\", $req[$req], $list[$list], $enum[$enum]\n";
}

sub write_dobj
{
    my ($self, $type, $desc, $req, $list, $enum, $change) = @_;
    
    print "\@DIRECT \'$type\', \"$desc\", $req[$req], $list[$list], $enum[$enum], $change[$change]\n";
}

sub write_param
{
    my ($self, $name, $id, $type, $desc, $req, $list, $enum) = @_;
    
    print "\@PARAM  \"$name\", \'$id\', \'$type\', \"$desc\", $req[$req], $list[$list], $enum[$enum]\n";
}

sub begin_class
{
    my ($self, $name, $id, $desc) = @_;
    
    print "\@CLASS \"$name\", \'$id\', \"$desc\"\n";
}

sub end_class
{
    print "\n"
}

sub write_property
{
    my ($self, $name, $id, $class, $desc, $list, $enum, $rdonly) = @_;
    
    print "\@PROPERTY \"$name\", \'$id\', \'$class\', \"$desc\", $list[$list], $enum[$enum], $rdonly[$rdonly]\n";
}

sub write_element
{
    my ($self, $name, @keys) = @_;
    
    print "\@ELEMENT \'$name\'";
    foreach (@keys) {
	print "\, \'$_\'";
    }
    print "\n";
}

sub begin_enumeration
{
    my ($self, $id) = @_;
	    
    print "\n\@ENUMERATION \'$id\'\n";
}

sub end_enumeration
{
    print "\n";
}

sub write_enum
{
    my ($self, $name, $id, $comment) = @_;
    
    print "\@ENUM \"$name\", \'$id\', \"$comment\"\n";
}



1;
