## Vizonex's Dev Jornal


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
if __name__ == "__main__":
    install()
    asyncio.run(main())
  ```
  No doubt that this will still require some heavy stress tests before we can just call it good but glad to see that progress is coming along so greatly :) 
 
 - 6/4/2023 Everything seems to be in order now including servers (Except for UDP because I haven't check that yet (It might work actually) but TCP works!) and I also fixed some other smaller details like signal functions. I'll try to turn this library into a python package shortly when I've added a few more commits. Once it has become a library I'll Modify this entire readme into learning how to install it using pip. I have no doubt that this is better than chat gpt or all those other inventions. Really Winloop is the future! I guess the most staisfying part of all is fixing things on your own. You will struggle but eventually you will make something useful. I hope this incredible month long journey has taught you that you can accomplish great things. - Vizonex

- 6/5/2023 Currently Running tests on All possible to run testsuites and I'm seeing really promising results escpecially with aiohttp. 
I made a new test to cover UDP due to the Unix Heavy testsuite and here is what I've tested so far. (also I disabed childwatcher because windows doesn't have those features)
- [x] test_base.py (All Passed Yes all 87 Passed 1 skipped because I don't have `fcntl` yet...)
- [x] test_fastapi.py (Works but it is not a unittest I'll upload this snippet of this code as a gist)
- [] test_pipes.py (Might be skipped , Seems very Unix Heavy)
- [] test_process_spawning.py (We know that Processes appear to work so I might skip this one because some of it is exteremely Unix heavy)
- [x] test_http.py (All Passed)
- [] test_signals.py (Haven't done yet but likely could be incompatable as well)
- [] test_sockets.py (Haven't ran it yet)
- [] test_sourcecode.py (Might Pass on this one just because not much was changed other than some names here and there...)
- [] test_fs_event.py (Haven't ran it yet but it could be incompatable)
- [] test_executors.py (Haven't ran it yet)
- [] test_unix.py (Obviously we can't do that so I'll Pass on it)
- [] test_dns.py (Should work here as well)
- [] In Other Places and everyday software (I've actually started using winloop on one of my Osint tools that harvests up User information that I haven't made public yet... (Works very well with Tor , I'm impressed with the fact that it hasn't broken down when digging up data from many different search engines), I'll try winloop on theHarvester https://github.com/laramies/theHarvester as well and report how fast it is when I get to doing it... I might plan on seeing if those developers/contributors actually want to start using this library that I modified from the uvloop devs over using the Windows selector event loop policy.)

Anyways I'm very close to setting up this python package, the last thing on my todo list is licensing and that's about it! 

- 6/9/2023 I am almost done with making the first pypi package and will likely have it done within a weeks time... I'll be letting the magicstack team know that users can use this library as an alternative from their setup.py as a pull-request/suggestion and I will be seeing if any of them also want to help with this project as well. If I'm lucky the first package will come out today or tomorrow. I'll need to test the installation from a virtual enviornment first but then after I'll start releasing the first beta version of this library along with a new readme , I'll archive this as "dev-journal.md" soon so that you can always go back and see what was accomplished.

- I just uploaded the pypi package under `winloop` but I had acciendly made a typo package called winloop.loop as well so I'll have to conatct pypi about getting that library removed. One license for Appache isn't showing up apparently so I'll have to get that one fixed as well...

- 6/15/2023 Winloop is already a sucess but there was an idea to go ahead and maybe see about merging winloop to uvloop so that the uvloop maintainers will be able to maintain the new branch. If we end up doing this I will like to see some votes maybe about the idea. 
## Reasons for why Merging Winloop to Uvloop would be a good idea
- Maitenece would be better and with an extra couple contriubtors like myself on hand we will be able to work with the Magicstak team on making uvloop avalible to all systems alike. 
- I would be able to stop having to do absolutely everything by myself and focus on other ideas and projects I had in mind in the future
That is if it actually succeeds at working...
## Cons
- Nobody decides that they want to try and merge something this big into uvloop since there's a couple of fallbacks that I had to do since windows is a competely 
different system from linux or apple.
- I'm mainly just worried about the task at hand as well as the fear that too many big changes would/could cause problems...
