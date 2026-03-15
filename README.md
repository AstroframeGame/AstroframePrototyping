# AstroframePrototyping

The prototyping for Astroframe in godot

[Live Demo](https://sentientdragon5gamedev.itch.io/astroframeprototype)

### Z indices

- -10 backgrounds
- 0 for ground
- 4 for characters interior
- 5 for bullets interior
- 8 for exteriors
- 12 for characters exteriors
- 13 for bullets exterior

### Credits:

- <a target="_blank" href="https://icons8.com/icon/YmmZ2YsHiv59/discord-new">Discord</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/3tC9EQumUAuq/github">GitHub</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/JnHXhz9KQ8RC/folder">Folder</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/9976/mute">Mute</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/9982/audio">Audio</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/35066/wrench">Wrench</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/10767/triangle-arrow">Triangle Arrow</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>
- <a target="_blank" href="https://icons8.com/icon/ms3ftPftW1cW/instagram">Instagram</a> icon by <a target="_blank" href="https://icons8.com">Icons8</a>

## Build and Run Instructions

Create a `.env` with a `GODOT_PATH` to the godot executable. As an example, this is where the Steam Version of Godot will install.

- Windows: `GODOT_PATH="C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"`
- Mac: `GODOT_PATH = "/Users/USERNAME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"`

Build the project with `python .\buildScripts\build.py --target=windows` where target can be `windows` , `mac`, `linux`, or `android`.
This will create a zip in `.\build`.

Unzip the build and launch the executable.

- Windows: Double click the exe
- Mac: Right click and run app. Allow the unsigned app to run (We promise we are not malware!).
- Linux: `chmod +x AstroFramePrototyping.x86_64` then `./AstroFramePrototyping.x86_64`
- Android: Download through Itch.io or other download portal, then Install the downloaded APK. Launch the app from the home screen. Controller Required.

For Steam, add the game to the library via store page (not live) or Steam key, then _Install_ the game and _Play_ the game in your Steam library.
