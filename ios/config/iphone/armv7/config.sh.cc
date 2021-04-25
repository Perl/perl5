#!/bin/sh
#
# This file was produced by running the Configure script. It holds all the
# definitions figured out by Configure. Should you modify one of these values,
# do not forget to propagate your changes by running "Configure -der". You may
# instead choose to run each of the .SH files by yourself, or "Configure -S".
#

# Package name      : perl%PERL_REVISION%
# Source directory  : .
# Configuration time: Wed Jun  3 17:10:10 CEST 2020
# Configured by     : jose
# Target system     : darwin joses-mac.local %DARWIN_VERSION% darwin kernel version %DARWIN_VERSION%: thu jun 21 20:07:40 pdt 2018; root:xnu-3248.73.11~1release_x86_64 x86_64 

: Configure command line arguments.
config_arg0='./Configure'
config_args='-des -Dinstallstyle=lib/perl%PERL_REVISION% -Dlibpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib /opt/local/lib -Dincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include /opt/local/include -Dlocincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include /opt/local/include -Dloclibpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib /opt/local/lib -Dprefix=/opt/local -Dcc=/usr/bin/clang -Dman1dir=/opt/local/share/man/man1p -Dman1ext=1pm -Dman3dir=/opt/local/share/man/man3p -Dman3ext=3pm -Dscriptdir=/opt/local/bin -Dsitebin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/sitebin -Dsiteman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man1 -Dsiteman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man3 -Dusemultiplicity=y -Duseshrplib -Dusethreads -Dvendorbin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION% -Dvendorman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man1 -Dvendorman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man3 -Dvendorprefix=/opt/local -Accflags=-arch armv7 -DTARGET_OS_IPHONE -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include -arch armv7 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk  -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong -Acppflags=-arch armv7 -DTARGET_OS_IPHONE -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include -arch armv7 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk  -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong -Aldflags=-arch armv7 -DTARGET_OS_IPHONE -arch armv7 -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib   -Wl,-headerpad_max_install_names -Alddlflags=-arch armv7 -DTARGET_OS_IPHONE -arch armv7 -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib   -Wl,-headerpad_max_install_names -bundle -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib  -L/opt/local/lib -Acccdlflags=-arch armv7 -miphoneos-version-min=8.0 -isysroot/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
config_argc=28
config_arg1='-des'
config_arg2='-Dinstallstyle=lib/perl%PERL_REVISION%'
config_arg3='-Dlibpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib /opt/local/lib '
config_arg4='-Dincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include /opt/local/include'
config_arg5='-Dlocincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include /opt/local/include'
config_arg6='-Dloclibpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib /opt/local/lib'
config_arg7='-Dprefix=/opt/local'
config_arg8='-Dcc=/usr/bin/clang'
config_arg9='-Dman1dir=/opt/local/share/man/man1p'
config_arg10='-Dman1ext=1pm'
config_arg11='-Dman3dir=/opt/local/share/man/man3p'
config_arg12='-Dman3ext=3pm'
config_arg13='-Dscriptdir=/opt/local/bin'
config_arg14='-Dsitebin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/sitebin'
config_arg15='-Dsiteman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man1'
config_arg16='-Dsiteman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man3'
config_arg17='-Dusemultiplicity=y'
config_arg18='-Duseshrplib'
config_arg19='-Dusethreads'
config_arg20='-Dvendorbin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%'
config_arg21='-Dvendorman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man1'
config_arg22='-Dvendorman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man3'
config_arg23='-Dvendorprefix=/opt/local'
config_arg24='-Accflags=-arch armv7 -DTARGET_OS_IPHONE -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include -arch armv7 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk  -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong'
config_arg25='-Acppflags=-arch armv7 -DTARGET_OS_IPHONE -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include -arch armv7 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk  -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong'
config_arg26='-Aldflags=-arch armv7 -DTARGET_OS_IPHONE -arch armv7 -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib  -Wl,-headerpad_max_install_names'
config_arg27='-Alddlflags=-arch armv7 -DTARGET_OS_IPHONE -arch armv7 -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib  -Wl,-headerpad_max_install_names -bundle -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/lib -L/opt/local/lib'
config_arg28='-Acccdlflags=-arch armv7 -miphoneos-version-min=8.0 -isysroot/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'

