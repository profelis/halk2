# halk2

Live coding extension for Haxe programming language.

------

## Installation

- haxelib git halk https://github.com/profelis/halk2.git
- goto haxelib/halk/(version)/
- `cd haxelib && haxe build.hxml`  // generate run.n


## Usage

#### Default build (without halk magic)

`haxelib run halk build.hxml` // simple haxe project

or

`haxelib run halk test flash` // openfl project

#### First build (magic starts here)

`haxelib run halk ... -halk`

#### Incremental build (build with --no-output, update live data very fast)

`haxelib run halk ... -halka` // allow -halk + random char (halk3, halke, halki, etc)
