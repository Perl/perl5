package Mac::AETE::Format::Dictionary;


sub new {
    my $type = shift;
    my $target = shift;
    my $self = {};
    return bless $self, $type;
}

@req = qw(optional required);

@list = qw(single list);
@enum = qw(non-enum enumerated);
@rdonly = qw(read-only read-write);
@change = qw(no-change change);

sub write_title
{
    my ($self, $title) = @_;
    print "Title: $title\n";
}

sub write_version
{
    my ($self, $version) = @_;
    print "Version: $version\n";
}


sub start_suite
{
    my ($self, $name, $desc, $id) = @_;
    
    print <<"EOT"

============================================================
Suite: $name, $desc
============================================================
Suite ID: '$id'

EOT

}

sub end_suite
{
    print "\n";
}

sub start_event
{
    my ($self, $name, $desc, $class, $id) = @_;
    
    print <<"EOT"
Event: $name, $desc
   Class: '$class'
   ID: '$id'
EOT
}

sub end_event
{
    print "\n";
}

sub write_reply
{
    my ($self, $type, $desc, $req, $list, $enum) = @_;
	    
    print <<"EOT"
   Reply: $desc
      Type: '$type'
      Flags: $req[$req], $list[$list], $enum[$enum]
EOT
}

sub write_dobj
{
    my ($self, $type, $desc, $req, $list, $enum, $change) = @_;
    
    print <<"EOT"
   Direct Object: $desc
      Type: '$type'
      Flags: $req[$req], $list[$list], $enum[$enum], $change[$change]
EOT
}

sub write_param
{
    my ($self, $name, $id, $type, $desc, $req, $list, $enum) = @_;
    
    print <<"EOT"
   Parameter: $name, $desc
      ID: '$id'
      Type: '$type'
      Flags: $req[$req], $list[$list], $enum[$enum]
EOT
}

sub begin_class
{
    my ($self, $name, $id, $desc) = @_;
    
    print <<"EOT"
Object Class: $name, $desc
   ID: '$id'
EOT
}

sub end_class
{
    print "\n\n"
}

sub write_comparison
{
    my ($self, $name, $id, $desc) = @_;
    
    print <<"EOT"

Comparision: $name, $desc
   ID: '$id'
   
EOT
}

sub write_property
{
    my ($self, $name, $id, $class, $desc, $list, $enum, $rdonly) = @_;
    
    print <<"EOT"
   Property: $name, $desc
      ID: '$id'
      Class: '$class'
      Flags: $list[$list], $enum[$enum], $rdonly[$rdonly]
EOT
}

sub write_element
{
    my ($self, $name, @keys) = @_;
    
print "   Elements: $name";

foreach (@keys) {
	print "\, \'$_\'";
   }
}

sub begin_enumeration
{
    my ($self, $id) = @_;
	    
    print <<"EOT"
Enumeration: '$id'
EOT
}

sub end_enumeration
{
    print "\n";
}

sub write_enum
{
    my ($self, $name, $id, $comment) = @_;
    
    print <<"EOT"
   $name, $comment, '$id'
EOT
}

1;
