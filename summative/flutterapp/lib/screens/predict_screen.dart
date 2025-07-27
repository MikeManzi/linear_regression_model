import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  _PredictScreenState createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _regionController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _cropController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weatherController = TextEditingController();
  final _daysToHarvestController = TextEditingController();

  final _regionFocus = FocusNode();
  final _soilTypeFocus = FocusNode();
  final _cropFocus = FocusNode();
  final _rainfallFocus = FocusNode();
  final _temperatureFocus = FocusNode();
  final _weatherFocus = FocusNode();
  final _daysToHarvestFocus = FocusNode();

  String? _fertilizerUsed = 'TRUE';
  String? _irrigationUsed = 'FALSE';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _showResultsDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 20,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[50]!, Colors.white],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 32,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Predicted Yield',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green[300]!.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _predict() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const String apiUrl =
        'https://linear-regression-model-aef5.onrender.com/api/v1/predict-yield';

    final Map<String, dynamic> data = {
      'Region': _regionController.text,
      'Soil_Type': _soilTypeController.text,
      'Crop': _cropController.text,
      'Rainfall_mm': double.tryParse(_rainfallController.text) ?? 0,
      'Temperature_Celsius': double.tryParse(_temperatureController.text) ?? 0,
      'Fertilizer_Used': _fertilizerUsed ?? 'TRUE',
      'Irrigation_Used': _irrigationUsed ?? 'FALSE',
      'Weather_Condition': _weatherController.text,
      'Days_to_Harvest': int.tryParse(_daysToHarvestController.text) ?? 0,
    };

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final predictedYield = result['predicted_yield_tons_per_hectare'];

        _showResultsDialog(
          '${predictedYield?.toStringAsFixed(2) ?? 'N/A'} tons/ha',
        );
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(
          'Error: ${response.statusCode}',
          responseData['error_message']?.toString() ?? 'Unknown error',
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to connect', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white, Colors.green[50]!],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.green[600],
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [
                                          Colors.green[600]!,
                                          Colors.green[800]!,
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'SmartHinga',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Predict your crop yield with ease',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const SizedBox(
                              width: 48,
                            ), // Balance the back button
                          ],
                        ),
                      ),

                      // Form Sections
                      _buildSectionCard(
                        'Location Information',
                        Icons.location_on,
                        [
                          _buildTextField(
                            _regionController,
                            'Region',
                            'e.g., North',
                            focusNode: _regionFocus,
                            nextFocus: _soilTypeFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a region';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            _soilTypeController,
                            'Soil Type',
                            'e.g., Loam',
                            focusNode: _soilTypeFocus,
                            nextFocus: _cropFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a soil type';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      _buildSectionCard('Crop Details', Icons.grass, [
                        _buildTextField(
                          _cropController,
                          'Crop',
                          'e.g., Wheat',
                          focusNode: _cropFocus,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a crop';
                            }
                            return null;
                          },
                        ),
                        _buildDropdown(
                          'Fertilizer Used',
                          ['TRUE', 'FALSE'],
                          _fertilizerUsed,
                          (value) {
                            setState(() => _fertilizerUsed = value);
                          },
                        ),
                        _buildDropdown(
                          'Irrigation Used',
                          ['TRUE', 'FALSE'],
                          _irrigationUsed,
                          (value) {
                            setState(() => _irrigationUsed = value);
                          },
                        ),
                      ]),

                      _buildSectionCard(
                        'Environmental Conditions',
                        Icons.wb_sunny,
                        [
                          _buildTextField(
                            _rainfallController,
                            'Rainfall (mm)',
                            'e.g., 500',
                            keyboardType: TextInputType.number,
                            focusNode: _rainfallFocus,
                            nextFocus: _temperatureFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter rainfall';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            _temperatureController,
                            'Temperature (°C)',
                            'e.g., 25',
                            keyboardType: TextInputType.number,
                            focusNode: _temperatureFocus,
                            nextFocus: _weatherFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter temperature';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            _weatherController,
                            'Weather Condition',
                            'e.g., Sunny',
                            focusNode: _weatherFocus,
                            nextFocus: _daysToHarvestFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a weather condition';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            _daysToHarvestController,
                            'Days to Harvest',
                            'e.g., 120',
                            keyboardType: TextInputType.number,
                            focusNode: _daysToHarvestFocus,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter days to harvest';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Predict Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green[600]!.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.analytics, size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Predict Yield',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.green[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.green[500]!, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            keyboardType: keyboardType ?? TextInputType.text,
            validator: validator,
            onFieldSubmitted: (value) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.green[500]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            items:
                options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null) {
                return 'Please select an option';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _regionController.dispose();
    _soilTypeController.dispose();
    _cropController.dispose();
    _rainfallController.dispose();
    _temperatureController.dispose();
    _weatherController.dispose();
    _daysToHarvestController.dispose();
    _regionFocus.dispose();
    _soilTypeFocus.dispose();
    _cropFocus.dispose();
    _rainfallFocus.dispose();
    _temperatureFocus.dispose();
    _weatherFocus.dispose();
    _daysToHarvestFocus.dispose();
    super.dispose();
  }
}
