#!/bin/sh
ocaml install.ml && cd bin && ./haxe build.hxml && cd .. && nano bin/test.lua
