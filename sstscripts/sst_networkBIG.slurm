#!/bin/bash
#SBATCH -p nsss
#SBATCH --nodelist=worker-2-of-3
#SBATCH -J SST_BIG
#SBATCH -e /mnt/spack_hpl_manila/sst_BIG.err
#SBATCH -o /mnt/spack_hpl_manila/sst_BIG.out
#SBATCH -N 1
#SBATCH --ntasks=32
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH -t 15:00:00

NTASKS=32

cd /mnt/spack_hpl_manila
export BLAS_DIR="/mnt/spack_hpl_manila/opt/OpenBLAS"
export MPI_DIR="/mnt/spack_hpl_manila/opt/openmpi"

export PATH="$MPI_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$MPI_DIR/lib:$BLAS_DIR/lib:$LD_LIBRARY_PATH"

export OPENBLAS_NUM_THREADS=1
export GOTO_NUM_THREADS=1
export OMP_NUM_THREADS=1
export OMPI_MCA_btl_tcp_if_include=enp1s0 
##export OMPI_MCA_btl_base_verbose=100
export OMPI_MCA_btl=self,vader,tcp # only shared memory and “self”
##export OMPI_MCA_btl=^openib
export OMPI_MCA_pml=ob1

SHARE=/mnt/spack_hpl_manila
OPT=$SHARE/opt

export SST_CORE_HOME=$OPT/sst-core
export SST_ELEMENTS_HOME=$OPT/sst-elements
export PATH=$SST_CORE_HOME/bin:$PATH
export PATH=$SST_ELEMENTS_HOME/bin:$PATH
export SST_ELEMENT_PATH=$SST_ELEMENTS_HOME/lib/sst-elements-library
export LD_LIBRARY_PATH=$SST_ELEMENTS_HOME/lib:$LD_LIBRARY_PATH

echo "Running SST simulation..."
cd $SHARE/IndySCC25-SST-Elements/network

echo "----------------------------"
echo "[halo , 512 endpoints, full]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=halo --work=80 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=full

echo "----------------------------"
echo "[fft , 512 endpoints, full]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=fft --work=1600 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=full

echo "----------------------------"
echo "[halo , 512 endpoints, half]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=halo --work=80 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=half

echo "----------------------------"
echo "[fft , 512 endpoints, half]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=fft --work=1600 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=half

echo "----------------------------"
echo "[halo , 512 endpoints, quarter]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=halo --work=80 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=quarter

echo "----------------------------"
echo "[fft , 512 endpoints, quarter]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=fft --work=1600 --iter=20 --jobs=4 --group_size=512 --num_groups=64 --bw=quarter

echo "----------------------------"
echo "[halo , 256 endpoints, full]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=halo --work=80 --iter=20 --jobs=4 --group_size=256 --num_groups=128 --bw=full

echo "----------------------------"
echo "[fft , 256 endpoints, full]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=fft --work=1600 --iter=20 --jobs=4 --group_size=256 --num_groups=128 --bw=full

echo "----------------------------"
echo "[halo , 256 endpoints, half]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=halo --work=80 --iter=20 --jobs=4 --group_size=256 --num_groups=128 --bw=half

echo "----------------------------"
echo "[fft , 256 endpoints, half]"
/mnt/spack_hpl_manila/opt/openmpi/bin/mpirun -np $NTASKS sst -- dragonfly.py -- --app=fft --work=1600 --iter=20 --jobs=4 --group_size=256 --num_groups=128 --bw=half

echo "Finished"