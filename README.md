# OoT VR (MMVR layout)

Ocarina of Time VR for Quest, structured the same way as
[Majora's Mask VR](https://github.com/fulldivegames/Majoras-Mask-VR) so both games can share one VR runtime.

| This repo | Majora's Mask VR equivalent | Role |
|---|---|---|
| `src/mmvr-runtime/` | `src/mmvr-runtime/` | Shared OpenXR core and platform/session implementation |
| `src/shipwright/soh/soh/VR/` | `src/2ship2harkinian/mm/2s2h/VR/` | OoT game-side VR hooks (player, items, camera, combat) |
| `src/shipwright/` (fetched) | `src/2ship2harkinian/` | Ship of Harkinian upstream, pinned in `UPSTREAM.json`, **not committed** |
| `patches/` | modified vendored files | Changes applied to upstream by `tools/fetch-upstream.sh` |

**Status: Windows Release build and a Quest 2 arm64 Debug APK are built; headset gameplay is not yet verified.** Quest Touch actions feed OoT's N64 pad state, and optional OpenXR hand tracking adds gesture-based pad input plus simple skeletal hand proxies. The hand map is provisional, and the proxies do not depth-occlude against the game world. An OoT head-anchored first-person camera callback is implemented but still needs headset validation. See `docs/ARCHITECTURE.md` and `TESTING.md` for limits and test steps.

Build the APK with `tools/build-quest.ps1 -Variant Debug`; see `BUILDING.md` for SDK setup and APK location. The build does not contain game ROM or copyrighted assets.

You must supply your own legally obtained Ocarina of Time dump. Do not commit or share ROMs or `oot.o2r`.
See `NOTICE.md` for licensing.
