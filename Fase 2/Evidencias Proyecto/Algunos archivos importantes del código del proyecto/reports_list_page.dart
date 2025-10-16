import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../reports/data/report_repository.dart';
import '../../reports/state/reports_list_controller.dart';
import '../../reports/models/report.dart';

import 'dialogs/report_preview_dialog.dart';
import '../utils/web_download.dart';
import '../../../utils/image_url.dart';

class ReportsListPage extends StatelessWidget {
  const ReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ReportsListController(ReportRepository(FirebaseFirestore.instance))
            ..refresh(),
      child: const _ReportsScaffold(),
    );
  }
}

class _ReportsScaffold extends StatelessWidget {
  const _ReportsScaffold();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReportsListController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // mínimos “suaves”
          const minW = 720.0;
          const minH = 520.0;

          // ancho panel izquierdo y separaciones
          const sideW = 260.0;
          const gap = 12.0;

          // Lienzo con tamaño FINITO siempre (clave para que Stack no falle)
          final canvasW = constraints.maxWidth  < minW ? minW : constraints.maxWidth;
          final canvasH = constraints.maxHeight < minH ? minH : constraints.maxHeight;

          // ==== contenido principal (requiere tamaño finito)
          final content = SizedBox(
            width: canvasW,
            height: canvasH,
            child: Stack(
              children: [
                // ====== COLUMNA IZQUIERDA (filtros) – fija ======
                Positioned.fill(
                  left: 12,
                  right: null,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: sideW),
                      child: const _LeftFiltersPanel(width: sideW),
                    ),
                  ),
                ),

                // ====== CONTENIDO (barra superior fija + lista + pie)
                Positioned.fill(
                  left: 12 + sideW + gap,
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      _StickyTop(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _TopToolbar(),
                            _SelectionBarCompact(controller: c),
                            if (c.loading) const LinearProgressIndicator(minHeight: 2),
                            if (c.error != null) _ErrorBox(error: c.error!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _ReportsTable(items: c.items)),
                      const SizedBox(height: 6),
                      const _PagerBarDense(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Si la ventana es más chica que los mínimos, mostramos scroll.
          final needsHScroll = constraints.maxWidth  < minW;
          final needsVScroll = constraints.maxHeight < minH;

          if (!needsHScroll && !needsVScroll) return content;

          Widget w = content;
          if (needsHScroll) w = SingleChildScrollView(scrollDirection: Axis.horizontal, child: w);
          if (needsVScroll) w = SingleChildScrollView(scrollDirection: Axis.vertical, child: w);
          return w;
        },
      ),
    );
  }
}

/* ----------------------------- BARRA SUPERIOR ----------------------------- */

class _TopToolbar extends StatelessWidget {
  const _TopToolbar();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReportsListController>();
    final r = c.range;

    InputDecoration dec(String label) => const InputDecoration(
      isDense: true,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ).copyWith(labelText: label);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Gestionar / Descargar (iconitos compactos)
            SegmentedButton<ReportsUIMode>(
              style: const ButtonStyle(
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              ),
              segments: const [
                ButtonSegment(value: ReportsUIMode.manage, icon: Icon(Icons.rule), label: Text('Gestionar')),
                ButtonSegment(value: ReportsUIMode.download, icon: Icon(Icons.download), label: Text('Descargar')),
              ],
              selected: {c.mode},
              onSelectionChanged: (_) =>
                  context.read<ReportsListController>().toggleMode(),
            ),

            // Fecha
            _DateBtn(
              label: c.usingDefaultRange
                  ? 'Últimos 90 días'
                  : '${_fmt(r.start)} – ${_fmt(r.end.subtract(const Duration(days: 1)))}',
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023, 1, 1),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: c.usingDefaultRange ? null : r,
                  builder: (ctx, child) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
                      child: child!,
                    ),
                  ),
                );
                c.setRange(picked);
                await c.refresh();
              },
            ),

            // Estado
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: c.state,
                decoration: dec('Estado'),
                isDense: true,
                onChanged: (v) { if (v != null) c.setState(v); },
                items: const [
                  DropdownMenuItem(value: 'todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'valido', child: Text('Válidos')),
                  DropdownMenuItem(value: 'eliminado', child: Text('Eliminados')),
                ],
              ),
            ),

            // Orden
            OutlinedButton.icon(
              style: const ButtonStyle(
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              ),
              onPressed: () => context.read<ReportsListController>().toggleSort(),
              icon: Icon(c.sortDesc ? Icons.south : Icons.north),
              label: Text(c.sortDesc ? 'Fecha: nuevo → antiguo' : 'Fecha: antiguo → nuevo'),
            ),

            // Marcar/Desmarcar visibles
            OutlinedButton.icon(
              style: const ButtonStyle(
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
              ),
              onPressed: c.visibleCount > 0 ? context.read<ReportsListController>().toggleAllVisible : null,
              icon: Icon(c.allVisibleSelected ? Icons.clear_all : Icons.done_all),
              label: Text(c.allVisibleSelected ? 'Desmarcar todos' : 'Marcar todos'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/* ------------------------------ PANEL IZQUIERDO ------------------------------ */

class _LeftFiltersPanel extends StatefulWidget {
  const _LeftFiltersPanel({required this.width});
  final double width;

  @override
  State<_LeftFiltersPanel> createState() => _LeftFiltersPanelState();
}

class _LeftFiltersPanelState extends State<_LeftFiltersPanel> {
  final _blockCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _blockCtrl.dispose();
    _authorCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReportsListController>();
    InputDecoration dec(String label) => const InputDecoration(
      isDense: true,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ).copyWith(labelText: label);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(width: widget.width, child: TextField(controller: _textCtrl,   decoration: dec('Texto (título/desc/url)'), onChanged: c.setText)),
                const SizedBox(height: 10),
                SizedBox(width: widget.width, child: TextField(controller: _blockCtrl,  decoration: dec('Bloque'), onChanged: c.setBlock)),
                const SizedBox(height: 10),
                SizedBox(width: widget.width, child: TextField(controller: _authorCtrl, decoration: dec('Autor'),  onChanged: c.setAuthor)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      _blockCtrl.clear(); _authorCtrl.clear(); _textCtrl.clear();
                      await context.read<ReportsListController>().clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ SELECCIÓN COMPACTA ------------------------------ */
// Eliminar
class _SelectionBarCompact extends StatelessWidget {
  const _SelectionBarCompact({required this.controller});
  final ReportsListController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasSelection) return const SizedBox.shrink();

    Future<bool> _confirm(BuildContext ctx, String title, String msg) async {
      final ok = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aceptar')),
          ],
        ),
      );
      return ok == true;
    }

    void _snack(String msg) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    final isManage = controller.mode == ReportsUIMode.manage;
    final onTrashTab = controller.viewingDeleted;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('${controller.selectedCount} seleccionados'),
          const Spacer(),

          // ——— Botones de acción ———
          if (isManage && onTrashTab) ...[
            // Restaurar (mantiene lo existente)
            FilledButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
              onPressed: () async {
                final ok = await _confirm(context, 'Restaurar seleccionados',
                    '¿Restaurar ${controller.selectedCount} reporte(s)?');
                if (ok) { await controller.restoreSelected(actor: 'admin'); _snack('Restaurados.'); }
              },
              icon: const Icon(Icons.undo),
              label: const Text('Restaurar'),
            ),
            const SizedBox(width: 8),
            // ✅ Nuevo: Borrar definitivo
            FilledButton.tonalIcon(
              style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
              onPressed: () async {
                final ok = await _confirm(context, 'Borrar DEFINITIVAMENTE',
                    'Se eliminarán de Firestore (y sus hashes). ¿Continuar?');
                if (ok) { await controller.hardDeleteSelected(actor: 'admin'); _snack('Eliminados definitivamente.'); }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Borrar definitivo'),
            ),
          ] else if (isManage && !onTrashTab) ...[
            // Eliminar (soft) en pestañas Todos/Válidos
            FilledButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
              onPressed: () async {
                final ok = await _confirm(context, 'Eliminar seleccionados',
                    '¿Enviar ${controller.selectedCount} reporte(s) a Eliminados?');
                if (ok) { await controller.deleteSelected(actor: 'admin'); _snack('Eliminados.'); }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ] else ...[
            // Descargar (modo “Descargar”)
            FilledButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
              onPressed: () async {
                final html = await controller.exportSelectedHtml();
                downloadTextFileWeb('reportes_contraplano.html', html);
                _snack('Descarga iniciada.');
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar'),
            ),
          ],

          const SizedBox(width: 8),
          if (!controller.allVisibleSelected)
            TextButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
              onPressed: controller.clearSelection,
              icon: const Icon(Icons.clear),
              label: const Text('Quitar selección'),
            ),
        ],
      ),
    );
  }
}

/* ---------------------------------- LISTA ---------------------------------- */

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({required this.items});
  final List<Report> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No se encontraron reportes con estos filtros.'));
    }
    final c = context.read<ReportsListController>();

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = items[i];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(value: c.isSelected(r), onChanged: (_) => c.toggle(r)),
                const SizedBox(width: 6),
                _Thumb(url: r.imageUrl),
              ],
            ),
            title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${_fmt(r.date)} · ${r.block} · ${r.author.isEmpty ? "—" : r.author}'),
            onTap: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => ReportPreviewDialog(report: r),
            ),
          );
        },
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/* ------------------------------ PIE COMPACTO ------------------------------ */

class _PagerBarDense extends StatelessWidget {
  const _PagerBarDense();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReportsListController>();
    final pages = c.totalPages;

    final style = Theme.of(context).textTheme.bodySmall;

    return Row(
      children: [
        Text('${c.visibleCount}/${c.totalVisible} · pág ${c.page + 1}/$pages', style: style),
        const Spacer(),
        DropdownButton<int>(
          value: c.pageSize,
          onChanged: (v) { if (v != null) context.read<ReportsListController>().setPageSize(v); },
          isDense: true,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 15,  child: Text('15')),
            DropdownMenuItem(value: 30,  child: Text('30')),
            DropdownMenuItem(value: 50,  child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
        ),
        const SizedBox(width: 4),
        IconButton(
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          onPressed: c.page > 0 ? context.read<ReportsListController>().prevPage : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
        ),
        IconButton(
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          onPressed: (c.page + 1) < pages ? context.read<ReportsListController>().nextPage : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Siguiente',
        ),
      ],
    );
  }
}

/* ----------------------------- HELPERS UI ----------------------------- */

class _StickyTop extends StatelessWidget {
  const _StickyTop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // sombra sutil + fondo para diferenciar zona fija
    final color = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: child,
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) =>
      OutlinedButton.icon(
        style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
        onPressed: onTap, icon: const Icon(Icons.date_range), label: Text(label),
      );
}

/* ----------------------- THUMBNAIL CON FALLBACK ------------------------ */

class _Thumb extends StatefulWidget {
  const _Thumb({required this.url});
  final String? url;

  static const _size = 40.0;
  // tu Worker (Cloudflare) para las imágenes
  static const _fnUrl = 'https://wispy-glade-1567.contraplano-mrc.workers.dev';

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _tryOriginal = false;

  @override
  Widget build(BuildContext context) {
    final src = widget.url;
    if (src == null || src.isEmpty) return const _NoImg(size: _Thumb._size);

    final proxied = imageProxied(src, functionsBaseUrl: _Thumb._fnUrl).toString();
    final urlToUse = _tryOriginal ? src : proxied;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        urlToUse,
        width: _Thumb._size,
        height: _Thumb._size,
        fit: BoxFit.cover,
        // servir más chico y rápido
        cacheWidth: 80,
        cacheHeight: 80,
        // si falla el proxy, intentamos 1 vez la URL original
        errorBuilder: (_, __, ___) {
          if (!_tryOriginal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tryOriginal = true);
            });
            return const SizedBox(width: _Thumb._size, height: _Thumb._size);
          }
          return const _NoImg(size: _Thumb._size);
        },
        loadingBuilder: (ctx, child, prog) => prog == null
            ? child
            : const SizedBox(
                width: _Thumb._size,
                height: _Thumb._size,
                child: Center(
                  child: SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NoImg extends StatelessWidget {
  const _NoImg({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: const Text('N/D', style: TextStyle(fontSize: 10)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
      ),
    );
  }
}
