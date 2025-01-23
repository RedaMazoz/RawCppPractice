include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(RawCppPractice_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(RawCppPractice_setup_options)
  option(RawCppPractice_ENABLE_HARDENING "Enable hardening" ON)
  option(RawCppPractice_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    RawCppPractice_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    RawCppPractice_ENABLE_HARDENING
    OFF)

  RawCppPractice_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR RawCppPractice_PACKAGING_MAINTAINER_MODE)
    option(RawCppPractice_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(RawCppPractice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(RawCppPractice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(RawCppPractice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(RawCppPractice_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(RawCppPractice_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(RawCppPractice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(RawCppPractice_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(RawCppPractice_ENABLE_IPO "Enable IPO/LTO" ON)
    option(RawCppPractice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(RawCppPractice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(RawCppPractice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(RawCppPractice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(RawCppPractice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(RawCppPractice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(RawCppPractice_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(RawCppPractice_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(RawCppPractice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(RawCppPractice_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      RawCppPractice_ENABLE_IPO
      RawCppPractice_WARNINGS_AS_ERRORS
      RawCppPractice_ENABLE_USER_LINKER
      RawCppPractice_ENABLE_SANITIZER_ADDRESS
      RawCppPractice_ENABLE_SANITIZER_LEAK
      RawCppPractice_ENABLE_SANITIZER_UNDEFINED
      RawCppPractice_ENABLE_SANITIZER_THREAD
      RawCppPractice_ENABLE_SANITIZER_MEMORY
      RawCppPractice_ENABLE_UNITY_BUILD
      RawCppPractice_ENABLE_CLANG_TIDY
      RawCppPractice_ENABLE_CPPCHECK
      RawCppPractice_ENABLE_COVERAGE
      RawCppPractice_ENABLE_PCH
      RawCppPractice_ENABLE_CACHE)
  endif()

  RawCppPractice_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (RawCppPractice_ENABLE_SANITIZER_ADDRESS OR RawCppPractice_ENABLE_SANITIZER_THREAD OR RawCppPractice_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(RawCppPractice_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(RawCppPractice_global_options)
  if(RawCppPractice_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    RawCppPractice_enable_ipo()
  endif()

  RawCppPractice_supports_sanitizers()

  if(RawCppPractice_ENABLE_HARDENING AND RawCppPractice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR RawCppPractice_ENABLE_SANITIZER_UNDEFINED
       OR RawCppPractice_ENABLE_SANITIZER_ADDRESS
       OR RawCppPractice_ENABLE_SANITIZER_THREAD
       OR RawCppPractice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${RawCppPractice_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${RawCppPractice_ENABLE_SANITIZER_UNDEFINED}")
    RawCppPractice_enable_hardening(RawCppPractice_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(RawCppPractice_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(RawCppPractice_warnings INTERFACE)
  add_library(RawCppPractice_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  RawCppPractice_set_project_warnings(
    RawCppPractice_warnings
    ${RawCppPractice_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(RawCppPractice_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    RawCppPractice_configure_linker(RawCppPractice_options)
  endif()

  include(cmake/Sanitizers.cmake)
  RawCppPractice_enable_sanitizers(
    RawCppPractice_options
    ${RawCppPractice_ENABLE_SANITIZER_ADDRESS}
    ${RawCppPractice_ENABLE_SANITIZER_LEAK}
    ${RawCppPractice_ENABLE_SANITIZER_UNDEFINED}
    ${RawCppPractice_ENABLE_SANITIZER_THREAD}
    ${RawCppPractice_ENABLE_SANITIZER_MEMORY})

  set_target_properties(RawCppPractice_options PROPERTIES UNITY_BUILD ${RawCppPractice_ENABLE_UNITY_BUILD})

  if(RawCppPractice_ENABLE_PCH)
    target_precompile_headers(
      RawCppPractice_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(RawCppPractice_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    RawCppPractice_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(RawCppPractice_ENABLE_CLANG_TIDY)
    RawCppPractice_enable_clang_tidy(RawCppPractice_options ${RawCppPractice_WARNINGS_AS_ERRORS})
  endif()

  if(RawCppPractice_ENABLE_CPPCHECK)
    RawCppPractice_enable_cppcheck(${RawCppPractice_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(RawCppPractice_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    RawCppPractice_enable_coverage(RawCppPractice_options)
  endif()

  if(RawCppPractice_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(RawCppPractice_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(RawCppPractice_ENABLE_HARDENING AND NOT RawCppPractice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR RawCppPractice_ENABLE_SANITIZER_UNDEFINED
       OR RawCppPractice_ENABLE_SANITIZER_ADDRESS
       OR RawCppPractice_ENABLE_SANITIZER_THREAD
       OR RawCppPractice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    RawCppPractice_enable_hardening(RawCppPractice_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
