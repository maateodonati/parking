// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverLoginScreen extends StatefulWidget {
  @override
  _DriverLoginScreenState createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login de Conductor'),
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
                      // Intenta iniciar sesión con correo y contraseña
                      await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // Aquí puedes redirigir al usuario a la pantalla de inicio
                      Navigator.pushNamed(context, '/DriverHomeScreen');
                    } catch (e) {
                      // Muestra un mensaje de error si el inicio de sesión falla
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
                  // Redirigir a la pantalla de registro de conductores
                  Navigator.pushNamed(context, '/driverRegister');
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
