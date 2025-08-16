import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/platos_rest_page.dart'; // Asegúrate de importar correctamente
import 'pages/bebidas_rest_page.dart'; // Asegúrate de importar correctamente
import '../../config/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MenuRestaurante extends StatefulWidget {
  final int restaurantId;
  final String name;
  final String phone;
  final String imageUrl;

  const MenuRestaurante({
    Key? key,
    required this.restaurantId,
    required this.name,
    required this.phone,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<MenuRestaurante> createState() => _MenuRestauranteState();
}

class _MenuRestauranteState extends State<MenuRestaurante> {
  int _selectedIndex = 0;
  String _imageUrl = '';
  int? _menuId;
  List<dynamic> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    print('[VISTA][MENU] Entrando a MenuRestaurante: restaurantId=${widget.restaurantId}, name=${widget.name}, phone=${widget.phone}, imageUrl=${widget.imageUrl}');
    _fetchRestauranteDetalle();
  }

  Future<void> _fetchRestauranteDetalle() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(AppConfig.restauranteClienteDetalleEndpoint(widget.restaurantId));
    print('[VISTA][MENU] URL detalle restaurante: $url');
    print('[VISTA][MENU] Token: $token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][MENU] Respuesta detalle restaurante statusCode: ${response.statusCode}');
      print('[VISTA][MENU] Respuesta detalle restaurante body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rest = data['data'];
        print('[VISTA][MENU] Detalle restaurante recibido: $rest');
        setState(() {
          _imageUrl = '${AppConfig.storageBaseUrl}${rest['imagen']}';
          print('[VISTA][MENU] Imagen restaurante: $_imageUrl');
          _menuId = rest['menu_id'];
          print('[VISTA][MENU] menu_id: $_menuId');
        });
        if (_menuId != null) {
          await _fetchProductos();
        }
      }
    } catch (e) {
      print('[VISTA][MENU] Error al obtener detalle restaurante: $e');
      // Puedes mostrar un error si lo deseas
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchProductos() async {
    if (_menuId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(
      AppConfig.productosMenuRestauranteEndpoint(widget.restaurantId, _menuId!),
    );
    print('[VISTA][MENU] URL productos: $url');
    print('[VISTA][MENU] Token productos: $token');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][MENU] Respuesta productos statusCode: ${response.statusCode}');
      print('[VISTA][MENU] Respuesta productos body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[VISTA][MENU] Productos recibidos: ${data['data']}');
        setState(() {
          _productos = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('[VISTA][MENU] Error al obtener productos: $e');
      // Puedes mostrar un error si lo deseas
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtra productos por tipo (corregido el nombre del campo)
    final platos = _productos.where((p) => p['tipo'] == 0).toList();
    final bebidas = _productos.where((p) => p['tipo'] == 1).toList();

    print('[VISTA][MENU] Productos filtrados - Platos: ${platos.length}, Bebidas: ${bebidas.length}');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        print('[VISTA][MENU] PopScope - didPop: $didPop');
        if (didPop) {
          print('[VISTA][MENU] Navegación hacia atrás exitosa');
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.red.shade700,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                print('[VISTA][MENU] Botón atrás presionado manualmente');
                Navigator.of(context).pop();
              },
            ),
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 25, left: 16, right: 16),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Espacio para el botón back
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _imageUrl.isNotEmpty
                        ? Image.network(
                            _imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported, size: 60),
                          )
                        : const Icon(Icons.image_not_supported, size: 60),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _openWhatsApp,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/icons/icono_whatsapp.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  PlatosRest(productos: platos),
                  BebidasRest(productos: bebidas),
                ],
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: isDark ? Colors.black : Colors.red.shade700,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Comidas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: 'Bebidas',
            ),
          ],
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }

  void _openWhatsApp() async {
    final phone = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Número de WhatsApp inválido")),
      );
      return;
    }
    final url = Uri.parse('https://wa.me/591$phone');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp. Verifica que esté instalado.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp. Verifica que esté instalado.")),
      );
    }
  }
}
