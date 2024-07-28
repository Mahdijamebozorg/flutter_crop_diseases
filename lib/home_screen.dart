import 'package:crop_diseases/image.dart';
import 'package:crop_diseases/live.dart';
import 'package:crop_diseases/model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0;

  void _selectPage(int index) {
    setState(() => _currentPage = index);
  }

  // final Classifier _classifier = Classifier();
  final Classifier _classifier = Classifier();
  bool _isInitialized = false;
  bool _isLite = true;

  @override
  void initState() {
    _classifier
        .loadModel(type: PredType.realtime)
        .then((value) => setState(() => _isInitialized = true));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(_currentPage == 0 ? "Image" : "Live"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('lite model'),
                Switch(
                    value: _isLite,
                    onChanged: (value) async {
                      setState(() => _isInitialized = false);
                      _isLite = value;
                      await _classifier.loadModel(
                          type: _isLite ? PredType.realtime : PredType.delayed);
                      setState(() => _isInitialized = true);
                    }),
              ],
            ),
          ),
        ],
      ),

      // Body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _isInitialized
              ? _currentPage == 0
                  ? ImageInput(classifier: _classifier)
                  : LiveInput(classifier: _classifier)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBar: SizedBox(
        height: screenSize.height * 0.07,
        child: BottomNavigationBar(
          onTap: _selectPage,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentPage,
          iconSize: screenSize.height * 0.07 * 0.5,
          selectedFontSize: screenSize.height * 0.07 * 0.2,
          unselectedFontSize: screenSize.height * 0.07 * 0.2,
          elevation: 8,
          type: BottomNavigationBarType.shifting,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Image'),
            BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Live'),
          ],
        ),
      ),
    );
  }
}
