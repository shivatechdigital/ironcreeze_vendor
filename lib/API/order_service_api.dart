class OrderService {
  static Future<void> acceptOrder(String orderId) async {
    try {
      // your API call
      print("Order Accepted: $orderId");

      // Example:
      // await http.post("api/accept-order")
    } catch (e) {
      print("Accept Order Failed");
    }
  }
}
