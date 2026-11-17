/// App-wide settings. Change these in one place.
///
/// The Firebase Web API key identifies the project to Firebase; it is not a
/// password. Access to data is controlled by the database security rules in
/// database.rules.json.
class AppConfig {
  static const firebaseApiKey = 'AIzaSyClRGizpf5NQf0EAiKz67BZN_nSwBIuKxw';
  static const databaseUrl = 'https://shop-77d61-default-rtdb.firebaseio.com';

  /// WhatsApp number for orders, in international format without "+".
  static const whatsappNumber = '254743676970';

  static const currency = 'KES';
  static const shopName = 'MyShop';
}
