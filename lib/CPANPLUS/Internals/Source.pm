package CPANPLUS::Internals::Source;

use strict;

use CPANPLUS::Error;
use CPANPLUS::Module;
use CPANPLUS::Module::Fake;
use CPANPLUS::Module::Author;
use CPANPLUS::Internals::Constants;

use Archive::Extract;

use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';
use Params::Check               qw[check];
use IPC::Cmd                    qw[can_run];
use Module::Load::Conditional   qw[can_load];

$Params::Check::VERBOSE = 1;

=pod

=head1 NAME

CPANPLUS::Internals::Source

=head1 SYNOPSIS

    ### lazy load author/module trees ###

    $cb->_author_tree;
    $cb->_module_tree;

=head1 DESCRIPTION

CPANPLUS::Internals::Source controls the updating of source files and
the parsing of them into usable module/author trees to be used by
C<CPANPLUS>.

Functions exist to check if source files are still C<good to use> as
well as update them, and then parse them.

The flow looks like this:

    $cb->_author_tree || $cb->_module_tree
        $cb->__check_trees
            $cb->__check_uptodate
                $cb->_update_source
        $cb->_build_trees
            $cb->__create_author_tree
                $cb->__retrieve_source
            $cb->__create_module_tree
                $cb->__retrieve_source
                $cb->__create_dslip_tree
                    $cb->__retrieve_source
            $cb->_save_source

    $cb->_dslip_defs

=head1 METHODS

=cut

{
    my $recurse; # flag to prevent recursive calls to *_tree functions

    ### lazy loading of module tree
    sub _module_tree {
        my $self = $_[0];

        unless ($self->{_modtree} or $recurse++ > 0) {
            my $uptodate = $self->_check_trees( @_[1..$#_] );
            $self->_build_trees(uptodate => $uptodate);
        }

        $recurse--;
        return $self->{_modtree};
    }

    ### lazy loading of author tree
    sub _author_tree {
        my $self = $_[0];

        unless ($self->{_authortree} or $recurse++ > 0) {
            my $uptodate = $self->_check_trees( @_[1..$#_] );
            $self->_build_trees(uptodate => $uptodate);
        }

        $recurse--;
        return $self->{_authortree};
    }

}

=pod

=head2 $cb->_check_trees( [update_source => BOOL, path => PATH, verbose => BOOL] )

Retrieve source files and return a boolean indicating whether or not
the source files are up to date.

Takes several arguments:

=over 4

=item update_source

A flag to force re-fetching of the source files, even
if they are still up to date.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

=cut

### retrieve source files, and returns a boolean indicating if it's up to date
sub _check_trees {
    my ($self, %hash) = @_;
    my $conf          = $self->configure_object;

    my $update_source;
    my $verbose;
    my $path;

    my $tmpl = {
        path            => { default => $conf->get_conf('base'),
                             store => \$path
                        },
        verbose         => { default => $conf->get_conf('verbose'),
                             store => \$verbose
                        },
        update_source   => { default => 0, store => \$update_source },
    };

    my $args = check( $tmpl, \%hash ) or return;

    ### if the user never wants to update their source without explicitly
    ### telling us, shortcircuit here
    return 1 if $conf->get_conf('no_update') && !$update_source;

    ### a check to see if our source files are still up to date ###
    msg( loc("Checking if source files are up to date"), $verbose );

    my $uptodate = 1; # default return value

    for my $name (qw[auth dslip mod]) {
        for my $file ( $conf->_get_source( $name ) ) {
            $self->__check_uptodate(
                file            => File::Spec->catfile( $args->{path}, $file ),
                name            => $name,
                update_source   => $update_source,
                verbose         => $verbose,
            ) or $uptodate = 0;
        }
    }

    return $uptodate;
}

=pod

=head2 $cb->__check_uptodate( file => $file, name => $name, [update_source => BOOL, verbose => BOOL] )

C<__check_uptodate> checks if a given source file is still up-to-date
and if not, or when C<update_source> is true, will re-fetch the source
file.

Takes the following arguments:

=over 4

=item file

The source file to check.

=item name

The internal shortcut name for the source file (used for config
lookups).

=item update_source

Flag to force updating of sourcefiles regardless.

=item verbose

Boolean to indicate whether to be verbose or not.

=back

Returns a boolean value indicating whether the current files are up
to date or not.

=cut

### this method checks whether or not the source files we are using are still up to date
sub __check_uptodate {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;


    my $tmpl = {
        file            => { required => 1 },
        name            => { required => 1 },
        update_source   => { default => 0 },
        verbose         => { default => $conf->get_conf('verbose') },
    };

    my $args = check( $tmpl, \%hash ) or return;

    my $flag;
    unless ( -e $args->{'file'} && (
            ( stat $args->{'file'} )[9]
            + $conf->_get_source('update') )
            > time ) {
        $flag = 1;
    }

    if ( $flag or $args->{'update_source'} ) {

         if ( $self->_update_source( name => $args->{'name'} ) ) {
              return 0;       # return 0 so 'uptodate' will be set to 0, meaning no use
                              # of previously stored hashrefs!
         } else {
              msg( loc("Unable to update source, attempting to get away with using old source file!"), $args->{verbose} );
              return 1;
         }

    } else {
        return 1;
    }
}

=pod

=head2 $cb->_update_source( name => $name, [path => $path, verbose => BOOL] )

This method does the actual fetching of source files.

It takes the following arguments:

=over 4

=item name

The internal shortcut name for the source file (used for config
lookups).

=item path

The full path where to write the files.

=item verbose

Boolean to indicate whether to be verbose or not.

=back

Returns a boolean to indicate success.

=cut

### this sub fetches new source files ###
sub _update_source {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;


    my $tmpl = {
        name    => { required => 1 },
        path    => { default => $conf->get_conf('base') },
        verbose => { default => $conf->get_conf('verbose') },
    };

    my $args = check( $tmpl, \%hash ) or return;


    my $path = $args->{path};
    my $now = time;

    {   ### this could use a clean up - Kane
        ### no worries about the / -> we get it from the _ftp configuration, so
        ### it's not platform dependant. -kane
        my ($dir, $file) = $conf->_get_mirror( $args->{'name'} ) =~ m|(.+/)(.+)$|sg;

        msg( loc("Updating source file '%1'", $file), $args->{'verbose'} );

        my $fake = CPANPLUS::Module::Fake->new(
                        module  => $args->{'name'},
                        path    => $dir,
                        package => $file,
                        _id     => $self->_id,
                    );

        ### can't use $fake->fetch here, since ->parent won't work --
        ### the sources haven't been saved yet
        my $rv = $self->_fetch(
                    module      => $fake,
                    fetchdir    => $path,
                    force       => 1,
                );


        unless ($rv) {
            error( loc("Couldn't fetch '%1'", $file) );
            return;
        }

        ### `touch` the file, so windoze knows it's new -jmb
        ### works on *nix too, good fix -Kane
        ### make sure it is writable first, otherwise the `touch` will fail
        unless (chmod ( 0644, File::Spec->catfile($path, $file) ) &&
                utime ( $now, $now, File::Spec->catfile($path, $file) )) {
            error( loc("Couldn't touch %1", $file) );
        }

    }
    return 1;
}

=pod

=head2 $cb->_build_trees( uptodate => BOOL, [use_stored => BOOL, path => $path, verbose => BOOL] )

This method rebuilds the author- and module-trees from source.

It takes the following arguments:

=over 4

=item uptodate

Indicates whether any on disk caches are still ok to use.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=item use_stored

A boolean flag indicating whether or not it is ok to use previously
stored trees. Defaults to true.

=back

Returns a boolean indicating success.

=cut

### (re)build the trees ###
sub _build_trees {
    my ($self, %hash)   = @_;
    my $conf            = $self->configure_object;

    my($path,$uptodate,$use_stored);
    my $tmpl = {
        path        => { default => $conf->get_conf('base'), store => \$path },
        verbose     => { default => $conf->get_conf('verbose') },
        uptodate    => { required => 1, store => \$uptodate },
        use_stored  => { default => 1, store => \$use_stored },
    };

    my $args = check( $tmpl, \%hash ) or return undef;

    ### retrieve the stored source files ###
    my $stored      = $self->__retrieve_source(
                            path        => $path,
                            uptodate    => $uptodate && $use_stored,
                            verbose     => $args->{'verbose'},
                        ) || {};

    ### build the trees ###
    $self->{_authortree} =  $stored->{_authortree} ||
                            $self->__create_author_tree(
                                    uptodate    => $uptodate,
                                    path        => $path,
                                    verbose     => $args->{verbose},
                                );
    $self->{_modtree}    =  $stored->{_modtree} ||
                            $self->_create_mod_tree(
                                    uptodate    => $uptodate,
                                    path        => $path,
                                    verbose     => $args->{verbose},
                                );

    ### return if we weren't able to build the trees ###
    return unless $self->{_modtree} && $self->{_authortree};

    ### write the stored files to disk, so we can keep using them
    ### from now on, till they become invalid
    ### write them if the original sources weren't uptodate, or
    ### we didn't just load storable files
    $self->_save_source() if !$uptodate or not keys %$stored;

    ### still necessary? can only run one instance now ###
    ### will probably stay that way --kane
#     my $id = $self->_store_id( $self );
#
#     unless ( $id == $self->_id ) {
#         error( loc("IDs do not match: %1 != %2. Storage failed!", $id, $self->_id) );
#     }

    return 1;
}

=pod

=head2 $cb->__retrieve_source(name => $name, [path => $path, uptodate => BOOL, verbose => BOOL])

This method retrieves a I<storable>d tree identified by C<$name>.

It takes the following arguments:

=over 4

=item name

The internal name for the source file to retrieve.

=item uptodate

A flag indicating whether the file-cache is up-to-date or not.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

Returns a tree on success, false on failure.

=cut

sub __retrieve_source {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;

    my $tmpl = {
        path     => { default => $conf->get_conf('base') },
        verbose  => { default => $conf->get_conf('verbose') },
        uptodate => { default => 0 },
    };

    my $args = check( $tmpl, \%hash ) or return;

    ### check if we can retrieve a frozen data structure with storable ###
    my $storable = can_load( modules => {'Storable' => '0.0'} )
                        if $conf->get_conf('storable');

    return unless $storable;

    ### $stored is the name of the frozen data structure ###
    my $stored = $self->__storable_file( $args->{path} );

    if ($storable && -e $stored && -s _ && $args->{'uptodate'}) {
        msg( loc("Retrieving %1", $stored), $args->{'verbose'} );

        my $href = Storable::retrieve($stored);
        return $href;
    } else {
        return;
    }
}

=pod

=head2 $cb->_save_source([verbose => BOOL, path => $path])

This method saves all the parsed trees in I<storable>d format if
C<Storable> is available.

It takes the following arguments:

=over 4

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

Returns true on success, false on failure.

=cut

sub _save_source {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;


    my $tmpl = {
        path     => { default => $conf->get_conf('base'), allow => DIR_EXISTS },
        verbose  => { default => $conf->get_conf('verbose') },
        force    => { default => 1 },
    };

    my $args = check( $tmpl, \%hash ) or return;

    my $aref = [qw[_modtree _authortree]];

    ### check if we can retrieve a frozen data structure with storable ###
    my $storable;
    $storable = can_load( modules => {'Storable' => '0.0'} )
                    if $conf->get_conf('storable');
    return unless $storable;

    my $to_write = {};
    foreach my $key ( @$aref ) {
        next unless ref( $self->{$key} );
        $to_write->{$key} = $self->{$key};
    }

    return unless keys %$to_write;

    ### $stored is the name of the frozen data structure ###
    my $stored = $self->__storable_file( $args->{path} );

    if (-e $stored && not -w $stored) {
        msg( loc("%1 not writable; skipped.", $stored), $args->{'verbose'} );
        return;
    }

    msg( loc("Writing compiled source information to disk. This might take a little while."),
	    $args->{'verbose'} );

    my $flag;
    unless( Storable::nstore( $to_write, $stored ) ) {
        error( loc("could not store %1!", $stored) );
        $flag++;
    }

    return $flag ? 0 : 1;
}

sub __storable_file {
    my $self = shift;
    my $conf = $self->configure_object;
    my $path = shift or return;

    ### check if we can retrieve a frozen data structure with storable ###
    my $storable = $conf->get_conf('storable')
                        ? can_load( modules => {'Storable' => '0.0'} )
                        : 0;

    return unless $storable;
    
    ### $stored is the name of the frozen data structure ###
    ### changed to use File::Spec->catfile -jmb
    my $stored = File::Spec->rel2abs(
        File::Spec->catfile(
            $path,                          #base dir
            $conf->_get_source('stored')    #file
            . '.' .
            $Storable::VERSION              #the version of storable 
            . '.stored'                     #append a suffix
        )
    );

    return $stored;
}

=pod

=head2 $cb->__create_author_tree([path => $path, uptodate => BOOL, verbose => BOOL])

This method opens a source files and parses its contents into a
searchable author-tree or restores a file-cached version of a
previous parse, if the sources are uptodate and the file-cache exists.

It takes the following arguments:

=over 4

=item uptodate

A flag indicating whether the file-cache is uptodate or not.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

Returns a tree on success, false on failure.

=cut

sub __create_author_tree() {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;


    my $tmpl = {
        path     => { default => $conf->get_conf('base') },
        verbose  => { default => $conf->get_conf('verbose') },
        uptodate => { default => 0 },
    };

    my $args = check( $tmpl, \%hash ) or return;
    my $tree = {};
    my $file = File::Spec->catfile(
                                $args->{path},
                                $conf->_get_source('auth')
                            );

    msg(loc("Rebuilding author tree, this might take a while"),
        $args->{verbose});

    ### extract the file ###
    my $ae      = Archive::Extract->new( archive => $file ) or return;
    my $out     = STRIP_GZ_SUFFIX->($file);

    ### make sure to set the PREFER_BIN flag if desired ###
    {   local $Archive::Extract::PREFER_BIN = $conf->get_conf('prefer_bin');
        $ae->extract( to => $out )                              or return;
    }

    my $cont    = $self->_get_file_contents( file => $out ) or return;

    ### don't need it anymore ###
    unlink $out;

    for ( split /\n/, $cont ) {
        my($id, $name, $email) = m/^alias \s+
                                    (\S+) \s+
                                    "\s* ([^\"\<]+?) \s* <(.+)> \s*"
                                /x;

        $tree->{$id} = CPANPLUS::Module::Author->new(
            author  => $name,           #authors name
            email   => $email,          #authors email address
            cpanid  => $id,             #authors CPAN ID
            _id     => $self->_id,    #id of this internals object
        );
    }

    return $tree;

} #__create_author_tree

=pod

=head2 $cb->_create_mod_tree([path => $path, uptodate => BOOL, verbose => BOOL])

This method opens a source files and parses its contents into a
searchable module-tree or restores a file-cached version of a
previous parse, if the sources are uptodate and the file-cache exists.

It takes the following arguments:

=over 4

=item uptodate

A flag indicating whether the file-cache is up-to-date or not.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

Returns a tree on success, false on failure.

=cut

### this builds a hash reference with the structure of the cpan module tree ###
sub _create_mod_tree {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;


    my $tmpl = {
        path     => { default => $conf->get_conf('base') },
        verbose  => { default => $conf->get_conf('verbose') },
        uptodate => { default => 0 },
    };

    my $args = check( $tmpl, \%hash ) or return undef;
    my $file = File::Spec->catfile($args->{path}, $conf->_get_source('mod'));

    msg(loc("Rebuilding module tree, this might take a while"),
        $args->{verbose});


    my $dslip_tree = $self->__create_dslip_tree( %$args );

    ### extract the file ###
    my $ae      = Archive::Extract->new( archive => $file ) or return;
    my $out     = STRIP_GZ_SUFFIX->($file);

    ### make sure to set the PREFER_BIN flag if desired ###
    {   local $Archive::Extract::PREFER_BIN = $conf->get_conf('prefer_bin');
        $ae->extract( to => $out )                              or return;
    }

    my $cont    = $self->_get_file_contents( file => $out ) or return;

    ### don't need it anymore ###
    unlink $out;

    my $tree = {};
    my $flag;

    for ( split /\n/, $cont ) {

        ### quick hack to read past the header of the file ###
        ### this is still rather evil... fix some time - Kane
        $flag = 1 if m|^\s*$|;
        next unless $flag;

        ### skip empty lines ###
        next unless /\S/;
        chomp;

        my @data = split /\s+/;

        ### filter out the author and filename as well ###
        ### authors can apparently have digits in their names,
        ### and dirs can have dots... blah!
        my ($author, $package) = $data[2] =~
                m|  [A-Z\d-]/
                    [A-Z\d-]{2}/
                    ([A-Z\d-]+) (?:/[\S]+)?/
                    ([^/]+)$
                |xsg;

        ### remove file name from the path
        $data[2] =~ s|/[^/]+$||;


        unless( $self->author_tree($author) ) {
            error( loc( "No such author '%1' -- can't make module object " .
                        "'%2' that is supposed to belong to this author",
                        $author, $data[0] ) );
            next;
        }

        ### adding the dslip info
        ### probably can use some optimization
        my $dslip;
        for my $item ( qw[ statd stats statl stati statp ] ) {
            ### checking if there's an entry in the dslip info before
            ### catting it on. appeasing warnings this way
            $dslip .=   $dslip_tree->{ $data[0] }->{$item}
                            ? $dslip_tree->{ $data[0] }->{$item}
                            : ' ';
        }

        ### Every module get's stored as a module object ###
        $tree->{ $data[0] } = CPANPLUS::Module->new(
                module      => $data[0],            # full module name
                version     => ($data[1] eq 'undef' # version number 
                                    ? '0.0' 
                                    : $data[1]), 
                path        => File::Spec::Unix->catfile(
                                    $conf->_get_mirror('base'),
                                    $data[2],
                                ),          # extended path on the cpan mirror,
                                            # like /A/AB/ABIGAIL
                comment     => $data[3],    # comment on the module
                author      => $self->author_tree($author),
                package     => $package,    # package name, like
                                            # 'foo-bar-baz-1.03.tar.gz'
                description => $dslip_tree->{ $data[0] }->{'description'},
                dslip       => $dslip,
                _id         => $self->_id,  #id of this internals object
        );

    } #for

    return $tree;

} #_create_mod_tree

=pod

=head2 $cb->__create_dslip_tree([path => $path, uptodate => BOOL, verbose => BOOL])

This method opens a source files and parses its contents into a
searchable dslip-tree or restores a file-cached version of a
previous parse, if the sources are uptodate and the file-cache exists.

It takes the following arguments:

=over 4

=item uptodate

A flag indicating whether the file-cache is uptodate or not.

=item path

The absolute path to the directory holding the source files.

=item verbose

A boolean flag indicating whether or not to be verbose.

=back

Will get information from the config file by default.

Returns a tree on success, false on failure.

=cut

sub __create_dslip_tree {
    my $self = shift;
    my %hash = @_;
    my $conf = $self->configure_object;

    my $tmpl = {
        path     => { default => $conf->get_conf('base') },
        verbose  => { default => $conf->get_conf('verbose') },
        uptodate => { default => 0 },
    };

    my $args = check( $tmpl, \%hash ) or return;

    ### get the file name of the source ###
    my $file = File::Spec->catfile($args->{path}, $conf->_get_source('dslip'));

    ### extract the file ###
    my $ae      = Archive::Extract->new( archive => $file ) or return;
    my $out     = STRIP_GZ_SUFFIX->($file);

    ### make sure to set the PREFER_BIN flag if desired ###
    {   local $Archive::Extract::PREFER_BIN = $conf->get_conf('prefer_bin');
        $ae->extract( to => $out )                              or return;
    }

    my $in      = $self->_get_file_contents( file => $out ) or return;

    ### don't need it anymore ###
    unlink $out;


    ### get rid of the comments and the code ###
    ### need a smarter parser, some people have this in their dslip info:
    # [
    # 'Statistics::LTU',
    # 'R',
    # 'd',
    # 'p',
    # 'O',
    # '?',
    # 'Implements Linear Threshold Units',
    # ...skipping...
    # "\x{c4}dd \x{fc}ml\x{e4}\x{fc}ts t\x{f6} \x{eb}v\x{eb}r\x{ff}th\x{ef}ng!",
    # 'BENNIE',
    # '11'
    # ],
    ### also, older versions say:
    ### $cols = [....]
    ### and newer versions say:
    ### $CPANPLUS::Modulelist::cols = [...]
    ### split '$cols' and '$data' into 2 variables ###
    ### use this regex to make sure dslips with ';' in them don't cause
    ### parser errors
    my ($ds_one, $ds_two) = ($in =~ m|.+}\s+
										(\$(?:CPAN::Modulelist::)?cols.*?)
										(\$(?:CPAN::Modulelist::)?data.*)
									|sx);

    ### eval them into existence ###
    ### still not too fond of this solution - kane ###
    my ($cols, $data);
    {   #local $@; can't use this, it's buggy -kane

        $cols = eval $ds_one;
        error( loc("Error in eval of dslip source files: %1", $@) ) if $@;

        $data = eval $ds_two;
        error( loc("Error in eval of dslip source files: %1", $@) ) if $@;

    }

    my $tree = {};
    my $primary = "modid";

    ### this comes from CPAN::Modulelist
    ### which is in 03modlist.data.gz
    for (@$data){
        my %hash;
        @hash{@$cols} = @$_;
        $tree->{$hash{$primary}} = \%hash;
    }

    return $tree;

} #__create_dslip_tree

=pod

=head2 $cb->_dslip_defs ()

This function returns the definition structure (ARRAYREF) of the
dslip tree.

=cut

### these are the definitions used for dslip info
### they shouldn't change over time.. so hardcoding them doesn't appear to
### be a problem. if it is, we need to parse 03modlist.data better to filter
### all this out.
### right now, this is just used to look up dslip info from a module
sub _dslip_defs {
    my $self = shift;

    my $aref = [

        # D
        [ q|Development Stage|, {
            i   => loc('Idea, listed to gain consensus or as a placeholder'),
            c   => loc('under construction but pre-alpha (not yet released)'),
            a   => loc('Alpha testing'),
            b   => loc('Beta testing'),
            R   => loc('Released'),
            M   => loc('Mature (no rigorous definition)'),
            S   => loc('Standard, supplied with Perl 5'),
        }],

        # S
        [ q|Support Level|, {
            m   => loc('Mailing-list'),
            d   => loc('Developer'),
            u   => loc('Usenet newsgroup comp.lang.perl.modules'),
            n   => loc('None known, try comp.lang.perl.modules'),
            a   => loc('Abandoned; volunteers welcome to take over maintainance'),
        }],

        # L
        [ q|Language Used|, {
            p   => loc('Perl-only, no compiler needed, should be platform independent'),
            c   => loc('C and perl, a C compiler will be needed'),
            h   => loc('Hybrid, written in perl with optional C code, no compiler needed'),
            '+' => loc('C++ and perl, a C++ compiler will be needed'),
            o   => loc('perl and another language other than C or C++'),
        }],

        # I
        [ q|Interface Style|, {
            f   => loc('plain Functions, no references used'),
            h   => loc('hybrid, object and function interfaces available'),
            n   => loc('no interface at all (huh?)'),
            r   => loc('some use of unblessed References or ties'),
            O   => loc('Object oriented using blessed references and/or inheritance'),
        }],

        # P
        [ q|Public License|, {
            p   => loc('Standard-Perl: user may choose between GPL and Artistic'),
            g   => loc('GPL: GNU General Public License'),
            l   => loc('LGPL: "GNU Lesser General Public License" (previously known as "GNU Library General Public License")'),
            b   => loc('BSD: The BSD License'),
            a   => loc('Artistic license alone'),
            o   => loc('other (but distribution allowed without restrictions)'),
        }],
    ];

    return $aref;
}

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:

1;
