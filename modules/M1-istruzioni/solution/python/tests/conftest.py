import pytest
from app.main import store

@pytest.fixture(autouse=True)
def reset_store():
    store._tasks.clear()
    store._next_id = 1
    yield
