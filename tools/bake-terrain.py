"""Bake native Roblox terrain in an isolated local Studio session."""
import argparse
import base64
from pathlib import Path
import subprocess
import tempfile
import shutil

ROOT = Path(__file__).resolve().parents[1]
EXPORT = """
bake(workspace.Terrain, parcels)
local data = game:GetService("SerializationService"):SerializeInstancesAsync({workspace.Terrain})
local encoded = buffer.tostring(game:GetService("EncodingService"):Base64Encode(data))
for i = 1, #encoded, 1800 do print("TERRAIN_DATA " .. encoded:sub(i, i + 1799)) end
print("TERRAIN_BYTES " .. buffer.len(data))
"""


def module(name, binding):
    source = (ROOT / "tools/world" / name).read_text(encoding="utf-8")
    return f"local {binding} = (function()\n{source}\nend)()\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--studio", required=True, type=Path)
    parser.add_argument("--lune", default="lune")
    args = parser.parse_args()
    studio = args.studio.resolve()
    lune = shutil.which(args.lune)
    if not lune:
        parser.error("Lune 0.11.1 is required to pack the native voxel model")
    with tempfile.TemporaryDirectory() as folder:
        temp = Path(folder)
        script, log = temp / "bake.luau", temp / "studio.log"
        script.write_text(module("zones.luau", "parcels") + module("landscape.luau", "bake") + EXPORT, encoding="utf-8")
        subprocess.run([str(studio), "--task", "RunScript", "--runScriptFile", str(script),
                        "--outputFile", str(log), "--quitAfterExecution"], check=True, timeout=360)
        lines = log.read_text(encoding="utf-8").splitlines()
        data = base64.b64decode("".join(line[13:] for line in lines if line.startswith("TERRAIN_DATA ")), validate=True)
        if not data.startswith(b"<roblox!") or f"TERRAIN_BYTES {len(data)}" not in lines:
            raise RuntimeError("Incomplete terrain export: " + "\n".join(lines[-3:])[:400])
        raw, packed = temp / "studio.rbxm", temp / "lunar.rbxm"
        raw.write_bytes(data)
        subprocess.run([lune, "run", str(ROOT / "tools/world/pack-terrain.luau"),
                        str(raw), str(packed)], check=True)
        output = ROOT / "world/LunarTerrain.rbxm"
        with tempfile.NamedTemporaryFile(dir=output.parent, delete=False) as result:
            result.write(packed.read_bytes())
        Path(result.name).replace(output)
    print(f"Baked {output.name} ({output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
