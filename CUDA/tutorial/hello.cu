//#include <stdio.h>
#include<iostream>
__global__ void cuda_hello(){
    printf("Hello World from GPU!\n");
	//std::cout << "Hello World from GPU!\n" << std::endl;
}

int main() {
    cuda_hello<<<1,1>>>(); 
    return 0;
}
