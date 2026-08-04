#!/data/data/com.termux/files/usr/bin/sh
# Mycelium Phone Setup — One-line bootstrap for Android Termux
# Usage: sh /sdcard/Download/mycelium-phone.sh
#
# For Android 6 (LG G4): sh /sdcard/Download/mycelium-phone.sh android6
#
# This script:
# 1. Installs build tools (clang, cmake, make, git, libzmq)
# 2. Clones the patched prima.cpp from AR-Davis/prima.cpp
# 3. Applies Android-specific fixes
# 4. Builds rpc-server
# 5. Starts it with setsid, bound to 0.0.0.0:50052
#
# Prerequisites: Termux installed (from F-Droid), storage permission granted.

set -e

ANDROID6="${1:-}"
MYCELIUM_HOME="$HOME/mycelium"
SOURCE_DIR="$MYCELIUM_HOME/prima.cpp"
BUILD_DIR="$MYCELIUM_HOME/build"

echo "============================================"
echo "  Mycelium Phone Setup"
echo "============================================"
if [ -n "$ANDROID6" ]; then
    echo "  Mode: Android 6 (LG G4 — legacy fixes enabled)"
else
    echo "  Mode: Android 11+ (standard)"
fi
echo "  Home: $HOME"
echo "  Target: $MYCELIUM_HOME"
echo "============================================"
echo ""

# ─── Step 1: Install build tools ───────────────────────────────
echo "[1/6] Installing build tools..."
pkg update -y 2>/dev/null || true
pkg install -y clang cmake make git libzmq 2>/dev/null || {
    # Fallback: install individually
    pkg install -y clang
    pkg install -y cmake
    pkg install -y make
    pkg install -y git
    pkg install -y libzmq
}
echo "  Done."
echo ""

# ─── Step 2: Clone source ──────────────────────────────────────
echo "[2/6] Cloning prima.cpp (patched, from AR-Davis)..."
mkdir -p "$MYCELIUM_HOME"
if [ -d "$SOURCE_DIR/.git" ]; then
    echo "  Source exists, pulling latest..."
    cd "$SOURCE_DIR"
    git pull --quiet || true
else
    # Try git clone first; if too slow, user can use tarball fallback
    git clone --depth 1 https://github.com/AR-Davis/prima.cpp.git "$SOURCE_DIR" 2>&1 || {
        echo "  git clone failed (slow connection?). Trying tarball from TheTower..."
        echo "  If you have a tarball at /sdcard/Download/prima-cpp-matched-src.tar.gz:"
        echo "    tar xzf /sdcard/Download/prima-cpp-matched-src.tar.gz -C $MYCELIUM_HOME"
        echo "  Then re-run this script."
        exit 1
    }
fi
echo "  Done."
echo ""

# ─── Step 3: Apply Android fixes ─────────────────────────────────
echo "[3/6] Applying Android-specific fixes..."
cd "$SOURCE_DIR"

# Fix 1: Remove llama dependency from rpc-server (rpc-server.cpp doesn't use llama)
RPC_CMAKE="examples/rpc/CMakeLists.txt"
if grep -q "target_link_libraries.*llama" "$RPC_CMAKE" 2>/dev/null; then
    sed -i 's/target_link_libraries(rpc-server PRIVATE ggml llama)/target_link_libraries(rpc-server PRIVATE ggml)/' "$RPC_CMAKE"
    echo "  Fix 1/4: Removed llama dependency from rpc-server CMakeLists"
fi

# Fix 2: HWCAP defines missing on older Android (Android 6 headers don't define these)
# These are needed by ggml's CPU feature detection
HWCAP_FILE="ggml/src/ggml-cpu/ggml-cpu.c"
if [ -n "$ANDROID6" ]; then
    # Create HWCAP defines if not present
    if ! grep -q "HWCAP_ASIMD" "$HWCAP_FILE" 2>/dev/null; then
        # Add defines at the top of the file after includes
        sed -i '/#include/a\
#ifndef HWCAP_ASIMD\
#define HWCAP_ASIMD (1 << 1)\
#endif\
#ifndef HWCAP_SVE\
#define HWCAP_SVE (1 << 22)\
#endif' "$HWCAP_FILE" 2>/dev/null || true
        echo "  Fix 2/4: Added HWCAP_ASIMD/HWCAP_SVE defines (Android 6)"
    fi
fi

# Fix 3: profiler.h includes llama.h — create a stub that doesn't
# (rpc-server build doesn't need llama, but common/profiler.h pulls it in)
PROFILER_H="common/profiler.h"
if [ -f "$PROFILER_H" ] && grep -q '#include "llama.h"' "$PROFILER_H" 2>/dev/null; then
    # Comment out the llama.h include in profiler.h
    sed -i 's/#include "llama.h"/\/\/#include "llama.h" -- removed by mycelium-phone.sh/' "$PROFILER_H"
    echo "  Fix 3/4: Commented out llama.h in profiler.h"
fi

# Fix 4: Ensure TMPDIR exists (Android 6 doesn't have /tmp)
export TMPDIR="${TMPDIR:-$HOME/tmp}"
mkdir -p "$TMPDIR"
echo "  Fix 4/4: TMPDIR set to $TMPDIR"
echo ""

# ─── Step 4: Build rpc-server ───────────────────────────────────
echo "[4/6] Building rpc-server (this may take 10-30 minutes)..."
echo "  Building in: $SOURCE_DIR"
echo "  CPU threads: $(nproc)"

cd "$SOURCE_DIR"

# Build with cmake (more reliable on Android than raw make)
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$SOURCE_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_RPC=ON \
    -DGGML_CUDA=OFF \
    -DGGML_METAL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    2>&1 | tail -5

# Build just rpc-server (not all examples)
cmake --build . --target rpc-server -j"$(nproc)" 2>&1 | tail -10
echo "  Done."
echo ""

# ─── Step 5: Install and verify ─────────────────────────────────
echo "[5/6] Installing rpc-server..."
cp "$BUILD_DIR/bin/rpc-server" "$MYCELIUM_HOME/rpc-server" 2>/dev/null || \
cp "$BUILD_DIR/rpc-server" "$MYCELIUM_HOME/rpc-server" 2>/dev/null || \
    find "$BUILD_DIR" -name "rpc-server" -type f -exec cp {} "$MYCELIUM_HOME/rpc-server" \;
chmod +x "$MYCELIUM_HOME/rpc-server"
echo "  Installed to: $MYCELIUM_HOME/rpc-server"
echo ""

# ─── Step 6: Start the compute node ─────────────────────────────
echo "[6/6] Starting rpc-server on 0.0.0.0:50052..."
echo ""
echo "============================================"
echo "  BUILD COMPLETE"
echo "============================================"
echo "  Binary: $MYCELIUM_HOME/rpc-server"
echo "  Port: 50052"
echo ""
echo "  The rpc-server is starting in the background."
echo "  It will survive ADB disconnect (setsid)."
echo ""
echo "  To check if it's running:"
echo "    ps aux | grep rpc-server"
echo ""
echo "  To stop it:"
echo "    pkill rpc-server"
echo ""
echo "  To start it again later:"
echo "    setsid $MYCELIUM_HOME/rpc-server -H 0.0.0.0 -p 50052 &"
echo "============================================"
echo ""

# Start with setsid so it survives terminal/ADB disconnect
setsid "$MYCELIUM_HOME/rpc-server" -H 0.0.0.0 -p 50052 &
sleep 2

# Verify it started
if pgrep -x rpc-server >/dev/null 2>&1; then
    echo "SUCCESS: rpc-server is running."
else
    echo "WARNING: rpc-server may not have started. Check errors above."
    echo "  Try running manually: $MYCELIUM_HOME/rpc-server -H 0.0.0.0 -p 50052"
fi