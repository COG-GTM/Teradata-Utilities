#!/usr/bin/env sh
# Regenerate the architecture diagram from its Graphviz source.
# Requires Graphviz (`dot`), e.g. `sudo apt-get install -y graphviz fonts-dejavu`.
set -eu
cd "$(dirname "$0")"
dot -Tpng -Gdpi=110 architecture.dot -o architecture.png
dot -Tsvg architecture.dot -o architecture.svg
echo "Wrote $(pwd)/architecture.png and architecture.svg"
