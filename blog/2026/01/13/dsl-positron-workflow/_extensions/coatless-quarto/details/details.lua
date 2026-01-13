-- ============================================================================
-- Default Options
-- ============================================================================

--- Default options for interactive (HTML-based) formats.
-- @class DEFAULT_INTERACTIVE
-- @field open boolean Whether details are open by default (default: false)
-- @field summary_text string Default summary text when none specified (default: "Click to expand")
-- @field accordion_mode string Accordion behavior mode: "exclusive" or "synchronized" (default: "exclusive")
-- @field show_controls boolean Whether to show expand/collapse all buttons (default: false)
-- @field controls_position string Position of controls: "top", "bottom", or "both" (default: "top")
-- @field controls_expand_text string Text for expand all button (default: "Expand all")
-- @field controls_collapse_text string Text for collapse all button (default: "Collapse all")
local DEFAULT_INTERACTIVE = {
  open = false,
  summary_text = "Click to expand",
  accordion_mode = "exclusive",
  show_controls = false,
  controls_position = "top",
  controls_expand_text = "Expand all",
  controls_collapse_text = "Collapse all"
}

--- Default options for non-interactive formats (PDF, Word, Typst).
-- @class DEFAULT_NON_INTERACTIVE
-- @field display string Display mode: "show", "placeholder", or "remove" (default: "show")
-- @field placeholder_text string Text shown when display is "placeholder"
-- @field summary_text string Default summary/title text for callouts (default: "Details")
-- @field callout_type string Quarto callout type: "note", "warning", "tip", "caution", "important" (default: "note")
local DEFAULT_NON_INTERACTIVE = {
  display = "show",
  placeholder_text = "Interactive content not available in this format.",
  summary_text = "Details",
  callout_type = "note"
}

--- Default debug mode setting.
-- @field DEFAULT_DEBUG boolean Whether debug logging is enabled by default
local DEFAULT_DEBUG = false

-- ============================================================================
-- Runtime State
-- ============================================================================

--- Runtime options for interactive formats (populated from document metadata).
-- @see DEFAULT_INTERACTIVE
local interactive_opts = {}

--- Runtime options for non-interactive formats (populated from document metadata).
-- @see DEFAULT_NON_INTERACTIVE
local non_interactive_opts = {}

--- Current debug mode state.
local debug_mode = DEFAULT_DEBUG

--- Counter for auto-generating unique element IDs.
local details_counter = 0

--- Flag indicating if any synchronized accordion groups exist in the document.
-- Used to determine whether to inject synchronization JavaScript.
local has_synchronized_groups = false

--- Flag indicating if any details elements were processed.
-- Used to determine whether to inject expand/collapse controls.
local has_details_elements = false

-- ============================================================================
-- Debug Logging
-- ============================================================================

--- Logs a debug message if debug mode is enabled.
-- Messages are prefixed with "[details]" and passed to quarto.log.info.
-- @name debug_log
-- @param message string The format string for the message
-- @param ... any Additional arguments passed to string.format
-- @usage debug_log("Processing element: %s", element_id)
local function debug_log(message, ...)
  if not debug_mode then
    return
  end
  local formatted = string.format("[details] " .. message, ...)
  quarto.log.info(formatted)
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--- Safely retrieves a nested value from a table using a sequence of keys.
-- Traverses the table following the key path and returns nil if any key is missing.
-- @name get_nested
-- @param tbl table The table to traverse
-- @param ... string Keys to follow in sequence
-- @return any The value at the nested path, or nil if any key is missing
-- @usage local value = get_nested(meta, "extensions", "details", "interactive")
local function get_nested(tbl, ...)
  local value = tbl
  for _, key in ipairs({...}) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[key]
  end
  return value
end

--- Converts a Pandoc MetaValue to a Lua boolean.
-- Handles boolean values directly, or stringifies and checks for "true" or empty string.
-- @name to_boolean
-- @param val any The MetaValue to convert
-- @return boolean|nil The converted boolean, or nil if val is nil
-- @usage local is_open = to_boolean(meta["open"])
local function to_boolean(val)
  if val == nil then
    return nil
  end
  if type(val) == "boolean" then
    return val
  end
  local str = pandoc.utils.stringify(val)
  return str == "true" or str == ""
end

--- Converts a Pandoc MetaValue to a string.
-- Uses pandoc.utils.stringify for conversion.
-- @name to_string
-- @param val any The MetaValue to convert
-- @return string|nil The stringified value, or nil if val is nil
-- @usage local text = to_string(meta["summary-text"])
local function to_string(val)
  if val == nil then
    return nil
  end
  return pandoc.utils.stringify(val)
end

--- Creates a shallow copy of a table.
-- Copies only the top-level key-value pairs; nested tables are not cloned.
-- @name shallow_copy
-- @param tbl table The table to copy
-- @return table A new table with the same top-level key-value pairs
-- @usage local opts = shallow_copy(DEFAULT_INTERACTIVE)
local function shallow_copy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

--- Validates that a value is one of the allowed options.
-- If the value is not in the allowed list, logs a warning and returns the default.
-- @name validate_option
-- @param value any The value to validate
-- @param allowed table Array of allowed values
-- @param name string Name of the option (used in warning messages)
-- @param default any Default value to return if validation fails
-- @return any The value if valid, otherwise the default
-- @usage local mode = validate_option(mode, {"exclusive", "synchronized"}, "accordion-mode", "exclusive")
local function validate_option(value, allowed, name, default)
  for _, v in ipairs(allowed) do
    if value == v then
      return value
    end
  end
  if value ~= nil then
    quarto.log.warning(string.format("details: invalid %s '%s'. Using '%s'.", name, value, default))
  end
  return default
end

--- Escapes special HTML characters in a string.
-- Replaces &, <, >, ", and ' with their HTML entity equivalents.
-- @name escape_html
-- @param str string The string to escape
-- @return string The escaped string safe for HTML output
-- @usage local safe = escape_html('<script>alert("xss")</script>')
local function escape_html(str)
  local replacements = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;"
  }
  return (str:gsub("[&<>\"']", replacements))
end

-- ============================================================================
-- Format Detection
-- ============================================================================

--- List of interactive (HTML-based) output formats.
-- These formats support the native HTML `<details>` element.
-- @class INTERACTIVE_FORMATS
-- @field [1] string "html:js"
local INTERACTIVE_FORMATS = {
  "html:js"
}

--- Checks if the current output format is interactive (HTML-based).
-- Iterates through INTERACTIVE_FORMATS and checks against quarto.doc.is_format.
-- @name is_interactive_format
-- @return boolean True if the current format supports HTML details elements
-- @usage if is_interactive_format() then process_html(el) end
local function is_interactive_format()
  for _, fmt in ipairs(INTERACTIVE_FORMATS) do
    if quarto.doc.is_format(fmt) then
      return true
    end
  end
  return false
end

-- ============================================================================
-- Options Parsing
-- ============================================================================

--- Parses interactive options from document metadata.
-- Extracts and validates options from the `extensions.details.interactive` metadata section.
-- @name parse_interactive_options
-- @param meta_section table|nil The interactive metadata section (may be nil)
-- @return table Parsed options table with defaults applied for missing values
-- @see DEFAULT_INTERACTIVE
-- @usage local opts = parse_interactive_options(meta["interactive"])
local function parse_interactive_options(meta_section)
  local opts = shallow_copy(DEFAULT_INTERACTIVE)
  
  if meta_section == nil then
    return opts
  end
  
  local open_val = to_boolean(meta_section["open"])
  if open_val ~= nil then
    opts.open = open_val
  end
  
  local summary = to_string(meta_section["summary-text"])
  if summary then
    opts.summary_text = summary
  end
  
  local accordion_mode = to_string(meta_section["accordion-mode"])
  if accordion_mode then
    opts.accordion_mode = validate_option(
      accordion_mode, 
      {"exclusive", "synchronized"}, 
      "accordion-mode", 
      opts.accordion_mode
    )
  end
  
  local show_controls = to_boolean(meta_section["show-controls"])
  if show_controls ~= nil then
    opts.show_controls = show_controls
  end
  
  local controls_position = to_string(meta_section["controls-position"])
  if controls_position then
    opts.controls_position = validate_option(
      controls_position,
      {"top", "bottom", "both"},
      "controls-position",
      opts.controls_position
    )
  end
  
  local expand_text = to_string(meta_section["controls-expand-text"])
  if expand_text then
    opts.controls_expand_text = expand_text
  end
  
  local collapse_text = to_string(meta_section["controls-collapse-text"])
  if collapse_text then
    opts.controls_collapse_text = collapse_text
  end
  
  return opts
end

--- Parses non-interactive options from document metadata.
-- Extracts and validates options from the `extensions.details.non-interactive` metadata section.
-- @name parse_non_interactive_options
-- @param meta_section table|nil The non-interactive metadata section (may be nil)
-- @return table Parsed options table with defaults applied for missing values
-- @see DEFAULT_NON_INTERACTIVE
-- @usage local opts = parse_non_interactive_options(meta["non-interactive"])
local function parse_non_interactive_options(meta_section)
  local opts = shallow_copy(DEFAULT_NON_INTERACTIVE)
  
  if meta_section == nil then
    return opts
  end
  
  local display = to_string(meta_section["display"])
  if display then
    opts.display = validate_option(display, {"show", "placeholder", "remove"}, "display", opts.display)
  end
  
  local placeholder = to_string(meta_section["placeholder-text"])
  if placeholder then
    opts.placeholder_text = placeholder
  end
  
  local summary = to_string(meta_section["summary-text"])
  if summary then
    opts.summary_text = summary
  end
  
  local callout = to_string(meta_section["callout-type"])
  if callout then
    opts.callout_type = callout
  end
  
  return opts
end

--- Initializes all runtime options from document metadata.
-- Parses the `extensions.details` metadata section and populates global option tables.
-- Debug mode is parsed first to enable logging during initialization.
-- @name initialize_options
-- @param meta table The full document metadata
-- @usage initialize_options(doc.meta)
local function initialize_options(meta)
  local details_meta = get_nested(meta, "extensions", "details")
  
  -- Parse debug option first so we can log during initialization
  if details_meta and details_meta["debug"] ~= nil then
    debug_mode = to_boolean(details_meta["debug"]) or false
  end
  
  debug_log("Initializing options")
  debug_log("Output format interactive: %s", tostring(is_interactive_format()))
  
  if details_meta == nil then
    interactive_opts = shallow_copy(DEFAULT_INTERACTIVE)
    non_interactive_opts = shallow_copy(DEFAULT_NON_INTERACTIVE)
    debug_log("No metadata found, using defaults")
    return
  end
  
  interactive_opts = parse_interactive_options(details_meta["interactive"])
  non_interactive_opts = parse_non_interactive_options(details_meta["non-interactive"])
  
  debug_log("Interactive options: open=%s, summary_text='%s'", 
    tostring(interactive_opts.open), interactive_opts.summary_text)
  debug_log("Non-interactive options: display=%s, callout_type=%s", 
    non_interactive_opts.display, non_interactive_opts.callout_type)
end

-- ============================================================================
-- Conditional Content Filtering
-- ============================================================================

--- Checks if a block is marked as interactive-only.
-- A block is interactive-only if it's a Div with the "interactive-only" class.
-- @name is_interactive_only
-- @param block table A Pandoc block element
-- @return boolean True if the block should only appear in interactive formats
local function is_interactive_only(block)
  return block.t == "Div" and block.classes:includes("interactive-only")
end

--- Checks if a block is marked as non-interactive-only.
-- A block is non-interactive-only if it's a Div with the "non-interactive-only" class.
-- @name is_non_interactive_only
-- @param block table A Pandoc block element
-- @return boolean True if the block should only appear in non-interactive formats
local function is_non_interactive_only(block)
  return block.t == "Div" and block.classes:includes("non-interactive-only")
end

--- Filters content blocks based on the current output format.
-- Removes interactive-only content for non-interactive formats and vice versa.
-- The wrapper div is removed and only inner content is preserved.
-- @name filter_conditional_content
-- @param content table Pandoc List of blocks to filter
-- @return table Filtered Pandoc List of blocks
-- @usage local filtered = filter_conditional_content(el.content)
local function filter_conditional_content(content)
  local interactive = is_interactive_format()
  local filtered = pandoc.List()
  
  for _, block in ipairs(content) do
    if is_interactive_only(block) then
      if interactive then
        -- Include the inner content, not the wrapper div
        for _, inner in ipairs(block.content) do
          filtered:insert(inner)
        end
        debug_log("Including interactive-only content")
      else
        debug_log("Removing interactive-only content")
      end
    elseif is_non_interactive_only(block) then
      if not interactive then
        -- Include the inner content, not the wrapper div
        for _, inner in ipairs(block.content) do
          filtered:insert(inner)
        end
        debug_log("Including non-interactive-only content")
      else
        debug_log("Removing non-interactive-only content")
      end
    else
      filtered:insert(block)
    end
  end
  
  return filtered
end

-- ============================================================================
-- Summary Extraction
-- ============================================================================

--- Converts Pandoc Inlines to an HTML string.
-- Used for rendering rich summary text from headings.
-- Removes wrapping paragraph tags from the output.
-- @name inlines_to_html
-- @param inlines table Pandoc Inlines (list of inline elements)
-- @return string HTML representation of the inlines
local function inlines_to_html(inlines)
  local doc = pandoc.Pandoc({pandoc.Plain(inlines)})
  local html = pandoc.write(doc, 'html')
  -- Remove wrapping <p> tags if present
  html = html:gsub("^%s*<p>", ""):gsub("</p>%s*$", "")
  return html
end

--- Converts Pandoc Blocks to an HTML string for summary display.
-- Used for rendering rich summary text from summary divs.
-- Removes wrapping paragraph tags for single paragraphs.
-- @name blocks_to_summary_html
-- @param blocks table Pandoc Blocks (list of block elements)
-- @return string HTML representation of the blocks
local function blocks_to_summary_html(blocks)
  local doc = pandoc.Pandoc(blocks)
  local html = pandoc.write(doc, 'html')
  -- Remove wrapping <p> tags for single paragraph
  html = html:gsub("^%s*<p>", ""):gsub("</p>%s*$", "")
  return html
end

--- Finds and removes a summary div from content.
-- Searches for a Div with the "summary" class and extracts its content.
-- @name extract_summary_div
-- @param content table Pandoc List of blocks (modified in place)
-- @return table|nil The summary div's content blocks, or nil if not found
-- @return table The modified content list with summary div removed
local function extract_summary_div(content)
  for i, block in ipairs(content) do
    if block.t == "Div" and block.classes:includes('summary') then
      local summary_content = block.content
      content:remove(i)
      debug_log("Extracted summary from div")
      return summary_content, content
    end
  end
  return nil, content
end

--- Finds and removes the first heading from content.
-- Extracts the heading's inline content to use as summary text.
-- @name extract_first_heading
-- @param content table Pandoc List of blocks (modified in place)
-- @return table|nil The heading's inline content, or nil if no heading found
-- @return table The modified content list with heading removed
local function extract_first_heading(content)
  for i, block in ipairs(content) do
    if block.t == "Header" then
      local heading_inlines = block.content
      content:remove(i)
      debug_log("Extracted summary from heading (level %d)", block.level)
      return heading_inlines, content
    end
  end
  return nil, content
end

--- Removes a summary div from content without extracting its text.
-- Used when summary comes from an attribute but div should still be removed.
-- @name remove_summary_div
-- @param content table Pandoc List of blocks (modified in place)
-- @return table The modified content list
local function remove_summary_div(content)
  for i, block in ipairs(content) do
    if block.t == "Div" and block.classes:includes('summary') then
      content:remove(i)
      break
    end
  end
  return content
end

--- Extracts summary information from a details div element.
-- Returns both HTML and plain text versions for different output formats.
-- Priority order: 1) summary attribute, 2) summary div, 3) first heading, 4) default.
-- @name extract_summary
-- @param el table The details Div element
-- @param default_text string Default summary text if no summary found
-- @return table Summary result table with html, plain, and source fields
-- @return table Cleaned content blocks with summary elements removed
-- @see SummaryResult
local function extract_summary(el, default_text)
  local content = pandoc.List(el.content)
  local summary = {
    html = escape_html(default_text),
    plain = default_text,
    source = "default"
  }
  
  -- Priority 1: summary attribute
  if el.attributes.summary then
    summary.html = escape_html(el.attributes.summary)
    summary.plain = el.attributes.summary
    summary.source = "attribute"
    content = remove_summary_div(content)
    debug_log("Summary from attribute: '%s'", summary.plain)
  else
    -- Priority 2: summary div (supports rich formatting)
    local div_content
    div_content, content = extract_summary_div(content)
    if div_content then
      summary.html = blocks_to_summary_html(div_content)
      summary.plain = pandoc.utils.stringify(div_content)
      summary.source = "div"
    else
      -- Priority 3: first heading (supports rich formatting)
      local heading_inlines
      heading_inlines, content = extract_first_heading(content)
      if heading_inlines then
        summary.html = inlines_to_html(heading_inlines)
        summary.plain = pandoc.utils.stringify(heading_inlines)
        summary.source = "heading"
      else
        debug_log("Using default summary")
      end
    end
  end
  
  return summary, content
end

-- ============================================================================
-- Accessibility and ID Generation
-- ============================================================================

--- Generates a unique ID for a details element.
-- Uses an auto-incrementing counter to ensure uniqueness within the document.
-- @name generate_details_id
-- @return string A unique ID in the format "details-N"
local function generate_details_id()
  details_counter = details_counter + 1
  return string.format("details-%d", details_counter)
end

--- Gets or generates an ID for a details element.
-- Returns the element's existing identifier if set, otherwise generates a new one.
-- @name get_element_id
-- @param el table The details Div element
-- @return string The element's ID (existing or generated)
local function get_element_id(el)
  if el.identifier and el.identifier ~= "" then
    debug_log("Using provided ID: '%s'", el.identifier)
    return el.identifier
  end
  local id = generate_details_id()
  debug_log("Generated ID: '%s'", id)
  return id
end

-- ============================================================================
-- HTML Output Generation
-- ============================================================================

--- Determines the open state for an HTML details element.
-- Checks the element's open attribute, falling back to global default.
-- @name get_html_open_state
-- @param el table The details Div element
-- @return boolean True if the details should be open by default
local function get_html_open_state(el)
  local attr_open = el.attributes.open
  
  if attr_open == "true" or attr_open == "" then
    return true
  elseif attr_open == "false" then
    return false
  else
    return interactive_opts.open
  end
end

--- Builds an HTML attributes string from a table.
-- Handles boolean attributes (true = present, false = absent) and string values.
-- @name build_html_attributes
-- @param attrs table Table of attribute name-value pairs
-- @return string Space-separated HTML attributes string
-- @usage build_html_attributes({id="test", open=true}) -- returns 'id="test" open'
local function build_html_attributes(attrs)
  local parts = {}
  for name, value in pairs(attrs) do
    if value == true then
      table.insert(parts, name)
    elseif value and value ~= false then
      table.insert(parts, string.format('%s="%s"', name, escape_html(value)))
    end
  end
  return table.concat(parts, " ")
end

--- Generates HTML output for a details element.
-- Creates the `<details>` and `<summary>` HTML wrapper while preserving
-- content as Pandoc blocks for proper Quarto processing (math, etc.).
-- @name generate_html
-- @param summary table The summary result table with html, plain, source fields
-- @param content table The content blocks to render inside the details
-- @param attrs table Table of HTML attributes for the details element
-- @return table Pandoc List of blocks (RawBlocks for wrapper, content blocks preserved)
-- @see SummaryResult
local function generate_html(summary, content, attrs)
  local attr_str = build_html_attributes(attrs)
  if attr_str ~= "" then
    attr_str = " " .. attr_str
  end

  local result = pandoc.List()

  -- Opening details and summary tags
  local opening = string.format(
    '<details%s>\n<summary>%s</summary>',
    attr_str,
    summary.html
  )
  result:insert(pandoc.RawBlock('html', opening))

  -- Preserve content as Pandoc blocks for proper Quarto processing
  for _, block in ipairs(content) do
    result:insert(block)
  end

  -- Closing details tag
  result:insert(pandoc.RawBlock('html', '</details>'))

  return result
end

--- Gets the accordion mode for a details element.
-- Checks element attribute first, then falls back to global setting.
-- @name get_accordion_mode
-- @param el table The details Div element
-- @return string Accordion mode: "exclusive" or "synchronized"
local function get_accordion_mode(el)
  local attr_mode = el.attributes["accordion-mode"]
  if attr_mode then
    return validate_option(
      attr_mode, 
      {"exclusive", "synchronized"}, 
      "accordion-mode", 
      interactive_opts.accordion_mode
    )
  end
  return interactive_opts.accordion_mode
end

--- Processes a details div for HTML output.
-- Builds the complete HTML structure with accessibility attributes and accordion support.
-- @name process_html
-- @param el table The details Div element
-- @param summary table The summary result table
-- @param content table The cleaned content blocks
-- @return table Pandoc RawBlock containing the HTML details element
-- @see SummaryResult
local function process_html(el, summary, content)
  local id = get_element_id(el)
  local is_open = get_html_open_state(el)
  local group = el.attributes.group
  local accordion_mode = get_accordion_mode(el)
  
  -- Build attributes table
  local attrs = {
    id = id,
    open = is_open,
    ["aria-label"] = summary.plain
  }
  
  -- Handle accordion grouping based on mode
  if group then
    if accordion_mode == "exclusive" then
      -- Use native HTML name attribute for exclusive mode
      attrs.name = group
    else
      -- Use data attribute for synchronized mode (handled by JavaScript)
      attrs["data-details-group"] = group
      attrs["data-accordion-mode"] = "synchronized"
      has_synchronized_groups = true
    end
  end
  
  debug_log("Processing HTML: id=%s, open=%s, group=%s, mode=%s", 
    id, tostring(is_open), tostring(group), accordion_mode)
  
  return generate_html(summary, content, attrs)
end

-- ============================================================================
-- Non-Interactive Output Generation
-- ============================================================================

--- Gets the display mode for non-interactive output.
-- Checks element attribute first, then falls back to global setting.
-- @name get_display_mode
-- @param el table The details Div element
-- @return string Display mode: "show", "placeholder", or "remove"
local function get_display_mode(el)
  local attr_display = el.attributes["display"]
  if attr_display then
    return validate_option(attr_display, {"show", "placeholder", "remove"}, "display", non_interactive_opts.display)
  end
  return non_interactive_opts.display
end

--- Gets the placeholder text for non-interactive output.
-- Checks element attribute first, then falls back to global setting.
-- @name get_placeholder_text
-- @param el table The details Div element
-- @return string Placeholder text to display
local function get_placeholder_text(el)
  return el.attributes["placeholder-text"] or non_interactive_opts.placeholder_text
end

--- Gets the callout type for non-interactive output.
-- Checks element attribute first, then falls back to global setting.
-- @name get_callout_type
-- @param el table The details Div element
-- @return string Quarto callout type (note, warning, tip, caution, important)
local function get_callout_type(el)
  return el.attributes["callout-type"] or non_interactive_opts.callout_type
end

--- Gets the summary text for non-interactive output.
-- Supports explicit override via non-interactive-summary attribute.
-- @name get_non_interactive_summary
-- @param el table The details Div element
-- @param summary table The summary result table
-- @return string Summary text to use as callout title
-- @see SummaryResult
local function get_non_interactive_summary(el, summary)
  -- Check for explicit non-interactive summary override
  local ni_summary = el.attributes["non-interactive-summary"]
  if ni_summary then
    return ni_summary
  end
  
  -- If no summary attribute was set, use non-interactive default
  if el.attributes.summary == nil and summary.source == "default" then
    return non_interactive_opts.summary_text
  end
  
  -- Use plain text version for callout title
  return summary.plain
end

--- Creates a Quarto callout block.
-- @name create_callout
-- @param title string The callout title
-- @param content table The callout content (Pandoc Blocks)
-- @param callout_type string The callout type (note, warning, tip, caution, important)
-- @param id string|nil Optional ID for the callout
-- @return table Quarto Callout block
local function create_callout(title, content, callout_type, id)
  return quarto.Callout({
    type = callout_type,
    title = title,
    content = pandoc.Blocks(content),
    collapse = false,
    id = id
  })
end

--- Creates placeholder content as Pandoc blocks.
-- Wraps the placeholder text in a paragraph.
-- @name create_placeholder_content
-- @param placeholder_text string The placeholder text
-- @return table Pandoc Blocks containing a single paragraph
local function create_placeholder_content(placeholder_text)
  return { pandoc.Para(pandoc.Str(placeholder_text)) }
end

--- Processes a details div for non-interactive output.
-- Creates a Quarto callout or removes the element based on display mode.
-- @name process_non_interactive
-- @param el table The details Div element
-- @param summary table The summary result table
-- @param content table The cleaned content blocks
-- @return table Quarto Callout block, empty table (for removal), or nil
-- @see SummaryResult
local function process_non_interactive(el, summary, content)
  local display = get_display_mode(el)
  
  debug_log("Processing non-interactive: display=%s", display)
  
  if display == "remove" then
    debug_log("Removing details block")
    return {}
  end
  
  local callout_type = get_callout_type(el)
  local title = get_non_interactive_summary(el, summary)
  local id = get_element_id(el)
  
  if display == "placeholder" then
    local placeholder = get_placeholder_text(el)
    local placeholder_content = create_placeholder_content(placeholder)
    debug_log("Creating placeholder callout: '%s'", placeholder)
    return create_callout(title, placeholder_content, callout_type, id)
  end
  
  -- display == "show"
  debug_log("Creating full callout with title: '%s'", title)
  return create_callout(title, content, callout_type, id)
end

-- ============================================================================
-- Main Filter Functions
-- ============================================================================

--- Checks if a Div element is a details block.
-- A Div is a details block if it has the "details" class.
-- @name is_details_div
-- @param el table The Div element to check
-- @return boolean True if the element is a details block
local function is_details_div(el)
  return el.classes:includes('details')
end

--- Gets the appropriate default summary text based on output format.
-- Returns interactive or non-interactive default based on current format.
-- @name get_default_summary
-- @return string Default summary text for the current format
local function get_default_summary()
  if is_interactive_format() then
    return interactive_opts.summary_text
  end
  return non_interactive_opts.summary_text
end

--- Processes a details Div element.
-- Main entry point for handling a details block. Extracts summary,
-- filters conditional content, and delegates to format-specific processor.
-- @name process_details_div
-- @param el table The Div element with the "details" class
-- @return table Processed output: RawBlock (HTML), Callout, empty table, or nil
local function process_details_div(el)
  debug_log("Processing details div")
  
  -- Track that we have at least one details element
  has_details_elements = true
  
  local default_summary = get_default_summary()
  local summary, content = extract_summary(el, default_summary)
  
  -- Filter conditional content based on format
  content = filter_conditional_content(content)
  
  if is_interactive_format() then
    return process_html(el, summary, content)
  end
  
  return process_non_interactive(el, summary, content)
end

-- ============================================================================
-- Standalone Conditional Content Filter
-- ============================================================================

--- Processes standalone conditional content divs (outside of details blocks).
-- Handles interactive-only and non-interactive-only divs at the document level.
-- @name process_conditional_div
-- @param el table The Div element to process
-- @return table|nil The inner content blocks, empty table (for removal), or nil (not conditional)
local function process_conditional_div(el)
  local interactive = is_interactive_format()
  
  if is_interactive_only(el) then
    if interactive then
      debug_log("Including standalone interactive-only div")
      return el.content
    else
      debug_log("Removing standalone interactive-only div")
      return {}
    end
  end
  
  if is_non_interactive_only(el) then
    if not interactive then
      debug_log("Including standalone non-interactive-only div")
      return el.content
    else
      debug_log("Removing standalone non-interactive-only div")
      return {}
    end
  end
  
  return nil
end

-- ============================================================================
-- JavaScript Generation
-- ============================================================================

--- Generates JavaScript for synchronized accordion groups.
-- Creates a script that listens for toggle events and synchronizes
-- all details elements in the same group.
-- @name generate_synchronized_js
-- @return string JavaScript code wrapped in script tags
local function generate_synchronized_js()
  return [[
<script>
(function() {
  document.addEventListener('DOMContentLoaded', function() {
    // Find all synchronized details elements
    var syncDetails = document.querySelectorAll('details[data-accordion-mode="synchronized"]');
    
    syncDetails.forEach(function(details) {
      details.addEventListener('toggle', function(e) {
        if (e.target !== details) return;
        
        var group = details.getAttribute('data-details-group');
        if (!group) return;
        
        var isOpen = details.open;
        
        // Find all other details in the same group
        var groupMembers = document.querySelectorAll(
          'details[data-details-group="' + group + '"][data-accordion-mode="synchronized"]'
        );
        
        groupMembers.forEach(function(member) {
          if (member !== details && member.open !== isOpen) {
            member.open = isOpen;
          }
        });
      });
    });
  });
})();
</script>
]]
end

-- ============================================================================
-- Expand/Collapse Controls
-- ============================================================================

--- Generates CSS for the expand/collapse controls.
-- Provides styling for the control buttons with hover, focus, and active states.
-- @name generate_controls_css
-- @return string CSS code wrapped in style tags
local function generate_controls_css()
  return [[
<style>
.details-controls {
  display: flex;
  gap: 0.5rem;
  margin: 1rem 0;
  flex-wrap: wrap;
}
.details-controls button {
  padding: 0.375rem 0.75rem;
  font-size: 0.875rem;
  font-weight: 500;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  background-color: #f9fafb;
  color: #374151;
  cursor: pointer;
  transition: background-color 0.15s ease-in-out, border-color 0.15s ease-in-out;
}
.details-controls button:hover {
  background-color: #f3f4f6;
  border-color: #9ca3af;
}
.details-controls button:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}
.details-controls button:active {
  background-color: #e5e7eb;
}
</style>
]]
end

--- Generates HTML for the expand/collapse controls.
-- Creates a button group with expand all and collapse all buttons.
-- Includes ARIA attributes for accessibility.
-- @name generate_controls_html
-- @param position string Position identifier ("top" or "bottom") used in element ID
-- @return string HTML code for the control buttons
local function generate_controls_html(position)
  local expand_text = escape_html(interactive_opts.controls_expand_text)
  local collapse_text = escape_html(interactive_opts.controls_collapse_text)
  
  return string.format([[
<div class="details-controls" id="details-controls-%s" role="group" aria-label="Expand or collapse all details sections">
  <button type="button" onclick="window.detailsExpandAll()" aria-label="%s">%s</button>
  <button type="button" onclick="window.detailsCollapseAll()" aria-label="%s">%s</button>
</div>
]], position, expand_text, expand_text, collapse_text, collapse_text)
end

--- Generates JavaScript for the expand/collapse control buttons.
-- Defines global functions for expanding and collapsing all details elements.
-- @name generate_controls_js
-- @return string JavaScript code wrapped in script tags
local function generate_controls_js()
  return [[
<script>
(function() {
  window.detailsExpandAll = function() {
    document.querySelectorAll('details').forEach(function(details) {
      details.open = true;
    });
  };
  
  window.detailsCollapseAll = function() {
    document.querySelectorAll('details').forEach(function(details) {
      details.open = false;
    });
  };
})();
</script>
]]
end

--- Checks if controls should be shown at a given position.
-- Evaluates based on show_controls setting and controls_position configuration.
-- @name should_show_controls_at
-- @param position string The position to check: "top" or "bottom"
-- @return boolean True if controls should be shown at the specified position
local function should_show_controls_at(position)
  if not interactive_opts.show_controls then
    return false
  end
  
  local configured = interactive_opts.controls_position
  if configured == "both" then
    return true
  end
  
  return configured == position
end

-- ============================================================================
-- Pandoc Filter Entry Points
-- ============================================================================

--- Meta filter: reads and initializes options from document metadata.
-- This filter runs first to parse configuration before processing elements.
-- @name Meta
-- @param meta table The document metadata
-- @return table The unchanged metadata
-- @see initialize_options
function Meta(meta)
  initialize_options(meta)
  return meta
end

--- Div filter: processes details divs and conditional content.
-- Handles both details blocks and standalone conditional content divs.
-- @name Div
-- @param el table The Div element to process
-- @return table|nil Processed output, or nil if the element is unchanged
-- @see process_details_div
-- @see process_conditional_div
function Div(el)
  -- Check for details div first
  if is_details_div(el) then
    return process_details_div(el)
  end
  
  -- Check for standalone conditional content
  return process_conditional_div(el)
end

--- Pandoc filter: injects controls and JavaScript at appropriate document positions.
-- Runs after all Div processing to add document-level features.
-- Injects expand/collapse controls and synchronized accordion JavaScript.
-- @name Pandoc
-- @param doc table The Pandoc document
-- @return table The modified document with injected blocks
function Pandoc(doc)
  if not is_interactive_format() then
    return doc
  end
  
  local blocks_to_prepend = pandoc.List()
  local blocks_to_append = pandoc.List()
  
  -- Handle expand/collapse controls
  if interactive_opts.show_controls and has_details_elements then
    debug_log("Injecting expand/collapse controls")
    
    -- Add CSS (only once, at the beginning)
    local css = generate_controls_css()
    blocks_to_prepend:insert(pandoc.RawBlock('html', css))
    
    -- Add JS for controls
    local controls_js = generate_controls_js()
    blocks_to_prepend:insert(pandoc.RawBlock('html', controls_js))
    
    -- Add controls at top if configured
    if should_show_controls_at("top") then
      debug_log("Adding controls at top")
      local top_controls = generate_controls_html("top")
      blocks_to_prepend:insert(pandoc.RawBlock('html', top_controls))
    end
    
    -- Add controls at bottom if configured
    if should_show_controls_at("bottom") then
      debug_log("Adding controls at bottom")
      local bottom_controls = generate_controls_html("bottom")
      blocks_to_append:insert(pandoc.RawBlock('html', bottom_controls))
    end
  end
  
  -- Handle synchronized accordion groups
  if has_synchronized_groups then
    debug_log("Injecting JavaScript for synchronized accordion groups")
    local sync_js = generate_synchronized_js()
    blocks_to_append:insert(pandoc.RawBlock('html', sync_js))
  end
  
  -- Apply modifications if any
  if #blocks_to_prepend > 0 or #blocks_to_append > 0 then
    local new_blocks = pandoc.List()
    
    -- Add prepended blocks
    for _, block in ipairs(blocks_to_prepend) do
      new_blocks:insert(block)
    end
    
    -- Add original blocks
    for _, block in ipairs(doc.blocks) do
      new_blocks:insert(block)
    end
    
    -- Add appended blocks
    for _, block in ipairs(blocks_to_append) do
      new_blocks:insert(block)
    end
    
    doc.blocks = new_blocks
  end
  
  return doc
end

-- ============================================================================
-- Filter Registration
-- ============================================================================

--- Filter chain registration.
-- Registers the filter functions in the correct execution order.
-- Meta runs first, then Div for each element, then Pandoc for final processing.
-- @return table Array of filter tables in execution order
return {
  { Meta = Meta },
  { Div = Div },
  { Pandoc = Pandoc }
}