#include <semaphore.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>

int main(int argc, char **argv)
{
  int fd, i,count=0,nloop=10,zero=0,*ptr;
  sem_t mutex;

  //open a file and map it into memory

  fd = open("log.txt",O_RDWR|O_CREAT,S_IRWXU);
  write(fd,&zero,sizeof(int));
  ptr = mmap(NULL,sizeof(int),PROT_READ |PROT_WRITE,MAP_SHARED,fd,0);
  close(fd);

  /* create, initialize semaphore */
  if( sem_init(&mutex,1,1) < 0)
    {
      perror("semaphore initilization");
      exit(0);
    }
  if (fork() == 0) { /* child process*/
    for (i = 0; i < nloop; i++) {
      sem_wait(&mutex);
      printf("child entered crititical section: %d\n", (*ptr)++);
      sleep(2);
      printf("child leaving critical section\n");
      sem_post(&mutex);
      sleep(1);
    }
    exit(0);
  } else {
  /* back to parent process */
    for (i = 0; i < nloop; i++) {
      sem_wait(&mutex);
      printf("parent entered critical section: %d\n", (*ptr)++);
      sleep(2);
      printf("parent leaving critical section\n");
      sem_post(&mutex);
      sleep(1);
    }
  }
  exit(0);
}
