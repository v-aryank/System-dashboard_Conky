# System-dashboard_Conky

A customised lightweight system monitor for Linux that renders overlays directly on your desktop. Here's the complete guide to replicate this on Ubuntu.
-

<b>Step 1 — Install Conky</b><br>
<u>bash</u><br>
<i>sudo apt update<br>
sudo apt install conky-all</i>

The conky-all variant includes all extras including Cairo graphics, Lua scripting, and font rendering support.<br>

---

<b>Step 2 — Install required fonts</b><br>
<u>bash</u><br>
<i>sudo apt install fonts-jetbrains-mono</i><br>

Also install icon fonts if you want symbols:<br>
<u>bash</u><br>
<i>sudo apt install fonts-font-awesome</i><br>

---

<b>Step 3 — Download both files attached. Then follow these steps:</b><br>
<u>bash</u><br>
<i>mkdir -p ~/.config/conky<br>
cp ~/Downloads/conky.conf ~/.config/conky/conky.conf<br>
cp ~/Downloads/rings.lua ~/.config/conky/rings.lua<br></i>

---

<b>Step 4 — Launch:</b><br>
<u>bash</u><br>
<i>conky -c ~/.config/conky/conky.conf &</i><br>

<b>If want to kill old conky and re-launch: </b><br>
<u>bash</u><br>
<i>pkill conky; sleep 1; conky -c ~/.config/conky/conky.conf &</i><br>

---

Make the program run at autostart, two steps — autostart via .desktop file, and a fix so Conky survives desktop restarts.
-
<b>Step 1 — Create the autostart entry:</b><br>
<u>bash</u><br>
<i>mkdir -p ~/.config/autostart<br>
nano ~/.config/autostart/sira-monitor.desktop</i><br>

Paste this exactly:<br>

<i>[Desktop Entry]<br>
Type=Application<br>
Name=SIRA System Monitor<br>
Comment=Conky system dashboard<br>
Exec=bash -c "sleep 5 && conky -c /home/user/.config/conky/conky.conf"<br>
Hidden=false<br>
NoDisplay=false<br>
X-GNOME-Autostart-enabled=true<br></i>

//Use your own desktop adress.<br>
Save with Ctrl+O → Enter → Ctrl+X.<br>

---

<b>Step 2 — Make it executable:</b><br>
<u>bash</u><br>
<i>chmod +x ~/.config/autostart/sira-monitor.desktop</i><br>

<b>Step 3 — Test it right now without rebooting:</b><br>
<u>bash</u><br>
<i>pkill conky; conky -c ~/.config/conky/conky.conf &</i><br>

<b>Step 4 — Verify autostart is registered:</b><br>
<u>bash</u><br>
<i>ls ~/.config/autostart/</i><br>

You should see sira-monitor.desktop listed.

That's it. Every time you power on or log in, GNOME will wait 5 seconds (for the desktop to fully load) then launch Conky automatically. The sleep 5 is important — without it Conky sometimes starts before the desktop compositor is ready and renders behind everything or disappears.