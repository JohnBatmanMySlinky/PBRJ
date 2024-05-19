cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/Users/johnmyslinski/.julia/artifacts/eb9099719fd3959a5d4f2e7f445657537479e22c /Users/johnmyslinski/Documents/PBRJ/src/nanovdb
cmake --build . --config Release
julia julia_part.jl