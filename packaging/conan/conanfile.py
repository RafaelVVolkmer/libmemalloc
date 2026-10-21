# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

"""Native Conan recipe for verified prebuilt release fixtures."""

import os
from typing import Any, ClassVar, cast

from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.files import copy


class LibmemallocMockConan(ConanFile):
    """Package bytes supplied by the Lua release verifier without rebuilding."""

    name = "libmemalloc-mock"
    package_type = "library"
    license = "GPL-3.0-only"
    description = "Release pipeline fixture; not an allocator implementation"
    # Conan replaces these class declarations with runtime model objects.
    settings: Any = "os", "arch", "compiler", "build_type"
    options: ClassVar[Any] = {"shared": [True, False]}
    default_options: ClassVar[dict[str, bool]] = {"shared": False}

    def validate(self) -> None:
        if str(self.settings.os) != "Linux":
            raise ConanInvalidConfiguration("Only the native Linux mock is qualified")
        if str(self.settings.build_type) not in ("Release", "Debug"):
            raise ConanInvalidConfiguration("Unsupported release variant")

    def package(self) -> None:
        root = cast(Any, self.conf).get("user.libmemalloc:release_root", check_type=str)
        if not isinstance(root, str) or not root:
            raise ConanInvalidConfiguration("A Lua-verified release root is required")
        package_folder = self.package_folder
        if not isinstance(package_folder, str):
            raise ConanInvalidConfiguration(
                "Conan did not initialize the package folder"
            )
        variant = str(self.settings.build_type).lower()
        suffix = "*.so" if self.options.shared else "*.a"
        count = copy(
            self,
            suffix,
            src=os.path.join(root, "bins", variant),
            dst=os.path.join(package_folder, "lib"),
            keep_path=False,
        )
        if len(count) != 1:
            raise ConanInvalidConfiguration("Expected exactly one selected library")
        # Stable loader identity; the Lua verifier checks the transport name.
        destination = "libmemalloc.so" if self.options.shared else "libmemalloc.a"
        os.rename(count[0], os.path.join(package_folder, "lib", destination))
        if self.options.shared:
            os.symlink(
                "libmemalloc.so",
                os.path.join(package_folder, "lib", "libmemalloc.so.0"),
            )
        copy(
            self,
            "*.h",
            src=os.path.join(root, "include"),
            dst=os.path.join(package_folder, "include"),
        )
        copy(
            self,
            "LICENSE",
            src=os.path.join(root, "licenses"),
            dst=os.path.join(package_folder, "licenses"),
        )
        copy(
            self,
            "*.json",
            src=os.path.join(root, "integrity"),
            dst=os.path.join(package_folder, "res", "integrity"),
        )

    def package_info(self) -> None:
        self.cpp_info.libs = ["memalloc"]
        self.cpp_info.set_property("cmake_file_name", "libmemalloc")
        self.cpp_info.set_property("cmake_target_name", "LMA::memalloc")
        self.cpp_info.set_property("pkg_config_name", "libmemalloc")

# EOF

