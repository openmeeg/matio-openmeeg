if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    # Install some custom requirements on OS X
    $CXX --version

    if [ "$MAT73" == "ON" ]; then
        brew tap homebrew/science # a lot of cool formulae for scientific tools
        brew update && brew upgrade
        brew install hdf5
    fi

else
    if [ "$MAT73" == "ON" ]; then
        sudo apt-get -y install libhdf5-serial-dev
    fi
fi
