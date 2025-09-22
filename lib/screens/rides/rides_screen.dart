import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/ride_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';

class RidesScreen extends ConsumerStatefulWidget {
  const RidesScreen({super.key});

  @override
  ConsumerState<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends ConsumerState<RidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (_getUserIsDriver(user)) {
        ref.read(myRidesProvider.notifier).loadMyRides();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      final searchState = ref.read(rideSearchProvider);
      if (searchState.hasMore && !searchState.isLoading) {
        ref.read(rideSearchProvider.notifier).loadMoreRides();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDriver = _getUserIsDriver(user);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isDriver ? 'رحلاتي' : 'البحث عن رحلة'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: isDriver ? 'رحلاتي النشطة' : 'نتائج البحث'),
            Tab(text: isDriver ? 'الرحلات المكتملة' : 'المفضلة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isDriver ? _buildMyRidesTab() : _buildSearchResultsTab(),
          isDriver ? _buildCompletedRidesTab() : _buildFavoritesTab(),
        ],
      ),
      floatingActionButton: isDriver
          ? FloatingActionButton(
              onPressed: _createNewRide,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMyRidesTab() {
    final ridesState = ref.watch(myRidesProvider);
    
    if (ridesState.isLoading) {
      return const LoadingWidget(message: 'جاري تحميل رحلاتك...');
    }
    
    if (ridesState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              ridesState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(myRidesProvider.notifier).loadMyRides();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    
    if (ridesState.rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'ليس لديك رحلات نشطة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'انقر على + لإنشاء رحلة جديدة',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: ridesState.rides.length,
      itemBuilder: (context, index) {
        final ride = ridesState.rides[index];
        return _buildRideCard(ride, isMyRide: true);
      },
    );
  }

  Widget _buildSearchResultsTab() {
    final searchState = ref.watch(rideSearchProvider);
    
    if (searchState.rides.isEmpty && !searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'ابحث عن رحلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'استخدم نموذج البحث في الصفحة الرئيسية',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    if (searchState.isLoading && searchState.rides.isEmpty) {
      return const LoadingWidget(message: 'جاري البحث عن الرحلات...');
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: searchState.rides.length + (searchState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == searchState.rides.length) {
          return const LoadingWidget();
        }
        
        final ride = searchState.rides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildCompletedRidesTab() {
    return const Center(
      child: Text('الرحلات المكتملة'),
    );
  }

  Widget _buildFavoritesTab() {
    return const Center(
      child: Text('المفضلة'),
    );
  }

  Widget _buildRideCard(Ride ride, {bool isMyRide = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onRideTap(ride),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.fromLocation, // ✅ FIXED: Using getter
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ride.toLocation, // ✅ FIXED: Using getter
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ride.price.toStringAsFixed(0)} ريال', // ✅ FIXED: Using getter
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRideTypeColor(ride.rideType).withOpacity(0.1), // ✅ FIXED: Using getter
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ride.rideTypeDisplayText, // ✅ FIXED: Using getter
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRideTypeColor(ride.rideType), // ✅ FIXED: Using getter
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Time and Date
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ride.departureDate.day}/${ride.departureDate.month} - ${ride.departureTimeString}', // ✅ FIXED: Using getters
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.event_seat,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.seatsAvailable}/${ride.totalSeats}', // ✅ FIXED: Using properties and getters
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              if (!isMyRide) ...[
                const SizedBox(height: 16),
                // Driver Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: _getDriverProfileImage(ride),
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: _getDriverProfileImage(ride) == null
                          ? Text(
                              _getDriverInitial(ride),
                              style: const TextStyle(color: AppColors.primaryColor),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDriverFullName(ride),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_getDriverRating(ride) != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getDriverRating(ride)!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Check if seats available before showing book button
                    ride.seatsAvailable > 0 // ✅ FIXED: Using property directly
                        ? ElevatedButton(
                            onPressed: () => _bookRide(ride),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('احجز'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'مكتملة',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ],
                ),
              ],

              // Action buttons for driver's own rides
              if (isMyRide) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _editRide(ride),
                        child: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelRide(ride),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorColor,
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _completeRide(ride),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('إكمال'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Simplified helper methods using model properties
  bool _getUserIsDriver(dynamic user) {
    if (user == null) return false;
    return user.isDriver ?? false;
  }

  Color _getRideTypeColor(String rideType) {
    switch (rideType) {
      case 'female_only':
        return Colors.pink;
      case 'male_only':
        return Colors.blue;
      case 'mixed':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  // ✅ FIXED: Driver helper methods using the DriverInfo class
  ImageProvider? _getDriverProfileImage(Ride ride) {
    final image = ride.driver.profileImage;
    return image != null ? NetworkImage(image) : null;
  }

  String _getDriverInitial(Ride ride) {
    final firstName = ride.driver.firstName;
    return firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';
  }

  String _getDriverFullName(Ride ride) {
    return ride.driver.fullName;
  }

  double? _getDriverRating(Ride ride) {
    return ride.driver.rating;
  }

  void _onRideTap(Ride ride) {
    Navigator.of(context).pushNamed('/ride-details', arguments: ride.id);
  }

  void _bookRide(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => _buildBookingDialog(ride),
    );
  }

  Widget _buildBookingDialog(Ride ride) {
    int selectedSeats = 1;
    final pickupController = TextEditingController();
    final notesController = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حجز الرحلة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route info
              Text(
                '${ride.fromLocation} → ${ride.toLocation}', // ✅ FIXED: Using getters
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Seats selection
              Row(
                children: [
                  const Text('عدد المقاعد:'),
                  const Spacer(),
                  DropdownButton<int>(
                    value: selectedSeats,
                    items: List.generate(
                      ride.seatsAvailable, // ✅ FIXED: Using property directly
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedSeats = value!;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pickup location input
              const Text(
                'نقطة الالتقاء:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pickupController,
                decoration: const InputDecoration(
                  hintText: 'أدخل نقطة الالتقاء المفضلة لك',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Notes input
              const Text(
                'ملاحظات (اختياري):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  hintText: 'أي ملاحظات إضافية...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Total price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'المجموع: ${(ride.price * selectedSeats).toStringAsFixed(0)} ريال', // ✅ FIXED: Using getter
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: pickupController.text.trim().isEmpty
                ? null
                : () {
                    Navigator.of(context).pop();
                    _confirmBooking(
                      ride.id,
                      selectedSeats,
                      pickupController.text.trim(),
                      notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                  },
            child: const Text('تأكيد الحجز'),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(
    int rideId,
    int seats, 
    String pickupLocation,
    String? notes,
  ) async {
    try {
      final success = await ref.read(myBookingsProvider.notifier).bookRide(
        rideId: rideId,
        seatsBooked: seats,
        pickupLocation: pickupLocation,
        pickupLatitude: 0.0,
        pickupLongitude: 0.0,
        notes: notes,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حجز الرحلة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh search results
        final searchState = ref.read(rideSearchProvider);
        if (searchState.searchParameters != null) {
          ref.read(rideSearchProvider.notifier).searchRides(searchState.searchParameters!);
        }
      } else if (mounted) {
        final error = ref.read(myBookingsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'فشل في حجز الرحلة'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ غير متوقع'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  // Driver ride management methods
  void _editRide(Ride ride) {
    Navigator.of(context).pushNamed('/edit-ride', arguments: ride.id);
  }

  void _cancelRide(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الرحلة'),
        content: const Text('هل أنت متأكد من إلغاء هذه الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref.read(myRidesProvider.notifier).cancelRide(ride.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إلغاء الرحلة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
  }

  void _completeRide(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إكمال الرحلة'),
        content: const Text('هل أنت متأكد من إكمال هذه الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref.read(myRidesProvider.notifier).completeRide(ride.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إكمال الرحلة بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('نعم، إكمال'),
          ),
        ],
      ),
    );
  }

  void _createNewRide() {
    Navigator.of(context).pushNamed('/create-ride');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
