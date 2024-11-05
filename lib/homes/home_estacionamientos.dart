import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ParkingHomeScreen extends StatefulWidget {
  @override
  _ParkingHomeScreenState createState() => _ParkingHomeScreenState();
}

class _ParkingHomeScreenState extends State<ParkingHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateReservationStatus(String requestId, String status) async {
    try {
      await _firestore.collection('solicitudes').doc(requestId).update({
        'status': status,
      });
    } catch (e) {
      print('Error actualizando estado de reserva: $e');
    }
  }

  Future<void> deleteRejectedRequest(String requestId) async {
    try {
      await _firestore.collection('solicitudes').doc(requestId).delete();
    } catch (e) {
      print('Error eliminando solicitud: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String parkingLotId = FirebaseAuth.instance.currentUser!.uid;
    print("UID del usuario: $parkingLotId"); // Log del UID

    return Scaffold(
      appBar: AppBar(title: Text('Home Estacionamiento')),
      body: Row(
        children: [
          // Sección de Solicitudes Pendientes
          Expanded(
            child: _buildRequestSection(
                parkingLotId, 'Pendiente', 'Solicitudes Pendientes'),
          ),
          VerticalDivider(),
          // Sección de Solicitudes Aceptadas
          Expanded(
            child: _buildRequestSection(
                parkingLotId, 'Aceptada', 'Solicitudes Aceptadas'),
          ),
          VerticalDivider(),
          // Sección de Solicitudes Rechazadas
          Expanded(
            child: _buildRequestSection(
                parkingLotId, 'Rechazada', 'Solicitudes Rechazadas/Canceladas',
                isRejected: true),
          ),
        ],
      ),
    );
  }

  // Método para construir una sección de solicitudes basada en el estado
  Widget _buildRequestSection(String parkingLotId, String status, String title,
      {bool isRejected = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('solicitudes')
              .where('parkingLotId', isEqualTo: parkingLotId)
              .where('status', isEqualTo: status)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text("No hay reservas en esta sección."),
              );
            }
            final requests = snapshot.data!.docs;
            print(
                "Solicitudes para $status: ${requests.length}"); // Log para verificar el número de solicitudes

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index];

                // Conversión de Timestamp a DateTime y formato legible
                DateTime dateTime = (request['dateTime'] as Timestamp).toDate();
                String formattedDate =
                    DateFormat('yyyy-MM-dd – HH:mm').format(dateTime);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      'Reserva de ${request['vehicleType']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Patente: ${request['licensePlate']} \nFecha y hora: $formattedDate', // Se muestra la patente
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: _buildActionButtons(request, status, isRejected),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Generar botones según el estado de la solicitud
  Widget _buildActionButtons(
      DocumentSnapshot request, String status, bool isRejected) {
    if (status == 'Pendiente') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () => updateReservationStatus(request.id, 'Aceptada'),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => updateReservationStatus(request.id, 'Rechazada'),
          ),
        ],
      );
    } else if (status == 'Aceptada') {
      return IconButton(
        icon: Icon(Icons.cancel, color: Colors.orange),
        onPressed: () => updateReservationStatus(request.id, 'Rechazada'),
      );
    } else if (isRejected) {
      return IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () => deleteRejectedRequest(request.id),
      );
    } else {
      return Text(status, style: TextStyle(fontSize: 14, color: Colors.grey));
    }
  }
}
