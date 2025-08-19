
import { exec } from 'child_process';
import { resolve } from 'path';
import * as vscode from 'vscode';

export class ShrenddEditorProvider implements vscode.CustomTextEditorProvider {
  
  readonly context: vscode.ExtensionContext;
  
  private targetFile: string = '';

  public static register(context: vscode.ExtensionContext): vscode.Disposable {
    const provider = new ShrenddEditorProvider(context);
    return vscode.window.registerCustomEditorProvider(
      ShrenddEditorProvider.viewType,
      provider
    );
  }

  private static readonly viewType = 'shrendd.templateEditor';

  constructor(private readonly mycontext: vscode.ExtensionContext) {
    this.context = mycontext
  }

  async resolveCustomTextEditor(
    document: vscode.TextDocument,
    webviewPanel: vscode.WebviewPanel,
    _token: vscode.CancellationToken
  ): Promise<void> {
    webviewPanel.webview.options = {
      enableScripts: true
    };

    webviewPanel.webview.html = this.getHtmlForWebview(document);

    // Listen for document changes
    const changeDocumentSubscription = vscode.workspace.onDidChangeTextDocument(e => {
      if (e.document.uri.toString() === document.uri.toString()) {
        webviewPanel.webview.postMessage({
          type: 'update',
          text: document.getText()
        });
      }
    });

    webviewPanel.onDidDispose(() => {
      changeDocumentSubscription.dispose();
    });

    // Handle messages from the webview
    webviewPanel.webview.onDidReceiveMessage(async message => {
      switch (message.type) {
        case 'edit':
          this.updateTextDocument(document, message.text);
          break;
        case 'process':
          const processed = await this.processTemplate(document, this.context);
          webviewPanel.webview.postMessage({ type: 'processed', text: processed });
          break;
      }
    });
  }

  private getHtmlForWebview(document: vscode.TextDocument): string {
    const nonce = getNonce();
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${nonce}'; style-src 'unsafe-inline';">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Shrendd Template Editor</title>
</head>
<body>
  <div>
    <button id="tab-source">Source</button>
    <button id="tab-processed">Preview</button>
  </div>
  <div id="editor-container">
  <textarea id="source" style="width:100%;height:300px;display:block;overflow:auto;white-space:pre;resize:none;">${escapeHtml(document.getText())}</textarea>
    <pre id="processed" style="width:100%;height:300px;display:none;"></pre>
  </div>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const source = document.getElementById('source');
    const processed = document.getElementById('processed');
    document.getElementById('tab-source').onclick = () => {
      source.style.display = 'block';
      processed.style.display = 'none';
    };
    document.getElementById('tab-processed').onclick = () => {
      source.style.display = 'none';
      processed.style.display = 'block';
      vscode.postMessage({ type: 'process' });
    };
    source.addEventListener('input', () => {
      vscode.postMessage({ type: 'edit', text: source.value });
    });
    window.addEventListener('message', event => {
      const message = event.data;
      if (message.type === 'update') {
        source.value = message.text;
      } else if (message.type === 'processed') {
        processed.textContent = message.text;
      }
    });
  </script>
</body>
</html>`;
  }

  private updateTextDocument(document: vscode.TextDocument, text: string) {
    const edit = new vscode.WorkspaceEdit();
    const fullRange = new vscode.Range(
      document.positionAt(0),
      document.positionAt(document.getText().length)
    );  
    edit.replace(document.uri, fullRange, text);
    vscode.workspace.applyEdit(edit);
  }

  private async processTemplate(doc: vscode.TextDocument, context: vscode.ExtensionContext): Promise<string> {
    // Run 'shrendd -b' on the current file and return its output
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const path = require('path');
    const cp = require('child_process');
    // Get the user's configured shell from VS Code settings
    const platform = process.platform;
    let shellConfigKey = 'terminal.integrated';
    let shellOs = 'defaultProfile.'
    let shellProfiles = 'profiles.';
    if (platform === 'win32') {
      shellOs += 'windows';
      shellProfiles += 'windows';
    } else if (platform === 'darwin') {
      shellOs += 'osx';
      shellProfiles += 'osx';
    } else {
      shellOs += 'linux';
      shellProfiles += 'linux';
    }
    const shellConfig = vscode.workspace.getConfiguration(shellConfigKey);
    const defaultProfile = 'Shrendd Terminal'; //shellConfig.get(`${shellOs}`);
    // const defaultProfile = shellConfig.get('defaultProfile.windows');
    // const profiles = shellConfig.get('profiles.windows');
    const profiles = shellConfig.get<Record<string, any>>(`${shellProfiles}`);
    let shellPath = '';
    // console.log(`Platform: ${platform}, Shell OS: ${shellOs}, default profile: ${defaultProfile}, Profiles: ${JSON.stringify(profiles)}`);
    if (profiles && typeof defaultProfile === 'string' && profiles[defaultProfile]) {
      shellPath += profiles[defaultProfile].path;
      // console.log(`Default Windows shell path: ${shellPath}`);
    } else {
      console.error('shrendd terminal profile not found or misconfigured.');
    }

    let shrenddPath: string | null = null;
    let shrenddStart = '';
    let shrenddTargetDir: string | null = null;
    let foldersToCheck: string[] = [];
    // foldersToCheck.push("test1");
    if (vscode.window.activeTextEditor) {
      // foldersToCheck.push("test1_a");
      const filePath = vscode.window.activeTextEditor.document.uri.fsPath;
      let currentDir = path.dirname(filePath);
      const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      // Normalize for Windows case-insensitivity
      const norm = (p: string) => p.replace(/\\/g, '/').toLowerCase();
      const normRoot = workspaceRoot ? norm(workspaceRoot) : undefined;
      while (currentDir) {
        foldersToCheck.push(currentDir);
        if (normRoot && norm(currentDir) === normRoot) break;
        const parentDir = path.dirname(currentDir);
        if (parentDir === currentDir) break;
        currentDir = parentDir;
      }
    }
    // foldersToCheck.push("test1_b");

    const filePath = doc.uri.fsPath;
    let currentDir = path.dirname(filePath);
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    // Normalize for Windows case-insensitivity
    const norm = (p: string) => p.replace(/\\/g, '/').toLowerCase();
    const normRoot = workspaceRoot ? norm(workspaceRoot) : undefined;
    while (currentDir) {
      foldersToCheck.push(currentDir);
      if (normRoot && norm(currentDir) === normRoot) break;
      const parentDir = path.dirname(currentDir);
      if (parentDir === currentDir) break;
      currentDir = parentDir;
    }
    // foldersToCheck.push("test2");
    // Also check workspace root and extension folder
    if (vscode.workspace.workspaceFolders?.[0]?.uri.fsPath) {
      foldersToCheck.push(vscode.workspace.workspaceFolders[0].uri.fsPath);
    }
    // foldersToCheck.push("test3");
    foldersToCheck.push(this.context.extensionUri.fsPath);
    const checkedPaths: string[] = [];
    for (const folder of foldersToCheck) {
      if (!folder) continue;
      const candidate = path.join(folder, 'shrendd');
      checkedPaths.push(candidate);
      if (fs.existsSync(candidate)) {
        shrenddPath = candidate;
        shrenddStart += folder;
        break;
      }
    }
    checkedPaths.push(doc.uri.path.split("/").slice(0, -1).join("/"));
    if (!shrenddPath) {
      return [
        '6 Shrendd executable not found in the file\'s folder or any parent folder up to the workspace root.',
        '',
        'Paths checked:',
        ...checkedPaths.map(p => '  ' + p),
        '',
        'Please ensure \'shrendd\' exists in your project directory.',
        '',
        'See documentation: https://github.com/gtque/shrendd#readme'
      ].join('\n');
    }

    // vscode.window.showInformationMessage(`Shrendd executable found at: ${shrenddPath}`);
    // const command = 'ls'; // `./shrendd --get-property shrendd.render.build.dir`; //'ls -l'; // Replace with your desired shell command
    // const args = ['-l']; //['--get-property', 'shrendd.render.build.dir']; // Add any arguments you need for the command
    // const options = { cwd: shrenddStart }; // Set working directory (optional)

    // const child = exec.spawn(command, args, options);
    // vscode.window.showInformationMessage(`Shrendd spawned`);
    shrenddTargetDir = 'not set';
    let output = '';
    let errorOutput = '';
    // Example: run 'pwd' using the user's configured shell
    const execOptions: any = {};
    if (shellPath) {
      execOptions.shell = shellPath;
    }
    execOptions.cwd = shrenddStart;
    // vscode.window.showInformationMessage(`shell: ${platform}: ${shrenddStart}: ${shellPath}`);

    const { execFile } = require('child_process');

    // const gitBashPath = 'C:\\Program Files\\Git\\bin\\bash.exe'; // Adjust path as needed
    // const command = `echo 'hello, world!'`; // Execute 'git status' silently

    // execFile(shellPath, [command], (error: Error | null, stdout: string, stderr: string) => {
    //     // if (error) {
    //     //     console.error(`execFile error: ${error}`);
    //     //     return;
    //     // }
    //     console.log(`stdout: ${stdout}`);
    //     // console.error(`stderr: ${stderr}`);
    // });

    // const child = cp.spawn('pwd', [], execOptions);
    // child.stdout.on('data', (data: any) => {
    //   output += data.toString();
    // });
    // child.stderr.on('data', (data: any) => {
    //   errorOutput += data.toString();
    // });
    // child.on('close', (code: any) => {
    //   console.log(`Child process exited with code ${code}`);
    // });
    // child.on('error', (err: any) => {
    //   vscode.window.showErrorMessage(`Failed to start command: ${err.message}`);
    // });

    // context.subscriptions.push(disposable);
    // child.stdout.on('data', (data: string) => {
    //     vscode.window.showInformationMessage(`target: ${data}`);
    // });

    // child.stderr.on('data', (data: string) => {
    //     vscode.window.showErrorMessage(`error: ${data}`);
    // });

    // child.on('close', (code: number) => {
    //     if (code === 0) {
    //         vscode.window.showInformationMessage(`Command executed successfully with exit code ${code}`);
    //     } else {
    //         vscode.window.showErrorMessage(`Command exited with error code ${code}`);
    //     }
    // });
    if (this.targetFile === '') {
      const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
      const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
      const thePromise = new Promise((resolve) => {
        exec(`export target="render"; ./shrendd --get-property "shrendd.default.build.dir" > ${shrenddTempFile}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(tempFile)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              console.log('Content of file:', contentString);
              this.targetFile = contentString.trim(); // Set the target file path
              fs.unlinkSync(uri.fsPath);
              resolve(this.targetFile);
            });
          } catch (error) {
              if (error instanceof Error) {
                console.error(`Failed to read file: ${error.message}`);
              } else {
                console.error('Failed to read file: Unknown error');
              }
              resolve(''); // Resolve with empty string on error
          }
          // fs.unlinkSync(uri.fsPath); // Clean up the temp file
          if (error) {
            console.error(`Error executing command: ${stderr || error.message}`);
            // resolve(`Error: ${stderr || error.message}`);
          } else {
            console.log(`Command (export target="render"; ./shrendd --get-property "shrendd.render.render.dir" > ${shrenddTempFile}) executed successfully: ${stdout}`);
            console.log(`Error message just incase: ${stderr}`);
            // resolve(stdout);
          }
        });
      });
      await thePromise;
    }
    
    let rendered = this.targetFile + ":\n"
    return rendered;
  }
}

function getNonce() {
  let text = '';
  const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  for (let i = 0; i < 32; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length));
  }
  return text;
}

function escapeHtml(unsafe: string): string {
  return unsafe.replace(/[&<"'>]/g, function(m) {
    switch (m) {
      case '&': return '&amp;';
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '"': return '&quot;';
      case "'": return '&#039;';
      default: return m;
    }
  });
}
