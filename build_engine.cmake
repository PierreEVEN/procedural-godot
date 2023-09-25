include(FetchContent)

set(FETCHCONTENT_UPDATES_DISCONNECTED ON)

# =======================================================================
# Ensure requirement are met
# =======================================================================
find_program(SCONS_PROGRAM scons)
if(NOT SCONS_PROGRAM)
    message(FATAL_ERROR "Cannot build Godot engine without SCons")
endif()
message(STATUS "SCons: ${SCONS_PROGRAM}")

# =======================================================================
# Get engine sources
# =======================================================================

SET(GODOT_SOURCE_PATH GODOT_SOURCES)
if(NOT EXISTS "${GODOT_SOURCE_PATH}")
	# Godot sources path wasn't specified in options
	FILE(TO_CMAKE_PATH "$ENV{GODOT_SOURCES}" GODOT_SOURCE_PATH)
	
	if(NOT EXISTS "${GODOT_SOURCE_PATH}") # Godot sources path wasn't specified in environment variables
		if (NOT ${ENGINE_VERSION})
			set(ENGINE_VERSION "4.1")
		endif()
		message(STATUS "Fetching godot sources from git : https://github.com/godotengine/godot.git -b ${ENGINE_VERSION}")
		FetchContent_Declare(
			godot 
			GIT_REPOSITORY	https://github.com/godotengine/godot.git
			GIT_TAG 		${ENGINE_VERSION}
		)
		FetchContent_MakeAvailable(godot)
		SET(GODOT_SOURCE_PATH ${godot_SOURCE_DIR})
		if (NOT EXISTS "${GODOT_SOURCE_PATH}")
			message(FATAL_ERROR "Failed to fetch godot from git : '${GODOT_SOURCE_PATH}'")
		endif()
	endif()
endif()

# Ensure path is valid
if (NOT EXISTS "${GODOT_SOURCE_PATH}")
	message(FATAL_ERROR "Provided godot sources path is not valid : '${GODOT_SOURCE_PATH}'")
endif()

set(GODOT_EXECUTABLE "${GODOT_SOURCE_PATH}/bin/godot.windows.editor.dev.double.x86_64${CMAKE_EXECUTABLE_SUFFIX}")

# =======================================================================
# Get godot-cpp sources
# =======================================================================

FILE(TO_CMAKE_PATH "$ENV{GODOT_CPP_SOURCES}" GODOT_CPP_SOURCE_PATH)
if (${DOUBLE_PRECISION})
	SET(FLOAT_PRECISION double)
endif()


SET(GODOT_CPP_SOURCE_PATH GODOT_CPP_SOURCES)
if(NOT EXISTS "${GODOT_CPP_SOURCE_PATH}")
	# Godot-cpp sources path wasn't specified in options
	FILE(TO_CMAKE_PATH "$ENV{GODOT_CPP_SOURCES}" GODOT_CPP_SOURCE_PATH)
	
	if(NOT EXISTS "${GODOT_CPP_SOURCE_PATH}") # Godot-cpp sources path wasn't specified in environment variables
		if (NOT ${ENGINE_VERSION})
			set(ENGINE_VERSION "4.1")
		endif()
		message(STATUS "Fetching godot-cpp sources from git : https://github.com/godotengine/godot-cpp -b ${ENGINE_VERSION}")
		FetchContent_Declare(
			godot_cpp
			GIT_REPOSITORY	https://github.com/godotengine/godot-cpp
			GIT_TAG 		${ENGINE_VERSION}
		)
		FetchContent_MakeAvailable(godot_cpp)

		SET(GODOT_CPP_SOURCE_PATH ${godot_cpp_SOURCE_DIR})
		if (NOT EXISTS "${GODOT_CPP_SOURCE_PATH}")
			message(FATAL_ERROR "Failed to fetch godot-cpp from git : '${GODOT_CPP_SOURCE_PATH}'")
		endif()
	else()
		FetchContent_Declare(godot_cpp SOURCE_DIR https://github.com/godotengine/godot-cpp)
		FetchContent_MakeAvailable(godot_cpp)
		if (NOT EXISTS "${GODOT_CPP_SOURCE_PATH}")
			message(FATAL_ERROR "Failed to fetch godot-cpp from env variable : '${GODOT_CPP_SOURCE_PATH}'")
		endif()
	endif()
else()
	FetchContent_Declare(godot_cpp SOURCE_DIR https://github.com/godotengine/godot-cpp)
	FetchContent_MakeAvailable(godot_cpp)
	if (NOT EXISTS "${GODOT_CPP_SOURCE_PATH}")
		message(FATAL_ERROR "Failed to fetch godot-cpp from option property : '${GODOT_CPP_SOURCE_PATH}'")
	endif()
endif()

# Ensure path is valid
if (NOT EXISTS "${GODOT_CPP_SOURCE_PATH}")
	message(FATAL_ERROR "Provided godot-cpp sources path is not valid : '${GODOT_CPP_SOURCE_PATH}'")
endif()

# @TODO : fix this source group
file(GLOB_RECURSE godot_cpp_sources CONFIGURE_DEPENDS "${GODOT_CPP_SOURCE_PATH}/*.[hc]" "${GODOT_CPP_SOURCE_PATH}/*.[hc]pp")
source_group(TREE ${GODOT_CPP_SOURCE_PATH} PREFIX src FILES ${godot_cpp_sources})

message(STATUS "Godot-cpp sources : ${GODOT_CPP_SOURCE_PATH}")
	
# =======================================================================
# Build engine from sources
# =======================================================================
if(NOT EXISTS "${GODOT_EXECUTABLE}")

	set(ENGINE_BUILD_OPTIONS platform=windows arch=x64 target=editor use_static_cpp=yes dev_build=yes debug_symbols=yes optimize=none use_lto=no bits=64 vsproj=yes)
	if (${DOUBLE_PRECISION})
		set(ENGINE_BUILD_OPTIONS ${ENGINE_BUILD_OPTIONS} precision=double)
	endif()
	
	
	message("Failed to find godot executable. Building godot from sources : ${GODOT_SOURCE_PATH}/scons ${ENGINE_BUILD_OPTIONS}")
	
	# Clean previously generated objects
	execute_process(
		COMMAND scons ${ENGINE_BUILD_OPTIONS} --clean
		WORKING_DIRECTORY "${GODOT_SOURCE_PATH}"
		COMMAND_ERROR_IS_FATAL ANY
	)
	
	# Build the engine
	execute_process(
		COMMAND scons ${ENGINE_BUILD_OPTIONS}
		WORKING_DIRECTORY "${GODOT_SOURCE_PATH}"
		COMMAND_ERROR_IS_FATAL ANY
	)
	
	if(NOT EXISTS "${GODOT_EXECUTABLE}")
        message(FATAL_ERROR "Couldn't find godot debug executable after scons build : ${GODOT_EXECUTABLE}")
    endif()
else()
	message(STATUS "Engine executable : ${GODOT_EXECUTABLE}")
endif()

# =======================================================================
# Add fake godot exe for IDEs
# =======================================================================
# file(GLOB_RECURSE godot_engine_sources CONFIGURE_DEPENDS "${GODOT_SOURCE_PATH}/*.[hc]" "${GODOT_SOURCE_PATH}/*.[hc]pp")
# add_executable(godot_engine EXCLUDE_FROM_ALL ${godot_engine_sources})
# source_group(TREE ${GODOT_SOURCE_PATH} PREFIX src FILES ${godot_engine_sources})
# target_include_directories(godot_engine PUBLIC
#     "${GODOT_SOURCE_PATH}"
#     "${GODOT_SOURCE_PATH}/platform/windows"
#     "${GODOT_SOURCE_PATH}/modules/gdnative/include"
#     "${GODOT_SOURCE_PATH}/thirdparty/zlib"
#     "${GODOT_SOURCE_PATH}/thirdparty/vulkan/include"
#     SYSTEM "${GODOT_SOURCE_PATH}/thirdparty/zstd"
#     SYSTEM "${GODOT_SOURCE_PATH}/thirdparty/mbedtls/include"
# )
# target_compile_definitions(godot_engine PUBLIC
#     $<$<CONFIG:Debug>:
#         DEBUG_ENABLED
#         DEBUG_METHODS_ENABLED
#         DEV_ENABLED
#     >
#     NOMINMAX
#     TOOLS_ENABLED
#     NO_EDITOR_SPLASH
#     WINDOWS_ENABLED
#     WASAPI_ENABLED
#     WINMIDI_ENABLED
#     TYPED_METHOD_BIND
#     VULKAN_ENABLED
#     GLES3_ENABLED
#     MINIZIP_ENABLED
#     BROTLI_ENABLED
#     ZSTD_STATIC_LINKING_ONLY
#     USE_VOLK
#     VK_USE_PLATFORM_WIN32_KHR
#     GLAD_ENABLED
#     GLES_OVER_GL
# )
