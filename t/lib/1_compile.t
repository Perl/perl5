#!./perl

BEGIN {
    chdir '..' if -d '../pod' && -d '../t';
    @INC = 'lib';
}

use strict;
use warnings;

my @Core_Modules = (
                    'AnyDBM_File',
                    'AutoLoader',
                    'AutoSplit',
                    'B',           # Do all these B things compile everywhere?
                    'B::Asmdata',
                    'B::Assembler',
                    'B::Bblock',
                    'B::Bytecode',
                    'B::C',
                    'B::CC',
                    'B::Concise',
                    'B::Debug',
                    'B::Deparse',
                    'B::Disassembler',
                    'B::Lint',
                    'B::Showlex',
                    'B::Stackobj',
                    'B::Stash',
                    'B::Terse',
                    'B::Xref',
                    'Benchmark',
                    'ByteLoader',
                    'CGI',
                    'CGI::Apache',
                    'CGI::Carp',
                    'CGI::Cookie',
                    # 'CGI::Fast', # won't load without FCGI
                    'CGI::Pretty',
                    'CGI::Push',
                    'CGI::Switch',
                    'CGI::Util',
                    'CPAN',
                    'CPAN::FirstTime',
                    'CPAN::Nox',
                    'Carp',
                    'Carp::Heavy',
                    'Class::Struct',
                    'Config',
                    'Cwd',
                    'DB',
                    #                 DB_File               # config specific
                    'Data::Dumper',
                    # 'Devel::DProf',  # needs to run as -d:DProf
                    'Devel::Peek',
                    'Devel::SelfStubber',
                    'DirHandle',
                    'Dumpvalue',
                    'DynaLoader',  # config specific?
                    'English',
                    'Encode',
                    'Env',
                    'Errno',
                    'Exporter',
                    'Exporter::Heavy',
                    'ExtUtils::Command',
                    'ExtUtils::Embed',
                    'ExtUtils::Install',
                    'ExtUtils::Installed',
                    'ExtUtils::Liblist',
                    # ExtUtils::MM_Cygwin   # ExtUtils::MakeMaker takes
                    # ExtUtils::MM_OS2      # care of testing these.
                    # ExtUtils::MM_Unix
                    # ExtUtils::MM_VMS
                    # ExtUtils::MM_Win32
                    'ExtUtils::MakeMaker',
                    'ExtUtils::Manifest',
                    'ExtUtils::Mkbootstrap',
                    'ExtUtils::Mksymlists',
                    'ExtUtils::Packlist',
                    'ExtUtils::testlib',
                    'Fatal',
                    'Fcntl',       # config specific?
                    'File::Basename',
                    'File::CheckTree',
                    'File::Compare',
                    'File::Copy',
                    'File::DosGlob',
                    'File::Find',
                    'File::Glob',
                    'File::Path',
                    'File::Spec',
                    'File::Spec::Functions',
                    # File::Spec::EPOC       # File::Spec will take care of
                    # File::Spec::Mac        # testing these compile.
                    # File::Spec::OS2
                    # File::Spec::Unix
                    # File::Spec::VMS
                    # File::Spec::Win32
                    'File::stat',
                    'FileCache',
                    'FileHandle',
                    'Filter::Simple',
                    'Filter::Util::Call',
                    'FindBin',
                    'Getopt::Long',
                    'Getopt::Std',
                    'I18N::Collate',
                    'IO',
                    'IO::Dir',
                    'IO::File',
                    'IO::Handle',
                    'IO::Pipe',
                    'IO::Poll',
                    'IO::Seekable',
                    'IO::Select',
                    'IO::Socket',
                    'IO::Socket::INET',
                    # IO::Socket::UNIX      # config specific
                    'IPC::Msg',
                    'IPC::Open2',
                    'IPC::Open3',
                    'IPC::Semaphore', # config specific?
                    'IPC::SysV',   # config specific?
                    'Math::BigFloat',
                    'Math::BigInt',
                    'Math::Complex',
                    'Math::Trig',
                    'Net::Ping',
                    'Net::hostent',
                    'Net::netent',
                    'Net::protoent',
                    'Net::servent',
                    'O',
                    'Opcode',
                    'POSIX',       # config specific?
                    'Pod::Checker',
                    'Pod::Find',
                    'Pod::Functions',
                    'Pod::Html',
                    'Pod::InputObjects',
                    'Pod::Man',
                    'Pod::Overstrike',
                    'Pod::ParseUtils',
                    'Pod::Parser',
                    'Pod::Plainer',
                    'Pod::Select',
                    'Pod::Text',
                    'Pod::Text::Color',
                    'Pod::Text::Termcap',
                    'Pod::Usage',
                    'SDBM_File',
                    'Safe',
                    'Search::Dict',
                    'SelectSaver',
                    'SelfLoader',
                    'Shell',
                    'Socket',
                    'Symbol',
                    'Sys::Hostname',
                    'Sys::Syslog',
                    'Term::ANSIColor',
                    'Term::Cap',
                    'Term::Complete',
                    'Term::ReadLine',
                    'Test',
                    'Test::Harness',
                    'Text::Abbrev',
                    'Text::ParseWords',
                    'Text::Soundex',
                    'Text::Tabs',
                    'Text::Wrap',
                    'Tie::Array',
                    'Tie::Hash',
                    'Tie::RefHash',
                    'Tie::Scalar',
                    'Tie::SubstrHash',
                    'Time::Local',
                    'Time::gmtime',
                    'Time::localtime',
                    'Time::tm',
                    'UNIVERSAL',
                    'User::grent',
                    'User::pwent',
                    'XSLoader',
                    'attributes',
                    'attrs',
                    'autouse',
                    'blib',
                    'bytes',
                    'charnames',
                    'constant',
                    'diagnostics',
                    'filetest',
                    'integer',
                    'less',
                    'lib',
                    'locale',
                    'open',
                    'ops',
                    'overload',
                    're',
                    'sigtrap',
                    'strict',
                    'subs',
                    'unicode::distinct',
                    'utf8',
                    'vars',
                    'warnings',
                    'warnings::register',
                   );         

print "1..".@Core_Modules."\n";

my $test_num = 1;
foreach my $module (@Core_Modules) {
    print "not " unless compile_module($module);
    print "ok $test_num\n";
    $test_num++;
}


# We do this as a seperate process else we'll blow the hell out of our
# namespace.
sub compile_module {
    my($module) = @_;
    
    return scalar `./perl -Ilib t/lib/compmod.pl $module` =~ /^ok/;
}
