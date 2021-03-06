# halk2

Live coding extension for Haxe programming language.

Tested targets: flash, neko, html5, cpp(desktop)

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

#### Magic build (additional args: --no-inline)

1. Build application `haxelib run halk build ... -halk`

2. Run application `haxelib run halk run ...`

3. Incremental build (skip all steps, only haxe build) (additional args: --no-output --no-inline) `haxelib run halk build ... -halka` // allow -halk + random char (halk3, halke, halki, etc)

## Manual usage (not recommended for openfl/lime projects)

- Set magic define `-D halk_angry`
- Build with `--no-inline` flag
- Rebuild with `--no-inline --no-output` flags

### Recommends

Useful compiler flags `-debug -dce no  --connect 4444`

for lime project

```
<haxeflag name="-debug" if="halk_angry"/>
<haxeflag name="-dce no" if="halk_angry"/>
<haxeflag name="--connect 4444"/>
```

More info about `--connect` http://haxe.org/manual/cr-completion-server.html 

### Known problems

- If you see `EUnknownVariable(__dollar__#####))` set `--no-inline` (autoset in `haxelib run halk`)
- `-debug` required for `cpp` target 
