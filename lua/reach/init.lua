local Entry = require('reach.picker.entry')
local Machine = require('reach.machine')
local Picker = require('reach.picker.picker')
local cache = require('reach.cache')
local config = require('reach.config')
local helpers = require('reach.helpers')
local highlights = require('reach.highlights')
local util = require('reach.util')
local notify = helpers.notify
local buffers = require('reach.buffers')
local make_buffers = require('reach.buffers.make_buffers')

local module = {}

function module.setup(cfg)
  config.setup(cfg)
  highlights.setup()
  cache.setup()
end

function module.buffers(options)
  options = buffers.options.extend(options)

  local bufs = make_buffers(options)

  local count = #bufs

  if not options.show_current then
    local current = vim.api.nvim_get_current_buf()
    count = util.count(function(buffer)
      return buffer.bufnr ~= current
    end, bufs)
  end

  if count < 1 then
    return notify('Only one buffer')
  end

  local entries = vim.tbl_map(function(buffer)
    return Entry:new({
      component = buffers.component,
      data = buffer,
    })
  end, bufs)

  local picker = Picker:new(entries, options.window)

  local max_handle_length = 0
  local marker_present = false

  for _, buffer in pairs(bufs) do
    if #buffer.handle > max_handle_length then
      max_handle_length = #buffer.handle
    end

    if buffer.previous_marker then
      marker_present = true
    end
  end

  picker:set_ctx({
    options = options,
    marker_present = marker_present,
    max_handle_length = max_handle_length,
  })

  local machine = Machine:new(buffers.machine)

  machine.ctx = {
    picker = picker,
    options = options,
  }

  machine:init()
end

return module
