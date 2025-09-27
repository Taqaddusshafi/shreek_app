import 'dart:async'; // ✅ ADD: Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Add for kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart' as RideProvider;
import '../../providers/booking_provider.dart';
import '../../models/ride_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../rides/create_ride_screen.dart';

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

  // ✅ ADD: Debounce timer for search
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 1000); // Increased to 1 second

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ✅ FIXED: Load initial data method
  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      if (isAuthenticated) {
        ref.read(myBookingsProvider.notifier).loadMyBookings();
        
        // ✅ FIXED: Load all available rides initially using searchRides
        final allRidesParams = SearchParameters(
          fromCity: '',
          toCity: '',
          departureDate: '',
          limit: 50,
        );
        
        ref.read(RideProvider.rideSearchProvider.notifier).searchRides(allRidesParams);
      }
    });
  }

  // ✅ FIXED: Refresh data method
  Future<void> _refreshData() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      final user = ref.read(currentUserProvider);
      await Future.wait([
        ref.read(myBookingsProvider.notifier).loadMyBookings(refresh: true),
        if (_getUserIsDriver(user)) 
          ref.read(RideProvider.myRidesProvider.notifier).loadMyRides(refresh: true),
      ]);
      
      // ✅ FIXED: Refresh available rides using searchRides
      final refreshParams = SearchParameters(
        fromCity: '',
        toCity: '',
        departureDate: '',
        limit: 50,
      );
      
      ref.read(RideProvider.rideSearchProvider.notifier).searchRides(refreshParams);
    }
  }

  // ✅ FIXED: Debounced live search method
  void _performLiveSearch() {
    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();
    
    // Create a new timer
    _debounceTimer = Timer(_debounceDuration, () {
      // Only search if there's meaningful content
      if (_fromController.text.trim().isNotEmpty || _toController.text.trim().isNotEmpty) {
        // Check minimum length to avoid too many requests
        final fromText = _fromController.text.trim();
        final toText = _toController.text.trim();
        
        // Skip search if both fields have less than 2 characters
        if (fromText.isNotEmpty && fromText.length < 2 && toText.isNotEmpty && toText.length < 2) {
          return;
        }
        
        final searchParams = SearchParameters(
          fromCity: fromText.isEmpty ? '' : fromText,
          toCity: toText.isEmpty ? '' : toText,
          departureDate: _selectedDate?.toIso8601String().split('T')[0] ?? '',
          limit: 20,
        );

        if (kDebugMode) {
          print('🔍 Debounced search with params: '
              'fromCity=${searchParams.fromCity}, '
              'toCity=${searchParams.toCity}, '
              'departureDate=${searchParams.departureDate}, '
              'limit=${searchParams.limit}');
        }

        ref.read(RideProvider.rideSearchProvider.notifier).searchRides(searchParams);
      }
    });
  }

  // ✅ ADD: Method to cancel ongoing search requests
  void _cancelPendingSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshData, // ✅ Use the new method
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
                                GestureDetector(
                                  onTap: () => _showProfileMenu(context),
                                  child: CircleAvatar(
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
                    
                    // ✅ FIXED: Show search results preview
                    _buildSearchResultsPreview(),
                    
                    const SizedBox(height: 24),
                    
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
              
              // ✅ IMPROVED: TextField with debounced search and minimum length check
              TextField(
                controller: _fromController,
                style: const TextStyle(fontSize: 16),
                maxLength: 100,
                onChanged: (value) {
                  // Only trigger search if input has meaningful length (2+ characters) or is cleared
                  if (value.trim().length >= 2 || value.trim().isEmpty) {
                    _performLiveSearch();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'من',
                  hintText: 'نقطة الانطلاق',
                  prefixIcon: const Icon(Icons.my_location),
                  suffixIcon: _fromController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _fromController.clear();
                            _cancelPendingSearch();
                            setState(() {}); // Update UI
                            _performLiveSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                  counterText: '', // Hide character counter
                ),
              ),
              
              const SizedBox(height: 12),
              
              // ✅ IMPROVED: TextField with debounced search and minimum length check
              TextField(
                controller: _toController,
                style: const TextStyle(fontSize: 16),
                maxLength: 100,
                onChanged: (value) {
                  // Only trigger search if input has meaningful length (2+ characters) or is cleared
                  if (value.trim().length >= 2 || value.trim().isEmpty) {
                    _performLiveSearch();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'إلى',
                  hintText: 'الوجهة',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: _toController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _toController.clear();
                            _cancelPendingSearch();
                            setState(() {}); // Update UI
                            _performLiveSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                  counterText: '', // Hide character counter
                ),
              ),
              
              const SizedBox(height: 12),
              
              // ✅ Keep CustomTextField for date field (no onChanged needed)
              InkWell(
                onTap: _selectDate,
                child: IgnorePointer(
                  child: CustomTextField(
                    controller: _dateController,
                    labelText: 'التاريخ',
                    hintText: 'اختر تاريخ السفر',
                    prefixIcon: Icons.calendar_today,
                    maxLength: 50,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'البحث',
                      onPressed: _searchRides,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showAllRides,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('عرض الكل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Search results preview widget
  Widget _buildSearchResultsPreview() {
    return Consumer(
      builder: (context, ref, child) {
        final searchState = ref.watch(RideProvider.rideSearchProvider);
        
        if (searchState.rides.isEmpty) {
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
                      Icons.search,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الرحلات المتاحة (${searchState.rides.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _viewAllSearchResults,
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: searchState.rides.take(5).length,
                itemBuilder: (context, index) {
                  final ride = searchState.rides[index];
                  return _buildRidePreviewCard(ride);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Ride preview card
  Widget _buildRidePreviewCard(dynamic ride) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route
              Text(
                '${_getRideFromCity(ride)} → ${_getRideToCity(ride)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Date and time
              Text(
                _getRideDepartureTime(ride),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Price and seats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getRidePrice(ride)} ر.س',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getRideAvailableSeats(ride)} مقعد',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Book button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('احجز الآن', style: TextStyle(fontSize: 12)),
                ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'حجوزات الرحلات',
                    Icons.event_note,
                    Colors.green,
                    () => _viewDriverBookings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'إحصائيات',
                    Icons.analytics,
                    Colors.orange,
                    () => _viewStats(),
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
        
        final upcomingBookings = bookingsState.bookings
            .where((b) => _isUpcomingBooking(b))
            .take(3)
            .toList();

        if (upcomingBookings.isEmpty && !bookingsState.isLoading) {
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
            if (bookingsState.isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (upcomingBookings.isNotEmpty) ...[
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
                    Expanded(
                      child: Text(
                        'حجز #${_getBookingId(booking)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      {'from': 'الطائف', 'to': 'الرياض', 'price': '140', 'rides': '25'},
      {'from': 'القصيم', 'to': 'الرياض', 'price': '90', 'rides': '18'},
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
              setState(() {}); // Update UI to show clear buttons
              _performLiveSearch(); // Trigger search with debounce
            },
          ),
        )),
      ],
    );
  }

  // Helper methods remain the same as in your original file...
  // [All helper methods from _getRideFromCity to _showProfileMenu remain unchanged]

  String _getRideFromCity(dynamic ride) {
    try {
      return ride.fromCity ?? ride.from_city ?? ride.fromLocation ?? 'غير محدد';
    } catch (e) {
      return 'غير محدد';
    }
  }

  String _getRideToCity(dynamic ride) {
    try {
      return ride.toCity ?? ride.to_city ?? ride.toLocation ?? 'غير محدد';
    } catch (e) {
      return 'غير محدد';
    }
  }

  String _getRideDepartureTime(dynamic ride) {
    try {
      final dateTime = ride.departureTime ?? ride.departure_time;
      if (dateTime == null) return 'غير محدد';
      
      DateTime parsedDate;
      if (dateTime is String) {
        parsedDate = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        parsedDate = dateTime;
      } else {
        return 'غير محدد';
      }
      
      return '${parsedDate.day}/${parsedDate.month} - ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  String _getRidePrice(dynamic ride) {
    try {
      final price = ride.pricePerSeat ?? ride.price_per_seat ?? ride.price ?? 0;
      return price.toString();
    } catch (e) {
      return '0';
    }
  }

  int _getRideAvailableSeats(dynamic ride) {
    try {
      return ride.availableSeats ?? ride.available_seats ?? ride.seats ?? 0;
    } catch (e) {
      return 0;
    }
  }

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
      return booking.pickupLocation ?? 
             booking.fromLocation ?? 
             booking.ride?.fromCity ?? 
             booking.rideFromCity ?? 
             'مكان الانطلاق';
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
        case 'rejected':
          return Colors.red.shade300;
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
      case 'rejected':
        return 'مرفوض';
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
      
      _performLiveSearch();
    }
  }

  void _searchRides() {
    // Cancel any pending search first
    _cancelPendingSearch();
    
    if (_fromController.text.isEmpty && _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('يرجى تحديد نقطة الانطلاق أو الوجهة على الأقل'),
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

    final searchParams = SearchParameters(
      fromCity: _fromController.text.trim().isEmpty ? '' : _fromController.text.trim(),
      toCity: _toController.text.trim().isEmpty ? '' : _toController.text.trim(),
      departureDate: _selectedDate?.toIso8601String().split('T')[0] ?? '',
      limit: 50,
    );

    if (kDebugMode) {
      print('🔍 Searching with params: '
          'fromCity=${searchParams.fromCity}, '
          'toCity=${searchParams.toCity}, '
          'departureDate=${searchParams.departureDate}, '
          'limit=${searchParams.limit}');
    }

    ref.read(RideProvider.rideSearchProvider.notifier).searchRides(searchParams);
    
    // Navigate to rides tab
    _viewAllSearchResults();

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

  void _showAllRides() {
    // Cancel any pending search first
    _cancelPendingSearch();
    
    if (kDebugMode) {
      print('🔍 Loading all available rides');
    }

    final searchParams = SearchParameters(
      fromCity: '',
      toCity: '',
      departureDate: '',
      limit: 100,
    );

    ref.read(RideProvider.rideSearchProvider.notifier).searchRides(searchParams);
    
    _viewAllSearchResults();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 8),
            Text('جاري تحميل جميع الرحلات المتاحة...'),
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

  void _viewAllSearchResults() {
    try {
      final tabController = DefaultTabController.of(context);
      tabController?.animateTo(1);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DefaultTabController not found: $e');
      }
    }
  }

  void _bookRide(dynamic ride) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('حجز رحلة ${_getRideFromCity(ride)} → ${_getRideToCity(ride)}'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _createRide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateRideScreen(),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(RideProvider.myRidesProvider.notifier).loadMyRides(refresh: true);
        
        final refreshParams = SearchParameters(
          fromCity: '',
          toCity: '',
          departureDate: '',
          limit: 50,
        );
        
        ref.read(RideProvider.rideSearchProvider.notifier).searchRides(refreshParams);
      }
    });
  }

  void _viewMyRides() {
    try {
      final tabController = DefaultTabController.of(context);
      tabController?.animateTo(1);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DefaultTabController not found: $e');
      }
    }
  }

  void _viewAllBookings() {
    try {
      final tabController = DefaultTabController.of(context);
      tabController?.animateTo(2);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ DefaultTabController not found: $e');
      }
    }
  }

  void _viewDriverBookings() {
    ref.read(myBookingsProvider.notifier).loadDriverBookings(refresh: true);
    _viewAllBookings();
  }

  void _viewStats() {
    ref.read(myBookingsProvider.notifier).loadBookingStats();
    _showStatsBottomSheet();
  }

  void _showStatsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final stats = ref.watch(bookingStatsProvider);
          
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إحصائيات سريعة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (stats != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('إجمالي الحجوزات', stats['totalBookings']?.toString() ?? '0'),
                      _buildStatItem('الحجوزات المؤكدة', stats['confirmedBookings']?.toString() ?? '0'),
                      _buildStatItem('الحجوزات المكتملة', stats['completedBookings']?.toString() ?? '0'),
                    ],
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // ✅ IMPORTANT: Cancel timer when disposing
    _debounceTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
