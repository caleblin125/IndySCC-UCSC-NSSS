#!/bin/bash
#SBATCH -p herohpl
#SBATCH -J HEROHPL
#SBATCH -e /home/exouser/hellompi/hello_%j.err
#SBATCH -o /home/exouser/hellompi/hello_%j.out
#SBATCH --nodes=9
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH -t 05:00:00

cd /home/exouser/hpl
module purge
module load nvhpc/24.7/nvhpc-hpcx-cuda12
module load hpcx-ompi

export OMPI_MCA_coll_hcoll_enable=0

export OMPI_MCA_btl_tcp_if_include=enp1s0
export OMPI_MCA_oob_tcp_if_include=enp1s0
export OMPI_MCA_btl=tcp,self
export OMPI_MCA_pml=ob1

SPACK_DIR=~/spack
if [[ ! -d "$SPACK_DIR" ]]; then
    git clone --depth=2 --branch=releases/v1.0 https://github.com/spack/spack.git $SPACK_DIR
    cd ~/spack
    . share/spack/setup-env.sh
    cd ~
    echo "source ~/spack/share/spack/setup-env.sh" >> ~/.bashrc
    echo "spack installed"
else
    echo "spack already exists"
fi 

echo "=== Job started ==="
echo "Working directory: $(pwd)"
echo "Running on: $(hostname)"
#mpirun -np 576 ~/share/hpl
echo "=== Job completed ==="

