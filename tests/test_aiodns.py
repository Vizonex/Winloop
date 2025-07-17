# NOTE: I forked the aiodns Repository you will have to use that for now
# or wait for the pull request I recently made to go through:
# https://github.com/saghul/aiodns/pull/116

try:
    import aiodns
except ImportError:
    skip_tests = True
else:
    skip_tests = False

import asyncio
import sys
import unittest

from winloop import _testbase as tb


class _TestAiodns:
    def test_dns_query(self):
        # This is not allowed to fail...
        resolver = aiodns.DNSResolver(loop=self.loop)

        async def test():
            async def query(name, query_type):
                return await resolver.query(name, query_type)

            await query("google.com", "A")
            await query("httpbin.org", "A")
            await query("example.com", "A")

        self.loop.run_until_complete(test())


@unittest.skipIf(skip_tests, "no aiodns module")
class Test_UV_Aiodns(_TestAiodns, tb.UVTestCase):
    pass


@unittest.skipIf(skip_tests, "no aiodns module")
class Test_AIO_Aiodns(_TestAiodns, tb.AIOTestCase):
    # Winloop comment: switching to selector loop (instead of proactor),
    # see https://github.com/saghul/aiodns/issues/86
    if sys.platform == "win32":

        def new_policy(self):
            return asyncio.WindowsSelectorEventLoopPolicy()
