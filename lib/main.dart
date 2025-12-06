import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as ml;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR 工具',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '二维码工具'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  String? _scanResult;
  final ms.MobileScannerController _scannerController = ms.MobileScannerController(
    detectionSpeed: ms.DetectionSpeed.noDuplicates,
    formats: const [ms.BarcodeFormat.qrCode],
  );
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code), text: '生成'),
              Tab(icon: Icon(Icons.qr_code_scanner), text: '扫描'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneratorTab(),
            _buildScannerTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '输入文本或链接',
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: _textController.text.isEmpty
                  ? const Text('请输入内容以生成二维码')
                  : QrImageView(
                      data: _textController.text,
                      version: QrVersions.auto,
                      size: 220,
                    ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('生成/更新二维码'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
        actions: [
          if (!kIsWeb)
            IconButton(
              tooltip: '从相册选择',
              icon: const Icon(Icons.photo_library),
              onPressed: _pickFromGallery,
            ),
        ],
      ),
      body: Stack(
        children: [
          ms.MobileScanner(
            controller: _scannerController,
            onDetect: (capture) => _handleDetect(capture.barcodes),
          ),
          if (_scanResult != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _scanResult!,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDetect(List<ms.Barcode> barcodes) async {
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw == _scanResult) return;
    // Pause camera to avoid duplicate triggers
    await _scannerController.stop();
    await _processScanResult(raw);
    // Resume camera after handling
    await _scannerController.start();
  }

  Uri? _parseHttpUrl(String text) {
    final uri = Uri.tryParse(text);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return null;
  }

  Future<void> _pickFromGallery() async {
    try {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Web 端不支持从相册识别二维码')),
          );
        }
        return;
      }
      final xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在识别所选图片...')),
        );
      }
      // Use Google ML Kit to decode static image from gallery
      final barcodeScanner = ml.BarcodeScanner(formats: [ml.BarcodeFormat.qrCode]);
      final inputImage = ml.InputImage.fromFilePath(xfile.path);
      final barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();
      if (barcodes.isNotEmpty) {
        final value = barcodes.first.rawValue;
        if (value != null && value.isNotEmpty) {
          await _processScanResult(value);
          return;
        }
      }
      // Fallback to MobileScanner analyzer if ML Kit found nothing
      await _scannerController.analyzeImage(xfile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别图片失败: $e')),
      );
    }
  }

  Future<void> _processScanResult(String raw) async {
    setState(() => _scanResult = raw);
    await Clipboard.setData(ClipboardData(text: raw));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
    final uri = _parseHttpUrl(raw);
    if (uri != null) {
      if (!mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('打开链接'),
          content: Text('检测到链接:\n${uri.toString()}\n是否用浏览器打开？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('打开')),
          ],
        ),
      );
      if (open == true) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
