#!/bin/sh
# Compiles the parser with a tiny harness on macOS and runs it.
set -e
cd "$(dirname "$0")/.."
swiftc -parse-as-library -o /tmp/carton-parse-check app/Carton/UPSPage.swift app/Carton/Store.swift tests/ParseCheck.swift
/tmp/carton-parse-check
