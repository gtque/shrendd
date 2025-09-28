import * as vscode from 'vscode';
import { ShrenddEditorProvider } from './shrenddEditorProvider';

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    ShrenddEditorProvider.register(context)
  );
}

export function deactivate() {}
