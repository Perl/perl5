#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

# This file mostly contains tests of the PADNAMEf_TOMBSTONE mechanism.
# Currently the only way it is accessible from perl code is via unimport from
# builtin.

use v5.36;
no warnings 'experimental::builtin';

# imported builtins can be unexported
{
    package UnimportTest;

    sub true() { return "yes" };

    {
        use builtin 'true';
        no builtin 'true';

        ::is(true(), "yes", 'no builtin can remove lexical import');
    }

    {
        use builtin 'true';
        { no builtin 'true'; }

        ::is(true(), 1, 'no builtin is lexically scoped');
    }
}

# multiple imports are idempotent
{
    use builtin 'true';
    use builtin 'true';
    is(true(), "1", 'imported true() from two use lines');

    no builtin 'true';
    ok(!defined eval "true(); 1", 'true() is no longer visible after a single no');
    like($@, qr/^Undefined subroutine &main::true called at /, 'Failure from missing function');
}

# tombstone reveals earlier lexicals of the same name
{
   my sub true() { return "yes" }

   {
      is(true(), "yes", 'lexical true() before import+unimport');

      use builtin 'true';
      no builtin 'true';

      is(true(), "yes", 'lexical true() after import+unimport');
   }

   {
       use builtin 'true';
       {
           use builtin 'true';
           no builtin 'true';
       }
       no builtin 'true';

       is(true(), "yes", 'lexical true() after double nested import+unimport');
   }
}

# vim: tabstop=4 shiftwidth=4 expandtab autoindent softtabstop=4

done_testing();
