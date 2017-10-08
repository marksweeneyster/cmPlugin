cmake_minimum_required(VERSION 3.6)
project(hola)
add_executable(hola src/hola.cpp)
install(TARGETS hola DESTINATION bin)
