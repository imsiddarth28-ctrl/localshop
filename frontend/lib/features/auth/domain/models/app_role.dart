enum AppRole {
  customer,
  shopOwner,
  admin;

  String toDbString() {
    switch (this) {
      case AppRole.customer:
        return 'customer';
      case AppRole.shopOwner:
        return 'shop_owner';
      case AppRole.admin:
        return 'admin';
    }
  }

  static AppRole fromDbString(String? role) {
    switch (role) {
      case 'shop_owner':
        return AppRole.shopOwner;
      case 'admin':
        return AppRole.admin;
      case 'customer':
      default:
        return AppRole.customer;
    }
  }
}
