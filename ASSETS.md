# Asset Production List

Art direction: **Stardew Valley × OMORI** — cozy pixel-art warmth blended with hand-drawn monochrome sketchbook ink, soft pastel accents, and generous White Space.

---

## 1. Core Illustrations (Currently Using Placeholders)

Replace these placeholder files in `assets/images/` with final artwork:

| File | Aspect / Size | Used In | Description |
| --- | --- | --- | --- |
| `assets/images/banner.gif` | `2304×1368` | Title Screen (`HomeScreen`) | Animated title screen banner. |
| `assets/images/background.png` | `3640×2048` | Game screen and story map | Pixel-art sky and meadow background. |
| `assets/images/crosswalk_rain.jpg` | 16:9 (`1280×720`) | Intro Death & Mirrored Ending (`OnboardingScreen`, `EndingScreen`) | Classic isekai rainy night crosswalk: wet asphalt, glowing pedestrian signal, approaching delivery truck headlights in pixel rain. |
| `assets/images/ending_dream_achieved.jpg` | 16:9 (`1280×720`) | Ending A & Memory Timeline (`EndingScreen`, `RoadmapScreen`) | Golden-hour hillside meadow overlooking a peaceful pixel town with floating lanterns and a sketchbook on a bench. |
| `assets/images/ending_dream_unfulfilled.jpg` | 16:9 (`1280×720`) | Ending B & Memory Timeline (`EndingScreen`, `RoadmapScreen`) | Quiet bedroom window at dusk with rain streaks, warm desk lamp, closed dusty notebook, bittersweet blue-gray palette. |

---

## 2. Character Portraits (Currently Using Placeholders)

Square character portraits in `assets/images/`:

| File | Life Stage | Used In | Description |
| --- | --- | --- | --- |
| `assets/images/child_happy.svg` | Infancy / Early Childhood / Childhood (0–10) | Game screen, onboarding, and story map | Pixel-art happy character sprite. |
| `assets/images/child_wah.svg` | Infancy / Early Childhood / Childhood (0–10) | Game screen, onboarding, and story map | Pixel-art crying character sprite for sad, anxious, or quiet moods. |
| `assets/images/portrait_teen.jpg` | Pre-Teen / Teenager (11–17) | Memory Album / Future Portrait Views | Thoughtful teenager with dark bangs and oversized sweater/hoodie. |
| `assets/images/portrait_adult.jpg` | Young Adult / Adulthood (18+) | Memory Album / Future Portrait Views | Warm, wistful young adult in a simple cozy jacket. |

---

## 2b. Main Choice Screen Character Sprites

The game uses `assets/images/background.png` behind the character. Standing sprites for ages 3+ remain in `assets/images/window/`:

| File | Aspect / Size | Variant | Description |
| --- | --- | --- | --- |
| `assets/images/window/standing_childhood.png` | 5:9 (`500×900`, transparent PNG) | Age: Childhood (3–10) | Full-height standing child portrait in striped sweater and sneakers in the left fourth of `GameScreen`. |
| `assets/images/window/standing_teen.png` | 5:9 (`500×900`, transparent PNG) | Age: Teen (11–17) | Full-height standing teen portrait in oversized hoodie in the left fourth of `GameScreen`. |
| `assets/images/window/standing_adult.png` | 5:9 (`500×900`, transparent PNG) | Age: Adult (18+) | Full-height standing young adult portrait in long coat holding a sketchbook in the left fourth of `GameScreen`. |

---

## 3. Audio Assets

Currently in `assets/audio/`:

| File | Format | Status | Description |
| --- | --- | --- | --- |
| `assets/audio/typewriter_blip.wav` | 22kHz Mono WAV (~26ms) | Placeholder synthesized | Undertale-style per-letter dialogue voice blip played on each character in `TypewriterText`. |

---

## 4. Planned / Nice-to-Have Polish Assets

Not yet wired into the app, recommended for final release:

- **App Icon (`1024×1024` PNG)** — Custom macOS, iOS, and Android launcher icon (e.g., hanging black lightbulb inside a pixel sketchbook frame).
- **Mood Expression Variants** — Optional alternate expressions (`happy`, `anxious`, `sad`, `quiet`) per life stage if portraits are expanded in the Memory Timeline.
- **Scenario Vignette Sketches** — Minimalist small ink doodles for key themes (`Attachment`, `Curiosity`, `Academics`, `Freedom`, `Ambition`, `Legacy`).
- **Additional Audio SFX & BGM:**
  - `assets/audio/rain_loop.ogg` — Soft looping rain ambience for the crosswalk intro and mirrored ending.
  - `assets/audio/white_space_bgm.ogg` — Sparse, gentle piano/music-box loop (OMORI White Space mood).
  - `assets/audio/choice_select.wav` — Soft paper-tap or wooden click when selecting a parenting choice.
  - `assets/audio/headlights_impact.wav` — Subtle dramatic cutoff/flash transition into White Space.
- **Bundled Fonts (`assets/fonts/`)** — Bundle `PatrickHand-Regular.ttf` and `VT323-Regular.ttf` locally so typography never depends on runtime Google Fonts fetching when offline.
