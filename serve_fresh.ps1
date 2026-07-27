param(
    [switch]$NoBuild,
    [switch]$Wasm,
    [switch]$Profile,
    [switch]$NoBrowser
)

$argsList = @()
if ($NoBuild) { $argsList += "--no-build" }
if ($Wasm) { $argsList += "--wasm" }
if ($Profile) { $argsList += "--profile" }
if ($NoBrowser) { $argsList += "--no-browser" }

python "$PSScriptRoot/scripts/serve_fresh.py" @argsList
