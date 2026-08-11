# deepThink

> Four AI minds. One conversation. Zero internet required.

![deepThink screenshot placeholder](docs/screenshot.png)

`deepThink` is a local AI conversation application where four distinct AI personalities — **WATSON**, **DEEP**, **NOVA**, and **SAGE** — hold an ongoing discussion with each other while you watch, listen, and interject at any time. All four models run **in parallel** (not round-robin), powered by [Ollama](https://ollama.com) running completely on your machine.

Built with Flutter/Dart for **macOS** (primary) and **Windows** (same codebase), packaged as a `.dmg` for macOS and available as source-compile for Windows.

---

## Characters

| Name | IBM Reference | Personality | Default Model |
|------|--------------|-------------|---------------|
| **WATSON** | IBM Watson AI | The Analyst — methodical, evidence-driven, breaks problems into structured components | `gemma2:9b` |
| **DEEP** | Deep Blue chess computer | The Host — Strategist & Philosopher, orchestrates the flow and challenges assumptions | `phi3:14b` |
| **NOVA** | IBM POWER systems | The Visionary — expansive lateral thinker, makes unexpected connections | `llama3:8b` |
| **SAGE** | IBM natural language research | The Challenger — incisive critic, never lets a weak argument slide | `mistral:7b` |

Each character has a configurable master system prompt that you can edit before each session. Their default personalities are tuned to create genuine intellectual tension and produce conversation worth reading.

---

## AI Models

| Model | Ollama Tag | ~RAM | Description |
|-------|-----------|------|-------------|
| Mistral 7B | `mistral:7b` | ~4.1 GB | The all-rounder — fast, sharp, great at debate and structured thinking |
| Llama 3 8B | `llama3:8b` | ~4.7 GB | Natural and expressive — great for free-flowing creative discussion |
| Gemma 2 9B | `gemma2:9b` | ~5.5 GB | Precise and clear — excellent at breaking down complex ideas cleanly |
| Phi-3 14B | `phi3:14b` | ~8.2 GB | Deep reasoning — punches above its size, best for philosophical depth |

All four models are downloaded on first launch (~22 GB total). After that the app runs **fully offline**. Model sizes and a live RAM total are displayed in the UI during model/character assignment.

> **Default full stack RAM:** ~22.5 GB. Recommended minimum: 32 GB unified memory (Apple Silicon) or 32 GB system RAM (Windows).

---

## Context Window Tiers (Auto-detected)

| Machine RAM | Standard Models | phi3:14b |
|-------------|----------------|----------|
| 32 GB | 8K tokens | 32K tokens |
| 48 GB | 16K tokens | 64K tokens |
| 64 GB | 32K tokens | 128K tokens |
| 128 GB+ | 64K tokens | 128K tokens (max) |

Context windows are selected automatically at startup based on detected RAM. `phi3:14b` always receives the largest available context window.

---

## Features

- **Parallel inference** — all four AIs generate responses concurrently, not in sequence
- **Pass logic** — each AI can choose to stay silent rather than produce low-quality filler
- **User interjection** — type at any time; all four AIs receive your message simultaneously
- **Session naming** — name your session or auto-generate a fun lowerCamelCase name (e.g. `thetaByte`, `thorKitten`)
- **Conversation logs** — every session saved to `~/Documents/deepThink/sessions/` as plain text
- **RAM-aware context** — context windows scale automatically with available memory
- **Fully offline** — zero network calls after model download; Ollama is bundled inside the app
- **Energy Orb avatars** — animated particle orbs for each character with idle / thinking / speaking / waiting states
- **User rename easter egg** — mention your name in chat; the AIs will pick it up and start using it

---

## Prerequisites

### macOS

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 13 Ventura or later | Apple Silicon (M1/M2/M3/M4) recommended |
| Xcode | 15+ | Required for macOS Flutter builds |
| Flutter | 3.22+ | Install via `brew install --cask flutter` |
| CocoaPods | Latest | `sudo gem install cocoapods` |
| Git | Any | Pre-installed on macOS |

### Windows

See [`windows/BUILD.md`](windows/BUILD.md) for full Windows build instructions.

| Requirement | Version | Notes |
|-------------|---------|-------|
| Windows | 10 or 11 (64-bit) | |
| Flutter | 3.22+ | [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows) |
| Visual Studio | 2022 | Desktop development with C++ workload required |
| Git for Windows | Any | |

---

## macOS Build Instructions

### 1. Install dependencies

```bash
brew install --cask flutter
sudo gem install cocoapods
```

### 2. Clone the repository

```bash
git clone https://github.com/007Style/deepThink.git
cd deepThink
```

### 3. Get Flutter packages

```bash
flutter pub get
```

### 4. Run in development

```bash
flutter run -d macos
```

### 5. Build a release `.app`

```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/deepThink.app
```

### 6. Package as a `.dmg` (requires `create-dmg`)

```bash
brew install create-dmg
./scripts/build_dmg.sh
# Output: build/deepThink-<version>.dmg
```

---

## Windows Build

See [`windows/BUILD.md`](windows/BUILD.md) for the full step-by-step guide.

Quick summary:

```powershell
flutter pub get
flutter build windows --release
# Output: build\windows\x64\runner\Release\deepThink.exe
```

---

## Project Architecture

```
deepThink/
├── lib/
│   ├── core/                     ← Pure Dart, ZERO Flutter imports
│   │   ├── ollama/               ← Ollama process + REST client + model management
│   │   ├── conversation/         ← Parallel inference engine + conversation log
│   │   ├── context/              ← Context window tracking + reset logic
│   │   └── session/              ← Session lifecycle + log persistence
│   └── ui/                       ← Flutter only
│       ├── avatars/energy_orb/   ← Animated particle orb avatars
│       ├── quadrants/            ← 2×2 AI panel grid
│       ├── widgets/              ← Shared UI components
│       ├── about/                ← Animated about screen
│       └── screens/              ← App screens (main, startup, first-launch, help)
├── assets/ollama/
│   ├── macos/                    ← Bundled Ollama binary (macOS arm64 + x64)
│   └── windows/                  ← Bundled Ollama binary (Windows x64)
├── scripts/
│   └── build_dmg.sh
├── windows/
│   └── BUILD.md
└── .github/workflows/
    ├── build_macos.yml
    └── build_windows.yml
```

**Portability note:** `lib/core/` contains zero Flutter imports — pure Dart only. This means the entire business logic layer can be ported to a native SwiftUI/WinUI 3 dual codebase in the future by rebuilding only the UI layer.

---

## Sessions & Logs

Session conversation logs are saved continuously (not just at end) to:

- **macOS:** `~/Documents/deepThink/sessions/<session-name>.txt`
- **Windows:** `%USERPROFILE%\Documents\deepThink\sessions\<session-name>.txt`

Log format:
```
[2025-01-15 14:32:01] DEEP: The question isn't whether consciousness emerges from complexity...
[2025-01-15 14:32:04] WATSON: I'd argue we need to define our terms more carefully first.
[2025-01-15 14:32:07] User: What do you all think about the Chinese Room argument?
```

---

## Manual Model Installation

If automatic model download fails, see **Help → Model Downloads & Manual Installation** inside the app, or follow these steps:

1. Install Ollama from [ollama.com/download](https://ollama.com/download)
2. Open Terminal and run:
   ```bash
   ollama pull mistral:7b
   ollama pull llama3:8b
   ollama pull gemma2:9b
   ollama pull phi3:14b
   ```
3. Verify: `ollama list`

Models are stored at:
- **macOS:** `~/.ollama/models/`
- **Windows:** `%USERPROFILE%\.ollama\models\`

---

## License

MIT License — see [LICENSE](LICENSE).

---

*From the minds of Daneyand & IBM's Bob*  
daneyand@ibm.com
