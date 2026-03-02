import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/unavailability_model.dart';
import '../../domain/entities/unavailability_entity.dart';

/// Provider que retorna todas as indisponibilidades da igreja do usuário logado
final churchUnavailabilitiesProvider =
    StreamProvider.autoDispose<List<UnavailabilityEntity>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user?.churchId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('unavailabilities')
      .where('churchId', isEqualTo: user!.churchId)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => UnavailabilityModel.fromFirestore(doc))
            .toList();
        // Ordena no client-side
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        return list;
      });
});

/// Provider que retorna as indisponibilidades de um usuário específico
final userUnavailabilitiesProvider = StreamProvider.autoDispose
    .family<List<UnavailabilityEntity>, String>((ref, userId) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user?.churchId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('unavailabilities')
      .where('churchId', isEqualTo: user!.churchId)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => UnavailabilityModel.fromFirestore(doc))
            .toList();
        // Ordena no client-side
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        return list;
      });
});

