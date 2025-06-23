# ----------------------------------------------------------------------------
# 1. PID Source Files
# ----------------------------------------------------------------------------
set(LIBMEMALLOC_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/libmemalloc.c"
)

set(GC_SOURCE
    "${CMAKE_CURRENT_SOURCE_DIR}/gc.c"
)

# ----------------------------------------------------------------------------
# 2. Object Libraries for Position-Independent Code
# ----------------------------------------------------------------------------
# main allocator objects
add_library(libmemalloc_obj OBJECT
    ${LIBMEMALLOC_SOURCES}
)
target_include_directories(libmemalloc_obj PRIVATE
    "${CMAKE_SOURCE_DIR}/inc"
)

# GC module compiled with debug-friendly flags
add_library(gc_obj OBJECT
    ${GC_SOURCE}
)
target_include_directories(gc_obj PRIVATE
    "${CMAKE_SOURCE_DIR}/inc"
)
# compile GC with no optimizations / frame pointers retained
target_compile_options(gc_obj PRIVATE
    -O0
    -g3
    -fno-omit-frame-pointer
    -fno-optimize-sibling-calls
)

# ensure PIC for both
set_target_properties(libmemalloc_obj PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OBJECT_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)
set_target_properties(gc_obj PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OBJECT_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

# ----------------------------------------------------------------------------
# 3. Static Library Target
# ----------------------------------------------------------------------------
add_library(libmemalloc_static STATIC
    $<TARGET_OBJECTS:libmemalloc_obj>
    $<TARGET_OBJECTS:gc_obj>
)
set_target_properties(libmemalloc_static PROPERTIES
    OUTPUT_NAME libmemalloc
    ARCHIVE_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

# ----------------------------------------------------------------------------
# 4. Shared Library Target
# ----------------------------------------------------------------------------
add_library(libmemalloc_shared SHARED
    $<TARGET_OBJECTS:libmemalloc_obj>
    $<TARGET_OBJECTS:gc_obj>
)
set_target_properties(libmemalloc_shared PROPERTIES
    OUTPUT_NAME libmemalloc
    LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

# ----------------------------------------------------------------------------
# 5. Install Targets and Headers
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
