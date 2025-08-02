class Usuario {
  final int id;
  final String username;
  final String email;
  final String password;
  final String token;  // <-- Añadido token aquí

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.token,
  });
}

class Restaurante {
  final int id;
  final String nombre;
  final String direccion;
  final int estado;
  final int propietarioId;

  Restaurante({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.estado = 1,
    required this.propietarioId,
  });
}

class Producto {
  final int id;
  final String nombre;
  final String categoria; // Ej: 'plato', 'bebida'
  final double precio;
  final int restauranteId;

  Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.restauranteId,
  });
}

// Datos simulados con token
final usuarioPrueba = Usuario(
  id: 1,
  username: 'username1',
  email: 'juan.perez@correo.com',
  password: '123456',
  token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mockedtoken1234567890',  // token simulado JWT
);

final restaurantePrueba = Restaurante(
  id: 1,
  nombre: 'roast and roll',
  direccion: 'https://www.google.com/maps/place/Cochabamba/@-17.3780353,-66.1518134,19.5z/data=!4m6!3m5!1s0x93e373e0d9e4ab27:0xa2719ae9532c3e65!8m2!3d-17.3820091!4d-66.1595813!16zL20vMDNrZ2N0?entry=ttu&g_ep=EgoyMDI1MDcyOS4wIKXMDSoASAFQAw%3D%3D',
  estado: 1,
  propietarioId: 1,
);

final productosPrueba = [
  Producto(
    id: 1,
    nombre: 'Silpancho',
    categoria: 'plato',
    precio: 25.0,
    restauranteId: 1,
  ),
  Producto(
    id: 2,
    nombre: 'Jugo de Maracuyá',
    categoria: 'bebida',
    precio: 8.0,
    restauranteId: 1,
  ),
];
