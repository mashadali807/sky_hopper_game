import 'package:flutter/material.dart';

/// A purchasable, selectable player appearance.
/// Pure data — no Flutter widgets, no storage references.
class CharacterSkin {
  const CharacterSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.bodyColor,
    required this.accentColor,
  });

  /// Stable id used as the storage key. NEVER change once shipped.
  final String id;
  final String name;
  final int price;
  final Color bodyColor;
  final Color accentColor;

  bool get isFree => price == 0;
}

/// Built-in skin collection. Real sprites arrive in Module 9; for now each
/// skin is rendered as a colored circle with an accent eye.
const List<CharacterSkin> kCharacterSkins = [
  CharacterSkin(
    id: 'default',
    name: 'Sunny',
    price: 0,
    bodyColor: Color(0xFFFFC107),
    accentColor: Colors.black87,
  ),
  CharacterSkin(
    id: 'azure',
    name: 'Azure',
    price: 50,
    bodyColor: Color(0xFF42A5F5),
    accentColor: Colors.white,
  ),
  CharacterSkin(
    id: 'mint',
    name: 'Mint',
    price: 100,
    bodyColor: Color(0xFF66BB6A),
    accentColor: Colors.black87,
  ),
  CharacterSkin(
    id: 'coral',
    name: 'Coral',
    price: 150,
    bodyColor: Color(0xFFEF5350),
    accentColor: Colors.white,
  ),
  CharacterSkin(
    id: 'violet',
    name: 'Violet',
    price: 250,
    bodyColor: Color(0xFFAB47BC),
    accentColor: Colors.white,
  ),
  CharacterSkin(
    id: 'gold',
    name: 'Gold',
    price: 500,
    bodyColor: Color(0xFFFFD700),
    accentColor: Color(0xFF5D4037),
  ),
];

CharacterSkin skinById(String id) => kCharacterSkins.firstWhere(
  (s) => s.id == id,
  orElse: () => kCharacterSkins.first,
);
