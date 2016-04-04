if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    # Install some custom requirements on OS X
    if [ "$MAT73" == "ON" ]; then
        brew tap homebrew/science # a lot of cool formulae for scientific tools
        brew update && brew upgrade
        brew install hdf5
    fi

else
    # # g++4.8.1
    if [ "$CXX" = "g++" ]; then sudo apt-get install -qq g++-4.8; fi
    if [ "$CXX" = "g++" ]; then export CXX="g++-4.8"; fi

    # clang 3.4
    if [ "$CXX" == "clang++" ]; then sudo apt-get install --allow-unauthenticated -qq clang-3.4; fi
    if [ "$CXX" == "clang++" ]; then export CXX="clang++-3.4"; fi

    if [ "$MAT73" == "ON" ]; then
        sudo apt-get -y install libhdf5-serial-dev
    fi

    wget https://s3.amazonaws.com/biibinaries/thirdparty/cmake-3.0.2-Linux-64.tar.gz
    tar -xzf cmake-3.0.2-Linux-64.tar.gz
    sudo cp -fR cmake-3.0.2-Linux-64/* /usr
    rm -rf cmake-3.0.2-Linux-64
    rm cmake-3.0.2-Linux-64.tar.gz
fi

mkdir build
cd build

cmake  \
    -DMAT73:BOOL=$MAT73 \
    ..

make
