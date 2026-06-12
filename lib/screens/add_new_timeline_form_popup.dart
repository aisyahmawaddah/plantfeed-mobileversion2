import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/providers/user_model_provider.dart';
import 'package:provider/provider.dart';

class AddNewTimelineScreenPopup extends StatefulWidget {
  final int groupId;
  const AddNewTimelineScreenPopup({Key? key, required this.groupId})
      : super(key: key);

  @override
  State<AddNewTimelineScreenPopup> createState() =>
      _AddNewTimelineScreenPopupState();
}

class _AddNewTimelineScreenPopupState
    extends State<AddNewTimelineScreenPopup> {
  final _formKey = GlobalKey<FormState>();
  File? photo;
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String _skill = 'Beginner';
  String _state = 'Johor';

  final List<String> _skillOptions = [
    'Beginner',
    'Average',
    'Skilled',
    'Specialist',
    'Expert',
  ];

  final List<String> _stateOptions = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('New Post',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _sectionLabel('Title'),
            TextFormField(
              controller: titleController,
              decoration: _inputDecoration('Enter title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Message
            _sectionLabel('Message'),
            TextFormField(
              controller: messageController,
              maxLines: 5,
              decoration: _inputDecoration('Enter feed message...'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Message is required' : null,
            ),
            const SizedBox(height: 16),

            // Farming Skill Level
            _sectionLabel('Farming Skill Level'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Column(
                children: _skillOptions.map((skill) {
                  return RadioListTile<String>(
                    title: Text(skill, style: const TextStyle(fontSize: 14)),
                    value: skill,
                    groupValue: _skill,
                    activeColor: Colors.green,
                    dense: true,
                    onChanged: (v) => setState(() => _skill = v!),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            _sectionLabel('Location'),
            DropdownButtonFormField<String>(
              value: _state,
              decoration: _inputDecoration(null),
              items: _stateOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _state = v!),
            ),
            const SizedBox(height: 16),

            // Photo
            _sectionLabel('Photo'),
            if (photo != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(photo!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => photo = null),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await ImagePicker()
                    .pickImage(source: ImageSource.gallery);
                if (picked != null && mounted) {
                  setState(() => photo = File(picked.path));
                }
              },
              icon: const Icon(Icons.photo_library, color: Colors.green),
              label: Text(
                  photo == null ? 'Choose Photo' : 'Change Photo',
                  style: const TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 28),

            // Upload button
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                int userId = userProvider.getUser?.id ?? 1;
                await apiService.addNewGroupSharing(
                  titleController.text.trim(),
                  messageController.text.trim(),
                  userId,
                  widget.groupId,
                  photo,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text('Upload',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}