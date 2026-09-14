#!/usr/bin/env python3
r"""Assert that armymemo.cls and README.md describe the same public API.

Version 1.0.0 froze the class's public command surface. A freeze that lives only
in a changelog sentence is not a freeze: the way it decays is that someone adds a
convenience command, never documents it, and it is public by accident and frozen
by the next release. This makes that a failing test instead.

The rule is symmetric and has no allowlist, deliberately:

    every command armymemo.cls defines without the am@ prefix
        must appear in README.md's frozen-API table
    every command README.md's frozen-API table names
        must be defined by armymemo.cls

A new public command therefore fails until it is documented, and a documented
command that is renamed or removed fails until the README catches up.

Two categories are excluded, both by rule rather than by name:

*   `\theenum*` and `\labelenum*` are LaTeX's own enumerate hooks. The class
    redefines them to get AR 25-50's 1. / a. / (1) / (a) labels, but they are
    kernel names and their behaviour is the kernel's contract, not this class's.
*   `am@`-prefixed macros are internal by construction -- a document cannot reach
    them without \makeatletter.

Usage:
    python3 tools/check-public-api.py [repo root]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# \newcommand{\foo}, \renewcommand\foo, \def\foo, \NewDocumentCommand{\foo},
# and \newdateformat{foo}, which defines \foo without a backslash in the source.
DEFINITION = re.compile(
    r"\\(?:new|renew|provide)command\s*\{?\\([A-Za-z@]+)"
    r"|\\(?:New|Renew|Provide)DocumentCommand\s*\{?\\([A-Za-z@]+)"
    r"|\\g?def\\([A-Za-z@]+)"
    r"|\\newdateformat\{([A-Za-z@]+)\}",
)

# A command named in the first cell of a row of the frozen-API table.
DOCUMENTED = re.compile(r"^\|\s*`\\([A-Za-z]+)`\s*\|", re.MULTILINE)

# LaTeX's enumerate hooks: kernel names, kernel contract.
KERNEL_HOOK = re.compile(r"^(?:the|label)enum(?:i|ii|iii|iv|v)$")

# The README table that IS the frozen list. Only this table is read: the prose
# around it names csquotes commands the class does not define (\enquote,
# \MakeOuterQuote) and commands deliberately removed (\continuedistro, \nd), and
# none of those are claims about this class's API.
REFERENCE_START = "### The frozen public API"
REFERENCE_END = "### Required fields"


def defined(cls_source: str) -> set[str]:
    """Public commands armymemo.cls defines, ignoring commented-out code."""
    live = "\n".join(
        line for line in cls_source.splitlines() if not line.lstrip().startswith("%")
    )
    names = set()
    for match in DEFINITION.finditer(live):
        name = next(group for group in match.groups() if group)
        if "@" not in name and not KERNEL_HOOK.match(name):
            names.add(name)
    return names


def documented(readme: str) -> set[str]:
    """Commands listed in the README's frozen-API table."""
    start = readme.index(REFERENCE_START)
    end = readme.index(REFERENCE_END, start)
    return {
        name
        for name in DOCUMENTED.findall(readme[start:end])
        if not KERNEL_HOOK.match(name)
    }


def main() -> int:
    """Compare the two lists and report either direction of drift."""
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    try:
        in_class = defined((root / "armymemo.cls").read_text())
        in_readme = documented((root / "README.md").read_text())
    except (OSError, ValueError) as exc:
        sys.stdout.write(f"FAIL public-api: {exc}\n")
        return 1

    undocumented = sorted(in_class - in_readme)
    unimplemented = sorted(in_readme - in_class)

    if undocumented:
        sys.stdout.write(
            "FAIL public-api: defined by armymemo.cls, absent from the README's\n"
            "     frozen-API table. Add it there, or give it the am@ prefix if it\n"
            "     was never meant to be public:\n",
        )
        for name in undocumented:
            sys.stdout.write(f"       \\{name}\n")
    if unimplemented:
        sys.stdout.write(
            "FAIL public-api: listed in the README's frozen-API table but not\n"
            "     defined by armymemo.cls. The class was renamed or trimmed and\n"
            "     the README did not follow:\n",
        )
        for name in unimplemented:
            sys.stdout.write(f"       \\{name}\n")
    if undocumented or unimplemented:
        return 1

    sys.stdout.write(
        f"ok   public-api ({len(in_class)} commands, class and README agree)\n",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
