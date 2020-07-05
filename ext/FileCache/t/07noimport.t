#!./perl -w

use Test::More tests => 1;

# Try using FileCache without importing to make sure everything's 
# initialized without it.
{
    package Y;
    use FileCache ();

    my $file = 'foo';
    END { unlink $file }
    FileCache::cacheout($file);
    {
        no strict 'refs';
        print $file "bar";
        close $file;
    }

    FileCache::cacheout("<", $file);
    ::ok( <$file> eq "bar" );
    close $file;
}
