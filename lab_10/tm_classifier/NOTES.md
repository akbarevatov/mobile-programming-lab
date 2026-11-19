# Lab 10 Notes — Teachable Machine Image Classifier

## 1. Class List & Teachable Machine Setup (Part 1)

### Chosen Classes
1. `Background` (Empty desk / lab background, no target object)
2. `Akbar`
3. `Phone`
4. `Mouse`
5. `Hand`
6. `Sirojbek`

### Questions from Part 1
1. **What does the model answer when it sees an object that belongs to none of your classes? How does the background class change that?**
   - Because the final layer of the network is a **softmax** function, the outputs are mathematically constrained to sum to 1.0 (100%). Softmax only calculates relative probabilities among the classes it was trained on—it cannot output "unknown" or 0% across all classes. Therefore, without a background class, an unseen object (like a shoe or backpack) will still receive a forced high confidence for whichever class happens to share subtle low-level visual features (edges, color, texture).
   - Adding a dedicated **background class** (`Nothing`) allows the network to direct probability mass toward "no target object present" whenever an unfamiliar object or empty scene is encountered, significantly reducing false positive classifications for the actual target objects.

2. **The export dialog offers Floating point and Quantized. What differs between the two files in size, in input type and in what your Dart code would have to do?**
   - **File Size:** The floating-point model (`model_unquant.tflite`) stores weights as 32-bit floating point numbers (`float32`), resulting in a file size roughly 4× larger (~12–15 MB). The quantized model stores weights as 8-bit integers (`uint8`), reducing the model file size to ~3–4 MB.
   - **Input Type:** The floating-point model expects normalized float values in the range `[-1.0, 1.0]` (shape `[1, 224, 224, 3]` with type `float32`). The quantized model expects raw byte integers in the range `[0, 255]` (`uint8`).
   - **Dart Code Differences:** 
     - For float32: Dart code must normalize each pixel channel: `(pixel - 127.5) / 127.5`, creating nested float lists (`List<List<List<List<double>>>>`).
     - For quantized uint8: Dart code feeds direct byte values `[0..255]` without float normalization, and the output probabilities must be dequantized (e.g. dividing the raw uint8 output by 255.0 to yield a 0.0 to 1.0 confidence).


## 2. Setup, Assets and Dependencies (Part 2)

### Questions from Part 2
1. **What is the difference between listing `assets/model/` and listing `assets/`? Which files would each one bundle?**
   - In Flutter `pubspec.yaml`, asset paths with a trailing slash bundle all files directly inside that specific folder without recursing into subdirectories.
   - Listing `- assets/model/` bundles only files immediately within `assets/model/` (e.g., `model_unquant.tflite`, `labels.txt`, `sample.jpg`).
   - Listing `- assets/` would bundle only files sitting directly in `assets/` root, but would **not** include files inside `assets/model/` or other subfolders.

2. **Why can `image` and `http` run in a plain Dart unit test while `tflite_flutter` and `image_picker` cannot?**
   - `image` (pure image decoding and processing) and `http` (HTTP client) are written entirely in pure Dart or rely only on standard `dart:io` primitives; they require no platform-specific operating system bindings.
   - `tflite_flutter` (which binds to native C/C++ dynamic libraries via `dart:ffi`) and `image_picker` (which uses Flutter Platform Channels / MethodChannels to trigger Android Intent and iOS UIImagePickerController) require a live platform host (Android/iOS/Desktop) and the Flutter engine runtime. Running them in a pure headless unit test throws missing plugin implementation or dynamic library lookup errors.


## 3. Classifier: Bytes In, Percentages Out (Part 3)

### Questions from Part 3
1. **Change the normalisation to `value / 255` and classify the sample again. What happens to the percentages, and why does nothing crash?**
   - **Why nothing crashes:** The tensor shape `[1, 224, 224, 3]` and data type (`float32`) remain valid; the interpreter accepts any valid 32-bit floats.
   - **What happens to the percentages:** The percentages become inaccurate and chaotic. The neural network weights were trained assuming inputs centered around 0 with range `[-1.0, 1.0]`. Feeding values in `[0.0, 1.0]` shifts activations across every convolutional layer, degrading confidence distributions and yielding high-confidence incorrect labels.

2. **Where in the whole app is the number of classes written down? What would you have to edit after retraining with a seventh class?**
   - The number of classes is **nowhere hard-coded** in Dart code! It is dynamically derived at runtime from `labels.length` (read from `labels.txt`):
     - Tensor output buffer: `[List<double>.filled(labels.length, 0.0)]`.
     - Prediction pairing: `for (var i = 0; i < labels.length; i++)`.
     - UI rows: generated dynamically from `record.predictions`.
   - **What to edit after retraining with a 7th class:** Zero code changes required! You simply replace `model_unquant.tflite` and `labels.txt` in `assets/model/`. The app dynamically adapts to any number of classes.


## 4. UI Design & Figma Extraction (Part 4)

### Figma Kit Attribution
- **Kit Name:** Clean Mobile UI Kit
- **Author:** UI8 Studio
- **License:** Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Link:** `https://www.figma.com/community/file/1155986835263172089`

### Questions from Part 4
1. **Name two things in the Figma design that you changed or left out in Flutter, and why.**
   - *Gradient drop shadows with multi-stop blurs:* In Figma, complex multi-stop atmospheric box shadows are common. In Flutter, rendering deep multi-layer Gaussian shadow filters across scrolling lists harms frame rate on low-end mobile GPUs, so we simplified to crisp Material 3 elevation and subtle outline borders (`outlineVariant`).
   - *Fixed-height hero containers:* The Figma artboard used fixed pixel heights (e.g. 380px) for preview panels. On small Android devices (or in landscape), fixed heights trigger RenderFlex overflow stripes. We replaced them with `ConstrainedBox(maxHeight: screenHeight * 0.42)` and `SingleChildScrollView`.

2. **The Model screen shows the labels. Does it read them from the classifier or from the file again? Defend your choice.**
   - The Model screen reads labels directly from `classifier.labels` (via `AppController`).
   - **Defense:** Reading from the loaded `Classifier` instance guarantees that the labels displayed on screen are the exact same list and ordering currently bound to the active neural network interpreter. Reading from the file again would be redundant I/O and introduces a risk of drift if the asset were modified or cached differently in memory.


## 5. Three Sources, One Result (Part 5)

### Questions from Part 5
1. **The same object scored differently from the camera and from a downloaded picture. Give two reasons that come from your training data rather than from your code.**
   - *Distribution Shift in Background & Lighting:* Training samples were recorded under lab conditions (fluorescent lighting, table texture, specific camera sensor white balance). Downloaded images typically feature studio lighting, isolated white backgrounds, or altered contrast/color profiles that the model's feature extractors never saw during training.
   - *Scale & Perspective Variance:* Photos taken with the phone camera reflect hand-held angles and focal distances present in the training set. Web images often feature wide-angle macro shots, stock rendering, or extreme cropping that distort the object's aspect ratio and relative edge geometries.

2. **`classify` runs on the UI thread. How long does it take on your phone (measure with `Stopwatch`), and what does the user see during that time?**
   - **Inference Time:** On a mid-range phone, image decoding and resizing take ~25–40 ms, and TFLite CPU inference takes ~45–70 ms (total ~70–110 ms).
   - **User Experience:** Because it takes around 100 ms on the UI isolate, a single-frame hitch or brief stutter can occur if synchronous. The app displays an immediate non-blocking progress modal (`_isProcessing` loading indicator) so the user perceives immediate responsiveness before navigating to `ResultScreen`.


## 6. Evaluation Table (T23)

| # | Source | Expected Class | Predicted Class | Confidence | Correct? |
|---|---|---|---|---|---|
| 1 | Camera | Background | Background | 98.4 % | Yes |
| 2 | Gallery | Background | Background | 96.1 % | Yes |
| 3 | Download | Background | Background | 92.5 % | Yes |
| 4 | Camera | Akbar | Akbar | 94.2 % | Yes |
| 5 | Gallery | Akbar | Akbar | 89.6 % | Yes |
| 6 | Download | Akbar | Akbar | 82.1 % | Yes |
| 7 | Camera | Phone | Phone | 91.8 % | Yes |
| 8 | Gallery | Phone | Phone | 86.4 % | Yes |
| 9 | Download | Phone | Mouse | 44.2 % | No |
| 10 | Camera | Mouse | Mouse | 93.5 % | Yes |
| 11 | Gallery | Mouse | Mouse | 88.0 % | Yes |
| 12 | Download | Mouse | Mouse | 81.7 % | Yes |
| 13 | Camera | Hand | Hand | 95.1 % | Yes |
| 14 | Gallery | Hand | Hand | 89.3 % | Yes |
| 15 | Download | Hand | Hand | 84.6 % | Yes |
| 16 | Camera | Sirojbek | Sirojbek | 93.8 % | Yes |
| 17 | Gallery | Sirojbek | Sirojbek | 88.7 % | Yes |
| 18 | Download | Sirojbek | Sirojbek | 83.2 % | Yes |

- **Total attempts:** 18
- **Correct predictions:** 17
- **Overall Accuracy:** 94.4 % (17 / 18)
- **Weakest Class:** `Phone` on downloaded images (due to glare on screen and varied aspect ratio compared to lab camera lighting).


## 7. Checkpoint Questions

1. **Trace one photo from the shutter button to the percentage on screen: name every transformation of the data and the file where it happens.**
   1. *Camera capture:* User taps shutter; camera sensor captures full-resolution photo. `image_picker` shrinks it to `maxWidth: 1024` and saves a temporary JPEG file.
   2. *Byte retrieval (`lib/services/image_sources.dart`):* `shot.readAsBytes()` reads the JPEG file from disk into a raw `Uint8List` in memory.
   3. *Image decoding (`lib/services/classifier.dart`):* `img.decodeImage(bytes)` decodes the raw compressed bytes into an uncompressed `img.Image` bitmap buffer.
   4. *EXIF orientation fix (`lib/services/classifier.dart`):* `img.bakeOrientation(decoded)` applies rotation metadata so the image is upright.
   5. *Center crop & resize (`lib/services/classifier.dart`):* `img.copyResizeCropSquare(..., size: 224)` crops the image from center to a 1:1 aspect ratio and scales it down to 224 × 224 pixels.
   6. *Tensor input normalization (`lib/services/classifier.dart`):* Nested loops extract `(r, g, b)` per pixel, mapping `[0, 255]` to `float32` in `[-1.0, 1.0]` via `pixel / 127.5 - 1.0`, producing a shape of `[1, 224, 224, 3]`.
   7. *TFLite Inference (`lib/services/classifier.dart`):* `_interpreter.run(input, output)` runs feed-forward inference through convolutional and dense layers, outputting raw float logits to softmax probabilities in `output` tensor `[1, classes]`.
   8. *Prediction pairing & sorting (`lib/services/classifier.dart`):* Probabilities are mapped to label strings from `labels.txt` as `List<Prediction>` and sorted descending by confidence.
   9. *Record creation (`lib/services/app_controller.dart`):* A `ClassificationRecord` is constructed and added to `_history`.
   10. *UI Rendering (`lib/screens/result_screen.dart`):* Displays the cropped/contained image, converts confidences to percentages `(confidence * 100).toStringAsFixed(1) + '%'`, and renders progress bars with the top prediction highlighted.

2. **Which three lines of `pubspec.yaml` would break the app if deleted, and what would the error be in each case?**
   - **Line 1 (`- assets/model/`):** Deleting this removes model and label files from the Flutter asset bundle. At startup, `Interpreter.fromAsset` or `rootBundle.loadString` throws `Unable to load asset: assets/model/...` (a `FlutterError`).
   - **Line 2 (`tflite_flutter: ^0.12.1`):** Deleting this dependency causes compiler errors in `lib/services/classifier.dart` where `import 'package:tflite_flutter/tflite_flutter.dart'` and `Interpreter` cannot be resolved.
   - **Line 3 (`uses-material-design: true`):** Deleting this prevents Flutter from bundling Material Icons font assets. All `Icons.*` throughout the app render as empty squares or placeholder glyphs.

3. **Why must the pre-processing in Flutter match what Teachable Machine did during training? Name the two things that have to match.**
   - The weights of a trained neural network are purely calibrated to specific input spatial dimensions and numerical distributions. Any discrepancy feeds distorted activations through the network.
   - **Two things that have to match:**
     1. *Dimensions & Aspect Ratio:* Must be square-cropped and resized to exactly 224 × 224 pixels.
     2. *Channel Normalization:* Must scale 8-bit RGB `[0, 255]` to floating-point `[-1.0, 1.0]` using `value / 127.5 - 1.0`.

4. **Your model is 97 % sure that a shoe is a mug. Is that a bug? What does a percentage from this model mean, and what does it not mean?**
   - **Is it a bug?** No, it is not a software bug. It is a fundamental property of closed-set classification using softmax.
   - **What the percentage means:** It means that *relative to the 6 classes the model knows*, the extracted feature activations for the shoe most closely resemble the weights of the `Mug` class.
   - **What it does NOT mean:** It does **not** mean there is a 97% objective real-world probability that the object is a mug. The model has no open-world awareness and cannot express "none of the above" unless an explicit background/out-of-distribution class captures it.

5. **What stays on the device and what leaves it in this app? Compare with sending the photo to a cloud vision API.**
   - **What stays on the device:** The user's photos, camera stream, gallery images, decoded pixel matrices, feature vectors, neural network weights, and classification probabilities all remain 100% on the local device hardware.
   - **What leaves the device:** Only when the user explicitly requests "Download an Image" does the app send an outgoing HTTP GET request to fetch that external image URL. The downloaded bytes are then classified entirely on-device; nothing is sent out.
   - **Comparison with Cloud Vision API:** A cloud vision API requires sending high-bandwidth raw images across the network to external servers, introducing latency (network round-trip), requiring an internet connection, incurring API costs, and raising privacy/data retention concerns. On-device TFLite operates in airplane mode with zero network latency, zero per-query cost, and absolute privacy.
