import 'package:flutter/material.dart';

import 'package:mrc_contraplano/features/reports/widgets/section_card.dart';
import 'package:mrc_contraplano/utils/validators.dart';

import 'package:mrc_contraplano/features/reports/state/report_form_state.dart';
import 'package:mrc_contraplano/features/reports/state/report_form_controller.dart';

// Secciones
import 'package:mrc_contraplano/features/reports/ui/sections/identity_section.dart';
import 'package:mrc_contraplano/features/reports/ui/sections/contraplano_section.dart';
import 'package:mrc_contraplano/features/reports/ui/sections/social_section.dart';

// Diálogo de vista previa
import 'package:mrc_contraplano/features/reports/ui/dialogs/preview_dialog.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});
  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  late final ReportFormState _s;
  late final ReportFormController _c;

  @override
  void initState() {
    super.initState();
    _s = ReportFormState();
    _c = ReportFormController(_s);
    _loadBlocksFromController();
  }

  Future<void> _loadBlocksFromController() async {
    try {
      final list = await _c.loadBlocks();
      if (!mounted) return;
      setState(() => _s.blocks = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando bloques: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _s.submitted = true);
    final ok = _s.formKey.currentState?.validate() ?? false;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos en rojo.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _s.saving = true);
    try {
      await _c.submit(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _s.saving = false);
    }
  }

  bool _canPreview() {
    setState(() => _s.submitted = true);
    final ok = _s.formKey.currentState?.validate() ?? false;

    final missing = <String>[];
    if (_s.nameCtrl.text.trim().isEmpty) missing.add('Nombre');
    if (_s.titleCtrl.text.trim().isEmpty) missing.add('Título de la noticia');
    if (_s.block == null || _s.block!.trim().isEmpty) missing.add('Bloque');

    if (!ok || missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa los campos en rojo.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return false;
    }
    return true;
  }

  AutovalidateMode get _auto =>
      _s.submitted ? AutovalidateMode.always : AutovalidateMode.onUserInteraction;

  Widget _header() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/branding/logo.png', height: 40),
                const SizedBox(width: 12),
                const Text(
                  'Generar Reporte',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/reports'),
            icon: const Icon(Icons.list_alt),
            label: const Text('Ver reportes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.all(16.0);
    const brandGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: brandGreen,
      appBar: AppBar(backgroundColor: brandGreen, elevation: 0, toolbarHeight: 8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: pad,
              child: Material(
                elevation: 0,
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: AbsorbPointer(
                    absorbing: _s.saving,
                    child: Opacity(
                      opacity: _s.saving ? 0.6 : 1,
                      child: Form(
                        key: _s.formKey,
                        child: ListView(
                          children: [
                            _header(),
                            const SizedBox(height: 4),
                            IdentitySection(
                              s: _s,
                              auto: _auto,
                              onBlockChanged: (v) => setState(() => _s.block = v),
                            ),
                            SectionCard(
                              title: 'Contraplano',
                              child: ContraplanoSection(s: _s, auto: _auto),
                            ),
                            SectionCard(
                              title: 'Redes Sociales',
                              child: SocialSection(s: _s, auto: _auto),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: OutlinedButton(
                                    onPressed: _s.saving
                                        ? null
                                        : () async {
                                            if (!_canPreview()) return;
                                            await showDialog<void>(
                                              context: context,
                                              useRootNavigator: true,
                                              barrierDismissible: false,
                                              builder: (_) => PreviewDialog(controller: _c),
                                            );
                                          },
                                    child: const Text('Vista previa'),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 360),
                                  child: ElevatedButton(
                                    onPressed: _s.saving ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandGreen,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(180, 48),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: _s.saving
                                        ? const SizedBox(
                                            height: 22, width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                          )
                                        : const Text('Generar reporte'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
