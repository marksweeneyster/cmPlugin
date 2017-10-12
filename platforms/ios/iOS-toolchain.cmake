# Standard settings
set (CMAKE_SYSTEM_NAME Linux)
set (CMAKE_SYSTEM_VERSION 1 )
set (UNIX True CACHE BOOLEAN "" FORCE)
set (APPLE True CACHE BOOLEAN "" FORCE)
set (IOS True CACHE BOOLEAN "" FORCE)

# arch
if (NOT ARCH)
    set(ARCH $ENV{ARCH})
endif()
if (NOT ARCH)
    set(ARCH armv7s)
endif()

# workaround to preserve vars across toolchain invocations
set(ENV{ARCH} ${ARCH})

# the arch drives the platform
if (${ARCH} STREQUAL "i386" OR ${ARCH} STREQUAL "x86_64")
	set (IOS_PLATFORM_NAME "iPhoneSimulator.platform")
else()
	set (IOS_PLATFORM_NAME "iPhoneOS.platform")
	set (IOS_EXTRA_C_FLAGS -fembed-bitcode)
endif ()

# Setup iOS developer location
if (NOT DEFINED CMAKE_IOS_DEVELOPER_ROOT)
	set (CMAKE_IOS_DEVELOPER_ROOT "/Applications/Xcode.app/Contents/Developer")
endif ()
set (CMAKE_IOS_DEVELOPER_ROOT ${CMAKE_IOS_DEVELOPER_ROOT} CACHE PATH "Location of iOS Platform")

# xcode tools
if (NOT DEFINED XCODE_TOOLCHAIN)
    set(XCODE_TOOLCHAIN "${CMAKE_IOS_DEVELOPER_ROOT}/Toolchains/XcodeDefault.xctoolchain")
endif()
set (XCODE_TOOLCHAIN ${XCODE_TOOLCHAIN} CACHE PATH "Location of XCode default toolchain")

# Setup sdk "root"
if (NOT DEFINED CMAKE_IOS_SDK_ROOT)
	set (CMAKE_IOS_SDK_ROOT "${CMAKE_IOS_DEVELOPER_ROOT}/Platforms/${IOS_PLATFORM_NAME}/Developer")
endif ()
set (CMAKE_IOS_SDK_ROOT ${CMAKE_IOS_SDK_ROOT} CACHE PATH "Location of iOS Platform")

# Find and use the most recent iOS sdk 
if (NOT DEFINED CMAKE_IOS_SDK)
	file (GLOB _CMAKE_IOS_SDKS "${CMAKE_IOS_SDK_ROOT}/SDKs/*")
	if (_CMAKE_IOS_SDKS) 
		list (SORT _CMAKE_IOS_SDKS)
		list (REVERSE _CMAKE_IOS_SDKS)
		list (GET _CMAKE_IOS_SDKS 0 CMAKE_IOS_SDK)
	else (_CMAKE_IOS_SDKS)
		message (FATAL_ERROR "No iOS SDK's found in default seach path ${CMAKE_IOS_SDK_ROOT}. Manually set CMAKE_IOS_SDK or install the iOS SDK.")
	endif ()

	# parse the version number out of the sdk path
	string(REGEX MATCH "([0-9]+\\.[0-9]+)" IOS_VERSION ${CMAKE_IOS_SDK})
	set(IOS_VERSION ${IOS_VERSION} CACHE STRING "" FORCE)

	message (STATUS "Toolchain using default iOS SDK: ${CMAKE_IOS_SDK}")
	message (STATUS "IOS_VERSION= ${IOS_VERSION}")
endif ()
set (CMAKE_IOS_SDK ${CMAKE_IOS_SDK} CACHE PATH "Location of the selected iOS SDK")

# minimum ios version to support bitcode
set (IOS_VERSION_MIN 6.0)

# Set the sysroot default to the most recent SDK
set (CMAKE_SYSROOT ${CMAKE_IOS_SDK})

# All iOS/Darwin specific settings - some may be redundant
set (CMAKE_SHARED_LIBRARY_PREFIX "lib")
set (CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set (CMAKE_SHARED_MODULE_PREFIX "lib")
set (CMAKE_SHARED_MODULE_SUFFIX ".so")
set (CMAKE_MODULE_EXISTS 1)
set (CMAKE_DL_LIBS "")

set (CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set (CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set (CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set (CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

set (CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set (CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -headerpad_max_install_names")
set (CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -headerpad_max_install_names")
set (CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set (CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set (CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a")

set (CMAKE_C_CREATE_MACOSX_FRAMEWORK
    "<CMAKE_C_COMPILER> <LANGUAGE_COMPILE_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS> <LINK_FLAGS> -o <TARGET> -install_name <TARGET_INSTALLNAME_DIR><TARGET_SONAME> <OBJECTS> <LINK_LIBRARIES>")
set (CMAKE_CXX_CREATE_MACOSX_FRAMEWORK
    "<CMAKE_CXX_COMPILER> <LANGUAGE_COMPILE_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS> <LINK_FLAGS> -o <TARGET> -install_name <TARGET_INSTALLNAME_DIR><TARGET_SONAME> <OBJECTS> <LINK_LIBRARIES>")

# Set the find root to the iOS developer roots and to user defined paths
set (CMAKE_FIND_ROOT_PATH ${XCODE_TOOLCHAIN} ${CMAKE_IOS_DEVELOPER_ROOT} ${CMAKE_IOS_SDK} ${CMAKE_IOS_SDK_ROOT} ${CMAKE_PREFIX_PATH} CACHE string  "iOS find search path root")

# default to searching for frameworks first
set (CMAKE_FIND_FRAMEWORK FIRST)

# set up the default search directories for frameworks
set (CMAKE_SYSTEM_FRAMEWORK_PATH
	${CMAKE_IOS_SDK}/System/Library/Frameworks
	${CMAKE_IOS_SDK}/System/Library/PrivateFrameworks
	${CMAKE_IOS_SDK}/Developer/Library/Frameworks
)

# only search the iOS sdks, not the remainder of the host filesystem
#set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
#set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# compile flags

set (CMAKE_C_FLAGS   "-miphoneos-version-min=${IOS_VERSION_MIN} -arch ${ARCH} ${IOS_EXTRA_C_FLAGS}" CACHE STRING "" FORCE)
set (CMAKE_CXX_FLAGS "-miphoneos-version-min=${IOS_VERSION_MIN} -arch ${ARCH} -stdlib=libc++ ${IOS_EXTRA_C_FLAGS}" CACHE STRING "" FORCE)

set (CMAKE_C_LINK_FLAGS   "-arch ${ARCH}")
set (CMAKE_CXX_LINK_FLAGS "-arch ${ARCH}")

# compilers (something is wrong with cmake's auto finding of ar/ranlib, so lets do it manually)

find_program(CMAKE_C_COMPILER clang)
find_program(CMAKE_CXX_COMPILER clang++)
find_program(CMAKE_AR ar)
find_program(CMAKE_RANLIB ranlib)
