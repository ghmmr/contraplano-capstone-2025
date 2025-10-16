import 'package:flutter/material.dart';
import '../data/report_repository.dart';
import '../models/report.dart';
import '../utils/html_exporter.dart';

enum ReportsUIMode { manage, download }

class ReportsListController extends ChangeNotifier {
  ReportsListController(this._repo);
  final ReportRepository _repo;

  // ------- Filtros -------
  DateTimeRange? _range;                 // null => últimos 90 días
  String _block = '';
  String _author = '';
  String _text = '';
  String _state = 'todos';               // 'todos' | 'valido' | 'eliminado'

  // ------- Orden -------
  bool _sortDesc = true;                 // true: nuevo→antiguo (default)
  bool get sortDesc => _sortDesc;
  void toggleSort() { _sortDesc = !_sortDesc; _page = 0; notifyListeners(); }

  // ------- Paginación (CLIENTE) -------
  int _page = 0;
  int _pageSize = 15; // default 15
  int get page => _page;
  int get pageSize => _pageSize;
  void nextPage() { if (_page < totalPages - 1) { _page++; notifyListeners(); } }
  void prevPage() { if (_page > 0) { _page--; notifyListeners(); } }
  void setPageSize(int v) {
    if (v != _pageSize) {
      _pageSize = v;
      _page = 0;
      _selected.clear(); // regla UX
      notifyListeners();
    }
  }

  // ------- Estado -------
  bool _loading = false;
  List<Report> _items = [];
  String? _error;

  // ------- Modo UI -------
  ReportsUIMode _mode = ReportsUIMode.manage;
  ReportsUIMode get mode => _mode;
  void toggleMode() { _mode = _mode == ReportsUIMode.manage ? ReportsUIMode.download : ReportsUIMode.manage; notifyListeners(); }
  String get primaryActionLabel {
    if (!hasSelection) return '...';
    return _mode == ReportsUIMode.manage ? (viewingDeleted ? 'Restaurar' : 'Eliminar') : 'Descargar';
  }

  // ------- Selección -------
  final Set<String> _selected = {};
  bool get hasSelection => _selected.isNotEmpty;
  int get selectedCount => _selected.length;
  bool get viewingDeleted => _state == 'eliminado';
  bool isSelected(Report r) => _selected.contains(r.id);
  void toggle(Report r) { if (!_selected.remove(r.id)) _selected.add(r.id); notifyListeners(); }
  void clearSelection() { _selected.clear(); notifyListeners(); }

  // ------- Getters públicos -------
  DateTimeRange get range => _range ?? _defaultRange90d();
  bool get usingDefaultRange => _range == null;
  String get block => _block;
  String get author => _author;
  String get text => _text;
  String get state => _state;
  bool get loading => _loading;
  String? get error => _error;

  // Lista filtrada y ordenada completa
  List<Report> get _visibleAll => _applyClientFilters(_items);

  // Página actual
  List<Report> get items {
    final start = _page * _pageSize;
    final end = (start + _pageSize) > _visibleAll.length ? _visibleAll.length : (start + _pageSize);
    if (start >= _visibleAll.length) return const [];
    return _visibleAll.sublist(start, end);
  }

  int get totalVisible => _visibleAll.length;
  int get totalPages => totalVisible == 0 ? 1 : ((totalVisible - 1) ~/ _pageSize) + 1;

  // Para UI: marcar/desmarcar visibles
  bool get allVisibleSelected {
    final vis = items.map((e) => e.id).toSet();
    if (vis.isEmpty) return false;
    for (final id in vis) { if (!_selected.contains(id)) return false; }
    return true;
  }
  int get visibleCount => items.length;

  void toggleAllVisible() {
    final vis = items.map((e) => e.id).toSet();
    final all = vis.isNotEmpty && vis.difference(_selected).isEmpty;
    if (all) { _selected.removeAll(vis); } else { _selected.addAll(vis); }
    notifyListeners();
  }

  // ------- Acciones de filtro -------
  // Mantener selección al cambiar bloque/autor/texto/fecha (misma categoría)
  void setRange(DateTimeRange? r) { _range = r; _page = 0; notifyListeners(); }
  void setBlock(String v)         { _block = v; _page = 0; notifyListeners(); }
  void setAuthor(String v)        { _author = v; _page = 0; notifyListeners(); }
  void setText(String v)          { _text = v; _page = 0; notifyListeners(); }

  // Cambiar de pestaña (estado) SÍ limpia selección
  void setState(String v) { _state = v; _page = 0; _selected.clear(); notifyListeners(); }

  Future<void> refresh() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final r = range;
      _items = await _repo.findByDateRange(from: r.start, to: r.end);
      _page = 0;
      _pruneSelectionToDataset(); // si algo ya no existe, lo saca de la selección
    } catch (e) { _error = e.toString(); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> clearFilters() async {
    _range = null; _block = _author = _text = ''; _state = 'todos';
    _selected.clear(); _page = 0;
    await refresh();
  }

  // ------- Acciones sobre datos -------
  Future<void> deleteSelected({required String actor}) async {
    _loading = true; notifyListeners();
    try {
      final toDel = _items.where((e) => _selected.contains(e.id)).toList();
      await _repo.softDeleteMany(items: toDel, actor: actor);
      clearSelection(); await refresh();
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> restoreSelected({required String actor}) async {
    _loading = true; notifyListeners();
    try {
      final toRes = _items.where((e) => _selected.contains(e.id)).toList();
      await _repo.restoreMany(items: toRes, actor: actor);
      clearSelection(); await refresh();
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> hardDeleteSelected({required String actor}) async {
    _loading = true; notifyListeners();
    try {
      final toHard = _items.where((e) => _selected.contains(e.id)).toList();
      await _repo.hardDeleteMany(items: toHard, actor: actor);
      clearSelection(); await refresh();
    } finally { _loading = false; notifyListeners(); }
  }

  /// Exporta HTML para selección actual
  Future<String> exportSelectedHtml() async {
    final selected = _items.where((e) => _selected.contains(e.id)).toList()
      ..sort((a, b) => _sortDesc ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
    return HtmlExporter.buildDocument(selected);
  }

  // ------- Helpers internos -------
  void _pruneSelectionToDataset() {
    final ids = _items.map((e) => e.id).toSet();
    _selected.removeWhere((id) => !ids.contains(id));
  }

  DateTimeRange _defaultRange90d() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 90));
    return DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day + 1),
    );
  }

  List<Report> _applyClientFilters(List<Report> src) {
    final t = _text.toLowerCase();
    final list = src.where((r) {
      final byBlock  = _block.isEmpty  || r.block.toLowerCase().contains(_block.toLowerCase());
      final byAuthor = _author.isEmpty || r.author.toLowerCase().contains(_author.toLowerCase());
      final byText   = t.isEmpty
          || r.title.toLowerCase().contains(t)
          || r.newsletterDesc.toLowerCase().contains(t)
          || r.url.toLowerCase().contains(t);
      final byState  = _state == 'todos' || r.state.toLowerCase() == _state;
      return byBlock && byAuthor && byText && byState;
    }).toList();

    list.sort((a, b) => _sortDesc ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
    return list;
  }
}
