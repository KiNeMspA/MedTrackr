// lib/screens/add_medication_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medtrackr/models/medication.dart';
import 'package:medtrackr/models/schedule.dart';
import 'package:medtrackr/models/dosage.dart';
import 'package:medtrackr/screens/add_dosage_screen.dart';
import 'package:medtrackr/screens/add_schedule_screen.dart';
import 'package:provider/provider.dart';
import 'package:medtrackr/providers/data_provider.dart';
import 'package:uuid/uuid.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  String _type = 'Injection';
  String? _storedIn;
  String _quantityUnit = 'mcg';
  final _quantityController = TextEditingController();
  bool _isReconstituting = false;
  final _targetDoseController = TextEditingController();
  String _targetDoseUnit = 'mcg';
  List<Map<String, dynamic>> _reconstitutionSuggestions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _targetDoseController.dispose();
    super.dispose();
  }

  void _calculateReconstitutionSuggestions() {
    final totalAmount = int.tryParse(_quantityController.text) ?? 0;
    final targetDose = double.tryParse(_targetDoseController.text) ?? 0;
    if (totalAmount <= 0 || targetDose <= 0 || _quantityUnit != 'mcg' || _targetDoseUnit != 'mcg') {
      setState(() => _reconstitutionSuggestions = []);
      return;
    }

    const volumes = [1.0, 2.0, 3.0, 4.0];
    final suggestions = <Map<String, dynamic>>[];
    for (final volume in volumes) {
      final concentration = (totalAmount * (_quantityUnit == 'mg' ? 1000 : 1)) / volume;
      final iuPerDose = (targetDose / concentration) * 100;
      if (iuPerDose >= 1 && iuPerDose <= 100) {
        suggestions.add({
          'volume': volume,
          'iu': iuPerDose,
          'concentration': concentration,
        });
      }
    }
    setState(() => _reconstitutionSuggestions = suggestions);
  }

  Future<void> _saveMedication(BuildContext context) async {
    if (_nameController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (_type == 'Injection' && _storedIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select how the medication is stored')),
      );
      return;
    }

    final medicationId = const Uuid().v4();
    final medication = Medication(
      id: medicationId,
      name: _nameController.text,
      type: _type,
      storageType: _type == 'Injection' || _type == 'Other' ? (_storedIn ?? '') : '',
      quantityUnit: _quantityUnit,
      quantity: int.tryParse(_quantityController.text)?.toDouble() ?? 0.0,
      remainingQuantity: int.tryParse(_quantityController.text)?.toDouble() ?? 0.0,
      reconstitutionVolumeUnit: _isReconstituting ? 'mL' : '',
      reconstitutionVolume: _isReconstituting && _reconstitutionSuggestions.isNotEmpty ? _reconstitutionSuggestions[0]['volume'] : 0.0,
    );

    Provider.of<DataProvider>(context, listen: false).addMedication(medication);

    final dosage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDosageScreen(medication: medication),
      ),
    );

    Navigator.pop(context, (medication, null, dosage));
  }

  @override
  Widget build(BuildContext context) {
    final isInjection = _type == 'Injection';
    final isTabletOrCapsule = _type == 'Tablet' || _type == 'Capsule';
    final storedInOptions = ['Syringe', 'Vial', 'Pen'];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Add Medication'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medication Details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medication Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Injection', 'Tablet', 'Capsule', 'Other']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _type = value!;
                  if (isTabletOrCapsule) {
                    _storedIn = null;
                  } else if (value == 'Injection') {
                    _storedIn = 'Vial';
                  } else {
                    _storedIn = 'Vial';
                  }
                }),
              ),
              if (!isTabletOrCapsule) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _storedIn,
                  decoration: InputDecoration(
                    labelText: 'Stored In${isInjection ? ' *' : ''}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFFFC107)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: storedInOptions
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _storedIn = value),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Total Medication Amount *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFFFC107)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _calculateReconstitutionSuggestions(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _quantityUnit,
                      decoration: InputDecoration(
                        labelText: 'Measure',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFFFC107)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['mcg', 'mg', 'mL', 'IU']
                          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _quantityUnit = value!;
                        _calculateReconstitutionSuggestions();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Reconstitute this medication?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  DropdownButton<bool>(
                    value: _isReconstituting,
                    items: [
                      DropdownMenuItem(value: true, child: Text('Yes')),
                      DropdownMenuItem(value: false, child: Text('No')),
                    ],
                    onChanged: (value) => setState(() {
                      _isReconstituting = value!;
                      if (!value) _reconstitutionSuggestions = [];
                    }),
                  ),
                ],
              ),
              if (_isReconstituting) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _targetDoseController,
                        decoration: InputDecoration(
                          labelText: 'Target Single Dosage (mcg) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFFFFC107)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateReconstitutionSuggestions(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _targetDoseUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFFFFC107)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['mcg']
                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _targetDoseUnit = value!;
                          _calculateReconstitutionSuggestions();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_reconstitutionSuggestions.isNotEmpty) ...[
                  const Text(
                    'Reconstitution Suggestions:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._reconstitutionSuggestions.map((suggestion) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Reconstitute with ${suggestion['volume']} mL to get ${suggestion['iu'].toStringAsFixed(1)} IU per ${suggestion['concentration'].toStringAsFixed(0)} mcg/mL',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )),
                ],
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _saveMedication(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Medication', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}