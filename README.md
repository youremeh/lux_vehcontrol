# lux_vehcontrol

An updated **lux_vehcontrol** with improved code and keybinds.  
Original can be found and downloaded [here](https://forum.cfx.re/t/release-luxart-vehicle-control/17304).  
  
# Keybinds  
  
## Lights  
| Key         | Function                        |  
|------------|--------------------------------|  
| `Q`        | Toggle on/off emergency vehicle lights |  
| `-`        | Toggle on/off left turn signal |  
| `=`        | Toggle on/off right turn signal |  
| `BACKSPACE`| Toggle on/off 4-way hazard lights |  

## Sirens  
| Key         | Function                                |  
|------------|----------------------------------------|  
| `LEFT ALT`   | Toggle on/off main emergency vehicle sirens |  
| `R`          | Cycle main sirens forward 1 siren     |  
| `UP ARROW`   | Toggle on/off secondary emergency vehicle siren |  
| `LEFT ARROW` | Cycle main siren back 1 siren         |  
| `RIGHT ARROW`| Cycle main siren forward 1 siren     |  

## What's changed?
```
- Better code optimizations probably
- "light reminder" that beeps every 7 seconds when lights are on
- Light reminder can be turned off via `/lr` or disabled in client.lua
- Ability to cycle the main siren forwards or backwards with arrow keys
- If the sirens are on, getting out of the vehicle dirver seat will disable them automatically
- Disables distant siren sounds, fixes multiple issues
- Starts different "blank" audios to prevent/stop ghost sirens (same with above)

- Uses new native "OverrideReactionToVehicleSiren" to move locals out the way
(see this: https://docs.fivem.net/natives/?_0x3F3EB3F7 for more info)
```
