# SMB Terminal Tools for macOS

Function for easier mounting and unmounting of a smb nas volumes on macOS by terminal.

For now, the server url and the username is hardcoded into the script, as I only have one NAS on my home network, but the script can easily be modified.

Password is not needed, as the terminal will ask for the password, and save it in keychain for future attempts.

## Requirements
- whiptail
```bash
brew install newt
```
- lf (optional)
```bash
brew install lf
```

## Installation

Edit the .nasconfig.env with your own server name / address and username, and place it into ~/.config/zsh/

To make the mounting be interchangable with the mounting and unmounting in finder, I had to add "._smb._tcp.local" after my server name / adcress. This will make it finder mount it with the same name, so that mounting and unmounting by terminal also mounts and unmounts the same share in finder.

Put the script in ~/.config/zsh/functions/ and put following command in .zshrc, to load all functions in the folder, or modify it to load only .

```bash
for file in ~/.config/zsh/functions/*.sh; do
    source "$file"
done
```

To make lf work properly (with lfcd), move lfcd.sh to ~/.config/lf/lfcd.sh and source it in your .zshrc
```bash
source ~/.config/lf/lfcd.sh
```

## How to use it

If the server / function is called MyNAS, and the share you want mounted is called MyShare, then you can either type MyServer to choose the share graphically, or type MyNAS MyShare to mount it directly.

### Parameters
-o - Open in lf   - will open the smb share with lf instead of just cd. Note that I'm using the lfcd script to make lf remember the current directory when exiting to the terminal.
-u - Unmount      - Unmount instead of mount
