#!/bin/bash

source ~/.bashrc
add_build() {
    local prefix="$1"

    if [[ -z "$prefix" ]]; then
        echo "Usage: add_build <prefix>"
        return 1
    fi

    # Normalize path
    prefix="$(cd "$prefix" 2>/dev/null && pwd)"
    if [[ -z "$prefix" ]]; then
        echo "Directory does not exist: $1"
        return 1
    fi

    # Add bin
    if [[ -d "$prefix/bin" ]]; then
        export PATH="$prefix/bin:$PATH"
    fi

    # Add lib or lib64
    if [[ -d "$prefix/lib" ]]; then
        export LD_LIBRARY_PATH="$prefix/lib:${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="$prefix/lib:${LIBRARY_PATH:-}"
    elif [[ -d "$prefix/lib64" ]]; then
        export LD_LIBRARY_PATH="$prefix/lib64:${LD_LIBRARY_PATH:-}"
        export LIBRARY_PATH="$prefix/lib64:${LIBRARY_PATH:-}"
    fi

    # Add include
    if [[ -d "$prefix/include" ]]; then
        export CPATH="$prefix/include:${CPATH:-}"
        export C_INCLUDE_PATH="$prefix/include:${C_INCLUDE_PATH:-}"
        export CPLUS_INCLUDE_PATH="$prefix/include:${CPLUS_INCLUDE_PATH:-}"
    fi

    export CMAKE_PREFIX_PATH="$prefix:${CMAKE_PREFIX_PATH:-}"

    echo "Added build prefix: $prefix"
}

INSTALL_DIR="/mnt/spack_hpl_manila/opt"
CLONE_DIR="/mnt/spack_hpl_manila/mysteryapp"
BUILD_DIR="$CLONE_DIR/build"

SHARE=/mnt/spack_hpl_manila
OPT=$SHARE/opt
MPIHOME=$SHARE/opt/openmpi
export DYLD_LIBRARY_PATH=$MPIHOME/lib:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=$MPIHOME/lib:$LD_LIBRARY_PATH
export MANPATH=$MPIHOME/share/man:$DYLD_LIBRARY_PATH

export PATH=$MPIHOME/bin:$PATH
export MPICC=mpicc
export MPICXX=mpicxx
export CXX="g++ -O3 -march=native"

# Run this to add all the builds to path
for d in $INSTALL_DIR/*; do
    if [[ -d "$d" ]]; then
        add_build "$d"
    fi
done

#LFS
cd $CLONE_DIR
#get-lfs
sudo apt-get install git-lfs

#boost
cd $CLONE_DIR
wget https://archives.boost.io/release/1.89.0/source/boost_1_89_0.tar.gz
tar -xzf boost_1_89_0.tar.gz 
rm -rf boost_1_89_0.tar.gz
cd boost_1_89_0/
mkdir $INSTALL_DIR/boost_1_89_0
./bootstrap.sh --prefix=$INSTALL_DIR/boost_1_89_0
./b2 install --prefix=$INSTALL_DIR/boost_1_89_0
cd ..
add_build $INSTALL_DIR/boost_1_89_0

#alternative for boost
sudo apt-get update
sudo apt-get install libboost-all-dev

#eigen
cd $CLONE_DIR
git clone https://gitlab.com/libeigen/eigen.git
cd eigen
git checkout 3.4.0

# sudo rm -rf $INSTALL_DIR/eigen
mkdir -p $INSTALL_DIR/eigen $BUILD_DIR/eigen

cd $BUILD_DIR/eigen
sudo rm $CLONE_DIR/eigen/CMakeCache.txt
cmake $CLONE_DIR/eigen -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/eigen

sudo make -j4 install
add_build $INSTALL_DIR/eigen

#nlohmann_json
cd $CLONE_DIR
git clone https://github.com/nlohmann/json.git
cd json
git checkout v3.11.3

mkdir $INSTALL_DIR/nlohmann_json $BUILD_DIR/nlohmann_json

cd $BUILD_DIR/nlohmann_json
sudo rm $CLONE_DIR/json/CMakeCache.txt
cmake $CLONE_DIR/json -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/nlohmann_json

sudo make -j4 install
add_build $INSTALL_DIR/nlohmann_json

#xerces-c
cd $CLONE_DIR
wget https://dlcdn.apache.org//xerces/c/3/sources/xerces-c-3.3.0.tar.gz
tar -xzf xerces-c-3.3.0.tar.gz
rm -rf xerces-c-3.3.0.tar.gz
cd xerces-c-3.3.0
mkdir $INSTALL_DIR/xerces-c-3.3.0
./configure --prefix=$INSTALL_DIR/xerces-c-3.3.0
make
sudo make install
cd $CLONE_DIR
add_build $INSTALL_DIR/xerces-c-3.3.0


XercesC_INCLUDE_DIR=$INSTALL_DIR/xerces-c-3.3.0/include
XercesC_LIBRARY=$INSTALL_DIR/xerces-c-3.3.0/lib/libxerces-c.so
XercesC_VERSION=3.3.0

#oneTBB
cd $CLONE_DIR
git clone https://github.com/uxlfoundation/oneTBB.git
cd oneTBB
git checkout v2022.2.0

mkdir -p $INSTALL_DIR/oneTBB $BUILD_DIR/oneTBB
cd $BUILD_DIR/oneTBB
sudo rm $CLONE_DIR/oneTBB/CMakeCache.txt
cmake $CLONE_DIR/oneTBB -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/oneTBB

sudo make -j4 install
add_build $INSTALL_DIR/oneTBB

#pythia
cd $CLONE_DIR
wget https://pythia.org/download/pythia83/pythia8313.tgz
tar -xzf pythia8313.tgz
rm -rf pythia8313.tgz
cd pythia8313
mkdir $INSTALL_DIR/pythia8313
./configure --prefix=$INSTALL_DIR/pythia8313
make
sudo make install 
cd $CLONE_DIR
add_build $INSTALL_DIR/pythia8313

#install root
cd $CLONE_DIR
sudo apt install binutils cmake dpkg-dev g++ gcc libssl-dev git libx11-dev \
    libxext-dev libxft-dev libxpm-dev python3 libtbb-dev libvdt-dev libgif-dev
git clone https://github.com/root-project/root.git #root not working yet
cd root
git checkout v6-34-04 #first time I checked out the specific version, hopefully works fine with previously cloned repos

mkdir $CLONE_DIR/rootbuild
cd $CLONE_DIR/rootbuild
mkdir -p $INSTALL_DIR/root
cmake $CLONE_DIR/root -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/root -Dgnuinstall=ON
sudo make -j8 
sudo make -j8 install
add_build $INSTALL_DIR/root

#install hepmc
cd $CLONE_DIR
git clone https://gitlab.cern.ch/hepmc/HepMC3.git
cd HepMC3 
git checkout 3.3.1
mkdir -p $INSTALL_DIR/HepMC3
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/HepMC3   \
        -DHEPMC3_ENABLE_ROOTIO:BOOL=OFF            \
        -DHEPMC3_ENABLE_PROTOBUFIO:BOOL=OFF        \
        -DHEPMC3_ENABLE_TEST:BOOL=OFF              \
        -DHEPMC3_INSTALL_INTERFACES:BOOL=OFF        \
        -DHEPMC3_BUILD_STATIC_LIBS:BOOL=OFF        \
        -DHEPMC3_BUILD_DOCS:BOOL=OFF     \
        -DHEPMC3_ENABLE_PYTHON:BOOL=OFF
make -j 8
sudo make -j 8 install
add_build $INSTALL_DIR/HepMC3

#install lcio
cd $CLONE_DIR
git clone https://github.com/iLCSoft/LCIO.git
cd LCIO
git checkout v02-22-05
mkdir build
cd build
mkdir -p $INSTALL_DIR/LCIO
cmake .. -DBUILD_ROOTDICT=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/LCIO
make -j 8 install
cd ..
. ./setup.sh
add_build $INSTALL_DIR/LCIO

#install geant4
cd $CLONE_DIR
git clone https://github.com/Geant4/geant4.git
cd geant4
git checkout v11.3.0

mkdir -p $INSTALL_DIR/geant4 $BUILD_DIR/geant4
cd $BUILD_DIR/geant4
sudo rm -rf CMakeCache.txt CMakeFiles
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/geant4 \
    -DGEANT4_BUILD_MULTITHREADED=ON \
    -DGEANT4_USE_GDML=ON \
    -DGEANT4_BUILD_TLS_MODEL=global-dynamic \
    -DXercesC_INCLUDE_DIR=$INSTALL_DIR/xerces-c-3.3.0/include \
    -DXercesC_LIBRARY=$INSTALL_DIR/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_LIBRARY_RELEASE=/mnt/spack_hpl_manila/opt/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_LIBRARY_DEBUG=/mnt/spack_hpl_manila/opt/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_VERSION=3.3.0 \
    -DCMAKE_CXX_FLAGS="-ftls-model=global-dynamic -fno-gnu-unique -fPIC" \
    -DCMAKE_C_FLAGS="-ftls-model=global-dynamic -fno-gnu-unique -fPIC" \
    -DCMAKE_BUILD_TYPE=Release \
    $CLONE_DIR/geant4 

sudo make -j8
sudo make -j8 install
add_build $INSTALL_DIR/geant4

#install DD4hep
cd $CLONE_DIR
git clone https://github.com/AIDASoft/DD4hep.git
cd DD4hep
git checkout v01-32-01

#Use apt boost
unset BOOST_ROOT
unset BOOST_INCLUDEDIR
unset BOOST_LIBRARYDIR
export PATH=$(echo $PATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)
export LIBRARY_PATH=$(echo $LIBRARY_PATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)
export CPATH=$(echo $CPATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)
export CPLUS_INCLUDE_PATH=$(echo $CPLUS_INCLUDE_PATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)
export CMAKE_PREFIX_PATH=$(echo $CMAKE_PREFIX_PATH | tr ':' '\n' | grep -v 'boost_1_' | paste -sd ':' -)

mkdir -p $INSTALL_DIR/DD4hep $BUILD_DIR/DD4hep
cd $BUILD_DIR/DD4hep
sudo rm -rf CMakeCache.txt CMakeFiles $CLONE_DIR/DD4hep/CMakeCache.txt $CLONE_DIR/DD4hep/CMakeFiles
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/DD4hep \
    -DDD4HEP_USE_GEANT4=ON -DBUILD_DOCS=OFF \
    -DBoost_NO_BOOST_CMAKE=OFF \
    -DDD4HEP_USE_LCIO=ON \
    -DBUILD_TESTING=ON \
    -DXercesC_INCLUDE_DIR=$INSTALL_DIR/xerces-c-3.3.0/include \
    -DXercesC_LIBRARY=$INSTALL_DIR/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_LIBRARY_RELEASE=$INSTALL_DIR/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_LIBRARY_DEBUG=$INSTALL_DIR/xerces-c-3.3.0/lib/libxerces-c.so \
    -DXercesC_VERSION=3.3.0 \
    -DGeant4_DIR=$INSTALL_DIR/geant4 \
    -DCMAKE_CXX_FLAGS="-ftls-model=global-dynamic -fno-gnu-unique -fPIC" \
    -DCMAKE_C_FLAGS="-ftls-model=global-dynamic -fno-gnu-unique -fPIC" \
    -DCMAKE_BUILD_TYPE=Release \
     $CLONE_DIR/DD4hep
sudo make -j8
sudo make -j8 install
add_build $INSTALL_DIR/DD4hep


#instll acts
# mkdir -p $CLONE_DIR/zips
# cd $CLONE_DIR/zips
# wget https://github.com/acts-project/acts/archive/refs/tags/v44.2.0.zip
# unzip v44.2.0.zip -d ..

cd $CLONE_DIR
git clone https://github.com/acts-project/acts
cd acts 
git checkout v44.2.0

source thisroot.sh
export DD4hep_DIR=$INSTALL_DIR/DD4hep
export HepMC3_DIR=$INSTALL_DIR/HepMC3
export Pythia8_DIR=$INSTALL_DIR/pythia8313  


export CPLUS_INCLUDE_PATH=$INSTALL_DIR/DD4hep/include:$CPLUS_INCLUDE_PATH
export CPATH=$INSTALL_DIR/DD4hep/include:$CPATH
export CXXFLAGS="$CXXFLAGS -I$INSTALL_DIR/DD4hep/include -I$INSTALL_DIR/HepMC3/include -I$INSTALL_DIR/Pythia8313/include"
export CPPFLAGS="$CPPFLAGS -I$INSTALL_DIR/DD4hep/include -I$INSTALL_DIR/HepMC3/include -I$INSTALL_DIR/Pythia8313/include"
export LD_LIBRARY_PATH=/mnt/spack_hpl_manila/opt/Pythia8/lib:/mnt/spack_hpl_manila/opt/DD4hep/lib:/mnt/spack_hpl_manila/opt/HepMC3/lib:$LD_LIBRARY_PATH
mkdir -p $INSTALL_DIR/acts $BUILD_DIR/acts
cd $BUILD_DIR/acts

sudo apt -y update
sudo apt -y install python3-pip python3-venv
sudo apt -y install python3-hatchling
sudo apt -y install python3-numpy python3-sympy python3-pip
# Create a local virtual environment
python3 -m venv acts_venv
# Activate it
source acts_venv/bin/activate
# Upgrade pip inside the venv
pip install --upgrade pip
# Install required packages
pip install sympy numpy particle hatchling codegen pybind11
# sudo apt -y install python3-pybind11 python3-numpy python3-particle
export PATH=~/acts_venv/bin:$PATH
export PYTHON_EXECUTABLE=~/acts_venv/bin/python3
export PYTHONPATH=$BUILD_DIR/acts/Core/src/Propagator/codegen:$PYTHONPATH

sudo rm -rf CMakeCache.txt CMakeFiles $CLONE_DIR/acts/CMakeCache.txt $CLONE_DIR/acts/CMakeFiles
cmake $CLONE_DIR/acts \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/acts \
    -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
    -DACTS_USE_SYSTEM_LIBS=OFF \
    -DACTS_USE_SYSTEM_NLOHMANN_JSON=OFF \
    -DACTS_BUILD_FATRAS_GEANT4=ON \
    -DACTS_BUILD_PLUGIN_GEANT4=ON \
    -DACTS_BUILD_PLUGIN_ROOT=ON \
    -DACTS_BUILD_PLUGIN_DD4HEP=ON \
    -DACTS_BUILD_ODD=ON \
    -DACTS_BUILD_EXAMPLES_PYTHON_BINDINGS=ON \
    -DACTS_BUILD_EXAMPLES_DD4HEP=ON \
    -DACTS_BUILD_EXAMPLES_PYTHIA8=ON \
    -DACTS_USE_SYSTEM_PYBIND11=OFF \
    -DDD4hep_DIR=$INSTALL_DIR/DD4hep \
    -DHepMC3_DIR=$INSTALL_DIR/HepMC3 \
    -DPythia8_DIR=$INSTALL_DIR/pythia8313 \
    -DCMAKE_BUILD_TYPE=Release

cmake --build $BUILD_DIR/acts -j8
source $BUILD_DIR/acts/install_this_acts_withdeps.sh

# sudo make -j8
# sudo make -j8 install
add_build $INSTALL_DIR/acts

python3 ../../acts/Examples/Scripts/Python/full_chain_odd_sc25.py --ttbar --no-output-root --onlyWriteVertices


