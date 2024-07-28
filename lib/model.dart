import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;

// ignore_for_file: constant_identifier_names
enum DetectionClasses {
  Apple___Apple_scab,
  Apple___Black_rot,
  Apple___Cedar_apple_rust,
  Apple___healthy,
  Blueberry___healthy,
  Cherry_including_sour___Powdery_mildew,
  Cherry_including_sour___healthy,
  Corn_maize___Cercospora_leaf_spot,
  Corn_maize___Common_rust_,
  Corn_maize___Northern_Leaf_Blight,
  Corn_maize___healthy,
  Grape___Black_rot,
  Grape___Esca_Black_Measles,
  Grape___Leaf_blight_Isariopsis_Leaf_Spot,
  Grape___healthy,
  Orange___Haunglongbing_Citrus_greening,
  Peach___Bacterial_spot,
  Peach___healthy,
  Pepper_bell___Bacterial_spot,
  Pepper_bell___healthy,
  Potato___Early_blight,
  Potato___Late_blight,
  Potato___healthy,
  Raspberry___healthy,
  Soybean___healthy,
  Squash___Powdery_mildew,
  Strawberry___Leaf_scorch,
  Strawberry___healthy,
  Tomato___Bacterial_spot,
  Tomato___Early_blight,
  Tomato___Late_blight,
  Tomato___Leaf_Mold,
  Tomato___Septoria_leaf_spot,
  Tomato___Spider_mites,
  Tomato___Target_Spot,
  Tomato___Tomato_Yellow_Leaf_Curl_Virus,
  Tomato___Tomato_mosaic_virus,
  Tomato___healthy,
}

enum PredType { realtime, delayed }

/// ImageUtils
class ImageUtils {
  static Future<image_lib.Image> readImageFromFile(String imagePath) async {
    return (await image_lib.decodeJpgFile(imagePath))!;
  }

  /// Converts a [CameraImage] in YUV420 format to [image_lib.Image] in RGB format
  static image_lib.Image convertYUV420ToImage(CameraImage cameraImage) {
    const shift = (0xFF << 24);
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = image_lib.Image(height: height, width: width);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);

        if (image.isBoundsSafe(height - h, w)) {
          image.setPixelRgba(height - h, w, r, g, b, shift);
        }
      }
    }
    return image;
  }
}

class Classifier {
  /// Instance of Interpreter
  late IsolateInterpreter _isolateInterpreter;
  late Interpreter _interpreter;
  static const String _liteModel = "asset/model/efficientnet_lite0.tflite";
  static const String _heavyModel = "asset/model/efficientnetb3.tflite";

  /// Loads interpreter from asset
  Future<void> loadModel(
      {Interpreter? interpreter, PredType type = PredType.realtime}) async {
    try {
      if (interpreter != null) {
        _interpreter = interpreter;
      } else if (type == PredType.delayed) {
        _interpreter = await Interpreter.fromAsset(
          _heavyModel,
          options: InterpreterOptions()..threads = 4,
        );
      } else {
        _interpreter = await Interpreter.fromAsset(
          _liteModel,
          options: InterpreterOptions()..threads = 4,
        );
      }
      _interpreter.allocateTensors();
      _isolateInterpreter =
          await IsolateInterpreter.create(address: _interpreter.address);
      Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Error while creating interpreter: $e");
    }
  }

  /// predict image by model
  Future<DetectionClasses> predict(image_lib.Image image) async {
    // resize image
    image_lib.Image resizedImage =
        image_lib.copyResize(image, width: 224, height: 224);
    // convert to rgb
    final decodedBytes =
        resizedImage.getBytes(order: image_lib.ChannelOrder.rgb);

    final input = decodedBytes.reshape([1, 224, 224, 3]);
    final output = Float32List(1 * 38).reshape([1, 38]);
    await _isolateInterpreter.run(input, output);

    // Get index of maxumum value from outout data
    final predictionResult = output[0] as List<num>;
    num maxElement = 0;
    for (num element in predictionResult) {
      maxElement = element > maxElement ? element : maxElement;
    }
    return DetectionClasses.values[predictionResult.indexOf(maxElement)];
  }
}
