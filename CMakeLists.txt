cmake_minimum_required(VERSION 3.20)

SET(PROJECT_NAME procedural_godot)

# =======================================================================
# CMake Setup
# =======================================================================

project(${PROJECT_NAME})

SET(CMAKE_CXX_STANDARD 23)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_CXX_EXTENSIONS ON)
SET(CMAKE_COLOR_DIAGNOSTICS ON)

if(MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP /EHsc")
endif()

OPTION(PLATFORM "Build platform" OFF)
OPTION(ENGINE_VERSION "Engine version" OFF)
OPTION(GODOT_SOURCES "Godot engine source path" OFF)
OPTION(GODOT_CPP_SOURCES "Godot-cpp source path" OFF)
OPTION(DOUBLE_PRECISION "Enabled double precision floating point" ON)

# The directory containing the .godot file
SET(GODOT_PROJECT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/game/")
# Where compiled binaries are stored
SET(BINARY_DIRECTORY "${GODOT_PROJECT_DIRECTORY}/bin/extensions")

# postfix debug binaries with "d"
set(CMAKE_DEBUG_POSTFIX "d")

# Build and include godot engine and godot_cpp
include("build_engine.cmake")

# =======================================================================
# GDExtension dynamic library setup/configuration
# =======================================================================

file(GLOB_RECURSE project_sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]" "${CMAKE_CURRENT_SOURCE_DIR}/src/*.[hc]pp")

# add the gdextension dynamic library
add_library(${PROJECT_NAME} SHARED ${project_sources})
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/src PREFIX src FILES ${project_sources})
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")

# =======================================================================
# Link Godot-cpp
# =======================================================================

# Import warnings
set(compiler_is_clang "$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>>")
set(compiler_is_gnu "$<CXX_COMPILER_ID:GNU>")
set(compiler_is_msvc "$<CXX_COMPILER_ID:MSVC>")
include("${GODOT_CPP_SOURCE_PATH}/cmake/GodotCompilerWarnings.cmake")
target_link_libraries(${PROJECT_NAME} PUBLIC godot::cpp)

# define output paths for gdextension shared lib and debug symbols
set_target_properties(${PROJECT_NAME} PROPERTIES
	ARCHIVE_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}"
	LIBRARY_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}"
	RUNTIME_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}"
	PDB_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}"
	COMPILE_PDB_OUTPUT_DIRECTORY "${BINARY_DIRECTORY}")

add_custom_target(
	LAUNCH
	DEPENDS ${PROJECT_NAME} godot_exe
	WORKING_DIRECTORY 
		${GODOT_PROJECT_DIRECTORY}
	COMMAND 
		${GODOT_EXECUTABLE} project.godot
	COMMENT
		"Start editor"
)
#add_dependencies(LAUNCH ${PROJECT_NAME})
