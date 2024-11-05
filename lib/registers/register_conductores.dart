// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterDriverScreen extends StatefulWidget {
  @override
  _RegisterDriverScreenState createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String name = '';
  String lastName = '';
  String phone = '';
  String email = '';
  String password = '';

  Future<void> _registerUser() async {
    try {
      // Crea un usuario con Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtiene el UID del usuario recién creado
      String uid = userCredential.user!.uid;

      // Guarda los datos en la colección 'conductores'
      await _firestore.collection('conductores').doc(uid).set({
        'nombre': name,
        'apellido': lastName,
        'telefono': phone,
        'correo': email,
      });

      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario registrado correctamente')),
      );

      // Puedes redirigir al usuario a otra pantalla si deseas
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Conductor'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                onChanged: (value) => name = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese su nombre' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Apellido'),
                onChanged: (value) => lastName = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese su apellido' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => phone = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese su teléfono' : null,
              ),
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
                    value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _registerUser();
                  }
                },
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
