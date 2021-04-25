#!/usr/bin/env sh

source $HOME/perl5/perlbrew/etc/bashrc
source setup_test.sh

if [ -z ${IOS_DEVICE_UUID+x} ]; 
    then echo "IOS_DEVICE_UUID is unset. Please set it and try again" && exit 0; 
    else echo "IOS_DEVICE_UUID is set to '$IOS_DEVICE_UUID'";
fi

if [ -z ${HARNESS_APP_ID+x} ]; 
    then echo "HARNESS_APP_ID is unset. Please set it and try again" && exit 0; 
    else echo "HARNESS_APP_ID is set to '$HARNESS_APP_ID'";
fi

# Tested on macOS Catalina 10.15.7 w/ XCode 12.4
# check README.ios for details

: "${PERL_MAJOR_VERSION:=33}"
: "${PERL_MINOR_VERSION:=9}"

export PERL_VERSION="5.$PERL_MAJOR_VERSION.$PERL_MINOR_VERSION"

: "${PERL5_GIT:=https://github.com/jpalao/perl5.git}"
: "${PERL_5_BRANCH:=ios_blead_test}"
: "${INSTALL_DIR:=local}"

WORKDIR=`pwd`

: "${CAMELBONES_GIT:=https://github.com/jpalao/camelbones.git}"
: "${CAMELBONES_BRANCH:=master}"
: "${CAMELBONES_PREFIX:=$WORKDIR}"
: "${IOS_MOUNTPOINT:=$WORKDIR/_ios_mount}"

: "${HARNESS_TARGET:=iphoneos}"
: "${HARNESS_BUILD_CONFIGURATION:=Debug}"

PERL_INSTALL_PREFIX="$WORKDIR/$INSTALL_DIR"

export CAMELBONES_PREFIX=`pwd`
export CAMELBONES_TARGET=$HARNESS_TARGET
export CAMELBONES_BUILD_CONFIGURATION=$HARNESS_BUILD_CONFIGURATION
export CAMELBONES_CI=1
export CAMELBONES_VERSION='1.3.0'
export CAMELBONES_CPAN_DIR=`pwd`"/perl-$PERL_VERSION/ext/CamelBones-$CAMELBONES_VERSION"
export INSTALL_CAMELBONES_FRAMEWORK=0
export OVERWRITE_CAMELBONES_FRAMEWORK=0

# CAMELBONES #
export ARCHS='arm64'
export PERL_DIST_PATH="$PERL_INSTALL_PREFIX/lib/perl5"
export LIBPERL_PATH="$PERL_INSTALL_PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE"

use_perlbrew() {
    perlbrew use "perl-$PERL_VERSION"
    if [ $? -ne 0 ]; then
        echo "perlbrew: failed to use perl for macOS, attempting to install"
        build_macos_perl
        perlbrew use "perl-$PERL_VERSION"
        check_exit_code
    fi
    check_host_perl_version
}

check_host_perl_version () {
    macos_perl_version=`perl -v`
    macos_perl_version_grep=`echo "$macos_perl_version" | grep -o "$PERL_VERSION"`
    if [ "$macos_perl_version_grep" = "$PERL_VERSION" ]; then
        echo "perl $PERL_VERSION seems installed at"
        echo `which perl`
        return 1
    else
        echo "Failed to detect perl version $PERL_VERSION"
        return 0
    fi
}

check_dependencies() {
    deps=( "xcodebuild" "git" "perl" "perlbrew" "ifuse" "ios-deploy" )
    for i in "${deps[@]}"
    do
        command -v $i >/dev/null 2>&1 || { 
            echo >&2 "$i is required. Please install it and try again"
            exit 1
        }
    done
}

check_exit_code() {
  if [ $? -ne 0 ]; then
    echo "Failed to build perl for iOS"
    exit $?
  fi
}

prepare_camelbones() {
  rm -Rf camelbones
  git clone --single-branch --branch "$CAMELBONES_BRANCH" "$CAMELBONES_GIT"
}

prepare_ios() {
  rm -Rf "perl-$PERL_VERSION"
  git clone --single-branch --branch "$PERL_5_BRANCH" "$PERL5_GIT" "perl-$PERL_VERSION"
}

prepare_appletv() {
  rm -Rf "perl-$PERL_VERSION"
  git clone --single-branch --branch "$PERL_5_BRANCH" "$PERL5_GIT" "perl-$PERL_VERSION"
}

build_libffi() {
    pushd ./libffi-3.2.1
    xcodebuild -scheme libffi-"$CAMELBONES_TARGET"
    check_exit_code
    popd
}

_term() { 
  echo "Killing refresh process..." 
  kill -TERM "$REFRESH_PID" 2>/dev/null
}

test_perl_device() {
    echo "Mount iOS device under $IOS_MOUNTPOINT"

    umount -f $IOS_MOUNTPOINT
    
    mkdir -p $IOS_MOUNTPOINT
    check_exit_code
                
    pushd "perl-$PERL_VERSION/ios/test"
    check_exit_code
        
    xcodebuild ARCHS='arm64' \
        CAMELBONES_FRAMEWORK_PATH="$CAMELBONES_PREFIX/camelbones/CamelBones/build/Products/$CAMELBONES_BUILD_CONFIGURATION-$CAMELBONES_TARGET" \
        PERL_DIST_PATH="$PERL_INSTALL_PREFIX/lib/perl5" \
        LIBPERL_PATH="$PERL_INSTALL_PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE" \
        PERL_VERSION="$PERL_VERSION" ARCHS="$ARCHS" ONLY_ACTIVE_ARCH=NO \
        -allowProvisioningUpdates -scheme harness
    check_exit_code
    
    # install the app so it can receive files in Documents
    ios-deploy --bundle "Build/Products/$HARNESS_BUILD_CONFIGURATION-$HARNESS_TARGET/harness.app"

    ifuse $IOS_MOUNTPOINT -u "$IOS_DEVICE_UUID" -o volname=harness --documents "$HARNESS_APP_ID"
    check_exit_code
    
    rm -Rf "$IOS_MOUNTPOINT/*"
    check_exit_code

    echo "Copy perl build directory to iOS device..."
    cp -Ra "$WORKDIR/perl-$PERL_VERSION/." $IOS_MOUNTPOINT 2>/dev/null
    #check_exit_code
    
    echo "Delete unsigned bundle files from harness mountpoint..."
    find $IOS_MOUNTPOINT -name "*.bundle" -type f -delete
    check_exit_code

    umount -f $IOS_MOUNTPOINT 
    #check_exit_code

    ios-deploy --justlaunch --debug --bundle "Build/Products/$HARNESS_BUILD_CONFIGURATION-$HARNESS_TARGET/harness.app"
    check_exit_code

    popd

    ifuse $IOS_MOUNTPOINT -u "$IOS_DEVICE_UUID" --documents "$HARNESS_APP_ID"
    check_exit_code
    sleep 2
    
    # needed for scrolling to keep in sync w/ device's ifuse fs
    perl -e "while (1) {sleep 1; system qw (ls $IOS_MOUNTPOINT);} " > /dev/null 2>&1 &
    REFRESH_PID=$!
    sleep 2
    
    tail -f $IOS_MOUNTPOINT/perl-tests.tap
    
    echo "kill $REFRESH_PID"
    kill $REFRESH_PID
    check_exit_code
    
    umount -f $IOS_MOUNTPOINT
    
    rm -Rf $IOS_MOUNTPOINT
    check_exit_code
}

build_camelbones_framework() {

    pushd camelbones/CamelBones
    build_libffi
    check_exit_code

    xcodebuild ARCHS="$ARCHS" PERL_DIST_PATH="$PERL_INSTALL_PREFIX/lib/perl5" \
    LIBPERL_PATH="$PERL_INSTALL_PREFIX/lib/perl5/$PERL_VERSION/darwin-thread-multi-2level/CORE" \
    PERL_VERSION="$PERL_VERSION" ARCHS="$ARCHS" ONLY_ACTIVE_ARCH=NO \
    -allowProvisioningUpdates -scheme "$CAMELBONES_TARGET"
    popd
}

build_macos_perl() {
    # uninstall perl-blead
    echo "Uninstalling perl-blead"
    perlbrew uninstall -q perl-blead

    echo "Installing perl-blead"
    # macOS generate_uudmap and miniperl are used in cross builds
    MACOSX_DEPLOYMENT_TARGET=10.5 perlbrew install -Dusedevel -Duselargefiles \
        -Dcccdlflags='-fPIC -DPERL_USE_SAFE_PUTENV' -Doptimize=-O3 -Duseshrplib \
        -Duse64bitall --thread --multi --64int --clan blead
    perlbrew alias create perl-blead "perl-$PERL_VERSION"
    
    pushd ~/perl5/perlbrew/build
    ln -s blead/perl5-blead "perl-$PERL_VERSION"
    popd
    
    perlbrew use "perl-$PERL_VERSION"

    # for test app build to re-link and sign binaries, see fix_ios_dylibs.sh
    cpanm File::Copy::Recursive
    cpanm File::Find::Rule
}

####################################################################

echo "Build started: $(date)"

trap _term SIGINT

check_dependencies

use_perlbrew

mkdir -p ext
rm -f "ext/CamelBones-$CAMELBONES_VERSION".tar.gz

prepare_ios
PERL_ARCH="$ARCHS" DEBUG=1 sh -x "perl-$PERL_VERSION/ios/build.sh"
check_exit_code

prepare_camelbones
build_camelbones_framework
check_exit_code

prepare_ios
mkdir -p $CAMELBONES_CPAN_DIR
chmod -R +w $CAMELBONES_CPAN_DIR
echo cp -R "$WORKDIR/camelbones/CamelBones/CPAN/." $CAMELBONES_CPAN_DIR/
cp -R "$WORKDIR/camelbones/CamelBones/CPAN/." $CAMELBONES_CPAN_DIR/
PERL_ARCH="$ARCHS" DEBUG=1 sh -x "perl-$PERL_VERSION/ios/build.sh"
check_exit_code

test_perl_device

echo "Build finished: $(date)"
