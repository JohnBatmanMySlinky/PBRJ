PATH1=$(julia -e 'using CxxWrap; print(CxxWrap.prefix_path())')
PATH2=$(pwd)
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$PATH1 $PATH2 
cmake --build . --config Release
