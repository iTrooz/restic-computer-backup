# Usage
## Create systemd unit
- Install units in `./systemd` in `~/.config/systemd/user`
- Change `ExecStart` in `restic.service` to point to the backup.sh of this repository on your filesystem
- `systemctl --user daemon-reload`
- `systemctl --user enable --now restic.timer`

## Configure script
- Create a `folder.txt` file with the list of folders to backup, one per line. [Example](./folders.example.txt)
- Create a `.env` from `.env.example` (used to provide restic variables)
- Add hooks in `./hooks/`. Some examples are available in `./hooks.example`
