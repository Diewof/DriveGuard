class EmergencyContact {
  final String? id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priority;
  final bool isActive;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.priority = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'priority': priority,
      'isActive': isActive,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      relationship: json['relationship'] ?? '',
      priority: json['priority'] ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    int? priority,
    bool? isActive,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
    );
  }
}