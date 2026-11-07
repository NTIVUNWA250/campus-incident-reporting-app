import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/errors.dart';
import '../core/photo_data.dart';
import '../core/validation.dart';
import '../data/incident_repository.dart';
import '../models/incident.dart';
import '../state/incident_controller.dart';
import '../state/session_controller.dart';
import '../widgets/common.dart';

class IncidentFormScreen extends StatefulWidget {
  const IncidentFormScreen({this.incident, super.key});
  final Incident? incident;
  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _description, _location;
  IncidentCategory _category = IncidentCategory.facilities;
  Uint8List? _photo;
  bool _busy = false, _picking = false;
  final _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    final incident = widget.incident;
    _title = TextEditingController(text: incident?.title);
    _description = TextEditingController(text: incident?.description);
    _location = TextEditingController(text: incident?.location);
    _category = incident?.category ?? _category;
    if (incident == null) _recoverPhoto();
  }

  Future<void> _recoverPhoto() async {
    try {
      final recovered = await _picker.retrieveLostData();
      if (recovered.files?.isNotEmpty ?? false) {
        await _readPhoto(recovered.files!.first);
      }
    } catch (_) {
      /* A fresh picker is still available if recovery is unsupported. */
    }
  }

  Future<void> _readPhoto(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw StateError('Choose a photo smaller than 5 MB.');
    }
    final bytes = await file.readAsBytes();
    photoContentType(bytes);
    if (mounted) setState(() => _photo = bytes);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (file != null) await _readPhoto(file);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final repository = context.read<IncidentController>().repository;
    final session = context.read<SessionController>();
    final draft = IncidentDraft(
      title: _title.text,
      description: _description.text,
      location: _location.text,
      category: _category,
    );
    try {
      String? warning;
      if (widget.incident == null) {
        warning = await repository.create(
          draft,
          session.user!.uid,
          session.name,
          _photo,
        );
      } else {
        await repository.edit(widget.incident!, draft);
        if (_photo != null) {
          try {
            await repository.attach(widget.incident!, _photo!);
          } catch (_) {
            warning =
                'Report changes saved, but the photo could not be attached. Please edit and retry.';
          }
        }
      }
      if (!mounted) return;
      showMessage(
        context,
        warning ??
            (widget.incident == null
                ? 'Report submitted. Thank you for helping your campus.'
                : 'Report updated.'),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.incident == null ? 'Report an incident' : 'Edit report',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Select a category',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: IncidentCategory.values
                      .map(
                        (category) => SizedBox(
                          width: (constraints.maxWidth - 16) / 3,
                          child: Semantics(
                            selected: _category == category,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _category = category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _category == category
                                      ? brand
                                      : const Color(0xFFF0EEFA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      categoryIcon(category.name),
                                      color: _category == category
                                          ? Colors.white
                                          : brand,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      category.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _category == category
                                            ? Colors.white
                                            : ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('incident-title'),
                controller: _title,
                enabled: !_busy,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Briefly describe the issue',
                ),
                validator: (v) => Validation.text(v, 'Title', 5, 100),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('incident-description'),
                controller: _description,
                enabled: !_busy,
                maxLength: 2000,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What happened, when, and who is affected?',
                ),
                validator: (v) => Validation.text(v, 'Description', 20, 2000),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('incident-location'),
                controller: _location,
                enabled: !_busy,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Block B - Room 204',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => Validation.text(v, 'Location', 3, 120),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add a photo (optional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'JPEG or PNG, up to 5 MB. Avoid faces and personal details.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (_photo != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _photo!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filled(
                        tooltip: 'Remove selected photo',
                        onPressed: _busy
                            ? null
                            : () => setState(() => _photo = null),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                )
              else if (widget.incident?.photoPath.isNotEmpty ?? false)
                const ListTile(
                  leading: Icon(Icons.image_outlined),
                  title: Text('Existing photo attached'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _busy || _picking ? null : _pickPhoto,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 90),
                    side: const BorderSide(color: Color(0xFFDAD9F0)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _picking ? 'Opening photo picker...' : 'Tap to add a photo',
                  ),
                ),
              const SizedBox(height: 24),
              BusyButton(
                label: widget.incident == null
                    ? 'Submit report'
                    : 'Save changes',
                busy: _busy,
                onPressed: _picking ? null : _submit,
              ),
              const SizedBox(height: 12),
              const Text(
                'Reports can be edited or deleted until staff start working on them.',
                style: TextStyle(fontSize: 12, color: muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
