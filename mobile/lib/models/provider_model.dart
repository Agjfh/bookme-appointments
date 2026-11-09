class ServiceItem {
  ServiceItem({required this.id, required this.name, required this.durationMinutes, required this.price});

  final int id;
  final String name;
  final int durationMinutes;
  final double price;

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as int,
        name: json['name'] as String,
        durationMinutes: json['duration_minutes'] as int,
        price: (json['price'] as num).toDouble(),
      );
}

class WorkingDay {
  WorkingDay({required this.weekday, required this.day, required this.opensAt, required this.closesAt});

  final int weekday;
  final String day;
  final String opensAt;
  final String closesAt;

  factory WorkingDay.fromJson(Map<String, dynamic> json) => WorkingDay(
        weekday: json['weekday'] as int,
        day: json['day'] as String,
        opensAt: json['opens_at'] as String,
        closesAt: json['closes_at'] as String,
      );
}

class Business {
  Business({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.rating,
    this.about,
    this.phone,
    this.imageUrl,
    this.startingPrice,
    this.services = const [],
    this.workingHours = const [],
  });

  final int id;
  final String name;
  final String category;
  final String? about;
  final String address;
  final String city;
  final String? phone;
  final String? imageUrl;
  final double rating;
  final double? startingPrice;
  final List<ServiceItem> services;
  final List<WorkingDay> workingHours;

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        about: json['about'] as String?,
        address: json['address'] as String,
        city: json['city'] as String,
        phone: json['phone'] as String?,
        imageUrl: json['image_url'] as String?,
        rating: (json['rating'] as num).toDouble(),
        startingPrice: (json['starting_price'] as num?)?.toDouble(),
        services: (json['services'] as List? ?? [])
            .map((s) => ServiceItem.fromJson(s as Map<String, dynamic>))
            .toList(),
        workingHours: (json['working_hours'] as List? ?? [])
            .map((h) => WorkingDay.fromJson(h as Map<String, dynamic>))
            .toList(),
      );
}

class Appointment {
  Appointment({
    required this.id,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.canCancel,
    required this.business,
    required this.service,
    this.notes,
  });

  final int id;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final double price;
  final bool canCancel;
  final String? notes;
  final Business business;
  final ServiceItem service;

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int,
        status: json['status'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        price: (json['price'] as num).toDouble(),
        canCancel: json['can_cancel'] as bool,
        notes: json['notes'] as String?,
        business: Business.fromJson(json['provider'] as Map<String, dynamic>),
        service: ServiceItem.fromJson(json['service'] as Map<String, dynamic>),
      );
}
