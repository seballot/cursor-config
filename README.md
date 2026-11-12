# cursor-config

Personal Cursor customizations tracked from `~/.cursor`.

## Tracked paths

- `skills/` — custom agent skills
- `extensions/close-file-tabs-only/` — local extension
- `cli-config.json` — Cursor CLI / agent config
- `cursor/User/` — symlinks to `~/.config/Cursor/User/` (IDE settings)
- `extensions.txt` — marketplace extension list (`id@version`)

## Restore

```bash
git clone git@github.com:seballot/cursor-config.git ~/.cursor   # or pull in place

mkdir -p ~/.config/Cursor/User
cp cursor/User/settings.json cursor/User/keybindings.json ~/.config/Cursor/User/

cp cli-config.json ~/.cursor/
cp -r extensions/close-file-tabs-only ~/.cursor/extensions/
cp -r skills/* ~/.cursor/skills/

xargs -a extensions.txt -I{} cursor --install-extension {}
```
