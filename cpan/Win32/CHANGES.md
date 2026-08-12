# Revision history for the Perl extension Win32

## 0.64 [2026-08-11]

- ship the CPAN tarball with LF line endings again; releases 0.60
  through 0.63 were packaged with CRLF because the release workflow's
  Windows runner converted the checkout [#65](https://github.com/perl-libwin32/win32/pull/65)

## 0.63 [2026-08-09]

- fix Win32::GetLastError() returning 0 after list-context Win32::HttpGetFile()
  calls on Cygwin -DDEBUGGING builds, diagnosed by [@sisyphus](https://github.com/sisyphus);
  add a CI job testing against a -DDEBUGGING Cygwin perl [#63](https://github.com/perl-libwin32/win32/pull/63)
- convert Changes to CHANGES.md and bump release-action to @v2

## 0.62 [2026-05-11]

- revert SvUTF8 flagging in wstr_to_sv and my_ansipath under CP_UTF8 ACP;
  make t/Unicode.t pass under CP_UTF8 ACP [#57](https://github.com/perl-libwin32/win32/pull/57)

## 0.61 [2026-05-10]

- handle CP_UTF8 system codepage in wstr_to_sv and my_ansipath [#53](https://github.com/perl-libwin32/win32/pull/53)
- fix inverted SKIP condition for non-English locale in t/HttpGetFile.t [#55](https://github.com/perl-libwin32/win32/pull/55)
- fix t/GetCurrentThreadId.t fork-emulation detection by [@sisyphus](https://github.com/sisyphus) [#45](https://github.com/perl-libwin32/win32/pull/45)

## 0.60 [2026-05-05]

- add LICENSE and modernize README [#51](https://github.com/perl-libwin32/win32/pull/51)
- update Microsoft doc URLs to learn.microsoft.com

## 0.59_02 [2026-05-04]

- detect newer Windows 10/11, Windows Server 2019/2022/2025, and
  Server SAC releases by Markus Demml ([@mardem1](https://github.com/mardem1)) [#42](https://github.com/perl-libwin32/win32/pull/42)
- fix 64-bit registry constant by [@jkahrman](https://github.com/jkahrman) [#37](https://github.com/perl-libwin32/win32/pull/37)
- follow-up to 64-bit registry fix by Tony Cook ([@tonycoz](https://github.com/tonycoz)) [#39](https://github.com/perl-libwin32/win32/pull/39)
- fix memory deallocation for WinHttpGetProxyForUrl strings [#49](https://github.com/perl-libwin32/win32/pull/49)
- include t/HttpGetFile.t in MANIFEST so it ships in the CPAN tarball [#50](https://github.com/perl-libwin32/win32/pull/50)
- convert tests to Test::More by Graham Knop ([@haarg](https://github.com/haarg)) [#35](https://github.com/perl-libwin32/win32/pull/35)
- clarify documentation of minor versions by Ferenc Erki ([@ferki](https://github.com/ferki)) [#25](https://github.com/perl-libwin32/win32/pull/25)

## 0.59 [2022-05-05]

- add Win32::GetChipArch and use it in Win32::GetOSName to support arm/arm64
  architecture by Pierrick Bouvier ([@p-b-o](https://github.com/p-b-o)) [#34](https://github.com/perl-libwin32/win32/pull/34)

## 0.58 [2022-01-17]

- add Win32::HttpGetFile (thanks to Craig Berry for the implementation
  and Tomasz Konojacki for code review) [#30](https://github.com/perl-libwin32/win32/pull/30)
- skip failing Unicode.t on Cygwin because cwd() no longer returns an
  ANSI (short) path there.
- Fixed test 14,15 of GetFullPathName.t when package is unpacked in a
  top level folder (thanks to Jianhong Feng) [#20](https://github.com/perl-libwin32/win32/pull/20)

## 0.57 [2021-03-10]

- fix calling convention for PFNRegGetValueA [#28](https://github.com/perl-libwin32/win32/pull/28)

## 0.56 [2021-03-07]

- added t/Privileges.t to MANIFEST

## 0.55 [2021-03-07]

- added Win32::IsSymlinkCreationAllowed(), Win32::IsDeveloperModeEnabled(),
  and Win32::GetProcessPrivileges() by Tomasz Konojacki ([@xenu](https://github.com/xenu)) [#27](https://github.com/perl-libwin32/win32/pull/27)
- removed old code for versions before Windows 2000
  by Tomasz Konojacki ([@xenu](https://github.com/xenu)) [#26](https://github.com/perl-libwin32/win32/pull/26)

## 0.54 [2020-03-27]

- Skip tests that rely upon short names if these are unavailable
  and additional docs about short filenames. Richard Leach ([@richardleach](https://github.com/richardleach)) [#23](https://github.com/perl-libwin32/win32/pull/23)

## 0.53 [2019-08-05]

- improve Win32::GetOSDisplayName
- added Win2016/2019 detection and version information by
  Richard Leach ([@richardleach](https://github.com/richardleach)) [#15](https://github.com/perl-libwin32/win32/pull/15)
- Include wchar.h to allow building with g++ by Tony Cook [rt#127836]

## 0.52_02 [2018-11-02] by Reini Urban

- added () usage croaks.
- Fixed a -Warray-bounds buffer overflow in LONGPATH,
- Fix various -Wunused warnings
  and two -Wmaybe-uninitialized.

## 0.52_01 [2017-11-30]

- add missing const

## 0.52 [2015-08-19]

- minimal Windows 10 support (thanks to Joel Maslak) [#8](https://github.com/perl-libwin32/win32/pull/8)
- refactor Windows 10 support to include ProductInfo flags
- add tests for Windows 8.1, 10, and 2012 R2 server
- define additional ProductInfo flags (TODO: add support for
  these codes in _GetOSName)

## 0.51 [2015-01-26]

- Win32-0.50 was released to CPAN from an out-dated Git repo, so
  didn't actually include the merged pull requests.

## 0.50 [2015-01-26]

- add GetOSName support for Windows 8.1 (thanks to Tony Cook ([@tonycoz](https://github.com/tonycoz))) [#6](https://github.com/perl-libwin32/win32/pull/6)
- Fix build in C++ mode (thanks to Steve Hay ([@steve-m-hay](https://github.com/steve-m-hay)) and Daniel Dragan) [#7](https://github.com/perl-libwin32/win32/pull/7)

## 0.49 [2014-04-15]

- Make sure Win32.xs uses winsock2.h and not winsock.h. [rt#94730]

## 0.48 [2013-11-20]

- Typo fixes by David Steinbrunner.
- Fix required perl version 5.6 -> 5.006.
- Don't call note() in t/GetOSName.t when it has not been
  imported from Test::More.
- Convert t/GetOSName.t to Unix line endings like the rest of
  this repo.

## 0.47 [2013-02-21]

- Make sure %PROCESSOR_ARCHITECTURE% is defined before calling
  Win32::GetArchName() in t/Names.t.  It may be undefined when
  the test is running under Cygwin crond.
- In t/Names.t don't assume that LoginName or NodeName is at
  least 2 characters long; it may just be 1. [rt#83474]

## 0.46 [2013-02-19]

- add Win2012/Win8 detection (thanks to Michiel Beijen) [rt#82572]
  [perl#116352]

## 0.45 [2012-08-07]

- add Win32::GetACP(), Win32::GetConsoleCP(),
  Win32::GetConsoleOutputCP(), Win32::GetOEMCP(), Win32::SetConsoleCP()
  and Win32::SetConsoleOutputCP(). [rt#78820] (Steve Hay)
- adjust t/Unicode.t for Cygwin 1.7, where readdir() returns
  the utf8 encoded filename without setting the SvUTF8 flag [rt#66751]
  [rt#74332]

## 0.44 [2011-01-12]

- fix memory leak introduced in 0.43

## 0.43 [2011-01-12]

- fix a few potential buffer overrun bugs reported by Alex Davies.
  [perl#78710]

## 0.42 [2011-01-06]

- remove brittle test for Win32::GetLongPathName($ENV{SYSTEMROOT})
  which will fail if the case of the environment value doesn't
  exactly match the case of the directory name on the filesystem.

## 0.41 [2010-12-10]

- Fix Win32::GetChipName() to return the native processor type when
  running 32-bit Perl on 64-bit Windows (WOW64).  This will also
  affect the values returned by Win32::GetOSDisplayName() and
  Win32::GetOSName(). [rt#63797]
- Fix Win32::GetOSDisplayName() to return the correct values for
  all products even when a service pack has been installed. (This
  was only an issue for some "special" editions).
- The display name for "Windows 7 Business Edition" is actually
  "Windows 7 Professional".
- Fix t/GetOSName.t tests to avoid using the values returned by
  GetSystemMetrics() when the test template didn't specify any
  value at all.

## 0.40 [2010-12-08]

- Add Win32::GetSystemMetrics function.
- Add Win32::GetProductInfo() function.
- Add Win32::GetOSDisplayName() function.
- Detect "Windows Server 2008 R2" as "Win2008" in Win32::GetOSName()
  (used to return "Win7" before). [rt#57172]
- Detect "Windows Home Server" as "WinHomeSvr" in Win32::GetOSName()
  (used to return "Win2003" before).
- Add "R2", "Media Center", "Tablet PC", "Starter Edition" etc.
  tags to the description returned by Win32::GetOSName() in
  list context.
- Rewrite the t/GetOSName.t tests

## 0.39 [2009-01-19]

- Add support for Windows 2008 Server and Windows 7 in
  Win32::GetOSName() and in the documentation for
  Win32::GetOSVersion().
- Make Win32::GetOSName() implementation testable.
- Document that the OSName for Win32s is actually "WinWin32s".

## 0.38 [2008-06-27]

- Fix Cygwin releated problems in t/GetCurrentThreadId.t
  (Jerry D. Hedden).

## 0.37 [2008-06-26]

- Add Win32::GetCurrentProcessId() function

## 0.36 [2008-04-17]

- Add typecasts for Win64 compilation

## 0.35 [2008-03-31]

Integrate changes from bleadperl:
- Silence Borland compiler warning (Steve Hay)
- Fix memory leak in Win32::GetOSVersion (Vincent Pit)
- Test Win32::GetCurrentThreadId on cygwin (Reini Urban, Steve Hay)

## 0.34 [2007-11-21]

- Document "WinVista" return value for Win32::GetOSName()
  (Steve Hay).

## 0.33 [2007-11-12]

- Update version to 0.33 for Perl 5.10 release
- Add $^O test in Makefile.PL for CPAN Testers
- Use Win32::GetLastError() instead of $^E in t/Names.t for
  cygwin compatibility (Jerry D. Hedden).

## 0.32 [2007-09-20]

- Additional #define's for older versions of VC++ (Dmitry Karasik).
- Win32::DomainName() doesn't return anything when the Workstation
  service isn't running.  Set $^E and adapt t/Names.t accordingly
  (Steve Hay & Jerry D. Hedden).
- Fix t/Names.t to allow Win32::GetOSName() to return an empty
  description as the 2nd return value (e.g. Vista without SP).
- Fix t/GetFileVersion.t for Perl 5.10

## 0.31 [2007-09-10]

- Apply Cygwin fixes from bleadperl (from Jerry D. Hedden).
- Make sure Win32::GetLongPathName() always returns drive
  letters in uppercase (Jerry D. Hedden).
- Use uppercase environment variable names in t/Unicode.t
  because the MSWin32 doesn't care, and Cygwin only works
  with the uppercased version.
- new t/Names.t test (from Sébastien Aperghis-Tramoni)

## 0.30 [2007-06-25]

- Fixed t/Unicode.t test for Cygwin (with help from Jerry D. Hedden).
- Fixed and documented Win32::GetShortPathName() to return undef
  when the pathname doesn't exist (thanks to Steve Hay).
- Added t/GetShortPathName.t

## 0.29 [2007-05-17]

- Fixed to compile with Borland BCC (thanks to Steve Hay).

## 0.28_01 [2007-05-16]

- Increase version number as 0.28 was already used by an ActivePerl
  release (for essentially 0.27 plus the Win32::IsAdminUser() change).

- Add MODULE and PROTOTYPES directives to silence warnings from
  newer versions of xsubpp.

- Use the Cygwin codepath in Win32::GetFullPathName() when
  PERL_IMPLICIT_SYS is not defined, because the other code
  relies on the virtualization code in win32/vdir.h.

## 0.27_02 [2007-05-15]

- We need Windows 2000 or later for the Unicode support because
  WC_NO_BEST_FIT_CHARS is not supported on Windows NT.

- Fix Win32::GetFullPathName() on Windows NT to return an
  empty file part if the original argument ends with a slash.

## 0.27_01 [2007-04-18]

- Update Win32::IsAdminUser() to use the IsUserAnAdmin() function
  in shell32.dll when available.  On Windows Vista this will only
  return true if the process is running with elevated privileges
  and not just when the owner of the process is a member of the
  "Administrators" group.

- Win32::ExpandEnvironmentStrings() may return a Unicode string
  (a string containing characters outside the system codepage)

- new Win32::GetANSIPathName() function returns a pathname in
  a form containing only characters from the system codepage

- Win32::GetCwd() will return an ANSI version of the directory
  name if the long name contains characters outside the system
  codepage.

- Win32::GetFolderPath() will return an ANSI pathname. Call
  Win32::GetLongPathName() to get the canonical Unicode
  representation.

- Win32::GetFullPathName() will return an ANSI pathname. Call
  Win32::GetLongPathName() to get the canonical Unicode
  representation.

- Win32::GetLongPathName() may return a Unicode path name.
  Call Win32::GetANSIPathName() to get a representation using
  only characters from the system codepage.

- Win32::LoginName() may return a Unicode string.

- new Win32::OutputDebugString() function sends a string to
  the debugger.

- new Win32::GetCurrentThreadId() function returns the thread
  id (to complement the process id in $$).

- new Win32::CreateDirectory() creates a new directory.  The
  name of the directory may contain Unicode characters outside
  the system codepage.

- new Win32::CreateFile() creates a new file.  The name of the
  file may contain Unicode characters outside the system codepage.


## 0.27 [2007-03-07]

- Extracted from the libwin32 distribution to simplify maintenance
  because Win32 is a dual-life core module since 5.8.4.

- Win32.pm and Win32.xs updated to version in bleadperl.
  This includes all the Win32::* function from win32/win32.c
  in core Perl, except for Win32::SetChildShowWindows().

- Install into 'perl' directory instead of 'site' for Perl 5.8.4
  and later.

- Add some simple tests.
