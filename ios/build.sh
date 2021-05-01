#!/usr/bin/env sh

############## CONFIG BEGIN ##############

# perl binaries
: "${PERL_ARCH:=arm64}"
: "${BITCODE:=0}"
: "${DEBUG:=0}"
: "${INSTALL_DIR:=local}"
: "${MIN_VERSION:=8.0}"
: "${PERL_APPLETV:=0}"
: "${PERL_APPLEWATCH:=0}"

# Xcode
: "${IOS_DEVICE_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk}"
: "${IOS_SIMULATOR_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk}"
: "${APPLETV_DEVICE_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk}"
: "${APPLETV_SIMULATOR_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk}"
: "${WATCHOS_DEVICE_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/WatchOS.platform/Developer/SDKs/WatchOS.sdk}"
: "${WATCHOS_SIMULATOR_SDK_PATH:=/Applications/Xcode.app/Contents/Developer/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator.sdk}"

############## CONFIG END ##############

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

PERL_REVISION=5

PERL_MAJOR_VERSION=`awk '/define[ 	]+PERL_VERSION/ {print $3}' "$SCRIPTPATH/../patchlevel.h"`
PERL_MINOR_VERSION=`awk '/define[ 	]+PERL_SUBVERSION/ {print $3}' "$SCRIPTPATH/../patchlevel.h"`

if [ $PERL_APPLETV -ne 0 ]; then
  PLATFORM_TAG="appletv"
  DEVICE_SDK_PATH="$APPLETV_DEVICE_SDK_PATH"
  SIMULATOR_SDK_PATH="$APPLETV_SIMULATOR_SDK_PATH"
  PERL_PLATFORM_TAG="PERL_APPLETV"
elif [ $PERL_APPLEWATCH -ne 0 ]; then
  PLATFORM_TAG="watch"
  DEVICE_SDK_PATH="$WATCHOS_DEVICE_SDK_PATH"
  SIMULATOR_SDK_PATH="$WATCHOS_SIMULATOR_SDK_PATH"
  PERL_PLATFORM_TAG="PERL_APPLEWATCH"
else
  PLATFORM_TAG="iphone"
  DEVICE_SDK_PATH="$IOS_DEVICE_SDK_PATH"
  SIMULATOR_SDK_PATH="$IOS_SIMULATOR_SDK_PATH"
  PERL_PLATFORM_TAG="PERL_IOS"
fi

MIN_VERSION_TAG="-m""$PLATFORM_TAG""os-version-min=$MIN_VERSION"
WORKDIR=`pwd`
PREFIX="$WORKDIR/$INSTALL_DIR"
PERL_VERSION="$PERL_REVISION.$PERL_MAJOR_VERSION.$PERL_MINOR_VERSION"

: "${PERLBREW_SOURCE:=$PERLBREW_ROOT/build/perl-$PERL_VERSION}"
export PERLBREW_SOURCE

mkdir "$PREFIX"
mkdir "$PREFIX/lib"
mkdir "$PREFIX/include"

case "$PERL_ARCH" in
  x86_64)
    SIMULATOR_BUILD=1
    ;;
  i386)
    SIMULATOR_BUILD=1
    ;;
  arm64)
    SIMULATOR_BUILD=0
    ;;
  armv7)
    SIMULATOR_BUILD=0
    ;;
  armv7s)
    SIMULATOR_BUILD=0
    ;;
  armv7k)
    SIMULATOR_BUILD=0
    ;;
  *)
    echo "Unsupported architecture: $PERL_ARCH"
    exit 1
    ;;
esac

# depends on GnuMakefile and DEBUGGING
if [ $DEBUG -eq 1 ]; then
  OPTIMIZER="-O0 -g"
else
  OPTIMIZER="-Os -O3"
fi

# simulator builds cannot produce bitcode
if [ $SIMULATOR_BUILD -eq 1 ]; then
  BITCODE=0
elif [ $PERL_APPLEWATCH -ne 0 ]; then
  PERL_ARCH="armv7k"
fi

BITCODE_BUILD_FLAGS=""
if [ $BITCODE -ne 0 ]; then
  BITCODE_BUILD_FLAGS="-fembed-bitcode"
fi

ARCH_FLAGS="-arch $PERL_ARCH"

SIMULATOR_BUILD_FLAGS="-DTARGET_OS_IPHONE -I$PREFIX/include -I$SIMULATOR_SDK_PATH/usr/include $ARCH_FLAGS $MIN_VERSION_TAG -isysroot $SIMULATOR_SDK_PATH"
SIMULATOR_LINK_FLAGS="-DTARGET_OS_IPHONE $ARCH_FLAGS -L$PREFIX/lib -L$SIMULATOR_SDK_PATH/usr/lib"

DEVICE_BUILD_FLAGS="-DTARGET_OS_IPHONE -I$PREFIX/include -I$DEVICE_SDK_PATH/usr/include $ARCH_FLAGS $MIN_VERSION_TAG -isysroot $DEVICE_SDK_PATH $BITCODE_BUILD_FLAGS"
DEVICE_LINK_FLAGS="-DTARGET_OS_IPHONE $ARCH_FLAGS -L$PREFIX/include -L$DEVICE_SDK_PATH/usr/lib"

if [ $SIMULATOR_BUILD -ne 0 ]; then
  BUILD_FLAGS="$SIMULATOR_BUILD_FLAGS"
  LINK_FLAGS="$SIMULATOR_LINK_FLAGS"
  SDK_PATH="$SIMULATOR_SDK_PATH"
else
  BUILD_FLAGS="$DEVICE_BUILD_FLAGS"
  LINK_FLAGS="$DEVICE_LINK_FLAGS"
  SDK_PATH="$DEVICE_SDK_PATH"
fi

BUILD_FLAGS="$BUILD_FLAGS -D$PERL_PLATFORM_TAG"
LINK_FLAGS="$LINK_FLAGS -D$PERL_PLATFORM_TAG"

######################################################
# Build perl
######################################################

build_perl() {
  cd "$WORKDIR"

  if [ -d "$WORKDIR/ext" ]; then
  for f in $WORKDIR/ext/*.tar.gz
  do
    echo $f is
    echo "Installing perl extension $f..."
    tar xvfz "$f" -C "perl-$PERL_VERSION/ext"
  done
  fi

  cd "perl-$PERL_VERSION"

  export SDKROOT="$SDK_PATH"
  export CC=/usr/bin/clang

  # do not strip if -g in ccflags
  if [ $DEBUG -eq 1 ]; then
    perl -0777 -i.bak.0 -pe "s|(\\$\\^O eq \'darwin\');|\(\1 && \\\$Config\{\"ccflags\"\} \!\~ /-g\\\s/);|" installperl
  fi

  # export min version
  if [ $PERL_APPLETV -ne 0 ]; then
    export APPLETV_DEPLOYMENT_TARGET="$MIN_VERSION"
  elif [ $PERL_APPLEWATCH -ne 0 ]; then
    export WATCHOS_DEPLOYMENT_TARGET="$MIN_VERSION"
  else
    export IPHONEOS_DEPLOYMENT_TARGET="$MIN_VERSION"
  fi

  # expand config
  cd "ios/config"
  perl -w template.pl
  cd ../..

  # replace config
  cp "ios/config/$PLATFORM_TAG/$PERL_ARCH/config.sh" .
  cp "ios/config/Policy.sh" .

  # patch the hardcoded build prefix in config
  perl -0777 -i.bak.0 -pe "s|/opt/local|$PREFIX|g" config.sh
  perl -0777 -i.bak.0 -pe "s|/opt/local|$PREFIX|g" Policy.sh

  perl -0777 -i.bak.1 -pe "s|%PERL_REVISION%|$PERL_REVISION|g" Policy.sh
  perl -0777 -i.bak.2 -pe "s|%PERL_MAJOR_VERSION%|$PERL_MAJOR_VERSION|g" Policy.sh
  perl -0777 -i.bak.3-pe "s|%PERL_MINOR_VERSION%|$PERL_MINOR_VERSION|g" Policy.sh
  
  # patch perl and os version
  os_version=$(uname -r)
  perl -0777 -i.bak.2 -pe "s|%PERL_REVISION%|$PERL_REVISION|g" config.sh
  perl -0777 -i.bak.3 -pe "s|%PERL_MAJOR_VERSION%|$PERL_MAJOR_VERSION|g" config.sh
  perl -0777 -i.bak.4 -pe "s|%PERL_MINOR_VERSION%|$PERL_MINOR_VERSION|g" config.sh
  perl -0777 -i.bak.5 -pe "s|%DARWIN_VERSION%|$os_version|g" config.sh
  
  # patch Makefile.SH #

  # use host generate_uudmap
  perl -i.bak.0 -pe 's|bitcount.h: generate_uudmap\\\$\(HOST_EXE_EXT\)|bitcount.h: generate_uudmap\\\$(HOST_EXE_EXT)\n\tcp "\$PERLBREW_SOURCE/generate_uudmap" .|' Makefile.SH

  # use host miniperl
  SUB_S="cp $PERLBREW_SOURCE/miniperl ." perl -i.bak.1 -pe 's|(    \$\(miniperl_objs\) \$\(libs\))|$1\n\t$ENV{SUB_S}|' Makefile.SH

  # use miniperl instead of full perl
  perl -i.bak.2 -pe 's|RUN_PERL = \\\$\(LDLIBPTH\) \\\$\(RUN\) \$perl\\\$\(EXE_EXT\)|RUN_PERL = \\\$(LDLIBPTH) \\\$(RUN) ./miniperl\\\$(EXE_EXT)|' Makefile.SH
  perl -i.bak.3 -pe 's|RUN_PERL = \\\$\(LDLIBPTH\) \\\$\(RUN\) ./perl\\\$\(EXE_EXT\) \-Ilib \-I\.|RUN_PERL = \\\$\(LDLIBPTH\) \\\$\(RUN\) ./miniperl\\\$\(EXE_EXT\) -Ilib -I.|' Makefile.SH

  # Patch Configure #

  # do not want db, header is detected but lib is not linkable
  sed -i.bak.0 -e $'s/libswanted="cl pthread socket bind inet nsl ndbm gdbm dbm db malloc dl ld"/libswanted="cl pthread socket bind inet nsl ndbm dbm malloc dl ld"/' Configure

  # use available extensions minus DB_File
  perl -0777 -i.bak.1 -pe 's|rp="What extensions do you wish to load dynamically\?"\n\t\. \.\/myread|rp="What extensions do you wish to load dynamically\?"\n\tavail_ext=\$\(echo "\$avail_ext" \| sed "s/ DB_File / /g"\)\n\tans="\$avail_ext"|' Configure

  # Binaries not executable in host arch. Do not abort on try tests
  perl -0777 -i.bak.2 -pe 's/Shall I abort Configure"\n\t\t*dflt=y/Shall I abort Configure"\n\t\tdflt=n/g' Configure

  # do not wait for press after Configure
  perl -0777 -i.bak.3 -pe 's/rp="Press return or use a shell escape to edit config.sh:"\n\t. UU\/myread/rp="Press return or use a shell escape to edit config.sh:"/' Configure

  # do not 'make depend' yet
  perl -0777 -i.bak.4 -pe 's|rp="Run \$make depend now\?"\n\t. UU\/myread|ans=n\n\trp="Run $make depend now\?"|' Configure

  # deployment target
  min_ver_replace="-m""$PLATFORM_TAG""os-version-min=8.0"
  perl -0777 -i.bak.4 -pe "s|$min_ver_replace|$MIN_VERSION_TAG|g" config.sh

  if [ $BITCODE -eq 1 ]; then
    perl -0777 -i.bak.5 -pe "s|\-fPIC|\-fPIC $BITCODE_BUILD_FLAGS|g" config.sh
    perl -0777 -i.bak.6 -pe "s|\-undefined dynamic_lookup||g" config.sh
    perl -0777 -i.bak.7 -pe "s|\-bundle|\-Xlinker \-bitcode_bundle|g" config.sh
  fi

  ./Configure -Dusedevel -f config.sh -d

  # accept all defaults of our arch config
  cp "ios/config/$PLATFORM_TAG/$PERL_ARCH/config.h" .

  # patch prefix
  perl -i.bak.0 -pe "s|/opt/local|$PREFIX|g" config.h

  perl -0777 -i.bak.4 -pe "s|$min_ver_replace|$MIN_VERSION_TAG|g" config.h

  if [ $PLATFORM_TAG != "iphone" ] ; then
    # patch fork
    perl -0777 -i.bak.0 -pe "s|d_fork='define'|d_fork='undef'|g" config.sh
    perl -0777 -i.bak.1 -pe "s|d_vfork='define'|d_vfork='undef'|g" config.sh
    perl -0777 -i.bak.2 -pe "s|usevfork='true'|usevfork='false'|g" config.sh
    perl -0777 -i.bak.0 -pe "s|#define HAS_FORK\t\t/\*\*/|/*#define HAS_FORK\t\t/ \*\*/|g" config.h

    # patch syscall
    perl -0777 -i.bak.3 -pe "s|d_syscall='define'|d_syscall='undef'|g" config.sh
    perl -0777 -i.bak.4 -pe "s|d_syscallproto='define'|d_syscallproto='undef'|g" config.sh
    perl -0777 -i.bak.1 -pe "s|#define HAS_SYSCALL\t/\*\*/|/*#define HAS_SYSCALL\t/ \*\*/|g" config.h
    perl -0777 -i.bak.2 -pe "s|#define	HAS_SYSCALL_PROTO\t/\*\*/|/*#define\tHAS_SYSCALL_PROTO\t/ \*\*/|g" config.h
  fi

  # remove DB_File
  perl -0777 -i.bak.4 -pe "s|DB_File||g" config.sh

  #patch arch
  perl -0777 -i.bak.5 -pe "s/myarchname=.*/\nmyarchname='$PERL_ARCH-darwin'/g" config.sh
  perl -0777 -i.bak.6 -pe "s|[^y]archname=.*|\narchname='$PERL_ARCH-darwin-ios-$PLATFORM_TAG-thread-multi'|" config.sh

  # patch perl version
  perl -0777 -i.bak.4 -pe "s|%PERL_REVISION%|$PERL_REVISION|g" config.h
  perl -0777 -i.bak.5 -pe "s|%PERL_MAJOR_VERSION%|$PERL_MAJOR_VERSION|g" config.h
  perl -0777 -i.bak.6 -pe "s|%PERL_MINOR_VERSION%|$PERL_MINOR_VERSION|g" config.h
  perl -0777 -i.bak.7 -pe "s|%DARWIN_VERSION%|$os_version|g" config.h

  make depend
  check_exit_code

  make
  check_exit_code

  make test_prep
  #make test would fail

  make install
  check_exit_code

  # generate dSYM file
  if [ $DEBUG -eq 1 ]; then
    echo "Generate libperl.dylib.dSYM..."
    pushd "$PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE"
    dsymutil libperl.dylib
    check_exit_code
    echo "$PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE/libperl.dylib.dSYM"
    popd
  fi

  #change install name of library for embedding
  chmod +w "$PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE/libperl.dylib"
  install_name_tool -id @rpath/libperl.dylib "$PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE/libperl.dylib"
  cd ..
}

delete_installed_perl() {
  rm -Rf "$PREFIX/bin/*"
  rm -Rf "$PREFIX/lib/*"
  rm -Rf "$PREFIX/doc/*"
  rm -Rf "$PREFIX/share/*"
  rm -Rf "$PREFIX/include/*"
}

check_exit_code() {
  if [ $? -ne 0 ]; then
    echo "Failed to build perl for iOS"
    exit $?
  fi
}

build_artifacts() {
  if [ $SIMULATOR_BUILD -ne 0 ]; then
    PLATFORM_TAG="$PLATFORM_TAG-simul"
  fi
  cd "$WORKDIR"
  TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
  export COPYFILE_DISABLE=true
  tar -c --exclude='._*' --exclude='.DS_Store' --exclude='*.bak' --exclude='*~' -vjf "perl-$PERL_VERSION-$PLATFORM_TAG-$PERL_ARCH-$TIMESTAMP.share.tar.bz2" "./$INSTALL_DIR/share"
  tar -c --exclude='._*' --exclude='.DS_Store' --exclude='*.bak' --exclude='*~' -vjf "perl-$PERL_VERSION-$PLATFORM_TAG-$PERL_ARCH-$TIMESTAMP.bin.tar.bz2" "./$INSTALL_DIR/bin"
  tar -c --exclude='._*' --exclude='.DS_Store' --exclude='*.bak' --exclude='*~' -vjf "perl-$PERL_VERSION-$PLATFORM_TAG-$PERL_ARCH-$TIMESTAMP.lib.tar.bz2" "./$INSTALL_DIR/lib/perl5"
  tar -c --exclude='._*' --exclude='.DS_Store' --exclude='*.bak' --exclude='*~' -vjf "perl-$PERL_VERSION-$PLATFORM_TAG-$PERL_ARCH-$TIMESTAMP.build.tar.bz2" "./perl-$PERL_VERSION"
}

delete_installed_perl
build_perl
build_artifacts
