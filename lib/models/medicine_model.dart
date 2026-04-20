class Medicine {
  String name;
  String time;

  Medicine({required this.name, required this.time});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
    };
  }
}