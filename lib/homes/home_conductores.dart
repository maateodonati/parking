// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedProvince;
  String? selectedCity;
  String? selectedZone;

  List<String> provinces = [];
  List<String> cities = [];
  List<String> zones = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    final parkingDocs = await _firestore.collection('estacionamientos').get();
    Set<String> provinceSet = {};
    Map<String, Set<String>> cityMap = {};

    for (var doc in parkingDocs.docs) {
      final province = doc['provincia'];
      final city = doc['ciudad'];
      final zone = doc['zona'];

      provinceSet.add(province);
      cityMap.putIfAbsent(province, () => {}).add(city);
    }

    setState(() {
      provinces = provinceSet.toList();
      cities =
          selectedProvince != null ? cityMap[selectedProvince]!.toList() : [];
    });
  }

  void showReservationForm(BuildContext context, String parkingLotId,
      parkingLotDomicilio, parkingLotNombre) {
    final _formKey = GlobalKey<FormState>();
    String selectedVehicleId = '';
    String reservationDurationInput = '60'; // Entrada por defecto
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    print("entro a showreservation");

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('conductores')
              .doc(userId)
              .collection('vehiculos')
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();

            final vehicles = snapshot.data!.docs;
            return AlertDialog(
              title: Text('Solicitud de Reserva'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedVehicleId.isNotEmpty
                          ? selectedVehicleId
                          : null,
                      items: vehicles.map((vehicle) {
                        return DropdownMenuItem(
                          value: vehicle.id,
                          child: Text(vehicle['apodo']), // Mostrar apodo
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedVehicleId = value!;
                      },
                      decoration:
                          InputDecoration(labelText: 'Selecciona tu vehículo'),
                      validator: (value) =>
                          value == null ? 'Seleccione un vehículo' : null,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                      },
                      child: Text(selectedDate == null
                          ? 'Seleccionar Fecha'
                          : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                      },
                      child: Text(selectedTime == null
                          ? 'Seleccionar Hora'
                          : selectedTime!.format(context)),
                    ),
                    TextFormField(
                      initialValue: reservationDurationInput,
                      decoration:
                          InputDecoration(labelText: 'Duración (min o h)'),
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        reservationDurationInput = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una duración válida';
                        }
                        if (!RegExp(r'^\d+(h|m)?$').hasMatch(value)) {
                          return 'Formato no válido (ej. 60m o 1h)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        selectedDate != null &&
                        selectedTime != null) {
                      final selectedDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      var vehicle =
                          vehicles.firstWhere((v) => v.id == selectedVehicleId);

                      // Convertir duración de entrada a minutos
                      int reservationDuration;
                      if (reservationDurationInput.endsWith('h')) {
                        reservationDuration = int.parse(
                                reservationDurationInput.replaceAll('h', '')) *
                            60; // convertir horas a minutos
                      } else {
                        reservationDuration = int.parse(reservationDurationInput
                            .replaceAll('m', '')); // en minutos
                      }

                      bool success = await createReservationRequest(
                          parkingLotId,
                          vehicle['tipo'],
                          vehicle['patente'],
                          selectedDateTime,
                          reservationDuration,
                          parkingLotDomicilio,
                          parkingLotNombre);

                      Navigator.pop(context);
                      // Muestra un Scaffold con el resultado
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Solicitud de reserva enviada exitosamente.'
                              : 'Error al enviar la solicitud.'),
                        ),
                      );
                    }
                  },
                  child: Text('Enviar Solicitud'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> createReservationRequest(
      String parkingLotId,
      String vehicleType,
      String licensePlate,
      DateTime selectedDateTime,
      int duration,
      parkingLotDomicilio,
      parkingLotNombre) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Obtener el nombre del conductor
      DocumentSnapshot driverDoc =
          await _firestore.collection('conductores').doc(userId).get();

      String driverName =
          driverDoc.exists ? driverDoc['nombre'] : 'Desconocido';

      await _firestore.collection('solicitudes').add({
        'parkingLotId': parkingLotId,
        'vehicleType': vehicleType,
        'licensePlate': licensePlate,
        'dateTime': Timestamp.fromDate(selectedDateTime),
        'duration': duration,
        'status': 'Pendiente',
        'driverId': userId,
        'driverName': driverName,
        'parkingLotDomicilio': parkingLotDomicilio,
        'parkingLotNombre': parkingLotNombre
      });
      return true; // Solicitud exitosa
    } catch (e) {
      print('Error al crear solicitud: $e');
      return false; // Error al crear la solicitud
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Conductores'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReservationListScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.car_rental),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => VehicleManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedProvince,
                  items: provinces.map((province) {
                    return DropdownMenuItem(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      selectedProvince = value;
                      selectedCity = null;
                      selectedZone = null;
                    });
                    await _loadFilterOptions();
                  },
                  decoration: InputDecoration(labelText: 'Provincia'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  items: cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                      selectedZone = null;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Ciudad'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('estacionamientos')
                  .where('provincia', isEqualTo: selectedProvince)
                  .where('ciudad', isEqualTo: selectedCity)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final parkingLots = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: parkingLots.length,
                  itemBuilder: (context, index) {
                    var parkingLot = parkingLots[index];

                    return ListTile(
                      title: Text(parkingLot['nombre_estacionamiento']),
                      subtitle: Text('Ubicación: ${parkingLot['domicilio']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          showReservationForm(
                              context,
                              parkingLot.id,
                              parkingLot['domicilio'],
                              parkingLot['nombre_estacionamiento']);
                        },
                        child: Text('Reservar'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleManagementScreen extends StatefulWidget {
  @override
  _VehicleManagementScreenState createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _addVehicle(String nickname, String type, String plate) async {
    try {
      await _firestore
          .collection('conductores')
          .doc(userId)
          .collection('vehiculos')
          .add({
        'apodo': nickname,
        'tipo': type,
        'patente': plate,
      });
    } catch (e) {
      print('Error al agregar vehículo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el vehículo')),
      );
    }
  }

  void _showAddVehicleDialog() {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String vehicleNickname = '';
    String vehicleType = 'Auto'; // Valor inicial del tipo
    String vehiclePlateLetters = '';
    String vehiclePlateNumbers = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Vehículo'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Apodo del vehículo'),
                  onChanged: (value) {
                    vehicleNickname = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese un apodo';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  decoration: InputDecoration(labelText: 'Tipo de vehículo'),
                  onChanged: (value) {
                    vehicleType = value!;
                  },
                  items: [
                    DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                    DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                    DropdownMenuItem(
                        value: 'Bicicleta', child: Text('Bicicleta')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Patente (Letras)'),
                        maxLength: 3,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z]')),
                        ],
                        onChanged: (value) {
                          vehiclePlateLetters = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese letras';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Patente (Números)'),
                        maxLength: 3,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          vehiclePlateNumbers = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese números';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  String fullPlate = vehiclePlateLetters + vehiclePlateNumbers;
                  _addVehicle(vehicleNickname, vehicleType, fullPlate);
                  Navigator.of(context).pop(); // Cerrar el diálogo
                }
              },
              child: Text('Agregar Vehículo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Vehículos'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _showAddVehicleDialog,
            child: Text('Agregar Vehículo'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conductores')
                  .doc(userId)
                  .collection('vehiculos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final vehicles = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    var vehicle = vehicles[index];

                    return ListTile(
                      title: Text(vehicle['apodo']),
                      subtitle: Text(
                          'Tipo: ${vehicle['tipo']}, Patente: ${vehicle['patente']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          // Eliminar vehículo
                          await _firestore
                              .collection('conductores')
                              .doc(userId)
                              .collection('vehiculos')
                              .doc(vehicle.id)
                              .delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Reservas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('driverId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          final reservations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              var reservation = reservations[index];
              return ListTile(
                title: Text('Reserva: ${reservation['licensePlate']}'),
                subtitle: Text(
                  'Estacionamiento: ${reservation['parkingLotNombre']}, '
                  'Domicilio: ${reservation['parkingLotDomicilio']}, '
                  'Fecha: ${DateFormat('yyyy-MM-dd').format(reservation['dateTime'].toDate())}, '
                  'Duración: ${reservation['duration']} min, '
                  'Estado: ${reservation['status']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
