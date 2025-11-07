// lib/mi_tienda/horario_editor.dart
import 'package:flutter/material.dart';

/// Abre un diálogo modal grande para editar horarios.
/// Recibe la estructura actual de horarios y devuelve la nueva (o null si se canceló).
/// Estructura: Map<String, Map<String,dynamic>>
/// Cada día: { 'abierto': bool, 'abre': {'hour':int,'minute':int,'period':'AM'|'PM'}?, 'cierra': {...}? }
Future<Map<String, Map<String, dynamic>>?> showHorarioEditorDialog(
    BuildContext context,
    Map<String, Map<String, dynamic>> current) {
  // deep copy
  final Map<String, Map<String, dynamic>> copia = {};
  current.forEach((k, v) {
    copia[k] = {
      'abierto': v['abierto'] ?? false,
      'abre': v['abre'] == null ? null : Map<String, dynamic>.from(v['abre']),
      'cierra': v['cierra'] == null ? null : Map<String, dynamic>.from(v['cierra']),
    };
  });

  // ensure all days are present (in case)
  const dias = ['lunes','martes','miercoles','jueves','viernes','sabado','domingo'];
  for (final d in dias) {
    copia.putIfAbsent(d, () => {'abierto': false, 'abre': null, 'cierra': null});
  }

  return showDialog<Map<String, Map<String, dynamic>>>(
    context: context,
    builder: (context) {
      String daySelected = 'lunes';
      return StatefulBuilder(
          builder: (context, setLocalState) {
            final hours = List<int>.generate(12, (i) => i + 1); // 1..12
            final minutes = List<int>.generate(6, (i) => i * 10); // 0,10,..50
            final periods = ['AM', 'PM'];

            String formatTime(Map<String, dynamic>? t) {
              if (t == null) return '--:--';
              final h = (t['hour'] as int).toString().padLeft(2, '0');
              final m = (t['minute'] as int).toString().padLeft(2, '0');
              final p = t['period'] as String;
              return '$h:$m $p';
            }

            Widget timeSelector(Map<String, dynamic>? value, void Function(Map<String,dynamic>?) onChanged, bool enabled) {
              final selHour = value?['hour'] as int?;
              final selMinute = value?['minute'] as int?;
              final selPeriod = value?['period'] as String?;
              final textColor = enabled ? Colors.white : Colors.white24;

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF143657),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    // hour
                    DropdownButton<int>(
                      value: selHour,
                      dropdownColor: const Color(0xFF143657),
                      underline: const SizedBox(),
                      style: TextStyle(color: textColor),
                      hint: Text('HH', style: TextStyle(color: textColor)),
                      items: hours.map((h) => DropdownMenuItem(value: h, child: Text(h.toString().padLeft(2,'0')))).toList(),
                      onChanged: enabled ? (h) {
                        if (h == null) return;
                        onChanged({'hour': h, 'minute': selMinute ?? 0, 'period': selPeriod ?? 'AM'});
                        setLocalState(() {});
                      } : null,
                    ),
                    const Text(':', style: TextStyle(color: Colors.white70)),
                    // minute
                    DropdownButton<int>(
                      value: selMinute,
                      dropdownColor: const Color(0xFF143657),
                      underline: const SizedBox(),
                      style: TextStyle(color: textColor),
                      hint: Text('MM', style: TextStyle(color: textColor)),
                      items: minutes.map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2,'0')))).toList(),
                      onChanged: enabled ? (m) {
                        if (m == null) return;
                        onChanged({'hour': selHour ?? 1, 'minute': m, 'period': selPeriod ?? 'AM'});
                        setLocalState(() {});
                      } : null,
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selPeriod,
                      dropdownColor: const Color(0xFF143657),
                      underline: const SizedBox(),
                      style: TextStyle(color: textColor),
                      hint: Text('AM/PM', style: TextStyle(color: textColor)),
                      items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: enabled ? (p) {
                        if (p == null) return;
                        onChanged({'hour': selHour ?? 1, 'minute': selMinute ?? 0, 'period': p});
                        setLocalState(() {});
                      } : null,
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B2239),
              contentPadding: const EdgeInsets.all(12),
              content: SizedBox(
                width: double.maxFinite,
                height: 520,
                child: Column(
                  children: [
                    // días horizontal
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: copia.keys.map((dia) {
                          final short = _shortDia(dia);
                          final selected = dia == daySelected;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => setLocalState(() => daySelected = dia),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: selected ? Colors.greenAccent : const Color(0xFF143657),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(short, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Abierto', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(width: 12),
                        Switch.adaptive(
                          value: copia[daySelected]!['abierto'] as bool,
                          onChanged: (v) {
                            setLocalState(() {
                              copia[daySelected]!['abierto'] = v;
                              if (!v) {
                                copia[daySelected]!['abre'] = null;
                                copia[daySelected]!['cierra'] = null;
                              } else {
                                copia[daySelected]!['abre'] ??= {'hour': 9, 'minute': 0, 'period': 'AM'};
                                copia[daySelected]!['cierra'] ??= {'hour': 6, 'minute': 0, 'period': 'PM'};
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF143657),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Horario para ${_nombreDia(daySelected)}', style: const TextStyle(color: Color(0xFFF6EED9), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            const Text('Hora de inicio', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            timeSelector(copia[daySelected]!['abre'], (val) => copia[daySelected]!['abre'] = val, copia[daySelected]!['abierto'] as bool),
                            const SizedBox(height: 12),
                            const Text('Hora de cierre', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            timeSelector(copia[daySelected]!['cierra'], (val) => copia[daySelected]!['cierra'] = val, copia[daySelected]!['abierto'] as bool),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 6),
                            Text('Resumen: ${copia[daySelected]!['abierto'] ? "${formatTime(copia[daySelected]!['abre'])} - ${formatTime(copia[daySelected]!['cierra'])}" : "Cerrado"}', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: copia.keys.map((k) {
                                    final row = copia[k]!;
                                    final display = row['abierto'] ? "${formatTime(row['abre'])} - ${formatTime(row['cierra'])}" : "Cerrado";
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_nombreDia(k), style: const TextStyle(color: Colors.white70)),
                                          Text(display, style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context, copia),
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
      );
    },
  );
}

String _shortDia(String dia) {
  switch (dia) {
    case 'lunes': return 'L';
    case 'martes': return 'M';
    case 'miercoles': return 'Mi';
    case 'jueves': return 'J';
    case 'viernes': return 'V';
    case 'sabado': return 'S';
    case 'domingo': return 'D';
    default: return dia;
  }
}

String _nombreDia(String dia) {
  switch (dia) {
    case 'lunes': return 'Lunes';
    case 'martes': return 'Martes';
    case 'miercoles': return 'Miércoles';
    case 'jueves': return 'Jueves';
    case 'viernes': return 'Viernes';
    case 'sabado': return 'Sábado';
    case 'domingo': return 'Domingo';
    default: return dia;
  }
}
