#!/bin/bash
#SBATCH --job-name=sst_job
#SBATCH --output=/mnt/spack_hpl_manila/sst_output_%j.txt
#SBATCH --error=/mnt/spack_hpl_manila/sst_error_%j.txt
#SBATCH --partition=nsss           # or gsss if using GPU partition
#SBATCH --nodes=3
#SBATCH --ntasks=9               # one SST simulation
#SBATCH --cpus-per-task=3          # adjust to your SST model
#SBATCH --time=02:00:00

# Load SST if your cluster uses modules
# module load sst

SHARE=/mnt/spack_hpl_manila
SCRATCH=$SHARE/scratch
OPT=$SHARE/opt

MPIHOME=$SHARE/opt/openmpi
export PATH=$MPIHOME/bin:$PATH
export MPICC=mpicc
export MPICXX=mpicxx
export CXX="g++ -O3 -march=zn"

export SST_CORE_HOME=$OPT/sst-core
export SST_CORE_ROOT=$SCRATCH/sst-core
export SST_ELEMENTS_HOME=$OPT/sst-elements
export SST_ELEMENTS_ROOT=$SCRATCHsst-elements
export PATH=$SST_CORE_HOME/bin:$PATH
export PATH=$SST_ELEMENTS_HOME/bin:$PATH

echo "Running SST simulation..."
mpirun -n $SLURM_NTASKS sst /mnt/spack_hpl_manila/demo1.py