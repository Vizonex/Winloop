from libc.stdint cimport int8_t, uint64_t


cdef extern from "winsock2.h":
    """
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif    
    """
    
    
    ctypedef unsigned long long UINT_PTR
    ctypedef UINT_PTR SOCKET 

    # TODO (Vizonex) Verify that these all are actually existant on windows...
    struct sockaddr:
        unsigned short sa_family
        char           sa_data[14]
    
    struct addrinfo:
        int            ai_flags
        int            ai_family
        int            ai_socktype
        int            ai_protocol
        size_t         ai_addrlen
        sockaddr*      ai_addr
        char*          ai_canonname
        addrinfo*      ai_next

    struct sockaddr_in:
        unsigned short sin_family
        unsigned short sin_port
        # ...

    struct sockaddr_in6:
        unsigned short sin6_family
        unsigned short sin6_port
        unsigned long  sin6_flowinfo
        # ...
        unsigned long  sin6_scope_id

    struct sockaddr_storage:
        unsigned short ss_family
        # ...

    const char *gai_strerror(int errcode)

    # All except for one... luckily I did this one already...
    # int socketpair(int domain, int type, int protocol, int socket_vector[2])

    int setsockopt(SOCKET socket, int level, int option_name,
                   const void *option_value, int option_len)
    
    unsigned long ntohl(unsigned long)
    unsigned long ntohl(unsigned long)
    unsigned long htonl(unsigned long)
    unsigned long ntohs(unsigned long)
    
    # SOCKET_ERROR = -1 
    int SOCKET_ERROR

    # Added WSABUF for uv__try_write TCP Implementation more directly inside of cython...
    ctypedef struct WSABUF:
        char * buf
        unsigned long len


# The AtFork Implementation does not work and it is belived that windows already takes care of this...
# http://locklessinc.com/articles/pthreads_on_windows/

# I'll leave this code here just to show other programers what was needed to be removed 
# Windows cannot do pthread_atfork anyways...
# cdef extern from "pthread.h":
# 
#     int pthread_atfork(
#         void (*prepare)(),
#         void (*parent)(),
#         void (*child)())

cdef extern from "io.h" nogil:
    int  _write(int _FileHandle, const void *_Buf, unsigned int _MaxCharCount)
    void _exit(int status)

cdef extern from "context.h":
    int PLATFORM_IS_APPLE

# nfork_handler.h really just means "I don't do forking but I'm here for compatability reasons..."
cdef extern from "includes/nfork_handler.h":
    uint64_t MAIN_THREAD_ID
    int8_t MAIN_THREAD_ID_SET
    void setMainThreadID(uint64_t id)


# socketpair.h by Vizonex 
cdef extern from "socketpair.h" nogil:
    # I implemented this for windows because I wasn't 
    # going to let it stop me from making Winloop not possible...
    int socketpair(int domain, int type, int protocol, SOCKET socket_vector[2])
    

