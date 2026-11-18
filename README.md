# IndySCC 2025 — UCSC "Not So Slow Slugs"

Cluster build and benchmark scripts from UC Santa Cruz's team (SCC 110) at the
**IndySCC 2025** student cluster competition, run on
[Jetstream2](https://jetstream-cloud.org/) cloud instances (AMD EPYC 7713,
64 cores per node).

Over the competition we built a Slurm cluster from bare Ubuntu VMs, compiled
the HPC software stack from source onto a shared filesystem, and ran the
competition workloads: the **HPL** (High Performance Linpack) "hero run" and
the **SST** (Structural Simulation Toolkit) hardware-simulation application.

## What's here

| Path | Purpose |
|---|---|
| [`Makefile`](Makefile), [`slurm.sh`](slurm.sh) | Bring up Munge + Slurm across a login node and workers over SSH (based on [slurm-for-dummies](https://github.com/SergioMEV/slurm-for-dummies)) |
| [`slurm.conf`](slurm.conf) | Cluster config: `nsss` CPU partition (3 × 32-CPU workers) and `gsss` GPU partition |
| [`setup_manila.sh`](setup_manila.sh) | Mount the Jetstream2 Manila (CephFS) share used as the shared `/opt` and scratch |
| [`install.sh`](install.sh) | Build OpenMPI, OpenBLAS, and HPL from source with Zen 3 flags (`-O3 -march=znver3 -flto=thin`) |
| [`SSTsetup.sh`](SSTsetup.sh) | Build SST core and SST elements |
| [`slurmscripts/`](slurmscripts/) | HPL and Spack batch scripts (multi-node HPL, 1 MPI rank × 64 threads per node) |
| [`sstscripts/`](sstscripts/) | SST network-simulation job scripts at increasing scale, plus a Miranda CPU + cache + memory demo |
| [`HPL.log`](HPL.log) | HPL output from the cluster |
| [`scc110_hpl_hero_submission.pdf`](scc110_hpl_hero_submission.pdf) | Our HPL hero-run report: theoretical peak, build choices, tuning, and lessons learned |

## Using the scripts

The node lists in `Makefile` and `slurm.sh` are written as `IP:<password>`
placeholders, and `setup_manila.sh` reads the share key from
`MANILA_ACCESS_KEY`. Fill these in for your own allocation:

```bash
# 1. edit NODES / NAMES in the Makefile for your instances
make            # installs Munge + Slurm on every node and starts the daemons

# 2. mount the shared filesystem on every node
export MANILA_ACCESS_KEY=...   # from the Jetstream2 Manila share
sudo -E ./setup_manila.sh

# 3. build the stack onto the share, then submit
./install.sh
sbatch slurmscripts/hpl.slurm
```

## Team

Tu Lan Tran, Holden Martinez, Tao Sato-Perry, Julien Lee, Caleb Lin, Myles Hallett.
