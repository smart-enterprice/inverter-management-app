String formatRole(String? role) {
  switch (role) {
    case 'ROLE_DEALER':
      return 'Dealer';
    case 'ROLE_MANAGER':
      return 'Manager';
    case 'ROLE_ADMIN':
      return 'Admin';
    case 'ROLE_SUPER_ADMIN':
      return 'Super Admin';
    case 'ROLE_PROJECT_MANAGER':
      return 'Project Manager';
    default:
      return role ?? 'N/A';
  }
}
