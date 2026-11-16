import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/document_type.dart';

class RequirementUploadTile extends StatelessWidget {
  final Requirement requirement;
  final Uint8List? bytes;
  final bool showError;
  final VoidCallback onTap;

  const RequirementUploadTile({
    super.key,
    required this.requirement,
    required this.bytes,
    required this.showError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final missing = showError && bytes == null;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: missing ? const Color(0xFFB42318) : AppColors.cardBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.welcomeCard,
                  child: bytes == null
                      ? const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary)
                      : Image.memory(bytes!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${requirement.label} *',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      missing ? 'This upload is required.' : requirement.hint,
                      style: TextStyle(
                        fontSize: 11,
                        color: missing
                            ? const Color(0xFFB42318)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                bytes == null ? Icons.upload_file : Icons.check_circle,
                color: bytes == null ? AppColors.primary : AppColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}