# OoT VR (MMVR layout)

Ocarina of Time VR for Quest, structured the same way as
[Majora's Mask VR](https://github.com/fulldivegames/Majoras-Mask-VR) so both games can share one VR runtime.

| This repo | Majora's Mask VR equivalent | Role |
|---|---|---|
| `src/mmvr-runtime/` | `src/mmvr-runtime/` | Shared OpenXR runtime (copied from MM VR; being split into generic core vs game-specific) |
| `src/shipwright/soh/soh/VR/` | `src/2ship2harkinian/mm/2s2h/VR/` | OoT game-side VR hooks (player, items, camera, combat) |
| `src/shipwright/` (fetched) | `src/2ship2harkinian/` | Ship of Harkinian upstream, pinned in `UPSTREAM.json`, **not committed** |
| `patches/` | modified vendored files | Changes applied to upstream by `tools/fetch-upstream.sh` |

**Status: milestone 1b, awaiting first Windows build.** Scaffold, libultraship hook patches (apply cleanly, not yet built), build script, test plan (`TESTING.md`). Nothing here renders in VR yet. See `docs/ARCHITECTURE.md`.

Start: `tools/fetch-upstream.sh`, then see `BUILDING.md`.

You must supply your own legally obtained Ocarina of Time dump. Do not commit or share ROMs or `oot.o2r`.
See `NOTICE.md` for licensing.
