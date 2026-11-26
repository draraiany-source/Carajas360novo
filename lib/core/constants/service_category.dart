import 'package:flutter/material.dart';

class ServiceCategory {
  final String id, name, emoji, group;
  final Color color;
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.group,
    required this.color,
  });
}
