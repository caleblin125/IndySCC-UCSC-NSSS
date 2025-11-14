
SHARE=/mnt/spack_hpl_manila
SCRATCH=$SHARE/scratch
HOME=$SHARE/opt

MPIHOME=$SHARE/opt/openmpi
export PATH=$MPIHOME/bin:$PATH
export MPICC=mpicc
export MPICXX=mpicxx
export CXX="g++ -O3 -march=zn"

export SST_CORE_HOME=$HOME/sst-core
export SST_CORE_ROOT=$SCRATCH/sst-core
export SST_ELEMENTS_HOME=$HOME/sst-elements
export SST_ELEMENTS_ROOT=$SCRATCHsst-elements

#Install 
echo "Installing repos..."
mkdir -p $SCRATCH
cd $SCRATCH
git clone https://github.com/sstsimulator/sst-core.git
cd sst-core
git checkout master
cd $SCRATCH
git clone https://github.com/sstsimulator/sst-elements.git
cd sst-elements
git checkout master
# cd $SCRATCH
# git clone https://github.com/sstsimulator/sst-macro.git
# cd sst-macro
# git checkout master


#Build SST core
echo "Building sst-core..."
cd $SCRATCH/sst-core
./autogen.sh
mkdir -p $SST_CORE_HOME
./configure --prefix=$SST_CORE_HOME
make -j all
make -j install
export PATH=$SST_CORE_HOME/bin:$PATH
which sst
sst --version
sst-info
# sst-test-core


#Build SST elements
echo "Building sst-elements..."
cd $SCRATCH/sst-elements
mkdir -p $SST_ELEMENTS_HOME
./autogen.sh
./configure --prefix=$SST_ELEMENTS_HOME --with-sst-core=$SST_CORE_HOME
make -j all
make -j install
export PATH=$SST_ELEMENTS_HOME/bin:$PATH
which sst
sst --version
sst-info
# sst-test-elements -w "*simple*"