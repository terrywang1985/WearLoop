# Building WearLoop 1.2.0

Use Flutter 3.47.8 (Dart 3.13.7), JDK 17 or newer, and Android SDK 36. The
application source and bundled assets are the same for Android build numbers 5
and 6; build 6 is uploaded after disabling Google Play's optional installer-source
checks. The build number is supplied by the build command rather than changing
the default development version in `pubspec.yaml`.

```sh
flutter pub get
flutter build appbundle --release --build-number=6 \
  --dart-define=WEARLOOP_SUPPORT_EMAIL=wearloop@3qk7.com \
  --dart-define=WEARLOOP_PRIVACY_URL=https://3qk7.com/wearloop/privacy/
```

For an independently signed release, configure your own Android upload keystore
using `tools/build_play_bundle.ps1` and its `-KeyProperties`, `-SupportEmail`,
`-PrivacyPolicyUrl`, and `-BuildNumber 6` arguments. The publisher's private signing
key is intentionally excluded. The portable equivalent of the script's Flutter
command is shown above; release signing must use your own key configuration.

The output is `build/app/outputs/bundle/release/app-release.aab`. Google Play's
signing keys and generated split APKs differ from a local build. Reproducing the
source behavior does not imply an identical signed file hash.

The bundled recognition model is unmodified. Model provenance, retained license
notices, and the available upstream training/export materials are described in
`MODEL_PROVENANCE.json`, `assets/legal`, and `third_party`. The source distribution is
AGPL-3.0-only; see `LICENSE`, `NOTICE`, and `THIRD_PARTY_NOTICES.md`.
