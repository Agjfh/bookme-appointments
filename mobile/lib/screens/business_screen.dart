import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/provider_model.dart';
import '../providers/booking_provider.dart';
import 'book_screen.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, required this.businessId});

  final int businessId;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  late final Future<Business> _future = context.read<BookingProvider>().business(widget.businessId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FutureBuilder<Business>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(appBar: AppBar(), body: Center(child: Text(snap.error.toString())));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final b = snap.data!;
          return CustomScrollView(slivers: [
            SliverAppBar.large(
              title: Text(b.name),
              flexibleSpace: b.imageUrl == null
                  ? null
                  : FlexibleSpaceBar(
                      background: Image.network(b.imageUrl!, fit: BoxFit.cover,
                          color: Colors.black38, colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(children: [
                Row(children: [
                  Chip(label: Text(b.category)),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(' ${b.rating.toStringAsFixed(1)}'),
                ]),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(b.address),
                  subtitle: b.phone == null ? null : Text(b.phone!),
                ),
                if (b.about != null) Text(b.about!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
                Text('Services', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final s in b.services)
                  Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle: Text('${s.durationMinutes} min'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('EGP ${s.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => BookScreen(business: b, service: s))),
                          child: const Text('Book'),
                        ),
                      ]),
                    ),
                  ),
                const SizedBox(height: 20),
                Text('Opening hours', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(children: [
                    for (var weekday = 0; weekday < 7; weekday++) _hoursRow(context, b, weekday),
                  ]),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _hoursRow(BuildContext context, Business b, int weekday) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final hours = b.workingHours.where((h) => h.weekday == weekday);
    final isToday = DateTime.now().weekday % 7 == weekday;
    return ListTile(
      dense: true,
      title: Text(days[weekday], style: TextStyle(fontWeight: isToday ? FontWeight.bold : null)),
      trailing: Text(
        hours.isEmpty ? 'Closed' : '${hours.first.opensAt} – ${hours.first.closesAt}',
        style: TextStyle(color: hours.isEmpty ? Theme.of(context).colorScheme.error : null),
      ),
    );
  }
}
