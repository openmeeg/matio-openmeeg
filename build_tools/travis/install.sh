
mkdir build
cd build

cmake  \
    -DMAT73:BOOL=$MAT73 \
    ..

make
