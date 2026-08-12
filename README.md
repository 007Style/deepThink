<div align="center">

```
██████╗ ███████╗███████╗██████╗ ████████╗██╗  ██╗██╗███╗   ██╗██╗  ██╗
██╔══██╗██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║  ██║██║████╗  ██║██║ ██╔╝
██║  ██║█████╗  █████╗  ██████╔╝   ██║   ███████║██║██╔██╗ ██║█████╔╝
██║  ██║██╔══╝  ██╔══╝  ██╔═══╝    ██║   ██╔══██║██║██║╚██╗██║██╔═██╗
██████╔╝███████╗███████╗██║        ██║   ██║  ██║██║██║ ╚████║██║  ██╗
╚═════╝ ╚══════╝╚══════╝╚═╝        ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
```

### *Four AI minds. One conversation. Fully offline. Entirely yours.*

[![macOS](https://img.shields.io/badge/macOS-arm64%20%7C%20x86__64-black?style=flat-square&logo=apple)](https://github.com/007Style/deepThink/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Ollama](https://img.shields.io/badge/Ollama-v0.32.9-FF6B35?style=flat-square)](https://ollama.com)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-132%20passing-brightgreen?style=flat-square)](#testing)
[![Version](https://img.shields.io/badge/version-v1.0.1-blue?style=flat-square)](CHANGELOG.md)

*From the minds of **Daneyand** & **IBM's Bob** · daneyand@ibm.com*

</div>

---

## What is deepThink?

deepThink drops **four distinct AI personalities** into a shared conversation and lets them debate, challenge, and build on each other's ideas — in parallel, in real time, right on your machine. No cloud. No accounts. No monthly bill. No one reading your conversations.

You can watch them go, interject with your own thoughts at any time, and steer the discussion wherever you want. Think of it as having four brilliant (and occasionally opinionated) AI colleagues around a virtual roundtable — and you own the building.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ┌──────────────┐        ┌──────────────┐             │
│   │   🔵 WATSON  │        │   🟣 DEEP    │             │
│   │   Analyst    │◄──────►│   Host       │             │
│   │  gemma2:9b   │        │  phi3:14b    │             │
│   └──────┬───────┘        └──────┬───────┘             │
│          │    ↑    YOU    ↓      │                      │
│          │    └────────────┘     │                      │
│   ┌──────┴───────┐        ┌──────┴───────┐             │
│   │  🟡 NOVA    │        │   🔴 SAGE    │             │
│   │  Visionary  │◄──────►│  Challenger  │             │
│   │  llama3:8b  │        │  mistral:7b  │             │
│   └──────────────┘        └──────────────┘             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## The Characters

| Character | Model | Personality | Role |
|-----------|-------|-------------|------|
| 🔵 **WATSON** | `gemma2:9b` | Analyst | Precise. Methodical. Breaks complexity into clarity. Named after IBM's legendary chess-playing, Jeopardy-winning AI — the one that started asking "what if a computer could think?" |
| 🟣 **DEEP** | `phi3:14b` | Host / Philosopher | Thoughtful. Provocative. Opens and guides the conversation. A nod to *Deep Blue* — the machine that in 1997 looked Garry Kasparov in the eye and didn't blink. |
| 🟡 **NOVA** | `llama3:8b` | Visionary | Creative. Expressive. Connects dots no one else sees. |
| 🔴 **SAGE** | `mistral:7b` | Challenger | Sharp. Contrarian. Pushes back, sharpens ideas, refuses easy answers. |

---

## A Love Letter to IBM's AI History

deepThink wouldn't exist without the giants that came before it.

**1956 — The Logic Theorist & the birth of AI**
The Dartmouth Conference. IBM researchers in the room. A bet that machines could reason. It took 70 years, but here we are.

**1981 — IBM PC changes computing forever**
The open platform that made personal computing real — and set the stage for the idea that powerful software should live on your desk, not in a data center.

**1985 — Deep Thought**
IBM's research group builds a chess computer that can evaluate 700,000 positions per second. The name? *Deep Thought* — after the computer in *The Hitchhiker's Guide to the Galaxy* that spent 7.5 million years computing the answer to Life, the Universe, and Everything. (The answer was 42. The question was harder.)

**1989 — Deep Thought II**
It beats every grandmaster except Kasparov. A machine that thinks about thinking. Sound familiar?

**1997 — Deep Blue defeats Kasparov**
```
Game 6. Brønstein Variation of the Caro-Kann Defense.
Move 19: Bd6. Kasparov resigns.
For the first time, a machine beats the reigning world chess champion.
The world watches and wonders: what comes next?
```
The answer, 30 years later, is four LLMs arguing about philosophy on your laptop.

**2011 — Watson wins Jeopardy!**
Not chess moves. Language. Context. Puns. Ken Jennings wrote: *"I, for one, welcome our new computer overlords."* IBM's Watson didn't just process — it understood. Or at least, it understood well enough to win $1 million on national television.

**2023–2026 — The LLM Revolution**
Transformers. Attention mechanisms. Billions of parameters. Open weights. The idea that language models can be small enough to run locally on Apple Silicon — and good enough to be genuinely useful — would have seemed like science fiction in 1997.

**deepThink — 2026**
Four of those models, running in parallel, on your machine, debating each other, in a Flutter app, bundled with the full Ollama runtime so you never have to configure anything.

*Deep Blue would approve.*

---

## Features

### 🧠 Parallel Inference
All four models run **simultaneously** — no round-robin, no waiting for one to finish before another starts. Each AI has its own jitter window (200–800 ms) so responses feel natural, not mechanical.

### 💬 You're Always in the Room
Hit Enter any time. The models will stop mid-debate and respond directly to you. Every AI is instructed it **must** respond to human input — no passing, no ignoring, no filler.

### 🔄 Smart Context Management
Each model's context window is tracked. When an AI hits 90% capacity, it gracefully resets using the last 2 messages per participant as a seed — so the conversation continues without a hard break.

### 🏷️ You Can Name Yourself
Tell any AI "call me Alex" or "my name is Jordan" mid-conversation and your name updates automatically in the UI. They'll use it going forward.

### 📊 Live Resource Gate
Not enough free RAM? deepThink shows you a live command centre with:
- A real-time RAM gauge (updated every 2 seconds)
- The top memory-consuming processes — with AI tools highlighted
- Per-model readiness as your RAM clears up
- **Auto-provisioning** the moment you free enough memory — no button needed

### 🏠 Fully Offline
After the one-time model download (~22.5 GB), deepThink never touches the internet again. No telemetry. No analytics. No license checks.

### 🎲 Fun Session Names
Every session gets a procedurally generated lowerCamelCase name: `thetaByte`, `thorKitten`, `neonSage`. Because why not.

---

## System Requirements

| | Minimum | Recommended |
|--|---------|-------------|
| **OS** | macOS 13 (Ventura) | macOS 14+ (Sonoma) |
| **CPU** | Apple M1 | Apple M2 Max or better |
| **RAM** | 24 GB free | 48 GB+ free |
| **Disk** | 30 GB free | 50 GB+ free |
| **GPU** | Metal-capable | Apple Silicon unified memory |

> **Windows:** Supported but requires self-compilation. See [`windows/BUILD.md`](windows/BUILD.md).

### Why so much RAM?
The four models together need ~22.5 GB of RAM to all stay loaded simultaneously:

```
mistral:7b   ████████░░░░░░░░░░░░  4.1 GB
llama3:8b    ██████████░░░░░░░░░░  4.7 GB
gemma2:9b    ████████████░░░░░░░░  5.5 GB
phi3:14b     ████████████████████  8.2 GB
─────────────────────────────────────────
Total        ░░░░░░░░░░░░░░░░░░░░  22.5 GB
```

On Apple Silicon, model weights live in the unified memory pool shared with the GPU — loading them once and keeping them resident (`OLLAMA_KEEP_ALIVE=-1`) means instant inference with no reload overhead.

---

## Installation

### Option A — Download DMG *(easiest)*

1. Download `deepThink-v1.0.1.dmg` from [Releases](https://github.com/007Style/deepThink/releases)
2. Open the DMG
3. Drag **deepThink** to your Applications folder
4. Launch — deepThink handles the rest

> **First launch:** macOS may show a security prompt because the app isn't notarized.
> Open **System Preferences → Security & Privacy** and click **Open Anyway**.

### Option B — Build from Source

```bash
# Prerequisites: Flutter 3.x, Xcode 15+, Git LFS, CocoaPods
git clone https://github.com/007Style/deepThink.git
cd deepThink
git lfs pull
flutter pub get
cd macos && pod install && cd ..
flutter run -d macos
```

Full instructions: [`DEVELOPMENT.md`](DEVELOPMENT.md)

---

## First Launch

```
1. ⚡ Splash screen          Ollama starts in the background
                             Hardware detected (RAM, GPU)
                             Models checked

2. 🧠 Welcome screen         See your system specs
                             See which models need downloading

3. 📥 Download screen        ~22.5 GB, one time only
                             Progress per model
                             Resumable (safely cancel and come back)

4. ⚙️  Config screen          Choose models for each character
                             Name your session (or roll the dice 🎲)
                             See live RAM allocation

5. 💬 Main screen            Press Start
                             DEEP opens the conversation
                             Watch them think, agree, disagree
                             Type anything — they'll respond
```

---

## Architecture at a Glance

```
lib/
├── core/               ← Pure Dart. Zero Flutter imports. Ever.
│   ├── conversation/   ConversationEngine · InferenceWorker × 4
│   ├── ollama/         OllamaClient · Launcher · HardwareDetector
│   ├── context/        ContextManager (90% reset threshold)
│   ├── session/        SessionManager · NameGenerator · AppStats
│   └── system/         ResourceMonitor (2s polling)
│
└── ui/                 ← Flutter
    ├── screens/        ResourceGate · Welcome · Download · Config · Main
    ├── quadrants/      2×2 AI conversation panels
    ├── avatars/        Plugin avatar system · Energy orb renderer
    └── widgets/        Theme · Input bar · Status band · Help menu
```

The core layer being pure Dart means the entire conversation engine can be ported to a
native SwiftUI or WinUI 3 shell without touching the logic. That's the plan.

Full documentation: [`ARCHITECTURE.md`](ARCHITECTURE.md)

---

## The Models

| Model | Parameters | Context (64 GB machine) | Speciality |
|-------|-----------|------------------------|------------|
| `phi3:14b` | 14 billion | 131,072 tokens | Reasoning depth, long-form analysis |
| `gemma2:9b` | 9 billion | 32,768 tokens | Structured thinking, factual precision |
| `llama3:8b` | 8 billion | 32,768 tokens | Natural language, creative expression |
| `mistral:7b` | 7 billion | 32,768 tokens | Speed, debate, structured argumentation |

Context windows scale automatically with your hardware tier (32 / 48 / 64 / 128 GB).

---

## Testing

```bash
flutter test            # 132 tests, all passing
flutter analyze         # zero warnings
```

Test coverage spans every core class:

```
✓ ConversationLog     (append, stream, getLastN, getLastNPerParticipant)
✓ Message             (construction, UUID, isPass, toPlainText)
✓ Participant         (defaults, 4 characters, masterPrompts)
✓ SystemPromptBuilder (prompt content, context window selection)
✓ UserNameDetector    (12 rename patterns, length limits, edge cases)
✓ ContextManager      (recordTokens, needsReset at 90%, buildResetSeed)
✓ ModelRegistry       (4 models, findById, total RAM)
✓ HardwareDetector    (RamTier classification, context window tiers)
✓ ModelPullProgress   (percent calculation, isDone, edge cases)
✓ NameGenerator       (lowerCamelCase, uniqueness, seeded Random)
✓ AppStats            (counters, date fields, toString)
✓ Session             (construction, JSON round-trip, toString)
✓ Widget smoke test   (splash screen renders)
```

---

## Contributing

Pull requests are welcome. A few things to keep in mind:

- **`lib/core/` must stay Flutter-free.** This is a hard rule.
- **New core logic needs unit tests.** See `test/core/` for examples.
- **Run `flutter analyze` before opening a PR.** Zero warnings required.
- **Follow the commit message convention:** `feat:`, `fix:`, `chore:`, `test:`, `docs:`

See [`DEVELOPMENT.md`](DEVELOPMENT.md) for setup instructions and a guide to adding
new characters or avatar types.

---

## Roadmap

- [ ] **Windows binary release** — self-compile guide exists; official release pending
- [ ] **Session replay** — load previous conversations from the NDJSON logs
- [ ] **Custom characters** — define your own AI personality in the config screen
- [ ] **Topic injection** — pre-seed conversations with a document or URL
- [ ] **Export** — export a conversation as Markdown or PDF
- [ ] **SwiftUI shell** — native macOS rewrite using the existing pure-Dart core
- [ ] **Model auto-update** — detect and offer newer model versions

---

## FAQ

**Q: Does this require an internet connection?**
After the one-time model download, no. deepThink runs 100% locally forever.

**Q: Does deepThink send my conversations anywhere?**
No. Nothing leaves your machine. There is no telemetry, no analytics endpoint, no account system.

**Q: What if a download fails?**
Hit **Retry**. If you keep getting `EOF` errors, run:
```bash
rm ~/.ollama/models/blobs/*-partial*
```
This clears corrupted partial blobs from a previous interrupted download. Then retry.

**Q: Can I use different models?**
The four characters have assigned models by default. In the Config screen you can reassign
models to characters. Any model already installed in your `~/.ollama/models/` folder will appear.

**Q: Why does deepThink bundle Ollama instead of using the installed version?**
To guarantee a known-good runtime version and eliminate setup friction. deepThink v1.0.1
bundles Ollama v0.32.9. If you have a system Ollama running on port 11434, deepThink will
detect it and use it rather than launching its own copy.

**Q: The app "just went away" without an error. What happened?**
Most likely another process consumed all available RAM while a model was loading. Close
browser tabs and any other AI tools, then relaunch. The Resource Gate screen will show you
exactly what's consuming memory.

**Q: Why four models? Why these four?**
Size diversity: from 7B to 14B parameters. Architecture diversity: Mistral, LLaMA, Gemma,
and Phi represent four different design philosophies. They genuinely disagree with each other
in interesting ways — which is the point.

---

## Credits & Acknowledgements

**Built by:**
- **Daneyand** — Vision, design, direction · daneyand@ibm.com
- **IBM's Bob** — Architecture, engineering, every line of code

**Standing on the shoulders of:**
- [Ollama](https://ollama.com) — The runtime that makes local LLMs accessible
- [Flutter](https://flutter.dev) — The framework that makes one codebase run everywhere
- [Mistral AI](https://mistral.ai) — mistral:7b
- [Meta AI](https://ai.meta.com) — llama3:8b
- [Google DeepMind](https://deepmind.google) — gemma2:9b
- [Microsoft Research](https://research.microsoft.com) — phi3:14b
- [IBM Research](https://research.ibm.com) — 70 years of asking "what if machines could think?"

---

<div align="center">

*"The question of whether a machine can think is about as interesting*
*as the question of whether a submarine can swim."*
— Edsger W. Dijkstra

---

*deepThink v1.0.1 · macOS · Flutter · Ollama · Built with ❤️ and IBM heritage*

*From the minds of Daneyand & IBM's Bob*

</div>
