#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use v5.40;

use Test2::V0 -target => 'SelectSaver';

ok dies { SelectSaver::new() }, 'Too few arguments to new dies';
ok dies { CLASS->new(undef, undef) }, 'Too many arguments to new dies';

subtest 'bareword filehandle' => sub {
    use feature 'bareword_filehandles';

    is refaddr(select), refaddr(*STDOUT), 'STDOUT is initially selected';

    open FOO, '>', undef;

    {
        ok my $saver = CLASS->new(*FOO), 'SelectSaver->new(*FOO)';

        is refaddr(select), refaddr(*FOO), 'FOO is now selected';
    }

    is refaddr(select), refaddr(*STDOUT), 'STDOUT is selected again';

    {
        ok my $saver = CLASS->new('FOO'), 'SelectSaver->new("FOO")';

        is refaddr(select), refaddr(*FOO), 'FOO is now selected';
    }

    is refaddr(select), refaddr(*STDOUT), 'STDOUT is selected again';
};

subtest 'lexical filehandle' => sub {
    is refaddr(select), refaddr(*STDOUT), 'STDOUT is initially selected';

    open my $fh, '>', undef;

    {
        ok my $saver = CLASS->new($fh), 'SelectSaver->new($fh)';

        is refaddr(select), refaddr($fh), '$fh is now selected';
    }

    is refaddr(select), refaddr(*STDOUT), 'STDOUT is selected again';
};

subtest 'no filehandle' => sub {
    is refaddr(select), refaddr(*STDOUT), 'STDOUT is initially selected';

    {
        ok my $saver = CLASS->new, 'SelectSaver->new';

        ok select(STDERR), 'select STDERR';

        is refaddr(select), refaddr(*STDERR), 'STDERR is now selected';
    }

    is refaddr(select), refaddr(*STDOUT), 'STDOUT is selected again';
};

done_testing;
