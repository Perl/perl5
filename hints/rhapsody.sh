##
# Rhapsody (Mac OS X Server) hints
# Wilfredo Sanchez <wsanchez@apple.com>
##

# Since we can build fat, the archname doesn't need the processor type
archname='rhapsody';

# Perl5.003 precedes this platform
d_bincompat3='undef';

# Libc is in libsystem.
libc='/System/Library/Frameworks/System.framework/System';

# nm works.
usenm='true';

# Optimize.
optimize='-O3';

# We have a prototype for telldir.
# We are not NeXTStep.
ccflags="${ccflags} -pipe -fno-common -DHAS_TELLDIR_PROTOTYPE -UNeXT -U__NeXT__";

# Don't use /usr/local/lib; we may have junk there.
libpth='/lib /usr/lib';

# Shared library extension in .dylib.
# Bundle extension in .bundle.
ld='cc';
so='dylib';
dlext='bundle';
dlsrc='dl_rhapsody.xs';
cccdlflags='';
lddlflags="${ldflags} -bundle -undefined suppress";
useshrplib='true';
libperl='Perl';
framework_path='/System/Library/Frameworks/Perl.framework';
base_address='0x4be00000';

# 4BSD uses /usr/share/man, not /usr/man.
# Don't put man pages in /usr/lib; that's goofy.
man1dir='/usr/share/man/man1';
man3dir='/usr/share/man/man3';

# Where to put modules.
privlib='/System/Library/Perl';
sitelib='/Local/Library/Perl';

# vfork works
usevfork='true';

# malloc works
usemymalloc='n';
