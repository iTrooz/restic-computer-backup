#!/bin/sh
# https://gist.github.com/iTrooz/712093480b3261698baec2f90fb4868b
# Called by crontab/systemd timer
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

# Set working directory
cd "$(realpath $(dirname $0))"

# Read paths from paths.txt, expand ~, and store as array
echo "Read paths to backup from paths.txt"
BACKUP_PATHS=()
while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" ]] && continue
    BACKUP_PATHS+=("$(eval echo $line)")
done < "paths.txt"
echo "Paths to backup (${#BACKUP_PATHS[@]}): ${BACKUP_PATHS[@]}"

# Do not run if on a metered network
for uuid in $(nmcli --fields=uuid connection show --active | tail -n +2); do
    metered=$(nmcli connection show "$uuid" | grep -i metered | awk '{print $2}')
    echo "connection $uuid metered status: $metered"
    if [ "$metered" = "yes" ]; then
        exit 10
    fi
done

# Create temporary folder for hooks data
rm -rf ./tmp
mkdir -p ./tmp

echo "Run hooks"
for hook in "./hooks/"*; do
    [ -x "$hook" ] && "$hook"
done

echo "Run restic backup"
backup_output="$(./restic.sh backup "${BACKUP_PATHS[@]}" --json)"

# Delete temporary folder
rm -rf ./tmp

echo "Parse backup summary and notify"
last_json=$(echo "$backup_output" | jq -s '.[-1]')
backup_time=$(echo "$last_json" | jq -r '.total_duration')
backup_time_rounded=$(LC_NUMERIC=C printf "%.2f" "$backup_time")
data_bytes=$(echo "$last_json" | jq -r '.total_bytes_processed')
human_size=$(numfmt --to=iec-i --suffix=B "$data_bytes")
notify-send "Restic Backup Complete" "Time: ${backup_time_rounded}s, Size: ${human_size}"

echo "Forget old backups"
./restic.sh forget --keep-daily 3 --keep-weekly 2 --keep-monthly 2 --group-by tags --prune
