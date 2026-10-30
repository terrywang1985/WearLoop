# Fashionpedia YOLOv8n model provenance

The runtime file `../../assets/models/fashionpedia_yolov8n.onnx` is an **unmodified** copy of:

`https://huggingface.co/louisJLN/yolo8-fashionpedia/resolve/2341a0b6fccba6c2349a429d243d15956b5973ee/results/yolov8n-fashionpedia-1.onnx`

The publisher's LFS SHA256 and the local runtime asset both equal:

`6b581af3abe2b4ae97a84cbe9aef5ae37207a68ee966d22b0b8d7969d79e6920` (12,273,953 bytes).

This exact hash match identifies the published artifact. It does not establish that WearLoop trained the model. WearLoop did not train, fine-tune or re-export it.

## Preserved notices and source material

The original ONNX metadata identifies `Ultralytics`, version `8.1.47`, description `Ultralytics best model trained on fashionpedia.yaml`, and `AGPL-3.0 License (https://ultralytics.com/license)`. That metadata remains untouched. The upstream model card separately declares `license: mit`; the original card is preserved verbatim as `upstream/README.md`. WearLoop does not treat the card as permission to remove underlying Ultralytics notices.

At the pinned revision the publisher supplies the files preserved in `upstream-files.json`. They are retained byte-for-byte under `upstream/`:

- Model card, dataset class YAML and training argument YAML.
- Training/inference notebook and dataset-to-YOLO conversion notebook.
- Published nano-model training report.

The matching Ultralytics model architecture YAML and package metadata are retained in `../ultralytics/`, with exact official URLs/hashes in `../license-source-records.json`. Full upstream implementation source: [Ultralytics v8.1.47](https://github.com/ultralytics/ultralytics/tree/v8.1.47). It is not executed by this source-preparation process.

## Rebuilding the app versus retraining the model

Building WearLoop uses the included ONNX asset and the first-party inference integration. It does **not** require a dataset, a PyTorch installation, a training run, an online inference service or unpublished weights. The ONNX graph and parameter tensors are included and can be inspected or modified with ONNX tooling. The public source includes the code and scripts needed to build and install a modified app using that asset or a replacement.

The available upstream notebook demonstrates a small-model training configuration, while the separate published arguments/report identify a nano run. The pinned repository does not supply the original training `best.pt`, a fully pinned training environment or all random-state/checkpoint history. Therefore we do **not** claim bit-for-bit retraining or re-export reproduction of the supplied model. To reproduce the shipped app, preserve and verify the supplied ONNX bytes. To conduct new training, obtain Fashionpedia under its own terms and use the disclosed upstream configuration/source; record and license any newly generated weights appropriately.

No upstream training/test photographs, dataset archives, dataset annotation dumps, unrelated model checkpoints or unrelated training notebooks from the private workspace are included. User wardrobe photos and databases are never part of the source release.

The artifact provenance and metadata are also recorded in `../../MODEL_PROVENANCE.json`. The complete WearLoop application is distributed under AGPL-3.0-only; see `../../LICENSE` and `../../NOTICE`.
