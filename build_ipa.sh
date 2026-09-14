#!/bin/bash
set -euo pipefail

# 0. สั่ง Flutter เตรียม Engine/Assets โดยไม่ต้องผ่าน Code Signing Validation
echo "Running Flutter Build Pre-configuration..."
flutter build ios --release --config-only

# ย้ายเข้าโฟลเดอร์ ios (หากรันสคริปต์จาก Root ของโปรเจกต์ Flutter)
if [ -d "ios" ]; then
  cd ios
fi

rm -rf build/
mkdir -p build

echo "Build Started!"
echo

# 1. เช็กหา Workspace (Flutter ใช้ Runner.xcworkspace)
if [ -d "Runner.xcworkspace" ]; then
  BUILD_FLAG="-workspace Runner.xcworkspace"
elif ls -d *.xcworkspace >/dev/null 2>&1; then
  WORKSPACE_FILE=$(ls -d *.xcworkspace | head -n 1)
  BUILD_FLAG="-workspace $WORKSPACE_FILE"
elif ls -d *.xcodeproj >/dev/null 2>&1; then
  PROJECT_FILE=$(ls -d *.xcodeproj | head -n 1)
  BUILD_FLAG="-project $PROJECT_FILE"
else
  echo "Error: No .xcworkspace or .xcodeproj found!"
  exit 1
fi

PROJECT_NAME="Runner"
SCHEME_NAME="Runner"

echo "Using Flag: $BUILD_FLAG"
echo "Building Scheme: $SCHEME_NAME"

# 2. สั่ง Archive ผ่าน xcodebuild
xcodebuild \
  $BUILD_FLAG \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/$PROJECT_NAME.xcarchive" \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=YES

# 3. ดึงไฟล์ .app อัตโนมัติ (จะค้นพบ Runner.app)
APP_PATH=$(find "$PWD/build/$PROJECT_NAME.xcarchive/Products/Applications" -maxdepth 1 -name "*.app" | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Error: Missing .app inside xcarchive"
  exit 1
fi

echo "Found App Bundle at: $APP_PATH"

# 4. จัดโฟลเดอร์ Payload
rm -rf "$PWD/build/Payload"
mkdir -p "$PWD/build/Payload"
cp -R "$APP_PATH" "$PWD/build/Payload/"

# 5. ทำ Pseudo-sign ด้วย ldid
APP_BINARY_NAME=$(basename "$APP_PATH" .app)
if command -v ldid >/dev/null 2>&1; then
  echo "Signing with ldid..."
  ldid -S "$PWD/build/Payload/$APP_BINARY_NAME.app/$APP_BINARY_NAME"
else
  echo "Warning: ldid not installed, skipping pseudo-signing."
fi

# 6. บีบอัดเป็น .ipa
(cd "$PWD/build" && /usr/bin/zip -qry "$PROJECT_NAME.ipa" Payload)

echo
echo "Build Successful!"
echo "IPA created at: ios/build/$PROJECT_NAME.ipa"
exit 0
