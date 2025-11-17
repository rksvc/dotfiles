--- generated from https://github.com/mpv-player/mpv/blob/master/DOCS/man/lua.rst
--- @meta mp.options

local options = {}

--- A `table` with key-value pairs. The type of the default values is important for
--- converting the values read from the config file or command-line back. Do not use
--- `nil` as a default value!
---
--- The `identifier` is used to identify the config-file and the command-line
--- options. These needs to unique to avoid collisions with other scripts. Defaults
--- to `mp.get_script_name()` if the parameter is `nil` or missing.
---
--- The `on_update` parameter enables run-time updates of all matching option values
--- via the `script-opts` option/property. If any of the matching options changes,
--- the values in the `table` (which was originally passed to the function) are
--- changed, and `on_update(list)` is called. `list` is a table where each updated
--- option has a `list[option_name] = true` entry. There is no initial `on_update()`
--- call. This never re-reads the config file. `script-opts` is always applied on
--- the original config file, ignoring previous `script-opts` values (for example,
--- if an option is removed from `script-opts` at runtime, the option will have the
--- value in the config file). `table` entries are only written for option values
--- whose values effectively change (this is important if the script changes `table`
--- entries independently).
function options.read_options(table, identifier, on_update) end

return options
