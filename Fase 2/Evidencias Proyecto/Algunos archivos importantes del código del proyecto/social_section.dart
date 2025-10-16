import 'package:flutter/material.dart';
import 'package:mrc_contraplano/features/reports/state/report_form_state.dart';
import 'package:mrc_contraplano/features/reports/widgets/social_url_row.dart';
import 'package:mrc_contraplano/utils/validators.dart';

class SocialSection extends StatelessWidget {
  final ReportFormState s;
  final AutovalidateMode auto;

  const SocialSection({
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
    final widgets = <Widget>[
      SocialUrlRow(
        key: const ValueKey('linkedinRow'),
        iconAsset: 'assets/icons/linkedin.png',
        label: 'LinkedIn',
        controller: s.linkedinCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHost(v, 'www.linkedin.com', label: 'LinkedIn'),
      ),
      SocialUrlRow(
        key: const ValueKey('facebookRow'),
        iconAsset: 'assets/icons/facebook.png',
        label: 'Facebook',
        controller: s.facebookCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHost(v, 'www.facebook.com', label: 'Facebook'),
      ),
      SocialUrlRow(
        key: const ValueKey('xRow'),
        iconAsset: 'assets/icons/x.png',
        label: 'Link X',
        controller: s.xCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalXWithAccount(v, 'contraplanotv'),
      ),
      SocialUrlRow(
        key: const ValueKey('igStoryRow'),
        iconAsset: 'assets/icons/instagram.png',
        label: 'Instagram Story',
        controller: s.igStoryCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHostAndPathContainsAll(
          v,
          hostSuffixes: ['instagram.com'],
          pathKeywords: ['stories'],
          label: 'Instagram Story',
        ),
      ),
      SocialUrlRow(
        key: const ValueKey('instagramRow'),
        iconAsset: 'assets/icons/instagram.png',
        label: 'Instagram',
        controller: s.instagramCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHostAndPathContainsAny(
          v,
          hostSuffixes: ['instagram.com', 'www.instagram.com', 'm.instagram.com'],
          anyPathKeywords: ['reel', '/p/'],
          label: 'Instagram',
        ),
      ),
      SocialUrlRow(
        key: const ValueKey('tiktok1Row'),
        iconAsset: 'assets/icons/tiktok.png',
        label: 'Tiktok 1: Contraplano_',
        controller: s.tiktok1Ctrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHostAndPathContainsAll(
          v,
          hostSuffixes: ['tiktok.com', 'www.tiktok.com'],
          pathKeywords: ['@contraplano_'],
          label: 'TikTok',
        ),
      ),
      SocialUrlRow(
        key: const ValueKey('tiktok2Row'),
        iconAsset: 'assets/icons/tiktok.png',
        label: 'Tiktok 2: prensacontraplano@gmail.com',
        controller: s.tiktok2Ctrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHostAndPathContainsAll(
          v,
          hostSuffixes: ['tiktok.com', 'www.tiktok.com'],
          pathKeywords: ['@contraplanotv'],
          label: 'TikTok',
        ),
      ),
      SocialUrlRow(
        key: const ValueKey('youtubeRow'),
        iconAsset: 'assets/icons/youtube.png',
        label: 'YouTube',
        controller: s.youtubeCtrl,
        autovalidateMode: auto,
        validator: (v) => optionalHttpsHost(v, 'youtu.be', label: 'YouTube'),
      ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < widgets.length; i += 2) {
      final left = widgets[i];
      final right = (i + 1 < widgets.length) ? widgets[i + 1] : const SizedBox.shrink();
      rows.add(_twoCols(left, right));
      if (i + 2 < widgets.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}
