

SHARE=/mnt/spack_hpl_manila
SCRATCH=$SHARE/scratch
OPT=$SHARE/opt

MPIHOME=$SHARE/opt/openmpi
export DYLD_LIBRARY_PATH=$MPIHOME/lib:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=$MPIHOME/lib:$LD_LIBRARY_PATH
export MANPATH=$MPIHOME/share/man:$DYLD_LIBRARY_PATH

export PATH=$MPIHOME/bin:$PATH
export MPICC=mpicc
export MPICXX=mpicxx

export CC=mpicc
export CXX=mpicxx

export CFLAGS="-O3 -march=znver3 -flto=thin -fno-plt"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-flto=thin"


export SST_CORE_HOME=$OPT/sst-core
export SST_CORE_ROOT=$SCRATCH/sst-core

export SST_ELEMENTS_HOME=$OPT/sst-elements
export SST_ELEMENTS_ROOT=$SCRATCH/sst-elements

sudo apt install -y libtool libtool-bin autoconf python3 python3-dev automake build-essential git

#Install 
echo "Installing repos..."
mkdir $SCRATCH

rm -rf $SST_CORE_ROOT
rm -rf $SST_CORE_HOME
cd $SCRATCH
git clone https://github.com/sstsimulator/sst-core.git
cd sst-core

git checkout v15.1.0_Final
rm -rf $SST_ELEMENTS_ROOT
rm -rf $SST_ELEMENTS_HOME
cd $SCRATCH
git clone https://github.com/sstsimulator/sst-elements.git
cd sst-elements
git checkout v15.1.0_Final
# cd $SCRATCH
# git clone https://github.com/sstsimulator/sst-macro.git
# cd sst-macro
# git checkout master


#Build SST core
echo "Building sst-core..."
cd $SST_CORE_ROOT
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
cd $SST_ELEMENTS_ROOT
mkdir -p $SST_ELEMENTS_HOME
./autogen.sh
./configure --prefix=$SST_ELEMENTS_HOME --with-sst-core=$SST_CORE_HOME
make -j all
make -j install
export PATH=$SST_ELEMENTS_HOME/bin:$PATH
export SST_ELEMENT_PATH=$SST_ELEMENTS_HOME/lib/sst-elements-library
export LD_LIBRARY_PATH=$SST_ELEMENTS_HOME/lib:$LD_LIBRARY_PATH
which sst
sst --version
sst-info
# sst-test-elements -w "*simple*"