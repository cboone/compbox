# compbox.plugin.zsh — Entry point for the compbox zsh plugin
#
# Sources all library files and activates the plugin.

# Resolve plugin root directory
readonly CBX_ROOT="${0:A:h}"

# Source library files
source "${CBX_ROOT}/lib/cbx-enable.zsh"
source "${CBX_ROOT}/lib/cbx-disable.zsh"
source "${CBX_ROOT}/lib/cbx-complete.zsh"
source "${CBX_ROOT}/lib/-cbx-compadd.zsh"
source "${CBX_ROOT}/lib/-cbx-complete.zsh"
source "${CBX_ROOT}/lib/-cbx-apply.zsh"
source "${CBX_ROOT}/lib/-cbx-generate-complist.zsh"
source "${CBX_ROOT}/lib/position.zsh"
source "${CBX_ROOT}/lib/render.zsh"
source "${CBX_ROOT}/lib/navigate.zsh"
source "${CBX_ROOT}/lib/keymap.zsh"
source "${CBX_ROOT}/lib/filter.zsh"
source "${CBX_ROOT}/lib/screen.zsh"
source "${CBX_ROOT}/lib/ghost.zsh"

# Activate the plugin
cbx-enable
