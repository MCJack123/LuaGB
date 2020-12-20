# LuaGB for ComputerCraft/CraftOS-PC
A gameboy emulator written in Pure Lua. Approaching feature completeness, but still a work in progress.

This is designed to be fairly cross platform, and currently consists of a platform-independent gameboy module which contains the emulator, and a ComputerCraft/CraftOS-PC interface. While it plays well, the structure of the emulator is in constant flux, so don't rely on the API resembling any sort of stability.

## Supported Features

* Supports CC: Tweaked (limited), or [CraftOS-PC](https://www.craftos-pc.cc) v2.1 or later.
* Original Gameboy (DMG) and Gameboy Color (GBC) (CraftOS-PC only)
* Decently cycle-approximate graphics? Seems slow for now, working on fixing.
* Multiple Palettes for DMG Mode
* SRAM and Save States

## Notable Missing Features

* Super Gameboy support (planned)
* Serial Transfer / Link Cable support
* RTC Timer (Pokemon Gold / Crystal)
* Key remapping, Gamepad support, etc
* Movie Recording / Playback / TAS Features (planned)
* Audio playback (can still record to file)
  * Rudimentary audio support is available in CraftOS-PC v2.3 or later by attaching a speaker

## Run Instructions
Download the repository, extract it to your ComputerCraft root.

Please be respectful of copyright in your region. You should only play commercial ROMs you have legally obtained yourself; in the US at least, this means you need to personally rip the ROM data from your own original cartridges. For free homebrew, I've been testing with several games and demos from PDRoms:
http://pdroms.de/

If you're interested in purchasing a fantastic cartridge ripper, I own and use the Joey Generation 3. Note that BennVenn makes these by hand, so if his shop is out of stock, check back in a few days:
http://bennvenn.myshopify.com/products/reader-writer-gen2


## Usage Instructions
`cd` to `LuaGB/computercraft` or `LuaGB/craftos-pc` directory, then run
```
main <games/path/to/game.gb>
```

Press Q to quit.

## Known Issues

This emulator is in its early stages, so it is primarily focused on accuracy rather than speed. Thanks to some help from the community it is now reasonably performant, especially on recent PCs running under LuaJIT, but it's hardly greased lightning. It may struggle on weaker PCs.

I still have not implemented every cartridge type, and some more advanced features (like the RTC clock on MBC3) are incomplete or missing entirely. I welcome bug reports, but please observe the console output when a game won't boot; if it complains about an Unknown MBC type, that's probably the real issue. I need to order physical cartridges for every MBC type to properly test, and that will take time.

Graphics output, though approaching cycle accuracy, is not perfect. It is close enough for games like Prehistorik Man to display their effects correctly, but some homebrew demos and a few commercial titles still have visual problems. Bug reports are very welcome here, as I simply don't have time in the day to test every game out there, and the small number of games I do have that are giving me obvious visual artifacts are proving difficult to debug.

This runs *very* slowly in ComputerCraft and standard CraftOS-PC. You can get a large performance increase by running it in CraftOS-PC Accelerated.

The ComputerCraft interface is currently in beta, and requires an 80x48 monitor to run. Color accuracy may be affected due to the fact that no more than two colors can be in a 2x3 area. I've attempted to round the colors as best as possible, but the artifacts will still be noticeable. It also does not, and will never, support Game Boy Color games due to ComputerCraft not supporting even the base set of colors (56) that a GBC has.

## Bug Reporting

I welcome bug reports of all kinds! I may be slow to respond to bug reports for commercial games that I do not physically own, as I need to order them from Amazon and then rip them to my computer before I can try to reproduce the bug. Bug reports can include homebrew too! The long term goal is for the emulator to match real hardware in its behavior, so don't feel like you need to limit bug reports to officially licensed games.
