#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# NeighbourGo — macOS Setup Script
# Run once in the project root: bash setup_mac.sh
# ──────────────────────────────────────────────────────────────────────────────
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
step() { echo -e "\n${YELLOW}▶ $1${NC}"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NeighbourGo — macOS Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
step "Step 1/8: Check Homebrew"
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found. Installing…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
ok "Homebrew ready"

# ── 2. Flutter ────────────────────────────────────────────────────────────────
step "Step 2/8: Check Flutter SDK"
if ! command -v flutter &>/dev/null; then
  warn "Flutter not found. Installing via Homebrew…"
  brew install --cask flutter
fi
FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1)
ok "Flutter: $FLUTTER_VERSION"

# ── 3. Xcode command-line tools ───────────────────────────────────────────────
step "Step 3/8: Check Xcode command-line tools"
if ! xcode-select -p &>/dev/null; then
  warn "Installing Xcode command-line tools…"
  xcode-select --install
  echo "  ↳ After the installer finishes, re-run this script."
  exit 0
fi
ok "Xcode CLT present at $(xcode-select -p)"

# ── 4. CocoaPods ─────────────────────────────────────────────────────────────
step "Step 4/8: Check CocoaPods"
if ! command -v pod &>/dev/null; then
  warn "Installing CocoaPods…"
  sudo gem install cocoapods
fi
ok "CocoaPods $(pod --version)"

# ── 5. Node.js & Firebase CLI ─────────────────────────────────────────────────
step "Step 5/8: Check Node.js + Firebase CLI"
if ! command -v node &>/dev/null; then
  warn "Node.js not found. Installing via Homebrew…"
  brew install node
fi
ok "Node $(node --version)"

if ! command -v firebase &>/dev/null; then
  warn "Firebase CLI not found. Installing…"
  npm install -g firebase-tools
fi
ok "Firebase CLI $(firebase --version)"

# ── 6. FlutterFire CLI ────────────────────────────────────────────────────────
step "Step 6/8: Check FlutterFire CLI"
if ! dart pub global list 2>/dev/null | grep -q flutterfire_cli; then
  warn "Installing FlutterFire CLI…"
  dart pub global activate flutterfire_cli
fi
ok "FlutterFire CLI ready"

# ── 7. Flutter pub get + code generation ─────────────────────────────────────
step "Step 7/8: Install Flutter dependencies + run code generation"
flutter pub get
echo "  ↳ Running build_runner (generates *.freezed.dart and *.g.dart)…"
dart run build_runner build --delete-conflicting-outputs
ok "Code generation complete"

# ── 8. iOS pod install ────────────────────────────────────────────────────────
step "Step 8/8: Install iOS CocoaPods"
cd ios
pod install --repo-update
cd ..
ok "iOS pods installed"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  ✅ Setup complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Create a Firebase project at https://console.firebase.google.com"
echo "     • Enable: Authentication (Phone), Firestore, Storage, Cloud Messaging"
echo ""
echo "  2. Run FlutterFire configure to replace lib/firebase_options.dart:"
echo "     firebase login"
echo "     flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID"
echo ""
echo "  3. Open iOS simulator:"
echo "     open -a Simulator"
echo ""
echo "  4. Run the app:"
echo "     flutter run"
echo ""
echo "  5. (Optional) Deploy Cloud Functions & Firestore rules:"
echo "     cd functions && npm install && cd .."
echo "     firebase deploy --only functions,firestore:rules,storage"
echo ""
