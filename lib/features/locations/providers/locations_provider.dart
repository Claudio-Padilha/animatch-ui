import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/domain/municipalities.dart';
import '../data/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>(
  (ref) => LocationsRepository(ref.watch(dioProvider)),
);

/// Fetched once per app session and cached in memory — states/cities don't
/// change during a session, so every screen shares the same result.
final municipalitiesProvider = FutureProvider<Municipalities>(
  (ref) => ref.watch(locationsRepositoryProvider).getMunicipalities(),
);
