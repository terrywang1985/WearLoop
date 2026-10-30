# Third-party notices

WearLoop is provided as a whole under AGPL-3.0-only; original notices and license grants for its dependencies remain intact. The root `LICENSE` contains the full AGPL version 3 text. First-party copyright is **2026 WearLoop contributors**. This file does not claim authorship of upstream code or model training.

## Bundled detection model

- Artifact: `assets/models/fashionpedia_yolov8n.onnx`.
- Publisher/source: [louisJLN/yolo8-fashionpedia](https://huggingface.co/louisJLN/yolo8-fashionpedia), pinned revision `2341a0b6fccba6c2349a429d243d15956b5973ee`.
- Original filename: `results/yolov8n-fashionpedia-1.onnx`.
- SHA256: `6b581af3abe2b4ae97a84cbe9aef5ae37207a68ee966d22b0b8d7969d79e6920`.
- The artifact's embedded metadata identifies Ultralytics 8.1.47 and AGPL-3.0. The publisher's model card declares MIT and describes Fashionpedia fine-tuning. Both statements are preserved, without replacing the model's embedded notice.
- `third_party/fashionpedia/` contains the unmodified available upstream model card, training notebook, dataset-conversion notebook, dataset class configuration, training arguments and report, with a provenance manifest. `third_party/ultralytics/` retains the matching model architecture configuration and package metadata. The upstream implementation is available at [Ultralytics v8.1.47](https://github.com/ultralytics/ultralytics/tree/v8.1.47).
- The model weights are bundled unmodified. WearLoop's preprocessing, decoding, NMS, garment filtering, category mapping and shoe merging are first-party source in `lib/services/fashion_detector.dart`.

## Fashionpedia attribution

The model publisher identifies Fashionpedia as the training dataset. The [dataset card](https://huggingface.co/datasets/detection-datasets/fashionpedia) declares CC BY 4.0; the [original CVDF project](https://github.com/cvdfoundation/fashionpedia) provides the images and annotations and records individual image licenses. No training images, dataset archives, image annotations or upstream sample photos are redistributed in this source release. Dataset access and retraining remain subject to the dataset and individual image terms.

Citation: Menglin Jia, Mengyun Shi, Mikhail Sirotenko, Yin Cui, Claire Cardie, Bharath Hariharan, Hartwig Adam and Serge Belongie, *Fashionpedia: Ontology, Segmentation, and an Attribute Localization Dataset*, ECCV 2020, [paper](https://arxiv.org/abs/2004.12276).

## Flutter, Dart and packages

Versions and archive integrity hashes are pinned in `pubspec.lock`. Exact license/notice texts copied from the resolved package sources are retained in `third_party/licenses/dart/`; `third_party/dart-license-inventory.json` lists them. This is a conservative inventory of the resolved runtime, platform, transitive, SDK and development packages. It does not claim every listed development package is present in the Android binary.

Flutter's distributed runtime/font/engine notices are retained in `third_party/licenses/flutter-runtime-notices.txt`, extracted from the Flutter-generated `NOTICES.Z` asset. The application also exposes Flutter's built-in package license registry. Unmodified dependency source is available through the packages and archive hashes identified by the lockfile and their upstream repositories.

Important direct packages include `provider`, `shared_preferences`, `image_picker`, `share_plus`, `flutter_onnxruntime`, `image`, `sqflite`, `path_provider`, `intl`, `cupertino_icons` and the Flutter localization SDK packages. Consult their exact preserved notices rather than inferring a license from a package name.

## ONNX Runtime

The Android inference dependency resolves to `com.microsoft.onnxruntime:onnxruntime-android:1.28.0`, through `flutter_onnxruntime` 1.9.0. ONNX Runtime is copyright Microsoft Corporation and distributed under the MIT License. Its exact official versioned `LICENSE` and `ThirdPartyNotices.txt` are preserved under `third_party/onnxruntime/`. Source: [Microsoft ONNX Runtime v1.28.0](https://github.com/microsoft/onnxruntime/tree/v1.28.0). The broader upstream notice file can cover components/configurations not present in this specific Android build; it is retained without removing original conditions.

## Android build/platform dependencies

The app uses AndroidX/Jetpack libraries through the pinned Flutter plugins and Google's Android Gradle Plugin, with Gradle and Kotlin build tooling. Their original Apache/BSD/other compatible notices remain applicable. They are general-purpose, unmodified upstream dependencies obtained by Flutter/Gradle, not authored by WearLoop. Android and Flutter platform libraries and toolchains are obtained separately; this source release does not bundle the Android SDK, a JDK, Flutter SDK or private signing material.

## Demonstration images and brand assets

The 14 clothing cutouts are AI-generated demonstration assets created for WearLoop, with original image outputs and prompts retained under `assets/clothing/`. They are not real user wardrobe photos and are not Fashionpedia samples. First-party app source, visual assets and related materials are offered under the project AGPL terms to the extent the project owner holds applicable rights. Third-party trademarks and upstream project names do not imply endorsement or a trademark license.
