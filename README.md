# Tag Fishing

Balatro mod — hold L2 to reload, press L1 to auto-hunt for tags.

## Controls

| Input | Action |
|-------|--------|
| **L2** (left trigger) | Hold to reload the run (presses R) |
| **L1** (left shoulder) | Start auto-hunting for selected tags |
| **R1** (right shoulder) | Cancel the hunt |

When hunting is active, the mod will continuously re-roll blinds until the configured tags appear on both Small and Big blinds.

## Installation

1. Install [Steamodded](https://github.com/Steamopollys/Steamodded)
2. Copy this folder into `%AppData%/Balatro/Mods/`
3. Launch Balatro

## Configuration

Edit `config.lua`:

```lua
return {
    trigger_axis = 'triggerleft',    -- axis for manual reload
    trigger_threshold = 0.5,         -- how far to pull the trigger
    hunt_tag_1_enabled = true,       -- enable tag 1 hunting
    hunt_tag_1_id = 'tag_investment',-- tag ID to hunt for (tag 1)
}
```

Tag 2 can be configured via the in-game mod settings UI (accessible from the main menu).

## Requirements

- [Steamodded](https://github.com/Steamopollys/Steamodded)
- Balatro (any recent version)
- A controller with analog triggers
