class ServerModel {
  final String id;
  final String name;
  final String createdBy;

  ServerModel({
    required this.id,
    required this.name,
    required this.createdBy,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
    );
  }
}

class ChannelModel {
  final String id;
  final String serverId;
  final String name;

  ChannelModel({
    required this.id,
    required this.serverId,
    required this.name,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String,
      serverId: json['server_id'] as String,
      name: json['name'] as String,
    );
  }
}