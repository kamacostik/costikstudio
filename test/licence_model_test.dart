import 'package:costikstudio/core/models/licence_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LicenceModel serialization and deserialization', () {
    final now = DateTime.now();
    final licence = LicenceModel(
      id: 'lic-123',
      userId: 'usr-456',
      startDate: now,
      expiredDate: now.add(const Duration(days: 30)),
      deviceCount: 5,
      createdAt: now,
    );

    final json = licence.toJson();
    expect(json['id'], 'lic-123');
    expect(json['user_id'], 'usr-456');
    expect(json['device_count'], 5);

    final restored = LicenceModel.fromJson(json);
    expect(restored.id, licence.id);
    expect(restored.userId, licence.userId);
    expect(restored.deviceCount, licence.deviceCount);
  });
}
