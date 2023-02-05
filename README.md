# Godot Steam Cloud

This is a wrapper to make it simple handling Steam Cloud usage across games. Made by Softwool to use in our games (check out [Pistola](https://store.steampowered.com/app/1956400/PISTOLA/) and [Torecower](https://store.steampowered.com/app/2210670/Torecower/). As we love open source, we wanted to share this simple tooling.

## Setup

- This project expects your project to use [GodotSteam](https://github.com/gramps/godotsteam)
- Add the `addons/` folder to your project (or `steam_cloud/*` into your `addons/` if it already exists)
- Make sure your game has the Cloud enabled [on steam](https://partner.steamgames.com/doc/features/cloud)

## API

`SteamCloud.gd` - Autoload

### Functions

#### save(\_filename: String, \_resource: Resource, \_path: String)

Saves your local file to desired path (defaults to _user://_) and then sends its contents under the name `_filename` to the cloud.
Calls back `save_finished` on success and `save_failed` on fail.

#### load(\_filename: String, \_path: String)

Loads both the local file from desired path (defaults to _user://_).
On error calls `load_failed`.

On success it returns `loaded_with_conflicts`, so you can check both the remote file and local one if you need to handle conflicts to keep them in sync.

If there's no conflicts and there's only a remote file (e.g.: When the player first plays the game _on a new device_), it calls `load_finished`.

_I need to improve this API._

### Signals

#### save_finished()

Emitted when your save is finished. You can use it to remove a "Save in Progress" view, for instance.

#### save_failed(remote: bool)

Emitted when there's an error during the file saving.
Remote: whether the error was when saving the remote file (to Steam Remote Storage) or local one.

#### loaded_with_conflicts(remote: Resource, local: Resource)

Emitted when there's both a remote and local files, so you can handle any reconciliations if needed to guarantee the player doesn't have any rollback into their progress.

#### load_finished(contents: Resource)

Emitted when the load is done in two cases:

- There's only the remote file;
- There's only the local file (this shouldn't happen at all, if this is happening, there's something wrong in your implementation)

#### load_failed(remote: bool)

Emitted when the loading fails, as well as with the same, it returns the `remote` variable so you know whether the error was in the file system or steam's remote storage.
