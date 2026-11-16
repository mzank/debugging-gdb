#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <format>
#include <iostream>
#include <numeric>
#include <ranges>

#include <hip/hip_runtime.h>

constexpr unsigned int vec_size{999};
constexpr unsigned int print_size{10};

// Error checking
inline void hipCheck(hipError_t err)
{
    if (err != hipSuccess)
    {
        std::cerr << "HIP error: "
                  << hipGetErrorString(err) << '\n';
        std::exit(EXIT_FAILURE);
    }
}

// One work-item per element
__global__ void vectorAdd(
    const float *__restrict__ A,
    const float *__restrict__ B,
    float *__restrict__ C,
    unsigned int size)
{
    unsigned int const i{blockIdx.x * blockDim.x + threadIdx.x};

    if (i < size)
    {
        C[i] = A[i] + B[i];
    }
}

// Grid-stride loop
__global__ void vectorAddStride(
    const float *__restrict__ A,
    const float *__restrict__ B,
    float *__restrict__ C,
    unsigned int size)
{
    unsigned int const tid{blockIdx.x * blockDim.x + threadIdx.x};
    unsigned int const stride{blockDim.x * gridDim.x};

    for (unsigned int i = tid; i < size; i += stride)
    {
        C[i] = A[i] + B[i];
    }
}

int main()
{
    std::cout << std::format("Vector size vec_size = {:4d}\n", vec_size);

    std::array<float, vec_size> h_A{}, h_B{}, h_C{}, h_C_stride{};
    float *d_A{}, *d_B{}, *d_C{}, *d_C_stride{};

    std::size_t const size{vec_size * sizeof(float)};

    // Initialize vectors
    std::iota(h_A.begin(), h_A.end(), 0.0f);
    std::ranges::transform(std::views::iota(0u, vec_size), h_B.begin(),
                           [](unsigned int i)
                           { return static_cast<float>(i * 2); });

    // Allocate device memory
    hipCheck(hipMalloc(&d_A, size));
    hipCheck(hipMalloc(&d_B, size));
    hipCheck(hipMalloc(&d_C, size));
    hipCheck(hipMalloc(&d_C_stride, size));

    // Copy data to GPU
    hipCheck(hipMemcpy(d_A, h_A.data(), size, hipMemcpyHostToDevice));
    hipCheck(hipMemcpy(d_B, h_B.data(), size, hipMemcpyHostToDevice));

    // Initialize vector
    hipCheck(hipMemset(d_C, 0, vec_size * sizeof(float)));
    hipCheck(hipMemset(d_C_stride, 0, vec_size * sizeof(float)));

    std::puts("------------- One work-item per element --------------");
    // Launch kernel
    constexpr unsigned int threads_per_block{67u};
    constexpr unsigned int nr_blocks{
        (vec_size + threads_per_block - 1u) / threads_per_block};
    vectorAdd<<<nr_blocks, threads_per_block>>>(d_A, d_B, d_C, vec_size);

    hipCheck(hipGetLastError());
    hipCheck(hipDeviceSynchronize());

    // Copy results back to CPU
    hipCheck(hipMemcpy(h_C.data(), d_C, size, hipMemcpyDeviceToHost));

    std::puts("Print only first rows:");
    for (unsigned int i : std::views::iota(0u, std::min(vec_size, print_size)))
    {
        std::cout << std::format("{:4.1f} + {:4.1f} = {:4.1f}\n",
                                 h_A[i], h_B[i], h_C[i]);
    }
    std::puts("---------------------------------------------------");

    std::puts("------------- Grid-stride loop --------------------");
    // Launch kernel
    constexpr unsigned int threads_per_block_stride{71u};
    constexpr unsigned int nr_blocks_stride{5u};
    vectorAddStride<<<nr_blocks_stride, threads_per_block_stride>>>(d_A, d_B, d_C_stride, vec_size);

    hipCheck(hipGetLastError());
    hipCheck(hipDeviceSynchronize());

    // Copy results back to CPU
    hipCheck(hipMemcpy(h_C_stride.data(), d_C_stride, size, hipMemcpyDeviceToHost));

    std::puts("Print only first rows:");
    for (unsigned int i : std::views::iota(0u, std::min(vec_size, print_size)))
    {
        std::cout << std::format("{:4.1f} + {:4.1f} = {:4.1f}\n",
                                 h_A[i], h_B[i], h_C_stride[i]);
    }
    std::puts("---------------------------------------------------");

    // Free device memory
    hipCheck(hipFree(d_A));
    hipCheck(hipFree(d_B));
    hipCheck(hipFree(d_C));
    hipCheck(hipFree(d_C_stride));

    return EXIT_SUCCESS;
}
