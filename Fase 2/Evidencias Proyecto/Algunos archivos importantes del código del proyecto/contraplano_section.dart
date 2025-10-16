import 'package:flutter/material.dart';
import 'package:mrc_contraplano/features/reports/state/report_form_state.dart';
import 'package:mrc_contraplano/features/reports/widgets/seo_input.dart';
import 'package:mrc_contraplano/utils/validators.dart';

class ContraplanoSection extends StatelessWidget {
  final ReportFormState s;
  final AutovalidateMode auto;

  const ContraplanoSection({
    super.key,
    required this.s,
    required this.auto,
  });

  Widget _twoCols(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _twoCols(
          // Noticia (host contraplano.cl)
          TextFormField(
            key: const ValueKey('noticiaUrlField'),
            controller: s.noticiaCtrl,
            validator: (v) => requiredHttpsHost(v, 'contraplano.cl', label: 'Noticia'),
            autovalidateMode: auto,
            decoration: const InputDecoration(
              labelText: 'Link Noticia Contraplano',
              prefixIcon: Icon(Icons.article),
            ),
          ),
          // Podcast (host radiocontraplano.cl)
          TextFormField(
            key: const ValueKey('podcastUrlField'),
            controller: s.podcastCtrl,
            validator: (v) => requiredHttpsHost(v, 'radiocontraplano.cl', label: 'Podcast'),
            autovalidateMode: auto,
            decoration: const InputDecoration(
              labelText: 'Link Podcast Contraplano',
              prefixIcon: Icon(Icons.podcasts),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _twoCols(
          // URL imagen newsletter
          TextFormField(
            key: const ValueKey('newsletterImgField'),
            controller: s.newsletterImgCtrl,
            validator: requiredImageUrl,
            autovalidateMode: auto,
            decoration: const InputDecoration(
              labelText: 'URL de la Imagen para Newletter',
              prefixIcon: Icon(Icons.image),
            ),
          ),
          // Descripción newsletter
          TextFormField(
            key: const ValueKey('newsletterDescField'),
            controller: s.newsletterDescCtrl,
            validator: requiredField,
            autovalidateMode: auto,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción para Newletter',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _twoCols(
          // SEO Podcast (b64)
          SeoInput(
            label: 'SEO Podcast',
            onBytesChanged: (b64) => s.seoPodcastB64 = b64,
          ),
          // SEO Noticia (b64)
          SeoInput(
            label: 'SEO Noticia Contraplano',
            onBytesChanged: (b64) => s.seoNoticiaB64 = b64,
          ),
        ),
      ],
    );
  }
}
