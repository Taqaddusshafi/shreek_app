import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart' as RideProvider;
import '../../providers/booking_provider.dart';
import '../../models/ride_model.dart' hide SearchParameters;
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (isAuthenticated) {
        ref.read(myBookingsProvider.notifier).loadMyBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          if (authState.isAuthenticated) {
            await ref.read(myBookingsProvider.notifier).loadMyBookings();
          }
        },
        color: AppColors.primaryColor,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                size: 32,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Shareek',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              if (user != null) ...[
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: _getUserProfileImage(user),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: _getUserProfileImage(user) == null
                                      ? Text(
                                          _getUserInitial(user),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user != null ? 'مرحباً، ${_getUserFirstName(user)}!' : 'مرحباً بك!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'إلى أين تريد أن تذهب اليوم؟',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Card
                    _buildSearchCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions for Drivers
                    if (user != null && _getUserIsDriver(user)) ...[
                      _buildDriverQuickActions(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Upcoming Bookings
                    _buildUpcomingBookings(),
                    
                    const SizedBox(height: 24),
                    
                    // Stats Card
                    if (user != null) _buildUserStatsCard(user),
                    
                    const SizedBox(height: 24),
                    
                    // Popular Routes
                    _buildPopularRoutes(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'البحث عن رحلة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _fromController,
                labelText: 'من',
                hintText: 'نقطة الانطلاق',
                prefixIcon: Icons.my_location,
                maxLength: 100,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _toController,
                labelText: 'إلى',
                hintText: 'الوجهة',
                prefixIcon: Icons.location_on,
                maxLength: 100,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: CustomTextField(
                  controller: _dateController,
                  labelText: 'التاريخ',
                  hintText: 'اختر تاريخ السفر',
                  prefixIcon: Icons.calendar_today,
                  enabled: false,
                  maxLength: 50,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'البحث',
                onPressed: _searchRides,
                icon: Icons.search,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'إنشاء رحلة',
                    Icons.add_road,
                    AppColors.primaryColor,
                    () => _createRide(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'رحلاتي',
                    Icons.directions_car,
                    Colors.blue,
                    () => _viewMyRides(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingsState = ref.watch(myBookingsProvider);
        
        // ✅ FIXED: Safe filtering of bookings
        final upcomingBookings = bookingsState.bookings
            .where((b) => _isUpcomingBooking(b))
            .take(3)
            .toList();

        if (upcomingBookings.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الحجوزات القادمة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _viewAllBookings(),
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingBookings.length,
                itemBuilder: (context, index) {
                  final booking = upcomingBookings[index];
                  return _buildBookingCard(booking);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حجز #${_getBookingId(booking)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getBookingStatusColor(booking).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getBookingStatusDisplayText(booking),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getBookingStatusColor(booking),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getBookingLocation(booking),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getBookingSeats(booking)} مقعد',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_getBookingPrice(booking)} ر.س',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatsCard(dynamic user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _getUserProfileImage(user),
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                child: _getUserProfileImage(user) == null
                    ? Text(
                        _getUserInitial(user),
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getUserFullName(user),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_getUserRating(user) != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            _getUserRating(user)!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_getUserTotalRides(user)} رحلة)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getUserRole(user),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularRoutes() {
    final routes = [
      {'from': 'الرياض', 'to': 'جدة', 'price': '150', 'rides': '45'},
      {'from': 'الدمام', 'to': 'الرياض', 'price': '120', 'rides': '32'},
      {'from': 'مكة', 'to': 'المدينة', 'price': '100', 'rides': '28'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: AppColors.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'الوجهات الشائعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...routes.map((route) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.route,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              '${route['from']} → ${route['to']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${route['rides']} رحلة متاحة'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'من ${route['price']} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'للمقعد',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            onTap: () {
              _fromController.text = route['from']!;
              _toController.text = route['to']!;
              _searchRides();
            },
          ),
        )),
      ],
    );
  }

  // ✅ FIXED: Helper methods for safe user property access
  ImageProvider? _getUserProfileImage(dynamic user) {
    if (user == null) return null;
    try {
      final image = user.profileImage ?? user.avatar ?? user.profileImageUrl;
      return image != null ? NetworkImage(image) : null;
    } catch (e) {
      return null;
    }
  }

  String _getUserInitial(dynamic user) {
    if (user == null) return 'U';
    try {
      final firstName = user.firstName ?? user.name ?? '';
      return firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    } catch (e) {
      return 'U';
    }
  }

  String _getUserFirstName(dynamic user) {
    if (user == null) return 'مستخدم';
    try {
      return user.firstName ?? user.name?.split(' ')[0] ?? 'مستخدم';
    } catch (e) {
      return 'مستخدم';
    }
  }

  String _getUserFullName(dynamic user) {
    if (user == null) return 'مستخدم';
    try {
      if (user.fullName != null) return user.fullName;
      
      final firstName = user.firstName ?? '';
      final lastName = user.lastName ?? '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        return '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        return firstName;
      } else if (user.name != null) {
        return user.name;
      }
      
      return 'مستخدم';
    } catch (e) {
      return 'مستخدم';
    }
  }

  double? _getUserRating(dynamic user) {
    if (user == null) return null;
    try {
      final rating = user.rating;
      return rating != null ? rating.toDouble() : null;
    } catch (e) {
      return null;
    }
  }

  int _getUserTotalRides(dynamic user) {
    if (user == null) return 0;
    try {
      return user.totalRides ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _getUserRole(dynamic user) {
    if (user == null) return 'راكب';
    try {
      final isDriver = user.isDriver ?? false;
      return isDriver ? 'سائق' : 'راكب';
    } catch (e) {
      return 'راكب';
    }
  }

  bool _getUserIsDriver(dynamic user) {
    if (user == null) return false;
    try {
      return user.isDriver ?? false;
    } catch (e) {
      return false;
    }
  }

  // ✅ FIXED: Booking helper methods with safe property access
  bool _isUpcomingBooking(dynamic booking) {
    try {
      final status = booking.status ?? '';
      return status == 'confirmed' || status == 'pending';
    } catch (e) {
      return false;
    }
  }

  String _getBookingId(dynamic booking) {
    try {
      return booking.id?.toString() ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getBookingLocation(dynamic booking) {
    try {
      return booking.pickupLocation ?? 'مكان الانطلاق';
    } catch (e) {
      return 'مكان الانطلاق';
    }
  }

  int _getBookingSeats(dynamic booking) {
    try {
      return booking.seatsBooked ?? booking.seats ?? 1;
    } catch (e) {
      return 1;
    }
  }

  String _getBookingPrice(dynamic booking) {
    try {
      final price = booking.totalPrice ?? booking.price ?? 0;
      return price.toString();
    } catch (e) {
      return '0';
    }
  }

  String _getBookingStatusDisplayText(dynamic booking) {
    try {
      final status = booking.status ?? '';
      return booking.statusDisplayText ?? _getBookingStatusText(status);
    } catch (e) {
      return 'غير محدد';
    }
  }

  Color _getBookingStatusColor(dynamic booking) {
    try {
      final status = booking.status ?? '';
      switch (status) {
        case 'pending':
          return Colors.orange;
        case 'confirmed':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        case 'completed':
          return Colors.blue;
        default:
          return AppColors.textSecondary;
      }
    } catch (e) {
      return AppColors.textSecondary;
    }
  }

  String _getBookingStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغى';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  // ✅ FIXED: _searchRides method with correct parameter names
  void _searchRides() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('يرجى تحديد نقطة الانطلاق والوجهة'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // ✅ FIXED: Use correct parameter names for SearchParameters
    final searchParams = RideProvider.SearchParameters(
      fromCity: _fromController.text.trim(),
      toCity: _toController.text.trim(),
      departureDate: _selectedDate?.toIso8601String().split('T')[0],
      limit: 20, // Optional: Set a reasonable limit
    );

    ref.read(RideProvider.rideSearchProvider.notifier).searchRides(searchParams);
    
    // Navigate to rides tab
    final tabController = DefaultTabController.of(context);
    if (tabController != null) {
      tabController.animateTo(1); // Navigate to rides tab
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.search, color: Colors.white),
            SizedBox(width: 8),
            Text('جاري البحث عن الرحلات...'),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _createRide() {
    Navigator.of(context).pushNamed('/create-ride');
  }

  void _viewMyRides() {
    final tabController = DefaultTabController.of(context);
    if (tabController != null) {
      tabController.animateTo(1); // Navigate to rides tab
    }
  }

  void _viewAllBookings() {
    final tabController = DefaultTabController.of(context);
    if (tabController != null) {
      tabController.animateTo(2); // Navigate to bookings tab
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
