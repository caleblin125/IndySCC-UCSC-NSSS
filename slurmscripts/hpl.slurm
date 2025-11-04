#!/bin/bash
#SBATCH --job-name=HPL_Test
#SBATCH --partition=nsss
#SBATCH --ntasks=9
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --nodes=9
#SBATCH --time=01:00:00
#SBATCH --output=logs/hpl-%j.out
#SBATCH --error=logs/hpl-%j.err

# Load necessary modules (if any)
# module load mpi
# module load blas

SHARE=/mnt/spack_hpl_manila

cd $SHARE
echo "Starting HPL run on $(date)"
echo "Running on nodes: $SLURM_NODELIST"

# Optional: show CPU info
srun --nodes=9 --ntasks=9 hostname

# Run HPL
sudo pkill -u $USER -f mpirun
sudo rm -rf /dev/shm/openmpi.*

source ./spack/share/spack/setup-env.sh
spack load /t7v4cds
spack load /ap6gqfj
mpirun --allow-run-as-root -np $SLURM_NPROCS xhpl > hpl.out

echo "HPL run finished on $(date)"

/mnt/spack_hpl_manila/spack/opt/spack/linux-zen3/openmpi-5.0.8-ciyamgpjqe7un4rqfhcwdtrhjlpubwzt/bin/mpirun --host worker-1-of-9:64,worker-2-of-9:64,worker-3-of-9:64,worker-4-of-9:64,worker-5-of-9:64,worker-6-of-9:64,worker-7-of-9:64,worker-8-of-9:64,worker-9-of-9:64 -n 576 /mnt/spack_hpl_manila/spack/opt/spack/linux-zen3/hpl-2.3-t7v4cdshucmgdoqpbyuvaqyoh7tslpql/bin/xhpl

