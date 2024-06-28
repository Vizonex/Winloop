from libc.stdint cimport int8_t, uint64_t


cdef extern from "winsock2.h" nogil:
    """
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
    """

    unsigned long ntohl(unsigned long)
    unsigned long htonl(unsigned long)
    unsigned long ntohs(unsigned long)

    ctypedef unsigned long long UINT_PTR
    ctypedef UINT_PTR SOCKET

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

    int setsockopt(SOCKET socket, int level, int option_name,
                   const void *option_value, int option_len)


cdef extern from "io.h" nogil:
    int  _write(int _FileHandle, const void *_Buf, unsigned int _MaxCharCount)
    void _exit(int status)


cdef extern from "includes/compat.h" nogil:

    cdef int EWOULDBLOCK

    cdef int PLATFORM_IS_APPLE
    cdef int PLATFORM_IS_LINUX
    cdef int PLATFORM_IS_WINDOWS

    struct epoll_event:
        # We don't use the fields
        pass

    int EPOLL_CTL_DEL
    int epoll_ctl(int epfd, int op, int fd, epoll_event *event)

    struct sockaddr_un:
        unsigned short sun_family
        char*          sun_path
        # ...

    object MakeUnixSockPyAddr(sockaddr_un *addr)

    int socketpair(int domain, int type, int protocol, int socket_vector[2])

    int write(int fd, const void *buf, unsigned int count)

cdef extern from "includes/fork_handler.h":

    uint64_t MAIN_THREAD_ID
    int8_t MAIN_THREAD_ID_SET
    ctypedef void (*OnForkHandler)()
    void handleAtFork()
    void setForkHandler(OnForkHandler handler)
    void resetForkHandler()
    void setMainThreadID(uint64_t id)

    int pthread_atfork(
        void (*prepare)(),
        void (*parent)(),
        void (*child)())
