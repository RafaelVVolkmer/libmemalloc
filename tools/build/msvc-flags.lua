-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Native MSVC profiles. Options with ABI effects are not cross-ABI promises.

--- Construct this module within its own initialization scope.
-- @return table: this module within its own initialization scope.
local function tools_build_msvc_flags_loadModule()
   return {
      { id = "od", flags = { "/Od" }, contract = "strict" },
      { id = "o1", flags = { "/O1" }, contract = "strict" },
      { id = "o2", flags = { "/O2" }, contract = "strict" },
      { id = "ox", flags = { "/Ox" }, contract = "strict" },
      { id = "size", flags = { "/O2", "/Os" }, contract = "strict" },
      { id = "speed", flags = { "/O2", "/Ot" }, contract = "strict" },
      { id = "no-inline", flags = { "/O2", "/Ob0" }, contract = "strict" },
      { id = "inline", flags = { "/O2", "/Ob2", "/Oi" }, contract = "strict" },
      {
         id = "fp-strict",
         flags = { "/O2", "/fp:strict" },
         contract = "strict-fp",
      },
      {
         id = "fp-fast",
         flags = { "/O2", "/fp:fast" },
         contract = "relaxed-fp",
      },
      {
         id = "unsigned-char",
         flags = { "/O2", "/J" },
         contract = "unsigned-char",
      },
      {
         id = "security",
         flags = { "/O2", "/GS", "/sdl", "/guard:cf" },
         link = { "/guard:cf" },
         contract = "strict",
      },
      {
         id = "ltcg",
         flags = { "/O2", "/GL" },
         link = { "/LTCG" },
         contract = "native-msvc-lto",
      },
      { id = "ndebug", flags = { "/O2", "/DNDEBUG" }, contract = "strict" },
   }
end

return tools_build_msvc_flags_loadModule()

-- EOF

