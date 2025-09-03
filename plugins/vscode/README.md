Shrendditor VS Code Extension

This extension provides a custom editor for editing "shrendd" template files. It features a two-tab interface:
- **Source Tab**: Displays the raw contents of the template file.
- **Processed Tab**: Shows the file after processing `importShrendd` statements.

## Features
- Edit shrendd template files.
- View processed/compiled output in a separate tab.

## Usage
Open any shrendd template file (e.g., `.srd`) and select "Open with Shrendditor".

## Development
- The extension is written in TypeScript.
- Processing logic is based on shell scripts in the main folder.

## Example Templates
See the `test` folder for example shrendd templates.

# Setup

* add a terminal definition for git-bash for `Shrendd Terminal`
  * `ctrl+shift+p` (or `cmd+shift+p` on mac)
  * search for `open user settings json`
  * add a new entry under the appropriate `terminal.integrated.profiles.[os]` section. for windows this should be: `terminal.integrated.profiles.windows`
  * the entry should look like:
```
        "Shrendd Terminal": {
            "path": "C:\\bin\\bash.exe",
            "args": ["-i", "-l"]
        }
```
  * where path is set to the appropriate value for your os, this should actually point to the actual `bash.exe` and not the `git-bash.exe`
  * if you don't point it to `bash.exe`, you may notice terminal windows opening as the plugin processes `.srd` files.
* install the `Shrendditor` plugin
  * currently the plugin is only provided as a VSIX file from shrendd's release page. In the future it may be provided through the market place.
  * `ctrl+shift+p` (or `cmd+shift+p` on mac)
  * search for "extensions install from vsix"
  * select the Shrendditor vsix file.
* close or reload vscode
  * `ctrl+shift+p` (or `cmd+shift+p` on mac)
  * search for "reload window"
* make sure you have run `./shrendd -init`
  * the plugin runs shrendd mostly in offline mode, so you need to have initialized shrendd locally for the project for the plugin to function properly


## Help?

If you, or someone you know, loves typescript, UI work, and vscode, please reach out. This plugin is being provided as a way to see what is possible, and could use someone that has the interest and skills to really develop it further.

Some desired future work:
1. auto-complete
2. syntax highlighting
3. build/compile single files
4. per-project plugin setting cache to reduce initial load times
5. full shrendd support from the UI, including rendering and deploying.