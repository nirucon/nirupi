#!/usr/bin/env bash
# NIRU emoji picker. Copies the chosen emoji to the clipboard.
# Uses rofimoji when installed, otherwise a bundled list (no dependency).
set -Eeuo pipefail

if command -v rofimoji >/dev/null 2>&1; then
  exec rofimoji --copy
fi

menu="${NIRUPI_MENU:-}"
pick() {
  if [[ -n $menu ]]; then "$menu" -i -p 'Emoji'; 
  elif command -v rofi >/dev/null 2>&1; then rofi -dmenu -i -p 'Emoji';
  elif command -v dmenu >/dev/null 2>&1; then dmenu -i -p 'Emoji';
  else cat; fi
}

copy() {
  if command -v wl-copy >/dev/null 2>&1 && [[ -n ${WAYLAND_DISPLAY:-} ]]; then wl-copy
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input
  else cat >/dev/null; fi
}

read -r -d '' EMOJI <<'EOF' || true
🙂 smiley
😀 grinning
😄 happy
😁 beam
😅 sweat smile
😂 joy
🤣 rofl
😊 blush
😇 innocent
🙃 upside down
😉 wink
😍 heart eyes
😘 kiss
😎 cool
🤓 nerd
🤔 thinking
🤨 raised brow
😐 neutral
😑 expressionless
😶 no mouth
🙄 eye roll
😏 smirk
😴 sleeping
😪 sleepy
😢 cry
😭 sob
😤 triumph
😠 angry
😡 rage
🤯 mind blown
😱 scream
😳 flushed
🥵 hot
🥶 cold
🤒 sick
🤕 hurt
🤠 cowboy
🥳 party
😈 devil
🤖 robot
👻 ghost
💀 skull
👽 alien
🤝 handshake
👍 thumbs up
👎 thumbs down
👌 ok
🤌 pinched
✌️ victory
🤞 fingers crossed
🤟 love you
🤘 rock
👏 clap
🙌 raise
🙏 pray
💪 muscle
👋 wave
🖐️ hand
✋ raised hand
🫡 salute
🫶 heart hands
❤️ red heart
🧡 orange heart
💛 yellow heart
💚 green heart
💙 blue heart
💜 purple heart
🖤 black heart
🤍 white heart
💔 broken heart
❤️‍🔥 heart on fire
💯 hundred
🔥 fire
✨ sparkles
⭐ star
🌟 glowing star
⚡ zap
💥 boom
💫 dizzy
🎉 tada
🎊 confetti
🎈 balloon
🎁 gift
🏆 trophy
🥇 gold
✅ check
☑️ ballot check
❌ cross
⚠️ warning
❗ exclamation
❓ question
💡 idea
🔔 bell
🔕 no bell
🔇 mute
🔊 loud
📢 megaphone
📌 pin
📍 round pin
📎 paperclip
🔗 link
🔒 lock
🔓 unlock
🔑 key
🛠️ tools
🔧 wrench
🔨 hammer
⚙️ gear
🧰 toolbox
🖥️ desktop
💻 laptop
⌨️ keyboard
🖱️ mouse
🖨️ printer
💾 save
📀 disk
🗑️ trash
📁 folder
📂 open folder
📄 file
📝 memo
📖 book
📚 books
📰 news
🔍 search
🔎 search right
🏠 house
🏢 office
🚀 rocket
✈️ plane
🚗 car
🚲 bike
🐧 penguin
🐍 snake
🐳 whale
🦀 crab
🐙 octopus
🦊 fox
🐱 cat
🐶 dog
🌱 seedling
🌳 tree
🍀 clover
🌸 blossom
🌻 sunflower
🌈 rainbow
☀️ sun
🌙 moon
⛅ cloud
🌧️ rain
❄️ snow
☕ coffee
🍵 tea
🍺 beer
🍷 wine
🍕 pizza
🍔 burger
🍎 apple
🍋 lemon
🍫 chocolate
🍩 donut
EOF

choice="$(printf '%s\n' "$EMOJI" | grep -vE '^[[:space:]]*$' | pick || true)"
[[ -n $choice ]] || exit 0
emoji="$(printf '%s' "$choice" | awk '{print $1}')"
printf '%s' "$emoji" | copy
command -v notify-send >/dev/null 2>&1 && notify-send -a NIRUPI "Emoji" "$emoji copied" >/dev/null 2>&1 || :
