import 'package:flutter_test/flutter_test.dart';
import 'package:bookme/models/provider_model.dart';

void main() {
  test('Business parses services and starting price', () {
    final b = Business.fromJson({
      'id': 1,
      'name': 'Smile Dental Clinic',
      'category': 'Dental',
      'address': 'Nasr City, Cairo',
      'city': 'Cairo',
      'rating': 4.8,
      'starting_price': 300,
      'services': [
        {'id': 1, 'name': 'Check-up', 'duration_minutes': 30, 'price': 300},
      ],
    });

    expect(b.services.single.durationMinutes, 30);
    expect(b.startingPrice, 300.0);
  });
}
