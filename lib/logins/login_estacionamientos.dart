// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParkingLoginScreen extends StatefulWidget {
  @override
  _ParkingLoginScreenState createState() => _ParkingLoginScreenState();
}

class _ParkingLoginScreenState extends State<ParkingLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login de Estacionamiento'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Correo electrónico'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese su correo' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onChanged: (value) => password = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese su contraseña' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      print(email);
                      print(password);
                      // Intenta iniciar sesión con Firebase Authentication
                      await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Aquí puedes redirigir al usuario a la pantalla principal
                      Navigator.pushNamed(context, '/ParkingHomeScreen');
                    } catch (e) {
                      print(e);
                      // Muestra un mensaje de error en caso de fallar el inicio de sesión
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Error: Credenciales incorrectas o usuario no encontrado'),
                        ),
                      );
                    }
                  }
                },
                child: Text('Iniciar Sesión'),
              ),
              SizedBox(
                  height:
                      20), // Espacio entre el botón de inicio y el de registro
              TextButton(
                onPressed: () {
                  // Redirigir a la pantalla de registro de estacionamientos
                  Navigator.pushNamed(context, '/parkingRegister');
                },
                child: Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
