import 'package:dio/dio.dart';

import '../../../shared/domain/association.dart';
import '../../../shared/domain/breeder_association.dart';
import '../../auth/domain/breeder.dart';
import '../domain/breeder_statistics.dart';

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<List<Association>> getAssociations() async {
    final response = await _dio.get<List<dynamic>>('/associations');
    return (response.data as List)
        .map((e) => Association.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BreederStatistics> getStatistics() async {
    final response = await _dio.get<Map<String, dynamic>>('/breeders/statistic');
    return BreederStatistics.fromJson(response.data!);
  }

  Future<Breeder> activate({
    required String breederId,
    required String name,
    required String phone,
    String? cpf,
    String? farmName,
    List<BreederAssociation> associations = const [],
    String? pictureUrl,
    required String directions,
    required String zipCode,
    required String city,
    required String state,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/breeders/$breederId/activate',
      options: Options(contentType: 'application/json'),
      data: {
        'name': name,
        'phone': phone,
        if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
        if (farmName != null && farmName.isNotEmpty) 'propertyName': farmName,
        if (associations.isNotEmpty)
          'associations': associations.map((a) => a.toJson()).toList(),
        'pictureUrl': ?pictureUrl,
        'address': {
          'directions': directions,
          'zipCode': zipCode,
          'city': city,
          'state': state,
        },
      },
    );
    return Breeder.fromJson(response.data!);
  }

  Future<Breeder> updateProfile({
    required String breederId,
    required String name,
    String? phone,
    String? farmName,
    String? city,
    String? state,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/breeders/$breederId',
      options: Options(contentType: 'application/json'),
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (farmName != null && farmName.isNotEmpty) 'propertyName': farmName,
        if (city != null && city.isNotEmpty || state != null && state.isNotEmpty)
          'address': {
            if (city != null && city.isNotEmpty) 'city': city,
            if (state != null && state.isNotEmpty) 'state': state,
          },
      },
    );
    return Breeder.fromJson(response.data!);
  }
}
