import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/receipt_ocr_service.dart';
import '../widgets/fade_in_slide.dart';
import 'receipt_review_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isScanning = false;
  final _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _image = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(
            'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. $e');
      }
    }
  }

  Future<void> _scanReceipt() async {
    if (_image == null) return;
    setState(() => _isScanning = true);
    try {
      final items = await ReceiptOcrService.extractItems(_image!);
      if (!mounted) return;
      if (items.isEmpty) {
        _showError('No food items found on the receipt. Try a clearer photo.');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptReviewScreen(items: items),
        ),
      );
    } catch (e) {
      if (mounted) _showError('OCR failed: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.urgentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearImage() => setState(() {
        _image = null;
        _imageBytes = null;
      });

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageBytes != null;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ── Title ────────────────────────────────────────────────────
              const FadeInSlide(
                delay: Duration.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Receipt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Add items quickly by scanning a receipt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Preview area ─────────────────────────────────────────────
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: hasImage
                      ? _ImagePreview(
                          bytes: _imageBytes!,
                          onClear: _clearImage,
                          isScanning: _isScanning,
                        )
                      : _EmptyPreview(pulseAnim: _pulseAnim),
                ),
              ),
              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────────────────────
              if (!hasImage) ...[
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(LucideIcons.camera, size: 18, color: Colors.white),
                      label: const Text('Capture Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        shadowColor: AppColors.brandGreen.withValues(alpha: 0.25),
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(LucideIcons.upload, size: 18, color: AppColors.mutedForeground),
                      label: const Text(
                        'Upload from Gallery',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isScanning 
                          ? null 
                          : const LinearGradient(
                              colors: [AppColors.brandGreenGradientStart, AppColors.brandGreenGradientEnd],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isScanning 
                          ? null 
                          : [
                              BoxShadow(
                                color: AppColors.brandGreen.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isScanning ? null : _scanReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning ? Colors.grey.shade300 : Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isScanning
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Scanning receipt…', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Scan with AI', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.mutedForeground),
                      label: const Text(
                        'Choose Different Image',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.foreground),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── AI badge ─────────────────────────────────────────────────
              FadeInSlide(
                delay: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.08),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Powered by Gemma 3 Vision',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'AI extracts items, quantities & estimated expiry dates automatically.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6D28D9),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Tips ─────────────────────────────────────────────────────
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.brandGreen.withValues(alpha: 0.2),
                        width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.lightbulb, size: 16, color: AppColors.brandGreen),
                          SizedBox(width: 8),
                          Text(
                            'Tips for best results',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...[
                        'Ensure receipt is flat & well-lit',
                        'Capture the full receipt in frame',
                        'Avoid shadows and glare',
                        'Works best with grocery receipts',
                      ].asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.brandGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(entry.value,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.mutedForeground,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _EmptyPreview({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner brackets
          const Positioned(
              left: 20, top: 20, child: _CornerBracket(topLeft: true)),
          const Positioned(
              right: 20, top: 20, child: _CornerBracket(topRight: true)),
          const Positioned(
              left: 20, bottom: 20, child: _CornerBracket(bottomLeft: true)),
          const Positioned(
              right: 20,
              bottom: 20,
              child: _CornerBracket(bottomRight: true)),
          
          Center(
            child: AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: pulseAnim.value,
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76, height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.mintBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.receipt,
                        size: 32, color: AppColors.brandGreen),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Capture or upload a receipt',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.foreground,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI will extract items automatically',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatefulWidget {
  final Uint8List bytes;
  final VoidCallback onClear;
  final bool isScanning;

  const _ImagePreview({
    required this.bytes,
    required this.onClear,
    required this.isScanning,
  });

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    if (widget.isScanning) {
      _scanController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_scanController.isAnimating) {
      _scanController.repeat(reverse: true);
    } else if (!widget.isScanning && _scanController.isAnimating) {
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            widget.bytes,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Scanning line overlay animation
        if (widget.isScanning) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'AI is reading your receipt…',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This takes a few seconds',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          // Animated horizontal scan line
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, child) {
              return Positioned(
                top: _scanAnim.value * 280, // Approximate height of the aspect ratio preview
                left: 10,
                right: 10,
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        if (!widget.isScanning)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onClear,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _CornerBracket({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: (topLeft || topRight)
              ? const BorderSide(color: AppColors.brandGreen, width: 3.0)
              : BorderSide.none,
          bottom: (bottomLeft || bottomRight)
              ? const BorderSide(color: AppColors.brandGreen, width: 3.0)
              : BorderSide.none,
          left: (topLeft || bottomLeft)
              ? const BorderSide(color: AppColors.brandGreen, width: 3.0)
              : BorderSide.none,
          right: (topRight || bottomRight)
              ? const BorderSide(color: AppColors.brandGreen, width: 3.0)
              : BorderSide.none,
        ),
      ),
    );
  }
}
