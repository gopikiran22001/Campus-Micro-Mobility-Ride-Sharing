class CollegeDomains {
  CollegeDomains._();

  // Map of Domain -> College Name
  // In a production app, this would be fetched from a backend Config/RemoteConfig
  static const Map<String, String> allowedDomains = {
    'pvpsit.ac.in': 'PVP Siddhartha Institute of Technology',
    'vrsec.ac.in': 'Velagapudi Ramakrishna Siddhartha Engineering College',
    'university.edu': 'Demo University', // For testing
    'college.edu': 'Demo College', // For testing
    // Add more allowed domains here
  };

  static bool isAllowed(String email) {
    if (!email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.containsKey(domain);
  }

  static String? getCollegeName(String email) {
    if (!email.contains('@')) return null;
    final domain = email.split('@').last.toLowerCase();
    return allowedDomains[domain];
  }
}
