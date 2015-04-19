#!/bin/bash

cd haxelib
haxe build.hxml
cd ..

echo "removing haxelib.zip"
rm haxelib.zip

zip -r haxelib.zip "src/halk" run.n haxelib.json

haxelib local haxelib.zip