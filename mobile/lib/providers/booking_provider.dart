import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import '../models/provider_model.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider(this.api);

  final ApiClient api;
  List<String> categories = [];
  List<Appointment> upcoming = [];
  List<Appointment> past = [];

  Future<void> loadCategories() async {
    categories = ((await api.get('/categories')) as List).cast<String>();
    notifyListeners();
  }

  Future<List<Business>> businesses({String? query, String? category}) async {
    final data = await api.get('/providers', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (category != null) 'category': category,
    }) as Map<String, dynamic>;
    return (data['data'] as List).map((b) => Business.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<Business> business(int id) async =>
      Business.fromJson(await api.get('/providers/$id') as Map<String, dynamic>);

  Future<List<String>> slots(int providerId, int serviceId, DateTime date) async {
    final data = await api.get('/providers/$providerId/slots', query: {
      'service_id': serviceId,
      'date': DateFormat('yyyy-MM-dd').format(date),
    }) as Map<String, dynamic>;
    return (data['slots'] as List).cast<String>();
  }

  Future<Appointment> book(ServiceItem service, DateTime date, String time, {String? notes}) async {
    final data = await api.post('/appointments', {
      'service_id': service.id,
      'starts_at': '${DateFormat('yyyy-MM-dd').format(date)} $time',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }) as Map<String, dynamic>;
    final appointment = Appointment.fromJson(data);
    upcoming = [...upcoming, appointment]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    notifyListeners();
    return appointment;
  }

  Future<void> loadAppointments() async {
    final results = await Future.wait([
      api.get('/appointments', query: {'scope': 'upcoming'}),
      api.get('/appointments', query: {'scope': 'past'}),
    ]);
    List<Appointment> parse(dynamic d) => ((d as Map<String, dynamic>)['data'] as List)
        .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
        .toList();
    upcoming = parse(results[0]);
    past = parse(results[1]);
    notifyListeners();
  }

  Future<void> cancel(Appointment appointment) async {
    await api.post('/appointments/${appointment.id}/cancel');
    await loadAppointments();
  }
}
