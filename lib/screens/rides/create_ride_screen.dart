import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shreek_app/core/constants/app_colors.dart';
import 'package:shreek_app/core/widgets/custom_button.dart';
import 'package:shreek_app/core/widgets/custom_text_field.dart';
import 'package:shreek_app/models/ride_model.dart';
import 'package:shreek_app/providers/auth_provider.dart';
import 'package:shreek_app/providers/ride_provider.dart';

class CreateRideScreen extends ConsumerStatefulWidget {
  const CreateRideScreen({super.key});

  @override
  ConsumerState<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends ConsumerState<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _fromCityController = TextEditingController();
  final _fromAddressController = TextEditingController();
  final _toCityController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form state
  DateTime? _selectedDateTime;
  bool _isFemaleOnly = false;
  
  // Default coordinates (you can add location picker later)
  double _fromLatitude = 24.7136; // Riyadh default
  double _fromLongitude = 46.6753;
  double _toLatitude = 21.4858; // Jeddah default
  double _toLongitude = 39.1925;

  @override
  void initState() {
    super.initState();
    // Set default values
    _seatsController.text = '3';
    _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  }

  @override
  Widget build(BuildContext context) {
    final myRidesState = ref.watch(myRidesProvider);
    final authState = ref.watch(authProvider);
    
    // ✅ FIXED: Proper user access
    final user = authState.user;
    final isDriver = user?.isDriver ?? false;
    
    // Listen to ride creation state
    ref.listen<RideState>(myRidesProvider, (previous, next) {
      if (previous?.isCreating == true && next.isCreating == false) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(next.error!)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'إغلاق',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ref.read(myRidesProvider.notifier).clearError();
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('تم إنشاء الرحلة بنجاح!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          Navigator.of(context).pop(true);
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إنشاء رحلة جديدة'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (myRidesState.isCreating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ FIXED: Driver verification check
              if (!isDriver) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'حساب سائق مطلوب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'يجب أن يكون لديك حساب سائق لإنشاء رحلات. يرجى التواصل مع الدعم الفني لتفعيل حسابك كسائق.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _showDriverRegistrationDialog,
                        icon: const Icon(Icons.contact_support, size: 16),
                        label: const Text('تواصل مع الدعم'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Route section
              _buildSectionHeader('معلومات المسار', Icons.route),
              const SizedBox(height: 16),
              _buildRouteSection(),
              const SizedBox(height: 24),
              
              // Trip details section
              _buildSectionHeader('تفاصيل الرحلة', Icons.info_outline),
              const SizedBox(height: 16),
              _buildTripDetailsSection(),
              const SizedBox(height: 32),
              
              // Create button
              CustomButton(
                text: 'إنشاء الرحلة',
                onPressed: isDriver && !myRidesState.isCreating 
                    ? _createRide 
                    : null,
                isLoading: myRidesState.isCreating,
              ),
              
              const SizedBox(height: 16),
              
              // Debug info (only in debug mode)
              if (kDebugMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('User: ${user?.name ?? 'null'}'),
                      Text('Is Driver: $isDriver'),
                      Text('Is Creating: ${myRidesState.isCreating}'),
                      Text('Selected DateTime: $_selectedDateTime'),
                      Text('Error: ${myRidesState.error ?? 'null'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection() {
    return Column(
      children: [
        // From location
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'من',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _fromCityController,
                labelText: 'المدينة',
                hintText: 'مثال: الرياض',
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'مدينة المغادرة مطلوبة';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _fromAddressController,
                labelText: 'العنوان التفصيلي',
                hintText: 'مثال: شارع الملك فهد',
                prefixIcon: Icons.place,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'عنوان المغادرة مطلوب';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Connection line
        Row(
          children: [
            const SizedBox(width: 6),
            Container(
              width: 2,
              height: 24,
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // To location
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'إلى',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _toCityController,
                labelText: 'المدينة',
                hintText: 'مثال: جدة',
                prefixIcon: Icons.location_city,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'مدينة الوصول مطلوبة';
                  }
                  if (value?.trim() == _fromCityController.text.trim()) {
                    return 'مدينة الوصول يجب أن تختلف عن المغادرة';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _toAddressController,
                labelText: 'العنوان التفصيلي',
                hintText: 'مثال: شارع التحلية',
                prefixIcon: Icons.place,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'عنوان الوصول مطلوب';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripDetailsSection() {
    return Column(
      children: [
        // Date and time picker
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تاريخ ووقت المغادرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateTime != null
                            ? DateFormat('EEEE، d MMMM y - HH:mm').format(_selectedDateTime!)
                            : 'اختر التاريخ والوقت',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDateTime != null 
                              ? Colors.black87
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Available seats
            Expanded(
              child: CustomTextField(
                controller: _seatsController,
                labelText: 'عدد المقاعد المتاحة',
                hintText: '1-8',
                prefixIcon: Icons.airline_seat_recline_normal,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'عدد المقاعد مطلوب';
                  }
                  final seats = int.tryParse(value!);
                  if (seats == null || seats < 1 || seats > 8) {
                    return 'يجب أن يكون بين 1-8';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Price per seat
            Expanded(
              child: CustomTextField(
                controller: _priceController,
                labelText: 'سعر المقعد (ريال)',
                hintText: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'سعر المقعد مطلوب';
                  }
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) {
                    return 'السعر يجب أن يكون رقماً صحيحاً';
                  }
                  if (price > 10000) {
                    return 'السعر مرتفع جداً';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Description
        CustomTextField(
          controller: _descriptionController,
          labelText: 'وصف الرحلة (اختياري)',
          hintText: 'أضف وصفاً للرحلة...',
          prefixIcon: Icons.description,
          maxLines: 3,
          maxLength: 500,
        ),
        
        const SizedBox(height: 16),
        
        // Female only switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFemaleOnly 
                  ? Colors.pink.shade200 
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.female,
                color: Colors.pink.shade600,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رحلة نسائية فقط',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'هذه الرحلة للنساء فقط',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isFemaleOnly,
                onChanged: (value) {
                  setState(() {
                    _isFemaleOnly = value;
                  });
                },
                activeColor: Colors.pink.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now.add(const Duration(hours: 2));
    
    // Date picker
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate == null) return;
    
    // Time picker
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedTime == null) return;
    
    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    if (combined.isBefore(now.add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('يجب أن يكون وقت المغادرة بعد ساعة على الأقل من الآن'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _selectedDateTime = combined;
    });
  }

  // ✅ FIXED: Complete ride creation method with proper validation
  Future<void> _createRide() async {
    final user = ref.read(authProvider).user;
    
    // ✅ Check user authentication
    if (user == null) {
      _showErrorDialog('يجب تسجيل الدخول أولاً');
      return;
    }

    // ✅ Check driver privileges
    if (!user.isDriver) {
      _showDriverRegistrationDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('يرجى اختيار تاريخ ووقت المغادرة'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    
    try {
      // ✅ FIXED: Create request matching your API exactly
      final request = CreateRideRequest(
        from: {
          'city': _fromCityController.text.trim(),
          'address': _fromAddressController.text.trim(),
          'coordinates': {
            'lat': _fromLatitude,
            'lng': _fromLongitude,
          },
        },
        to: {
          'city': _toCityController.text.trim(),
          'address': _toAddressController.text.trim(),
          'coordinates': {
            'lat': _toLatitude,
            'lng': _toLongitude,
          },
        },
        departureTime: _selectedDateTime!.toIso8601String(),
        availableSeats: int.parse(_seatsController.text),
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isFemaleOnly: _isFemaleOnly,
      );
      
      if (kDebugMode) {
        print('🚗 Creating ride with request: ${request.toJson()}');
        print('👤 User is driver: ${user.isDriver}');
      }
      
      final success = await ref.read(myRidesProvider.notifier).createRide(request);
      
      if (kDebugMode) {
        print('🚗 Create ride result: $success');
      }
      
      // Success/error handling is done in the listener
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _createRide: $e');
      }
      
      _showErrorDialog('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // ✅ NEW: Show driver registration dialog
  void _showDriverRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.orange),
            SizedBox(width: 8),
            Text('تفعيل حساب السائق'),
          ],
        ),
        content: const Text(
          'يجب أن يكون لديك حساب سائق مفعل لإنشاء الرحلات. يرجى التواصل مع الدعم الفني لتفعيل حسابك كسائق.\n\n'
          'سيحتاج الدعم الفني إلى التحقق من:\n'
          '• رخصة القيادة\n'
          '• بيانات المركبة\n'
          '• الهوية الشخصية',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _contactSupport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('تواصل مع الدعم'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Contact support method
  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.contact_support, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('تواصل مع الدعم'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'للحصول على حساب سائق، يرجى التواصل معنا على:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('الهاتف: 123456789', style: TextStyle(fontSize: 14)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text('البريد الإلكتروني: support@shareek.com', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('ساعات العمل: 8:00 - 20:00', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Enhanced error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fromCityController.dispose();
    _fromAddressController.dispose();
    _toCityController.dispose();
    _toAddressController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// ✅ User model looks correct - no changes needed
class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? nationality;
  final String? city;
  final String? currentAddress;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? bio;
  final bool isDriver;
  final bool isActive;
  final bool phoneVerified;
  final bool emailVerified;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.nationality,
    this.city,
    this.currentAddress,
    this.state,
    this.postalCode,
    this.country,
    this.bio,
    required this.isDriver,
    required this.isActive,
    required this.phoneVerified,
    required this.emailVerified,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      nationality: json['nationality'],
      city: json['city'],
      currentAddress: json['currentAddress'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      bio: json['bio'],
      isDriver: json['isDriver'] ?? false,
      isActive: json['isActive'] ?? true,
      phoneVerified: json['phoneVerified'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'city': city,
      'currentAddress': currentAddress,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'bio': bio,
      'isDriver': isDriver,
      'isActive': isActive,
      'phoneVerified': phoneVerified,
      'emailVerified': emailVerified,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? nationality,
    String? city,
    String? currentAddress,
    String? state,
    String? postalCode,
    String? country,
    String? bio,
    bool? isDriver,
    bool? isActive,
    bool? phoneVerified,
    bool? emailVerified,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      city: city ?? this.city,
      currentAddress: currentAddress ?? this.currentAddress,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      isDriver: isDriver ?? this.isDriver,
      isActive: isActive ?? this.isActive,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Convenience getters
  String get fullName => name;
  double? get rating => null; // Will be calculated from ratings
  String get firstName => name.split(' ').first;
  String get lastName => name.split(' ').length > 1 ? name.split(' ').last : '';
  bool get isPassenger => !isDriver;
}
