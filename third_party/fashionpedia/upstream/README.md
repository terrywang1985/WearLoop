---
model_summary: null
license: mit
datasets:
- detection-datasets/fashionpedia
language:
- en
base_model:
- Ultralytics/YOLOv8
tags:
- clothes
- second
- hand
- fashion
- repair
- tshirt
- fashionpedia
- pants
- socks
- shoes
- dress
---
# Yolo 8 trained on Fashionpedia dataset
![Inference example](results/training-metrics/val_batch2_pred.jpg)

## Model Details
YOLO8 with size S and N finetunned. It was a head traning then a full training for each size.

### Model Description

## Uses
Ultralytics YOLO8

## Training Details

### Training Data
It was trained on Fashionpedia dataset

### Training Procedure
It was trained ~10 hours on a 4070 Ti SUPER

#### Preprocessing
No modification, just format conversion.

#### Training Hyperparameters
Default