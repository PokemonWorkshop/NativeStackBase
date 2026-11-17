include(DeclareNativeDependency)

if(ANDROID)
  message(FATAL_ERROR "TODO")
elseif(WIN32)
  # Use provided MSYS2 package
  declare_default_native_dependency(freetype MODE sysroot)
elseif(LINUX)
  # Build from source in-tree
  declare_default_native_dependency(
    freetype
    MODE source_url
    SOURCE_URL
      https://download.savannah.gnu.org/releases/freetype/freetype-2.14.3.tar.xz
    SOURCE_HASH
      "SHA256=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f"
    OPTIONS FT_DISABLE_HARFBUZZ=ON FT_DISABLE_PNG=ON FT_DISABLE_BROTLI=ON
            FT_DISABLE_BZIP2=ON
  )
elseif(SWITCH)
  # Use portlib
  declare_default_native_dependency(freetype MODE sysroot)
elseif(APPLE)
  message(FATAL_ERROR "TODO")
endif()

# Define alias for Freetype::Freetype because in-tree build is nasty
# and does not define the Freetype::Freetype target itself
#
# Defined here and not in the branch to cover override calls as well
if(NOT TARGET Freetype::Freetype)
  add_library(Freetype::Freetype ALIAS freetype-interface)
endif()
