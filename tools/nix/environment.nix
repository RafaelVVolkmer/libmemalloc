# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# Compose host prerequisites from the tools catalog. Explicit synchronization
# installs the Python groups; entering a shell does not mutate Git or use pip.
{ pkgs }:
let
  inherit (pkgs) lib;
  catalog = (builtins.fromTOML (builtins.readFile ./packages.toml)).groups;
  reviewed = (builtins.fromTOML (builtins.readFile ../toolchain/lock.toml)).tools;
  python = builtins.fromTOML (builtins.readFile ../python/pyproject.toml);
  package = path: lib.getAttrFromPath (lib.splitString "." path) pkgs;
  select = groups: map package (lib.unique (lib.concatMap (name: catalog.${name}) groups));
  lua = pkgs.stdenv.mkDerivation {
    pname = "libmemalloc-lua";
    version = reviewed.lua.version;
    src = pkgs.fetchurl {
      url = "https://www.lua.org/ftp/lua-${reviewed.lua.version}.tar.gz";
      sha256 = reviewed.lua.sha256;
    };
    dontConfigure = true;
    buildPhase = "make -j$NIX_BUILD_CORES all";
    installPhase = ''
      mkdir -p "$out/bin" "$out/include"
      cp src/lua src/luac "$out/bin/"
      cp src/*.h "$out/include/"
    '';
  };
  luv = pkgs.stdenv.mkDerivation {
    pname = "libmemalloc-luv";
    version = reviewed.luv.version;
    src = pkgs.fetchurl {
      url = "https://github.com/luvit/luv/releases/download/${reviewed.luv.version}/"
        + "luv-${reviewed.luv.version}.tar.gz";
      sha256 = reviewed.luv.sha256;
    };
    nativeBuildInputs = [ pkgs.cmake ];
    cmakeFlags = [
      "-DWITH_LUA_ENGINE=Lua" "-DLUA_BUILD_TYPE=System"
      "-DLUA_INCDIR=${lua}/include" "-DLUA=${lua}/bin/lua"
      "-DBUILD_TESTING=OFF" "-DLUADIR=share/lua" "-DLIBDIR=lib"
    ];
    installPhase = ''
      mkdir -p "$out/lib"
      cp luv.so "$out/lib/"
    '';
  };

  # Use the same uv archive and identity as scripts/toolchain/python.lua.
  uv = pkgs.stdenvNoCC.mkDerivation {
    pname = "libmemalloc-uv";
    version = reviewed.uv.version;
    src = pkgs.fetchurl {
      url = "https://github.com/astral-sh/uv/releases/download/${reviewed.uv.version}/"
        + "uv-x86_64-unknown-linux-musl.tar.gz";
      sha256 = reviewed.uv.sha256;
    };
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      cp uv uvx "$out/bin/"
      runHook postInstall
    '';
  };

  # Report differences instead of claiming Nixpkgs matches every upstream pin.
  identities = lib.genAttrs (lib.unique (lib.concatLists (builtins.attrValues catalog)))
    (name: (package name).version or "unversioned");
  versions = pkgs.writeText "libmemalloc-tool-versions.json" (builtins.toJSON {
    nixpkgs = identities;
    repository = reviewed;
    pythonGroups = python.dependency-groups;
  });

  # Keep caches in the checkout, and prefer explicitly synchronized Python tools.
  shell = groups: pkgs.mkShell {
    packages = select groups ++ [ lua uv ];
    LIBMEMALLOC_UV = "${uv}/bin/uv";
    LIBMEMALLOC_NIX_TOOL_VERSIONS = versions;
    shellHook = ''
      workspace_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      export UV_CACHE_DIR="$workspace_root/.cache/tools/uv-cache"
      export UV_PROJECT_ENVIRONMENT="$workspace_root/.cache/tools/python-dev"
      export ZIG_GLOBAL_CACHE_DIR="$workspace_root/.cache/tools/zig-cache"
      export PATH="$workspace_root/.cache/tools/quality/bin:$UV_PROJECT_ENVIRONMENT/bin:$PATH"
      export LUA_CPATH="${luv}/lib/?.so;;"
      export LIBMEMALLOC_QUALITY_PYTHON="$UV_PROJECT_ENVIRONMENT/bin/python"
      export LIBMEMALLOC_LUA="${lua}/bin/lua"
      printf '%s\n' 'Python setup: see docs/getting-started/nix.md'
      printf '%s\n' 'Groups: automation,quality,python-lint; directory: .cache/tools/python-dev'
      printf '%s\n' 'Quality setup: lua scripts/toolchain/install/quality.lua --profile=all'
      printf '%s\n' 'Tool versions: nix build ./tools/nix#tool-versions'
      unset workspace_root
    '';
  };
in
{
  inherit versions;
  shells = {
    default = shell (builtins.attrNames catalog);
    build = shell [ "base" "build" ];
    docs = shell [ "base" "documentation" "lint" ];
  };
}

# EOF

