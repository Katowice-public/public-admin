#!/usr/bin/env bash
# Downloads the Luau CLI (if needed), generates the combined harness, and runs
# the end-to-end Loader flow. Exits non-zero on any module load / init failure.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LUAU="${LUAU:-}"

if [ -z "$LUAU" ]; then
	if command -v luau >/dev/null 2>&1; then
		LUAU="$(command -v luau)"
	elif [ -x "$ROOT/.bin/luau" ]; then
		LUAU="$ROOT/.bin/luau"
	else
		echo "Luau CLI not found — downloading..."
		mkdir -p "$ROOT/.bin"
		curl -sL "https://github.com/luau-lang/luau/releases/download/0.733/luau-ubuntu.zip" -o /tmp/luau.zip
		unzip -o -q /tmp/luau.zip -d /tmp/luau-extract
		mv /tmp/luau-extract/luau "$ROOT/.bin/luau"
		chmod +x "$ROOT/.bin/luau"
		LUAU="$ROOT/.bin/luau"
	fi
fi

bash "$ROOT/test/gen.sh"
"$LUAU" "$ROOT/test/_combined.luau"
