#!/bin/bash

tar -xjf leptonica-1.69.tar.bz2.tar.bz2
tar -xjf tesseract-ocr-3.02.02.tar.gz

GLOBAL_OUTDIR="`pwd`/../"
LOCAL_OUTDIR="./outdir"
LEPTON_LIB="`pwd`/leptonica-1.69"
TESSERACT_LIB="`pwd`/tesseract-ocr"

IOS_BASE_SDK="7.0"
IOS_DEPLOY_TGT="6.1"

print_compilers_settings()
{
	CXX=`xcrun -f clang++`
	CC=`xcrun  -f  clang`
	LD=`xcrun  -f  ld`
	AR=`xcrun  -f  ar`
	AS=`xcrun  -f  as`
	NM=`xcrun  -f  nm`
	RANLIB=`xcrun  -f  ranlib`
	echo "CFLAGS	$CFLAGS"
	echo "CXX	$CXX"
	echo "CC	$CC"
	echo "LD	$LD"
	echo "AR	$AR"
	echo "AS	$AS"
	echo "NM	$NM"
	echo "RANLIB	$RANLIB"	
}

setenv_all()
{
	# Add internal libs
	export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib"
	
	export CXX=`xcrun -f clang++`
	export CC=`xcrun  -f  clang`
	export LD=`xcrun  -f  ld`
	export AR=`xcrun  -f  ar`
	export AS=`xcrun  -f  as`
	export NM=`xcrun  -f  nm`
	export RANLIB=`xcrun  -f  ranlib`

	# export CXX=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
	# export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
	# export LD=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld
	# export AR=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
	# export AS=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/as
	# export NM=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
	# export RANLIB=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib

	export LDFLAGS="-L$SDKROOT/usr/lib/"
	
	export CPPFLAGS=$CFLAGS
	export CXXFLAGS=$CFLAGS

	echo "CFLAGS	$CFLAGS"
	echo "CXX	$CXX"
	echo "CC	$CC"
	echo "LD	$LD"
	echo "AR	$AR"
	echo "AS	$AS"
	echo "NM	$NM"
	echo "RANLIB	$RANLIB"
	echo "LDFLAGS	$LDFLAGS"
	echo "CPPFLAG	$CPPFLAG"
	echo "CXXFLAG	$CXXFLAG"
}

setenv_arm7()
{
	unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
	
  	export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
	export SDKROOT=$DEVROOT/SDKs/iPhoneOS$IOS_BASE_SDK.sdk
	
	export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"
	
	setenv_all
}

setenv_i386()
{
	unset DEVROOT SDKROOT CFLAGS CC LD CPP CXX AR AS NM CXXCPP RANLIB LDFLAGS CPPFLAGS CXXFLAGS
	
	export DEVROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
	export SDKROOT=$DEVROOT/SDKs/iPhoneSimulator$IOS_BASE_SDK.sdk
	
	export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"
	
	setenv_all
}

create_outdir_lipo()
{
	for lib_i386 in `find $LOCAL_OUTDIR/i386 -name "lib*\.a"`; do
		lib_arm7=`echo $lib_i386 | sed "s/i386/arm7/g"`
		lib=`echo $lib_i386 | sed "s/i386\///g"`
		lipo -arch armv7 $lib_arm7 -arch i386 $lib_i386 -create -output $lib
	done
}

merge_libfiles()
{
	DIR=$1
	LIBNAME=$2
	
	cd $DIR
	for i in `find . -name "lib*.a"`; do
		$AR -x $i
	done
	$AR -r $LIBNAME *.o
	rm -rf *.o __*
	cd -
}


#######################
# LEPTONLIB
#######################
cd $LEPTON_LIB
rm -rf $LOCAL_OUTDIR
mkdir -p $LOCAL_OUTDIR/arm7 $LOCAL_OUTDIR/i386

# armv7
echo 'Compiling LEPTONLIB for armv7'

make clean &> /dev/null
make distclean &> /dev/null
setenv_arm7
./configure --host=arm-apple-darwin6 --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff &> ./build.log || exit;

make -j4 &> /dev/null
cp -rf src/.libs/lib*.a $LOCAL_OUTDIR/arm7

# i386
echo 'Compiling LEPTONLIB for i386'

make clean &> /dev/null
make distclean &> /dev/null
setenv_i386
./configure --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff &> ./build.log || exit;
make -j4 &> /dev/null
cp -rf src/.libs/lib*.a $LOCAL_OUTDIR/i386

create_outdir_lipo
mkdir -p $GLOBAL_OUTDIR/include/leptonica && cp -rf src/*.h $GLOBAL_OUTDIR/include/leptonica
mkdir -p $GLOBAL_OUTDIR/lib && cp -rf $LOCAL_OUTDIR/lib*.a $GLOBAL_OUTDIR/lib
cd ..

#######################
# TESSERACT-OCR (v3)
#######################
cd $TESSERACT_LIB
rm -rf $LOCAL_OUTDIR
mkdir -p $LOCAL_OUTDIR/arm7 $LOCAL_OUTDIR/i386

# armv7
echo 'Compiling TESSERACT-OCR for armv7'

make clean &> /dev/null
make distclean &> /dev/null
setenv_arm7
bash autogen.sh &> /dev/null
./configure --host=arm-apple-darwin6 --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/ &> ./build.log || exit;

make -j4 &> /dev/null
for i in `find . -name "lib*.a"`; do cp -rf $i $LOCAL_OUTDIR/arm7; done
merge_libfiles $LOCAL_OUTDIR/arm7 libtesseract_all.a

# i386
echo 'Compiling TESSERACT-OCR for i386'
make clean &> /dev/null
make distclean &> /dev/null
setenv_i386
bash autogen.sh &> /dev/null
./configure --enable-shared=no LIBLEPT_HEADERSDIR=$GLOBAL_OUTDIR/include/ &> ./build.log || exit;
make -j4 &> /dev/null
for i in `find . -name "lib*.a" | grep -v arm`; do cp -rf $i $LOCAL_OUTDIR/i386; done
merge_libfiles $LOCAL_OUTDIR/i386 libtesseract_all.a

create_outdir_lipo
mkdir -p $GLOBAL_OUTDIR/include/tesseract
tess_inc=( api/*.h ccmain/*.h ccstruct/*.h ccutil/*.h )
for i in "${tess_inc[@]}"; do
   cp -rf $i $GLOBAL_OUTDIR/include/tesseract
done
mkdir -p $GLOBAL_OUTDIR/lib && cp -rf $LOCAL_OUTDIR/libtesseract_all.a $GLOBAL_OUTDIR/lib
make clean &> /dev/null
make distclean &> /dev/null
rm -rf $LOCAL_OUTDIR
cd ..


rm -rf ./leptonica-1.69
rm -rf ./tesseract-ocr

echo "Finished!"
