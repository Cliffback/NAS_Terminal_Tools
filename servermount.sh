# Function to mount Synology NAS and navigate to the mounted folder
function MyServer() {

    # Path to the dotfile
    local config_path="${HOME}/.config/zsh/.nasconfig.env"
    # Check if the dotfile exists
    if [ ! -f "$config_path" ]; then
        echo ".nasconfig not found: $config_path"
        return 1
    fi

    # Read servername and username from the dotfile
    local nas_address=$(grep 'nas_address' "$config_path" | cut -d '=' -f2)
    local username=$(grep 'username' "$config_path" | cut -d '=' -f2)

    if [ -z "$nas_address" ] || [ -z "$username" ]; then
        echo "Servername or username not found in dotfile."
        return 1
    fi

    local use_lfcd=false
    local use_unmount=false

    while getopts "ou" opt; do
        case $opt in
            o)
                use_lfcd=true
                ;;
            u)
                use_unmount=true
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$use_unmount" = true ]; then
        unmount_smb_volumes "$@"
        return $?
    fi

if [ -z "$1" ]; then
        local share_name

        # Get the list of available shares using smbutil
        local shares=$(smbutil view "//${username}@${nas_address}" 2>/dev/null | awk '/Disk/{print $1}')

        if [ -z "$shares" ]; then
            echo "No shares found on the NAS."
            return 1
        fi

        local shares_array=()
        while IFS= read -r line; do
            shares_array+=("$line" "")
        done <<< "$shares"

        if [ ${#shares_array[@]} -eq 0 ]; then
            echo "No shares found on the NAS."
            return 1
        fi

        # Use whiptail to present a selection menu
        share_name=$(whiptail --title "Choose NAS Share" --menu "Select a share to mount:" 15 60 8 "${shares_array[@]}" 3>&1 1>&2 2>&3)

        if [ -z "$share_name" ]; then
            echo "No share selected. Aborting."
            return 1
        fi
    else
        local share_name=$1
    fi

 

    # Set the mount path
    local mount_path="/Volumes/${share_name}"

    # Check if the share is already mounted
    
    if mount | grep -q "//${username}@${nas_address}/${share_name}"; then
        echo "NAS share is already mounted."

if [ "$use_lfcd" = true ]; then
            lfcd "$mount_path" || return 1
        else
            cd "$mount_path" || return 1
        fi        
        return 0
    fi

    # Rest of the function remains unchanged...
# If the directory does not exist, create it
    if [ ! -d "$mount_path" ]; then
        echo "Mount path doesn't exist. Creating..."
        sudo mkdir -p "$mount_path"
        sudo chmod 777 "$mount_path"
        sudo chown -R mathias.eek "$mount_path"
        if [ $? -ne 0 ]; then
            echo "Failed to create mount path. Aborting."
            return 1
        fi
    fi
    # Mount the NAS using the retrieved or entered password
    mount_smbfs "//${username}@${nas_address}/${share_name}" "$mount_path"

    if [ $? -eq 0 ]; then
        echo "NAS share mounted successfully."

if [ "$use_lfcd" = true ]; then
            lfcd "$mount_path" || return 1
        else
            cd "$mount_path" || return 1
        fi        
    else
        echo "Failed to mount NAS share."
        return 1
    fi
}

function unmount_smb_volumes() {
    local volume_to_unmount=$1
    local current_directory=$(pwd)

    if [ -n "$volume_to_unmount" ]; then
        echo "Unmounting volume: $volume_to_unmount"
        umount "$volume_to_unmount" || return 1
        echo "Volume '$volume_to_unmount' unmounted successfully."
    else
        local mounted_smb_volumes=$(mount | grep "//" | grep "smbfs" | awk -F '/' '{print $(NF)}' | awk -F'@' '{print $NF}' | sed -E 's/ \(smbfs,.*//' | uniq)

        if [ -z "$mounted_smb_volumes" ]; then
            echo "No SMB volumes currently mounted."
            return 1
        fi

        local mounted_smb_volumes_array=()
        local formatted_mounted_volumes=()

        while IFS= read -r line; do
            mounted_smb_volumes_array+=("$line" "")
            formatted_mounted_volumes+=("$line" "")
        done <<< "$mounted_smb_volumes"

        local chosen_volume
        chosen_volume=$(whiptail --title "Choose SMB Volume to Unmount" --menu "Select an SMB volume to unmount:" 15 60 8 "${formatted_mounted_volumes[@]}" 3>&1 1>&2 2>&3)

        if [ -z "$chosen_volume" ]; then
            echo "No SMB volume selected for unmounting. Aborting."
            return 1
        fi

        local chosen_volume_full_path=$(mount | grep "smbfs" | grep "$chosen_volume" | awk '{print $1}')

        # Check if the current directory is in /Volumes; if not, change to /Volumes
        if [[ "$current_directory" == "/Volumes/${chosen_volume}"* ]]; then
            echo "Changing to /Volumes directory."
            cd /Volumes || return 1
        fi
        
        echo "Unmounting SMB volume: $chosen_volume_full_path"
        umount "$chosen_volume_full_path" || return 1
        echo "SMB Volume '$chosen_volume_full_path' unmounted successfully."

        # Return to the original directory if it was changed
        if [[ "$current_directory" != "/Volumes"* ]]; then
            echo "Returning to original directory: $current_directory"
            cd "$current_directory" || return 1
        fi
    fi
}
