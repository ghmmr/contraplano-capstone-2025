import 'package:flutter/material.dart';
import 'package:mrc_contraplano/features/reports/state/report_form_state.dart';
import 'package:mrc_contraplano/utils/validators.dart';
import 'package:dropdown_button2/dropdown_button2.dart';


class IdentitySection extends StatelessWidget {
  final ReportFormState s;
  final AutovalidateMode auto;
  final ValueChanged<String?>? onBlockChanged;

  const IdentitySection({
    super.key,
    required this.s,
    required this.auto,
    this.onBlockChanged,
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
          TextFormField(
            key: const ValueKey('nameField'),
            controller: s.nameCtrl,
            validator: requiredField,
            autovalidateMode: auto,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            ),
          ),
          TextFormField(
            key: const ValueKey('titleField'),
            controller: s.titleCtrl,
            validator: requiredField,
            autovalidateMode: auto,
            decoration: const InputDecoration(
              labelText: 'Título de la noticia',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Campo: Bloque (sin escritura, popup del mismo ancho del campo)
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return DropdownButtonFormField2<String>(
              key: const ValueKey('blockDropdown'),
              value: s.block,
              items: s.blocks
                  .map((b) => DropdownMenuItem<String>(
                        value: b,
                        child: Text(b, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                s.block = v;
                onBlockChanged?.call(v);
              },

              // ✅ obligatorio + validación en vivo
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
              autovalidateMode: auto,

              // Estilo del “input” para que calce con tus TextFormField
              decoration: const InputDecoration(
                labelText: 'Bloque',
                border: OutlineInputBorder(),
                isDense: true, // 👈 reduce altura del label/field
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),

              // —— Estilos específicos del paquete ——
              buttonStyleData: const ButtonStyleData(
                height: 48, // similar a tus campos
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 320,   // scroll interno, no desborda en alto
                width: w,         // 👈 popup del MISMO ancho del campo
                elevation: 2,
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 40,
              ),
              // No definimos dropdownSearchData => ❌ sin cuadro de búsqueda
            );
          },
        ),



      ],
    );
  }
}
