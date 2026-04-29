import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _kMaxPhotos = 3;

/// Horizontal strip that shows uploaded animal photos and an add-more button.
/// Manages no state itself — keep [photoUrls] in the parent screen.
class AnimalPhotoStrip extends StatelessWidget {
  const AnimalPhotoStrip({
    super.key,
    required this.photoUrls,
    required this.onAdd,
    required this.onRemove,
    this.isLoading = false,
  });

  final List<String> photoUrls;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int i = 0; i < photoUrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _PhotoTile(
                url: photoUrls[i],
                onRemove: () => onRemove(i),
              ),
            ),
          if (photoUrls.length < _kMaxPhotos)
            _AddTile(isLoading: isLoading, onTap: isLoading ? null : onAdd),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 108,
            height: 108,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: 108,
              height: 108,
              color: Colors.grey.shade100,
            ),
            errorWidget: (_, _, _) => Container(
              width: 108,
              height: 108,
              color: Colors.grey.shade100,
              child: Icon(Icons.broken_image_outlined,
                  color: AppColors.muted, size: 28),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          color: AppColors.primary.withValues(alpha: 0.04),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 30,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Foto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
