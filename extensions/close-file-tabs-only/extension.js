const vscode = require("vscode");

const AGENT_URI_SCHEMES = new Set([
  "composer",
  "backgroundcomposer",
  "backgroundcomposerpeek",
  "aichat",
  "chat",
]);

/**
 * @param {import("vscode").Tab} tab
 */
function isAgentChatTab(tab) {
  const input = tab?.input;
  if (!input) {
    return false;
  }

  const viewType = input.viewType;
  if (typeof viewType === "string" && viewType.toLowerCase().includes("composer")) {
    return true;
  }

  for (const uri of [input.uri, input.modified, input.original]) {
    if (!uri) {
      continue;
    }
    const scheme = (uri.scheme || "").toLowerCase();
    if (AGENT_URI_SCHEMES.has(scheme)) {
      return true;
    }
    const path = `${uri.path || ""} ${uri.fsPath || ""}`.toLowerCase();
    if (path.includes("/composer/") || path.includes("composer:")) {
      return true;
    }
  }

  return false;
}

const FILE_URI_SCHEMES = new Set([
  "file",
  "untitled",
  "vscode-remote",
  "vscode-vfs",
  "output",
  "git",
]);

/**
 * @param {import("vscode").Tab} tab
 */
function isFileEditorTab(tab) {
  if (isAgentChatTab(tab)) {
    return false;
  }
  const input = tab?.input;
  if (!input) {
    return false;
  }
  for (const uri of [input.uri, input.modified, input.original]) {
    if (uri?.scheme && FILE_URI_SCHEMES.has(uri.scheme)) {
      return true;
    }
  }
  const name = input.constructor?.name ?? "";
  return (
    name === "TabInputText" ||
    name === "TabInputTextDiff" ||
    name === "TabInputNotebook" ||
    name === "TabInputWebview" ||
    name === "TabInputCustom"
  );
}

/**
 * @param {import("vscode").Tab} tab
 * @param {import("vscode").TabGroup} group
 */
async function focusTab(tab, group) {
  const input = tab.input;
  if (!input) {
    return false;
  }

  const column =
    group.viewColumn === vscode.ViewColumn.Active
      ? vscode.window.activeTextEditor?.viewColumn ?? vscode.ViewColumn.One
      : group.viewColumn;

  for (const uri of [input.uri, input.modified, input.original]) {
    if (uri) {
      await vscode.window.showTextDocument(uri, {
        viewColumn: column,
        preserveFocus: false,
        preview: false,
      });
      return true;
    }
  }

  return false;
}

/**
 * @param {import("vscode").TabGroup} group
 */
async function focusGroup(group) {
  const fileTab = group.tabs.find((t) => isFileEditorTab(t));
  if (!fileTab) {
    return false;
  }
  return focusTab(fileTab, group);
}

const FOCUS_GROUP_COMMANDS = {
  1: "workbench.action.focusFirstEditorGroup",
  2: "workbench.action.focusSecondEditorGroup",
  3: "workbench.action.focusThirdEditorGroup",
  4: "workbench.action.focusFourthEditorGroup",
  5: "workbench.action.focusFifthEditorGroup",
  6: "workbench.action.focusSixthEditorGroup",
  7: "workbench.action.focusSeventhEditorGroup",
  8: "workbench.action.focusEighthEditorGroup",
};

function hasFileTabs() {
  return vscode.window.tabGroups.all.some((group) =>
    (group.tabs ?? []).some((tab) => isFileEditorTab(tab)),
  );
}

async function closeViaEditorGroupFocus() {
  for (const cmd of Object.values(FOCUS_GROUP_COMMANDS)) {
    await vscode.commands.executeCommand(cmd);
    const active = vscode.window.tabGroups.activeTabGroup;
    const tabs = active?.tabs ?? [];
    if (tabs.length === 0) {
      continue;
    }
    if (tabs.every(isAgentChatTab) || !tabs.some(isFileEditorTab)) {
      continue;
    }
    if (tabs.every(isFileEditorTab)) {
      await vscode.commands.executeCommand(
        "workbench.action.closeEditorsInGroup",
      );
      continue;
    }
    for (let i = tabs.length - 1; i >= 0; i--) {
      const tab = tabs[i];
      if (!isFileEditorTab(tab)) {
        continue;
      }
      try {
        await focusTab(tab, active);
        await vscode.commands.executeCommand(
          "workbench.action.closeActiveEditor",
        );
      } catch {
        await vscode.window.tabGroups.close(tab, true);
      }
    }
  }
}

async function closeFileTabsOnly() {
  const groups = [...vscode.window.tabGroups.all];

  for (let g = groups.length - 1; g >= 0; g--) {
    const group = groups[g];
    const tabs = group.tabs ?? [];
    if (tabs.length === 0) {
      continue;
    }

    const fileTabs = tabs.filter((t) => isFileEditorTab(t));
    if (fileTabs.length === 0) {
      continue;
    }

    if (fileTabs.length === tabs.length) {
      await focusGroup(group);
      await vscode.commands.executeCommand(
        "workbench.action.closeEditorsInGroup",
      );
      continue;
    }

    for (let i = fileTabs.length - 1; i >= 0; i--) {
      const tab = fileTabs[i];
      try {
        const focused = await focusTab(tab, group);
        if (focused) {
          await vscode.commands.executeCommand(
            "workbench.action.closeActiveEditor",
          );
        } else {
          await vscode.window.tabGroups.close(tab, true);
        }
      } catch {
        try {
          await vscode.window.tabGroups.close(tab, true);
        } catch {
          // ignore
        }
      }
    }
  }

  if (hasFileTabs()) {
    await closeViaEditorGroupFocus();
  }
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "closeFileTabsOnly.closeAll",
      closeFileTabsOnly,
    ),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
