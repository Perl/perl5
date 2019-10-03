use strict;
use warnings;
BEGIN { 'warnings'->unimport('utf8') if $] < 5.014 }; # turn off 'UTF-16 surrogate 0xd800' warnings

use Test::More;
use Encode qw(encode decode FB_CROAK LEAVE_SRC);

my $script = quotemeta $0;

plan tests => 12;

my @invalid;

my @D800_bytes = (ord("A") == 65)
                 ? ( 0xED, 0xA0, 0x80 )
                 : (ord("^") == 95)                 # 1047
                    ? ( 0xDD, 0x65, 0x41, 0x41 )
                      : (ord("^") == 106)           # 037
                        ? ( 0xDD, 0x64, 0x41, 0x41 )
                        : ( 0xDC, 0x66, 0x41, 0x41 );       # Assume POSIX-BC
my $D800_bytes = join "", map { chr } @D800_bytes;
my $D800_display = join "", map { sprintf("\\x%02X", $_) } @D800_bytes;


ok ! defined eval { encode('UTF-8', "\x{D800}", FB_CROAK | LEAVE_SRC) }, 'Surrogate codepoint \x{D800} is not encoded to strict UTF-8';
like $@, qr/^"\\x\{d800\}" does not map to UTF-8 at $script line /, 'Error message contains strict UTF-8 name';
@invalid = ();
encode('UTF-8', "\x{D800}", sub { @invalid = @_; return ""; });
is_deeply \@invalid, [ 0xD800 ], 'Fallback coderef contains invalid codepoint 0xD800';

ok ! defined eval { decode('UTF-8', $D800_bytes, FB_CROAK | LEAVE_SRC) }, "Surrogate UTF-8 byte sequence $D800_display is not decoded with strict UTF-8 decoder";
like $@, qr/^UTF-8 "\Q$D800_display\E" does not map to Unicode at $script line /, 'Error message contains strict UTF-8 name and original (not decoded) invalid sequence';
@invalid = ();
decode('UTF-8', $D800_bytes, sub { @invalid = @_; return ""; });
is_deeply \@invalid, [ @D800_bytes ], 'Fallback coderef contains the invalid byte sequence';

# Now get rid of last byte and repeat
pop @D800_bytes;
$D800_bytes = join "", map { chr } @D800_bytes;
$D800_display = join "", map { sprintf("\\x%02X", $_) } @D800_bytes;

ok ! defined eval { decode('UTF-8', $D800_bytes, FB_CROAK | LEAVE_SRC) }, "Invalid byte sequence $D800_display is not decoded with strict UTF-8 decoder";
like $@, qr/^UTF-8 "\Q$D800_display\E" does not map to Unicode at $script line /, 'Error message contains strict UTF-8 name and original (not decoded) invalid sequence';
@invalid = ();
decode('UTF-8', $D800_bytes, sub { @invalid = @_; return ""; });
is_deeply \@invalid, [ @D800_bytes ], 'Fallback coderef contains the invalid byte sequence';

ok ! defined eval { decode('utf8', $D800_bytes, FB_CROAK | LEAVE_SRC) }, "Invalid byte sequence $D800_display is not decoded with non-strict utf8 decoder";
like $@, qr/^utf8 "\Q$D800_display\E" does not map to Unicode at $script line /, 'Error message contains non-strict utf8 name and original (not decoded) invalid sequence';
decode('utf8', $D800_bytes, sub { @invalid = @_; return ""; });
is_deeply \@invalid, [ @D800_bytes ], 'Fallback coderef contains the invalid byte sequence';
