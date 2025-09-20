#!/bin/zsh
# Called by crontab
set -e
trap 'on_exit $?' EXIT
on_exit() {
    status=$1
    if [ $status -eq 0 ]; then
        echo "Success"
    elif [ $status -eq 10 ]; then
        echo "Failed because of metered network"
        notify-send "Restic backup" "Failed because of metered network"
    else
        echo "Failure: $status"
        notify-send -u critical "Restic backup" "Failed with exit code $status"
    fi
}

SCRIPT_DIR=$(realpath $(dirname $0))
# Read folders from folders.txt, expand ~, and store as array
BACKUP_FOLDERS=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" ]] && continue
            BACKUP_FOLDERS+=("$(eval echo $line)")
done < "$SCRIPT_DIR/folders.txt"
echo $BACKUP_FOLDERS

for uuid in $(nmcli --fields=uuid connection show --active | tail -n +2); do
    metered=$(nmcli connection show "$uuid" | grep -i metered | awk '{print $2}')
    echo "connection $uuid metered status: $metered"
    if [ "$metered" = "yes" ]; then
        exit 10
    fi
done

echo "Run restic backup"
backup_output="$($SCRIPT_DIR/restic.sh backup "${BACKUP_FOLDERS[@]}" --json)"

echo "Parse backup summary and notify"
last_json=$(echo "$backup_output" | jq -s '.[-1]')
backup_time_rounded=$(LC_NUMERIC=C printf "%.2f" "$backup_time")
backup_time_rounded=$(printf "%.2f" "$backup_time")
data_bytes=$(echo "$last_json" | jq -r '.total_bytes_processed')
human_size=$(numfmt --to=iec-i --suffix=B "$data_bytes")
notify-send "Restic Backup Complete" "Time: ${backup_time_rounded}s, Size: ${human_size}"

echo "Forget old backups"
$SCRIPT_DIR/restic.sh forget --keep-daily 3 --keep-weekly 1 --keep-monthly 1 --prune
