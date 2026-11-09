# Patches

Documentation for VSCodium patches applied on top of VS Code.

---

## fix-policies

**Replace `@vscode/policy-watcher` with `@vscodium/policy-watcher`**

VS Code uses `@vscode/policy-watcher` to enforce Group Policy Objects (GPOs) on
Windows. That package reads from:

```
HKLM\SOFTWARE\Policies\Microsoft\<productName>
```

VSCodium forks this into `@vscodium/policy-watcher`, which takes a separate
`vendorName` argument. The `createWatcher()` call becomes:

```ts
createWatcher('VSCodium', this.productName, ...)
```

Because VSCodium sets `product.nameLong = 'VSCodium'` (via `prepare_vscode.sh`),
`this.productName` resolves to `'VSCodium'` at runtime. Therefore, the final
Windows registry key that VSCodium reads policies from is:

```
HKLM\SOFTWARE\Policies\VSCodium\VSCodium\<PolicyName>
```

(or `HKCU\SOFTWARE\Policies\VSCodium\VSCodium\<PolicyName>` for per-user policies)

This differs from VS Code's path (`Microsoft\VSCode`) and is the root cause of
[issue #2714](https://github.com/VSCodium/vscodium/issues/2714) where users mirror
VS Code's registry structure and find their GPOs ignored. Enterprise admins must
use the VSCodium-specific registry path.

### References

- [VSCodium issue #2714](https://github.com/VSCodium/vscodium/issues/2714)
- [VSCodium/policy-watcher — RegistryPolicy.hh](https://github.com/VSCodium/policy-watcher/blob/main/src/windows/RegistryPolicy.hh)

---

## 90-horizon-ui

**Launcher view containers, an SCM redirect setting, editor-area screens and activity bar defaults**

This patch is generic: it contains nothing that is specific to any one extension.

### Launcher view containers (`order` and `command`)

Built-in extensions (`extension.isBuiltin`) may set two extra fields on `contributes.viewsContainers.activitybar[]` entries:

- `order` (number): overrides the automatic order that custom containers receive.
- `command` (string): makes the container a *launcher*. It is registered with `hideIfEmpty: false` and `rejectAddedViews: true`, and carries the new `IViewContainerDescriptor.openCommand`.

Extensions that are not built in ignore both fields, so marketplace extensions are unaffected.

When a container with an `openCommand` is opened in the side bar, a workbench contribution (`contrib/horizon/browser/horizon.contribution.ts`) re-opens the last regular side bar container (Explorer if that one is itself a launcher), hides the side bar, and runs the command. The same contribution closes an editor-area screen when a regular side bar view is opened outside such a redirect.

### `horizon.scm.openCommand`

A window-scoped, restricted string setting, empty by default. When it is non-empty:

- The Source Control container behaves as a launcher for that command.
- The built-in Source Control views (Repositories, Changes, Graph) are hidden through `when: !config.horizon.scm.openCommand`.
- The Source Control container (not its Changes view) owns the `workbench.view.scm` command and Ctrl+Shift+G, so the keybinding, the View menu entry, the Command Palette and every `executeCommand('workbench.view.scm')` caller open the container; when `horizon.scm.openCommand` is set, the launcher redirect then runs that command.
- `horizon.scm.openCommand` is a restricted setting: its value is a command ID and is ignored in untrusted workspaces. Trusted workspaces, user settings and built-in extension `configurationDefaults` can set it.
- Known limitation: the Source Control open command and Ctrl+Shift+G now open the Source Control container. If the Changes view has been moved to another container, they open the Source Control container rather than revealing the moved view; use the view's own focus command instead.

When it is empty, Source Control behaves as in stock VSCodium. A built-in extension can provide a default through `contributes.configurationDefaults`.

Quick diff (gutter, overview ruler and minimap decorations) is unaffected. It depends on `IQuickDiffService` and the providers registered by the git extension, not on the Source Control views.

### Editor-area screens (`horizonScreens`)

- Built-in extensions may declare `contributes.horizonScreens`: an array of `{ "id": string, "title": string }`, where each `id` is a webview view the extension registers with `window.registerWebviewViewProvider`. Other extensions are ignored with a warning.
- `horizon.workbench.showScreen` (arguments: the screen id, optionally `{ preserveFocus: boolean }`) shows that webview over the whole main editor area, without a tab or header. It hides the side bar, and the editor groups underneath are hidden but kept.
- The screen closes, and the editors return, when an editor opens in the main editor area, when a regular side bar view is opened (activity bar, view commands, Ctrl+B), or with **Horizon: Close Screen** (Ctrl+W / Ctrl+F4 while a screen is shown and focus is in the main window). No editor is closed.
- A screen and the side bar are never shown together; the redirect of a launcher container does not close the screen. The panel and secondary side bar can be shown next to a screen. One screen is shown at a time, and hidden screens keep their webview for the session.
- While the editor area is hidden (maximized panel or secondary side bar) the screen is suspended: it is hidden, reported as not visible, and `horizonActiveScreen` is empty. It comes back with the editor area.
- The shown screen is restored after a window reload when the side bar is hidden. The context key `horizonActiveScreen` holds its id (empty when none is shown).
- `onView:<id>` activation events are generated from the contribution.

### Activity bar defaults

A one-time, per-profile contribution unpins Run and Debug, Testing and Remote Explorer from the activity bar. A profile storage marker (`horizon.activityBar.defaultsApplied`) prevents it from running again, so later user choices are kept.

### Regenerating the patch

`dev/patch.sh` is interactive. To regenerate without prompts:

- Reset `vscode/` to its upstream HEAD (`git add -A && git reset -q --hard HEAD`).
- Re-apply the current patch first: `git apply --ignore-whitespace ../patches/90-horizon-ui.patch`.
- Edit, then `git add -A && git diff --staged -U1 > ../patches/90-horizon-ui.patch`, then reset again.
- Verify that every patch applies in order with `bash dev/check-patches.sh`.

Files touched: `src/vs/workbench/common/views.ts`, `src/vs/workbench/api/browser/viewsExtensionPoint.ts`, `src/vs/workbench/contrib/scm/browser/scm.contribution.ts`, `src/vs/workbench/workbench.common.main.ts`, the new `src/vs/workbench/contrib/horizon/browser/horizon.contribution.ts`, the new `src/vs/workbench/contrib/horizon/browser/horizonScreens.ts` and the new `src/vs/workbench/contrib/horizon/browser/media/horizonScreens.css`.
