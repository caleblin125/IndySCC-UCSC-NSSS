#!/bin/bash
#SBATCH -p nsss
#SBATCH -J HEROHPL
#SBATCH -e /mnt/spack_hpl_manila/hplmpirun_%j.err
#SBATCH -o /mnt/spack_hpl_manila/hplmpirun_%j.out
#SBATCH -N 3
#SBATCH --ntasks=192
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --mem=240G
#SBATCH -t 15:00:00

cd /mnt/spack_hpl_manila
export HPL_DIR="/mnt/spack_hpl_manila/opt/hpl"
export BLAS_DIR="/mnt/spack_hpl_manila/opt/OpenBLAS"
export MPI_DIR="/mnt/spack_hpl_manila/opt/openmpi"

export PATH="$MPI_DIR/bin:$HPL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$MPI_DIR/lib:$BLAS_DIR/lib:$HPL_DIR/lib:$LD_LIBRARY_PATH"


export OPENBLAS_NUM_THREADS=1
export GOTO_NUM_THREADS=1
export OMP_NUM_THREADS=1
export OMPI_MCA_btl_tcp_if_include=enp1s0 
##export OMPI_MCA_btl_base_verbose=100
export OMPI_MCA_btl=self,vader,tcp # only shared memory and “self”
##export OMPI_MCA_btl=^openib
export OMPI_MCA_pml=ob1

/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np 192 /mnt/spack_hpl_manila/opt/hpl/bin/xhpl
