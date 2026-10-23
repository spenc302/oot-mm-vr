include(FetchContent)

set(BUILD_FORCE_GENERATION OFF CACHE BOOL "" FORCE)
set(BUILD_LOADER ON CACHE BOOL "" FORCE)
set(BUILD_API_LAYERS OFF CACHE BOOL "" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(BUILD_CONFORMANCE_TESTS OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    mmvr_openxr_sdk
    GIT_REPOSITORY https://github.com/KhronosGroup/OpenXR-SDK-Source.git
    GIT_TAG release-1.1.65
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(mmvr_openxr_sdk)

if(TARGET openxr_loader AND NOT TARGET OpenXR::openxr_loader)
    add_library(OpenXR::openxr_loader ALIAS openxr_loader)
endif()

if(NOT TARGET OpenXR::headers OR NOT TARGET OpenXR::openxr_loader)
    message(FATAL_ERROR "The Android OpenXR SDK did not provide headers and an OpenXR loader target.")
endif()

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(INSTALL_DOCS OFF CACHE BOOL "" FORCE)
set(INSTALL_PKG_CONFIG_MODULE OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    mmvr_ogg
    GIT_REPOSITORY https://github.com/xiph/ogg.git
    GIT_TAG v1.3.5
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(mmvr_ogg)
if(NOT TARGET Ogg::ogg)
    add_library(Ogg::ogg ALIAS ogg)
endif()
set(OGG_INCLUDE_DIR "${mmvr_ogg_SOURCE_DIR}/include")
set(OGG_LIBRARY ogg)

FetchContent_Declare(
    mmvr_vorbis
    GIT_REPOSITORY https://github.com/xiph/vorbis.git
    GIT_TAG v1.3.7
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(mmvr_vorbis)
add_library(Vorbis::vorbis ALIAS vorbis)
add_library(Vorbis::vorbisenc ALIAS vorbisenc)
add_library(Vorbis::vorbisfile ALIAS vorbisfile)

set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_TESTING OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
    mmvr_opus
    GIT_REPOSITORY https://github.com/xiph/opus.git
    GIT_TAG v1.5.2
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(mmvr_opus)

FetchContent_Declare(
    mmvr_opusfile
    GIT_REPOSITORY https://github.com/xiph/opusfile.git
    GIT_TAG v0.12
    GIT_SHALLOW TRUE
)
FetchContent_GetProperties(mmvr_opusfile)
if(NOT mmvr_opusfile_POPULATED)
    FetchContent_Populate(mmvr_opusfile)
endif()
add_library(mmvr_opusfile STATIC
    "${mmvr_opusfile_SOURCE_DIR}/src/info.c"
    "${mmvr_opusfile_SOURCE_DIR}/src/internal.c"
    "${mmvr_opusfile_SOURCE_DIR}/src/opusfile.c"
    "${mmvr_opusfile_SOURCE_DIR}/src/stream.c"
)
add_library(OpusFile::Opusfile ALIAS mmvr_opusfile)
target_include_directories(mmvr_opusfile
    PUBLIC "${mmvr_opusfile_SOURCE_DIR}/include"
    PRIVATE "${mmvr_opusfile_SOURCE_DIR}/src"
)
target_link_libraries(mmvr_opusfile PUBLIC Ogg::ogg Opus::opus)

set(SDL2NET_INSTALL OFF CACHE BOOL "" FORCE)
set(SDL2NET_SAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
    mmvr_sdl2_net
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_net.git
    GIT_TAG release-2.2.0
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(mmvr_sdl2_net)
if(NOT TARGET SDL2_net::SDL2_net)
    add_library(SDL2_net::SDL2_net ALIAS SDL2_net)
endif()
set(mmvr_sdl2_net_include_dir "${CMAKE_CURRENT_BINARY_DIR}/mmvr-sdl2-net-include")
file(MAKE_DIRECTORY "${mmvr_sdl2_net_include_dir}/SDL2")
configure_file(
    "${mmvr_sdl2_net_SOURCE_DIR}/SDL_net.h"
    "${mmvr_sdl2_net_include_dir}/SDL2/SDL_net.h"
    COPYONLY
)
target_include_directories(SDL2_net PUBLIC "${mmvr_sdl2_net_include_dir}")
