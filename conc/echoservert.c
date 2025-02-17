/*
 * echoservert.c - A concurrent echo server using threads
 */
/* $begin echoservertmain */
#include "csapp.h"

void echo(int connfd);
void *thread(void *vargp);

int main(int argc, char **argv) {
  int listenfd, *connfdp;
  socklen_t clientlen;
  struct sockaddr_storage clientaddr;
  pthread_t tid;

  if (argc != 2) {
    fprintf(stderr, "usage: %s <port>\n", argv[0]);
    exit(0);
  }
  listenfd = Open_listenfd(argv[1]);

  while (1) {
    clientlen = sizeof(struct sockaddr_storage);
    connfdp = Malloc(sizeof(int));  // line:conc:echoservert:beginmalloc
    *connfdp = Accept(listenfd, (SA *)&clientaddr,
                      &clientlen);  // line:conc:echoservert:endmalloc
    Pthread_create(&tid, NULL, thread, connfdp);
  }
}

/* Thread routine */
void *thread(void *vargp) {
  /*
  ignore this paragraph: maybe kernel schedule thread before related `Accept`
  return, then dereference may throw error later when using its dereferenced
  later (maybe longer if shedule too late)

  here `Accept` blocks, so `Pthread_create` must run after *connfdp is valid and
  then main thread and peer thread run concurrently.
  */
  int connfd = *((int *)vargp);
  Pthread_detach(pthread_self());  // line:conc:echoservert:detach
  Free(vargp);                     // line:conc:echoservert:free
  echo(connfd);
  Close(connfd);
  return NULL;
}
/* $end echoservertmain */
