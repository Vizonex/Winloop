DEF UV_STREAM_RECV_BUF_SIZE = 256000  # 250kb

DEF FLOW_CONTROL_HIGH_WATER = 64  # KiB
DEF FLOW_CONTROL_HIGH_WATER_SSL_READ = 256  # KiB
DEF FLOW_CONTROL_HIGH_WATER_SSL_WRITE = 512  # KiB

DEF DEFAULT_FREELIST_SIZE = 250
DEF DNS_PYADDR_TO_SOCKADDR_CACHE_SIZE = 2048

DEF DEBUG_STACK_DEPTH = 10


DEF __PROCESS_DEBUG_SLEEP_AFTER_FORK = 1


DEF LOG_THRESHOLD_FOR_CONNLOST_WRITES = 5


# Number of seconds to wait for SSL handshake to complete
# The default timeout matches that of Nginx.
DEF SSL_HANDSHAKE_TIMEOUT = 60.0
# Number of seconds to wait for SSL shutdown to complete
# The default timeout mimics lingering_time
DEF SSL_SHUTDOWN_TIMEOUT = 30.0
DEF SSL_READ_MAX_SIZE = 256 * 1024




# # Cython's DEF Keywords are DEPRECATED, This is a workaround, I'll make a pull request for uvloop to do the same - Vizonex 

# cdef extern from *:
#     """
#     #define UV_STREAM_RECV_BUF_SIZE 256000
#     #define FLOW_CONTROL_HIGH_WATER 64 
#     #define FLOW_CONTROL_HIGH_WATER_SSL_READ 256 
#     #define FLOW_CONTROL_HIGH_WATER_SSL_WRITE 512 

#     #define DEFAULT_FREELIST_SIZE 250
#     #define DNS_PYADDR_TO_SOCKADDR_CACHE_SIZE 2048

#     #define DEBUG_STACK_DEPTH 10
    
#     #define __PROCESS_DEBUG_SLEEP_AFTER_FORK 1
#     #define LOG_THRESHOLD_FOR_CONNLOST_WRITES 5
#     #define SSL_HANDSHAKE_TIMEOUT 60.0
#     #define SSL_SHUTDOWN_TIMEOUT 30.0
#     #define SSL_READ_MAX_SIZE 256 * 1024
#     """

#     int UV_STREAM_RECV_BUF_SIZE  

#     int FLOW_CONTROL_HIGH_WATER  # KiB
#     int FLOW_CONTROL_HIGH_WATER_SSL_READ  # KiB
#     int FLOW_CONTROL_HIGH_WATER_SSL_WRITE  # KiB

#     int DEFAULT_FREELIST_SIZE 
#     int DNS_PYADDR_TO_SOCKADDR_CACHE_SIZE

#     int DEBUG_STACK_DEPTH 


#     int __PROCESS_DEBUG_SLEEP_AFTER_FORK


#     int LOG_THRESHOLD_FOR_CONNLOST_WRITES


#     # Number of seconds to wait for SSL handshake to complete
#     # The default timeout matches that of Nginx.
#     float SSL_HANDSHAKE_TIMEOUT
#     # Number of seconds to wait for SSL shutdown to complete
#     # The default timeout mimics lingering_time
#     float SSL_SHUTDOWN_TIMEOUT
#     int SSL_READ_MAX_SIZE



