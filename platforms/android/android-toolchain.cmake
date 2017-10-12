macro(setup_android_vars)
    # sdk home
    if (NOT ANDROID_HOME)
        set(ANDROID_HOME $ENV{ANDROID_HOME})
    endif()

    # ndk home
    if (NOT ANDROID_NDK_HOME)
        set(ANDROID_NDK_HOME $ENV{ANDROID_NDK_HOME})
    endif()

    # cache for ndk standalone
    if (NOT ANDROID_NDK_CACHE)
        set(ANDROID_NDK_CACHE $ENV{ANDROID_NDK_CACHE})
    endif()
    if (NOT ANDROID_NDK_CACHE)
        set(ANDROID_NDK_CACHE ${CMAKE_BINARY_DIR})
    endif()

    # arch 
    if (NOT ARCH)
        set(ARCH $ENV{ARCH})
    endif()
    if (NOT ARCH)
        set(ARCH "arm")
    endif()
    if ("${ARCH}" STREQUAL arm)
        set(ARCH_EABI armeabi-v7a)
        set(ARCH_PREFIX "${ARCH}")
        set(ANDROID_PLATFORM_DEFAULT android-9)
    elseif ("${ARCH}" STREQUAL arm64)
        set(ARCH_EABI arm64-v8a)
        set(ARCH_PREFIX aarch64)
        set(ANDROID_PLATFORM_DEFAULT android-21)
    elseif ("${ARCH}" STREQUAL x86)
        set(ARCH_EABI "${ARCH}")
        set(ARCH_PREFIX i686)
        set(ANDROID_PLATFORM_DEFAULT android-9)
    elseif ("${ARCH}" STREQUAL x86_64)
        set(ARCH_EABI "${ARCH}")
        set(ARCH_PREFIX "${ARCH}")
        set(ANDROID_PLATFORM_DEFAULT android-21)
    else()
        set(ARCH_EABI "${ARCH}")
        set(ARCH_PREFIX "${ARCH}")
        set(ANDROID_PLATFORM_DEFAULT android-9)
    endif()

    # platform
    if (NOT ANDROID_PLATFORM)
        set(ANDROID_PLATFORM $ENV{ANDROID_PLATFORM})
    endif()
    if (NOT ANDROID_PLATFORM)
        set(ANDROID_PLATFORM ${ANDROID_PLATFORM_DEFAULT})
    endif()

    set(ANDROID_NDK_COMPILER_PREFIX ${ARCH_PREFIX}-linux-android)
    set(ANDROID_LINKER_FLAGS "-landroid -llog")

    if ("${ARCH}" STREQUAL "arm")
        set(ANDROID_NDK_COMPILER_PREFIX arm-linux-androideabi)
        set(ANDROID_C_FLAGS "-march=armv7-a -mfloat-abi=softfp -mfpu=neon")

        # NDK docs say "*required* to use the following linker flags that routes around a CPU bug in some Cortex-A8 implementations"
        set(ANDROID_LINKER_FLAGS "${ANDROID_LINKER_FLAGS} -Wl,--fix-cortex-a8")

        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   ${ANDROID_C_FLAGS}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ANDROID_C_FLAGS}")
    endif()

    set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    ${ANDROID_LINKER_FLAGS} -pie")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${ANDROID_LINKER_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ANDROID_LINKER_FLAGS}")
endmacro()

macro(setup_android_ndk)
    get_filename_component(ANDROID_NDK_BASENAME "${ANDROID_NDK_HOME}" NAME)
    
    set(ANDROID_NDK_STANDALONE_HOME ${ANDROID_NDK_CACHE}/${ANDROID_NDK_BASENAME}_${ANDROID_PLATFORM}_${ARCH})
    if (NOT EXISTS ${ANDROID_NDK_STANDALONE_HOME})
        message(STATUS "setting up android ndk standalone at ${ANDROID_NDK_STANDALONE_HOME}")
        message("${ANDROID_NDK_HOME}/build/tools/make-standalone-toolchain.sh --platform=${ANDROID_PLATFORM} --arch=${ARCH} --install-dir=${ANDROID_NDK_STANDALONE_HOME}")
        execute_process(
                COMMAND         ${ANDROID_NDK_HOME}/build/tools/make-standalone-toolchain.sh --platform=${ANDROID_PLATFORM} --arch=${ARCH} --install-dir=${ANDROID_NDK_STANDALONE_HOME}
                RESULT_VARIABLE NDK_STANDALONE_RESULT
            )
    endif()
endmacro()

macro(setup_android)
    setup_android_vars()
    setup_android_ndk()
endmacro()

setup_android()
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(ANDROID 1)
set(PLATFORM "android")
set(DEFAULT_ARCHES arm;arm64;x86;x86_64)

set(CMAKE_C_COMPILER     ${ANDROID_NDK_STANDALONE_HOME}/bin/${ANDROID_NDK_COMPILER_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER   ${ANDROID_NDK_STANDALONE_HOME}/bin/${ANDROID_NDK_COMPILER_PREFIX}-g++)

set(CMAKE_FIND_ROOT_PATH ${ANDROID_NDK_STANDALONE_HOME})
#set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
#set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
