# Personal Theme

A custom dark theme for VS Code/Cursor that combines the base **Vesper** theme with your personal color customizations.

## Features

This theme includes:
- **All base Vesper theme colors** - Complete syntax highlighting, UI elements, and color scheme
- **Your custom overrides** - Personalized colors for:
  - Title bar (darker backgrounds with light text)
  - Tabs (custom active/inactive states)
  - Sidebar section headers (custom background)
  - Bracket highlighting (pink/cyan accent colors)
  - Function names (cyan color: `#a4dedb`)
  - Panel borders
  - Editor group headers

## Installation

### Local Installation

1. Copy this folder to your Cursor extensions directory:
   ```bash
   cp -r ~/cursor-theme-personal ~/.cursor/extensions/personal-theme
   ```

2. Or create a symlink for easy updates:
   ```bash
   ln -s ~/cursor-theme-personal ~/.cursor/extensions/personal-theme
   ```

3. Restart Cursor

4. Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) and select **"Preferences: Color Theme"**

5. Choose **"Personal Theme"**

## Color Palette

### Base Colors (from Vesper)
- **Background**: `#101010` (base), `#1f1f1f` (your override)
- **Foreground**: `#FFF` (base), `#eaeaea` (your override)
- **Accents**: `#FFC799` (orange), `#99FFE4` (cyan), `#FF8080` (red)

### Your Custom Colors
- **Editor Background**: `#1f1f1f`
- **Editor Foreground**: `#eaeaea`
- **Title Bar**: `#1f1f1f` (active), `#1a1a1a` (inactive)
- **Tabs**: `#2f2f2f` (active), `#1a1a1a` (inactive)
- **Sidebar Section Headers**: `#2f2f2f` background, `#eaeaea` text
- **Bracket Colors**: 
  - Pink: `#ff7dc7`
  - Cyan: `#8dfdff`
  - Gray: `#939393`
- **Function Names**: `#a4dedb` (cyan)
- **Borders**: `#2c2c2c`, `#393939`

## Customization

Edit `themes/personal-theme.json` to modify colors. See [VS Code Theme Color Reference](https://code.visualstudio.com/api/references/theme-color) for available color keys.

## Based On

- **Vesper Theme** by Rauno Freiberg - Original theme structure and base colors
- Your personal customizations from `settings.json`
