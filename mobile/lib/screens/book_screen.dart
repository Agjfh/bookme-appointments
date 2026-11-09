import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/provider_model.dart';
import '../providers/booking_provider.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.business, required this.service});

  final Business business;
  final ServiceItem service;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _days = List.generate(14, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + i);
  });
  late DateTime _date = _days.first;
  String? _time;
  List<String> _slots = [];
  bool _loadingSlots = true;
  bool _booking = false;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _time = null;
    });
    try {
      final slots = await context.read<BookingProvider>().slots(widget.business.id, widget.service.id, _date);
      if (mounted) setState(() => _slots = slots);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _booking = true);
    try {
      final appointment = await context
          .read<BookingProvider>()
          .book(widget.service, _date, _time!, notes: _notes.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text("You're booked!"),
          content: Text(
            '${widget.service.name} at ${widget.business.name}\n'
            '${DateFormat('EEEE, d MMMM · HH:mm').format(appointment.startsAt)}',
            textAlign: TextAlign.center,
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        showError(context, e);
        _loadSlots(); // The slot may have just been taken; refresh.
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${widget.business.name} · ${widget.service.durationMinutes} min · EGP ${widget.service.price.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final day = _days[i];
                final selected = DateUtils.isSameDay(day, _date);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    _date = day;
                    _loadSlots();
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(i == 0 ? 'Today' : DateFormat('EEE').format(day),
                          style: TextStyle(color: selected ? theme.colorScheme.onPrimary : null, fontSize: 12)),
                      Text('${day.day}',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: selected ? theme.colorScheme.onPrimary : null, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Available times', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _loadingSlots
                ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                : _slots.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No free times on this day. Try another date.')),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _slots)
                            ChoiceChip(
                              label: Text(s),
                              selected: _time == s,
                              onSelected: (_) => setState(() => _time = s),
                            ),
                        ],
                      ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes for the provider (optional)'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _time == null || _booking ? null : _confirm,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(_time == null
                ? 'Pick a time'
                : _booking
                    ? 'Booking...'
                    : 'Confirm ${DateFormat('EEE d MMM').format(_date)} at $_time'),
          ),
        ),
      ),
    );
  }
}
