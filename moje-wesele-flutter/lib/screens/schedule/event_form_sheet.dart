import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/schedule_event.dart';
import '../../services/schedule_service.dart';

/// Modalny formularz dodawania / edycji wydarzenia harmonogramu.
class EventFormSheet extends StatefulWidget {
  const EventFormSheet({super.key, this.existing});

  final ScheduleEvent? existing;

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _responsible;
  late final TextEditingController _locationUrl;

  late int _hour;
  late int _minute;
  late String _category;
  bool _private = false;
  bool _showLinkToGuests = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _responsible = TextEditingController(text: e?.responsible ?? '');
    _locationUrl = TextEditingController(text: e?.locationUrl ?? '');
    _hour = e?.hour ?? 12;
    _minute = e?.minute ?? 0;
    _category = e?.category ?? 'Inne';
    if (!SchedCategory.names.contains(_category)) _category = 'Inne';
    _private = e?.private ?? false;
    _showLinkToGuests = e?.showLinkToGuests ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    _responsible.dispose();
    _locationUrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ScheduleEventDraft(
        hour: _hour,
        minute: _minute,
        name: _name.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        responsible: _responsible.text.trim(),
        category: _category,
        private: _private,
        locationUrl: _locationUrl.text.trim(),
        showLinkToGuests: _showLinkToGuests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEEC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEdit ? 'Edytuj wydarzenie' : 'Dodaj wydarzenie',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        _field(
                          'Godzina',
                          InkWell(
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: _dec(),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule,
                                      size: 18, color: AppColors.textLight),
                                  const SizedBox(width: 10),
                                  Text(timeStr,
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _field(
                          'Nazwa *',
                          TextFormField(
                            controller: _name,
                            decoration: _dec(hint: 'np. Ceremonia ślubna'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Podaj nazwę'
                                : null,
                          ),
                        ),
                        _field(
                          'Opis',
                          TextField(
                            controller: _description,
                            maxLines: 2,
                            decoration: _dec(hint: 'Szczegóły…'),
                          ),
                        ),
                        _field(
                          'Miejsce',
                          TextField(
                            controller: _location,
                            decoration: _dec(hint: 'np. Sala weselna'),
                          ),
                        ),
                        _field(
                          'Osoba odpowiedzialna',
                          TextField(
                            controller: _responsible,
                            decoration: _dec(hint: 'np. Oboje'),
                          ),
                        ),
                        _field(
                          'Kategoria',
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration: _dec(),
                            items: [
                              for (final c in SchedCategory.all)
                                DropdownMenuItem(
                                  value: c.name,
                                  child: Text('${c.icon} ${c.name}'),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _category = v ?? _category),
                          ),
                        ),
                        _field(
                          'Link do lokalizacji',
                          TextField(
                            controller: _locationUrl,
                            keyboardType: TextInputType.url,
                            decoration: _dec(hint: 'https://maps…'),
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text('🔒 Prywatne (ukryte przed gośćmi)',
                              style: GoogleFonts.inter(fontSize: 14)),
                          value: _private,
                          onChanged: (v) => setState(() => _private = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text('👁 Pokaż link gościom',
                              style: GoogleFonts.inter(fontSize: 14)),
                          value: _showLinkToGuests,
                          onChanged: (v) =>
                              setState(() => _showLinkToGuests = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textLight,
                                  side: const BorderSide(
                                      color: Color(0xFFD7DEEC)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Anuluj'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(_isEdit ? 'Zapisz' : 'Dodaj'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          child,
        ],
      ),
    );
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
}
