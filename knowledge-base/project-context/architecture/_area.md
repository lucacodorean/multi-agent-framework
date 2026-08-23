# <area>

The form for one area of this directory. Copy it, name it after the area, and
add its row to this directory's `README.md`. Delete this line and the one above.

## What it is

One paragraph. What this area exists to do, and the entry point that proves it — by path.

## What it publishes

What the rest of the system may depend on, and where that is declared. Anything not listed is
internal, and depending on it is a boundary violation.

## What it depends on

One row per dependency, each an area or an interface — never a file. Cite where the dependency
is bound, so the direction is checkable.

| depends on | bound at |
|---|---|
| <area or interface> | <path> |

## What it does not do

The claims most worth writing down, because they are the ones an agent otherwise assumes.
