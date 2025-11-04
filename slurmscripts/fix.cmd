#!/bin/bash
#SBATCH -N 9
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --mem=240G
#SBATCH -t 15:00:00
#SBATCH -e /mnt/spack_hpl_manila/fix_%j.err
#SBATCH -o /mnt/spack_hpl_manila/fix__%j.out
echo "=== FIXING MPI ENVIRONMENT ==="

# 1. Kill any leftover MPI processes
echo "Cleaning stuck MPI processes..."
pkill -f ompi 2>/dev/null || echo "No ompi processes found"
pkill -f orted 2>/dev/null || echo "No orted processes found"

# 2. Clean environment variables that interfere with mpirun
echo "Cleaning conflicting environment variables..."
unset SLURM_MPI_TYPE 2>/dev/null
unset PMI_FD 2>/dev/null
unset PMI_RANK 2>/dev/null
unset PMI_SIZE 2>/dev/null
unset PMI_JOBID 2>/dev/null
unset I_MPI_PMI_LIBRARY 2>/dev/null

# 3. Reset OpenMPI specific variables
unset OMPI_MCA_plm 2>/dev/null
unset OMPI_MCA_ras 2>/dev/null
unset OMPI_MCA_ess 2>/dev/null

# 4. Clean module environment and reload fresh
echo "Resetting modules..."
module purge
module load nvhpc/24.7/nvhpc
# 5. Verify MPI is working
echo "Verifying MPI installation..."
which mpirun
mpirun --version | head -1

# 6. Test with a simple command
echo "Testing MPI execution with hostname..."
mpirun -np 576 hostname

echo "=== MPI ENVIRONMENT FIXED ==="
echo "If you see hostnames above, mpirun is working!"
