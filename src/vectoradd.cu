#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <format>
#include <iostream>
#include <numeric>
#include <ranges>

#include <cuda_runtime.h>

constexpr unsigned int vec_size{999};
constexpr unsigned int print_size{10};

// Error checking
inline void cudaCheck(cudaError_t err)
{
    if (err != cudaSuccess)
    {
        std::cerr << "CUDA error: "
                  << cudaGetErrorString(err) << '\n';
        std::exit(EXIT_FAILURE);
    }
}

// One thread per element
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
    cudaCheck(cudaMalloc(&d_A, size));
    cudaCheck(cudaMalloc(&d_B, size));
    cudaCheck(cudaMalloc(&d_C, size));
    cudaCheck(cudaMalloc(&d_C_stride, size));

    // Copy data to GPU
    cudaCheck(cudaMemcpy(d_A, h_A.data(), size, cudaMemcpyHostToDevice));
    cudaCheck(cudaMemcpy(d_B, h_B.data(), size, cudaMemcpyHostToDevice));

    // Initialize vector
    cudaCheck(cudaMemset(d_C, 0, vec_size * sizeof(float)));
    cudaCheck(cudaMemset(d_C_stride, 0, vec_size * sizeof(float)));

    std::puts("------------- One thread per element --------------");
    // Launch kernel
    constexpr unsigned int threads_per_block{67u};
    constexpr unsigned int nr_blocks{
        (vec_size + threads_per_block - 1u) / threads_per_block};
    vectorAdd<<<nr_blocks, threads_per_block>>>(d_A, d_B, d_C, vec_size);

    cudaCheck(cudaGetLastError());
    cudaCheck(cudaDeviceSynchronize());

    // Copy results back to CPU
    cudaCheck(cudaMemcpy(h_C.data(), d_C, size, cudaMemcpyDeviceToHost));

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

    cudaCheck(cudaGetLastError());
    cudaCheck(cudaDeviceSynchronize());

    // Copy results back to CPU
    cudaCheck(cudaMemcpy(h_C_stride.data(), d_C_stride, size, cudaMemcpyDeviceToHost));

    std::puts("Print only first rows:");
    for (unsigned int i : std::views::iota(0u, std::min(vec_size, print_size)))
    {
        std::cout << std::format("{:4.1f} + {:4.1f} = {:4.1f}\n",
                                 h_A[i], h_B[i], h_C_stride[i]);
    }
    std::puts("---------------------------------------------------");

    // Free device memory
    cudaCheck(cudaFree(d_A));
    cudaCheck(cudaFree(d_B));
    cudaCheck(cudaFree(d_C));
    cudaCheck(cudaFree(d_C_stride));

    return EXIT_SUCCESS;
}
