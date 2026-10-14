# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/install.cmake
# Purpose:
#   Install the library, public interface and relocatable package metadata.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

install(
  TARGETS memalloc
  EXPORT libmemallocTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES core/mock.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libmemalloc)
install(FILES LICENSE DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/libmemalloc)
install(
  EXPORT libmemallocTargets
  NAMESPACE LMA::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/libmemalloc)

configure_package_config_file(
  packaging/cmake/libmemallocConfig.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/libmemallocConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/libmemalloc)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/libmemallocConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY ExactVersion)
# pkg-config files may live in lib, lib64 or a multiarch library directory.
file(RELATIVE_PATH LMA_PC_PREFIX_RELATIVE "${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig"
     "${CMAKE_INSTALL_PREFIX}")
foreach(directory IN ITEMS LIBDIR INCLUDEDIR)
  if(IS_ABSOLUTE "${CMAKE_INSTALL_${directory}}")
    set(LMA_PC_${directory} "${CMAKE_INSTALL_${directory}}")
  else()
    set(LMA_PC_${directory} "\${prefix}/${CMAKE_INSTALL_${directory}}")
  endif()
endforeach()
set(LMA_PC_CFLAGS "")
if(BUILD_SHARED_LIBS)
  set(LMA_PC_CFLAGS " -DLMA_SHARED_LIBRARY")
endif()
configure_file(packaging/pkgconfig/libmemalloc.pc.in libmemalloc.pc @ONLY)
configure_file(packaging/cmake/fixture-version.txt.in fixture-version.txt @ONLY)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libmemallocConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/libmemallocConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/libmemalloc)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libmemalloc.pc
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/fixture-version.txt
        DESTINATION ${CMAKE_INSTALL_DATADIR}/libmemalloc)

# EOF

