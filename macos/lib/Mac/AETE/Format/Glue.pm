package Mac::AETE::Format::Glue;
use Data::Dumper;
use Fcntl;
use File::Basename;
use File::Path;
use Mac::AETE::Parser;
use Mac::Glue;
use MLDBM ('DB_File', $Mac::Glue::SERIALIZER);

use strict;
use vars qw(@ISA $VERSION $TYPE);

$TYPE = 'McPp';

@ISA = qw(Mac::AETE::Parser);
$VERSION = '0.32';

sub fixname {
    (my $ev = shift) =~ s/[^a-zA-Z0-9_]/_/g;
    $ev =~ s/^_+//;
    $ev =~ s/_+$//;
    return $ev;
}

sub doc_enums {
    my $self = shift;
    my($text, %n, %d);
    return unless exists $self->{N};

    $text = "=head2 Enumerations\n\n=over 4\n\n";
    %n = %{$self->{N }};
    %d = %{$self->{DN}};

    foreach my $n (sort keys %n) {
        $text .= "=item '$n'\n\n=over 4\n\n";
        foreach my $e (keys %{$n{$n}}) {
            $text .= sprintf("=item %s (%s)%s\n\n", $e, $n{$n}{$e}{id},
                $n{$n}{$e}{desc} ne '' ? "\n\n$n{$n}{$e}{desc}" : '');
        }
        $text .= "=back\n\n";
    }

    $text .= "=back\n\n";
    return $text;
}

sub doc_events {
    my($self, $text, %e, %d) = $_[0];
    return unless exists $self->{E};

    $text = "=head2 Events\n\n=over 4\n\n";
    %e = %{$self->{E }};
    %d = %{$self->{DE}};
    foreach my $e (sort keys %e) {
        my($d, $p, %p);
        $d = $e{$e}{params}{'----'}[1] if $e{$e}{params}{'----'}[1] ne 'null';
        %p = map {($_, $e{$e}{params}{$_})} keys %{$e{$e}{params}};
        my $dobj = delete $p{'----'};

        my @keys = sort keys %p;
        @keys = sort {
            $b->[4] <=> $a->[4]
                    ||
            $a->[0] cmp $b->[0]
        } map {[
            $_, $d{$e}{params}{$_}, @{$e{$e}{params}{$_}}
        ]} @keys;

        my $req;
        $p = join ', ', map {
            $req += !$_->[4];
            ($req == 1? '[' : '') . "$_->[0] => $p{$_->[0]}[1]"
        } @keys;
        $p .= ']' if $req;

        unshift @keys,
            ['----', $d{$e}{params}{'----'}, @{$e{$e}{params}{'----'}}]
            if $dobj;

        $text .= sprintf("=item \$obj->%s(%s%s%s)\n\n%s\n\n%s",
            $e, ($d ? $d : ''), ($p && $d ? ', ' : ''),
            ($p ? $p : ''), "$d{$e}{desc} ($e{$e}{class}/$e{$e}{event})",
            ($e{$e}{reply}[1] ? "Reply type: $e{$e}{reply}[0]\n\n" : ''));

        if ($d || $p) {
            $text .= "Parameters:\n\n";
            $text .= join '', map {
                my $x = $_->[0] eq '----' ? 'direct object' : $_->[0];
                    "    $x ($_->[2]): $_->[1]\n"
                } @keys;
            $text .= "\n";
        }
        $text .= "\n";
    }
    $text .= "=back\n\n";
    return $text;
}

sub doc_classes {
    my($self, $text, %c, %d) = $_[0];
    $text = "=head2 Classes\n\n=over 4\n\n";
    return unless $self->{C}; 
    %c = %{$self->{C }};
    %d = $self->{DC} ? %{$self->{DC}} : ();

    foreach my $c (sort keys %c) {
        my(%p, %e, %n);
        %p = map {($_, $c{$c}{properties}{$_})} keys %{$c{$c}{properties}};
        %e = map {($_, $c{$c}{elements}{$_})}   keys %{$c{$c}{elements}};

        foreach (keys %p) {
            if (! $_ && $p{$_}[0] eq 'c@#!') {
                delete $p{$_};
            }
        }

        $text .= sprintf("=item %s (%s)%s\n\n", $c, $c{$c}{id},
            ($d{$c}{desc} ? "\n\n$d{$c}{desc}" : ''));

        if (values %p) {
            $text .= "Properties:\n\n";
            $text .= join '',
                map {
                    sprintf("    %s (%s/%s): %s%s\n", $_,
                        $c{$c}{properties}{$_}[0],
                        ($c{$c}{properties}{$_}[0] eq 'c@#^'
                            ? $self->{CLASSNAMES}{$c{$c}{properties}{$_}[1]}
                            : $c{$c}{properties}{$_}[1]),
                        $d{$c}{properties}{$_}, 
                        ($c{$c}{properties}{$_}[4] ? ' (read-only)' : '')
                    )
                } (sort keys %p);
            $text .= "\n";
        }

        if (values %e) {
            $text .= "Elements:\n\n    " . join(', ', sort
                map { exists $self->{CLASSNAMES}{$_} ? $self->{CLASSNAMES}{$_} : $_ }
                map { while (length($_) < 4) { $_ = "$_ " }; $_ }
                keys %e) . "\n\n";
        }

    }
    $text .= "=back\n\n";

    return $text;
}

sub finish {
    my($self, $nopod) = @_;
    my %dbm;

    my $path = dirname($self->{OUTPUT});
    mkpath($path);
    die "Couldn't create path: $!" unless -d $path;

    unlink $self->{OUTPUT} if $self->{DELETE};

    if (!tie %dbm, 'MLDBM', $self->{OUTPUT}, O_CREAT|O_RDWR|O_EXCL, 0640) {
        warn "Can't tie to '$self->{OUTPUT}': $!";
        return;
    }

    $dbm{ENUM}          = $self->{N};
    $dbm{CLASS}         = $self->{C};
    $dbm{EVENT}         = $self->{E};
    $dbm{COMPARISON}    = $self->{P};
    $dbm{ID}            = $self->{ID};

    MacPerl::SetFileInfo('McPL', $TYPE, $self->{OUTPUT});
    return 1 if $nopod;

    foreach (@{$self}{qw(START FINISH)}) {
        s/__APPNAME__/$self->{TITLE}/g;
        s/__APPID__/$self->{ID}/g;
    }

    local *FILE;
    my $file = $$self{OUTPUT};
    chop($file) while length(basename("$file.pod")) > 27;
    $file .= ".pod";
    unlink $file if $self->{DELETE};

    sysopen FILE, $file, O_CREAT|O_WRONLY|O_EXCL
        or die "Can't create file '$file': $!";
    MacPerl::SetFileInfo(qw(·uck TEXT), $file);

    print FILE $self->{START};
    print FILE doc_events($self);
    print FILE doc_classes($self);
    print FILE doc_enums($self);
    print FILE $self->{FINISH};

    return 1;
}

sub new {
    my $type = shift or die;
    my $output = shift or die;
    my $delete = shift;
    my $self = {OUTPUT => $output, _init()};
    $self->{DELETE} = $delete || 0;
    return bless($self, $type);
}

sub write_title {
    my($self, $title) = @_;
    $self->{ID} = (MacPerl::GetFileInfo($title))[0];
    $self->{TITLE} = basename($self->{OUTPUT});
}

sub write_version {
    my($self, $version) = @_;
    $self->{VERSION} = $version;
}

sub start_suite {
    my($self, $name, $desc, $id) = @_;
}

sub end_suite {
    my($self) = @_;
}

sub start_event {
    my($self, $name, $desc, $class, $id, $ev, $en, $c) = @_;
    $ev = lc fixname($name);
    $en = $ev;
#     $c = 2;
#     while (exists($self->{E}{$en})) {
#         $en = $ev . $c++;
#     }
    @{$self->{E }{$en}}{qw(class event desc)} = ($class, $id, $desc);
      $self->{DE}{$en}{desc}             = $desc;
    $self->{CE} = $en;
}

sub end_event {
    my($self) = @_;
    undef($self->{CE});
}

sub write_reply {
    my($self, $type, $desc, $req, $list, $enum) = @_;
    $self->{E }{$self->{CE}}{reply} = [$type, $req, $list, $enum];  # desc?
    $self->{DE}{$self->{CE}}{reply} = $desc;
}

sub write_dobj {
    my($self, $type, $desc, $req, $list, $enum, $change) = @_;
    $self->{E }{$self->{CE}}{params}{'----'} = ['----', $type, $req, $list, $enum, $change];  # desc?
    $self->{DE}{$self->{CE}}{params}{'----'} = $desc;
}

sub write_param {
    my($self, $name, $id, $type, $desc, $req, $list, $enum) = @_;
    my $ev = lc fixname($name);
    $self->{E }{$self->{CE}}{params}{$ev} = [$id, $type, $req, $list, $enum];  # desc?
    $self->{DE}{$self->{CE}}{params}{$ev} = $desc;
}

sub begin_class {
    my($self, $name, $id, $desc, $ev, $en, $c) = @_;
    $ev = lc fixname($name);
    $en = $ev;
#     $c = 2;
#     while (exists($self->{C}{$en})) {
#         $en = $ev . $c++;
#     }
    $self->{C }{$en}{id} = $id;
    $self->{C }{$en}{desc} = $desc;
    $self->{DC}{$en}{desc} = $desc;
    $self->{CC} = $en;
    $self->{CLASSNAMES}{$id} = $en unless exists $self->{CLASSNAMES}{$id};
}

sub end_class {
    my($self) = @_;
    undef($self->{CE});
}

sub write_property {
    my($self, $name, $id, $class, $desc, $list, $enum, $rdonly) = @_;
    my $ev = lc fixname($name);
    $self->{C }{$self->{CC}}{properties}{$ev} = [$id, $class, $list, $enum, $rdonly];  # desc?
    $self->{DC}{$self->{CC}}{properties}{$ev} = $desc;
}

sub end_properties {
    my($self) = @_;
}

sub write_element {
    my($self, $name, @keys) = @_;
    my $ev = lc fixname($name);
    $self->{C }{$self->{CC}}{elements}{$ev} = [@keys];
}

sub write_comparison {
    my($self, $name, $id, $desc) = @_;
    $self->{P }{$name} = [$id, $desc];
#    print "# OK\n";
}

sub begin_enumeration {
    my($self, $id) = @_;
    $self->{N}{$id} = {};
    $self->{'NE'} = $id;
}

sub end_enumeration {
    my $self = shift;
    undef $self->{'NE'};
}

sub write_enum {
    my($self, $name, $id, $desc, $ev, $en, $c) = @_;
    $en = $ev = lc fixname($name);
#     $c = 2;
#     while (exists $self->{N}{$en}) {
#         $en = $ev . $c++;
#     }

    $self->{N }{$self->{'NE'}}{$en}{id}   = $id;
    $self->{N }{$self->{'NE'}}{$en}{desc} = $desc;
    $self->{DN}{$self->{'NE'}}{$en}{desc} = $desc;
}

sub _init {
    my(%self);
    $self{START} = <<'EOT';
=head1 NAME

__APPNAME__ Glue - Control __APPNAME__ app

=head1 SYNOPSIS

    use Mac::Glue;
    my $obj = new Mac::Glue '__APPNAME__';

=head1 DESCRIPTION

See C<Mac::Glue> for complete documentation on base usage and framework.

EOT

    $self{FINISH} = <<EOT;
=head1 AUTHOR

Glue created by ${\($ENV{'USER'} || '????')}
using F<gluemac> by Chris Nandor and the Mac::AETE modules
by David C. Schooley.

Copyright (c) ${\((localtime)[5] + 1900)}.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

=head1 SEE ALSO

Mac::AppleEvents, Mac::AppleEvents::Simple, macperlcat, Inside Macintosh: 
Interapplication Communication, Mac::Glue, Mac::AETE.

=cut
EOT

    return %self;
}
1;

__END__
