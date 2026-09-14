#!/bin/bash
set -euo pipefail

echo "Preparing iOS dependencies..."
# 1. รัน Cocoapods เพื่อผูก Flutter Engine เข้า Xcode Workspace โดยไม่ผ่าน Flutter Build CLI
if [ -d "ios" ]; then
  cd ios
  pod install || true
  cd ..
fi

rm -rf ios/build/
mkdir -p ios/build

echo "Build Started!"
echo

# 2. เช็กหา Workspace
if [ -d "ios/Runner.xcworkspace" ]; then
  BUILD_FLAG="-workspace ios/Runner.xcworkspace"
elif ls -d ios/*.xcworkspace >/dev/null 2>&1; then
  WORKSPACE_FILE=$(ls -d ios/*.xcworkspace | head -n 1)
  BUILD_FLAG="-workspace $WORKSPACE_FILE"
else
  echo "Error: No .xcworkspace found in ios/"
  exit 1
fi

PROJECT_NAME="Runner"
SCHEME_NAME="Runner"

echo "Using Flag: $BUILD_FLAG"
echo "Building Scheme: $SCHEME_NAME"

# 3. สั่ง Archive ผ่าน xcodebuild โดยตรง (ข้าม Flutter CLI validation)
xcodebuild \
  $BUILD_FLAG \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/ios/build/$PROJECT_NAME.xcarchive" \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=YES

# 4. ดึงไฟล์ .app
APP_PATH=$(find "$PWD/ios/build/$PROJECT_NAME.xcarchive/Products/Applications" -maxdepth 1 -name "*.app" | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "Error: Missing .app inside xcarchive"
  exit 1
fi

echo "Found App Bundle at: $APP_PATH"

# 5. จัดโฟลเดอร์ Payload
rm -rf "$PWD/ios/build/Payload"
mkdir -p "$PWD/ios/build/Payload"
cp -R "$APP_PATH" "$PWD/ios/build/Payload/"

# 6. ทำ Pseudo-sign ด้วย ldid
APP_BINARY_NAME=$(basename "$APP_PATH" .app)
if command -v ldid >/dev/null 2>&1; then
  echo "Signing with ldid..."
  ldid -S "$PWD/ios/build/Payload/$APP_BINARY_NAME.app/$APP_BINARY_NAME"
else
  echo "Warning: ldid not installed, skipping pseudo-signing."
fi

# 7. บีบอัดเป็น .ipa
(cd "$PWD/ios/build" && /usr/bin/zip -qry "$PROJECT_NAME.ipa" Payload)

echo
echo "Build Successful!"
echo "IPA created at: ios/build/$PROJECT_NAME.ipa"
exit 0
