import 'package:flutter/material.dart';

enum PlayerShape { circle, square, triangle, star, hexagon }

/// A purchasable, selectable player appearance.
class CharacterSkin {
  const CharacterSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.bodyColor,
    required this.accentColor,
    this.shape = PlayerShape.circle, // Default to circle for old skins
  });

  final String id;
  final String name;
  final int price;
  final Color bodyColor;
  final Color accentColor;
  final PlayerShape shape;

  bool get isFree => price == 0;
}

/// Built-in skin collection.
const List<CharacterSkin> kCharacterSkins = [
  // --- Classic Circles ---
  CharacterSkin(
    id: 'default',
    name: 'Sunny',
    price: 0,
    bodyColor: Color(0xFFFFC107),
    accentColor: Colors.black87,
    shape: PlayerShape.circle,
  ),
  CharacterSkin(
    id: 'azure',
    name: 'Azure',
    price: 50,
    bodyColor: Color(0xFF42A5F5),
    accentColor: Colors.white,
    shape: PlayerShape.circle,
  ),
  CharacterSkin(
    id: 'mint',
    name: 'Mint',
    price: 100,
    bodyColor: Color(0xFF66BB6A),
    accentColor: Colors.black87,
    shape: PlayerShape.circle,
  ),

  // --- Premium Shapes ---
  CharacterSkin(
    id: 'square_coral',
    name: 'Coral Box',
    price: 150,
    bodyColor: Color(0xFFEF5350),
    accentColor: Colors.white,
    shape: PlayerShape.square,
  ),
  CharacterSkin(
    id: 'tri_violet',
    name: 'Violet Tri',
    price: 250,
    bodyColor: Color(0xFFAB47BC),
    accentColor: Colors.white,
    shape: PlayerShape.triangle,
  ),
  CharacterSkin(
    id: 'star_gold',
    name: 'Gold Star',
    price: 500,
    bodyColor: Color(0xFFFFD700),
    accentColor: Color(0xFF5D4037),
    shape: PlayerShape.star,
  ),
  CharacterSkin(
    id: 'hex_cyan',
    name: 'Cyan Hex',
    price: 750,
    bodyColor: Color(0xFF00BCD4),
    accentColor: Colors.white,
    shape: PlayerShape.hexagon,
  ),
];

CharacterSkin skinById(String id) => kCharacterSkins.firstWhere(
  (s) => s.id == id,
  orElse: () => kCharacterSkins.first,
);
