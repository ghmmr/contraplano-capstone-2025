// lib/features/reports/state/report_form_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mrc_contraplano/features/reports/state/report_form_state.dart';
import 'package:mrc_contraplano/services/report_service.dart';
import 'package:mrc_contraplano/utils/formatter.dart';
import 'package:mrc_contraplano/utils/html_report.dart';
import 'package:mrc_contraplano/utils/web_download.dart';
import 'package:mrc_contraplano/utils/report_plaintext.dart';

class ReportFormController {
  final ReportFormState s;
  final ReportService _service;

  ReportFormController(this.s, {ReportService? service})
      : _service = service ?? ReportService();

  // -- Helper SnackBar flotante (se ve sobre diálogos)
  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<List<String>> loadBlocks() async {
    final snap = await FirebaseFirestore.instance
        .collection('config')
        .doc('categories')
        .get();
    if (!snap.exists) return <String>[];
    final data = snap.data();
    final list = List<String>.from(data?['list'] ?? []);
    return list;
  }

  Future<void> submit(BuildContext context) async {
    // Defensa en profundidad: validación de Form (por si la UI no lo corrió)
    s.submitted = true;
    final ok = s.formKey.currentState?.validate() ?? false;
    if (!ok) {
      _showSnack(context, 'Revisa los campos en rojo.');
      return;
    }

    // Guardas explícitas: si algo crítico está vacío, aborta.
    final missing = <String>[];
    if (s.nameCtrl.text.trim().isEmpty) missing.add('Nombre');
    if (s.titleCtrl.text.trim().isEmpty) missing.add('Título de la noticia');
    if (s.block == null || s.block!.trim().isEmpty) missing.add('Bloque');

    if (missing.isNotEmpty) {
      _showSnack(context, 'Completa: ${missing.join(', ')}');
      return;
    }

    s.saving = true;
    try {
      final links = <String, String?>{
        'noticia': s.orNull(s.noticiaCtrl.text),
        'podcast': s.orNull(s.podcastCtrl.text),
        'newsletter_img': s.orNull(s.newsletterImgCtrl.text),
        'seo_podcast_b64': s.seoPodcastB64,
        'seo_noticia_b64': s.seoNoticiaB64,
        'youtube': s.orNull(s.youtubeCtrl.text),
        'linkedin': s.orNull(s.linkedinCtrl.text),
        'facebook': s.orNull(s.facebookCtrl.text),
        'instagram': s.orNull(s.instagramCtrl.text),
        'instagram_story': s.orNull(s.igStoryCtrl.text),
        'tiktok1': s.orNull(s.tiktok1Ctrl.text),
        'tiktok2': s.orNull(s.tiktok2Ctrl.text),
        'x': s.orNull(s.xCtrl.text),
      };

      // Llamada con deduplicación (RB2) + manejo de errores amigable
      try {
        await _service.createReportDedup(
          title: s.titleCtrl.text.trim(),
          block: s.block!.trim(),
          links: links,
          newsletterDesc: s.orNull(s.newsletterDescCtrl.text),
          createdByName: s.nameCtrl.text.trim(),
          // P7 (WP): source: 'wp', wpUserId: ..., wpDisplayName: ...
        );
      } on DuplicateReportException {
        _showSnack(context, 'La URL ya fue reportada (hash coincidente).');
        return;
      } on FirebaseException catch (fe) {
        final friendly = switch (fe.code) {
          'permission-denied' => 'No tienes permisos para generar reportes.',
          'unavailable'       => 'Servicio no disponible momentáneamente. Intenta de nuevo.',
          _                   => 'Error de servidor: ${fe.message ?? fe.code}',
        };
        _showSnack(context, friendly);
        return;
      } catch (_) {
        _showSnack(
          context,
          'Error inesperado al guardar, porque está intentando generar un reporte duplicado, '
          'que ya se encuentra almacenado en la base de datos ContraPlano',
        );
        return;
      }

      // Copiar al portapapeles con el formato actual (texto plano del clipboard clásico)
      final txt = formatReportClipboard(
        date: DateTime.now(),
        block: s.block!.trim(),
        name: s.nameCtrl.text.trim(),
        title: s.titleCtrl.text.trim(),
        noticia: s.noticiaCtrl.text.trim(),
        podcast: s.podcastCtrl.text.trim(),
        youtube: s.youtubeCtrl.text.trim(),
        linkedin: s.linkedinCtrl.text.trim(),
        facebook: s.facebookCtrl.text.trim(),
        instagram: s.instagramCtrl.text.trim(),
        instagramStory: s.igStoryCtrl.text.trim(),
        tiktok1: s.tiktok1Ctrl.text.trim(),
        tiktok2: s.tiktok2Ctrl.text.trim(),
        x: s.xCtrl.text.trim(),
        newsletterImageUrl: s.newsletterImgCtrl.text.trim(),
        newsletterDesc: s.newsletterDescCtrl.text.trim(),
      );
      await Clipboard.setData(ClipboardData(text: txt));
      _showSnack(context, 'Reporte guardado y copiado al portapapeles');
    } finally {
      s.saving = false;
    }
  }

  // ===== P4: Vista previa / descarga =====
  // Helper: retorna trim o '' si es null
  String _t(String? v) => (v ?? '').trim();

  String _buildHtml() => buildReportHtml(
        date: DateTime.now(),
        block: _t(s.block),
        name: _t(s.nameCtrl.text),
        title: _t(s.titleCtrl.text),
        noticia: _t(s.noticiaCtrl.text),
        podcast: _t(s.podcastCtrl.text),
        youtube: _t(s.youtubeCtrl.text),
        linkedin: _t(s.linkedinCtrl.text),
        facebook: _t(s.facebookCtrl.text),
        instagram: _t(s.instagramCtrl.text),
        instagramStory: _t(s.igStoryCtrl.text),
        tiktok1: _t(s.tiktok1Ctrl.text),
        tiktok2: _t(s.tiktok2Ctrl.text),
        x: _t(s.xCtrl.text),
        newsletterImageUrl: _t(s.newsletterImgCtrl.text),
        newsletterDesc: _t(s.newsletterDescCtrl.text),
      );

  String _buildPlain() => buildReportPlainText(
        date: DateTime.now(),
        block: _t(s.block),
        name: _t(s.nameCtrl.text),
        title: _t(s.titleCtrl.text),
        noticia: _t(s.noticiaCtrl.text),
        podcast: _t(s.podcastCtrl.text),
        youtube: _t(s.youtubeCtrl.text),
        linkedin: _t(s.linkedinCtrl.text),
        facebook: _t(s.facebookCtrl.text),
        instagram: _t(s.instagramCtrl.text),
        instagramStory: _t(s.igStoryCtrl.text),
        tiktok1: _t(s.tiktok1Ctrl.text),
        tiktok2: _t(s.tiktok2Ctrl.text),
        x: _t(s.xCtrl.text),
        newsletterImageUrl: _t(s.newsletterImgCtrl.text),
        newsletterDesc: _t(s.newsletterDescCtrl.text),
      );

  // API que usa la página
  String buildPreviewHtml() => _buildHtml();

  // NUEVO: exponer también el texto plano para la vista previa
  String buildPreviewPlain() => _buildPlain();

  Future<void> copyPreviewHtml() async =>
      Clipboard.setData(ClipboardData(text: _buildHtml()));

  Future<void> copyPreviewPlain() async =>
      Clipboard.setData(ClipboardData(text: _buildPlain()));

  void downloadPreviewTxt() {
    // Para el .txt ahora usamos el TEXTO PLANO (no HTML) como acordamos
    downloadTextFileWeb('reporte_mrc.txt', _buildPlain());
  }

}
