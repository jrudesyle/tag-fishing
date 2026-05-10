# Tag Fishing

Balatro mod — hold L2 to reload, tap L1 to auto-hunt for tags.

## Structure

- `ControllerReload.lua` — entrypoint, all gameplay logic in one file
- `config.lua` — config returned as a Lua table; loaded into `MOD.config`
- `debug.log` — ephemeral runtime log, safe to delete

## Key conventions

- The `--- STEAMODDED HEADER` block is mandatory, must be exactly 7 comment lines (`MOD_NAME`, `MOD_ID`, `MOD_AUTHOR`, `MOD_DESCRIPTION`, `VERSION`)
- `MOD = SMODS.current_mod` gives access to mod context and config
- The mod hooks global `love.gamepadaxis`, `love.gamepadpressed`, and `Game.update_blind_select` via monkey-patching
- Simulated keypress: set `G.CONTROLLER.held_keys['r'] = true` / `nil`
- Config UI built via `MOD.config_tab()` using `G.UIT` primitives

## No build / test / lint

Zero build tools, tests, or CI. No `package.json` or lockfiles. This is a drop-in Balatro mod folder — place it in `%AppData%/Balatro/Mods/` alongside Steamodded.

## Important constraints

- `SMODS.current_mod` is only available after Steamodded finishes loading; any code using it must be inside the mod file itself, not required at the top level before Steamodded initializes
- Lua globals like `G`, `love`, `SMODS` are injected by the game at runtime — no static analysis or require path can resolve them
- Version bump in the header on every release
- Config UI toggles use `ref_table = MOD.config, ref_value = '<key>'` — the key is the actual config field name
