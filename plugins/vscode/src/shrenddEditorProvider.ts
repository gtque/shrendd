
import { exec } from 'child_process';
import { resolve } from 'path';
import * as vscode from 'vscode';

// Import specific workers if needed, e.g., for language features
// import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker';

export class ShrenddEditorProvider implements vscode.CustomTextEditorProvider {
  
  readonly context: vscode.ExtensionContext;
  
  private shrenddLocal = null;
  private shrenddProperties = new Map();
  private documentShrendder = new Map();
  private forceShrendd = false;

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
      enableScripts: true,
      localResourceRoots: [
        vscode.Uri.file(require('path').join(this.context.extensionUri.fsPath, 'media'))
      ]
    };

    webviewPanel.webview.html = this.getHtmlForWebview(document, webviewPanel.webview, this.context);
    const panelTitle = webviewPanel.title;
    if (!this.documentShrendder.has(panelTitle)) {
      this.documentShrendder.set(panelTitle, new Map());
    }
    this.documentShrendder.get(panelTitle).set("isDisposed", false);
    this.documentShrendder.get(panelTitle).set("panel", webviewPanel);
    this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
        type: 'set-force',
        text: this.forceShrendd,
    });
    if (this.documentShrendder.get(panelTitle).has("isRunning")) {
      this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
          type: 'set-status',
          text: this.documentShrendder.get(panelTitle).get("isRunning"),
      });
    }
    // Listen for document changes
    const changeDocumentSubscription = vscode.workspace.onDidChangeTextDocument(e => {
      if (e.document.uri.toString() === document.uri.toString()) {
        console.log("document change detected, updating webview");
        webviewPanel.webview.postMessage({
          type: 'update',
          text: e.document.getText()
        });
      }
    });

    webviewPanel.onDidDispose(() => {
      changeDocumentSubscription.dispose();
      this.documentShrendder.get(panelTitle).set("isDisposed", true);
    });

    // Handle messages from the webview
    webviewPanel.webview.onDidReceiveMessage(async message => {
      switch (message.type) {
        case 'edit':
          this.updateTextDocument(panelTitle, document, message.text);
          if (this.documentShrendder.get(panelTitle).has("isRunning")) {
            this.updateStatusWebview(panelTitle, webviewPanel, this.documentShrendder.get(panelTitle).get("isRunning"));
          }
          break;
        case 'process':
          // console.log(`panel: ${webviewPanel.title}`);
          if (!this.documentShrendder.get(panelTitle).has("isRunning") || this.documentShrendder.get(panelTitle).get("isRunning") === "shrenddered") {
            console.log("shrendding the document...");
            this.documentShrendder.get(panelTitle).set("isRunning", "shrendding...");
            try {
              const processed = await this.processTemplate(panelTitle, webviewPanel, document, this.context);
              if (!this.documentShrendder.get(panelTitle).get("isDisposed")) {
                this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({ type: 'processed', text: processed });
              }
            } catch (error) {
              console.log("error updating template, please try loading the preview again.");
              if (!this.documentShrendder.get(panelTitle).get("isDisposed")) {
                this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({ type: 'processed', text: "error building template, please try loading the preview again." });
              }
            }
            this.documentShrendder.get(panelTitle).set("isRunning", "shrenddered");
          } else {
            this.updateStatusWebview(panelTitle, webviewPanel, this.documentShrendder.get(panelTitle).get("isRunning"));
          }
          break;
        case "force-true":
          console.log("set force shrendd to true");
          this.forceShrendd = true;
          break;
        case "force-false":
          console.log("set force shrendd to false");
          this.forceShrendd = false;
          break;
        case "refocus":
          this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
              type: 'set-force',
              text: this.forceShrendd,
          });
          if (this.documentShrendder.get(panelTitle).has("isRunning")) {
            this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
                type: 'set-status',
                text: this.documentShrendder.get(panelTitle).get("isRunning"),
            });
          }
          break;
      }
    });

    webviewPanel.onDidChangeViewState(e => {
      if (e.webviewPanel.active) {
          // The webview has been selected/focused.
          // You can perform an action here, for example:
          console.log(`MyCustomEditor: Tab for ${document.fileName} is now active.`);

          // You might need to update the webview with fresh content,
          // in case it was hidden and re-rendered.
          this.updateWebview(panelTitle, webviewPanel, document);
      }
    });
  }

  private getHtmlForWebview(
  document: vscode.TextDocument,
  webview: vscode.Webview,
  context: vscode.ExtensionContext
): string {
  const nonce = getNonce();
  const bundleUri = webview.asWebviewUri(
    vscode.Uri.file(
      require('path').join(context.extensionUri.fsPath, 'media', 'bundled', 'bundle.js')
    )
  );
  
  const initialValue = document.getText().replace(/'/g, "\\'").replace(/\n/g, '\\n').replace(/\r/g, '\\r');
  // console.log("Initial value for webview:", JSON.stringify(document.getText()));
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${nonce}' vscode-webview: 'unsafe-eval'; style-src 'unsafe-inline' vscode-webview:; font-src vscode-webview: data:; worker-src blob: vscode-webview:; child-src blob:; img-src data: vscode-webview:;">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Shrendd Template Editor</title>
  <style>
    #meditor-container { width: 100%; height: 90vh; }
    #source { width: 100%; height: 100%; }
    #processed { width: 100%; height: 100%; display: none; white-space: pre; }
    #select-render { width: 150px; }
    .label-status {  border: none; border-left: 3px solid #0411ff; font-weight: bold; padding-left: 3px; }
    .tab-status { width: 175px; }
    .tab-btn { margin-right: 8px; }
    .tab-btn.selected { background-color: #0411ff; }
    body {
      font-family: var(--vscode-editor-font-family); /* Example: using a VS Code CSS variable */
      font-size: var(--vscode-editor-font-size);
      color: var(--vscode-editor-foreground);
      background-color: var(--vscode-editor-background);
    }
  </style>
</head>
<body>
  <script nonce="${nonce}">
    console.log("trying to initialize shrendd content");
    window.initialShrenddContent = '${initialValue}';
  </script>
  <div>
    <button class="tab-btn selected" id="tab-source">Source</button>
    <button class="tab-btn" id="tab-processed">Preview</button>
    <select class="tab-btn" id="select-render">
      <option value="!build!">pre-rendered</option>
    </select>
    <input class="tab-btn" id="check-force" type="checkbox">Force Refresh</input>
    <label class="label-status" for="test-status">Status:</label>
    <input class="tab-status" id="text-status" type="text" readonly></input>
  </div>
  <div id="meditor-container">
    <div id="source"></div>
    <pre id="processed"></pre>
  </div>
  <script nonce="${nonce}" src="${bundleUri}"></script>
</body>
</html>`;
}

  private updateWebview(panelTitle: string, webviewPanel: vscode.WebviewPanel, document: vscode.TextDocument) {
    // Post the latest document content to the webview
    if (!this.documentShrendder.get(panelTitle).get("isDisposed")) {
      this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
          type: 'update',
          text: document.getText(),
      });
    }
  }

  private updateStatusWebview(panelTitle: string, webviewPanel: vscode.WebviewPanel, message: string) {
    // Post the latest document content to the webview
    if (!this.documentShrendder.get(panelTitle).get("isDisposed")) {
      this.documentShrendder.get(panelTitle).set("isRunning", message);
      this.documentShrendder.get(panelTitle).get("panel").webview.postMessage({
          type: 'set-status',
          text: message,
      });
    }
  }

  private updateTextDocument(panelTitle: string, document: vscode.TextDocument, text: string) {
    if (!this.documentShrendder.get(panelTitle).get("isDisposed")) {
      const edit = new vscode.WorkspaceEdit();
      const fullRange = new vscode.Range(
        document.positionAt(0),
        document.positionAt(document.getText().length)
      );  
      edit.replace(document.uri, fullRange, text);
      vscode.workspace.applyEdit(edit);
    }
  }
  
  private async waitUntilCondition(
    conditionFunction: () => boolean | Promise<boolean>,
    intervalMs: number = 100,
    timeoutMs: number = Infinity
  ): Promise<void> {
    const startTime = Date.now();

    while (true) {
      const isConditionMet = await Promise.resolve(conditionFunction());

      if (isConditionMet) {
        return; // Condition is true, exit the loop
      }

      if (Date.now() - startTime >= timeoutMs) {
        throw new Error("Timeout waiting for condition to be true.");
      }

      await new Promise(resolve => setTimeout(resolve, intervalMs)); // Wait for the specified interval
    }
  }

  private async processTemplate(panelTitle: string, webviewPanel: vscode.WebviewPanel, doc: vscode.TextDocument, context: vscode.ExtensionContext): Promise<string> {
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const path = require('path');
    
    const forcedAtStart = this.forceShrendd;

    if (!this.shrenddLocal) {
      this.shrenddLocal = await this.loadShrenddLocal();
    }
    
    // Get the user's configured shell from VS Code settings
    const shellPath = this.detectTerminal();
    
    const filePath = doc.uri.fsPath;
    // let shrenddTargetDir: string | null = null;

    const shrenddInfo = this.findShrenddStart(filePath);

    let shrenddModule = shrenddInfo.get("shrenddModule").replaceAll(`${shrenddInfo.get("shrenddStart")}`, "");
    let shrenddDefaultModuleName = 'dot';
    if (!shrenddModule) {
      console.log("no module detected");
      shrenddModule = ".";
    } else {
      console.log(`Detected shrendd module: ${shrenddModule}`);
      shrenddModule = shrenddModule.replace(/^[/\\]+/, ''); // remove leading slashes
      shrenddDefaultModuleName = shrenddModule;
    }

    this.updateStatusWebview(panelTitle, webviewPanel, `initially detected module: ${shrenddModule}`);

    shrenddInfo.get("checkedPaths").push(doc.uri.path.split("/").slice(0, -1).join("/"));
    if (!shrenddInfo.get("shrenddStart")) {
      return [
        'Shrendd executable not found in the file\'s folder or any parent folder up to the workspace root.',
        '',
        'Paths checked:',
        ...shrenddInfo.get("checkedPaths").map((p: any) => '  ' + p),
        '',
        'Please ensure \'shrendd\' exists in your project directory.',
        '',
        'See documentation: https://github.com/gtque/shrendd#readme'
      ].join('\n');
    }

    // shrenddTargetDir = 'not set';
    // let output = '';
    // let errorOutput = '';
    // Example: run 'pwd' using the user's configured shell
    const execOptions: any = {};
    if (shellPath) {
      execOptions.shell = shellPath;
    }
    execOptions.cwd = shrenddInfo.get("shrenddStart");
    // vscode.window.showInformationMessage(`shell: ${platform}: ${shrenddStart}: ${shellPath}`);

    // const { execFile } = require('child_process');
    let currentTarget = "";
    let myTargets = "";
    if (this.shrenddProperties.has(`${shrenddDefaultModuleName}`)) {
      if (this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has('targets')) {
        myTargets = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get('targets');
      } else {
        try {
          console.log(`waiting for condition: ${shrenddDefaultModuleName} initialized.`);
          this.updateStatusWebview(panelTitle, webviewPanel, `${shrenddDefaultModuleName} initializing`);
          await this.waitUntilCondition(() => this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has('targeted') && this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get('targeted'), 500, 5*60000); // Check every 500ms, with a 5-second timeout
          console.log("Condition met: Data is ready for processing.");
          // Proceed with processing the data
        } catch (error: any) {
          console.error(error.message);
        }
        if (this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has('targets')) {
          myTargets = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get('targets');
        }
      }
    } else {
      this.updateStatusWebview(panelTitle, webviewPanel, `initializing module properties`);
      // console.log(`no properties cached for module ${shrenddDefaultModuleName}, getting them now`);
      // also get shrendd.working.dir to use as part of module calculation, will be be prepended to the path after stripping the plugins working dir.
      this.shrenddProperties.set(`${shrenddDefaultModuleName}`, new Map());
      const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
      const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
      const propertyCommand = `./shrendd --get-property "shrendd.targets" --get-property shrendd.working.dir --module "${shrenddModule}" -verbose > ${shrenddTempFile}`;
      const thePromise = new Promise((resolve) => {
        exec(`${propertyCommand}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(tempFile)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              // console.log(`${shrenddDefaultModuleName} targets:`, contentString);
              myTargets = contentString.trim().trimStart(); // get the list of targets for the module.
              let targetProperties = myTargets.split("\n");
              myTargets = targetProperties.shift() || '';
              for (const templateTarget of targetProperties) {
                let parts = templateTarget.split(": ");
                if (this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(parts[0])) {
                } else {
                  this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set(parts[0], new Map());
                }
                this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(parts[0]).set("shrenddStart", parts[1].trim());
              }
              this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set('targets', myTargets);
              fs.unlinkSync(uri.fsPath);
              resolve(myTargets);
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
            // console.log(`${propertyCommand}) executed successfully: ${stdout}`);
            // resolve(stdout);
          }
        });
      });
      await thePromise;
      let didGet = this.getTemplateDirs(myTargets, shrenddModule, shrenddDefaultModuleName, execOptions);
      await didGet;
    }
    if (myTargets != null && myTargets.trim().length > 0) {
      let currentTargets = myTargets.split(" ");
      console.log(`checking file path: ${filePath}`);
      for (const possibleTarget of currentTargets) {
        console.log(`checking target: ${possibleTarget}`);
        if (filePath.includes(possibleTarget)) {
          currentTarget = possibleTarget;
          break;
        }
      }
    }
    if (currentTarget === "") {
      console.error(`No target found for file ${filePath} in module ${shrenddDefaultModuleName}. This file does not appear to be in a valid shrendd project. Make sure the file is in a proper module and target directory. If you are using custom directories for the targets, please make sure the path includes the target name does not include names that match other targets defined in your project: ${myTargets}`);
      return `No target found for file ${filePath} in module ${shrenddDefaultModuleName}. This file does not appear to be in a valid shrendd project. Please see error log for more information.`;
    }
    let shrenddModuleName = shrenddDefaultModuleName;
    if (shrenddModuleName === "dot") {
      // console.log(`no module explicitely detected, will see if it can be parsed from the file path: ${filePath}`);
      // console.log(`shrenddStart: ${shrenddStart}`);
      const actualShrenddStart = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).get("shrenddStart");
      let actualShrenddTemplateDir = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`default-${currentTarget}`).get(`template.dir`).replace(`${actualShrenddStart}`, "");
      if(this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(`${currentTarget}`) && this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).has(`template.dir`)) {
        actualShrenddTemplateDir = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).get(`template.dir`).replace(`${actualShrenddStart}`, "");
      }
      let moduleDetectionPath = path.dirname(filePath).replace(`${shrenddInfo.get("shrenddStart")}`, "").replace(/\\/g, "/").replace(`${actualShrenddTemplateDir}`, "");
      // console.log(`moduleDetectionPath: ${moduleDetectionPath}`);
      if (!moduleDetectionPath || moduleDetectionPath === '' || moduleDetectionPath === '/') {
        console.log("no module detected, using default module name");
        this.updateStatusWebview(panelTitle, webviewPanel, `using default module`);
      } else {
        shrenddModule = moduleDetectionPath.replace(/^[/\\]+/, ''); // remove leading slashes
        console.log(`Detected shrendd module from file path: ${shrenddModule}`);
        shrenddModuleName = shrenddModule;
        if (!this.shrenddProperties.has(`${shrenddModuleName}`)) {
          console.log(`no properties cached for module ${shrenddModuleName}, getting them now`);
          let didGet = this.getTemplateDirs(myTargets, shrenddModule, shrenddModuleName, execOptions);
          await didGet;
        }
      }
    } else {
      console.log("a defined module has already been detected, assuming that is the module for this file");
    }
    this.updateStatusWebview(panelTitle, webviewPanel, `module: ${shrenddModuleName}`);
    let myTargetFile = "";
    if (this.shrenddProperties.get(`${shrenddModuleName}`).has('isRunning') && this.shrenddProperties.get(`${shrenddModuleName}`).get('isRunning')) {
        try {
          console.log(`waiting for condition: ${shrenddModuleName} to not be running`);
          this.updateStatusWebview(panelTitle, webviewPanel, `${shrenddModuleName} in progress`);
          await this.waitUntilCondition(() => !this.shrenddProperties.get(`${shrenddModuleName}`).get('isRunning'), 500, 15*60000); // Check every 500ms, with a 5-second timeout
          console.log("Condition met: Data is ready for processing.");
          // Proceed with processing the data
        } catch (error: any) {
          console.error(error.message);
        }
    }
    this.shrenddProperties.get(`${shrenddModuleName}`).set('isRunning', true);
    if (this.shrenddProperties.get(`${shrenddModuleName}`) && this.shrenddProperties.get(`${shrenddModuleName}`).has(`${currentTarget}`) && this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).has(`build.dir`)) {
      myTargetFile = this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).get(`build.dir`);
    }
    if (myTargetFile === '') {
      // console.log('no build dir defined yet, getting it from shrendd');
      this.updateStatusWebview(panelTitle, webviewPanel, `detecting build directory`);
      const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
      const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
      const target = currentTarget;
      const propertyCommand = `./shrendd --target "${target}" --get-property "shrendd.${target}.build.dir" --get-property "shrendd.default.build.dir" --module "${shrenddModule}" > ${shrenddTempFile}`;
      const thePromiseOfProperties = new Promise((resolve) => {
        exec(`${propertyCommand}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(tempFile)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              console.log('build dirs:', contentString);
              myTargetFile = contentString.trim().trimStart().trimEnd(); // Set the target file path
              let targetProperties = myTargetFile.split("<<<>>>");
              let targetedBuildDir = targetProperties.shift() || '';
              let targetedBuildDirs = targetedBuildDir.trimStart().trimEnd().split("\n");
              let defaultBuildDir = targetProperties.shift() || '';
              let defaultBuildDirs = defaultBuildDir.trimStart().trimEnd().split("\n");
              if (!this.shrenddProperties.has(`${shrenddModuleName}`)) {
                this.shrenddProperties.set(`${shrenddModuleName}`, new Map());
              }
              for (const currentBuildDir of defaultBuildDirs) {
                console.log(`parsing default build dir: ${currentBuildDir}`);
                const finalTarget = currentBuildDir.split(": ")[0].trim();
                const finalDir = currentBuildDir.split(": ")[1].trim();
                if (!this.shrenddProperties.get(`${shrenddModuleName}`).has(`default-${finalTarget}`)) {
                  this.shrenddProperties.get(`${shrenddModuleName}`).set(`default-${finalTarget}`, new Map());
                }
                this.shrenddProperties.get(`${shrenddModuleName}`).get(`default-${finalTarget}`).set('build.dir', finalDir);
              }
              for (const currentBuildDir of targetedBuildDirs) {
                const finalTarget = currentBuildDir.split(": ")[0].trim();
                console.log(`parsing target (${finalTarget}) build dir: ${currentBuildDir}`);
                const finalDir = currentBuildDir.split(": ")[1].trim();
                if (!this.shrenddProperties.get(`${shrenddModuleName}`).has(`${finalTarget}`)) {
                  this.shrenddProperties.get(`${shrenddModuleName}`).set(`${finalTarget}`, new Map());
                }
                this.shrenddProperties.get(`${shrenddModuleName}`).get(`${finalTarget}`).set('build.dir', finalDir);
              }
              defaultBuildDir = this.shrenddProperties.get(`${shrenddModuleName}`).get(`default-${currentTarget}`).get('build.dir');
              targetedBuildDir = this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).get('build.dir');
              console.log("defaultBuildDir: ", defaultBuildDir);
              myTargetFile = defaultBuildDir;
              if (`${targetedBuildDir}` !== '' && `${targetedBuildDir}` !== 'null') {
                myTargetFile = targetedBuildDir;
                console.log(`Using targeted (${currentTarget}) build dir: ${myTargetFile}`);
              }
              this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).set('build.dir', myTargetFile);
              fs.unlinkSync(uri.fsPath);
              resolve(myTargetFile);
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
            console.log(`${propertyCommand}) executed successfully: ${stdout}`);
            // resolve(stdout);
          }
        });
      });
      await thePromiseOfProperties;
    }
    let moduleTemplateDir = this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).get('template.dir');
    let moduleBuildDir = this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).get('build.dir');
    let moduleDetectionPath = "/" + path.normalize(filePath).replace(/:/g, "").replace(/\\/g, "/");
    console.log(`module: ${shrenddModuleName} -> target: ${currentTarget}`);
    console.log(`original file path: ${path.normalize(filePath)}`);
    console.log(`normalized file path: ${moduleDetectionPath}`);
    console.log(`template dir: ${moduleTemplateDir}`);
    console.log(`build dir: ${moduleBuildDir}`);
    moduleDetectionPath = moduleDetectionPath.replace(`${moduleTemplateDir}`, `${moduleBuildDir}`).replace(".srd", "");
    if (process.platform === 'win32') {
      // Replace all forward slashes with backslashes.
      // The 'g' flag ensures all occurrences are replaced, not just the first.
      // return linuxPath.replace(/\//g, '\\');
      console.log("converting to Windows path: ", moduleDetectionPath);
      moduleDetectionPath = moduleDetectionPath.replace(/^[/\\]+/, '').replace(/\//g, "\\").replace(/^([a-zA-Z])\\/, '$1:\\'); // Ensure Windows paths start with a drive letter
    } else {
      // If not Windows (e.g., Linux, macOS), the path is already in the correct format.
      // return linuxPath;
      console.log("not Windows, keeping path as is");
    }
    console.log(`final moduleTemplateDir: ${moduleDetectionPath}`);
    const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
    const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
    const propertyCommand = `./shrendd -b --module "${shrenddModule}" -offline > ${shrenddTempFile}`;
    const ouri = vscode.Uri.file(filePath);
    const uri = vscode.Uri.file(moduleDetectionPath);
    let mustBuild = true;
    try {
      let fileTime = (await vscode.workspace.fs.stat(ouri)).mtime;
      let builtTime = (await vscode.workspace.fs.stat(uri)).mtime;
      if ( fileTime < builtTime ) {
        console.log("no change detected, no need to build.")
        this.updateStatusWebview(panelTitle, webviewPanel, `no changes detected`);
        mustBuild = false;
      } else {
        console.log(`change detected, must rebuild: ${filePath} < ${builtTime}`)
        this.updateStatusWebview(panelTitle, webviewPanel, `changes detected, rebuilding`);
      }
    } catch (error) {
      this.updateStatusWebview(panelTitle, webviewPanel, `no file, rebuilding`);
      console.log("some file did not exist, assuming it is the compiled file, as it would be hard to get here if it was the template file. will run the build.");
    }
    let rendered = moduleDetectionPath + ":\n";
    if ( forcedAtStart || mustBuild ) {
      this.updateStatusWebview(panelTitle, webviewPanel, `shrendd building`);
      const thePromiseOfTheBuild = (cmd: string) => new Promise((resolve) => {
        exec(`${cmd}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              // console.log('Content of file:', contentString);
              myTargetFile = contentString.trim().trimStart().trimEnd(); // Set the target file path
              // fs.unlinkSync(uri.fsPath);
              resolve(myTargetFile);
            });
          } catch (error) {
              if (error instanceof Error) {
                console.error(`Failed to read file: ${error.message}`);
              } else {
                console.error('Failed to read file: Unknown error');
              }
              resolve(`error building, please run './shrendd -b --module ${shrenddModule}' for more information`); // Resolve with empty string on error
          }
        });
      });
      rendered += await thePromiseOfTheBuild(`${propertyCommand}`);
      this.updateStatusWebview(panelTitle, webviewPanel, `template built`);
    } else {
      const thePromiseOfTheBuild = new Promise((resolve) => {
        try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              // console.log('Content of file:', contentString);
              myTargetFile = contentString.trim().trimStart().trimEnd(); // Set the target file path
              // fs.unlinkSync(uri.fsPath);
              resolve(myTargetFile);
            });
          } catch (error) {
              if (error instanceof Error) {
                console.error(`Failed to read file: ${error.message}`);
              } else {
                console.error('Failed to read file: Unknown error');
              }
              resolve(`error building, please run './shrendd -b --module ${shrenddModule}' for more information`); // Resolve with empty string on error
          }
        });
        rendered += await thePromiseOfTheBuild
        this.updateStatusWebview(panelTitle, webviewPanel, `template unchanged`);
          // rendered += myTargetFile
    }
    this.shrenddProperties.get(`${shrenddModuleName}`).set('isRunning', false);
    // .replace(/^[/\\]+/, '');
    return rendered;
  }

  private async loadShrenddLocal() {
    const fs = require('fs');
    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    try {
      let directory = vscode.Uri.file(`${workspaceRoot}/.shrendd`);
      await vscode.workspace.fs.createDirectory(directory);
      console.log(`Directory created or already exists: ${directory.fsPath}`);
    } catch (error: any) {
      vscode.window.showErrorMessage(`Failed to create directory: ${error.message}`);
    }
    try {
      let directory = vscode.Uri.file(`${workspaceRoot}/.shrendd/.vscode`);
      await vscode.workspace.fs.createDirectory(directory);
      console.log(`Directory created or already exists: ${directory.fsPath}`);
    } catch (error: any) {
      vscode.window.showErrorMessage(`Failed to create directory: ${error.message}`);
    }
    let shrenddProperties = vscode.Uri.file(`${workspaceRoot}/.shrendd/.vscode/shrendd.json`);
    try {
      (await vscode.workspace.fs.stat(shrenddProperties)).mtime;
    } catch (error: any) {
        console.log("no local shrendd.json found, stubbing a basic one.");
        try {
          fs.writeFileSync(shrenddProperties.fsPath, "{\"shrendd\":\"vscode\"}");
        } catch (error2: any) {
          console.log(`problem stubbing shrendd.json ${error2.message}`);
          vscode.window.showErrorMessage(`Failed to create file: ${error instanceof Error ? error.message : String(error)}`);
        }
    }
    const shrenddLoco = JSON.parse(fs.readFileSync(`${workspaceRoot}/.shrendd/.vscode/shrendd.json`, 'utf-8'))

    // type PersonalInfo = typeof personalInfoData;

    // const myInfo: PersonalInfo = personalInfoData;
    console.log(shrenddLoco.sprinkle.frosting);
    return shrenddLoco;
  }

  private detectTerminal() {
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
      return "";
    }
    return shellPath;
  }

  private findShrenddStart(filePath: string) {
    const fs = require('fs');
    const path = require('path');

    let shrenddPath: string | null = null;
    let shrenddStart = '';
    let shrenddModule = "";
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
      const moduleCandidate = path.join(folder, 'shrendd.yml');
      checkedPaths.push(candidate);
      //module in this case is only important
      if (fs.existsSync(moduleCandidate)) {
        if (!shrenddModule) {
          shrenddModule = folder;
        }
      }
      if (fs.existsSync(candidate)) {
        shrenddPath = candidate;
        shrenddStart += folder;
        break;
      }
    }
    let shrenddInfo = new Map();
    shrenddInfo.set("shrenddPath", shrenddPath);
    shrenddInfo.set("shrenddStart", shrenddStart);
    shrenddInfo.set("shrenddModule", shrenddModule);
    shrenddInfo.set("checkedPaths", checkedPaths);
    return shrenddInfo;
  }

  private async getTemplateDirs(myTargets: string, shrenddModule: string, shrenddDefaultModuleName: string, execOptions: any) {
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const path = require('path');
    // const cp = require('child_process');

    console.log(`getting template dirs for module ${shrenddDefaultModuleName} with targets: ${myTargets}`);
    let currentTargets = myTargets.split(" ");
    let defaultTargets = "--get-property shrendd.default.template.dir";
    for (const possibleTarget of currentTargets) {
      console.log("adding target:", possibleTarget);
      if (`${possibleTarget}` !== "." ) {
        console.log("target added");
        defaultTargets += ` --get-property shrendd.${possibleTarget}.template.dir`;
      } else {
        console.log("appears to be an empty target, nothing to add.")
      }
    }
    console.log(`defaultTargets: ${defaultTargets}`);
    const tempFile2 = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
    const shrenddTempFile2 = "/" + path.normalize(tempFile2).replace(/:/g, "").replace(/\\/g, "/");
    const propertyCommand2 = `./shrendd ${defaultTargets} --module "${shrenddModule}" > ${shrenddTempFile2}`;
    const thePromiseOfTemplateProperties = (cmd: string) => new Promise((resolve) => {
      exec(`${cmd}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
        const uri = vscode.Uri.file(tempFile2)
        try {
          vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
            const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
            console.log(`${shrenddDefaultModuleName} templateDirs:\n`, contentString);
            defaultTargets = contentString.trim(); // get the list of targets for the module.
            let targetProperties = defaultTargets.split("<<<>>>");
            console.log("length of targetProperties: ", targetProperties.length);
            // let defaultProperty = targetProperties.shift()?.trim() || '';
            // console.log(`defaultProperty: ${defaultProperty}`);
            let onDefault = "default-";
            for (const targetProperty of targetProperties) {
              console.log(`parsing targetProperty: ${targetProperty}`);
              let propertyList = targetProperty.trimStart().split("\n");
              console.log("length of propertyList: ", propertyList.length);
              for (const possibleTarget of currentTargets) {
                let dirValue = (propertyList.shift()?.trim() || '').replace(`${possibleTarget}:`,"").trim()
                if (dirValue === '' || dirValue === 'null' ) {
                  console.log(`no template dir defined for target ${onDefault}${possibleTarget}, skipping`);
                  continue; // skip if no template dir is defined
                }
                console.log(`setting template.dir for target ${onDefault}${possibleTarget} to ${dirValue}`);
                if (!this.shrenddProperties.has(`${shrenddDefaultModuleName}`)) {
                  this.shrenddProperties.set(`${shrenddDefaultModuleName}`, new Map());
                }
                if (!this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(`${onDefault}${possibleTarget}`)) {
                  this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set(`${onDefault}${possibleTarget}`, new Map());
                }
                this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${onDefault}${possibleTarget}`).set('template.dir', dirValue);
              }
              onDefault = "";
            }
            for (const possibleTarget of currentTargets) {
              if (!this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(`${possibleTarget}`)) {
                this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set(`${possibleTarget}`, new Map());
              }
              if (!this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${possibleTarget}`).has('template.dir') 
                || this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${possibleTarget}`).get('template.dir') === null 
                || this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${possibleTarget}`).get('template.dir') === "null") {
                console.log(`no template dir dedfined for ${possibleTarget}, setting to default dir: ${this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`default-${possibleTarget}`).get('template.dir')}`);
                this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${possibleTarget}`).set('template.dir', this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`default-${possibleTarget}`).get('template.dir'));
              }
            }
            this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set("targeted", true);
            fs.unlinkSync(uri.fsPath);
            resolve(defaultTargets);
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
          console.log(`${cmd}) executed successfully: ${stdout}`);
          // resolve(stdout);
        }
      });
    });
    await thePromiseOfTemplateProperties(`${propertyCommand2}`);
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

