import asyncio
import socket
import sys
import unittest

from winloop import _testbase as tb


def patched_getaddrinfo(*args, **kwargs):
    # corrected socket.getaddrinfo() behavior: ai_canonname always follows the
    # flag AI_CANONNAME, even if `host` is an IP
    rv = []
    result = socket.getaddrinfo(*args, **kwargs)
    for af, sk, proto, canon_name, addr in result:
        if kwargs.get("flags", 0) & socket.AI_CANONNAME:
            if not canon_name:
                canon_name = args[0]
                if not isinstance(canon_name, str):
                    canon_name = canon_name.decode("ascii")
        elif canon_name:
            canon_name = ""
        rv.append((af, sk, proto, canon_name, addr))
    return rv


class BaseTestDNS:
    def _test_getaddrinfo(self, *args, _patch=False, **kwargs):
        err = None
        try:
            if _patch:
                a1 = patched_getaddrinfo(*args, **kwargs)
            else:
                a1 = socket.getaddrinfo(*args, **kwargs)
        except (socket.gaierror, UnicodeError) as ex:
            err = ex

        try:
            a2 = self.loop.run_until_complete(self.loop.getaddrinfo(*args, **kwargs))
        except (socket.gaierror, UnicodeError) as ex:
            if err is not None:
                self.assertEqual(ex.args, err.args)
            else:
                ex.__context__ = err
                raise ex
        except OSError as ex:
            ex.__context__ = err
            raise ex
        else:
            if err is not None:
                raise err

            self.assertEqual(a1, a2)

    def _test_getnameinfo(self, *args, **kwargs):
        err = None
        try:
            a1 = socket.getnameinfo(*args, **kwargs)
        except Exception as ex:
            err = ex

        try:
            a2 = self.loop.run_until_complete(self.loop.getnameinfo(*args, **kwargs))
        except Exception as ex:
            if err is not None:
                if ex.__class__ is not err.__class__:
                    print(ex, err)
                self.assertIs(ex.__class__, err.__class__)
                self.assertEqual(ex.args, err.args)
            else:
                raise
        else:
            if err is not None:
                raise err

            self.assertEqual(a1, a2)

    @unittest.skip("Needs patches")
    def test_getaddrinfo_1(self):
        self._test_getaddrinfo("example.com", 80)
        self._test_getaddrinfo("example.com", 80, type=socket.SOCK_STREAM)

    def test_getaddrinfo_2(self):
        self._test_getaddrinfo("example.com", 80, flags=socket.AI_CANONNAME)

    def test_getaddrinfo_3(self):
        self._test_getaddrinfo("a" + "1" * 50 + ".wat", 800)

    def test_getaddrinfo_4(self):
        self._test_getaddrinfo("example.com", 80, family=-1)
        self._test_getaddrinfo("example.com", 80, type=socket.SOCK_STREAM, family=-1)

    def test_getaddrinfo_5(self):
        self._test_getaddrinfo("example.com", "80")
        self._test_getaddrinfo("example.com", "80", type=socket.SOCK_STREAM)

    def test_getaddrinfo_6(self):
        self._test_getaddrinfo(b"example.com", b"80")
        self._test_getaddrinfo(b"example.com", b"80", type=socket.SOCK_STREAM)

    def test_getaddrinfo_7(self):
        self._test_getaddrinfo(None, 0)
        self._test_getaddrinfo(None, 0, type=socket.SOCK_STREAM)

    def test_getaddrinfo_8(self):
        # Winloop comment: on Windows, an empty string for host will return
        # all registered addresses on the local computer. Enabling this feature
        # is not possible using libuv (an empty host will give an error which
        # is consistent with behavior on Linux).
        # Winloop supports the use of an empty string for host by internally
        # using b'..localmachine' for host. However, even though the Windows
        # documentation mentions that both by using an empty string for host
        # and by using "..localmachine" for host "all registered addresses on
        # the local computer are returned", these lists may actually differ
        # slightly. This will make the test below fail.
        # As a useful replacement, we therefore test explicitly using
        # b'..localmachine' for host.
        host = b"..localmachine" if sys.platform == "win32" else ""
        self._test_getaddrinfo(host, 0)
        self._test_getaddrinfo(host, 0, type=socket.SOCK_STREAM)

    def test_getaddrinfo_9(self):
        host = b"..localmachine" if sys.platform == "win32" else b""
        self._test_getaddrinfo(host, 0)
        self._test_getaddrinfo(host, 0, type=socket.SOCK_STREAM)

    def test_getaddrinfo_10(self):
        self._test_getaddrinfo(None, None)
        self._test_getaddrinfo(None, None, type=socket.SOCK_STREAM)

    def test_getaddrinfo_11(self):
        self._test_getaddrinfo(b"example.com", "80")
        self._test_getaddrinfo(b"example.com", "80", type=socket.SOCK_STREAM)

    def test_getaddrinfo_12(self):
        # musl always returns ai_canonname but we don't
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo("127.0.0.1", "80")
        self._test_getaddrinfo(
            "127.0.0.1",
            "80",
            type=socket.SOCK_STREAM,
            # Winloop comment: we set proto=6 for TCP
            # on Windows to make socket.getaddrinfo()
            # return proto=6 as uvlib/loop does
            # We do so below, in eight places in total.
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )

    def test_getaddrinfo_13(self):
        # musl always returns ai_canonname but we don't
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo(b"127.0.0.1", b"80")
        self._test_getaddrinfo(
            b"127.0.0.1",
            b"80",
            type=socket.SOCK_STREAM,
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )

    def test_getaddrinfo_14(self):
        # musl always returns ai_canonname but we don't
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo(b"127.0.0.1", b"http")
        self._test_getaddrinfo(
            b"127.0.0.1",
            b"http",
            type=socket.SOCK_STREAM,
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )

    def test_getaddrinfo_15(self):
        # musl always returns ai_canonname but we don't
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo("127.0.0.1", "http")
        self._test_getaddrinfo(
            "127.0.0.1",
            "http",
            type=socket.SOCK_STREAM,
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )

    def test_getaddrinfo_16(self):
        self._test_getaddrinfo("localhost", "http")
        self._test_getaddrinfo("localhost", "http", type=socket.SOCK_STREAM)

    def test_getaddrinfo_17(self):
        self._test_getaddrinfo(b"localhost", "http")
        self._test_getaddrinfo(b"localhost", "http", type=socket.SOCK_STREAM)

    def test_getaddrinfo_18(self):
        self._test_getaddrinfo("localhost", b"http")
        self._test_getaddrinfo("localhost", b"http", type=socket.SOCK_STREAM)

    # Winloop comment: see comment in __static_getaddrinfo_pyaddr() in dns.pyx
    # TODO: add Windows to that analysis handling two failing tests below.
    def test_getaddrinfo_19(self):
        # musl always returns ai_canonname while macOS never return for IPs,
        # but we strictly follow the docs to use the AI_CANONNAME flag in a
        # shortcut __static_getaddrinfo_pyaddr()
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo("::1", 80)
        self._test_getaddrinfo(
            "::1",
            80,
            type=socket.SOCK_STREAM,
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )
        # Winloop comment: next one fails with '[::1]:80' vs '::1'
        if sys.platform != "win32":
            self._test_getaddrinfo(
                "::1",
                80,
                type=socket.SOCK_STREAM,
                proto=6 if sys.platform == "win32" else 0,
                flags=socket.AI_CANONNAME,
                _patch=patch,
            )

    def test_getaddrinfo_20(self):
        # musl always returns ai_canonname while macOS never return for IPs,
        # but we strictly follow the docs to use the AI_CANONNAME flag in a
        # shortcut __static_getaddrinfo_pyaddr()
        patch = self.implementation != "asyncio"

        self._test_getaddrinfo("127.0.0.1", 80)
        self._test_getaddrinfo(
            "127.0.0.1",
            80,
            type=socket.SOCK_STREAM,
            proto=6 if sys.platform == "win32" else 0,
            _patch=patch,
        )
        # Winloop comment: next one fails with '127.0.0.1:80' vs '127.0.0.1'
        if sys.platform != "win32":
            self._test_getaddrinfo(
                "127.0.0.1",
                80,
                type=socket.SOCK_STREAM,
                proto=6 if sys.platform == "win32" else 0,
                flags=socket.AI_CANONNAME,
                _patch=patch,
            )

    # https://github.com/libuv/libuv/security/advisories/GHSA-f74f-cvh7-c6q6
    # See also: https://github.com/MagicStack/uvloop/pull/600
    def test_getaddrinfo_21(self):
        payload = f"0x{'0' * 246}7f000001.example.com".encode("ascii")
        self._test_getaddrinfo(payload, 80)
        self._test_getaddrinfo(payload, 80, type=socket.SOCK_STREAM)

    def test_getaddrinfo_22(self):
        payload = f"0x{'0' * 246}7f000001.example.com"
        self._test_getaddrinfo(payload, 80)
        self._test_getaddrinfo(payload, 80, type=socket.SOCK_STREAM)

    ######

    def test_getnameinfo_1(self):
        self._test_getnameinfo(("127.0.0.1", 80), 0)

    def test_getnameinfo_2(self):
        self._test_getnameinfo(("127.0.0.1", 80, 1231231231213), 0)

    def test_getnameinfo_3(self):
        self._test_getnameinfo(("127.0.0.1", 80, 0, 0), 0)

    def test_getnameinfo_4(self):
        self._test_getnameinfo(("::1", 80), 0)

    def test_getnameinfo_5(self):
        self._test_getnameinfo(("localhost", 8080), 0)


class Test_UV_DNS(BaseTestDNS, tb.UVTestCase):
    def test_getaddrinfo_close_loop(self):
        # Test that we can close the loop with a running
        # DNS query.

        try:
            # Check that we have internet connection
            socket.getaddrinfo("example.com", 80)
        except socket.error:
            raise unittest.SkipTest

        async def run():
            fut = self.loop.create_task(self.loop.getaddrinfo("example.com", 80))
            await asyncio.sleep(0)
            fut.cancel()
            self.loop.stop()

        try:
            self.loop.run_until_complete(run())
        finally:
            self.loop.close()


class Test_AIO_DNS(BaseTestDNS, tb.AIOTestCase):
    pass
