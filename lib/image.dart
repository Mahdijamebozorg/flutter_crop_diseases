import 'dart:io';
import 'package:crop_diseases/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_dir;

class ImageInput extends StatefulWidget {
  final Classifier classifier;
  const ImageInput({required this.classifier, super.key});

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  XFile? file = XFile("");
  bool isloading = false;
  var label = "";
  void trySetState(Function f) {
    if (mounted) setState(() => f());
  }

  ///take image if device have camera
  Future _takeImage() async {
    final picker = ImagePicker();
    final imageFile =
        await picker.pickImage(source: ImageSource.camera, maxWidth: 600);

    //if has taken
    if (imageFile != null) {
      //enable CircularProgressIndicator
      trySetState(() => isloading = true);

      // get root level app directory
      final appDir = await path_dir.getApplicationDocumentsDirectory();
      // temp file name
      final fileName = path.basename(imageFile.path);
      //save file
      await imageFile.saveTo("${appDir.path}/$fileName");
      debugPrint("Image saved ${imageFile.path}");
      file = imageFile;
      // await widget.addImage(file);

      //disable CircularProgressIndicator
      trySetState(() => isloading = false);
    }
  }

  ///choose an image from device
  Future _chooseImage() async {
    final picker = ImagePicker();
    final pickedImage =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    //if an image has choosen
    if (pickedImage != null) {
      //enable CircularProgressIndicator
      trySetState(() => isloading = true);

      debugPrint("Picked image: ${pickedImage.path}");
      file = pickedImage;
      // await widget.addImage(file);

      //disable CircularProgressIndicator
      trySetState(() => isloading = false);
    }
  }

  Future _processImage() async {
    if (file != null && file!.path.isNotEmpty) {
      trySetState(() => isloading = true);
      final output = await widget.classifier
          .predict(await ImageUtils.readImageFromFile(file!.path));
      trySetState(() {
        label = output.toString();
        isloading = false;
      });
      debugPrint("model output: ${output.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, imagePart) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              children: [
                isloading
                    ? const Center(child: CircularProgressIndicator())
                    : file!.path == ""
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red)),
                              child: const Center(
                                  child: Text("No image has chosen!")),
                            ),
                          )
                        : kIsWeb
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.network(
                                  file!.path,
                                  fit: BoxFit.fill,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.file(
                                  File(file!.path),
                                  fit: BoxFit.fill,
                                ),
                              ),
                Positioned(
                  bottom: 50.0,
                  left: 15,
                  child: Text(
                    textAlign: TextAlign.center,
                    "Detection: $label",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // chooese button
                ElevatedButton(
                  onPressed: _chooseImage,
                  child: const Icon(Icons.photo_album),
                ),
                //capture button
                ElevatedButton(
                  onPressed: _takeImage,
                  child: const Icon(
                    Icons.camera_alt,
                  ),
                ),
                //predict label
                ElevatedButton(
                  onPressed: _processImage,
                  child: const Icon(
                    Icons.start,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
