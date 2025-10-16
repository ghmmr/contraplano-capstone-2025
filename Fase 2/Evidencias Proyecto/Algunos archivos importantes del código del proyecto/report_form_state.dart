// lib/features/reports/state/report_form_state.dart
import 'package:flutter/material.dart';

class ReportFormState {
  // ===== Form & flags =====
  final formKey = GlobalKey<FormState>();
  bool saving = false;
  bool submitted = false;

  // ===== Datos principales =====
  final nameCtrl = TextEditingController(text: 'Marialejandra Méndez');
  final titleCtrl = TextEditingController();
  String? block;
  List<String> blocks = [];

  // ===== Contraplano (obligatorios) =====
  final noticiaCtrl = TextEditingController();
  final podcastCtrl = TextEditingController();

  // ===== Newsletter (opcionales) =====
  final newsletterImgCtrl = TextEditingController();
  final newsletterDescCtrl = TextEditingController();

  // ===== Redes / SEO (opcionales) =====
  final youtubeCtrl = TextEditingController();
  final linkedinCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final instagramCtrl = TextEditingController();
  final igStoryCtrl = TextEditingController();
  final tiktok1Ctrl = TextEditingController();
  final tiktok2Ctrl = TextEditingController();
  final xCtrl = TextEditingController();

  // ===== SEO imagenes (Base64) =====
  String? seoPodcastB64;
  String? seoNoticiaB64;

  // Helper: string -> null si viene vacía
  String? orNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

  void dispose() {
    for (final c in [
      nameCtrl,
      titleCtrl,
      noticiaCtrl,
      podcastCtrl,
      newsletterImgCtrl,
      newsletterDescCtrl,
      youtubeCtrl,
      linkedinCtrl,
      facebookCtrl,
      instagramCtrl,
      igStoryCtrl,
      tiktok1Ctrl,
      tiktok2Ctrl,
      xCtrl,
    ]) {
      c.dispose();
    }
  }
}
