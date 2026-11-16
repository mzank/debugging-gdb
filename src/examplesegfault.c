#include <stdio.h>
#include <stdlib.h>

void modify(int **ptr)
{
    if (ptr == nullptr || *ptr == nullptr)
        return;

    if (**ptr % 2)
        *ptr = nullptr;
}

void calculate(int *ptr)
{
    modify(&ptr);
    *ptr = 99;
}

int main()
{
    int number = 4;
    int *data = &number;

    calculate(data);

    calculate(data);

    return EXIT_SUCCESS;
}
