# Roblox ESP Script (Box + Name + Distance + Head Circle)

This repository contains a Roblox Lua ESP (Extrasensory Perception) script for use with Roblox executors.  
Features include:

- **2D Box ESP** around all players (except yourself)
- **Name tag** above the box
- **Distance indicator** below the box (shows distance in studs)
- **Head ESP Circle**: a circle is drawn around each player's head
- **Dynamic scaling**: ESP elements scale with distance
- **Infinite Jump** and a simple Speed UI

## How to Use

1. **Upload the script** (`main.lua`) to a public GitHub repository (if not already).
2. **Inject it in Roblox** using your favorite executor with this loader code:

    ```lua
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ljashub/bloxstrike-beta/main/main.lua"))()
    ```

## Features

- ESP overlays update live and work after respawn.
- No duplicate overlays.
- Head and box ESP scale down at distance.
- Simple, reliable, and does not require any paid tools.

## Disclaimer

- This script is for **educational purposes only**.
- Use responsibly and according to the Roblox Terms of Service.
- The author is not responsible for misuse or any bans that may result from using this script.

## Credits

- Script by [ljas](https://github.com/ljashub)
