import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/data/report_draft_store.dart';

class DraftReminderCard extends StatefulWidget {
  const DraftReminderCard({
    super.key,
    required this.store,
    required this.pending,
  });

  final ReportDraftStore store;
  final List<ReportDraft> pending;

  @override
  State<DraftReminderCard> createState() => _DraftReminderCardState();
}

class _DraftReminderCardState extends State<DraftReminderCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  ReportDraft? _draft;
  DateTime? _dueAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _read();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _read();
  }

  @override
  void didUpdateWidget(covariant DraftReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.pending != widget.pending) {
      _read();
    }
  }

  Future<void> _read() async {
    final store = widget.store;
    try {
      final draft = await store.readDraft();
      final drafts = [?draft, ...widget.pending];
      final reminder = await store.readReminder();
      if (!mounted || widget.store != store) return;
      final scheduled = drafts
          .where((item) => item.idempotencyKey == reminder?.draftId)
          .firstOrNull;
      final date = scheduled == null ? null : reminder?.dueAt;
      _timer?.cancel();
      setState(() {
        _draft = scheduled ?? drafts.firstOrNull;
        _dueAt = date;
      });
      if (date != null) {
        final remaining = date.difference(DateTime.now());
        _timer = Timer(
          remaining.isNegative ? Duration.zero : remaining,
          _notify,
        );
      }
    } on Exception {
      if (mounted) setState(() => _dueAt = null);
    }
  }

  Future<void> _notify() async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final store = widget.store;
    final dueAt = _dueAt;
    if (dueAt == null || _busy) return;
    try {
      final delivered = await store.acknowledgeReminder(dueAt);
      if (!mounted || widget.store != store || delivered == null) return;
      setState(() => _dueAt = null);
      if (delivered) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tienes un reporte pendiente por enviar.'),
        ),
      );
    } on Exception {
      if (mounted) _showFailure();
    }
  }

  void _showFailure() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('No se pudo actualizar el recordatorio.')),
  );

  Future<void> _change(Duration? delay) async {
    final draft = _draft;
    if (_busy || draft == null) return;
    setState(() => _busy = true);
    try {
      if (delay == null) {
        await widget.store.cancelReminder();
      } else {
        await widget.store.scheduleReminder(draft, DateTime.now().add(delay));
      }
      if (mounted) await _read();
    } on Exception {
      if (mounted) _showFailure();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) return const SizedBox.shrink();
    final time = _dueAt;
    final locale = MaterialLocalizations.of(context);
    return Card(
      child: ListTile(
        title: const Text('Recordatorio de reporte'),
        subtitle: Text(
          time == null
              ? 'Programa un aviso para retomar el borrador'
              : '${locale.formatShortDate(time)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(time))}',
        ),
        trailing: PopupMenuButton<String>(
          enabled: !_busy,
          tooltip: 'Programar recordatorio',
          onSelected: (option) => _change(switch (option) {
            '15' => const Duration(minutes: 15),
            '60' => const Duration(hours: 1),
            '1440' => const Duration(days: 1),
            _ => null,
          }),
          itemBuilder: (context) => [
            const PopupMenuItem(value: '15', child: Text('En 15 minutos')),
            const PopupMenuItem(value: '60', child: Text('En una hora')),
            const PopupMenuItem(value: '1440', child: Text('Mañana')),
            if (time != null)
              const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
          ],
        ),
      ),
    );
  }
}
