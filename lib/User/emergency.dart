import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatelessWidget {
  final List<Map<String, String>> emergencyContacts = [
    {
      "name": "Police",
      "number": "100",
      "icon": "security",
    },
    {
      "name": "Fire Brigade",
      "number": "101",
      "icon": "local_fire_department",
    },
    {
      "name": "Ambulance",
      "number": "102",
      "icon": "local_hospital",
    },
    {
      "name": "Women Helpline",
      "number": "1091",
      "icon": "support",
    },
    {
      "name": "Disaster Management",
      "number": "108",
      "icon": "warning",
    },
    {
      "name": "Child Helpline",
      "number": "1098",
      "icon": "child_care",
    },
    {
      "name": "Senior Citizen Helpline",
      "number": "14567",
      "icon": "elderly",
    },
    {
      "name": "Cyber Crime Helpline",
      "number": "1930",
      "icon": "computer",
    },
    {
      "name": "Anti-Poison Helpline",
      "number": "1066",
      "icon": "medical_services",
    },
    {
      "name": "Railway Enquiry",
      "number": "139",
      "icon": "train",
    },
    {
      "name": "Road Accident Emergency Service",
      "number": "1073",
      "icon": "car_repair",
    },
    {
      "name": "LPG Leak Helpline",
      "number": "1906",
      "icon": "gas_meter",
    },
    {
      "name": "Blood Bank Helpline",
      "number": "1910",
      "icon": "bloodtype",
    },
    {
      "name": "Tourist Helpline (Multi-Language)",
      "number": "1363",
      "icon": "tour",
    },
    {
      "name": "Ayush COVID-19 Counselling",
      "number": "14443",
      "icon": "health_and_safety",
    },
    {
      "name": "Farmer Helpline (Kisan Call Center)",
      "number": "18001801551",
      "icon": "agriculture",
    },
    {
      "name": "National AIDS Helpline",
      "number": "1097",
      "icon": "healing",
    },
  ];

  Future<void> _makePhoneCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $number';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF416d6d),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: emergencyContacts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final contact = emergencyContacts[index];
            final icon = contact['icon'] ?? 'phone_in_talk';

            return InkWell(
              onTap: () => _makePhoneCall(contact['number'] ?? ''),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFc5d0d3),
                      child: Icon(
                        _getIconFromName(icon),
                        size: 28,
                        color: const Color(0xFF416d6d),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF416d6d),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact['number'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF608e8e),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.call,
                        size: 28,
                        color: Color(0xFF416d6d),
                      ),
                      onPressed: () => _makePhoneCall(contact['number'] ?? ''),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'security':
        return Icons.security;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'support':
        return Icons.support;
      case 'warning':
        return Icons.warning;
      case 'child_care':
        return Icons.child_care;
      case 'elderly':
        return Icons.elderly;
      case 'computer':
        return Icons.computer;
      case 'medical_services':
        return Icons.medical_services;
      case 'train':
        return Icons.train;
      case 'car_repair':
        return Icons.car_repair;
      case 'gas_meter':
        return Icons.gas_meter;
      case 'bloodtype':
        return Icons.bloodtype;
      case 'tour':
        return Icons.tour;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'agriculture':
        return Icons.agriculture;
      case 'healing':
        return Icons.healing;
      default:
        return Icons.phone_in_talk;
    }
  }
}
