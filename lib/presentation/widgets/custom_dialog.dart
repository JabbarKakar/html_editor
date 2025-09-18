
import 'package:flutter/material.dart';

import 'custom_button.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final String message;
  final Widget? content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancelButton;
  final bool showConfirmButton;
  final Color confirmButtonColor;
  final Color cancelButtonColor;
  final EdgeInsets? insetPadding;
  final String? errorText;

  const CustomDialog({
    Key? key,
    required this.title,
    this.titleWidget,
    required this.message,
    this.onConfirm,
    this.confirmText = "OK",
    this.cancelText = "Cancel",
    this.onCancel,
    this.showCancelButton = true,
    this.showConfirmButton = true,
    this.content,
    this.confirmButtonColor = Colors.blue,
    this.cancelButtonColor = Colors.red,
    this.insetPadding,
    this.errorText,
    List<TextButton>? additionalActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: insetPadding ?? EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: titleWidget ??
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
            SizedBox(height: 16,),
            if (content != null)
              content!
            else
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                textAlign: TextAlign.left,
              ),
            // Display error message if present
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorText!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(height: 18,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showCancelButton)
                  CustomButton(
                    hasShadow: false,
                    borderColor: Colors.black,
                    color: Colors.white,
                    textColor: Colors.black,
                    borderWidth: 1,
                    text: cancelText,
                    textSize: 12,
                    padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                if (showCancelButton && showConfirmButton) SizedBox(width: 20,),
                if (showConfirmButton)
                  CustomButton(
                    color: confirmButtonColor,
                    text: confirmText,
                    textSize: 12,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    onPressed: () {
                      if (onConfirm != null) {
                        onConfirm!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
