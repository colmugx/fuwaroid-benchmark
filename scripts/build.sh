#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

rm -rf build external/fuwaroid
mkdir -p build/{erlang,akka,proto,pony,caf} external

echo '== Fuwaroid =='
git clone --depth 1 https://github.com/colmugx/fuwaroid.git external/fuwaroid
(
  cd external/fuwaroid
  moon update
  moon build --target native --release
)
FUWAROID_BIN="external/fuwaroid/_build/native/release/build/bench/bench.exe"
test -x "$FUWAROID_BIN"

echo '== Erlang/OTP =='
erlc -o build/erlang benchmarks/erlang/bench.erl

echo '== Akka Typed =='
mvn -q -f benchmarks/akka/pom.xml -DskipTests package
cp benchmarks/akka/target/akka-bench.jar build/akka/akka-bench.jar

echo '== Proto.Actor Go =='
(
  cd benchmarks/protoactor
  go mod download
  go build -trimpath -ldflags='-s -w' -o "$ROOT/build/proto/proto_bench" .
)

echo '== Pony =='
# ponyc's normal build is optimized; --debug is the opt-out.
ponyc -b pony_bench -o "$ROOT/build/pony" benchmarks/pony

echo '== CAF =='
cmake -S benchmarks/caf -B build/caf-src -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/caf-src --target caf_bench -j "$(nproc)"
cp build/caf-src/caf_bench build/caf/caf_bench

printf '\nBuilt binaries:\n'
ls -lh \
  "$FUWAROID_BIN" \
  build/erlang/bench.beam \
  build/akka/akka-bench.jar \
  build/proto/proto_bench \
  build/pony/pony_bench \
  build/caf/caf_bench
