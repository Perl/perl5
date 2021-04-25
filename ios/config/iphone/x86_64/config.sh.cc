#!/bin/sh
#
# This file was produced by running the Configure script. It holds all the
# definitions figured out by Configure. Should you modify one of these values,
# do not forget to propagate your changes by running "Configure -der". You may
# instead choose to run each of the .SH files by yourself, or "Configure -S".
#

# Package name      : perl%PERL_REVISION%
# Source directory  : .
# Configuration time: Wed Jun 17 13:38:56 CEST 2020
# Configured by     : jose
# Target system     : darwin joses-mac.local %DARWIN_VERSION% darwin kernel version %DARWIN_VERSION%: thu jun 21 20:07:40 pdt 2018; root:xnu-3248.73.11~1release_x86_64 x86_64 

: Configure command line arguments.
config_arg0='./Configure'
config_args='-des -Duse64bitall -Duse64bitint -Duselongdouble -Dquadmath -Dinstallstyle=lib/perl%PERL_REVISION% -Dlibpth= /opt/local/lib -Dincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include /opt/local/include -Dlocincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include /opt/local/include -Dloclibpth= /opt/local/lib -Dprefix=/opt/local -Dcc=/usr/bin/clang -Dman1dir=/opt/local/share/man/man1p -Dman1ext=1pm -Dman3dir=/opt/local/share/man/man3p -Dman3ext=3pm -Dscriptdir=/opt/local/bin -Dsitebin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/sitebin -Dsiteman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man1 -Dsiteman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man3 -Dusemultiplicity=y -Duseshrplib -Dusethreads -Dvendorbin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION% -Dvendorman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man1 -Dvendorman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man3 -Dvendorprefix=/opt/local -Dccflags=-arch x86_64 -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -arch x86_64 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk  -DPERL_IOS -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong -Dcppflags=-arch x86_64 -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -arch x86_64 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk  -DPERL_IOS -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong -Aldflags=-arch x86_64 -L/opt/local/lib -DPERL_IOS -Wl,-headerpad_max_install_names -Alddlflags=-arch x86_64 -L/opt/local/lib -DPERL_IOS -Wl,-headerpad_max_install_names -bundle -L/opt/local/lib -Acccdlflags=-arch x86_64 -isysroot/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
config_argc=32
config_arg1='-des'
config_arg2='-Duse64bitall'
config_arg3='-Duse64bitint'
config_arg4='-Duselongdouble'
config_arg5='-Dquadmath'
config_arg6='-Dinstallstyle=lib/perl%PERL_REVISION%'
config_arg7='-Dlibpth= /opt/local/lib'
config_arg8='-Dincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include /opt/local/include'
config_arg9='-Dlocincpth=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include /opt/local/include'
config_arg10='-Dloclibpth= /opt/local/lib'
config_arg11='-Dprefix=/opt/local'
config_arg12='-Dcc=/usr/bin/clang'
config_arg13='-Dman1dir=/opt/local/share/man/man1p'
config_arg14='-Dman1ext=1pm'
config_arg15='-Dman3dir=/opt/local/share/man/man3p'
config_arg16='-Dman3ext=3pm'
config_arg17='-Dscriptdir=/opt/local/bin'
config_arg18='-Dsitebin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/sitebin'
config_arg19='-Dsiteman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man1'
config_arg20='-Dsiteman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/siteman/man3'
config_arg21='-Dusemultiplicity=y'
config_arg22='-Duseshrplib'
config_arg23='-Dusethreads'
config_arg24='-Dvendorbin=/opt/local/libexec/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%'
config_arg25='-Dvendorman1dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man1'
config_arg26='-Dvendorman3dir=/opt/local/share/perl%PERL_REVISION%.%PERL_MAJOR_VERSION%/man/man3'
config_arg27='-Dvendorprefix=/opt/local'
config_arg28='-Dccflags=-arch x86_64 -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -arch x86_64 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk  -DPERL_IOS -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong'
config_arg29='-Dcppflags=-arch x86_64 -I/opt/local/include -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/include -arch x86_64 -miphoneos-version-min=8.0 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk  -DPERL_IOS -DPERL_USE_SAFE_PUTENV -fno-common -fPIC -DPERL_DARWIN -DTARGET_OS_IPHONE -pipe -O0 -g -fno-strict-aliasing -fstack-protector-strong'
config_arg30='-Aldflags=-arch x86_64 -L/opt/local/lib -DPERL_IOS -Wl,-headerpad_max_install_names'
config_arg31='-Alddlflags=-arch x86_64 -L/opt/local/lib -DPERL_IOS -Wl,-headerpad_max_install_names -bundle -L/opt/local/lib'
config_arg32='-Acccdlflags=-arch x86_64 -isysroot/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'

