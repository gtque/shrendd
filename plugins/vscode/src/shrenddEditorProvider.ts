
import * as vscode from 'vscode';

export class ShrenddEditorProvider implements vscode.CustomTextEditorProvider {
  public static register(context: vscode.ExtensionContext): vscode.Disposable {
    const provider = new ShrenddEditorProvider(context);
    return vscode.window.registerCustomEditorProvider(
      ShrenddEditorProvider.viewType,
      provider
    );
  }

  private static readonly viewType = 'shrendd.templateEditor';

  constructor(private readonly context: vscode.ExtensionContext) {}

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
          const processed = await this.processTemplate(document);
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

  private async processTemplate(doc: vscode.TextDocument): Promise<string> {
    // Run 'shrendd -b' on the current file and return its output
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const path = require('path');
    const { exec } = require('child_process');
    // Find shrendd executable in file's folder or parent folder

    let shrenddPath: string | null = null;
    let foldersToCheck: string[] = [];
    if (vscode.window.activeTextEditor) {
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
    // Also check workspace root and extension folder
    if (vscode.workspace.workspaceFolders?.[0]?.uri.fsPath) {
      foldersToCheck.push(vscode.workspace.workspaceFolders[0].uri.fsPath);
    }
  foldersToCheck.push(this.context.extensionUri.fsPath);
  const checkedPaths: string[] = [];
    for (const folder of foldersToCheck) {
      if (!folder) continue;
      const candidate = path.join(folder, 'shrendd');
      checkedPaths.push(candidate);
      if (fs.existsSync(candidate)) {
        shrenddPath = candidate;
        break;
      }
    }
    checkedPaths.push(doc.uri.path.split("/").slice(0, -1).join("/"));
    if (!shrenddPath) {
      return [
        '3 Shrendd executable not found in the file\'s folder or any parent folder up to the workspace root.',
        '',
        'Paths checked:',
        ...checkedPaths.map(p => '  ' + p),
        '',
        'Please ensure \'shrendd\' exists in your project directory.',
        '',
        'See documentation: https://github.com/gtque/shrendd#readme'
      ].join('\n');
    }

    // Write the text to a temp file
    const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
    fs.writeFileSync(tempFile, doc.getText(), 'utf8');
    return new Promise((resolve) => {
      exec(`"${shrenddPath}" -b "${tempFile}"`, { cwd: path.dirname(tempFile) }, (error: Error | null, stdout: string, stderr: string) => {
        fs.unlinkSync(tempFile);
        if (error) {
          resolve(`Error: ${stderr || error.message}`);
        } else {
          resolve(stdout);
        }
      });
    });
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
