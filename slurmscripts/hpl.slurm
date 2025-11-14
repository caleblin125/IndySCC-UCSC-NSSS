#!/bin/bash
#SBATCH --job-name=HPL_Test
#SBATCH --partition=nsss
#SBATCH --nodes=9
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --time=01:00:00
#SBATCH --output=logs/hpl-%j.out
#SBATCH --error=logs/hpl-%j.err

# ===============================================================
# HPL Linpack Benchmark Job Script for SLURM
# Runs HPL across 9 nodes (1 MPI rank per node, 64 threads each)
# ===============================================================

set -e
set -o pipefail

# --- CONFIG ---
SHARE=/mnt/spack_hpl_manila
HPL_VER="2.3"

echo "=============================================="
echo "🚀 Starting HPL benchmark at $(date)"
echo "Running on nodes: $SLURM_NODELIST"
echo "=============================================="

cd $SHARE

# --- Optional diagnostic ---
srun hostname

# --- Clean old MPI daemons (safely) ---
sudo pkill -u "$USER" -f mpirun || true
sudo rm -rf /dev/shm/openmpi.*

# --- OpenMPI environment cleanup ---
export OMPI_MCA_ess_base_jobid=0
export OMPI_MCA_plm_rsh_no_tree_spawn=1
export OMPI_MCA_pmix=^pmi

# --- Install dependencies ---
echo "📦 Installing OpenMPI, OpenBLAS, and build tools..."
sudo apt-get update -y
sudo apt-get install -y build-essential gfortran openmpi-bin libopenmpi-dev libopenblas-dev wget tar

# Wait for install to sync
sleep 10

# --- Build HPL from source (if not already installed) ---
if [[ ! -f /usr/local/bin/xhpl ]]; then
    echo "🧰 Building HPL from source..."
    cd /tmp
    wget -q https://netlib.org/benchmark/hpl/hpl-${HPL_VER}.tar.gz -O hpl-${HPL_VER}.tar.gz
    tar xzf hpl-${HPL_VER}.tar.gz
    cd hpl-${HPL_VER}

    cp -f setup/Make.Linux_PII_CBLAS Make.Linux_OpenMPI
    sed -i 's#CC = .*#CC = mpicc#g' Make.Linux_OpenMPI
    sed -i 's#LINKER = .*#LINKER = mpicc#g' Make.Linux_OpenMPI
    sed -i 's#LIBS = .*#LIBS = -lopenblas#g' Make.Linux_OpenMPI
    sed -i 's#LAdir = .*#LAdir = /usr/lib/x86_64-linux-gnu#g' Make.Linux_OpenMPI

    echo "⚙️ Building HPL..."
    make arch=Linux_OpenMPI -j$(nproc)

    sudo ln -sf bin/Linux_OpenMPI/xhpl /usr/local/bin/xhpl
    echo "✅ HPL built and installed to /usr/local/bin/xhpl"
fi

# --- Verify build ---
which xhpl
xhpl -v 2>/dev/null || true

# --- Run HPL ---
echo "🏁 Launching HPL with $SLURM_NNODES nodes and $SLURM_CPUS_PER_TASK threads each..."
mpirun --allow-run-as-root -np $SLURM_NNODES /usr/local/bin/xhpl > $SHARE/hpl.out

echo "✅ HPL run finished at $(date)"

 mpirun --allow-run-as-root --prefix /usr --host worker-1-of-9:64,worker-2-of-9:64,worker-3-of-9:64,worker-4-of-9:64,worker-5-of-9:64,worker-6-of-9:64,worker-7-of-9:64,worker-8-of-9:64,worker-9-of-9:64 -n 576 -x OMPI_MCA_plm_rsh_agent /mnt/spack_hpl_manila/opt/hpl/bin/xhpl | tee HPL.log
