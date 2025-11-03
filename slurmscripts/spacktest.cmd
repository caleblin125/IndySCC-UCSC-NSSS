#!/bin/bash
#SBATCH -p nsss
#SBATCH -J spackinstall
#SBATCH -e /home/exouser/hellompi/hello_%j.err
#SBATCH -o /home/exouser/hellompi/hello_%j.out
#SBATCH --nodes=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH -t 05:00:00

cd /home/exouser
module purge
SPACK_DIR=~/spack

rm -fr spack

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

spack install hpl
echo "=== Node $SLURM_PROCID on $(hostname) completed ==="

