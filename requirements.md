Below is the latest, detailed set of requirements for your “Fluffel” Mac Pet project, consolidating everything we’ve discussed—core functionality, visual design, animations, tech solutions, and development guidelines. This reflects the evolution of your idea from the initial concept to the detailed plan we’ve built, including the Cursor.sh prompt and `.cursorrules`. It’s structured for clarity and completeness, serving as a comprehensive blueprint for implementation.

-----

### Fluffel: Mac Pet Desktop Companion - Full Requirements

#### Project Overview

- **Purpose**: Fluffel is a lightweight, interactive desktop companion for macOS that enhances the user experience with a cute, animated creature living on the screen.
- **Target Audience**: macOS users looking for a fun, playful utility.
- **Platform**: macOS, minimum version 13.0 (Ventura).
- **Distribution**: Packaged as a `.dmg` file (optional Mac App Store submission later).

-----

### Core Features

1. **Follows Lines/Surfaces**
- Fluffel moves along the edges of open windows, the dock, or other visible screen boundaries.
- Behavior: Waddles or hops smoothly, staying on the “surface” until it moves or disappears.
2. **Can Drop**
- If a window Fluffel is on moves or closes, it falls to the desktop with a cute bounce.
- Visual Cue: Spins or flails during descent, lands with a slight rebound.
3. **Tries to Ascend**
- After falling, Fluffel attempts to climb back up using nearby windows or desktop icons.
- If no path exists, it flies (see below).
- Behavior: Wiggles or hops while searching for a way up.
4. **Flying (Once Per Hour)**
- Fluffel can fly to ascend when stuck, limited to once per hour.
- Visual Cue: Flutters wings (if present) or glides upward with a glowing effect.
- Cooldown: After flying, it’s grounded for 60 minutes, showing exhaustion (e.g., panting).
5. **Cute Idle/Thinking Movements**
- When idle, Fluffel performs small, adorable actions (e.g., head tilt, paw twitch, little dance).
- When “thinking” (e.g., deciding a path), it taps a paw or tilts its head.
6. **Reacts to Cursor**
- Fluffel chases the cursor playfully when it moves nearby.
- Behavior: Scurries toward it with quick steps, pouncing if close.
7. **Icons as Toys**
- Desktop icons are interactive “toys” Fluffel can bat, stack, or roll.
- Visual Cue: Gentle push or nudge motion, with icons wobbling slightly.
8. **Hide-and-Seek Game**
- Fluffel can vanish and reappear behind windows or icons for a hide-and-seek game.
- Trigger: User double-clicks Fluffel or it initiates randomly when idle.
- Visual Cue: Fades out with a giggle, fades in when found.
9. **Resting**
- Fluffel rests when “tired” (e.g., after prolonged activity), curling into a ball with a snoring animation.
- Trigger: Stamina system (depletes with movement, recharges when idle).
- Interaction: Nudge with cursor to wake it.
10. **Asks to Play**
- When bored (e.g., idle too long), Fluffel requests playtime via a text bubble (e.g., “Play with me!”).
- Behavior: Bounces or tugs at the screen edge until the user interacts.

-----

### Visual Design

- **Appearance**:
  - Shape: Small, round, plush-like creature (50x50 pixels on screen).
  - Features: Big, expressive eyes, tiny paws or stubs, optional tail/wings for personality.
  - Colors: Soft pastels (e.g., pink, blue, lavender) with light shading for depth.
  - Style: Simple 2D cartoon/pixel art, avoiding complex details.
- **Placeholder**: For initial development, use a red circle with two white dot eyes (drawn in SpriteKit).
- **Final Design**: Replace with a custom sprite sheet (e.g., `fluffel.png`, 5x2 grid, 50x50 px frames) created in Aseprite or similar.
- **Expressions**: Variants for happy (curved eyes), thinking (tilted head), tired (half-closed eyes).

-----

### Animations

- **Format**: 2D sprite animations, 2-3 frames per sequence for simplicity, implemented in SpriteKit.
- **Types**:
1. **Idle**: Head tilt, paw twitch, or slight bounce (2-3 frames).
2. **Walking**: Waddling or hopping along edges (2-3 frames).
3. **Falling**: Spinning or flailing with a bounce on landing (3 frames).
4. **Flying**: Fluttering wings or smooth glide (3 frames).
5. **Cursor Chase**: Quick scamper with excited motion (2 frames).
6. **Icon Play**: Gentle bat or push (2 frames).
7. **Hide-and-Seek**: Fade out/in (opacity change, no frames needed).
8. **Sleeping**: Slow breathing (body expands/contracts, 2 frames).
- **Physics**: Lightweight SpriteKit physics for falling/bouncing (e.g., `SKPhysicsBody.circleOfRadius(25)`).
- **Sound**: Optional chirps or giggles via AVFoundation (e.g., short `.mp3` files).

-----

### Technical Requirements

- **Language**: Swift (macOS-native).
- **Frameworks**:
  - **AppKit**: Window management, desktop overlay, text bubbles.
  - **SpriteKit**: Sprite rendering, animations, basic physics.
  - **Core Animation**: Fallback for simple animations (e.g., falling).
  - **AVFoundation**: Audio playback (e.g., chirps).
- **Dependencies**: None (use native frameworks only).
- **Performance**: Low CPU usage (background threading for non-UI tasks, optimized animations).
- **Extensibility**: Easy to swap sprites/animations via sprite sheets or configurable properties.

-----

### Development Approach

- **Phased Implementation**:
1. **Phase 1: Basic Fluffel**
  - Transparent window, SpriteKit scene, placeholder sprite (red circle with eyes), arrow key movement.
2. **Phase 2: Edge Following and Falling**
  - Window edge detection, walking animation, falling with bounce.
3. **Phase 3: Cursor Interaction**
  - Cursor tracking, chase animation.
4. **Phase 4: Idle Animations and Icon Play**
  - Idle animation, icon interaction with batting animation.
5. **Phase 5: Advanced Features**
  - Flying (with cooldown), hide-and-seek, resting, play requests.
6. **Phase 6: Polish and Deploy**
  - Optimize performance, add sound, package as `.dmg`.
- **Tools**:
  - **IDE**: Xcode (latest version).
  - **Design**: Aseprite (or Piskel/GIMP) for sprite sheet creation.
  - **Version Control**: Git (optional, e.g., GitHub).

-----

### Workload Estimate (Approximate)

- **Total Hours**: 105-145 hours (solo developer, intermediate experience).
- **Breakdown**:
  - Planning/Setup: 10-15 hours.
  - Core Movement/Animation: 30-40 hours.
  - Interactivity: 25-35 hours.
  - Personality/Polish: 20-25 hours.
  - Testing/Optimization: 15-20 hours.
  - Deployment: 5-10 hours.
- **Timeline**: 3-4 weeks (solo, full-time) or 2-3 weeks (two developers).

-----

### Development Guidelines (From `.cursorrules`)

- **Code Style**: SwiftLint conventions (camelCase, 2-space indentation), comments for key logic.
- **File Structure**: Descriptive names (e.g., `FluffelView.swift`), grouped folders (e.g., `Views/`).
- **Error Handling**: Minimal (e.g., optional binding), expand if requested.
- **Naming Examples**: `fluffelNode` (SpriteKit node), `fluffelWindow` (NSWindow).
- **Animation Example**:
  
  ```swift
  let atlas = SKTextureAtlas(named: "Fluffel")
  let walkFrames = [atlas.textureNamed("walk1"), atlas.textureNamed("walk2")]
  let walkAction = SKAction.animate(with: walkFrames, timePerFrame: 0.2)
  fluffelNode.run(SKAction.repeatForever(walkAction))
  ```

-----

### Deliverables

- **App**: A functional `.dmg` file with Fluffel running on macOS.
- **Assets**: Placeholder sprite (code-generated), optional custom sprite sheet (user-provided).
- **Documentation**: Basic setup/run instructions (e.g., “Double-click Fluffel.dmg to install”).

-----

### Notes

- **Customization**: Users can later swap Fluffel’s sprite, colors, or sounds via a settings panel (future enhancement).
- **Scalability**: Design supports adding new behaviors (e.g., multiplayer Fluffels) if desired.
- **Testing**: Multi-monitor support and window focus handling to be verified in Phase 6.

-----

This is the complete, up-to-date requirements document for Fluffel, ready to guide development via Cursor.sh or manual coding. It captures every detail we’ve refined—functionality, visuals, animations, and tech—while keeping the scope clear and actionable. Let me know if you want to adjust anything (e.g., add a feature, tweak the design) before proceeding! Ready to start with Phase 1?