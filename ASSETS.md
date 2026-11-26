# Asset Production List

Art direction: **Stardew Valley × OMORI** — cozy pixel-art warmth blended with hand-drawn monochrome sketchbook ink, soft pastel accents, and generous White Space.

---

## 1. Core Illustrations (Currently Using Placeholders)

Replace these placeholder files in `assets/images/` with final artwork:

| File | Aspect / Size | Used In | Description |
| --- | --- | --- | --- |
| `assets/images/title_banner.jpg` | 16:9 (`1280×720`) | Title Screen (`HomeScreen`) | Cozy White Space meets pixel cottage: hanging black lightbulb over a wooden desk, open sketchbook, starry window. |
| `assets/images/crosswalk_rain.jpg` | 16:9 (`1280×720`) | Intro Death & Mirrored Ending (`OnboardingScreen`, `EndingScreen`) | Classic isekai rainy night crosswalk: wet asphalt, glowing pedestrian signal, approaching delivery truck headlights in pixel rain. |
| `assets/images/ending_dream_achieved.jpg` | 16:9 (`1280×720`) | Ending A & Memory Timeline (`EndingScreen`, `RoadmapScreen`) | Golden-hour hillside meadow overlooking a peaceful pixel town with floating lanterns and a sketchbook on a bench. |
| `assets/images/ending_dream_unfulfilled.jpg` | 16:9 (`1280×720`) | Ending B & Memory Timeline (`EndingScreen`, `RoadmapScreen`) | Quiet bedroom window at dusk with rain streaks, warm desk lamp, closed dusty notebook, bittersweet blue-gray palette. |

---

## 2. Character Portraits (Currently Using Placeholders)

Square 1:1 (`512×512`) Stardew × OMORI portraits in `assets/images/`:

| File | Life Stage | Used In | Description |
| --- | --- | --- | --- |
| `assets/images/portrait_infancy.jpg` | Infancy (0–2) | Intro Reincarnation & Future Portrait Views | Peaceful sleeping newborn swaddled in a cream blanket on warm sketchbook paper. |
| `assets/images/portrait_childhood.jpg` | Early Childhood / Childhood (3–10) | Memory Album / Future Portrait Views | Expressive young child with messy dark hair and cozy striped sweater. |
| `assets/images/portrait_teen.jpg` | Pre-Teen / Teenager (11–17) | Memory Album / Future Portrait Views | Thoughtful teenager with dark bangs and oversized sweater/hoodie. |
| `assets/images/portrait_adult.jpg` | Young Adult / Adulthood (18+) | Memory Album / Future Portrait Views | Warm, wistful young adult in a simple cozy jacket. |

---

## 2b. Main Choice Screen Window Scene (Currently Using Placeholders)

Layered vibrant background assets in `assets/images/window/` used by `WindowSceneBackground` on `GameScreen`:

| File | Aspect / Size | Variant | Description |
| --- | --- | --- | --- |
| `assets/images/window/sky_happy.png` | 16:9 (`1280×720`) | Mood: `happy` | Bright sunlit pastel blue sky with golden sunbeams and fluffy cream clouds. |
| `assets/images/window/sky_proud.png` | 16:9 (`1280×720`) | Mood: `proud` | Golden-hour sunset sky in peach, rose-pink, and glowing amber. |
| `assets/images/window/sky_neutral.png` | 16:9 (`1280×720`) | Mood: `neutral` | Calm pastel afternoon sky with soft drifting clouds. |
| `assets/images/window/sky_quiet.png` | 16:9 (`1280×720`) | Mood: `quiet` | Serene twilight indigo-lavender sky with crescent moon and stars. |
| `assets/images/window/sky_anxious.png` | 16:9 (`1280×720`) | Mood: `anxious` | Restless violet-slate dusk sky with heavy clouds and muted coral horizon. |
| `assets/images/window/sky_sad.png` | 16:9 (`1280×720`) | Mood: `sad` | Moody rainy blue-gray twilight sky with diagonal rain streaks. |
| `assets/images/window/standing_infancy.png` | 5:9 (`500×900`, transparent PNG) | Age: Infancy (0–2) | Full-height standing/seated swaddled baby portrait in the left fourth of `GameScreen`. |
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
