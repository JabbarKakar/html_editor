import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'html_editor_view.dart';

class DescriptionField extends StatefulWidget {
  final TextEditingController descriptionController;
  final TextEditingController? targetController;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete; // New parameter
  final bool enablePicture;
  final String title;
  final String hintText;
  final bool showEditDelete; // New parameter to control visibility
  final bool isReadOnly; // New parameter to make field read-only when showing controls

  const DescriptionField({
    super.key,
    required this.descriptionController,
    this.targetController,
    this.onEdit,
    this.onDelete,
    this.enablePicture = true,
    this.title = 'Ticket Description',
    this.hintText = 'Ticket Description',
    this.showEditDelete = false,
    this.isReadOnly = false,
  });

  @override
  State<DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<DescriptionField> {
  bool isExpanded = false;
  bool showSeeMore = false;
  final GlobalKey _contentKey = GlobalKey();
  final double _collapsedHeight = 45.0;

  String _normalizeHtml(String input) {
    String out = input.trim();
    if (out.isEmpty) return '';

    // Only decode if it's actually a JSON string (starts and ends with quotes and contains escaped content)
    try {
      if (out.startsWith('"') && out.endsWith('"') && (out.contains(r'\"') || out.contains(r'\u'))) {
        out = jsonDecode(out);
      }
    } catch (_) {
      // If JSON decode fails, use the original string
    }

    // Unescape common encodings and entities across multiple variants
    // 1) Handle one-or-more backslashes before unicode sequences (e.g. \u003C, \\\u003C)
    out = out
        .replaceAllMapped(RegExp(r'\\+u003[cC]'), (_) => '<')
        .replaceAllMapped(RegExp(r'\\+u003[eE]'), (_) => '>')
        .replaceAllMapped(RegExp(r'\\+u002[6]'), (_) => '&');

    // 2) Handle unicode sequences without preceding backslash (e.g. u003C) anywhere in text
    out = out
        .replaceAll(RegExp(r'u003c', caseSensitive: false), '<')
        .replaceAll(RegExp(r'u003e', caseSensitive: false), '>')
        .replaceAll(RegExp(r'u0026', caseSensitive: false), '&');

    // 3) Handle JSON-style escaped characters
    out = out
        .replaceAll(r'\/', '/')
        .replaceAll(r'\"', '"');

    // 4) Handle HTML entities (named and numeric)
    out = out
        .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
        .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&#60;|&#x3c;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&#62;|&#x3e;', caseSensitive: false), '>')
        .replaceAll(RegExp(r'&#38;|&#x26;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&quot;', caseSensitive: false), '"')
        .replaceAll(RegExp(r'&#39;|&apos;', caseSensitive: false), "'");

    return _sanitizeHtml(out);
  }

  String _sanitizeHtml(String html) {
    final RegExp emptySrcImg = RegExp("<img\\b(?![^>]*src\\s*=\\s*([\"']).+?\\1)[^>]*>", caseSensitive: false);
    String cleaned = html.replaceAll(emptySrcImg, '');
    cleaned = cleaned.replaceAll(RegExp("<img[^>]*\\bsrc\\s*=\\s*([\"'])\\s*\\1[^>]*>", caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp("<img[^>]*\\bsrc\\s*=\\s*([\"'])(?!https?:|data:image\/)[^\"']*\\1[^>]*>", caseSensitive: false), '');
    return cleaned;
  }

  List<HtmlExtension> get _safeImageTagExtension => [
    TagExtension(
      tagsToExtend: {"img"},
      builder: (context) {
        final src = context.attributes['src']?.trim();
        if (src == null || src.isEmpty) {
          return const SizedBox.shrink();
        }
        if (src.startsWith('data:image/')) {
          final comma = src.indexOf(',');
          if (comma == -1) return const SizedBox.shrink();
          final base64Part = src.substring(comma + 1);
          try {
            final Uint8List bytes = base64Decode(base64Part);
            return Image.memory(bytes, fit: BoxFit.contain);
          } catch (_) {
            return const SizedBox.shrink();
          }
        }
        if (src.startsWith('http://') || src.startsWith('https://')) {
          return Image.network(src, fit: BoxFit.contain);
        }
        return const SizedBox.shrink();
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.descriptionController.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkContentHeight();
  }

  @override
  void dispose() {
    widget.descriptionController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkContentHeight();
      }
    });
  }

  void _checkContentHeight() {
    if (!mounted) return;

    final text = widget.descriptionController.text.trim();
    if (text.isEmpty) {
      setState(() {
        showSeeMore = false;
      });
      return;
    }

    final source = _normalizeHtml(text);
    final hasImages = source.contains('<img') || source.contains('<image') || source.contains('data:image/');
    final isLongText = source.length > 150;

    setState(() {
      showSeeMore = hasImages || isLongText;
    });
  }

  Future<void> _editDescription() async {
    final editedHtml = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HtmlEditorScreen(
          title: widget.title,
          descriptionText: widget.descriptionController.text,
          picture: widget.enablePicture,
        ),
      ),
    );

    if (editedHtml != null && editedHtml is String) {
      // Clean the HTML content before setting it
      String cleanedHtml = editedHtml.trim();

      // Remove any JSON encoding artifacts
      if (cleanedHtml.startsWith('"') && cleanedHtml.endsWith('"')) {
        try {
          cleanedHtml = jsonDecode(cleanedHtml);
        } catch (_) {
          // If it fails to decode, use as is
        }
      }

      widget.descriptionController.text = cleanedHtml;
      widget.targetController?.text = cleanedHtml;
      if (widget.onEdit != null) widget.onEdit!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isReadOnly ? null : () => _editDescription(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 70,
        ),
        decoration: BoxDecoration(
          color: widget.showEditDelete ? Colors.white : Colors.grey,
          borderRadius: BorderRadius.circular(widget.showEditDelete ? 14 : 12),
          border: widget.showEditDelete ? Border.all(color: Colors.grey.withOpacity(0.2)) : null,
        ),
        child: Padding(
          padding: EdgeInsets.only(
              left: 16,
              top: 10,
              bottom: 8,
              right: widget.showEditDelete ? 14 : 16
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row with optional edit/delete controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (widget.showEditDelete)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _editDescription,
                          child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.grey,
                              size: 16
                          ),
                        ),
                        if (widget.onDelete != null) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Icon(
                                CupertinoIcons.delete,
                                color: Colors.grey,
                                size: 16
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          key: _contentKey,
                          height: isExpanded ? null : _collapsedHeight,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Html(
                              data: widget.descriptionController.text.trim().isEmpty
                                  ? "<p>${widget.hintText}</p>"
                                  : _normalizeHtml(widget.descriptionController.text),
                              style: {
                                "p": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  textAlign: TextAlign.justify,
                                  fontSize: FontSize(11),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "h1": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: FontSize(18),
                                  margin: Margins.only(bottom: 8),
                                  padding: HtmlPaddings.zero,
                                ),
                                "h2": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: FontSize(16),
                                  margin: Margins.only(bottom: 6),
                                  padding: HtmlPaddings.zero,
                                ),
                                "h3": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: FontSize(14),
                                  margin: Margins.only(bottom: 4),
                                  padding: HtmlPaddings.zero,
                                ),
                                "h4": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: FontSize(13),
                                  margin: Margins.only(bottom: 4),
                                  padding: HtmlPaddings.zero,
                                ),
                                "h5": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontSize: FontSize(12),
                                  margin: Margins.only(bottom: 2),
                                  padding: HtmlPaddings.zero,
                                ),
                                "h6": Style(
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontSize: FontSize(11.5),
                                  margin: Margins.only(bottom: 2),
                                  padding: HtmlPaddings.zero,
                                ),
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "div": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                              },
                              extensions: _safeImageTagExtension,
                            ),
                          ),
                        ),
                        if (!isExpanded && showSeeMore)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 15,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (widget.showEditDelete ? Colors.white : Colors.grey).withOpacity(0.0),
                                    (widget.showEditDelete ? Colors.white : Colors.grey).withOpacity(1.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (showSeeMore) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? "See less" : "See more",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}