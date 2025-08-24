
import { exec } from 'child_process';
import { resolve } from 'path';
import * as vscode from 'vscode';

export class ShrenddEditorProvider implements vscode.CustomTextEditorProvider {
  
  readonly context: vscode.ExtensionContext;
  
  private targetFile: string = '';
  private shrenddProperties = new Map();

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
    let shrenddModule = "";
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
    shrenddModule = shrenddModule.replaceAll(`${shrenddStart}`, "");
    let shrenddDefaultModuleName = 'dot';
    if (!shrenddModule) {
      console.log("no module detected");
      shrenddModule = ".";
    } else {
      console.log(`Detected shrendd module: ${shrenddModule}`);
      shrenddModule = shrenddModule.replace(/^[/\\]+/, ''); // remove leading slashes
      shrenddDefaultModuleName = shrenddModule;
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

    // const { execFile } = require('child_process');
    let currentTarget = "";
    let myTargets = "";
    if (this.shrenddProperties.has(`${shrenddDefaultModuleName}`)) {
      if (this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has('targets')) {
        myTargets = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get('targets');
      }
    } else {
      console.log(`no properties cached for module ${shrenddDefaultModuleName}, getting them now`);
      // also get shrendd.working.dir to use as part of module calculation, will be be prepended to the path after stripping the plugins working dir.
      this.shrenddProperties.set(`${shrenddDefaultModuleName}`, new Map());
      const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
      const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
      const propertyCommand = `./shrendd --get-property "shrendd.targets" --get-property shrendd.working.dir --module "${shrenddModule}" > ${shrenddTempFile}`;
      const thePromise = new Promise((resolve) => {
        exec(`${propertyCommand}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(tempFile)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              console.log(`${shrenddDefaultModuleName} targets:`, contentString);
              myTargets = contentString.trim().trimStart(); // get the list of targets for the module.
              let targetProperties = myTargets.split("\n");
              myTargets = targetProperties.shift() || '';
              this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set('targets', myTargets);
              for (const templateTarget of targetProperties) {
                let parts = templateTarget.split(": ");
                if (this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(parts[0])) {
                } else {
                  this.shrenddProperties.get(`${shrenddDefaultModuleName}`).set(parts[0], new Map());
                }
                this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(parts[0]).set("shrenddStart", parts[1].trim());
              }
              
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
            console.log(`${propertyCommand}) executed successfully: ${stdout}`);
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
      console.log(`no module explicitely detected, will see if it can be parsed from the file path: ${filePath}`);
      console.log(`shrenddStart: ${shrenddStart}`);
      const actualShrenddStart = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).get("shrenddStart");
      let actualShrenddTemplateDir = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`default-${currentTarget}`).get(`template.dir`).replace(`${actualShrenddStart}`, "");
      if(this.shrenddProperties.get(`${shrenddDefaultModuleName}`).has(`${currentTarget}`) && this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).has(`template.dir`)) {
        actualShrenddTemplateDir = this.shrenddProperties.get(`${shrenddDefaultModuleName}`).get(`${currentTarget}`).get(`template.dir`).replace(`${actualShrenddStart}`, "");
      }
      let moduleDetectionPath = path.dirname(filePath).replace(`${shrenddStart}`, "").replace(/\\/g, "/").replace(`${actualShrenddTemplateDir}`, "");
      console.log(`moduleDetectionPath: ${moduleDetectionPath}`);
      if (!moduleDetectionPath || moduleDetectionPath === '' || moduleDetectionPath === '/') {
        console.log("no module detected, using default module name");
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
    let myTargetFile = "";
    if (this.shrenddProperties.get(`${shrenddModuleName}`) && this.shrenddProperties.get(`${shrenddModuleName}`).has(`${currentTarget}`) && this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).has(`build.dir`)) {
      myTargetFile = this.shrenddProperties.get(`${shrenddModuleName}`).get(`${currentTarget}`).get(`build.dir`);
    }
    if (myTargetFile === '') {
      console.log('no build dir defined yet, getting it from shrendd');
      const tempFile = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
      const shrenddTempFile = "/" + path.normalize(tempFile).replace(/:/g, "").replace(/\\/g, "/");
      const target = currentTarget;
      const propertyCommand = `export target="${target}"; ./shrendd --get-property "shrendd.${target}.build.dir" --get-property "shrendd.default.build.dir" --module "${shrenddModule}" > ${shrenddTempFile}`;
      const thePromiseOfProperties = new Promise((resolve) => {
        exec(`${propertyCommand}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(tempFile)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              console.log('Content of file:', contentString);
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
                console.log(`parsing default build dir: ${currentBuildDir}`);
                const finalTarget = currentBuildDir.split(": ")[0].trim();
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
                console.log(`Using targeted build dir: ${myTargetFile}`);
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
    const propertyCommand = `./shrendd -b --module "${shrenddModule}" > ${shrenddTempFile}`;
    const thePromiseOfTheBuild = new Promise((resolve) => {
        exec(`${propertyCommand}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
          const uri = vscode.Uri.file(moduleDetectionPath)
          try {
            vscode.workspace.fs.readFile(uri).then((contentBytes: Uint8Array) => {
              const contentString = Buffer.from(contentBytes).toString('utf8'); // Convert bytes to string
              console.log('Content of file:', contentString);
              myTargetFile = contentString.trim().trimStart().trimEnd(); // Set the target file path
              fs.unlinkSync(uri.fsPath);
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
    let rendered = moduleDetectionPath + ":\n" + await thePromiseOfTheBuild;
    // .replace(/^[/\\]+/, '');
    return rendered;
  }

  private async getTemplateDirs(myTargets: string, shrenddModule: string, shrenddDefaultModuleName: string, execOptions: any) {
    const tmp = require('os').tmpdir();
    const fs = require('fs');
    const path = require('path');
    const cp = require('child_process');

    let currentTargets = myTargets.split(" ");
    let defaultTargets = "--get-property shrendd.default.template.dir";
    for (const possibleTarget of currentTargets) {
      defaultTargets += ` --get-property shrendd.${possibleTarget}.template.dir`;
    }
    console.log(`defaultTargets: ${defaultTargets}`);
    const tempFile2 = path.join(tmp, `shrendd-preview-${Date.now()}.srd`);
    const shrenddTempFile2 = "/" + path.normalize(tempFile2).replace(/:/g, "").replace(/\\/g, "/");
    const propertyCommand2 = `./shrendd ${defaultTargets} --module "${shrenddModule}" > ${shrenddTempFile2}`;
    const thePromiseOfTemplateProperties = new Promise((resolve) => {
      exec(`${propertyCommand2}`, execOptions, (error: Error | null, stdout: any, stderr: any) => {
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
          console.log(`${propertyCommand2}) executed successfully: ${stdout}`);
          // resolve(stdout);
        }
      });
    });
    await thePromiseOfTemplateProperties;
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

