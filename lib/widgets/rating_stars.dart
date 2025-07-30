import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showRating;
  final VoidCallback? onTap;
  final bool interactive;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
    this.showRating = false,
    this.onTap,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            double starRating = rating - index;
            IconData iconData;
            Color starColor;

            if (starRating >= 1) {
              iconData = Icons.star;
              starColor = color ?? Colors.amber;
            } else if (starRating > 0) {
              iconData = Icons.star_half;
              starColor = color ?? Colors.amber;
            } else {
              iconData = Icons.star_border;
              starColor = color ?? Colors.grey[400]!;
            }

            return Icon(iconData, size: size, color: starColor);
          }),
          if (showRating) ...[
            SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InteractiveRatingStars extends StatefulWidget {
  final double initialRating;
  final double size;
  final Color? color;
  final Function(double) onRatingChanged;

  const InteractiveRatingStars({
    super.key,
    required this.initialRating,
    this.size = 24,
    this.color,
    required this.onRatingChanged,
  });

  @override
  State<InteractiveRatingStars> createState() => _InteractiveRatingStarsState();
}

class _InteractiveRatingStarsState extends State<InteractiveRatingStars> {
  late double currentRating;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              currentRating = index + 1.0;
            });
            widget.onRatingChanged(currentRating);
          },
          onPanUpdate: (details) {
            // Handle drag to rate
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(
              details.globalPosition,
            );
            final starIndex = (localPosition.dx / (widget.size + 4)).floor();
            final newRating = (starIndex + 1).clamp(1, 5).toDouble();

            if (newRating != currentRating) {
              setState(() {
                currentRating = newRating;
              });
              widget.onRatingChanged(currentRating);
            }
          },
          child: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            size: widget.size,
            color: index < currentRating
                ? (widget.color ?? Colors.amber)
                : Colors.grey[400],
          ),
        );
      }),
    );
  }
}
