#!/bin/bash
#SBATCH -p nsss
#SBATCH -J HEROHPL
#SBATCH -e /mnt/spack_hpl_manila/hplmpirun_%j.err
#SBATCH -o /mnt/spack_hpl_manila/hplmpirun__%j.out
#SBATCH -N 9
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --mem=240G
#SBATCH -t 15:00:00
chmod +x /mnt/spack_hpl_manila/spack/opt/spack/linux-zen3/hpl-2.3-ap6gqfjnb7zb5jmshj7o2sa44wtwjrnd
module purge
module load nvhpc/24.7/nvhpc

export MPICH_MAX_THREAD_SAFETY=multiple
export OMP_NUM_THREADS=1
export OMPI_MCA_coll_hcoll_enable=0

#export OMPI_MCA_btl_tcp_if_include=enp1s0
#export OMPI_MCA_oob_tcp_if_include=enp1s0
#export OMPI_MCA_btl=tcp,self
#export OMPI_MCA_pml=ob1
unset OMPI_MCA_btl_tcp_if_include
unset OMPI_MCA_oob_tcp_if_include

# Let Open MPI auto-detect the network
export OMPI_MCA_btl=^openib
export OMPI_MCA_pml=ob1


mpirun -np 576 /mnt/spack_hpl_manila/spack/opt/spack/linux-zen3/hpl-2.3-ap6gqfjnb7zb5jmshj7o2sa44wtwjrnd/bin/xhpl

