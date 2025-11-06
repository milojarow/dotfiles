# ============================================================================
# Powerlevel10k Configuration Extension
# ============================================================================
# NOTE: This file does NOT contain the full prompt aesthetic configuration.
# It is a minimal extension that only modifies prompt layout (double-line).
# All visual styling (colors, icons, separators, fonts) is inherited from
# powerlevel10k's internal defaults.
# ============================================================================

# Left prompt elements - adding newline for double-line layout
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  context       # user@hostname
  dir           # current directory
  vcs           # git status
  newline       # \n - this creates the line break
  prompt_char   # prompt symbol (where you type)
)

# Right prompt elements - keeping original configuration
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # exit code
  root_indicator          # root indicator
  background_jobs         # background jobs
  time                    # current time
)

# Multiline prompt connectors - visual lines connecting first and second line
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=$'%240F╭─'
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=$'%240F├─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=$'%240F╰─ '
