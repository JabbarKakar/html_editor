import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html_editor/presentation/widgets/toast_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'custom_button.dart';
import 'custom_dialog.dart';
import 'custom_image_picker.dart';
import 'custom_text_field.dart';

class HtmlEditorScreen extends StatefulWidget {
  final String descriptionText;
  final String title;
  final bool picture;
  const HtmlEditorScreen({
    super.key,
    required this.descriptionText,
    required this.title,
    this.picture = true,
  });

  @override
  State<HtmlEditorScreen> createState() => _HtmlEditorScreenState();
}

class _HtmlEditorScreenState extends State<HtmlEditorScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasContent = false;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isUnorderedList = false;
  bool _isOrderedList = false;
  bool _isAlignLeft = false;
  bool _isAlignCenter = false;
  bool _isAlignRight = false;
  bool _isJustify = false;
  bool _isStrikethrough = false;
  bool _isSubscript = false; // Add here
  bool _isSuperscript = false; // Add here
  bool _isHighlighted = false;

  String _selectedHeading = 'Normal';
  String? _selectedCase = 'Sentence case';
  String? _selectedFont = 'Default';
  String _selectedBorder = 'None'; // Added for border selection

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'onChange',
        onMessageReceived: (JavaScriptMessage message) {
          setState(() {
            _hasContent = message.message == 'true';
          });
        },
      )
      ..addJavaScriptChannel(
        'onSelectionChange',
        onMessageReceived: (JavaScriptMessage message) {
          final states = message.message.split(',');
          setState(() {
            _isBold = states[0] == 'true';
            _isItalic = states[1] == 'true';
            _isUnderline = states[2] == 'true';
            _isStrikethrough = states[3] == 'true';
            _isUnorderedList = states[4] == 'true';
            _isOrderedList = states[5] == 'true';
            _isSubscript = states[6] == 'true'; // Add this
            _isSuperscript = states[7] == 'true'; // Add this
            _isHighlighted = states[8] == 'true';
          });
        },
      )
      ..addJavaScriptChannel(
        'onImageInsert',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message != 'success') {
            ToastHelper.showToast('Image insertion failed: ${message.message}');
          }
        },
      );
    _loadEditorContent();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue, // Ensure blue36 is defined
          centerTitle: true,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white, // Ensure whiteColor is defined
              fontFamily: 'Inter',
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.white, size: 24),
            onPressed: () => _showExitDialog(),
            tooltip: 'Close',
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => _clearContent(),
              tooltip: 'Clear content',
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildCustomToolbar(),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      WebViewWidget(
                        controller: _controller,
                        gestureRecognizers: const {},
                      ),
                      if (_isLoading)
                        Container(
                          color: Colors.white.withOpacity(0.9),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading editor...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(Icons.format_bold, () => _executeCommand('bold'), isActive: _isBold),
            _buildToolbarButton(Icons.format_italic, () => _executeCommand('italic'), isActive: _isItalic),
            _buildToolbarButton(Icons.format_underline, () => _executeCommand('underline'), isActive: _isUnderline),
            _buildToolbarButton(Icons.format_strikethrough, () => _executeCommand('strikeThrough'), isActive: _isStrikethrough),
            SizedBox(width: 8),
            _buildToolbarButton(Icons.subscript, () => _executeCommand('subscript'), isActive: _isSubscript),
            _buildToolbarButton(Icons.superscript, () => _executeCommand('superscript'), isActive: _isSuperscript),
            SizedBox(width: 8),
            _buildFontSelector(),
            SizedBox(width: 8),
            _buildFontSizeSelector(),
            SizedBox(width: 8),
            _buildHeadingSelector(),
            SizedBox(width: 8),
            _buildCaseSelector(),
            SizedBox(width: 8),
            _buildBorderSelector(), // Added border selector
            SizedBox(width: 8),
            _buildToolbarButton(Icons.format_align_left, () => _executeCommand('justifyLeft'), isActive: _isAlignLeft),
            _buildToolbarButton(Icons.format_align_center, () => _executeCommand('justifyCenter'), isActive: _isAlignCenter),
            _buildToolbarButton(Icons.format_align_right, () => _executeCommand('justifyRight'), isActive: _isAlignRight),
            _buildToolbarButton(Icons.format_align_justify, () => _executeCommand('justifyFull'), isActive: _isJustify),
            SizedBox(width: 8),
            _buildToolbarButton(Icons.format_color_fill, () => _showColorPicker()),
            _buildToolbarButton(Icons.highlight, () => _executeCommand('backColor', '#FFFF00'), isActive: _isHighlighted),
            SizedBox(width: 8),
            _buildToolbarButton(Icons.format_list_bulleted, () => _executeCommand('insertUnorderedList'), isActive: _isUnorderedList),
            _buildToolbarButton(Icons.format_list_numbered, () => _executeCommand('insertOrderedList'), isActive: _isOrderedList),
            SizedBox(width: 8),
            _buildToolbarButton(Icons.link, () => _insertLink()),
            _buildToolbarButton(Icons.table_chart, () => _showTableDialog()),
            if (widget.picture)_buildToolbarButton(Icons.image, () => _insertImage()),
            SizedBox(width: 8),
            _buildToolbarButton(Icons.undo, () => _executeCommand('undo')),
            _buildToolbarButton(Icons.redo, () => _executeCommand('redo')),
            SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBorderSelector() {
    final borders = {
      'None': 'none',
      'Solid': '1px solid #000000',
      'Dashed': '1px dashed #000000',
      'Dotted': '1px dotted #000000',
      'Double': '3px double #000000',
    };

    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBorder,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 16, color: Colors.grey.shade700),
          style: TextStyle(fontSize: 12, color: Colors.black87),
          items: borders.keys.map((label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _selectedBorder = value);
            final borderStyle = borders[value]!;
            await _changeBorderStyle(borderStyle);
          },
        ),
      ),
    );
  }

  Widget _buildHeadingSelector() {
    final headings = {
      'Normal': 'p',
      'Heading 1': 'h1',
      'Heading 2': 'h2',
      'Heading 3': 'h3',
      'Heading 4': 'h4',
      'Heading 5': 'h5',
      'Heading 6': 'h6',
    };

    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedHeading,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 16, color: Colors.grey.shade700),
          style: TextStyle(fontSize: 12, color: Colors.black87),
          items: headings.keys.map((label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;

            setState(() => _selectedHeading = value);

            final tag = headings[value]!;
            // Ensure editor focus, restore lastRange if available, then apply formatBlock
            await _controller.runJavaScript('''
            (function() {
              var editor = document.getElementById("editor");
              if (!editor) return;
              try {
                editor.focus();
                var sel = window.getSelection();
                // restore lastRange if it exists
                if (typeof lastRange !== 'undefined' && lastRange !== null) {
                  sel.removeAllRanges();
                  try { sel.addRange(lastRange); } catch(e) {}
                }
              } catch(e) {}
              document.execCommand("formatBlock", false, "<$tag>");
              // update lastRange after formatting
              try {
                var sel2 = window.getSelection();
                if (sel2.rangeCount > 0) {
                  var range = sel2.getRangeAt(0);
                  var container = range.commonAncestorContainer;
                  if (editor.contains(container) || container === editor) {
                    lastRange = range.cloneRange();
                  }
                }
              } catch(e) {}
            })();
          ''');
          },
        ),
      ),
    );
  }

  Widget _buildCaseSelector() {
    final cases = {
      'Sentence case': 'sentence',
      'lower case': 'lower',
      'UPPER CASE': 'upper',
      'Capitalize Each Word': 'capitalize',
      'tOGGLE cASE': 'toggle',
    };

    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCase,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 16, color: Colors.grey.shade700),
          style: TextStyle(fontSize: 12, color: Colors.black87),
          items: cases.keys.map((label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;

            setState(() => _selectedCase = value);

            final caseType = cases[value]!;
            await _changeCase(caseType);
          },
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector() {
    final fontSizes = List<int>.generate(50, (i) => (i + 1) * 2);
    int selectedSize = 16;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedSize,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down,
                  size: 16, color: Colors.grey.shade700),
              style: TextStyle(fontSize: 12, color: Colors.black87),
              items: fontSizes.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text(
                    "$size px",
                    style: TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() => selectedSize = value);

                  await _controller.runJavaScript('''
                  document.execCommand("fontSize", false, "7");
                  var elements = document.getElementById("editor").getElementsByTagName("font");
                  for (var i = 0; i < elements.length; i++) {
                    if (elements[i].size == "7") {
                      elements[i].removeAttribute("size");
                      elements[i].style.fontSize = "${value}px";
                    }
                  }
                ''');
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontSelector() {
    final fonts = {
      'Default': 'inherit',
      'Arial': 'Arial, sans-serif',
      'Georgia': 'Georgia, serif',
      'Times New Roman': 'Times New Roman, Times, serif',
      'Courier New': 'Courier New, monospace',
      'Verdana': 'Verdana, sans-serif',
      'Trebuchet MS': 'Trebuchet MS, sans-serif',
      'Comic Sans MS': 'Comic Sans MS, cursive, sans-serif',
    };

    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFont,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 16, color: Colors.grey.shade700),
          style: TextStyle(fontSize: 12, color: Colors.black87),
          items: fonts.keys.map((label) {
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label, style: TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _selectedFont = value);

            final fontValue = fonts[value]!;
            await _changeFontFamily(fontValue);
          },
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.blue : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              color: Colors.white,
              textColor: Colors.black,
              borderColor: Colors.grey,
              borderWidth: 0.7,
              text: "Cancel",
              onPressed: () => _showExitDialog(),
            ),
            SizedBox(width: 12),
            CustomButton(
              text: "Done",
              onPressed: () => _saveAndReturn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(String color, String name) {
    return GestureDetector(
      onTap: () {
        _executeCommand('foreColor', color);
        Navigator.pop(context);
      },
      child: Container(
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: color == '#000000' ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _loadEditorContent() {
    final initialContent = _getInitialText();
    final html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
            font-size: 16px;
            line-height: 1.6;
            color: #2C3E50;
            margin: 0;
            padding: 16px;
            height: 100vh;
            overflow-y: auto;
          }
          #editor {
            outline: none;
            min-height: 200px;
          }
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 8px 0;
          }
          td, th {
            border: 1px solid #ccc;
            padding: 8px;
          }
          p { margin: 0 0 12px 0; }
          img {
            max-width: 100% !important;
            height: auto !important;
            max-height: 300px !important;
            border-radius: 8px;
            display: block;
            margin: 8px 0;
          }
          ul, ol { padding-left: 20px; }
          blockquote {
            border-left: 4px solid #3498db;
            margin: 16px 0;
            padding: 8px 16px;
            background-color: #f8f9fa;
            border-radius: 4px;
          }
          a { color: #3498db; text-decoration: none; }
          a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <div id="editor" contenteditable="true">$initialContent</div>
        <script>
          const editor = document.getElementById('editor');
          // Track last selection range inside the editor
          let lastRange = null;

          editor.addEventListener('input', function() {
            onChange.postMessage(editor.innerHTML.length > 0 ? 'true' : 'false');
          });

          document.addEventListener('selectionchange', function() {
          const isBold = document.queryCommandState('bold');
          const isItalic = document.queryCommandState('italic');
          const isUnderline = document.queryCommandState('underline');
          const isStrikethrough = document.queryCommandState('strikeThrough');
          const isUnorderedList = document.queryCommandState('insertUnorderedList');
          const isOrderedList = document.queryCommandState('insertOrderedList');
          const isSubscript = document.queryCommandState('subscript');
          const isSuperscript = document.queryCommandState('superscript');
          const isHighlighted = document.queryCommandState('backColor');
          onSelectionChange.postMessage(
          [isBold, isItalic, isUnderline, isStrikethrough, isUnorderedList, isOrderedList, isSubscript, isSuperscript, isHighlighted].join(',')
          );
          // Save range if selection is inside editor
          const sel = window.getSelection();
          if (sel.rangeCount > 0) {
          const range = sel.getRangeAt(0);
          const container = range.commonAncestorContainer;
          if (editor.contains(container) || container === editor) {
          lastRange = range.cloneRange();
          }
         }
         });

          // Handle image load errors
          document.addEventListener('error', function(e) {
            if (e.target.tagName === 'IMG') {
              console.error('Image failed to load:', e.target.src);
              e.target.style.border = '2px dashed #ccc';
              e.target.alt = 'Failed to load image';
            }
          }, true);

          // Ensure editor is focusable and has a caret
          function focusEditorAtEnd() {
            editor.focus();
            const range = document.createRange();
            range.selectNodeContents(editor);
            range.collapse(false);
            const sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(range);
            lastRange = range.cloneRange();
          }

          // Helper to insert a node at the caret (inside editor)
          function insertNodeAtCaret(node) {
            try {
              // Restore selection inside editor if we have it
              const sel = window.getSelection();
              if (lastRange) {
                sel.removeAllRanges();
                sel.addRange(lastRange);
              }

              // If selection is not inside editor, move caret to end
              if (sel.rangeCount === 0) {
                focusEditorAtEnd();
              } else {
                const container = sel.getRangeAt(0).commonAncestorContainer;
                if (!editor.contains(container) && container !== editor) {
                  focusEditorAtEnd();
                }
              }

              const range = sel.getRangeAt(0);
              range.deleteContents();
              range.insertNode(node);

              // Add a paragraph after image for better editing flow
              const p = document.createElement('p');
              p.innerHTML = '<br>';
              range.setStartAfter(node);
              range.collapse(true);
              range.insertNode(p);

              // Place caret inside the new paragraph
              range.setStart(p, 0);
              range.setEnd(p, 0);
              sel.removeAllRanges();
              sel.addRange(range);

              // Update lastRange
              lastRange = range.cloneRange();

              // Trigger input event
              const event = new Event('input', { bubbles: true });
              editor.dispatchEvent(event);

              onImageInsert.postMessage('success');
            } catch (e) {
              onImageInsert.postMessage('error: ' + e.message);
            }
          }

          // Public helpers callable from Flutter
          window.insertImageDataUrl = function(dataUrl, altText) {
            try {
              const img = document.createElement('img');
              img.src = dataUrl;
              img.alt = altText || 'Image';
              img.style.maxWidth = '100%';
              img.style.height = 'auto';
              img.style.maxHeight = '300px';
              img.style.borderRadius = '8px';
              img.style.display = 'block';
              img.style.margin = '8px 0';
              insertNodeAtCaret(img);
            } catch (e) {
              onImageInsert.postMessage('error: ' + e.message);
            }
          }

          window.insertImageUrl = function(url, altText) {
            try {
              const img = document.createElement('img');
              img.src = url;
              img.alt = altText || 'Image';
              img.style.maxWidth = '100%';
              img.style.height = 'auto';
              img.style.maxHeight = '300px';
              img.style.borderRadius = '8px';
              img.style.display = 'block';
              img.style.margin = '8px 0';
              insertNodeAtCaret(img);
            } catch (e) {
              onImageInsert.postMessage('error: ' + e.message);
            }
          }

          // Initialize caret position
          setTimeout(focusEditorAtEnd, 0);
        </script>
      </body>
      </html>
    ''';
    _controller.loadHtmlString(html);
  }

  void _executeCommand(String command, [String? value]) async {
    await _controller.runJavaScript(
        'document.execCommand("$command", false, ${value != null ? '"$value"' : 'null'});');

    final result = await _controller.runJavaScriptReturningResult('''
    [
      document.queryCommandState('bold'),
      document.queryCommandState('italic'),
      document.queryCommandState('underline'),
      document.queryCommandState('strikeThrough'),
      document.queryCommandState('insertUnorderedList'),
      document.queryCommandState('insertOrderedList'),
      document.queryCommandState('justifyLeft'),
      document.queryCommandState('justifyCenter'),
      document.queryCommandState('justifyRight'),
      document.queryCommandState('justifyFull'),
      document.queryCommandState('subscript'),
      document.queryCommandState('superscript'),
      document.queryCommandState('backColor')
    ].join(',')
  ''');

    if (result is String) {
      final states = result.replaceAll(RegExp(r'^"|"$'), '').split(',');
      setState(() {
        _isBold = states[0] == 'true';
        _isItalic = states[1] == 'true';
        _isUnderline = states[2] == 'true';
        _isStrikethrough = states[3] == 'true';
        _isUnorderedList = states[4] == 'true';
        _isOrderedList = states[5] == 'true';
        _isAlignLeft = states[6] == 'true';
        _isAlignCenter = states[7] == 'true';
        _isAlignRight = states[8] == 'true';
        _isJustify = states[9] == 'true';
        _isSubscript = states[10] == 'true'; // Add this
        _isSuperscript = states[11] == 'true'; // Add this
        _isHighlighted = states[12] == 'true';
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: "Select Color",
        message: "",
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildColorOption('#000000', 'Black'),
            _buildColorOption('#3498db', 'Blue'),
            _buildColorOption('#e74c3c', 'Red'),
            _buildColorOption('#27ae60', 'Green'),
            _buildColorOption('#f39c12', 'Orange'),
            _buildColorOption('#9b59b6', 'Purple'),
            _buildColorOption('#ffffff', 'White'),
            _buildColorOption('#7f8c8d', 'Gray'),
            _buildColorOption('#bdc3c7', 'Light Gray'),
            _buildColorOption('#2c3e50', 'Dark Blue Gray'),
            _buildColorOption('#2980b9', 'Royal Blue'),
            _buildColorOption('#1abc9c', 'Turquoise'),
            _buildColorOption('#16a085', 'Teal'),
            _buildColorOption('#5dade2', 'Sky Blue'),
            _buildColorOption('#85c1e9', 'Light Blue'),
            _buildColorOption('#c0392b', 'Dark Red'),
            _buildColorOption('#e67e22', 'Carrot'),
            _buildColorOption('#ff7675', 'Pink'),
            _buildColorOption('#fd79a8', 'Light Pink'),
            _buildColorOption('#d35400', 'Pumpkin'),
            _buildColorOption('#2ecc71', 'Emerald'),
            _buildColorOption('#58d68d', 'Light Green'),
            _buildColorOption('#145a32', 'Dark Green'),
            _buildColorOption('#00b894', 'Mint'),
            _buildColorOption('#f1c40f', 'Yellow'),
            _buildColorOption('#f5b041', 'Amber'),
            _buildColorOption('#f8c471', 'Light Orange'),
            _buildColorOption('#f7dc6f', 'Light Yellow'),
            _buildColorOption('#8e44ad', 'Dark Purple'),
            _buildColorOption('#bb8fce', 'Lavender'),
            _buildColorOption('#6c3483', 'Deep Violet'),
            _buildColorOption('#a0522d', 'Sienna'),
            _buildColorOption('#d7bde2', 'Lilac'),
            _buildColorOption('#a1887f', 'Taupe'),
            _buildColorOption('#d35400', 'Rust'),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        showConfirmButton: false,
      ),
    );
  }

  void _insertLink() async {
    final url = await _showInputDialog('Enter link URL:', 'https://');
    if (url != null && url.isNotEmpty) {
      _executeCommand('createLink', url);
      ToastHelper.showToast('Link inserted successfully');
    }
  }

  void _insertImage() async {
    final TextEditingController urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(40),
        elevation: 0,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 10,
            left: 10,
            right: 10,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final file =
                      await CustomImagePicker.pickImage(ImageSource.camera);
                      Navigator.pop(context);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final base64 = base64Encode(bytes);
                        final mimeType = "image/${file.path.split('.').last}";
                        await _insertImageToEditor(
                            base64, mimeType, 'Camera Image');
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 36, color: Colors.blue),
                        SizedBox(height: 8,),
                        Text(
                          'Camera',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10,),
                  GestureDetector(
                    onTap: () async {
                      final file = await CustomImagePicker.pickImage(
                          ImageSource.gallery);
                      Navigator.pop(context);
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        final base64 = base64Encode(bytes);
                        final mimeType = "image/${file.path.split('.').last}";
                        await _insertImageToEditor(
                            base64, mimeType, 'Gallery Image');
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library,
                            size: 36, color: Colors.blue),
                        SizedBox(height: 8,),
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: "Image URL",
                      hintText: "https://example.com/image.jpg",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomButton(
                      text: "Insert",
                      onPressed: () async {
                        final url = urlController.text.trim();
                        if (url.isNotEmpty) {
                          Navigator.pop(context);
                          await _insertImageFromUrl(url);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14,),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
        confirmText: "Exit",
        cancelText: "Stay",
        title: 'Exit Editor',
        message:
        'Are you sure you want to exit? Any unsaved changes will be lost.',
      ),
    );
    if (result == true) {
      Navigator.pop(context);
    }
  }

  void _clearContent() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
        confirmText: "Clear",
        title: 'Clear Content',
        message:
        'Are you sure you want to clear all content? This action cannot be undone.',
      ),
    );
    if (result == true) {
      await _controller
          .runJavaScript('document.getElementById("editor").innerHTML = "";');
      setState(() {
        _hasContent = false;
        _isBold = false;
        _isItalic = false;
        _isUnderline = false;
        _isUnorderedList = false;
        _isOrderedList = false;
        _isSubscript = false; // Add here
        _isSuperscript = false; // Add here
        _isHighlighted = false;
        _selectedBorder = 'None'; // Reset border selection
      });
    }
  }

  void _saveAndReturn() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('document.getElementById("editor").innerHTML');
      if (result is String) {
        String html = result;
        if (html.startsWith('"') && html.endsWith('"')) {
          html = html.substring(1, html.length - 1);
        }

        // Unescape any escaped characters
        html = html.replaceAll(r'\"', '"')
            .replaceAll(r'\\', '\\')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t');

        // 🔹 ADD THIS: Ensure HTML is properly formatted for API
        // Don't let it get double-encoded
        html = html.replaceAll(r'\u003C', '<')
            .replaceAll(r'\u003E', '>')
            .replaceAll(r'\u0026', '&');

        Navigator.pop(context, html);
      } else {
        ToastHelper.showToast('Error retrieving content. Please try again.');
      }
    } catch (e) {
      ToastHelper.showToast('Error saving content. Please try again.');
    }
  }

  Future<void> _changeCase(String type) async {
    await _controller.runJavaScript('''
    (function() {
      var editor = document.getElementById("editor");
      if (!editor) return;

      editor.dataset.caseType = "$type";

      var sel = window.getSelection();
      if (sel.rangeCount > 0) {
        var range = sel.getRangeAt(0);
        var selectedText = range.toString();
        if (selectedText && selectedText.length > 0) {
          function toSentenceCase(str) { return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase(); }
          function toCapitalizeEachWord(str) { return str.replace(/\\w\\S*/g, function(txt) { return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); }); }
          function toToggleCase(str) { return str.split('').map(function(c){ return c === c.toUpperCase() ? c.toLowerCase() : c.toUpperCase(); }).join(''); }

          var transformed = selectedText;
          switch ("$type") {
            case "sentence": transformed = toSentenceCase(selectedText); break;
            case "lower": transformed = selectedText.toLowerCase(); break;
            case "upper": transformed = selectedText.toUpperCase(); break;
            case "capitalize": transformed = toCapitalizeEachWord(selectedText); break;
            case "toggle": transformed = toToggleCase(selectedText); break;
          }

          var span = document.createElement("span");
          span.textContent = transformed;
          span.dataset.case = "$type";
          range.deleteContents();
          range.insertNode(span);

          var newRange = document.createRange();
          newRange.setStartAfter(span);
          newRange.collapse(true);
          sel.removeAllRanges();
          sel.addRange(newRange);

          editor.dispatchEvent(new Event('input', { bubbles: true }));
          return;
        }
      }

      if (!editor.dataset.caseListenerAdded) {
        editor.dataset.caseListenerAdded = "1";

        editor.addEventListener("input", function(e) {
          try {
            var caseType = editor.dataset.caseType || "";
            var sel = window.getSelection();
            if (!sel.rangeCount) return;
            var r = sel.getRangeAt(0);
            var node = r.endContainer;
            var offset = r.endOffset;

            if (node.nodeType !== Node.TEXT_NODE) {
              var child = null;
              if (node.childNodes && node.childNodes.length) {
                child = node.childNodes[Math.max(0, offset - 1)];
                while (child && child.nodeType !== Node.TEXT_NODE) {
                  if (child.childNodes && child.childNodes.length) child = child.childNodes[child.childNodes.length - 1];
                  else break;
                }
              }
              if (child && child.nodeType === Node.TEXT_NODE) {
                node = child;
                offset = Math.min(offset, node.textContent.length);
              } else {
                return;
              }
            }

            var text = node.textContent || "";
            function toSentenceCase(str){ return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase(); }
            function toCapitalizeEachWord(str){ return str.replace(/\\w\\S*/g, function(txt){ return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase(); }); }
            function toToggleCase(str){ return str.split('').map(function(c){ return c === c.toUpperCase() ? c.toLowerCase() : c.toUpperCase(); }).join(''); }

            var transformed = text;
            switch(caseType) {
              case "sentence": transformed = toSentenceCase(text); break;
              case "lower": transformed = text.toLowerCase(); break;
              case "upper": transformed = text.toUpperCase(); break;
              case "capitalize": transformed = toCapitalizeEachWord(text); break;
              case "toggle": transformed = toToggleCase(text); break;
            }

            if (transformed !== text) {
              node.textContent = transformed;
              var newOffset = Math.min(offset, node.textContent.length);
              var newRange = document.createRange();
              newRange.setStart(node, newOffset);
              newRange.collapse(true);
              sel.removeAllRanges();
              sel.addRange(newRange);
            }
          } catch (err) {
            // ignore errors silently
          }
        });
      }
    })();
  ''');
  }

  Future<void> _insertImageToEditor(
      String base64, String mimeType, String altText) async
  {
    try {
      final safeAlt = altText.replaceAll('"', '\\"');
      await _controller.runJavaScript(
          'window.insertImageDataUrl("data:$mimeType;base64,$base64","$safeAlt");');
      ToastHelper.showToast('Image inserted successfully');
      await _debugEditorContent();
    } catch (e) {
      ToastHelper.showToast('Error inserting image: $e');
    }
  }

  Future<void> _insertImageFromUrl(String url) async {
    try {
      final safeUrl = url.replaceAll('"', '\\"');
      await _controller
          .runJavaScript('window.insertImageUrl("$safeUrl","Image");');
      ToastHelper.showToast('Image inserted successfully');
    } catch (e) {
      ToastHelper.showToast('Error inserting image: $e');
    }
  }

  Future<void> _debugEditorContent() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        JSON.stringify({
          "html": document.getElementById('editor').innerHTML,
          "imageCount": document.querySelectorAll('#editor img').length,
          "hasContent": document.getElementById('editor').innerHTML.length > 0
        })
      ''');
    } catch (e) {
      debugPrint('Debug Error: $e');
    }
  }

  Future<String?> _showInputDialog(String hint,
      [String initialValue = '']) async
  {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
        context: context,
        builder: (context) => CustomDialog(
          title: "Enter URL",
          message: "",
          content: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CustomTextFormField(
              controller: controller,
              keyboardType: hint.contains('URL')
                  ? TextInputType.url
                  : TextInputType.text,
              hintText: 'Url',
            ),
          ),
          onCancel: () => Navigator.pop(context),
          onConfirm: () => Navigator.pop(context, controller.text),
          confirmText: "Insert",
        ));
  }

  Future<void> _changeFontFamily(String font) async {
    final safeFont = font.replaceAll('"', '\\"');

    await _controller.runJavaScript('''
    (function() {
      var editor = document.getElementById('editor');
      if (!editor) return;
      var font = "${safeFont}";
      editor.focus();
      var sel = window.getSelection();
      if (!sel.rangeCount) return;
      var range = sel.getRangeAt(0);

      function placeCaretAt(node, offset) {
        var r = document.createRange();
        var s = window.getSelection();
        r.setStart(node, offset);
        r.collapse(true);
        s.removeAllRanges();
        s.addRange(r);
      }

      if (!range.collapsed) {
        try {
          var span = document.createElement('span');
          span.style.fontFamily = font;
          range.surroundContents(span);

          var newRange = document.createRange();
          newRange.setStartAfter(span);
          newRange.collapse(true);
          sel.removeAllRanges();
          sel.addRange(newRange);
        } catch (e) {
          try { document.execCommand('fontName', false, font); } catch(e2) {}
        }
      } else {
        try {
          var span = document.createElement('span');
          span.style.fontFamily = font;
          var zw = document.createTextNode('\\u200B');
          span.appendChild(zw);
          range.insertNode(span);
          placeCaretAt(span.firstChild, 1);
        } catch (e) {
          try { document.execCommand('fontName', false, font); } catch(e2) {}
        }
      }
    })();
  ''');
  }

  Future<void> _changeBorderStyle(String borderStyle) async {
    final safeBorderStyle = borderStyle.replaceAll('"', '\\"');
    await _controller.runJavaScript('''
    (function() {
      var editor = document.getElementById('editor');
      if (!editor) return;
      var borderStyle = "${safeBorderStyle}";
      editor.focus();
      var sel = window.getSelection();
      if (!sel.rangeCount) return;
      var range = sel.getRangeAt(0);

      function placeCaretAt(node, offset) {
        var r = document.createRange();
        var s = window.getSelection();
        r.setStart(node, offset);
        r.collapse(true);
        s.removeAllRanges();
        s.addRange(r);
      }

      if (!range.collapsed) {
        try {
          var span = document.createElement('span');
          span.style.border = borderStyle;
          span.style.display = 'inline-block'; // Ensure border is visible
          span.style.padding = '2px'; // Add padding for better appearance
          range.surroundContents(span);

          var newRange = document.createRange();
          newRange.setStartAfter(span);
          newRange.collapse(true);
          sel.removeAllRanges();
          sel.addRange(newRange);
        } catch (e) {
          console.error('Error applying border:', e);
        }
      } else {
        try {
          var span = document.createElement('span');
          span.style.border = borderStyle;
          span.style.display = 'inline-block';
          span.style.padding = '2px';
          var zw = document.createTextNode('\\u200B');
          span.appendChild(zw);
          range.insertNode(span);
          placeCaretAt(span.firstChild, 1);
        } catch (e) {
          console.error('Error applying border:', e);
        }
      }
    })();
  ''');
  }

  Future<void> _showTableDialog() async {
    final TextEditingController rowController = TextEditingController(text: '3');
    final TextEditingController colController = TextEditingController(text: '3');

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(40),
        elevation: 0,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
              Text(
                'Insert Table',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFieldContainer(
                      controller: rowController,
                      keyboardType: TextInputType.number,
                      hintText: 'Rows', label: 'Rows',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CustomFieldContainer(
                      controller: colController,
                      keyboardType: TextInputType.number,
                      hintText: 'Columns', label: 'Columns',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  text: 'Insert',
                  onPressed: () {
                    final rows = int.tryParse(rowController.text) ?? 3;
                    final cols = int.tryParse(colController.text) ?? 3;
                    if (rows > 0 && cols > 0) {
                      Navigator.pop(context, {'rows': rows, 'cols': cols});
                    } else {
                      ToastHelper.showToast('Please enter valid row and column numbers');
                    }
                  },
                ),
              ),
              SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await _insertTable(result['rows']!, result['cols']!);
    }
  }

  Future<void> _insertTable(int rows, int cols) async {
    try {
      await _controller.runJavaScript('''
      (function() {
        var editor = document.getElementById('editor');
        if (!editor) return;

        // Restore selection or focus at end
        var sel = window.getSelection();
        if (typeof lastRange !== 'undefined' && lastRange !== null) {
          sel.removeAllRanges();
          try { sel.addRange(lastRange); } catch(e) {}
        } else {
          editor.focus();
          var range = document.createRange();
          range.selectNodeContents(editor);
          range.collapse(false);
          sel.removeAllRanges();
          sel.addRange(range);
        }

        // Create table
        var table = document.createElement('table');
        table.style.borderCollapse = 'collapse';
        table.style.width = '100%';
        table.style.margin = '8px 0';
        for (var i = 0; i < ${rows}; i++) {
          var tr = document.createElement('tr');
          for (var j = 0; j < ${cols}; j++) {
            var td = document.createElement('td');
            td.style.border = '1px solid #ccc';
            td.style.padding = '8px';
            td.innerHTML = '<br>';
            tr.appendChild(td);
          }
          table.appendChild(tr);
        }

        // Insert table at caret
        var range = sel.getRangeAt(0);
        range.deleteContents();
        range.insertNode(table);

        // Add paragraph after table for better editing flow
        var p = document.createElement('p');
        p.innerHTML = '<br>';
        range.setStartAfter(table);
        range.collapse(true);
        range.insertNode(p);

        // Place caret in first cell
        var firstCell = table.querySelector('td');
        if (firstCell) {
          range.setStart(firstCell, 0);
          range.setEnd(firstCell, 0);
          sel.removeAllRanges();
          sel.addRange(range);
          lastRange = range.cloneRange();
        }

        // Trigger input event
        var event = new Event('input', { bubbles: true });
        editor.dispatchEvent(event);
      })();
    ''');
      ToastHelper.showToast('Table inserted successfully');
    } catch (e) {
      ToastHelper.showToast('Error inserting table: $e');
    }
  }

  String _getInitialText() {
    if (widget.descriptionText.isEmpty) {
      return '';
    }

    String cleanText = widget.descriptionText.trim();

    if (cleanText.startsWith('"') && cleanText.endsWith('"')) {
      try {
        cleanText = jsonDecode(cleanText);
      } catch (_) {
        cleanText = cleanText.substring(1, cleanText.length - 1);
      }
    }

    cleanText = cleanText
        .replaceAllMapped(RegExp(r'\\+u003[cC]'), (_) => '<')
        .replaceAllMapped(RegExp(r'\\+u003[eE]'), (_) => '>')
        .replaceAllMapped(RegExp(r'\\+u0026'), (_) => '&')
        .replaceAll(RegExp(r'u003c', caseSensitive: false), '<')
        .replaceAll(RegExp(r'u003e', caseSensitive: false), '>')
        .replaceAll(RegExp(r'u0026', caseSensitive: false), '&')
        .replaceAll(r'\/', '/')
        .replaceAll(r'\"', '"')
        .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
        .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&#60;|&#x3c;', caseSensitive: false), '<')
        .replaceAll(RegExp(r'&#62;|&#x3e;', caseSensitive: false), '>')
        .replaceAll(RegExp(r'&#38;|&#x26;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&quot;', caseSensitive: false), '"')
        .replaceAll(RegExp(r'&#39;|&apos;', caseSensitive: false), "'");

    if (!cleanText.startsWith('<') && cleanText.isNotEmpty) {
      cleanText = '<p>$cleanText</p>';
    }
    return cleanText;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ImageData {
  final String base64;
  final String mimeType;

  ImageData({required this.base64, required this.mimeType});
}
