#!/bin/bash

# Get current timestamp and 24 hours ago timestamp
current_time=$(date +%s)
day_ago=$((current_time - 86400))

# Process /var/log/messages and extract first occurrence of each hostname in last 24 hours
awk -v day_ago="$day_ago" '
BEGIN {
    # Initialize month name to number mapping
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months, " ")
    for (i in months) month_nums[months[i]] = sprintf("%02d", i)

    # Get current year
    "date +%Y" | getline current_year
}

{
    # Extract timestamp components
    month = month_nums[$1]
    day = sprintf("%02d", $2)
    time = $3

    # Parse hostname (usually the 4th field)
    hostname = $4

    # Remove any trailing colon from hostname
    sub(/:$/, "", hostname)

    # Skip if we have already seen this hostname
    if (hostname in seen) next

    # Construct timestamp in a format that date can understand
    timestamp = sprintf("%s-%s-%s %s", current_year, month, day, time)

    # Convert log timestamp to epoch using -d option with correct format
    cmd = "date -d \"" timestamp "\" +%s 2>/dev/null"
    if ((cmd | getline epoch_time) > 0) {
        # Only process entries from last 24 hours
        if (epoch_time >= day_ago) {
            # Store the first occurrence of this hostname
            seen[hostname] = 1
            print hostname " " $1 " " $2 " " $3
        }
    }
    close(cmd)
}' /var/log/messages | sort
