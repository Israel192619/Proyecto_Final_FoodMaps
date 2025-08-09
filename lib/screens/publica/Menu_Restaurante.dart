import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/platos_rest.dart';
import 'pages/bebidas_rest.dart';

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

  @override
  Widget build(BuildContext context) {
    final screens = [
      PlatosRest(restaurantId: widget.restaurantId),
      BebidasRest(restaurantId: widget.restaurantId),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.red.shade700,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 25, left: 16, right: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 60),
                  ),
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
      body: screens[_selectedIndex],
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
        mode: LaunchMode.externalApplication, // Asegura que se abra fuera de la app
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
