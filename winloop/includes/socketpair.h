/*
License for socketpair.h because I'm nice - Vizonex

The MIT License (MIT)

Copyright © 2023 Vizonex

Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation 
files (the “Software”), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, 
publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:
The above copyright notice and this permission notice shall 
be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
OTHER DEALINGS IN THE SOFTWARE.
*/

/* Please Note this will only work on windows operating systems! Some things in my code will be changed 
at a fast pace in the future... */

#ifndef __SOCKET_PAIR_H__
#define __SOCKET_PAIR_H__

#define _WINSOCKAPI_    // stops windows.h including winsock.h
#include <windows.h>
#include <winsock2.h>
#include <stdlib.h>
#include <time.h>


/* Inspiration was taken from both of these libraries on how to implement this function...
https://github.com/ncm/selectable-socketpair/blob/master/socketpair.c 
AND https://github.com/curl/curl/blob/master/lib/socketpair.c
*/

char* WinLoopRandom(char* rnd, int size){
  srand((unsigned int)(time(0) >> 32));
  for (int i = 0; i < size; i++)
    rnd[i] = (char)(rand() >> 8);
  return rnd;
}

int WinLoopTimeout(unsigned long timeout){
  if (!timeout)
    return 0;
  if (timeout < 0){
    return -1;
  };
  Sleep(timeout);
  return 0;
}

/* enusres that no sockets are being blocked */
int non_block(SOCKET socket, unsigned int nonblock){
    unsigned long flags = nonblock ? 1UL : 0UL;
    return ioctlsocket(socket, FIONBIO, &flags);
}

/* Based on Libcurl's version but with a few modifications here and here... */
int WinLoopPoll(struct pollfd ufds[], unsigned int nfds, unsigned long timeout_ms){
    int r;
    int no_fds = 1;

    if (ufds){
      for (unsigned int i = 0; i < nfds; i++){
        if (ufds[i].fd == SOCKET_ERROR){
          no_fds = 0;
          break;
        }
      }
    }
    
    if (no_fds)
      /* Sleep it out... */
      WinLoopTimeout(timeout_ms);

    /* PLEASE WORK!! */
    struct timeval tvalue = {0,timeout_ms};
    r = select(0, NULL, NULL, NULL, &tvalue);
    /* A simple ternary shall do for now...*/
    return r ? 1 : 0;
    
}

/*
I wasn't just going to let this go , 
I had already spent hours on this in fact multiple weeks making this happen.
I wasn't just going to let this one function stop me from trashing my ideas, 
Anything that can make asyncio less shitty on windows is a win for me - Vizonex. 
*/


/* So I did this by looking at how libcurl and some libraries do it and I liked libcurl's implementation 
so I added my own twist to that algorythm... 

Now I understand exactly what it does! */


/* Makes 2 sockets by making a listener to test 
them both to make sure that they're alive and then once verified the listener is deleted and 
the two sockets (reader, writer) as added and returned to the socket_vectors. */
int socketpair(int domain, int type, int protocol, SOCKET socket_vector[2]){
    union {
        struct sockaddr_in inaddr;
        struct sockaddr addr;
    } a;

    /* we really don't need type or protocol but 
    I kept them here mostly for compatability reasons... */
    (void)type;
    (void)protocol;

    int addrlen = (int)sizeof(a.inaddr);

    SOCKET listener = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    if (listener == SOCKET_ERROR)
        return -1;

    struct pollfd pfd[1]; 

    memset(&a, 0, sizeof(a));
    a.inaddr.sin_family = AF_INET;
    a.inaddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    a.inaddr.sin_port = 0;

    int reuse = 1;

    /* Set a and b to SOCKET_Error Until they have been resolved */
    socket_vector[0] = socket_vector[1] = SOCKET_ERROR;

    (void)reuse;

    if (setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, (char *)&reuse, sizeof(reuse)) == -1)
      goto error;

    if(bind(listener, &a.addr, sizeof(a.inaddr)) == -1) 
      goto error;

    if(getsockname(listener, &a.addr, &addrlen) == -1 || addrlen < (int)sizeof(a.inaddr)) 
      goto error;

    if(listen(listener, 1) == -1) 
      goto error;

    socket_vector[0] = socket(AF_INET, SOCK_STREAM, 0);

    if(socket_vector[0] == SOCKET_ERROR) 
      goto error;

    if(connect(socket_vector[0], &a.addr, sizeof(a.inaddr)) == -1)
      goto error;
    
    /* No blocking allowed!! */
    if (non_block(listener,1) < 0)
      goto error;

    socket_vector[1] = accept(listener, NULL, NULL);
    if(socket_vector[1] == SOCKET_ERROR)
      goto error;

    pfd[0].fd = listener;
    pfd[0].events = POLLIN;
    pfd[0].revents = 0;

    char rnd[9];

    /* We're not libcurl so I implemented my own os_random() function here... */
    WinLoopRandom(rnd, 9);

    /* test reader and writer by sending them things back and forth... */
    send(socket_vector[0] , rnd, sizeof(rnd), 0);

    do {
     
      int nread;
      
      char check[sizeof(rnd)];
      char *p = &check[0];
      size_t s = sizeof(check);
      
      /* No flags are nessesary at the end...*/
      nread = recv(socket_vector[1], p, s, 0);
      if(nread == -1) {
        int sockerr = SOCKET_ERROR;
        if (WSAEWOULDBLOCK == sockerr)
          continue;
        goto error;
      }
      s -= nread;
      if(s) {
        p += nread;
        /* need more... */
        continue;
      }
      if(memcmp(rnd, check, sizeof(check)))
        goto error;

      /* We're done now because we figured out that both sockets are alive...*/
      goto finish;
      break;
    } while(1);
    
    error:
      /**/
      int e = WSAGetLastError();
      closesocket(listener);
      closesocket(socket_vector[0]);
      closesocket(socket_vector[1]);
      WSASetLastError(e);
      return -1;

    finish:
      /* we're now done using the listener and we can continue on back into Cython from here... */
      closesocket(listener);
      return 0;
}

/* This will likely be for replacing the file descriptor api call 
in loop.pyx I haven't decided on it yet but I wrote it incase I will be...*/
SOCKET get_socket_descriptor(){
  return socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
}



#endif /* __SOCKET_PAIR_H__ */