if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    # Install some custom requirements on OS X
    $CXX --version

else
    # Install some custom requirements on Linux
    # g++4.8.1
    if [ "$CXX" == "g++" ]; then sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test; fi

    # clang 3.4
    if [ "$CXX" == "clang++" ]; then sudo add-apt-repository -y ppa:h-rayflood/llvm; fi

    # To get recent hdf5 version:
    if [ "$MAT73" == "ON" ]; then
        sudo sed -i -e 's/trusty/vivid/g' /etc/apt/sources.list
    fi

    sudo apt-get update -qq

fi
