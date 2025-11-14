#!/bin/bash
#SBATCH --job-name=test_slurm
#SBATCH -e /mnt/spack_hpl_manila/slurmtest/status.err
#SBATCH -o /mnt/spack_hpl_manila/slurmtest/status.out
#SBATCH --nodes=3      
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:10:00
#SBATCH --partition=nsss         # Change to your partition name

echo "====================================="
echo " SLURM Node Connection + CPU Test"
echo " Job ID: $SLURM_JOB_ID"
echo " Nodes: $SLURM_NODELIST"
echo "====================================="
echo

# Get expanded per-node list
NODELIST=$(scontrol show hostname $SLURM_NODELIST)

# Loop nodes *in order* and run tests one at a time
for NODE in $NODELIST; do
    echo "----------------------------------"
    echo "Node: $NODE"
    echo "----------------------------------"

    srun --nodes=1 --ntasks=1 --nodelist=$NODE bash -c "
        echo \"Ping Test:\"
        ping -c 2 $NODE | head -n 4
        echo
        echo \"CPU Info:\"
        lscpu | egrep 'Architecture|Model name|CPU\(s\)|Thread|Core|Socket'
        echo
        echo \"Memory:\"
        free -h
        echo
    "

    echo "----------------------------------"
    echo
done

# **Real list of real compute node hostnames**
export ALLNODES="$(scontrol show hostnames "$SLURM_NODELIST")"

srun bash -c '
    MYNODE=$(hostname -s)                      # short real node name
    LOGFILE="/mnt/spack_hpl_manila/slurmtest/random_messages_${MYNODE}.log"
    : > "$LOGFILE"
    # Convert node list to bash array
    read -ra NODE_ARRAY <<< "$ALLNODES"
    NODECOUNT=${#NODE_ARRAY[@]}

    for ((i=1; i<=10000; i++)); do
        TARGET=${NODE_ARRAY[$(shuf -i 0-$(($NODECOUNT-1)) -n 1)]}
        ping -c 1 -W 1 "$TARGET" > /dev/null 2>&1
        echo "$i $(date +%H:%M:%S) $MYNODE → $TARGET" >> "$LOGFILE"
    done

    echo "Finished $MYNODE (saved: $LOGFILE)"
'