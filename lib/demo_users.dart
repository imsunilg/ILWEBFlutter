/// Demo/development credentials. Only referenced when `enableDemoLogin` is true (never in production builds).
class DemoUser {
  const DemoUser({required this.role, required this.username, required this.password});

  final String role;
  final String username;
  final String password;

  String get label => role[0] + role.substring(1).toLowerCase();
}

const demoUsers = [
  DemoUser(role: 'ADMIN', username: 'admin', password: 'Admin@123'),
  DemoUser(role: 'AGENT', username: 'agent', password: 'Agent@123'),
  DemoUser(role: 'UNDERWRITER', username: 'underwriter', password: 'Underwriter@123'),
  DemoUser(role: 'MANAGER', username: 'manager', password: 'Manager@123'),
  DemoUser(role: 'CUSTOMER', username: 'customer', password: 'Customer@123'),
];
