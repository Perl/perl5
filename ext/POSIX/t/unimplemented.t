#!./perl -w

use strict;
use Test::More;
use Config;

plan(skip_all => "POSIX is unavailable")
    unless $Config{extensions} =~ /\bPOSIX\b/;

require POSIX;

foreach ([atexit => ' is C-specific: use END {} instead'],
	 [atof => ' is C-specific, stopped'],
	 [atoi => ' is C-specific, stopped'],
	 [atol => ' is C-specific, stopped'],
	 [bsearch => ' not supplied'],
	 [calloc => ' is C-specific, stopped'],
	 [clearerr => \'IO::Handle::clearerr'],
	 [div => ' is C-specific, use /, % and int instead'],
	 [execl => ' is C-specific, stopped'],
	 [execle => ' is C-specific, stopped'],
	 [execlp => ' is C-specific, stopped'],
	 [execv => ' is C-specific, stopped'],
	 [execve => ' is C-specific, stopped'],
	 [execvp => ' is C-specific, stopped'],
	 [fclose => \'IO::Handle::close'],
	 [fdopen => \'IO::Handle::new_from_fd'],
	 [feof => \'IO::Handle::eof'],
	 [ferror => \'IO::Handle::error'],
	 [fflush => \'IO::Handle::flush'],
	 [fgetc => \'IO::Handle::getc'],
	 [fgetpos => \'IO::Seekable::getpos'],
	 [fgets => \'IO::Handle::gets'],
	 [fileno => \'IO::Handle::fileno'],
	 [fopen => \'IO::File::open'],
	 [fprintf => ' is C-specific--use printf instead'],
	 [fputc => ' is C-specific--use print instead'],
	 [fputs => ' is C-specific--use print instead'],
	 [fread => ' is C-specific--use read instead'],
	 [free => ' is C-specific, stopped'],
	 [freopen => ' is C-specific--use open instead'],
	 [fscanf => ' is C-specific--use <> and regular expressions instead'],
	 [fseek => \'IO::Seekable::seek'],
	 [fsetpos => \'IO::Seekable::setpos'],
	 [fsync => \'IO::Handle::sync'],
	 [ftell => \'IO::Seekable::tell'],
	 [fwrite => ' is C-specific--use print instead'],
	 [labs => ' is C-specific, use abs instead'],
	 [ldiv => ' is C-specific, use /, % and int instead'],
	 [longjmp => ' is C-specific: use die instead'],
	 [malloc => ' is C-specific, stopped'],
	 [memchr => ' is C-specific, use index() instead'],
	 [memcmp => ' is C-specific, use eq instead'],
	 [memcpy => ' is C-specific, use = instead'],
	 [memmove => ' is C-specific, use = instead'],
	 [memset => ' is C-specific, use x instead'],
	 [offsetof => ' is C-specific, stopped'],
	 [putc => ' is C-specific--use print instead'],
	 [putchar => ' is C-specific--use print instead'],
	 [puts => ' is C-specific--use print instead'],
	 [qsort => ' is C-specific, use sort instead'],
	 [rand => ' is non-portable, use Perl\'s rand instead'],
	 [realloc => ' is C-specific, stopped'],
	 [scanf => ' is C-specific--use <> and regular expressions instead'],
	 [setbuf => \'IO::Handle::setbuf'],
	 [setjmp => ' is C-specific: use eval {} instead'],
	 [setvbuf => \'IO::Handle::setvbuf'],
	 [siglongjmp => ' is C-specific: use die instead'],
	 [sigsetjmp => ' is C-specific: use eval {} instead'],
	 [srand => ''],
	 [sscanf => ' is C-specific--use regular expressions instead'],
	 [strcat => ' is C-specific, use .= instead'],
	 [strchr => ' is C-specific, use index() instead'],
	 [strcmp => ' is C-specific, use eq instead'],
	 [strcpy => ' is C-specific, use = instead'],
	 [strcspn => ' is C-specific, use regular expressions instead'],
	 [strlen => ' is C-specific, use length instead'],
	 [strncat => ' is C-specific, use .= instead'],
	 [strncmp => ' is C-specific, use eq instead'],
	 [strncpy => ' is C-specific, use = instead'],
	 [strpbrk => ' is C-specific, stopped'],
	 [strrchr => ' is C-specific, use rindex() instead'],
	 [strspn => ' is C-specific, stopped'],
	 [strtok => ' is C-specific, stopped'],
	 [tmpfile => \'IO::File::new_tmpfile'],
	 [ungetc => \'IO::Handle::ungetc'],
	 [vfprintf => ' is C-specific'],
	 [vprintf => ' is C-specific'],
	 [vsprintf => ' is C-specific'],
	) {
    my ($func, $action) = @$_;
    my $expect = ref $action ? qr/Use method $$action\(\) instead at \(eval/
	: qr/Unimplemented: POSIX::$func\(\)\Q$action\E at \(eval/;
    is(eval "POSIX::$func(); 1", undef, "POSIX::$func fails as expected");
    like($@, $expect, "POSIX::$func gives expected error message");
}

done_testing();
