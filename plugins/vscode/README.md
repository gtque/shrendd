# Shrendd Template Editor VS Code Extension

This extension provides a custom editor for editing "shrendd" template files. It features a two-tab interface:
- **Source Tab**: Displays the raw contents of the template file.
- **Processed Tab**: Shows the file after processing `importShrendd` statements, using the shell rendering logic from the main folder.

## Features
- Edit shrendd template files with syntax highlighting.
- View processed output in a separate tab.

## Usage
Open any shrendd template file (e.g., `.yml`, `.shrendd`) and select "Open with Shrendd Template Editor".

## Development
- The extension is written in TypeScript.
- Processing logic is based on shell scripts in the main folder.

## Example Templates
See the `test` folder for example shrendd templates.
