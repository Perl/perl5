#!perl
use strict;
use warnings;

BEGIN {
    chdir 't';
    require './test.pl';
}

plan(tests => 6);

my $nonfile = tempfile();

@INC = qw(Perl Rules);

eval {
    require $nonfile;
};

like $@, qr/^Can't locate $nonfile in \@INC \(\@INC contains: @INC\) at/;

eval {
    require "$nonfile.ph";
};

like $@, qr/^Can't locate $nonfile\.ph in \@INC \(did you run h2ph\?\) \(\@INC contains: @INC\) at/;

eval {
    require "$nonfile.h";
};

like $@, qr/^Can't locate $nonfile\.h in \@INC \(change \.h to \.ph maybe\?\) \(did you run h2ph\?\) \(\@INC contains: @INC\) at/;

eval 'require <foom>';
like $@, qr/^<> should be quotes at /, 'require <> error';

my $module   = tempfile();
my $mod_file = "$module.pm";

open my $module_fh, ">", $mod_file or die $!;
print { $module_fh } "print 1; 1;\n";
close $module_fh;

chmod 0333, $mod_file;

SKIP: {
    skip_if_miniperl("these modules may not be available to miniperl", 2);

    push @INC, '../lib';
    require Cwd;
    require File::Spec::Functions;
    if ($^O eq 'cygwin') {
        require Win32;
    }

    # Going to try to switch away from root.  Might not work.
    # (stolen from t/op/stat.t)
    my $olduid = $>;
    eval { $> = 1; };
    skip "Can't test permissions meaningfully if you're superuser", 2
        if ($^O eq 'cygwin' ? Win32::IsAdminUser() : $> == 0);

    local @INC = ".";
    eval "use $module";
    like $@,
        qr<^\QCan't locate $mod_file:>,
        "special error message if the file exists but can't be opened";

    my $file = File::Spec::Functions::catfile(Cwd::getcwd(), $mod_file);
    eval {
        require($file);
    };
    like $@,
        qr<^\QCan't locate $file:>,
        "...even if we use a full path";

    # switch uid back (may not be implemented)
    eval { $> = $olduid; };
}

1 while unlink $mod_file;

# I can't see how to test the EMFILE case
# I can't see how to test the case of not displaying @INC in the message.
# (and does that only happen on VMS?)
