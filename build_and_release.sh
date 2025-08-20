#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the array of flavors based on your project structure.
flavors=("poteu" "pteep" "height_rules" "fz116" "fire_reg")

# Get the current version from pubspec.yaml
version=$(grep 'version:' pubspec.yaml | awk '{print $2}')

# Create a directory for the release artifacts if it doesn't exist.
mkdir -p releases

echo "Starting build process for version $version..."

# Loop through each flavor and build it.
for flavor in "${flavors[@]}"
do
  echo "--------------------------------------------------"
  echo "Building flavor: $flavor"
  echo "--------------------------------------------------"

  # 1. Clean previous build artifacts.
  echo ">>> Cleaning project..."
  flutter clean

  # 2. Get dependencies.
  flutter pub get

  # 3. Generate app icons for the specific flavor.
  echo ">>> Generating icons for $flavor..."
  flutter pub run flutter_launcher_icons:main -f flutter_launcher_icons-$flavor.yaml

  # 4. Build the Android App Bundle (.aab) for the flavor.
  echo ">>> Building App Bundle for $flavor..."
  flutter build appbundle --flavor "$flavor"

  # 5. Move and rename the generated .aab file to the releases directory.
  echo ">>> Moving and renaming artifact..."
  mv "build/app/outputs/bundle/${flavor}Release/app-${flavor}-release.aab" "releases/${flavor}-v${version}.aab"

  echo ">>> Successfully built $flavor v$version!"
done

echo "--------------------------------------------------"
echo "All builds completed successfully!"
echo "Release artifacts are located in the 'releases' directory."
echo "--------------------------------------------------"