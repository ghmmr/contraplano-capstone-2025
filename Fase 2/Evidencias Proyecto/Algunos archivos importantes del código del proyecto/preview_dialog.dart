import 'package:flutter/material.dart';
import 'package:mrc_contraplano/features/reports/state/report_form_controller.dart';

enum _PreviewMode { html, text }

class PreviewDialog extends StatefulWidget {
  const PreviewDialog({super.key, required this.controller});
  final ReportFormController controller;

  @override
  State<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PreviewDialog> {
  final _scrollCtrl = ScrollController();
  _PreviewMode _mode = _PreviewMode.html;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final htmlText  = widget.controller.buildPreviewHtml();
    final plainText = widget.controller.buildPreviewPlain();
    final current   = _mode == _PreviewMode.html ? htmlText : plainText;

    // NOTA: ScaffoldMessenger + Scaffold DENTRO del diálogo
    // para que el SnackBar se muestre por encima (y no detrás).
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFE9EEE7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header con título + botón X
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vista previa',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Selector de vista: HTML | Texto
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<_PreviewMode>(
                      segments: const [
                        ButtonSegment(value: _PreviewMode.html, label: Text('HTML')),
                        ButtonSegment(value: _PreviewMode.text, label: Text('Texto')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) => setState(() => _mode = s.first),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Área scrollable con Scrollbar + SelectableText
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      elevation: 0,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Scrollbar(
                          controller: _scrollCtrl,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            child: SelectableText(
                              current,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.0,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botonera (sin "Generar" para evitar redundancia)
                  LayoutBuilder(
                    builder: (context, c) {
                      Future<void> _ok(String msg) async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }

                      final buttons = [
                        OutlinedButton(
                          onPressed: () async {
                            await widget.controller.copyPreviewHtml();
                            await _ok('HTML copiado al portapapeles.');
                          },
                          child: const Text('Copiar HTML'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await widget.controller.copyPreviewPlain();
                            await _ok('Texto copiado al portapapeles.');
                          },
                          child: const Text('Copiar Texto'),
                        ),
                        OutlinedButton(
                          onPressed: () => widget.controller.downloadPreviewTxt(),
                          child: const Text('Descargar .txt'),
                        ),
                      ];

                      if (c.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              runSpacing: 8, spacing: 8,
                              children: buttons.map((b) => SizedBox(width: double.infinity, child: b)).toList(),
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: buttons
                            .map((b) => Padding(padding: const EdgeInsets.only(right: 8), child: b))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
