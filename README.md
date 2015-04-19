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

#### First build (magic starts here) (additional args: --no-inline)

`haxelib run halk ... -halk`

#### Incremental build (skip all steps, only haxe build) (additional args: --no-output --no-inline)

`haxelib run halk ... -halka` // allow -halk + random char (halk3, halke, halki, etc)

### Recommends

Useful compiler flags `-debug -dce no  --connect 4444`

for lime project

```
<haxeflag name="-debug"/>
<haxeflag name="-dce no"/>
<haxeflag name="--connect 4444"/>
```

More info about `--connect` http://haxe.org/manual/cr-completion-server.html 

### Known problems

If you see `EUnknownVariable(__dollar__#####))` set `--no-inline`