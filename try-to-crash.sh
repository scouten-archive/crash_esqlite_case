#!/bin/bash

set -e

mix deps.get
./integration/hack_out_incompatible_tests.sh

for i in {1..100}
do
  echo
  echo --------- Attempt $i ---------
  mix test
done
