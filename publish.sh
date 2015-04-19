#!/bin/bash

cd haxelib
haxe build.hxml
cd ..

zip -r haxelib.zip "src/halk" run.n haxelib.json