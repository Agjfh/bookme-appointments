import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/provider_model.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'business_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _category;
  List<Business> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    context.read<BookingProvider>().loadCategories().catchError((_) {});
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<BookingProvider>().businesses(query: _search.text.trim(), category: _category);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<BookingProvider>().categories;
    final name = context.watch<AuthProvider>().user?.name.split(' ').first ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $name 👋'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Book your next appointment',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _load);
              },
              decoration: const InputDecoration(
                hintText: 'Search clinics, salons, services...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(label: const Text('All'), selected: _category == null, onSelected: (_) {
                _category = null;
                _load();
              }),
              for (final c in categories)
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) {
                  _category = c;
                  _load();
                }),
            ]),
            const SizedBox(height: 16),
            if (_loading && _items.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_error != null && _items.isEmpty)
              Center(child: Text(_error!))
            else if (_items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Nothing found.')))
            else
              for (final b in _items) _BusinessCard(business: b),
          ],
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => BusinessScreen(businessId: business.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (business.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(business.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest)),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(business.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${business.category} · ${business.address}', style: theme.textTheme.bodySmall),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(business.rating.toStringAsFixed(1)),
                ]),
                if (business.startingPrice != null)
                  Text('from EGP ${business.startingPrice!.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
