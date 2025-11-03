#!/bin/bash
#SBATCH --job-name=HPL_Test
#SBATCH --partition=small
#SBATCH --nodes=9
#SBATCH --ntasks-per-node=2
#SBATCH --time=01:00:00
#SBATCH --output=hpl-%j.out
#SBATCH --error=hpl-%j.err

# Load necessary modules (if any)
module load mpi
module load blas

echo "Starting HPL run on $(date)"
echo "Running on nodes: $SLURM_NODELIST"

# Optional: show CPU info
srun --nodes=1 --ntasks=1 lscpu

# Run HPL
srun --mpi=pmix ~/share/xhpl

echo "HPL run finished on $(date)"

