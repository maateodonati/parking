// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterParkingScreen extends StatefulWidget {
  @override
  _RegisterParkingScreenState createState() => _RegisterParkingScreenState();
}

class _RegisterParkingScreenState extends State<RegisterParkingScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String parkingName = '';
  String province = '';
  String city = '';
  String zone = 'Centro';
  String address = '';
  String email = '';
  String password = '';

  // Lista de opciones para el menú desplegable
  final List<String> zones = ['Centro', 'Norte', 'Sur', 'Este', 'Oeste'];

  Future<void> _registerParking() async {
    try {
      // Crea el usuario con Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtiene el UID del usuario recién creado
      String uid = userCredential.user!.uid;

      // Guarda los datos en la colección 'estacionamientos'
      await _firestore.collection('estacionamientos').doc(uid).set({
        'nombre_estacionamiento': parkingName,
        'provincia': province,
        'ciudad': city,
        'zona': zone,
        'domicilio': address,
        'correo': email,
      });

      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estacionamiento registrado correctamente')),
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
        title: Text('Registro de Estacionamiento'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'Nombre del Estacionamiento'),
                onChanged: (value) => parkingName = value,
                validator: (value) => value!.isEmpty
                    ? 'Ingrese el nombre del estacionamiento'
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Provincia'),
                onChanged: (value) => province = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese la provincia' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ciudad'),
                onChanged: (value) => city = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese la ciudad' : null,
              ),
              DropdownButtonFormField<String>(
                value: zone,
                items: zones.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => zone = newValue!),
                decoration: InputDecoration(labelText: 'Zona'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Domicilio'),
                onChanged: (value) => address = value,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese el domicilio' : null,
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
                    _registerParking();
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
