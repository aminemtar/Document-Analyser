import 'dart:convert';

class DocItem {
  final String name;
  final String type;
  final String size;
  final String date;
  final String status;
  final String? path;
  final String? analysisJson;
  const DocItem(this.name, this.type, this.size, this.date, this.status,
      {this.path, this.analysisJson});

  DocItem copyWith({String? status, String? analysisJson}) => DocItem(
      name, type, size, date, status ?? this.status,
      path: path, analysisJson: analysisJson ?? this.analysisJson);

  Map<String, dynamic> toJson() => {
        'name': name, 'type': type, 'size': size, 'date': date,
        'status': status, 'path': path, 'analysisJson': analysisJson
      };
  factory DocItem.fromJson(Map<String, dynamic> json) => DocItem(
        json['name'] ?? 'Untitled document',
        json['type'] ?? 'FILE',
        json['size'] ?? '—',
        json['date'] ?? 'Recently added',
        json['status'] ?? 'Ready',
        path: json['path'],
        analysisJson: json['analysisJson'],
      );
}
