# Linux-only aliases

# Debian/Ubuntu ship bat as `batcat`
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat='batcat'; }

# Debian/Ubuntu ship fd as `fdfind`
(( $+commands[fd] )) || { (( $+commands[fdfind] )) && alias fd='fdfind'; }
