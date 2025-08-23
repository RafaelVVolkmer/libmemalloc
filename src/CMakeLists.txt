# ----------------------------------------------------------------------------
# 1. PID Source Files
# ----------------------------------------------------------------------------
set(LIBMEMALLOC_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/libmemalloc.c"
)

find_package(Threads REQUIRED)

# ----------------------------------------------------------------------------
# 2. Object Libraries for Position-Independent Code
# ----------------------------------------------------------------------------
add_library(libmemalloc_obj OBJECT
    ${LIBMEMALLOC_SOURCES}
)

target_include_directories(libmemalloc_obj PRIVATE
    "${CMAKE_SOURCE_DIR}/inc"
)

set_target_properties(libmemalloc_obj PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OBJECT_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

# ----------------------------------------------------------------------------
# 3. If it is debug, enable logs
# ----------------------------------------------------------------------------
target_compile_definitions(libmemalloc_obj
    PRIVATE
      $<$<CONFIG:Debug>:LOG_LEVEL=LOG_LEVEL_DEBUG>
)

# ----------------------------------------------------------------------------
# 4. Static Library Target
# ----------------------------------------------------------------------------
add_library(libmemalloc_static STATIC
    $<TARGET_OBJECTS:libmemalloc_obj>
)

set_target_properties(libmemalloc_static PROPERTIES
    OUTPUT_NAME memalloc
    ARCHIVE_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

target_link_libraries(libmemalloc_static
    PUBLIC Threads::Threads
)

# ----------------------------------------------------------------------------
# 5. Shared Library Target
# ----------------------------------------------------------------------------
add_library(libmemalloc_shared SHARED
    $<TARGET_OBJECTS:libmemalloc_obj>
)

set_target_properties(libmemalloc_shared PROPERTIES
    OUTPUT_NAME memalloc
    LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

target_link_libraries(libmemalloc_shared
    PUBLIC Threads::Threads
)

target_compile_options(libmemalloc_shared PRIVATE -fPIC)

# ----------------------------------------------------------------------------
# 6. Install Targets and Headers
# ----------------------------------------------------------------------------
install(TARGETS libmemalloc_static libmemalloc_shared
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY "${CMAKE_SOURCE_DIR}/inc/"
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

