\# nav\_groups.nvim



Window-local navigation groups for Neovim. Think grapple/harpoon but with multiple independent groups that can be active simultaneously across different windows.



\## Features



\- \*\*Multiple navigation groups\*\*: Create as many groups as you need

\- \*\*Window-local\*\*: Each window can have its own active group

\- \*\*Auto-expansion\*\*: Adding files automatically creates new empty groups

\- \*\*Visual editor\*\*: View and edit all groups in a buffer

\- \*\*Lualine integration\*\*: Show current group and file position in statusline

\- \*\*Independent navigation\*\*: Navigate files within a group without affecting other groups



\## Use Case



Perfect for game development or any project where you work on multiple independent systems:



\- \*\*Group 1\*\*: First-person controller, state machine, states

\- \*\*Group 2\*\*: Inventory system, UI, item database  

\- \*\*Group 3\*\*: Enemy AI, behavior trees, pathfinding



Each group stays independent. Switch between groups or have different groups active in split windows.



\## Installation



\### Using \[lazy.nvim](https://github.com/folke/lazy.nvim)



```lua

{

&nbsp; dir = '/path/to/nav\_groups.nvim', -- or use a git repo when published

&nbsp; config = function()

&nbsp;   require('nav\_groups').setup()

&nbsp; end,

&nbsp; dependencies = {

&nbsp;   'nvim-lualine/lualine.nvim', -- optional, for statusline

&nbsp; }

}

```



\### Using \[packer.nvim](https://github.com/wbthomason/packer.nvim)



```lua

use {

&nbsp; '/path/to/nav\_groups.nvim',

&nbsp; config = function()

&nbsp;   require('nav\_groups').setup()

&nbsp; end

}

```



\### Manual Installation



1\. Copy `nav\_groups.lua` to your Neovim runtime path:

&nbsp;  - Linux/macOS: `~/.config/nvim/lua/nav\_groups.lua`

&nbsp;  - Windows: `~/AppData/Local/nvim/lua/nav\_groups.lua`



2\. Add to your `init.lua`:

```lua

require('nav\_groups').setup()

```



\## Usage



\### Basic Workflow



1\. \*\*Open your project\*\* and start editing files

2\. \*\*Add files to groups\*\* using `<leader>ga` (or `:NavGroupAdd`)

&nbsp;  - Files are added to the current window's active group

&nbsp;  - A new empty group is automatically created when you add files

3\. \*\*Navigate\*\* within the group:

&nbsp;  - `<leader>gn` - Next file in group

&nbsp;  - `<leader>gp` - Previous file in group

4\. \*\*Switch groups\*\*:

&nbsp;  - `<leader>g]` - Next group

&nbsp;  - `<leader>g\[` - Previous group

5\. \*\*View/edit all groups\*\*: `<leader>ge` (or `:NavGroupShow`)



\### Default Keybindings



| Key | Command | Description |

|-----|---------|-------------|

| `<leader>ga` | `:NavGroupAdd` | Add current file to current group |

| `<leader>gd` | `:NavGroupRemove` | Remove current file from current group |

| `<leader>gn` | `:NavGroupNext` | Next file in current group |

| `<leader>gp` | `:NavGroupPrev` | Previous file in current group |

| `<leader>g]` | `:NavGroupSwitchNext` | Switch to next group |

| `<leader>g\[` | `:NavGroupSwitchPrev` | Switch to previous group |

| `<leader>ge` | `:NavGroupShow` | Open group editor buffer |

| `<leader>gv` | `:NavGroupVsplit` | Vsplit with different group context |



\### Advanced: Multi-Window Workflow



1\. Open your first system's files and add them to group 1

2\. Use `:NavGroupVsplit` (or `<leader>gv`) to create a new split

3\. The new window will use a different group (or create a new one)

4\. Add files to this group

5\. Each window independently navigates its own group!



\*\*Example scenario:\*\*

```

Left window:       Right window:

Group 1            Group 2

\- player.lua       - enemy.lua

\- input.lua        - ai\_behavior.lua

\- camera.lua       - pathfinding.lua

```



Navigate `player.lua` → `input.lua` on the left while independently navigating enemy system files on the right.



\### Group Editor



Press `<leader>ge` to open the group editor. You'll see:



```

1

\- path/to/file1.lua

\- path/to/file2.lua

2

\- path/to/other.lua

3

\- empty

```



You can:

\- Reorder files (cut/paste lines)

\- Remove files (delete lines)

\- Add files (type `- path/to/file.lua`)

\- Save changes (`:w` or `:wq`)



\## Lualine Integration



Add to your lualine config:



```lua

require('lualine').setup({

&nbsp; sections = {

&nbsp;   lualine\_c = {

&nbsp;     'filename',

&nbsp;     require('nav\_groups').get\_status

&nbsp;   },

&nbsp; },

})

```



This shows: `\[2] 1 2 \[3] 4` meaning:

\- Window is using group 2

\- Group has 4 files

\- Currently on file 3



\## Configuration



\### Disable Default Keymaps



```lua

require('nav\_groups').setup({

&nbsp; keymaps = false

})

```



Then define your own:



```lua

local nav = require('nav\_groups')

vim.keymap.set('n', '<C-h>a', nav.add\_file)

vim.keymap.set('n', '<C-h>d', nav.remove\_file)

-- etc...

```



\## API



\### Functions



\- `add\_file()` - Add current file to current window's group

\- `remove\_file()` - Remove current file from current window's group

\- `next\_file()` - Navigate to next file in group

\- `prev\_file()` - Navigate to previous file in group

\- `next\_group()` - Switch window to next group

\- `prev\_group()` - Switch window to previous group

\- `show\_groups()` - Open group editor

\- `vsplit\_new\_group()` - Create vsplit with different group

\- `get\_status()` - Get status string for lualine



\### Data Structure



```lua

-- Access groups directly if needed

require('nav\_groups').groups = {

&nbsp; { 'file1.lua', 'file2.lua' },  -- Group 1

&nbsp; { 'other.lua' },                -- Group 2

&nbsp; {},                             -- Group 3 (empty)

}

```



\## Future Enhancements



Potential features for later:



\- Session persistence (save/restore groups)

\- Group labels/names (instead of just numbers)

\- Per-project vs global groups

\- Telescope integration

\- Jump to file by number (e.g., `<leader>g3` jumps to file 3)



\## Comparison to Other Plugins



\### vs Harpoon/Grapple

\- \*\*Harpoon/Grapple\*\*: One global list of files

\- \*\*nav\_groups\*\*: Multiple independent lists, window-local



\### vs Argument List

\- \*\*Argument list\*\*: One list per tab

\- \*\*nav\_groups\*\*: Multiple lists, any window can use any list



\### vs Location List

\- \*\*Location list\*\*: Window-local but designed for errors

\- \*\*nav\_groups\*\*: Window-local and designed for navigation



\## License



MIT



\## Contributing



This is a personal workflow tool, but feel free to fork and adapt to your needs!

