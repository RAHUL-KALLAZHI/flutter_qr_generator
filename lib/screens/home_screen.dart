import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final TextEditingController _textController = TextEditingController();
final FocusNode _focusNode = FocusNode();
final globalKey = GlobalKey();

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextInputWidget(),
                GenerateButton(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<ui.Image> _loadOverlayImage() async {
  final completer = Completer<ui.Image>();
  final byteData = await rootBundle.load('assets/logo.png');
  ui.decodeImageFromList(byteData.buffer.asUint8List(), completer.complete);
  return completer.future;
}

Future<void> getImageData() async {
  XFile? qrImage;
  List<XFile> files = [];
  final boundary =
      globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
  final image = await boundary!.toImage();
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final imageBytes = byteData!.buffer.asUint8List();

  if (imageBytes != null) {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        await File('${directory.path}/container_image.png').create();
    await imagePath.writeAsBytes(imageBytes);
    await Share.shareFiles([imagePath.path]);
    print("image path: $imagePath");
  }
  //await Share.shareXFiles(files);
}

class QRContainer extends StatefulWidget {
  final String message;
  const QRContainer({
    required this.message,
    super.key,
  });

  @override
  State<QRContainer> createState() => _QRContainerState();
}

class _QRContainerState extends State<QRContainer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _loadOverlayImage(),
      builder: (ctx, snapshot) {
        const size = 250.0;
        if (!snapshot.hasData) {
          return const SizedBox(width: size, height: size);
        }
        return GestureDetector(
          onTap: () async {
            await getImageData();
          },
          child: RepaintBoundary(
            key: globalKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                size: const Size.square(size),
                painter: QrPainter(
                  data: widget.message,
                  version: QrVersions.auto,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  embeddedImage: snapshot.data,
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: const Size.square(45),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GenerateButton extends StatefulWidget {
  const GenerateButton({
    super.key,
  });

  @override
  State<GenerateButton> createState() => _GenerateButtonState();
}

bool isQrShown = false;

class _GenerateButtonState extends State<GenerateButton> {
  void generateQR() {
    final data = _textController.text;
    if (data.isNotEmpty) {
      setState(() {
        isQrShown = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {
            generateQR();
          },
          child: const Text("Generate QR"),
        ),
        const SizedBox(
          height: 15,
        ),
        Visibility(
          visible: isQrShown,
          child: QRContainer(
            message: _textController.text,
          ),
        )
      ],
    );
  }
}

class TextInputWidget extends StatelessWidget {
  const TextInputWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: 3,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          labelText: "Text to encode",
          enabledBorder: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(),
        ),
        onTapOutside: (event) {
          _focusNode.unfocus();
        },
      ),
    );
  }
}
