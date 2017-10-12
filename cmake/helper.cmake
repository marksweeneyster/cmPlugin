set(HELPER_DIR ${CMAKE_CURRENT_LIST_DIR})

macro(setup_output_dirs)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})

    set(INSTALL_RUNTIME_DIRECTORY bin)
    set(INSTALL_LIBRARY_DIRECTORY lib/${PROJECT_NAME})
    set(INSTALL_ARCHIVE_DIRECTORY lib/${PROJECT_NAME})
    set(INSTALL_HEADER_DIRECTORY  include/${PROJECT_NAME})

    set(suffix)
    if (NOT "${ARGV0}" STREQUAL "")
        set(suffix "${ARGV0}/")
    endif()
    set(CMAKE_JAR_OUTPUT_DIRECTORY     ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/${suffix})
    set(INSTALL_JAR_DIRECTORY          ${INSTALL_ARCHIVE_DIRECTORY}/${suffix})

    if (ANDROID)
        set(suffix "${suffix}${ARCH_EABI}")
    elseif (TIZEN)
        set(suffix "${suffix}${TIZEN_SDK_VERSION}/${ARCH}/${TIZEN_BUILD_TYPE}")
    elseif (ARCH)
        set(suffix "${suffix}${ARCH}")
    endif()

    # append the suffix onto all output dirs
    set(OUTPUT_DIRS CMAKE_RUNTIME_OUTPUT_DIRECTORY;CMAKE_LIBRARY_OUTPUT_DIRECTORY;CMAKE_ARCHIVE_OUTPUT_DIRECTORY;INSTALL_RUNTIME_DIRECTORY;INSTALL_LIBRARY_DIRECTORY;INSTALL_ARCHIVE_DIRECTORY)
    foreach(var ${OUTPUT_DIRS})
        set(${var} ${${var}}/${suffix})
    endforeach()
endmacro()

# Merge static libraries into a big static lib. The resulting library 
# should not not have dependencies on other static libraries.
MACRO(MERGE_STATIC_LIBS TARGET OUTPUT_NAME LIBS_TO_MERGE)
    # To produce a library we need at least one source file.
    # It is created by ADD_CUSTOM_COMMAND below and will helps 
    # also help to track dependencies.
    SET(SOURCE_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_depends.c)
    ADD_LIBRARY(${TARGET} STATIC ${SOURCE_FILE})
    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES OUTPUT_NAME ${OUTPUT_NAME})

    IF (UNIX)
        SET(UNAR_DIR ${CMAKE_CURRENT_BINARY_DIR}/${TARGET})
        file(MAKE_DIRECTORY ${UNAR_DIR})
    ENDIF()

    # Make the generated dummy source file depended on all static input
    # libs. If input lib changes,the source file is touched
    # which causes the desired effect (relink).
    ADD_CUSTOM_COMMAND( 
        OUTPUT    ${SOURCE_FILE}
        COMMAND ${CMAKE_COMMAND}    -E touch ${SOURCE_FILE}
        DEPENDS ${LIBS_TO_MERGE})

    SET(STATIC_LIBS)
    FOREACH(LIB ${LIBS_TO_MERGE})
        GET_TARGET_PROPERTY(LIB_LOCATION ${LIB} LOCATION_${CMAKE_BUILD_TYPE})
        IF (NOT LIB_LOCATION)
                GET_TARGET_PROPERTY(LIB_LOCATION ${LIB} LOCATION_${CMAKE_BUILD_TYPE})
        ENDIF()
        GET_TARGET_PROPERTY(LIB_TYPE ${LIB} TYPE)
        
        IF(NOT LIB_LOCATION AND EXISTS ${LIB})
             SET(LIB_LOCATION ${LIB})        
             LIST(APPEND STATIC_LIBS ${LIB_LOCATION})
        ELSEIF(LIB_TYPE STREQUAL "STATIC_LIBRARY")
             LIST(APPEND STATIC_LIBS ${LIB_LOCATION})
             ADD_DEPENDENCIES(${TARGET} ${LIB})
        ENDIF()

        GET_FILENAME_COMPONENT(LIBNAME ${LIB_LOCATION} NAME_WE)

        IF (UNIX AND NOT APPLE)
            SET(LIB_UNAR_DIR ${UNAR_DIR}/${LIB})
            file(MAKE_DIRECTORY ${LIB_UNAR_DIR})
            ADD_CUSTOM_COMMAND(
                    COMMAND ${CMAKE_AR} x ${LIB_LOCATION}
                    COMMAND ${CMAKE_COMMAND} -E touch ${LIB_UNAR_DIR}/${LIBNAME}.txt
                    WORKING_DIRECTORY ${LIB_UNAR_DIR}
                    OUTPUT    ${LIB_UNAR_DIR}/${LIBNAME}.txt
                    DEPENDS ${LIB_LOCATION}
            )
            SET(UNAR_OBJS ${UNAR_OBJS};${LIB_UNAR_DIR}/*.o)
            ADD_CUSTOM_TARGET(unar_${LIBNAME}_${TARGET} DEPENDS ${LIB_UNAR_DIR}/${LIBNAME}.txt)
            ADD_DEPENDENCIES(unar_${LIBNAME}_${TARGET} ${LIB})
            ADD_DEPENDENCIES(${TARGET} unar_${LIBNAME}_${TARGET})
        ENDIF()
    ENDFOREACH()

    IF(MSVC)
        # To merge libs, just pass them to lib.exe command line.
        SET(LINKER_EXTRA_FLAGS "")
        FOREACH(LIB ${STATIC_LIBS})
            SET(LINKER_EXTRA_FLAGS "${LINKER_EXTRA_FLAGS} ${LIB}")
        ENDFOREACH()
        SET_TARGET_PROPERTIES(${TARGET} PROPERTIES STATIC_LIBRARY_FLAGS "${LINKER_EXTRA_FLAGS}")
        message("FLAGS= ${LINKER_EXTRA_FLAGS}")
    ELSE()
        GET_TARGET_PROPERTY(TARGET_LOCATION ${TARGET} LOCATION)    
        IF(APPLE)
            # Use OSX's libtool to merge archives (it handles universal binaries properly)
            ADD_CUSTOM_COMMAND(TARGET ${TARGET} POST_BUILD
                COMMAND rm ${TARGET_LOCATION}
                COMMAND /usr/bin/libtool -static -o ${TARGET_LOCATION}    ${STATIC_LIBS}
            )    
        ELSE()
            ADD_CUSTOM_COMMAND(TARGET ${TARGET} POST_BUILD
                COMMAND rm ${TARGET_LOCATION}
                COMMAND ${CMAKE_AR} r ${TARGET_LOCATION} ${UNAR_OBJS}
                COMMAND ${CMAKE_RANLIB} ${TARGET_LOCATION}
            )
        ENDIF()
    ENDIF()
ENDMACRO()

# cmake only knows how to build dynamic frameworks,
# so hack around it by making a temp dynamic framework, and copying the static file into it
macro(make_static_framework targetname name lib header version package modulemap_template)
    # setup the modulemap
    set(MODULE_NAME ${name})
    set(modulemap_path ${CMAKE_CURRENT_BINARY_DIR}/module.modulemap)
    configure_file(${modulemap_template} ${modulemap_path})
    set_property(SOURCE "${modulemap_path}" PROPERTY MACOSX_PACKAGE_LOCATION "Modules")

    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/dummy.c "#include <stdio.h>\n")

    # make a dummy dynamic framework
    set(shared_framework_target ${targetname}_shared_framework)
    add_library(${shared_framework_target} SHARED ${CMAKE_CURRENT_BINARY_DIR}/dummy.c ${modulemap_path} ${header})
    set_target_properties(${shared_framework_target} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY tmp
        OUTPUT_NAME ${name}
        FRAMEWORK 1
        MACOSX_FRAMEWORK_BUNDLE_VERSION ${version}
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${version}
        MACOSX_FRAMEWORK_IDENTIFIER ${package}
    )

    if (CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
        set(output_framework ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY})
    else()
        set(output_framework ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    set(output_framework ${output_framework}/${name}.framework)
    set(${targetname}_framework_path ${output_framework})

    # make the static framework
    set(static_framework_name ${name}.framework)
    add_custom_command(
        DEPENDS $<TARGET_FILE_DIR:${shared_framework_target}> ${lib} ${header}    
        OUTPUT ${output_framework}/Versions/Current/${name}
        COMMAND rm -rf ${output_framework}
        COMMAND cp -af $<TARGET_FILE_DIR:${shared_framework_target}>/../.. ${output_framework}
        COMMAND ${CMAKE_COMMAND} -E create_symlink Versions/Current/Modules ${output_framework}/Modules
        COMMAND ${CMAKE_COMMAND} -E copy ${lib} ${output_framework}/Versions/Current/${name}
        )
    add_custom_target(${targetname}_framework ALL DEPENDS ${shared_framework_target} ${output_framework}/Versions/Current/${name})
endmacro()

# python (particularly whl files) needs a very strict version scheme
macro(get_python_compatible_version version varname)
    string(REPLACE "-" ";" version_parts ${version})
    message("version parts ${version_parts}")
    foreach (version_part ${version_parts})
        if (version_part MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
            set(${varname} ${version_part})
        endif()
    endforeach()
endmacro()

# unknown filename renaming
set(FILE_RENAME_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/rename.cmake)
file(WRITE  ${FILE_RENAME_SCRIPT} "file(GLOB frompath \${PATTERN}) \n")
file(APPEND ${FILE_RENAME_SCRIPT} "get_filename_component(fromfile \${frompath} NAME) \n")
file(APPEND ${FILE_RENAME_SCRIPT} "get_filename_component(todir    \${TO}       DIRECTORY) \n")
file(APPEND ${FILE_RENAME_SCRIPT} "file(COPY \${frompath} DESTINATION \${todir}) \n")
file(APPEND ${FILE_RENAME_SCRIPT} "file(RENAME \${todir}/\${fromfile} \${TO}) \n")

