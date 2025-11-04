#!/bin/bash
#SBATCH -J HPL_9_node_pure_mpi
#SBATCH -N 9
#SBATCH -n 64
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH -t 02:00:00
#SBATCH -p nsss
#SBATCH -o hpl_%j.out
#SBATCH -e hpl_%j.err


cd /mnt/spack_hpl_manila/
source /mnt/spack_hpl_manila/spack/share/spack/setup-env.sh

spack load hpl /t7v

# Simple run
srun xhpl
