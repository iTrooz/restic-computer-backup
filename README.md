# What is this ?
This project is primarily meant for use on personal computers, for periodical restic backups of important stuff. For example, it can backup your secret store, bitwarden Vault, and static folders.

This repository hosts a script `backup.sh` allowing you to backup folders specified in `paths.txt`, and run custom hooks in `hooks/` to query data to backup. The script will sends a popup to your desktop environment upon success failure.

systemd units are also available to automatically run a backup daily.

# Usage
## Create systemd unit
- Install units in `./systemd` in `~/.config/systemd/user`
- Change `ExecStart` in `restic.service` to point to the backup.sh of this repository on your filesystem
- `systemctl --user daemon-reload`
- `systemctl --user enable --now restic.timer`

## Configure script
- Create a `paths.txt` file with the list of paths to backup, one per line. [Example](./paths.example.txt)
- Create a `.env` from `.env.example` (used to provide restic variables)
- (Optional) Add hooks in `./hooks/`. Some examples are available in `./hooks.example`. These hooks will run before the backup. You will still need to add the associated paths to `paths.txt`
