
import pytest
import anyio
import sys
import winloop
from typing import Any

pytestmark = pytest.mark.anyio


# Mirror of a test from anyio SEE: https://github.com/agronholm/anyio/pull/960#issuecomment-3217929102
# This test looked pretty difficult to try and reproduce 
# so I just moved everything here - Vizonex

ASYNCIO_PARAMS = (
    pytest.param(("asyncio", {"debug": True}), id="asyncio"),
    pytest.param(("asyncio",{"debug": True, "loop_factory": winloop.new_event_loop}), id="asyncio+winloop")
)


@pytest.fixture(params=ASYNCIO_PARAMS)
def anyio_backend(request: pytest.FixtureRequest) -> tuple[str, dict[str, Any]]:
    return request.param

@pytest.mark.parametrize(
    "shell, command",
    [
        pytest.param(
            True,
            f'{sys.executable} -c "import sys; print(sys.stdin.read()[::-1])"',
            id="shell",
        ),
        pytest.param(
            False,
            [sys.executable, "-c", "import sys; print(sys.stdin.read()[::-1])"],
            id="exec",
        ),
    ],
)
async def test_run_process(
    shell: bool, command: str | list[str], anyio_backend_name: str
) -> None:
    process = await anyio.run_process(command, input=b"abc")
    assert process.returncode == 0
    print( process.stdout.rstrip())
    assert process.stdout.rstrip() == b"cba"


