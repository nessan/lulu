-----------------------------------------------------------------------------------------------------------------------
-- Lulu: Loads all the `lulu` modules into the global environment.
--
-- Full Documentation:      https://nessan.github.io/lulu
-- Source Repository:       https://github.com/nessan/lulu
-- SPDX-FileCopyrightText:  2025 Nessan Fitzmaurice <nzznfitz+gh@icloud.com>
-- SPDX-License-Identifier: MIT
-----------------------------------------------------------------------------------------------------------------------

-- The core `lulu.string` and `lulu.table` modules are "unnamed". They extend the native `string` and `table` types.
require('lulu.string')
require('lulu.table')

-- The list of the other "named" `lulu` modules.
local lulu_modules = {
    'Array',
    'callable',
    'Enum',
    'messages',
    'paths',
    'scribe',
    'types',
    'xpeg'
}

-- Load the other `lulu` modules into the global environment with the correct name.
-- After this, you can use `local arr = Array { 1, 2, 3 }` etc. without any `lulu` prefix.
for _, module in ipairs(lulu_modules) do
    _G[module] = require('lulu.' .. module)
end
