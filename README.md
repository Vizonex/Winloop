![Alt text](https://raw.githubusercontent.com/Vizonex/Winloop/main/winloop.png)

# Winloop
An Alternative library for uvloop compatability with windows Because let's face it. Window's python asyncio can be garabage at times. 
I never really liked the fact that I couldn't make anything run faster escpecially when you have fiber internet connections in place. 
It always felt dissapointing when libuv is avalible on windows but doesn't have uvloop compatability. 
So I went ahead and downloaded the uvloop source code and I'm currently modifying alot of parts to make it windows compatable. 

This library is still being worked on but I wanted to make sure for right now that the name of this library has been claimed by me. 
I will not be posting any code yet until I have resolved licensing with the uvloop devs (No Longer required see bottom paragraph in updates).

The main differences will be some name changes incase there's any problems and the disabling of non-windows compatable apis...

## Current Progress

This has not been finished yet but as of right now I have done all the followings to try and get this to work 
- disabled epoll because Windows cannot truely fork proccesses. 
- disabled pthreads due to the same problem and infact the C function called pthread_atfork() is not avalible on Windows so __install_atfork() is not there anymore...

Luckily managed to get the library to compile by invoking the following libraries 
- uv_a.lib (dlls are slow, so I'm going static)
- Ws2_32.lib
- Advapi32.lib
- iphlpapi.lib
- WSock32.lib
- Userenv.lib
- User32.lib


## Updates

Made my own socketpair function in C inspired by libcurl's version for winloop to use so that the current ways that the library does polling wouldn't break.
I also replaced `uv_poll_init` with `uv_pool_init_socket` as a temporary monkey_patch/solution. 


- As of May 18th 2023 I have gotten winloop finally working but it will require some more tests , I plan to do those within a couple of days...

- As of May 20th 2023 We are having problems with fixing some of the implementations on `Winloop/handles/process.pyx` `UVProccess._init` has to be reworked because windows can only spawn a proccess not fork one... In fact all Unix parts may need to be redone. But luckily we have a headstart and shouldn't be to difficult to implement because we have the base-work layed out for us so that we don't have to reinvent the wheel.

- I will be trying to get premission from the magicstack Team if I can just go ahead and upload my modfied cython files soon to this repository. But for now I will be soon uploading my `socketpair.h` function based on where I have my `setup.py` file stored which I will also be uploading today. You have my permission to use the code for socketpair because it's the only file where I had to write in a bunch of newer things... It's likely my code will be `cygwin` compatable soon so that's a start in the right direction going forward...
- On 5/21/2023 I pointed out that we no longer will have licensing problems and I'll just need to provide the original Apache License alongside my own and all the parts that I modify will be MIT Licensed... https://github.com/MagicStack/uvloop/issues/536

- If you wish to compile this project yourslef and test it be sure to get yourself a copy of uvloop's test suite (I'll see about likely modifying some parts since the childwatcher used in uvloop's test suite doesn't exist...). I also might be making a discord server in the future that will be dedicated to making and mainting this library if we can get enough people to participate so that we can handle this library a little bit more efficiently. Feel free to fork this repository and to make pull requests as well. We will need all the help we can get...

- Currently as of 5/30/2023 There seems to be serveral problems that I cannot directly diagnose and they are pretty vague but someone will need to come up with a way to spawn proccesses instead of forking them which may need some fixing since I'm still am seeing the same `-4058` error response. the problem can be found in `process.pyx` I have not found a propper solution yet because it is so hard to find. help would be appreciated. 

- After a long time of digging I accidently came accross pyuv https://github.com/saghul/pyuv which is pefrect we should be able to find out alot of ways to implement this code now, THANK YOU FOR EXISTING, I APPRECIATE IT! I'll be downloading this library since it has windows support but mainly will be using it for figuring out how to implement the rest of these things that I have questions about for figuring how how we should come in and approch the rest of these problems...

- Update it works but the reason why it gave me a `-4058` is because it wants a `File`! Apparently the shell commands are not files but `rundll32` is. Someone is going to have to explain to me why this is the case and why we cannot normally invoke shell commands and what our workaround for this issue is going to be.  

- 5/31/2023 I FIXED IT I'll now move onto TCP Connections or other parts that need checking. All I can say is that figuring this all out was HELL! 

- As of now 6/2/2023 I have figured out that tcp connections currently are giving me bad file descriptor errors so that will need to be fixed escpecially in `streams.pyx`. I have now uploaded a video to my youtube channel in the hopes to get others intrested in contributing to something this incredible and big https://youtu.be/tz9RYJ6aBZ8 

- 6/3/2023 , I've fixed TCP Connections and it seems to be working ok as well as SSL for now... I did the following once I've used `install()`
```python
from winloop import install
import aiohttp
import asyncio 
# Seems to work just fine with ssl as well. Didn't expect for ssl to also work at all along side tcp connections so that's nice :)
# Less code to have to be changed is always a pleasent thing.
async def main():
    async with aiohttp.ClientSession("https://httpbin.org") as client:
        async with client.get("/ip") as resp:
            print(await resp.json())
if __name__ == "__main__"
    install()
    asyncio.run(main())
  ```
  No doubt that this will still require some heavy stress tests before we can just call it good but glad to see that progress is coming along so greatly :) 
