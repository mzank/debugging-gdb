#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <format>
#include <iostream>
#include <numeric>
#include <ranges>
#include <vector>

constexpr unsigned int vec_size{999};
constexpr unsigned int print_size{10};

int main()
{
    std::cout << std::format("Vector size vec_size = {:4d}\n", vec_size);

#ifdef _OPENACC
    std::cout << "OpenACC version: " << _OPENACC << '\n';
#else
    std::cout << "OpenACC is not enabled.\n";
#endif

    std::vector<float> A(vec_size, 0.0f);
    std::vector<float> B(vec_size, 0.0f);
    std::vector<float> C(vec_size, 0.0f);

    // Initialize vectors
    std::iota(A.begin(), A.end(), 0.0f);
    std::ranges::transform(std::views::iota(0u, vec_size), B.begin(),
                           [](unsigned int i)
                           { return static_cast<float>(i * 2); });

    std::puts("------------- OpenACC GPU vector addition ---------");
    float const *A_ptr{A.data()};
    float const *B_ptr{B.data()};
    float *C_ptr{C.data()};

#pragma acc parallel loop copyin(A_ptr[0 : vec_size], B_ptr[0 : vec_size]) copyout(C_ptr[0 : vec_size])
    for (unsigned int i = 0; i < vec_size; ++i)
    {
        C_ptr[i] = A_ptr[i] + B_ptr[i];
    }

    for (unsigned int i : std::views::iota(0u, std::min(vec_size, print_size)))
    {
        std::cout << std::format("{:4.1f} + {:4.1f} = {:4.1f}\n",
                                 A[i], B[i], C[i]);
    }
    std::puts("---------------------------------------------------");

    return EXIT_SUCCESS;
}
