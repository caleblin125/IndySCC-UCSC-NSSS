#!/bin/bash
set -e # Exit immediately if any command fails

# --- Configuration from your screenshot ---
CLIENT_NAME="scc110-hpl-spack"
ACCESS_KEY="AQCJIwlpSjuJFRAAUMNyErjGKaLWJykTQOAE5A=="
MOUNT_POINT="/mnt/spack_hpl_manila"
KEYRING_FILE="/etc/ceph/ceph.client.${CLIENT_NAME}.keyring"

# Note: Copied this long path directly from your script
EXPORT_PATH="149.165.158.38:6789,149.165.158.22:6789,149.165.158.54:6789,149.165.158.70:6789,149.165.158.86:6789:/volumes/_nogroup/d63a7073-f387-4e1a-9174-619ba30687f3/d05cb892-601d-4821-abb0-8829deea874b"

# --- End Configuration ---


# 1. Create the mount point directory (if it doesn't exist)
#    This matches Step 1 in the guide.
echo "Creating mount point ${MOUNT_POINT}..."
sudo mkdir -p "${MOUNT_POINT}"


# 2. Create the ceph keyring file
#    This matches Step 2.i in the guide.
echo "Creating keyring file ${KEYRING_FILE}..."
printf "[client.%s]\n    key = %s\n" "${CLIENT_NAME}" "${ACCESS_KEY}" | sudo tee "${KEYRING_FILE}" > /dev/null

# Set permissions on the keyring file
sudo chmod 600 "${KEYRING_FILE}"


# 3. Add the share to /etc/fstab so it mounts on boot
#    This matches Step 2.ii in the guide.
FSTAB_ENTRY="${EXPORT_PATH} ${MOUNT_POINT} ceph name=${CLIENT_NAME},x-systemd.device-timeout=30,x-systemd.mount-timeout=30,noatime,_netdev,rw 0 2"

# Check if the line already exists in fstab before adding it
if ! grep -qF "${MOUNT_POINT}" /etc/fstab; then
    echo "Adding share to /etc/fstab..."
    # Add a newline just in case the file doesn't end with one
    printf "\n%s\n" "${FSTAB_ENTRY}" | sudo tee -a /etc/fstab > /dev/null
else
    echo "fstab entry for ${MOUNT_POINT} already exists."
fi


# 4. Mount the share immediately
#    This matches Step 3 in the guide.
echo "Mounting all filesystems in /etc/fstab..."
sudo mount -a

echo "Done. Share should be mounted at ${MOUNT_POINT}."
df -h "${MOUNT_POINT}"
