import 'dart:math';

String truncateName(String name, {int maxLength = 40, double? availableWidth}) {
  if (availableWidth != null) {
    // For PlayerCard: Estimate max characters based on available width.
    // Assuming an average character width of ~10.0 pixels for titleLarge text style.
    const double estimatedCharWidth = 10.0;
    final dynamicMaxLength = (availableWidth / estimatedCharWidth).floor();
    
    if (name.length <= dynamicMaxLength) {
      return name;
    }
    
    // Set maxLength to the calculated dynamic limit, ensuring it's at least 5 
    // to allow for "..." and a couple of characters.
    maxLength = max(5, dynamicMaxLength); 
  }

  if (name.length <= maxLength) {
    return name;
  }
  return '${name.substring(0, maxLength - 3)}...';
}
