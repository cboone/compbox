# Compbox

A zsh plugin that replaces the built-in completion display with a bordered popup menu styled to match tmux's native menus: rounded corners, default terminal colors, and a red-foreground highlight for the selected item.

## Installation

### Plugin Managers

#### [zinit](https://github.com/zdharma-continuum/zinit)

```zsh
zinit light cboone/compbox
```

#### [antidote](https://getantidote.github.io/)

Add to your plugins file (e.g., `~/.zsh_plugins.txt`):

```text
cboone/compbox
```

#### [sheldon](https://sheldon.cli.rs/)

Add to `~/.config/sheldon/plugins.toml`:

```toml
[plugins.compbox]
github = "cboone/compbox"
```

#### [Oh My Zsh](https://ohmyz.sh/)

```bash
git clone https://github.com/cboone/compbox.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/compbox
```

Then add `compbox` to your `plugins` array in `~/.zshrc`:

```zsh
plugins=(... compbox)
```

#### [zplug](https://github.com/zplug/zplug)

```zsh
zplug "cboone/compbox"
```

### Manual

Clone the repository and source the plugin file in your `~/.zshrc`:

```bash
git clone https://github.com/cboone/compbox.git ~/.zsh/compbox
```

```zsh
source ~/.zsh/compbox/compbox.plugin.zsh
```

## Requirements

- zsh 5.9+
- tmux (uses `tmux capture-pane` for screen save/restore)

## Usage

TODO

## License

[MIT License](./LICENSE). TL;DR: Do whatever you want with this software, just keep the copyright notice included. The authors aren't liable if something goes wrong.
