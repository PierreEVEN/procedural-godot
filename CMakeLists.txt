# I'm new to goddot, this CMakeLists is based on https://github.com/vorlac/godot-roguelite

cmake_minimum_required(VERSION 3.20)

project(procedural_godot)

SET(CMAKE_CXX_STANDARD 23)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_CXX_EXTENSIONS ON)
SET(CMAKE_COLOR_DIAGNOSTICS ON)

OPTION(PLATFORM "Build platform" OFF)

SET(GODOT_PROJECT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/game/")
SET(BINARY_DIRECTORY "${GODOT_PROJECT_DIRECTORY}/bin")
file(TO_CMAKE_PATH "$ENV{GODOT_SOURCES}" GODOT_SOURCE_PATH)
file(TO_CMAKE_PATH "$ENV{GODOT_CPP_SOURCES}" GODOT_CPP_SOURCE_PATH)

# define output paths for gdextension shared lib and debug symbols
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")
SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")
SET(CMAKE_PDB_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")
SET(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")

# postfix debug binaries with "d"
set(CMAKE_DEBUG_POSTFIX "d")

# Build and include godot engine and godot_cpp
include("engine.cmake")

# =======================================================================
# GDExtension dynamic library setup/configuration
# =======================================================================

file(GLOB_RECURSE project_sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]" "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]pp")

# add the gdextension dynamic library
add_library(procedural_godot SHARED ${project_sources})

# used below to conditionally set certain compile options depending on the toolset used.
# taken from godot-cpp's cmakelists.txt for consistency (along with some of the compiler 
# options defined in target_compile_options() below).
set(compiler_is_clang "$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>>")
set(compiler_is_gnu "$<CXX_COMPILER_ID:GNU>")
set(compiler_is_msvc "$<CXX_COMPILER_ID:MSVC>")

# import the same compiler warning settings that the bindings library uses
include("${GODOT_CPP_SOURCE_PATH}/cmake/GodotCompilerWarnings.cmake")

# set compiler options for the gdextension library based on the compiler being used
target_compile_options(procedural_godot PUBLIC
	/EHsc
	/utf-8
	/Zc:preprocessor
	$<$<CONFIG:Debug>:
		/MDd
	>
	$<$<CONFIG:Release>:
		/MD
		/O2
	>
)

target_include_directories(procedural_godot PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Include godot-cpp
include(FetchContent)
FetchContent_Declare(godot_cpp SOURCE_DIR ${GODOT_CPP_SOURCE_PATH})
FetchContent_MakeAvailable(godot_cpp)

target_link_libraries(procedural_godot PUBLIC godot::cpp)