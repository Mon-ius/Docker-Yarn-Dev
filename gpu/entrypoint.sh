#!/bin/sh

set -e

NVMOD=/sys/module/nvidia/version

if [ -f $NVMOD ]; then
    NVDR_VER=$(cat $NVMOD)
    MAJOR_VER="${NVDR_VER%.*}"
    echo "Host driver detected ${NVDR_VER} from NVIDIA version file $NVMOD"
    echo "Installing major version driver: ${MAJOR_VER}"
else
    NVDR_VER=580.65.06
    MAJOR_VER="${NVDR_VER%.*}"
    echo "[WARN] Installing default major version driver : ${MAJOR_VER}"
fi

NVLIST="https://www.nvidia.com/en-us/drivers/unix/linux-amd64-display-archive"
NVDR_VERSION=$(curl -fsSL "$NVLIST" | grep -oP "Version: \K${MAJOR_VER}\.\d+" | head -n 1)

DRIVER="https://us.download.nvidia.com/XFree86/Linux-x86_64/$NVDR_VERSION/NVIDIA-Linux-x86_64-$NVDR_VERSION.run"
curl -fsSL "$DRIVER" -o cuda-driver.run && chmod +x cuda-driver.run
./cuda-driver.run --accept-license --ui=none --no-kernel-module --no-questions

cat <<'EOF' | tee /opt/build.sh
#!/bin/dash

BUILD_DIR="build"
CUDA_BIN="/usr/local/cuda/bin/nvcc"
CMAKE_PREFIX_PATH="/opt/torch/libtorch"
CXX_COMPILER="g++"

rm -rf $BUILD_DIR

CUDACXX=$CUDA_BIN cmake -S . -B $BUILD_DIR \
    -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER

cmake --build $BUILD_DIR -j$(nproc) && ./$BUILD_DIR/cuda-test
EOF

cat <<'EOF' | tee /opt/CMakeLists.txt
    cmake_minimum_required(VERSION 3.25)
    project(cuda-test LANGUAGES CXX)

    find_package(CUDAToolkit REQUIRED)
    find_package(Torch REQUIRED)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TORCH_CXX_FLAGS}")

    add_executable(cuda-test cuda-test.cu)
    target_link_libraries(cuda-test "${TORCH_LIBRARIES}" CUDA::cudart)
    set_property(TARGET cuda-test PROPERTY CXX_STANDARD 17)
EOF

cat <<'EOF' | tee /opt/cuda-test.cu
#include <iostream>
#include <cuda_runtime.h>
#include <ATen/ATen.h>

int main() {
    auto option = at::device(at::kCUDA);
    auto device = option.device();
    if (!device.is_cuda()) {
        std::cout << "Not a CUDA device" << std::endl;
        exit(0);
    }

    int device_index = device.index(); 
    std::cout << "CUDA device index: " << device_index << std::endl;

    cudaDeviceProp _prop;
    cudaGetDeviceProperties(&_prop, 0);

    std::cout << "Device " << device << ": " << _prop.name << std::endl;
    std::cout << "  Max threads per block:  " << _prop.maxThreadsPerBlock << std::endl;
    std::cout << "  Max block dimensions:   (" 
            << _prop.maxThreadsDim[0] << ", " 
            << _prop.maxThreadsDim[1] << ", " 
            << _prop.maxThreadsDim[2] << ")" << std::endl;
    std::cout << "  Max grid dimensions:    (" 
            << _prop.maxGridSize[0] << ", " 
            << _prop.maxGridSize[1] << ", " 
            << _prop.maxGridSize[2] << ")" << std::endl;
}
EOF

echo "cd /opt && sh /opt/build.sh" > /usr/bin/cuda-test && chmod +x /usr/bin/cuda-test

exec "$@"