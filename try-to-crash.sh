#!/bin/bash

set -e

# mix deps.get # not necessary since we've added deps
MIX_ENV=test mix compile

for i in {1..100}
do
  echo
  echo --------- Attempt $i ---------
  mix test --no-deps-check
done
