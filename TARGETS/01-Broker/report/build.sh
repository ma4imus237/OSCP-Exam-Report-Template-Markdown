#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")"
ruby osert.rb generate -i report.md -o output -e OSCP -s 123456
