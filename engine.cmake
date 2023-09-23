set(GODOT_EXECUTABLE "${GODOT_SOURCE_PATH}/bin/godot.windows.editor.double.x86_64${CMAKE_EXECUTABLE_SUFFIX}")

if(NOT EXISTS "${GODOT_SOURCE_PATH}")
	message(FATAL_ERROR "Cannot find godot engine sources")
endif()

# Build the engine
if(NOT EXISTS "${GODOT_EXECUTABLE}")
	message("Failed to find godot executable. Building godot from sources")
	execute_process(
		COMMAND scons platform=windows arch=x64 target=editor use_static_cpp=yes dev_build=yes debug_symbols=yes optimize=none use_lto=no precision=double bits=64 vsproj=yes --clean
		WORKING_DIRECTORY "${GODOT_SOURCE_PATH}"
		COMMAND_ERROR_IS_FATAL ANY
	)

	# this build should only ever need to be run once (unless the enging debug binaries
	# are deleted or you want to change the build configuration/command invoked below).
	execute_process(
		COMMAND scons platform=windows arch=x64 target=editor use_static_cpp=yes dev_build=yes debug_symbols=yes optimize=none use_lto=no precision=double bits=64 vsproj=yes 
		WORKING_DIRECTORY "${GODOT_SOURCE_PATH}"
		COMMAND_ERROR_IS_FATAL ANY
	)
	
	if(NOT EXISTS "${GODOT_EXECUTABLE}")
        message(FATAL_ERROR "Couldn't find godot debug executable after scons build: ${GODOT_EXECUTABLE}")
    endif()
endif()

# populate source file list for the godot engine submodule
file(GLOB_RECURSE godot_engine_sources CONFIGURE_DEPENDS "${GODOT_SOURCE_PATH}/*.[hc]" "${GODOT_SOURCE_PATH}/*.[hc]pp")

# add the engine sources as a library so intellisense works in VS and VSCode 
# (and any other IDEs that support CMake in a way where the information from 
# the CMake build is fed into the IDE for additional context about the code 
# when browsing/debugging). even though the engine is being added as a library here, 
# the EXCLUDE_FROM_ALL option will prevent it from compiling. This is done 
# purely for IDE integration so it's able to properly navigate the engine
# source code using features like "go do definition", or typical tooltips.
add_library(godot_engine EXCLUDE_FROM_ALL ${godot_engine_sources})

# this is just a handful of additional include directories used by the engine.
# this isn't a complete list, I just add them as needed whenever I venture into 
# code where the IDE can't find certain header files during engine source browsing.
target_include_directories(godot_engine PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine"
    "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine/platform/windows"
    "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine/thirdparty/zlib"
    "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine/thirdparty/vulkan/include"
    SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine/thirdparty/zstd"
    SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/extern/godot-engine/thirdparty/mbedtls/include"
)

# define a bunch of the same symbol definitions
# used when by the scons engine build. These build 
# flags can differen based on the engine's build for 
# you system. Update as needed for your setup.
target_compile_definitions(godot_engine PUBLIC
    $<$<CONFIG:Debug>:
        DEBUG_ENABLED
        DEBUG_METHODS_ENABLED
        DEV_ENABLED
    >
    NOMINMAX
    TOOLS_ENABLED
    NO_EDITOR_SPLASH
    WINDOWS_ENABLED
    WASAPI_ENABLED
    WINMIDI_ENABLED
    TYPED_METHOD_BIND
    VULKAN_ENABLED
    GLES3_ENABLED
    MINIZIP_ENABLED
    BROTLI_ENABLED
    ZSTD_STATIC_LINKING_ONLY
    USE_VOLK
    VK_USE_PLATFORM_WIN32_KHR
    GLAD_ENABLED
    GLES_OVER_GL
)
