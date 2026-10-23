# OoT VR (MMVR layout)

Ocarina of Time VR for Quest, structured the same way as
[Majora's Mask VR](https://github.com/fulldivegames/Majoras-Mask-VR) so both games can share one VR runtime.

| This repo | Majora's Mask VR equivalent | Role |
|---|---|---|
| `mmvr-runtime/`, `mmvr-runtime0/` | `src/mmvr-runtime/` | Shared OpenXR core and platform/session implementation |
| `src/shipwright/soh/soh/VR/` | `src/2ship2harkinian/mm/2s2h/VR/` | OoT game-side VR hooks (player, items, camera, combat) |
| `src/shipwright/` (fetched) | `src/2ship2harkinian/` | Ship of Harkinian upstream, pinned in `UPSTREAM.json`, **not committed** |
| `patches/` | modified vendored files | Changes applied to upstream by `tools/fetch-upstream.sh` |

**Status: early gameplay integration, not yet built.** Quest Touch actions are connected to OoT's N64 pad state, and gameplay scenes are wired to the runtime's stereo renderer without relying on Majora's Mask's HUD pointer. The runtime has controller poses and stereo rendering, but OoT's head-relative camera, tracked-hand rendering/actions, item/combat interactions, and Quest APK packaging are not implemented. See `docs/ARCHITECTURE.md` and `TESTING.md`.

Start: `tools/fetch-upstream.sh`, then see `BUILDING.md`.

You must supply your own legally obtained Ocarina of Time dump. Do not commit or share ROMs or `oot.o2r`.
See `NOTICE.md` for licensing.
