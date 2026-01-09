# AVATAR CREATOR COPIER (Local Overlay Avatar Copy)

A **client-side (local-only)** Roblox dev tool that lets you **visually copy any player’s avatar** by spawning a **local overlay clone** of their character model. The overlay follows your HumanoidRootPart smoothly and mirrors your pose/animations, so it looks like you “became” that avatar - **without changing your real Roblox account avatar** and **without other players seeing anything**.

This is built for **dev testing** (cosmetic verification, outfit compatibility, UI previews, and animation/rig checks).

---

## ✨ Key Features

### ✅ Local-Only Avatar Copy (No Server Changes)
- Enter a **Username or UserId**.
- The script resolves the target and generates a humanoid model locally.
- Your real avatar is not modified server-side. This is **visual-only**.

### ✅ Smooth Overlay Follow (No Jitter)
- The overlay model is attached to your character using a **WeldConstraint** between HRPs.
- This provides a stable follow system compared to per-frame teleporting.

### ✅ Pose / Animation Mirroring
- The script maps **Motor6D → Motor6D** pairs between your rig and the overlay rig.
- Every frame, it copies `Motor6D.Transform` so the overlay matches your current pose:
  - idle
  - walking/running
  - jumping
  - tool animations
  - emotes (depending on the game)

### ✅ Hide My Character (Local)
- Optional toggle to locally hide your real character so the overlay appears as a full replacement.
- Uses **local transparency** techniques so it does not alter server state.

### ✅ Built-In UI (Clean + Draggable + Mobile Friendly)
- Search input (Username/UserId)
- Target preview card (name + userId + thumbnail)
- Buttons:
  - Spawn/Update Overlay
  - Remove Overlay
  - Hide My Character toggle
- Draggable UI supports mouse/touch

### ✅ Local Nametag Control (Optional)
- A local-only panel to:
  - Hide existing in-game nameplates on your character (local)
  - Display a custom local nametag (local)
  - Adjust:
    - height offset above the head
    - outline strength
    - font style (Bold/Black)

> Nametag changes are **visual-only** and do not change your Roblox identity.

---

## 🔧 How It Works (Technical Overview)

1. **Target Resolve**
   - If input is numeric → treated as UserId
   - If input is text → resolved to UserId via Roblox APIs

2. **Avatar Model Creation**
   - Uses `Players:CreateHumanoidModelFromUserIdAsync(userId)` (or fallback)
   - Produces a full rig model with accessories/clothing

3. **Local-Only Parenting**
   - Overlay is parented under a folder inside `workspace.CurrentCamera`
   - This keeps it client-only and prevents normal world interactions

4. **Safety Hardening**
   - Disables any Scripts/LocalScripts inside the overlay model
   - Sets overlay parts:
     - `CanCollide = false`
     - `CanTouch = false`
     - `CanQuery = false`
     - `Massless = true`
   - Prevents the overlay from affecting physics, triggers, or gameplay logic

5. **Smooth Follow**
   - WeldConstraint binds overlay HRP to your HRP

6. **Pose Mirror Loop**
   - Motor6D pairs are matched by signature (name + part0/part1)
   - Copies `Transform` values each frame for accurate pose mirroring

7. **Optional Local Hide**
   - Hides your real character locally so only the overlay is visible

---

## ✅ Intended Use Cases
- Internal QA testing of cosmetics and rig compatibility
- Previewing how a specific avatar looks in your game environment
- Animation pose verification on different body types
- UI/Avatar systems development without altering real account avatar

---

## ⚠️ Notes / Limitations
- **Visual-only:** does not change:
  - your server hitbox
  - server avatar description
  - your real username/display name
- Some games use custom rigs or custom animation controllers; overlay results can vary.
- If a game has aggressive character replacement logic, you may need to re-spawn the overlay after respawn.

---

## 🧪 Safety / Ethics
This tool is intended for **your own development, testing, and internal QA**.  
Do not use it to mislead other players or impersonate others in public environments.

---

## Credits
Created by **Kixdev** — “AVATAR CREATOR COPIER”
