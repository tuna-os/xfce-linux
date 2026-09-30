"""Keep incomplete greeter experiments outside the production image graph."""

from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
PRODUCTION_DEPS = REPO / "elements" / "xfce-linux" / "deps.bst"


def test_incomplete_greeter_is_not_a_production_dependency():
    """greetd/ReGreet requires cage, which this repository does not package."""
    dependencies = PRODUCTION_DEPS.read_text()

    assert "xfce-linux/greetd.bst" not in dependencies
    assert "xfce-linux/regreet.bst" not in dependencies


def test_experimental_greeter_elements_remain_available():
    """Keep the isolated elements available for explicit development builds."""
    elements = REPO / "elements" / "xfce-linux"

    assert (elements / "greetd.bst").is_file()
    assert (elements / "regreet.bst").is_file()
