# Winloop
An Alternative library for uvloop compatability with windows Because let's face it. Window's python asyncio can be garabage at times. 
I never really liked the fact that I couldn't make anything run faster escpecially when you have fiber internet connections in place. 
It always felt dissapointing when libuv is avalible on windows but doesn't have uvloop compatability. 
So I went ahead and downloaded the uvloop source code and I'm currently modifying alot of parts to make it windows compatable. 

This library is still being worked on but I wanted to make sure for right now that the name of this library has been claimed by me. 
I will not be posting any code yet until I have resolved licensing with the uvloop devs. 

The main differences will be some name changes incase there's any problems and the disabling of non-windows compatable apis...

## Current Progress

This has not been finished yet but as of right now I have done all the followings to try and get this to work 
- disabled epoll because Windows cannot truely fork proccesses. 
- disabled pthreads due to the same problem. and infact the api called pthread_atfork() so __install_atfork() is not there anymore...

Luckily managed to get the library to compile by invoking the following libraries 
- uv_a.lib (dlls are slow, so I'm going static)
- Ws2_32.lib
- Advapi32.lib
- iphlpapi.lib
- WSock32.lib
- Userenv.lib
- User32.lib
