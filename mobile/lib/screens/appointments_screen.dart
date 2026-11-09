import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/provider_model.dart';
import '../providers/booking_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await context.read<BookingProvider>().loadAppointments();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('${a.service.name} at ${a.business.name} will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel it')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<BookingProvider>().cancel(a);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My appointments'),
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'History')]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_list(p.upcoming, upcoming: true), _list(p.past)]),
      ),
    );
  }

  Widget _list(List<Appointment> items, {bool upcoming = false}) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: items.isEmpty
          ? ListView(children: [
              const SizedBox(height: 140),
              Center(child: Text(upcoming ? 'No upcoming appointments.' : 'Nothing here yet.')),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) => _AppointmentCard(
                appointment: items[i],
                onCancel: items[i].canCancel ? () => _cancel(items[i]) : null,
              ),
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, this.onCancel});

  final Appointment appointment;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final statusColor = switch (a.status) {
      'confirmed' => Colors.green,
      'completed' => theme.colorScheme.primary,
      _ => theme.colorScheme.error,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(DateFormat('MMM').format(a.startsAt).toUpperCase(), style: theme.textTheme.labelSmall),
              Text('${a.startsAt.day}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.service.name, style: theme.textTheme.titleSmall),
              Text(a.business.name, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('EEE · HH:mm').format(a.startsAt)} – ${DateFormat('HH:mm').format(a.endsAt)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(a.status.replaceAll('_', ' ').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
            ]),
          ),
          if (onCancel != null) TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ]),
      ),
    );
  }
}
