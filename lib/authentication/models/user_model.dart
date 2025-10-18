class UserModel {
  UserModel({
    this.image,
    this.about,
    this.name,
    this.createdAt,
    this.isOnline,
    this.id,
    this.lastActive,
    this.email,
    this.pushToken,
    this.role,
    this.classLevel,
    this.isDeleted,
    this.liveDuration,
    this.canCreate,
  });
  String? image;
  String? about;
  String? name;
  String? createdAt;
  bool? isOnline;
  String? id;
  String? lastActive;
  String? email;
  String? pushToken;
  String? role;
  String? classLevel;
  bool? isDeleted;
  int? liveDuration;
  bool? canCreate;

  RoleType getRoleType() {
    RoleType? result = RoleType.tutor;
    // RoleType? result;
    switch (role) {
      case "tutor":
        result = RoleType.tutor;
        break;
      case "student":
        result = RoleType.student;
        break;
      default:
    }
    return result;
  }

  UserModel.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    about = json['about'] ?? '';
    name = json['name'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['is_online'] ?? true;
    id = json['id'] ?? '';
    lastActive = json['last_active'] ?? '';
    email = json['email'] ?? '';
    pushToken = json['push_token'] ?? '';
    role = json['role'] ?? '';
    classLevel = json['class_level'] ?? '';
    isDeleted = json['is_deleted'] ?? false;
    liveDuration = json['live_duration'] ?? 0;
    canCreate = json['can_create'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    data['about'] = about;
    data['name'] = name;
    data['created_at'] = createdAt;
    data['is_online'] = isOnline;
    data['id'] = id;
    data['last_active'] = lastActive;
    data['email'] = email;
    data['push_token'] = pushToken;
    data['role'] = role;
    data['class_level'] = classLevel;
    data['is_deleted'] = isDeleted;
    data['live_duration'] = liveDuration;
    data['can_create'] = canCreate;
    return data;
  }
}

enum RoleType { tutor, student }
