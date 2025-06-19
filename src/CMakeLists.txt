# ----------------------------------------------------------------------------
# 1. PID Source Files
# ----------------------------------------------------------------------------
set(LIBMEMALLOC_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/libmemalloc.c"
)

# ----------------------------------------------------------------------------
# 2. Object Library for Position-Independent Code
# ----------------------------------------------------------------------------
add_library(libmemalloc_obj OBJECT
    ${LIBMEMALLOC_SOURCES}
)

target_include_directories(libmemalloc_obj PRIVATE
    "${CMAKE_SOURCE_DIR}/inc"
)

# ----------------------------------------------------------------------------
# 3. Static Library Target
# ----------------------------------------------------------------------------
add_library(libmemalloc_static STATIC
    $<TARGET_OBJECTS:libmemalloc_obj>
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
)

set_target_properties(libmemalloc_shared PROPERTIES
    OUTPUT_NAME libmemalloc
    LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

set_target_properties(libmemalloc_obj PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    OBJECT_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}"
)

# ----------------------------------------------------------------------------
# 5. Custom Command to Copy Object File
# ----------------------------------------------------------------------------
# 6. Install Targets and Headers
install(TARGETS libmemalloc_static libmemalloc_shared
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
install(DIRECTORY "${CMAKE_SOURCE_DIR}/inc/"
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

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