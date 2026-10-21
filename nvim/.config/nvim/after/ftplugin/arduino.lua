-- arduino-cli in a terminal split; sketch dir = this file's dir.
-- ponytail: Uno + first USB serial port; set both in sketch.yaml if you add boards
local fqbn = "arduino:avr:uno"
local port = "$(ls /dev/cu.usb* 2>/dev/null | head -1)"

local function run(cmd)
  vim.cmd("write")
  vim.cmd("botright 15split | terminal " .. cmd)
end

local function map(lhs, cmd, desc)
  vim.keymap.set("n", lhs, function()
    run(cmd:gsub("SKETCH", vim.fn.shellescape(vim.fn.expand("%:p:h"))))
  end, { buffer = true, desc = desc })
end

map("<localleader>c", "arduino-cli compile -b " .. fqbn .. " SKETCH", "Arduino compile")
map("<localleader>u", "arduino-cli compile -u -b " .. fqbn .. " -p " .. port .. " SKETCH", "Arduino upload")
map("<localleader>m", "arduino-cli monitor -p " .. port .. " -c baudrate=9600", "Arduino serial monitor")
