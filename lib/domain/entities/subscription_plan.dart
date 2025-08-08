class SubscriptionPlan {
  final String planType;
  final String price;
  final String title;

  const SubscriptionPlan({
    required this.planType,
    required this.price,
    required this.title,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      planType: json['planType'] as String,
      price: json['price'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'planType': planType, 'price': price, 'title': title};
  }
}
