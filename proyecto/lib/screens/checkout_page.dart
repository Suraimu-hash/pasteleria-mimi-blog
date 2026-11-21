import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/carrito_model.dart';
import '../models/pedido_model.dart';
import '../services/session.dart';
import '../services/tienda_service.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/imagen_red.dart';

/// Proceso de pago: dirección de entrega + método de pago.
///
/// El pago con tarjeta es SIMULADO (modo de prueba): la API valida la tarjeta
/// pero no cobra dinero real.
class CheckoutPage extends StatefulWidget {
  final CarritoModel carrito;

  const CheckoutPage({super.key, required this.carrito});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TiendaService tienda = TiendaService();
  final formKey = GlobalKey<FormState>();

  final direccionCtrl = TextEditingController(
    text: Sesion.usuario?['dir_usr']?.toString() ?? '',
  );
  final telefonoCtrl = TextEditingController();
  final titularCtrl = TextEditingController(text: Sesion.nombre);
  final numeroCtrl = TextEditingController();
  final vencimientoCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  String metodo = 'tarjeta';
  bool pagando = false;

  @override
  void dispose() {
    for (final c in [
      direccionCtrl, telefonoCtrl, titularCtrl, numeroCtrl, vencimientoCtrl, cvvCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Validaciones ----------
  static bool luhnValido(String numero) {
    var suma = 0;
    var doble = false;
    for (var i = numero.length - 1; i >= 0; i--) {
      var d = int.parse(numero[i]);
      if (doble) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      suma += d;
      doble = !doble;
    }
    return suma % 10 == 0;
  }

  String? validarNumero(String? v) {
    final n = (v ?? '').replaceAll(' ', '');
    if (n.length < 13 || n.length > 19) return 'Número incompleto';
    if (!luhnValido(n)) return 'Número de tarjeta no válido';
    return null;
  }

  String? validarVencimiento(String? v) {
    final partes = (v ?? '').split('/');
    if (partes.length != 2 || partes[1].length != 2) return 'Usa MM/AA';
    final mes = int.tryParse(partes[0]);
    final anio = int.tryParse(partes[1]);
    if (mes == null || anio == null || mes < 1 || mes > 12) return 'Fecha no válida';
    final hoy = DateTime.now();
    final vence = DateTime(2000 + anio, mes + 1); // primer día del mes siguiente
    if (!vence.isAfter(hoy)) return 'Tarjeta vencida';
    return null;
  }

  String marca(String numero) {
    final n = numero.replaceAll(' ', '');
    if (n.startsWith('4')) return 'VISA';
    if (RegExp(r'^5[1-5]').hasMatch(n) || RegExp(r'^2[2-7]').hasMatch(n)) {
      return 'Mastercard';
    }
    if (RegExp(r'^3[47]').hasMatch(n)) return 'AMEX';
    return '';
  }

  // ---------- Pago ----------
  Future<void> pagar() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => pagando = true);
    try {
      final pedido = await tienda.pagar(
        direccion: direccionCtrl.text,
        telefono: telefonoCtrl.text,
        metodoPago: metodo,
        tarjeta: metodo == 'tarjeta'
            ? {
                'titular': titularCtrl.text.trim(),
                'numero': numeroCtrl.text.replaceAll(' ', ''),
                'vencimiento': vencimientoCtrl.text.trim(),
                'cvv': cvvCtrl.text.trim(),
              }
            : null,
      );
      if (!mounted) return;
      await _mostrarConfirmacion(pedido);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (d) => AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
          title: const Text('No se pudo completar el pago'),
          content: Text(limpiarError(e)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Entendido')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => pagando = false);
    }
  }

  Future<void> _mostrarConfirmacion(PedidoModel pedido) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('¡Pedido confirmado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pedido #${pedido.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Total: ${formatearPrecio(pedido.total)}'),
            Text(pedido.pagoTexto),
            Text('Referencia: ${pedido.referenciaPago}'),
            const SizedBox(height: 10),
            Text(
              pedido.metodoPago == 'tarjeta'
                  ? 'Recibirás tu pedido en la dirección indicada.'
                  : 'Paga en efectivo al recibir tu pedido.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Ver mis pedidos')),
        ],
      ),
    );
  }

  // ---------- UI ----------
  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Mimi.frambuesa,
          ),
        ),
      );

  Widget _resumen() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final i in widget.carrito.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${i.cantidad} × ${i.nombre}')),
                    Text(formatearPrecio(i.subtotal)),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text(
                  formatearPrecio(widget.carrito.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Mimi.frambuesa,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formTarjeta() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.science_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pago en modo de prueba (no se cobra dinero real).\n'
                  'Aprobada: 4242 4242 4242 4242\n'
                  'Rechazada: 4000 0000 0000 0002\n'
                  'Usa cualquier fecha futura y CVV de 3 dígitos.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: titularCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del titular',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v ?? '').trim().length < 3 ? 'Escribe el nombre' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: numeroCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _FormatoTarjeta(),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Número de tarjeta',
            prefixIcon: const Icon(Icons.credit_card),
            suffixText: marca(numeroCtrl.text),
            border: const OutlineInputBorder(),
          ),
          validator: validarNumero,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: vencimientoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _FormatoVencimiento(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Vence (MM/AA)',
                  border: OutlineInputBorder(),
                ),
                validator: validarVencimiento,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: cvvCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').length < 3 ? 'CVV no válido' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar pedido')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _titulo('Resumen'),
            _resumen(),
            _titulo('Entrega'),
            TextFormField(
              controller: direccionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().length < 5 ? 'Escribe la dirección completa' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            _titulo('Método de pago'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'tarjeta',
                  icon: Icon(Icons.credit_card),
                  label: Text('Tarjeta'),
                ),
                ButtonSegment(
                  value: 'efectivo',
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Efectivo'),
                ),
              ],
              selected: {metodo},
              onSelectionChanged: (s) => setState(() => metodo = s.first),
            ),
            const SizedBox(height: 14),
            if (metodo == 'tarjeta')
              _formTarjeta()
            else
              const Text(
                'Pagarás en efectivo al recibir tu pedido. '
                'Tu pedido quedará como "Pago pendiente".',
                style: TextStyle(color: Mimi.gris),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: pagando ? null : pagar,
                icon: pagando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  metodo == 'tarjeta'
                      ? 'Pagar ${formatearPrecio(widget.carrito.total)}'
                      : 'Confirmar pedido',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "4242424242424242" -> "4242 4242 4242 4242"
class _FormatoTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final digitos = nuevo.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// "1228" -> "12/28"
class _FormatoVencimiento extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final digitos = nuevo.text.replaceAll('/', '');
    final texto = digitos.length > 2
        ? '${digitos.substring(0, 2)}/${digitos.substring(2)}'
        : digitos;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
