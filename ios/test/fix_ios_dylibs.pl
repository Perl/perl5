#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw 'abs_path getcwd';
use File::Find::Rule;
use File::Basename;
use File::Copy;
use File::Copy::Recursive qw(fcopy);

my $test = 0;
my $otool = "/usr/bin/otool";
my $install_name_tool = "/usr/bin/install_name_tool";

my ($PRODUCT_NAME, $TARGET_BUILD_DIR, $TARGET_NAME, $SOURCE_PREFIX, $SIGN_ID) = @ARGV;

my $SOURCE_PREFIX_REGEX = qr|^$SOURCE_PREFIX|;
my $BINARY_MATCH = qr "|^$SOURCE_PREFIX.*(?:dylib|bundle)$|";

my $TARGET_BIN_DIR = "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/";
my $TARGET_FRAMEWORK_DIR = "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/Frameworks";
my $TARGET_PERLIBDIR_DIR = "$TARGET_BUILD_DIR/$PRODUCT_NAME.app/perl5";

my $perl_dependencies = find_perl_dependencies();

for my $lib (keys %$perl_dependencies) {
    $lib = resolve_symlink($lib) if (-l $lib);
    my ($base, $dir, $ext) = fileparse($lib,'\.[^\.]*');
    
    if (!-e $TARGET_FRAMEWORK_DIR."/".$base.$ext) {
        print "fcopy: $lib\n\t$TARGET_FRAMEWORK_DIR/".$base.$ext."\n";
        exit 2;
    }
}

my @search_paths = ($TARGET_FRAMEWORK_DIR, $TARGET_BIN_DIR, $TARGET_PERLIBDIR_DIR);
my @dl_files = File::Find::Rule->file()
    ->name('*.bundle', '*.dylib', $PRODUCT_NAME) 
    ->in( @search_paths );
    
push @dl_files, $TARGET_FRAMEWORK_DIR."/CamelBones.framework/CamelBones"; 

if (!scalar @dl_files) {
    die "No dependencies found. Exiting now";
}

for my $file (@dl_files) {
    process_file_dependencies($file); 
}

for my $file(File::Find::Rule->file()->name('*.bundle')->in( $TARGET_PERLIBDIR_DIR )){
	#sign the file
	`/usr/bin/codesign --force --sign $SIGN_ID --preserve-metadata=identifier,entitlements --timestamp=none $file`;
}

my $cb_framework = $TARGET_FRAMEWORK_DIR."/CamelBones.framework/CamelBones";
`/usr/bin/codesign --force --sign $SIGN_ID --preserve-metadata=identifier,entitlements --timestamp=none $cb_framework`;

my $libperl_lib = $TARGET_FRAMEWORK_DIR."/libperl.dylib";
`/usr/bin/codesign --force --sign $SIGN_ID --preserve-metadata=identifier,entitlements --timestamp=none $libperl_lib`;

sub get_install_name {
    my $lib = shift;
    die "can't get install name. File does not exist"
        if (!-e $lib);
    my @otool_lines = split "\n", `$otool -D $lib`;
    my $install_name = $otool_lines[1];
    $install_name =~ s/\t//g
        if ($install_name);
    return $install_name;
}

sub sym_link_lib {
    my ($target,$destination) = @_;
    my $cwd = getcwd;
    chdir $TARGET_FRAMEWORK_DIR;
    eval { symlink($target,$destination); 1 };
    die $@ if $@;
    chdir $cwd; 
}

sub print_file_info {
    my $file = shift;
    print "-> $file\n";
    my $file_output = `file $file`;
    print "File information:\n$file_output";
}

sub change_dyn_id {
    my ($id, $file) = @_;
    system "chmod", "+w", $file;
    my $install_name_tool_command = "$install_name_tool -id $id $file";
    if (!$test) {
        my $install_name_tool_output = `$install_name_tool_command`;
        if (length $install_name_tool_output) {
            die "Error while changing library name for $file:\n$install_name_tool_output";
        }
        print "SUCCESS: $install_name_tool_command\n";
    } else {
        print "$install_name_tool_command\n";
    }
    system "chmod", "-w", $file;
}

sub change_dyn_path {
    my ($new, $old, $file) = @_;
    system "chmod", "+w", $file;
    my $install_name_tool_command = "$install_name_tool -change $old $new $file";
    if (!$test) {
        my $install_name_tool_output = `$install_name_tool_command`;
        if (length $install_name_tool_output) {
            die "Error while changing linked library path. Command was $install_name_tool_command";
        }
        print "SUCCESS: $install_name_tool_command\n";
    } else {
        print "$install_name_tool_command\n";
    }
    system "chmod", "-w", $file;
}

sub find_perl_dependencies {
    my @perl_bundles = File::Find::Rule->file()
        ->name('*.bundle') 
        ->in( $TARGET_PERLIBDIR_DIR );
        
    my %dependencies;
    for my $file (@perl_bundles) {
        
        chomp $file;
        
        my $install_name = get_install_name($file);
        print "Install name is: $install_name\n"
            if ($install_name);
        
        my $otool_lines = get_otool_links($file);
        foreach my $f (@$otool_lines){
            print "->Linked to: " .$f. "\n";
            $dependencies{$f} = undef if ($f =~ /$SOURCE_PREFIX_REGEX/);
        }        
    }
    
    while (1) {
        my $dep_count = scalar keys %dependencies;
        for my $d (keys %dependencies) {
            my $otool_lines = get_otool_links($d);
            foreach my $l (@$otool_lines){
                $dependencies{$l} = undef if ($l =~ /$SOURCE_PREFIX_REGEX/);
            }  
        }
        last if (scalar keys %dependencies == $dep_count);
    }    
    return \%dependencies;
}

sub get_otool_links {
    my $file = shift;
    my @otool_lines = split "\n", `$otool -L $file`;
    
    my $otool_file = shift @otool_lines;
    $otool_file =~ s/://gi;

    warn "$otool_file ne $file. otool not referencing the file read from file list"
        if ($otool_file ne $file);
    
    for my $f(@otool_lines) {
        $f =~ s/\t//g;
        $f =~ s/ \(.*//g;
    }
    return \@otool_lines;
}

sub process_file_dependencies {
    
    my $file = shift;
       
    chomp $file;
    if (!-f $file) {
        die "file '$file does not exist";
    }
    if (-l $file && $file =~ $TARGET_PERLIBDIR_DIR) {
        print "$file is symlink...\n";
        return;
    } elsif (-l $file) {
        print "$file is symlink and not on perl tree...\n";
        return;     
    }
    
    print "=======================================================\n";
    print "FILE: $file\n";
        
    my $deps = get_otool_links($file);
    
    my $install_name = get_install_name($file);
    $install_name = '' if ! $install_name;
    print "Install name is: $install_name\n";
    
    my ($base, $dir, $ext) = fileparse($file,'\.[^\.]*');
    if ($install_name && $install_name ne '@executable_path/Frameworks/'.$base.$ext) {
        change_dyn_id('@executable_path/Frameworks/'.$base.$ext, $file)
            unless (($base eq $PRODUCT_NAME) || ($file =~ /\.bundle$/));
    }    
    
    foreach my $f (@$deps){
        print "->Linked to: " .$f. "\n";
        
        if (($f =~ $BINARY_MATCH) || ($f =~ /$TARGET_FRAMEWORK_DIR/)) {
            next if ($f !~ /$SOURCE_PREFIX_REGEX/);
            my ($b, $d, $e) = fileparse($f,'\.[^\.]*');
            
            if ($b eq $PRODUCT_NAME && $file eq "$TARGET_BIN_DIR/$PRODUCT_NAME") {
                print "Main executable: $TARGET_BIN_DIR/$PRODUCT_NAME\n";
                change_dyn_path('@executable_path/Frameworks/'.$b.$e, $d.$b.$e, $file);
            } elsif (-e "$TARGET_FRAMEWORK_DIR/$b$e") {
                print "Dylib destination exists: $TARGET_FRAMEWORK_DIR/$base$ext\n";                 
                change_dyn_path('@executable_path/Frameworks/'.$b.$e, $d.$b.$e, $file);
            } else {
                print "Dylib destination does not exist: $TARGET_FRAMEWORK_DIR/$base$ext\n";

                if ($file !~ $TARGET_PERLIBDIR_DIR) {
                    my $targets_found = 0;
                    
                    if (-l $f) {
                        for my $target (@dl_files) {
                            chomp $target;
                            $b =~ s/\.[A-Z]$//;
                            print "looking for: $b in $target\n";
                            if ($target =~ m/$b/ && !(-l $target) && $b ne $PRODUCT_NAME) {
                                die "A destination for symlink must reside in $TARGET_FRAMEWORK_DIR"
                                    if ($target !~ $TARGET_FRAMEWORK_DIR);
                                my ($tb, $td, $te) = fileparse($target,'\.[^\.]*');
                                $targets_found++;
                                sym_link_lib($tb.$te, $b.$ext);
                            }
                        }
                    }
        
                    die "Found $targets_found targets for $f\n"
                        if ($targets_found != 1);
                }
                change_dyn_path('@executable_path/Frameworks/'.$b.$e, $d.$b.$e, $file);    
            }
        } else {
            print "NOT HANDLED " . $f . "\n";
        } 
    }    
}

sub resolve_symlink {
    my $f = shift;
    return undef if (!-l $f);
    my $result = $f;
    while (1) {
        my $r = abs_path($result);
        last if ($r eq $result);
        $result = $r;
    }
    return $result;
}
