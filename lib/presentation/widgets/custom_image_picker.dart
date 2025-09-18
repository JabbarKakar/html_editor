import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomImagePicker extends StatelessWidget {
  static final ImagePicker _picker = ImagePicker();
  final ValueNotifier<File?> imageNotifier;
  final double height;
  final double width;
  final double borderRadius;
  final double imgRadius;
  final double iconSize;
  final IconData placeholderIcon;
  final String? placeholderImagePath;
  final String? placeholderText;
  final Color placeholderColor;
  final Color borderColor;
  final Color backgroundColor;
  final TextStyle? placeholderTextStyle;
  final Function(File?)? onImageSelected;
  final bool isImagePickerEnabled;
  final String? networkImageUrl;

  const CustomImagePicker({
    Key? key,
    required this.imageNotifier,
    this.height = 200.0,
    this.width = double.infinity,
    this.borderRadius = 14.0,
    this.imgRadius = 14.0,
    this.iconSize = 100.0,
    this.placeholderIcon = Icons.person,
    this.placeholderImagePath,
    this.placeholderText,
    this.placeholderColor = Colors.grey,
    this.borderColor = Colors.yellow,
    this.backgroundColor = Colors.white,
    this.placeholderTextStyle,
    this.onImageSelected,
    this.isImagePickerEnabled = true,
    this.networkImageUrl,

  }) : super(key: key);

  static void showImagePickerOptions({
    required BuildContext context,
    required ValueNotifier<File?> imageNotifier,
  }) {
    print("showImagePickerOptions called");
    final picker = ImagePicker();

    Future<void> pickImage(ImageSource source) async {
      print("pickImage called with source: $source");
      final XFile? pickedFile = await picker.pickImage(source: source);
      print("pickImage result: ${pickedFile?.path ?? 'null'}");
      if (pickedFile != null) {
        imageNotifier.value = File(pickedFile.path);
        print("Image picked and set to notifier: ${pickedFile.path}");
      } else {
        print("No image was picked");
      }
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(40),
        elevation: 0,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: 10,left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding:  EdgeInsets.all(16),
                    child: GestureDetector(
                        onTap:  () => Navigator.pop(context),
                        child: Icon(Icons.cancel_outlined, color: Colors.black,size: 18,)),
                  )),
              Center(child: Text('Select Image Source', style: TextStyle(fontSize: 20,fontFamily: 'Inter',fontWeight: FontWeight.w500))),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => pickImage(ImageSource.camera),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 36, color: Colors.blue),
                        SizedBox(height: 8,),
                        Text('Camera', style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  SizedBox(width: 10,),
                  GestureDetector(
                    onTap: () => pickImage(ImageSource.gallery),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 36, color: Colors.blue),
                        SizedBox(height: 8,),
                        Text('Gallery', style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15,),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isImagePickerEnabled
          ? () => showImagePickerOptions(
        context: context,
        imageNotifier: imageNotifier,
      )
          : null,

      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor),
        ),
        child: ValueListenableBuilder<File?>(
          valueListenable: imageNotifier,
          builder: (context, file, _) {
            if (file != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.file(file, fit: BoxFit.cover),
              );
            } else if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.network(networkImageUrl!, fit: BoxFit.cover),
              );
            } else {
              return Center(child: Icon(Icons.add_a_photo, size: 30));
            }
          },
        ),
      ),
    );
  }
  static Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

}
