import * as monaco from 'monaco-editor';

// Declare acquireVsCodeApi for TypeScript to avoid "Cannot find name" error
declare function acquireVsCodeApi(): { postMessage: (msg: any) => void };

const vscode = acquireVsCodeApi();
window.addEventListener('DOMContentLoaded', () => {
  const source = document.getElementById('source') as HTMLDivElement;
  const processed = document.getElementById('processed') as HTMLPreElement;
  let initialContent = (window as any).initialShrenddContent;
  console.log("dom content loaded, initializing editor:", initialContent);
  let editor = monaco.editor.create(source, {
    value: (window as any).initialShrenddContent || '',
    language: 'shell',
    automaticLayout: true,
  });
  let suppressUpdate = false;

  editor.onDidChangeModelContent(() => {
    suppressUpdate = true;
    vscode.postMessage({ type: 'edit', text: editor.getValue() });
  });

  window.addEventListener('message', event => {
    const message = event.data;
    if (message.type === 'update') {
      if (!suppressUpdate && editor.getValue() !== message.text) {
        editor.setValue(message.text);
      }
    } else if (message.type === 'processed') {
      processed.textContent = message.text;
    }
  });

  editor.onDidChangeModelContent(() => {
    vscode.postMessage({ type: 'edit', text: editor.getValue() });
  });

  (document.getElementById('tab-source') as HTMLButtonElement).onclick = () => {
    source.style.display = 'block';
    processed.style.display = 'none';
  };
  (document.getElementById('tab-processed') as HTMLButtonElement).onclick = () => {
    source.style.display = 'none';
    processed.style.display = 'block';
    vscode.postMessage({ type: 'process' });
  };
});