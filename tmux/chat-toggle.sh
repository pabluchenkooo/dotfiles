#!/bin/sh
# Toggle iamb as a left side pane in the current window.
# While hidden it lives in session "chat"; a "hold" window keeps that session alive when the pane is pulled out.
here="$1"  # pane the key was pressed in

tmux has -t chat 2>/dev/null || tmux new -d -s chat -n hold
tmux list-windows -t chat -F '#{window_name}' | grep -qx hold || tmux new-window -d -t chat -n hold

chat=$(tmux list-panes -a -F '#{pane_id} #{@chat}' | awk '$2 == 1 { print $1; exit }')
if [ -z "$chat" ]; then
  chat=$(tmux new-window -d -t chat -n iamb -P -F '#{pane_id}' iamb)
  tmux set -p -t "$chat" @chat 1
fi

if [ "$(tmux display -p -t "$chat" '#{window_id}')" = "$(tmux display -p -t "$here" '#{window_id}')" ]; then
  tmux break-pane -d -s "$chat" -n iamb -t chat:
else
  tmux join-pane -h -b -l 35% -s "$chat" -t "$here"
fi
