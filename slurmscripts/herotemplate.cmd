#!/bin/bash
#SBATCH -p nsss
#SBATCH -J HEROHPL
#SBATCH -e /mnt/spack_hpl_manila/hplrun_%j.err
#SBATCH -o /mnt/spack_hpl_manila/hplrun__%j.out
#SBATCH --N=9
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --mem=240G
#SBATCH -t 15:00:00

source /mnt/spack_hpl_manila

module purge
module load nvhpc/24.7/nvhpc
spack load hpl

export MPICH_MAX_THREAD_SAFETY=multiple
export OMP_NUM_THREADS=1
export OMPI_MCA_coll_hcoll_enable=0

export OMPI_MCA_btl_tcp_if_include=enp1s0
export OMPI_MCA_oob_tcp_if_include=enp1s0
export OMPI_MCA_btl=tcp,self
export OMPI_MCA_pml=ob1



mpirun -np 576 /mnt/spack_hpl_manila/xhpl

