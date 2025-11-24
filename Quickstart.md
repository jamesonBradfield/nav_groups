\# nav\_groups.nvim - Quick Start



Get up and running in 2 minutes!



\## Installation



\### Option 1: Manual Install (Fast!)

```bash

cd /path/to/downloaded/files

chmod +x install.sh

./install.sh

```



\### Option 2: Copy Manually

```bash

\# Linux/macOS

cp nav\_groups.lua ~/.config/nvim/lua/



\# Windows (PowerShell)

Copy-Item nav\_groups.lua ~/AppData/Local/nvim/lua/

```



\## Setup



Add to your `init.lua`:

```lua

require('nav\_groups').setup()

```



Restart nvim.



\## Usage in 30 Seconds



1\. \*\*Open files\*\* you want to group together

2\. \*\*Press `<leader>ga`\*\* on each file to add them to group 1

3\. \*\*Press `<leader>gn`\*\* to cycle through those files

4\. \*\*Press `<leader>g]`\*\* to switch to group 2

5\. \*\*Repeat\*\* - add different files to group 2



\## Key Bindings



| Key | What It Does |

|-----|--------------|

| `<leader>ga` | Add current file to group |

| `<leader>gn` | Next file in group |

| `<leader>gp` | Previous file in group |

| `<leader>g]` | Next group |

| `<leader>ge` | Edit all groups |



\## Lualine (Optional)



Already have lualine? Add this to see your groups:



```lua

require('lualine').setup({

&nbsp; sections = {

&nbsp;   lualine\_c = {

&nbsp;     'filename',

&nbsp;     require('nav\_groups').get\_status  -- Add this line

&nbsp;   },

&nbsp; },

})

```



\## Example Workflow



\*\*Working on a game's player controller:\*\*

1\. Open `player.lua` → `<leader>ga`

2\. Open `input.lua` → `<leader>ga`

3\. Open `camera.lua` → `<leader>ga`

4\. Now `<leader>gn` cycles through these 3 files



\*\*Switch to work on enemy AI:\*\*

1\. `<leader>g]` (switch to group 2)

2\. Open `enemy.lua` → `<leader>ga`

3\. Open `ai\_behavior.lua` → `<leader>ga`

4\. Now `<leader>gn` cycles through AI files (group 1 is untouched!)



\*\*Need both visible?\*\*

1\. `<leader>gv` (vsplit with new group)

2\. Left window uses group 1, right uses group 2

3\. Navigate independently in each!



\## That's It!



See `README.md` for full documentation.



\## Troubleshooting



\*\*"Nothing happens when I press the keys"\*\*

\- Make sure you added `require('nav\_groups').setup()` to init.lua

\- Restart nvim



\*\*"Error: module 'nav\_groups' not found"\*\*

\- Check the file is in the right place: `~/.config/nvim/lua/nav\_groups.lua`

\- Try `:lua print(vim.fn.stdpath('config'))` to find your config directory



\*\*"I want different keybindings"\*\*

```lua

require('nav\_groups').setup({ keymaps = false })

vim.keymap.set('n', '<C-1>', require('nav\_groups').add\_file)

-- etc... see example\_config.lua

```

