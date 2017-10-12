cmake_minimum_required(VERSION 3.6)

include(cmake/platforms.cmake)
include(cmake/helper.cmake)

setup_toolchain()
setup_platforms()

project(hola)
add_executable(hola src/hola.cpp)
install(TARGETS hola DESTINATION bin)
