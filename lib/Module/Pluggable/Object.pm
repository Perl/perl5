package Module::Pluggable::Object;

use strict;
use File::Find ();
use File::Basename;
use File::Spec::Functions qw(splitdir catdir abs2rel);
use Carp qw(croak carp);
use Devel::InnerPackage;
use Data::Dumper;

sub new {
    my $class = shift;
    my %opts  = @_;

    return bless \%opts, $class;

}


sub plugins {
        my $self = shift;

        # override 'require'
        $self->{'require'} = 1 if $self->{'inner'};

        my $filename   = $self->{'filename'};
        my $pkg        = $self->{'package'};

        # automatically turn a scalar search path or namespace into a arrayref
        for (qw(search_path search_dirs)) {
            $self->{$_} = [ $self->{$_} ] if exists $self->{$_} && !ref($self->{$_});
        }




        # default search path is '<Module>::<Name>::Plugin'
        $self->{'search_path'} = ["${pkg}::Plugin"] unless $self->{'search_path'}; 


        #my %opts = %$self;


        # check to see if we're running under test
        my @SEARCHDIR = exists $INC{"blib.pm"} && $filename =~ m!(^|/)blib/! ? grep {/blib/} @INC : @INC;

        # add any search_dir params
        unshift @SEARCHDIR, @{$self->{'search_dirs'}} if defined $self->{'search_dirs'};


        my @plugins = $self->search_directories(@SEARCHDIR);

        # push @plugins, map { print STDERR "$_\n"; $_->require } list_packages($_) for (@{$self->{'search_path'}});
        
        # return blank unless we've found anything
        return () unless @plugins;


        # exceptions
        my %only;   
        my %except; 
        my $only;
        my $except;

        if (defined $self->{'only'}) {
            if (ref($self->{'only'}) eq 'ARRAY') {
                %only   = map { $_ => 1 } @{$self->{'only'}};
            } elsif (ref($self->{'only'}) eq 'Regexp') {
                $only = $self->{'only'}
            } elsif (ref($self->{'only'}) eq '') {
                $only{$self->{'only'}} = 1;
            }
        }
        

        if (defined $self->{'except'}) {
            if (ref($self->{'except'}) eq 'ARRAY') {
                %except   = map { $_ => 1 } @{$self->{'except'}};
            } elsif (ref($self->{'except'}) eq 'Regexp') {
                $except = $self->{'except'}
            } elsif (ref($self->{'except'}) eq '') {
                $except{$self->{'except'}} = 1;
            }
        }


        # remove duplicates
        # probably not necessary but hey ho
        my %plugins;
        for(@plugins) {
            next if (keys %only   && !$only{$_}     );
            next unless (!defined $only || m!$only! );

            next if (keys %except &&  $except{$_}   );
            next if (defined $except &&  m!$except! );
            $plugins{$_} = 1;
        }

        # are we instantiating or requring?
        if (defined $self->{'instantiate'}) {
            my $method = $self->{'instantiate'};
            return map { ($_->can($method)) ? $_->$method(@_) : () } keys %plugins;
        } else { 
            # no? just return the names
            return keys %plugins;
        }


}

sub search_directories {
    my $self      = shift;
    my @SEARCHDIR = @_;

    my @plugins;
    # go through our @INC
    foreach my $dir (@SEARCHDIR) {
        push @plugins, $self->search_paths($dir);
    }

    return @plugins;
}


sub search_paths {
    my $self = shift;
    my $dir  = shift;
    my @plugins;

    my $file_regex = $self->{'file_regex'} || qr/\.pm$/;


    # and each directory in our search path
    foreach my $searchpath (@{$self->{'search_path'}}) {
        # create the search directory in a cross platform goodness way
        my $sp = catdir($dir, (split /::/, $searchpath));

        # if it doesn't exist or it's not a dir then skip it
        next unless ( -e $sp && -d _ ); # Use the cached stat the second time

        my @files = $self->find_files($sp);

        # foreach one we've found 
        foreach my $file (@files) {
            # untaint the file; accept .pm only
            next unless ($file) = ($file =~ /(.*$file_regex)$/); 
            # parse the file to get the name
            my ($name, $directory) = fileparse($file, $file_regex);

            $directory = abs2rel($directory, $sp);
            # then create the class name in a cross platform way
            $directory =~ s/^[a-z]://i if($^O =~ /MSWin32|dos/);       # remove volume
            if ($directory) {
                ($directory) = ($directory =~ /(.*)/);
            } else {
                $directory = "";
            }
            my $plugin = join "::", splitdir catdir($searchpath, $directory, $name);

            next unless $plugin =~ m!(?:[a-z\d]+)[a-z\d]!i;

            my $err = $self->handle_finding_plugin($plugin);
            carp "Couldn't require $plugin : $err" if $err;
             
            push @plugins, $plugin;
        }

        # now add stuff that may have been in package
        # NOTE we should probably use all the stuff we've been given already
        # but then we can't unload it :(
        push @plugins, $self->handle_innerpackages($searchpath) unless (exists $self->{inner} && !$self->{inner});
    } # foreach $searchpath

    return @plugins;
}

sub handle_finding_plugin {
    my $self   = shift;
    my $plugin = shift;

    return unless (defined $self->{'instantiate'} || $self->{'require'}); 
    $self->_require($plugin);
}

sub find_files {
    my $self         = shift;
    my $search_path  = shift;
    my $file_regex   = $self->{'file_regex'} || qr/\.pm$/;


    # find all the .pm files in it
    # this isn't perfect and won't find multiple plugins per file
    #my $cwd = Cwd::getcwd;
    my @files = ();
    { # for the benefit of perl 5.6.1's Find, localize topic
        local $_;
        File::Find::find( { no_chdir => 1, 
                           wanted => sub { 
                             # Inlined from File::Find::Rule C< name => '*.pm' >
                             return unless $File::Find::name =~ /$file_regex/;
                             (my $path = $File::Find::name) =~ s#^\\./##;
                             push @files, $path;
                           }
                      }, $search_path );
    }
    #chdir $cwd;
    return @files;

}

sub handle_innerpackages {
    my $self = shift;
    my $path = shift;
    my @plugins;


    foreach my $plugin (Devel::InnerPackage::list_packages($path)) {
        my $err = $self->handle_finding_plugin($plugin);
        #next if $err;
        #next unless $INC{$plugin};
        push @plugins, $plugin;
    }
    return @plugins;

}


sub _require {
    my $self = shift;
    my $pack = shift;
    local $@;
    eval "CORE::require $pack";
    return $@;
}


1;

=pod

=head1 NAME

Module::Pluggable::Object - automatically give your module the ability to have plugins

=head1 SYNOPSIS


Simple use Module::Pluggable -

    package MyClass;
    use Module::Pluggable::Object;
    
    my $finder = Module::Pluggable::Object->new(%opts);
    print "My plugins are: ".join(", ", $finder->plugins)."\n";

=head1 DESCRIPTION

Provides a simple but, hopefully, extensible way of having 'plugins' for 
your module. Obviously this isn't going to be the be all and end all of
solutions but it works for me.

Essentially all it does is export a method into your namespace that 
looks through a search path for .pm files and turn those into class names. 

Optionally it instantiates those classes for you.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYING

Copyright, 2006 Simon Wistow

Distributed under the same terms as Perl itself.

=head1 BUGS

None known.

=head1 SEE ALSO

L<Module::Pluggable>

=cut 

