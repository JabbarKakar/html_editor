import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool showCursor;
  final GestureTapCallback? onTap;
  final double fontSize;
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final int? maxLimit;
  final TextCapitalization textCapitalization;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines,
    this.minLines,
    this.fieldKey,
    this.focusNode,
    this.readOnly = false,
    this.showCursor = true,
    this.onTap,
    this.fontSize = 11.0,
    this.onChanged,
    this.maxLimit,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textCapitalization: textCapitalization,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      autofocus: false,
      maxLength: maxLimit,
      maxLengthEnforcement: maxLimit != null
          ? MaxLengthEnforcement.enforced
          : MaxLengthEnforcement.none,
      showCursor: showCursor,
      cursorColor: Colors.yellow,
      readOnly: readOnly,
      key: fieldKey,
      focusNode: focusNode,
      onTap: onTap,
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.black,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Inter',
          overflow: TextOverflow.ellipsis,
        ),
        errorStyle: TextStyle(fontSize: 9, color: Colors.red),
        errorMaxLines: 3,
        counterText: "",
        border: InputBorder.none,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixIconConstraints: BoxConstraints(maxHeight: 28),
        prefixIconConstraints: BoxConstraints(maxHeight: 28),
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        isDense: true,
      ),
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      enabled: !readOnly,
      onChanged: (value) {
        // Automatically remove error once valid input is provided
        // if (fieldKey != null) {
        //   fieldKey!.currentState?.validate();
        // }
        // if (onChanged != null) {
        //   onChanged!(value);
        // }
      },
    );
  }
}

class CustomFieldContainer extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  final Widget? leadingIcon;
  final GestureTapCallback? onTap;
  final GlobalKey<FormFieldState>? fieldKey;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool showCursor;
  final double fontSize;
  final int? maxLimit;
  final bool showCharCount;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  const CustomFieldContainer({
    Key? key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines,
    this.minLines,
    this.leadingIcon,
    this.fieldKey,
    this.focusNode,
    this.readOnly = false,
    this.showCursor = true,
    this.onTap,
    this.fontSize = 11.0,
    this.maxLimit,
    this.showCharCount = true,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  _CustomFieldContainerState createState() => _CustomFieldContainerState();
}

class _CustomFieldContainerState extends State<CustomFieldContainer> {
  late ValueNotifier<int> currentLengthNotifier;

  @override
  void initState() {
    super.initState();
    currentLengthNotifier = ValueNotifier<int>(widget.controller.text.length);

    widget.controller.addListener(() {
      currentLengthNotifier.value = widget.controller.text.length;
    });
  }

  @override
  void dispose() {
    currentLengthNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, top: 10, bottom: 8, right: 0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            widget.leadingIcon!,
            SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: (widget.fontSize - 1),
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (widget.maxLimit != null && widget.showCharCount)
                      ValueListenableBuilder<int>(
                        valueListenable: currentLengthNotifier,
                        builder: (context, currentLength, child) {
                          return Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Text(
                              '$currentLength/${widget.maxLimit}',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: 2),
                GestureDetector(
                  onTap: widget.onTap,
                  child: CustomTextFormField(
                    controller: widget.controller,
                    hintText: widget.hintText,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.suffixIcon,
                    validator: widget.validator,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    fieldKey: widget.fieldKey,
                    focusNode: widget.focusNode,
                    readOnly: widget.readOnly,
                    showCursor: widget.showCursor,
                    fontSize: widget.fontSize,
                    maxLimit: widget.maxLimit,

                    textCapitalization: widget.textCapitalization,
                    onChanged: (value) {
                      if (widget.fieldKey != null) {
                        widget.fieldKey!.currentState?.validate();
                      }
                      if (widget.onChanged != null) {
                        widget.onChanged!(value);
                      }
                    },
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