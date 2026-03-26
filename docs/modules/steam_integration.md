# Steam Integration Module

## Setup (when ready to publish)
1. Install GodotSteam GDExtension from Godot Asset Library (search "GodotSteam GDExtension 4.4+")
2. Restart Godot editor
3. Set your Steam App ID in Project Settings > Steam > Initialization
4. Uncomment the Steam API calls in `src/autoload/steam_manager.gd`
5. Define achievements in Steamworks backend matching `data/achievements.json`

## Files
- `src/autoload/steam_manager.gd` - Steam init, callbacks, achievements, leaderboards, cloud save
- `src/autoload/save_manager.gd` - Save/load with Steam Cloud fallback to local
- `data/achievements.json` - Achievement definitions

## Key APIs Used
- `Steam.steamInitEx()` - Initialize with status check
- `Steam.run_callbacks()` - Must call every frame in `_process()`
- `Steam.setAchievement()` / `Steam.storeStats()` - Unlock achievements
- `Steam.findLeaderboard()` / `Steam.uploadLeaderboardScore()` - Leaderboards
- `Steam.fileWriteAsync()` / `Steam.fileRead()` - Cloud saves

## Testing Without Steam
- App ID 480 (SpaceWar) can be used for testing
- Create `steam_appid.txt` with `480` in project root (remove before shipping!)
- SteamManager gracefully falls back to offline mode when Steam unavailable

## Build for Steam
1. Export from Godot using standard export templates
2. Use SteamPipe/steamcmd to upload to Steam depot
3. Never include `steam_appid.txt` in the shipped build
