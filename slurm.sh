# https://github.com/SergioMEV/slurm-for-dummies
# User to SSH as
SSH_USER="exouser"

# Nodes and their passwords
# Format: NODE:PASS
NODES=(
  "149.165.150.159:AURA DANA LIMA OLIN BAND RAG SCOT MEAN MEL WE RAW"
  "149.165.151.146:WELD RIFT VICE JEFF CAIN TICK FUN DART HOCK ORR HILL"
)

echo "-------------STARTING TO INSTAL SLURM----------------"

echo "-------------MUNGE----------------"
sudo apt update > /dev/null
sudo apt upgrade > /dev/null
sudo apt install -y openssh-server openssh-client
sudo apt install -y munge libmunge2 libmunge-dev
sudo apt install -y sshpass

munge -n | unmunge | grep STATUS

sudo /usr/sbin/mungekey
sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/
sudo chmod 0755 /run/munge/
sudo chmod 0700 /etc/munge/munge.key
sudo chown -R munge: /etc/munge/munge.key

sudo systemctl enable munge
sudo systemctl restart munge


echo "-------------MUNGE COPYING----------------"
#install munge
for NODE_INFO in "${NODES[@]}"; do
    NODE="${NODE_INFO%%:*}"
    PASS="${NODE_INFO##*:}"

    echo "[*] Installing Munge on $NODE..."

    # Use sshpass + sudo -S to allow sudo with password
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$NODE" bash -c "'
        echo \"$PASS\" | sudo -S apt update -qq >/dev/null &&
        echo \"$PASS\" | sudo -S apt install -y -qq munge libmunge2 libmunge-dev >/dev/null &&
        munge -n | unmunge | grep STATUS && 
        echo \"Munge installation completed on \$(hostname) at \$(date)\" | sudo tee /tmp/munge_installed.txt >/dev/null
    '"

done

# copy key
for NODE_INFO in "${NODES[@]}"; do
    NODE="${NODE_INFO%%:*}"
    PASS="${NODE_INFO##*:}"


    echo "[*] Copying Munge key to $NODE..."
    sudo cat /etc/munge/munge.key | \
        sshpass -p "$PASS" ssh "$SSH_USER@$NODE" "sudo tee /etc/munge/munge.key >/dev/null"
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$NODE" bash -c "'
        echo \"$PASS\" | sudo -S chown munge:munge /etc/munge/munge.key &&
        echo \"$PASS\" | sudo -S chmod 400 /etc/munge/munge.key &&
        sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/ &&
        sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/ &&
        sudo chmod 0755 /run/munge/ &&
        sudo chmod 0700 /etc/munge/munge.key &&
        sudo chown -R munge: /etc/munge/munge.key &&
        sudo systemctl enable munge &&
        sudo systemctl restart munge &&
        echo \"Munge installation and key copied on \$(hostname) at \$(date)\" | sudo tee /tmp/munge_installed.txt
    '"

    echo "[+] Munge installation marked on $NODE"
done

echo "[*] Munge installation completed on all nodes. Check /tmp/munge_installed.txt on each node for confirmation."


echo "-------------SLURM INSTALL----------------"
#SLURM install
sudo apt install -y -qq slurm-wlm libpmix-dev libpmix2 

sudo tee /etc/slurm/slurm.conf > /dev/null << 'EOF'
# Slurm configuration for team 'nsss'
ClusterName=nsss
SlurmctldHost=login           # Change to your controller's hostname

StateSaveLocation=/var/spool/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid

ProctrackType=proctrack/linuxproc
ReturnToService=1
SlurmctldTimeout=120
SlurmdTimeout=300
InactiveLimit=0
KillWait=30

# Use the simple 'linear' node selection plugin
SelectType=select/linear

# Logging
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log

# Node and partition definitions
# Adjust CPUs/Sockets/Cores/Threads from `lscpu`
NodeName=node-[1-2] CPUs=64 RealMemory=250000 State=UNKNOWN
PartitionName=debug Nodes=node-[1-2] Default=YES MaxTime=INFINITE State=UP
EOF

sudo mkdir -p /var/spool/slurmctld
sudo chown slurm:slurm /var/spool/slurmctld
sudo chmod 755 /var/spool/slurmctld

sudo systemctl enable slurmctld
sudo systemctl restart slurmctld
sudo systemctl status slurmctld.service



echo "-------------SLURM COPIES----------------"
for NODE_INFO in "${NODES[@]}"; do
    NODE="${NODE_INFO%%:*}"
    PASS="${NODE_INFO##*:}"

    echo "[*] Copying Slurm Conf to $NODE... <---------------------"
    sudo cat /etc/slurm/slurm.conf | \
        sshpass -p "$PASS" ssh "$SSH_USER@$NODE" "sudo tee /etc/slurm/slurm.conf >/dev/null"
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$NODE" bash -c "'
        sudo apt install -y -qq slurm-wlm libpmix-dev libpmix2 &&
        sudo mkdir -p /var/spool/slurmd &&
        sudo chown slurm:slurm /var/spool/slurmd &&
        sudo chmod 755 /var/spool/slurmd &&
        sudo systemctl enable slurmd &&
        sudo systemctl restart slurmd &&
        sudo systemctl status slurmd.service &&
        echo \"Slurm on \$(hostname) at \$(date)\" | sudo tee /tmp/munge_installed.txt
    '"

    echo "[+] Slurm installation marked on $NODE"
done