# Linux-only aliases

# Debian/Ubuntu ship bat as `batcat`
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat='batcat'; }
