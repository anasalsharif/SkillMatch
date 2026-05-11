import 'package:flutter/material.dart';

class RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int ratingCount;
  final double? myRating;
  final bool isLoading;
  final void Function(double)? onRate;
  final bool allowUpdate;

  const RatingDisplay({
    Key? key,
    required this.averageRating,
    required this.ratingCount,
    this.myRating,
    this.isLoading = false,
    this.onRate,
    this.allowUpdate = false,
  }) : super(key: key);

  Widget _buildRatingStars(BuildContext context, double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(
          Icon(Icons.star, color: Theme.of(context).primaryColor, size: 32),
        );
      } else if (rating >= i - 0.5) {
        stars.add(
          Icon(
            Icons.star_half,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
        );
      } else {
        stars.add(
          Icon(
            Icons.star_border,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
        );
      }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildRatingStars(context, averageRating),
                const SizedBox(height: 8),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            if (allowUpdate && onRate != null) ...[const SizedBox(height: 16)],
          ],
        ),
      ),
    );
  }
}
