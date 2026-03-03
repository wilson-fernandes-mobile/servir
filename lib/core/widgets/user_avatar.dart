import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Widget reutilizável para exibir avatar de usuário.
/// Suporta:
/// - Fotos em base64 (salvas no Firestore)
/// - URLs de rede (Firebase Storage)
/// - Fallback para inicial do nome
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.userName,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primaryLight;
    final txtColor = textColor ?? AppColors.primary;

    // Se não tem foto, mostra inicial
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.6,
            color: txtColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Se tem foto, tenta exibir
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: _buildImage(photoUrl!, userName, radius, txtColor),
      ),
    );
  }

  Widget _buildImage(String url, String name, double radius, Color txtColor) {
    // Verifica se é base64
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(name, radius, txtColor),
        );
      } catch (e) {
        return _buildFallback(name, radius, txtColor);
      }
    }

    // Se for URL de rede (Firebase Storage)
    return CachedNetworkImage(
      imageUrl: url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      placeholder: (context, url) => SizedBox(
        width: radius * 0.6,
        height: radius * 0.6,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => _buildFallback(name, radius, txtColor),
    );
  }

  Widget _buildFallback(String name, double radius, Color txtColor) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: radius * 0.6,
        color: txtColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

