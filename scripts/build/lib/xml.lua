-- SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
-- SPDX-License-Identifier: GPL-3.0-only

--- Parse the bounded UTF-8 XML subset emitted by CTest, without DTDs or I/O.
-- Reject namespaces and processing instructions beyond the declaration.
-- @return table: public operations constructed by this module.
local function XML_loadModule()
   local XML_TAB = 9
   local XML_LF = 10
   local XML_CR = 13
   local XML_PRINTABLE_FIRST = 32
   local XML_SURROGATE_BEFORE = 0xD7FF
   local XML_SURROGATE_AFTER = 0xE000
   local XML_BMP_LAST = 0xFFFD
   local XML_SUPPLEMENTARY_FIRST = 0x10000
   local XML_UNICODE_LAST = 0x10FFFF
   local XML_DECIMAL_BASE = 10
   local XML_HEX_BASE = 16
   local XML_MAX_SOURCE_BYTES = 8 * 1024 * 1024
   local XML_MAX_ELEMENTS = 10000
   local XML_MAX_DEPTH = 16

   local exports = {}
   local entities = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'" }

   --- Accept only XML 1.0 character values, including numeric references.
   -- @param code any: code supplied to this operation.
   -- @return boolean|nil: accept only XML 1.0 character values, including
   -- numeric references.
   local function xml_character(code)
      return code == XML_TAB
         or code == XML_LF
         or code == XML_CR
         or (code >= XML_PRINTABLE_FIRST and code <= XML_SURROGATE_BEFORE)
         or (code >= XML_SURROGATE_AFTER and code <= XML_BMP_LAST)
         or (code >= XML_SUPPLEMENTARY_FIRST and code <= XML_UNICODE_LAST)
   end

   --- Decode predefined and numeric entities once; never expand declarations.
   -- @param name string: entry or operation name to resolve.
   -- @return any: predefined and numeric entities once; never expand
   -- declarations.
   local function xml_entity(name)
      if entities[name] then
         return entities[name]
      end

      local decimal = name:match("^#([0-9]+)$")
      local hex = name:match("^#x([0-9a-fA-F]+)$")
      local code = decimal and tonumber(decimal, XML_DECIMAL_BASE)
         or (hex and tonumber(hex, XML_HEX_BASE))

      assert(code and xml_character(code), "invalid XML entity")

      return utf8.char(code)
   end

   --- Require every ampersand to begin one complete, supported reference.
   -- @param value any: value supplied to this operation.
   -- @return any: require every ampersand to begin one complete, supported
   -- reference.
   local function xml_text(value)
      assert(not value:find("]]>", 1, true), "invalid XML character data")
      local position, result = 1, {}

      while position <= #value do
         local first = value:find("&", position, true)
         if not first then
            result[#result + 1] = value:sub(position)
            break
         end

         result[#result + 1] = value:sub(position, first - 1)
         local last =
            assert(value:find(";", first, true), "unterminated XML entity")

         result[#result + 1] = xml_entity(value:sub(first + 1, last - 1))
         position = last + 1
      end

      return table.concat(result)
   end

   --- Parse quoted attributes, rejecting duplicates and missing separators.
   -- @param source string: source supplied to this operation.
   -- @return table, table: quoted attributes, rejecting duplicates and missing
   -- separators.
   local function xml_attributes(source)
      local attributes, order, position = {}, {}, 1

      while position <= #source do
         local first, last, name, quote = source:find(
            "^%s+([A-Za-z_][A-Za-z0-9_.-]*)%s*=%s*(['\"])",
            position
         )
         if not first then
            assert(source:sub(position):match("^%s*$"), "invalid XML attribute")
            break
         end

         assert(not attributes[name], "duplicate XML attribute")
         local close =
            assert(source:find(quote, last + 1, true), "unclosed XML attribute")
         local value = source:sub(last + 1, close - 1)

         assert(not value:find("<", 1, true), "markup in XML attribute")
         attributes[name] = xml_text((value:gsub("[\t\n\r]", " ")))
         order[#order + 1] = name
         position = close + 1
      end

      return attributes, order
   end

   --- Find the tag terminator without treating quoted greater-than as markup.
   -- @param source string: source supplied to this operation.
   -- @param position number: one-based byte position in the source.
   -- @return any: the tag terminator without treating quoted greater-than as
   -- markup.
   local function xml_tagEnd(source, position)
      local quote

      for index = position, #source do
         local value = source:sub(index, index)
         if quote then
            if value == quote then
               quote = nil
            end
         elseif value == '"' or value == "'" then
            quote = value
         elseif value == ">" then
            return index
         end
      end

      error("unclosed XML tag")
   end

   --- Validate the optional XML declaration in its sole permitted position.
   -- @param value any: value supplied to this operation.
   -- @return nil: no values.
   local function xml_declaration(value)
      local body =
         assert(value:match("^<%?xml(%s.+)%?>$"), "invalid XML declaration")
      local attributes, order = xml_attributes(body)

      assert(
         order[1] == "version" and attributes.version == "1.0",
         "unsupported XML version"
      )
      local expected = { "version" }
      if attributes.encoding then
         assert(
            attributes.encoding:upper() == "UTF-8",
            "unsupported XML encoding"
         )
         expected[#expected + 1] = "encoding"
      end

      if attributes.standalone then
         assert(
            attributes.standalone == "yes" or attributes.standalone == "no",
            "invalid XML standalone"
         )
         expected[#expected + 1] = "standalone"
      end

      assert(
         table.concat(order, ",") == table.concat(expected, ","),
         "invalid XML declaration fields"
      )
   end

   --- Build a tree only after checking encoding, nesting and document closure.
   -- @param source string: source supplied to this operation.
   -- @return nil: a tree only after checking encoding, nesting and document
   -- closure.
   local function XML_parse(source)
      assert(#source <= XML_MAX_SOURCE_BYTES, "XML report exceeds size limit")
      for _, code in utf8.codes(source) do
         assert(xml_character(code), "invalid XML character")
      end

      source = source:gsub("^\239\187\191", ""):gsub("\r\n?", "\n")
      local position, count, root, stack = 1, 0, nil, {}

      --- Attach character data only to the current element.
      -- @param value any: value supplied to this operation.
      -- @return nil: no values.
      local function append(value)
         if #stack == 0 then
            assert(value:match("^%s*$"), "text outside XML root")
         else
            local node = stack[#stack]

            node.text[#node.text + 1] = value
         end
      end

      --- Parse a start/end tag and keep the element stack balanced.
      -- @param value any: value supplied to this operation.
      -- @return nil: no values.
      local function tag(value)
         local closing = value:match("^/([A-Za-z_][A-Za-z0-9_.-]*)%s*$")
         if closing then
            assert(
               stack[#stack] and stack[#stack].name == closing,
               "mismatched XML close tag"
            )
            table.remove(stack)

            return
         end

         local empty = value:sub(-1) == "/"
         if empty then
            value = value:sub(1, -2)
         end

         local name, rest = value:match("^([A-Za-z_][A-Za-z0-9_.-]*)(.*)$")

         assert(name, "invalid XML tag")
         local node = {
            name = name,
            attributes = xml_attributes(rest),
            children = {},
            text = {},
         }

         count = count + 1
         assert(
            count <= XML_MAX_ELEMENTS and #stack < XML_MAX_DEPTH,
            "XML report exceeds structural limits"
         )
         if #stack == 0 then
            assert(not root, "multiple XML roots")
            root = node
         else
            local children = stack[#stack].children

            children[#children + 1] = node
         end

         if not empty then
            stack[#stack + 1] = node
         end
      end

      --- Consume non-element markup without interpreting its body as elements.
      -- @param prefix any: prefix supplied to this operation.
      -- @param ending any: ending supplied to this operation.
      -- @return nil: no values.
      local function special(prefix, ending)
         local last = assert(
            source:find(ending, position + #prefix, true),
            "unclosed XML markup"
         )
         local body = source:sub(position + #prefix, last - 1)
         if prefix == "<!--" then
            assert(
               not body:find("--", 1, true) and body:sub(-1) ~= "-",
               "invalid XML comment"
            )
         elseif prefix == "<![CDATA[" then
            assert(#stack > 0, "CDATA outside XML root")
            append(body)
         else
            assert(position == 1, "misplaced XML declaration")
            xml_declaration(source:sub(position, last + #ending - 1))
         end

         position = last + #ending
      end

      while position <= #source do
         if source:sub(position, position) ~= "<" then
            local last = source:find("<", position, true) or (#source + 1)
            local value = source:sub(position, last - 1)
            if #stack == 0 then
               assert(value:match("^%s*$"), "text outside XML root")
            end

            append(xml_text(value))
            position = last
         elseif source:sub(position, position + 3) == "<!--" then
            special("<!--", "-->")
         elseif source:sub(position, position + 8) == "<![CDATA[" then
            special("<![CDATA[", "]]>")
         elseif source:sub(position, position + 1) == "<?" then
            special("<?", "?>")
         else
            local last = xml_tagEnd(source, position + 1)

            tag(source:sub(position + 1, last - 1))
            position = last + 1
         end
      end

      assert(root and #stack == 0, "incomplete XML document")

      return root
   end

   exports.parse = XML_parse

   return exports
end

return XML_loadModule()

-- EOF

