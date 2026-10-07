function fastfetch --description "fastfetch with rotating PNG logo via chafa"
    if set -q FASTFETCH_SKIP
        return
    end
    ~/.local/bin/fa $argv
end
