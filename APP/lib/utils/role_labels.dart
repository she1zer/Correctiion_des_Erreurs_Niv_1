String roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Administrateur';
    case 'technicien':
      return 'Employé';
    case 'client':
      return 'Client';
    default:
      return role;
  }
}

String displayRole(String? poste, String role) {
  if (poste != null && poste.isNotEmpty) return poste;
  return roleLabel(role);
}
