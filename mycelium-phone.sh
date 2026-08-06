#!/data/data/com.termux/files/usr/bin/sh
# Mycelium Phone Setup — One-line bootstrap for Android Termux
# Usage: sh /sdcard/Download/mycelium-phone.sh
#
# For Android 6 (LG G4): sh /sdcard/Download/mycelium-phone.sh android6
#
# This script:
# 1. Installs build tools (clang, cmake, make, git, libzmq)
# 2. Clones the patched prima.cpp from AR-Davis/prima.cpp
# 3. Applies Android-specific fixes (HWCAP defines for Android 6)
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
    echo "  Mode: Android 6 (legacy fixes enabled)"
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
    git clone --depth 1 https://github.com/AR-Davis/prima.cpp.git "$SOURCE_DIR" 2>&1 || {
        echo ""
        echo "  git clone failed (slow connection?)."
        echo "  Alternative: copy a tarball to /sdcard/Download/ and run:"
        echo "    mkdir -p $MYCELIUM_HOME"
        echo "    tar xzf /sdcard/Download/prima-cpp-matched-src.tar.gz -C $MYCELIUM_HOME"
        echo "    mv $MYCELIUM_HOME/prima-cpp-matched-src $SOURCE_DIR"
        echo "  Then re-run this script."
        exit 1
    }
fi
echo "  Done."
echo ""

# ─── Step 3: Apply Android fixes ─────────────────────────────────
echo "[3/6] Applying Android-specific fixes..."
cd "$SOURCE_DIR"

# Fix: HWCAP defines missing on Android 6 headers
if [ -n "$ANDROID6" ]; then
    # Find the ggml cpu file that checks HWCAP
    HWCAP_FILE=$(grep -rl "HWCAP_ASIMD\|HWCAP_SVE" ggml/src/ 2>/dev/null | head -1)
    if [ -n "$HWCAP_FILE" ] && ! grep -q "define HWCAP_ASIMD" "$HWCAP_FILE" 2>/dev/null; then
        # Add defines near the top, after includes
        sed -i '/#include/a\
#ifndef HWCAP_ASIMD\
#define HWCAP_ASIMD (1 << 1)\
#endif\
#ifndef HWCAP_SVE\
#define HWCAP_SVE (1 << 22)\
#endif' "$HWCAP_FILE"
        echo "  Fix 1/2: Added HWCAP_ASIMD/HWCAP_SVE defines to $HWCAP_FILE"
    else
        echo "  Fix 1/2: HWCAP defines already present or file not found (skipping)"
    fi
fi

# Fix: TMPDIR — Android doesn't have /tmp
export TMPDIR="${TMPDIR:-$HOME/tmp}"
mkdir -p "$TMPDIR"
echo "  Fix 2/2: TMPDIR set to $TMPDIR"
echo ""

# ─── Step 4: Build rpc-server ───────────────────────────────────
echo "[4/6] Building rpc-server (this may take 10-30 minutes)..."
echo "  Building in: $BUILD_DIR"
echo "  CPU threads: $(nproc)"

cd "$SOURCE_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure — only build what we need (rpc-server)
cmake "$SOURCE_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_RPC=ON \
    -DGGML_CUDA=OFF \
    -DGGML_METAL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    2>&1 | tail -10

echo ""
echo "  Starting build..."

# Build just rpc-server target
cmake --build . --target rpc-server -j"$(nproc)" 2>&1 || {
    echo ""
    echo "  BUILD FAILED. Trying with -j1 (single thread, less memory pressure)..."
    cmake --build . --target rpc-server -j1 2>&1
}
echo "  Build complete."
echo ""

# ─── Step 5: Find and install the binary ─────────────────────────
echo "[5/6] Finding and installing rpc-server..."

# Search multiple possible locations
BINARY=""
for candidate in \
    "$BUILD_DIR/bin/rpc-server" \
    "$BUILD_DIR/rpc-server" \
    "$BUILD_DIR/examples/rpc/rpc-server" \
    "$BUILD_DIR/examples/rpc/bin/rpc-server"; do
    if [ -f "$candidate" ]; then
        BINARY="$candidate"
        break
    fi
done

# If not found in common spots, search the whole build tree
if [ -z "$BINARY" ]; then
    echo "  Searching build tree for rpc-server..."
    BINARY=$(find "$BUILD_DIR" -name "rpc-server" -type f 2>/dev/null | head -1)
fi

if [ -z "$BINARY" ]; then
    echo ""
    echo "  ERROR: rpc-server binary not found anywhere in $BUILD_DIR"
    echo "  Contents of build dir:"
    find "$BUILD_DIR" -maxdepth 3 -type f -name "*.so" -o -name "rpc*" 2>/dev/null | head -20
    echo ""
    echo "  The build may have failed. Check the output above."
    echo "  You can try building manually:"
    echo "    cd $BUILD_DIR"
    echo "    cmake --build . --target rpc-server -j1"
    exit 1
fi

echo "  Found binary at: $BINARY"
cp "$BINARY" "$MYCELIUM_HOME/rpc-server"
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
echo "  To check if running: ps aux | grep rpc-server"
echo "  To stop: pkill rpc-server"
echo "  To restart: setsid $MYCELIUM_HOME/rpc-server -H 0.0.0.0 -p 50052 &"
echo "============================================"
echo ""

# Start with setsid so it survives terminal/ADB disconnect
setsid "$MYCELIUM_HOME/rpc-server" -H 0.0.0.0 -p 50052 &
sleep 2

if pgrep -x rpc-server >/dev/null 2>&1; then
    echo "SUCCESS: rpc-server is running on port 50052."
else
    echo "WARNING: rpc-server may not have started."
    echo "  Try manually: $MYCELIUM_HOME/rpc-server -H 0.0.0.0 -p 50052"
fi