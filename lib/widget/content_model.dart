class ContentModel {
  String image;
  String title;
  String description;

  ContentModel({required this.image, required this.title, required this.description});
}

List<ContentModel> contents = [
  ContentModel(
    image: "images/screen1.png",
    title: "Delicious Food",
    description: "Order your favorite food from the best restaurants in town",
  ),
  ContentModel(
    image: "images/screen2.png",
    title: "Fast Delivery",
    description: "Get your food delivered to your doorstep in minutes",
  ),
  ContentModel(
    image: "images/screen3.png",
    title: "Easy Payment",
    description: "Pay securely with your preferred payment method",
  ),
]; 