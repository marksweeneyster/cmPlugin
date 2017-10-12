macro(setup_toolchain)
    if (NOT CMAKE_TOOLCHAIN_FILE)
        if (ANDROID)
            set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/platforms/android/toolchain.cmake)
            include("${CMAKE_TOOLCHAIN_FILE}")
    
            message(STATUS "ANDROID_HOME= ${ANDROID_HOME}")
            message(STATUS "ANDROID_NDK_HOME= ${ANDROID_NDK_HOME}")
            message(STATUS "ANDROID_NDK_STANDALONE_HOME= ${ANDROID_NDK_STANDALONE_HOME}")
            message(STATUS "ARCH= ${ARCH} (${ARCH_EABI})")
            message(STATUS "ANDROID_PLATFORM= ${ANDROID_PLATFORM}")
        elseif (IOS)
            set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/platforms/ios/iOS-toolchain.cmake)
            include("${CMAKE_TOOLCHAIN_FILE}")
        elseif (TIZEN)
            set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/platforms/tizen/tizen-toolchain.cmake) 
            include("${CMAKE_TOOLCHAIN_FILE}")
        elseif (APPLE)
        elseif (UNIX)
            set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/platforms/linux/linux-toolchain.cmake) 
            include("${CMAKE_TOOLCHAIN_FILE}")
        endif()
    endif()
endmacro()

macro(setup_platforms)
    # default build type
    if (NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Debug)
    endif()

    if (UNIX AND NOT APPLE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
    elseif (UNIX)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")
    endif()

    if (UNIX)
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fPIC")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    endif()

    if (TIZEN)
        set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -DTIZEN")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DTIZEN")
    endif()

    find_program(LS ls)
    if (WIN32)
        set(PATH_LIST_SEPARATOR "\;")
    else()
        set(PATH_LIST_SEPARATOR ":")
    endif()

    if (ANDROID)
        setup_android()
        find_package(Java REQUIRED)
        set(JAVA 1)

        if (NOT CMAKE_BUILD_TYPE STREQUAL Debug)
            set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   -DNDEBUG")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNDEBUG")
        endif()
    elseif (NOT IOS AND NOT TIZEN)
        find_package(Java REQUIRED)
        find_package(JNI REQUIRED)
        if (JNI_FOUND)
            set(JAVA 1)
        endif()

        setup_python()
    endif()

    if (MSVC)
        set(all_flags
            CMAKE_C_FLAGS
            CMAKE_C_FLAGS_DEBUG
            CMAKE_C_FLAGS_MINSIZEREL
            CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_CXX_FLAGS
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_MINSIZEREL
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_RELWITHDEBINFO)
        if (NOT MSVC_SHARED_RT)
            set(LIB_RT_SUFFIX mt)
            set(LIB_RT_FLAG  /MT)
            message(STATUS "MSVC: using statically-linked runtime (${LIB_RT_FLAG}).")
        else()
            set(LIB_RT_SUFFIX md)
            set(LIB_RT_FLAG  /MD)
            message(STATUS "MSVC: using dynamically-linked runtime (${LIB_RT_FLAG}).")
        endif()

        foreach(flag ${all_flags})
            if(${flag} MATCHES "/MD")
                string(REGEX REPLACE "/MD" "${LIB_RT_FLAG}" ${flag} "${${flag}}")
            endif()
        endforeach()

        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_CRT_SECURE_NO_WARNINGS -DNOMINMAX -D_USE_MATH_DEFINES")
    endif()

    setup_swig()
    setup_valgrind()
endmacro()

macro(setup_installation)
    # add install target that will install things only from this project    
    set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME ${PROJECT_NAME})
    add_custom_target(install_${PROJECT_NAME} 
                      COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target preinstall
                      COMMAND ${CMAKE_COMMAND} -DCOMPONENT=${PROJECT_NAME} -P ${PROJECT_BINARY_DIR}/cmake_install.cmake)
endmacro()

macro(setup_python)
    # CMake's python-detection is crazy broken, so we use python-config on *nix.
    # Sadly on Windows python-config isn't available, so do our best with CMake.
    #
    # see https://cmake.org/Bug/view.php?id=14809
    #
    if (WIN32)
        find_package(PythonInterp)
        find_package(PythonLibs)

        set(PYTHON_CFLAGS "-I${PYTHON_INCLUDE_PATH}")
        set(PYTHON_LDFLAGS "${PYTHON_LIBRARIES}")
        set(PYTHON_VERSION "${PYTHON_VERSION_STRING}")
        get_filename_component(PYTHON_DIR ${PYTHON_EXECUTABLE} DIRECTORY)
        set(PYTHON_TOOLS_DIR ${PYTHON_DIR}/Scripts)

        # hack to fix spaces-in-paths
        string(REGEX REPLACE "(.:\\/.*)\\w*" "\"\\1\"" PYTHON_CFLAGS "${PYTHON_CFLAGS}")
        string(REGEX REPLACE "(.:\\/.*)\\w*" "\"\\1\"" PYTHON_LDFLAGS "${PYTHON_LDFLAGS}")
    else()
        if (("${ARCH}" STREQUAL armv7l OR "${ARCH}" STREQUAL arm) AND NOT ANDROID AND NOT IOS)
            find_program(PYTHON_CONFIG_EXECUTABLE arm-linux-gnueabihf-python-config NO_CMAKE_FIND_ROOT_PATH)
        elseif (NOT ARCH STREQUAL "aarch64")
            find_program(PYTHON_CONFIG_EXECUTABLE python-config NO_CMAKE_FIND_ROOT_PATH)
        endif()
        if (PYTHON_CONFIG_EXECUTABLE)
            execute_process(COMMAND ${PYTHON_CONFIG_EXECUTABLE} --cflags OUTPUT_VARIABLE PYTHON_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
            execute_process(COMMAND ${PYTHON_CONFIG_EXECUTABLE} --ldflags OUTPUT_VARIABLE PYTHON_LDFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
            if (NOT PYTHON_EXECUTABLE)
                execute_process(COMMAND ${PYTHON_CONFIG_EXECUTABLE} --exec-prefix OUTPUT_VARIABLE PYTHON_EXECUTABLE OUTPUT_STRIP_TRAILING_WHITESPACE)
                set(PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE}/bin/python)
            endif()

            get_filename_component(PYTHON_DIR ${PYTHON_EXECUTABLE} DIRECTORY)
            set(PYTHON_TOOLS_DIR ${PYTHON_DIR})

            # get the python version
            execute_process(COMMAND ${PYTHON_EXECUTABLE} --version ERROR_VARIABLE PYTHON_VERSION)
            string(STRIP ${PYTHON_VERSION} PYTHON_VERSION)
            string(REPLACE " " ";" PYTHON_VERSION ${PYTHON_VERSION})
            list(GET PYTHON_VERSION 1 PYTHON_VERSION)
        endif()
    endif()

    if (PYTHON_EXECUTABLE)
        message(STATUS "PYTHON_EXECUTABLE= ${PYTHON_EXECUTABLE}")
        message(STATUS "PYTHON_VERSION= ${PYTHON_VERSION}")
        message(STATUS "PYTHON_CFLAGS= ${PYTHON_CFLAGS}")
        message(STATUS "PYTHON_LDFLAGS= ${PYTHON_LDFLAGS}")

        find_program(VIRTUALENV virtualenv HINTS ${PYTHON_TOOLS_DIR})
        if (VIRTUALENV STREQUAL VIRTUALENV-NOTFOUND)
            message(FATAL_ERROR "virtualenv not found")
        endif()

        if (NOT ANDROID AND NOT IOS)
            set(PYTHON 1)
        endif()
    endif()
endmacro()

macro(setup_output_dirs)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})

    set(INSTALL_RUNTIME_DIRECTORY bin)
    set(INSTALL_LIBRARY_DIRECTORY lib)
    set(INSTALL_ARCHIVE_DIRECTORY lib)

    if (NOT "${ARGV0}" STREQUAL "")
        set(suffix "${ARGV0}/")
    endif()
    if (ANDROID)
        set(suffix "${suffix}${ARCH_EABI}")
    endif()

    # append the suffix onto all output dirs
    set(OUTPUT_DIRS CMAKE_RUNTIME_OUTPUT_DIRECTORY;CMAKE_LIBRARY_OUTPUT_DIRECTORY;CMAKE_ARCHIVE_OUTPUT_DIRECTORY;INSTALL_RUNTIME_DIRECTORY;INSTALL_LIBRARY_DIRECTORY;INSTALL_ARCHIVE_DIRECTORY)
    foreach(var ${OUTPUT_DIRS})
        set(${var} ${${var}}/${suffix})
    endforeach()
endmacro()

macro(setup_openv)
    # opencv's dist for ios is just a framework-- no cmake stuff :(
    if (IOS)
        set(OpenCV_DIR $ENV{OPENCV_IOS_HOME})
        find_library(OpenCV_FRAMEWORK opencv2 PATHS ${OpenCV_DIR}/..)

        message(STATUS "OpenCV_FRAMEWORK= ${OpenCV_FRAMEWORK}")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -F ${OpenCV_DIR}/..")
        set(OpenCV_LIBS "-framework opencv2 -framework Foundation -framework AVFoundation -framework CoreGraphics -framework ImageIO -framework CoreVideo -framework CoreMedia")
        set(opencv_fat_lib ${OpenCV_DIR}/opencv2)

        set(opencv_thin_lib ${CMAKE_BINARY_DIR}/libs/opencv/libopencv2_${ARCH}.a)
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/libs/opencv)
        add_custom_command(COMMAND lipo -extract ${ARCH} ${opencv_fat_lib} -output ${opencv_thin_lib}
                           OUTPUT ${opencv_thin_lib}
                           DEPENDS ${opencv_fat_lib}
                           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                          )
        add_custom_target(opencv_thin DEPENDS ${opencv_thin_lib})

        add_library(opencv_core STATIC IMPORTED GLOBAL)
        add_dependencies(opencv_core opencv_thin)
        set_property(TARGET opencv_core PROPERTY IMPORTED_LOCATION ${opencv_thin_lib})
    else()
        if (ANDROID)
            set(OpenCV_DIR $ENV{OPENCV_ANDROID_HOME}/sdk/native/jni)

            # special opencv vars
            set(ANDROID_NDK_ABI_NAME ${ARCH})
            if (${ANDROID_NDK_ABI_NAME} STREQUAL "armv7-a")
                set(ANDROID_NDK_ABI_NAME armeabi_v7a)
            endif()
        elseif (UNIX AND ARCH)
            string(TOUPPER "${ARCH}" ARCHU)
            set(OpenCV_DIR $ENV{OPENCV_${ARCHU}_HOME}/share/OpenCV)
        elseif (DEFINED ENV{OPENCV_HOME})
            set(OpenCV_DIR $ENV{OPENCV_HOME}/share/OpenCV)
        endif()

        if (OpenCV_DIR)
            set(opencv_package_args NO_DEFAULT_PATH)
            message(STATUS "OpenCV_DIR= ${OpenCV_DIR}")
        endif()
        set(OpenCV_STATIC ON)

        find_package(OpenCV REQUIRED ${opencv_package_args})
        set_target_properties(opencv_core PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${OpenCV_INCLUDE_DIRS}")
        message(STATUS "OpenCV_INCLUDE_DIRS= ${OpenCV_INCLUDE_DIRS}")
    endif()

    message(STATUS "OpenCV_LIBS= ${OpenCV_LIBS}")
endmacro()

macro(setup_platform_utils)
    if (NOT TARGET platform_utils)
        set(platform_utils_path libs/platform_utils)
        include_directories(${platform_utils_path}/include)
        file(GLOB_RECURSE srcs ${platform_utils_path}/src/*.cpp)
        file(GLOB_RECURSE platform_utils_test_srcs ${platform_utils_path}/test/*.cpp)
        add_library(platform_utils STATIC ${srcs})
    endif()
endmacro()

macro(setup_valgrind)
    find_program(CTEST_COVERAGE_COMMAND NAMES gcov)
    message(STATUS "CTEST_COVERAGE_COMMAND   = ${CTEST_COVERAGE_COMMAND}")

    if (VALGRIND)
        find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
        if (CTEST_MEMORYCHECK_COMMAND)
            set(CTEST_MEMORYCHECK_COMMAND_OPTIONS
                    --leak-check=full --error-exitcode=42
                    --gen-suppressions=all --suppressions=${CMAKE_SOURCE_DIR}/test/unit/valgrind.supp
                )

            if (APPLE)
                set(CTEST_MEMORYCHECK_COMMAND_OPTIONS ${CTEST_MEMORYCHECK_COMMAND_OPTIONS}
                    --dsymutil=yes)
            endif()
            if (CI)
                set(CTEST_MEMORYCHECK_COMMAND_OPTIONS ${CTEST_MEMORYCHECK_COMMAND_OPTIONS}
                    --xml=yes --xml-file=valgrind.xml)
            endif()
        else()
            message(FATAL_ERROR "Cannot find CTEST_MEMORYCHECK_COMMAND")
        endif()
        message(STATUS "CTEST_MEMORYCHECK_COMMAND= ${CTEST_MEMORYCHECK_COMMAND}")
    endif()
endmacro()

macro(setup_swig)
    if (NOT SWIG_DIR)
        set(SWIG_DIR $ENV{SWIG_DIR} )
    endif()
    if (NOT SWIG_EXECUTABLE)
        set(SWIG_EXECUTABLE $ENV{SWIG_EXECUTABLE} )
    endif()
    find_package(SWIG REQUIRED)
    INCLUDE(${SWIG_USE_FILE})
    message(STATUS "SWIG_DIR  = ${SWIG_DIR}" )
    message(STATUS "SWIG_EXECUTABLE  = ${SWIG_EXECUTABLE}" )
endmacro()

macro(setup_gtest)
    enable_testing()
    if (NOT TARGET gtest)
        option(
          gtest_force_shared_crt
          "Use shared (DLL) run-time lib even when Google Test is built as static lib."
          ${MSVC_SHARED_RT})
        add_subdirectory(${PROJECT_SOURCE_DIR}/libs/gtest/googletest)    
    endif()
endmacro()

macro(setup_licenser)
    # licensing sdk
    include_directories(${PROJECT_SOURCE_DIR}/libs/sdk_licensing/src/check)

    # licenser tool that injects license
    find_program(LICENSER sdk-license HINTS ${PROJECT_SOURCE_DIR}/build/tools/bin)
    if (NOT LICENSER)
        message(FATAL_ERROR "Cannot find licenser tool")
    endif()

    # license to inject
    if (NOT LICENSE)
        set(LICENSE $ENV{LICENSE})
    endif()
    if (NOT LICENSE)
        message(STATUS "No LICENSE supplied")
    endif()
endmacro()

