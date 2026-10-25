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

  String toDisplayName() {
    switch (this) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.shopOwner:
        return 'Shop Owner';
      case AppRole.admin:
        return 'Admin';
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
