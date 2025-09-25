import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/ride_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';
import '../rides/create_ride_screen.dart'; // ✅ Add import for CreateRideScreen

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
        ref.read(myRidesProvider.notifier).loadMyRides(refresh: true);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      final searchState = ref.read(rideSearchProvider);
      if (searchState.hasMore && !searchState.isLoading && !searchState.isLoadingMore) {
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
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: isDriver ? 'رحلاتي النشطة' : 'نتائج البحث'),
            Tab(text: isDriver ? 'الرحلات المكتملة' : 'المفضلة'),
          ],
        ),
        actions: [
          if (isDriver)
            IconButton(
              onPressed: () {
                ref.read(myRidesProvider.notifier).refreshAll();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isDriver ? _buildMyRidesTab() : _buildSearchResultsTab(),
          isDriver ? _buildCompletedRidesTab() : _buildFavoritesTab(),
        ],
      ),
      // ✅ FIXED: Add unique heroTag to prevent hero conflicts
      floatingActionButton: isDriver
          ? FloatingActionButton.extended(
              heroTag: "rides_screen_fab", // ✅ Add unique hero tag
              onPressed: _createNewRide,
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'رحلة جديدة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildMyRidesTab() {
    final ridesState = ref.watch(myRidesProvider);
    
    if (ridesState.isLoading && ridesState.rides.isEmpty) {
      return const LoadingWidget(message: 'جاري تحميل رحلاتك...');
    }
    
    if (ridesState.hasError && ridesState.rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل رحلاتك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ridesState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(myRidesProvider.notifier).loadMyRides(refresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (ridesState.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: AppColors.primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ليس لديك رحلات نشطة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'انقر على "رحلة جديدة" لإنشاء رحلة جديدة وبدء مشاركة المقاعد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _createNewRide,
                icon: const Icon(Icons.add),
                label: const Text('إنشاء رحلة جديدة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: BorderSide(color: AppColors.primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myRidesProvider.notifier).refreshAll();
      },
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: ridesState.rides.length + (ridesState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == ridesState.rides.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final ride = ridesState.rides[index];
          return _buildRideCard(ride, isMyRide: true);
        },
      ),
    );
  }

  Widget _buildSearchResultsTab() {
    final searchState = ref.watch(rideSearchProvider);
    
    if (searchState.isEmpty && !searchState.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_outlined,
                  size: 64,
                  color: AppColors.primaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ابحث عن رحلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'استخدم نموذج البحث في الصفحة الرئيسية للعثور على الرحلات المتاحة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (searchState.isLoading && searchState.rides.isEmpty) {
      return const LoadingWidget(message: 'جاري البحث عن الرحلات...');
    }

    if (searchState.hasError && searchState.rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في البحث',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                searchState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (searchState.searchParameters != null) {
                    ref.read(rideSearchProvider.notifier).searchRides(
                      searchState.searchParameters!,
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        if (searchState.searchParameters != null) {
          await ref.read(rideSearchProvider.notifier).searchRides(
            searchState.searchParameters!,
          );
        }
      },
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: searchState.rides.length + (searchState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == searchState.rides.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final ride = searchState.rides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildCompletedRidesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'الرحلات المكتملة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر رحلاتك المكتملة هنا قريباً',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'الرحلات المفضلة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر رحلاتك المفضلة هنا قريباً',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride, {bool isMyRide = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onRideTap(ride),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route and Price Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.fromCity,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: Container(
                              width: 2,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.toCity,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${ride.pricePerSeat.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontSize: 20,
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
                            color: _getRideTypeColor(ride.isFemaleOnly).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ride.isFemaleOnly ? 'نساء فقط' : 'مختلط',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getRideTypeColor(ride.isFemaleOnly),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Time and Date Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(ride.departureTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.event_seat,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.availableSeats}/${ride.totalSeats}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ✅ FIXED: Driver Information with proper fallback handling
                if (!isMyRide) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _getDriverProfileImage(ride),
                        backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                        child: _getDriverProfileImage(ride) == null
                            ? Text(
                                _getDriverInitial(ride),
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDriverName(ride),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_getDriverRating(ride) != null && _getDriverRating(ride)! > 0)
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_getDriverTotalRides(ride)} رحلة)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Booking Button
                      ride.availableSeats > 0
                          ? ElevatedButton(
                              onPressed: () => _bookRide(ride),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'احجز',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'مكتملة',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                        child: OutlinedButton.icon(
                          onPressed: () => _editRide(ride),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('تعديل'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: BorderSide(color: AppColors.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelRide(ride),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('إلغاء'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _completeRide(ride),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('إكمال'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Helper methods with proper fallback for driver info
  bool _getUserIsDriver(dynamic user) {
    if (user == null) return false;
    try {
      return user.isDriver ?? false;
    } catch (e) {
      return false;
    }
  }

  Color _getRideTypeColor(bool isFemaleOnly) {
    return isFemaleOnly ? Colors.pink : Colors.green;
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return 'اليوم ${DateFormat('HH:mm').format(dateTime)}';
      } else if (messageDate == today.add(const Duration(days: 1))) {
        return 'غداً ${DateFormat('HH:mm').format(dateTime)}';
      } else if (dateTime.difference(now).inDays < 7) {
        return DateFormat('EEEE HH:mm').format(dateTime);
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      }
    } catch (e) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  // ✅ FIXED: Driver helper methods with proper fallback
  ImageProvider? _getDriverProfileImage(Ride ride) {
    String? imageUrl;
    
    try {
      // Try different possible property paths
      imageUrl = (ride as dynamic).driverInfo?.profileImageUrl ??
                 (ride as dynamic).driver?.profileImageUrl ??
                 (ride as dynamic).driverProfileImage ??
                 (ride as dynamic).profileImage;
    } catch (e) {
      imageUrl = null;
    }
    
    return imageUrl != null ? NetworkImage(imageUrl) : null;
  }

  String _getDriverInitial(Ride ride) {
    String name = _getDriverName(ride);
    return name.isNotEmpty ? name[0].toUpperCase() : 'س';
  }

  String _getDriverName(Ride ride) {
    try {
      // Try different possible property paths for driver name
      String? firstName = (ride as dynamic).driverInfo?.firstName ??
                          (ride as dynamic).driver?.firstName ??
                          (ride as dynamic).driverFirstName;
      
      String? lastName = (ride as dynamic).driverInfo?.lastName ??
                         (ride as dynamic).driver?.lastName ??
                         (ride as dynamic).driverLastName;
      
      String? fullName = (ride as dynamic).driverInfo?.name ??
                         (ride as dynamic).driver?.name ??
                         (ride as dynamic).driverName;
      
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
      
      if (firstName != null && firstName.isNotEmpty) {
        return lastName != null && lastName.isNotEmpty 
            ? '$firstName $lastName' 
            : firstName;
      }
      
      return 'السائق';
    } catch (e) {
      return 'السائق';
    }
  }

  double? _getDriverRating(Ride ride) {
    try {
      // Try different possible property paths for driver rating
      final rating = (ride as dynamic).driverInfo?.rating ??
                     (ride as dynamic).driver?.rating ??
                     (ride as dynamic).driverRating;
      return rating?.toDouble();
    } catch (e) {
      return null;
    }
  }

  int _getDriverTotalRides(Ride ride) {
    try {
      // Try different possible property paths for total rides
      return (ride as dynamic).driverInfo?.totalRides ??
             (ride as dynamic).driver?.totalRides ??
             (ride as dynamic).driverTotalRides ??
             0;
    } catch (e) {
      return 0;
    }
  }

  void _onRideTap(Ride ride) {
    // Navigate to ride details screen
    // Navigator.of(context).pushNamed('/ride-details', arguments: ride.id);
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
        title: const Row(
          children: [
            Icon(Icons.book_online, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('حجز الرحلة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride.fromCity} → ${ride.toCity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(ride.departureTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Seats selection
              Row(
                children: [
                  const Text(
                    'عدد المقاعد:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: selectedSeats,
                      underline: Container(),
                      items: List.generate(
                        ride.availableSeats,
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
                decoration: InputDecoration(
                  hintText: 'أدخل نقطة الالتقاء المفضلة لك',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
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
                decoration: InputDecoration(
                  hintText: 'أي ملاحظات إضافية...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Total price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.1),
                      AppColors.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'إجمالي المبلغ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(ride.pricePerSeat * selectedSeats).toStringAsFixed(0)} ريال سعودي',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
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
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('جاري تأكيد الحجز...'),
          ],
        ),
      ),
    );

    try {
      final success = await ref.read(myBookingsProvider.notifier).createBooking(
        rideId: rideId,
        seatsBooked: seats,
        pickupLocation: pickupLocation,
        pickupLatitude: 0.0,
        pickupLongitude: 0.0,
        notes: notes,
      );

      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم حجز الرحلة بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(error ?? 'فشل في حجز الرحلة')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('حدث خطأ غير متوقع'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Driver ride management methods
  void _editRide(Ride ride) {
    // Navigate to edit ride screen
    // Navigator.of(context).pushNamed('/edit-ride', arguments: ride.id);
  }

  void _cancelRide(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('إلغاء الرحلة'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إشعار جميع الركاب المحجوزين.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا، احتفظ بالرحلة'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('جاري إلغاء الرحلة...'),
                    ],
                  ),
                ),
              );
              
              final success = await ref.read(myRidesProvider.notifier).cancelRide(ride.id);
              
              // Dismiss loading
              if (mounted) Navigator.of(context).pop();
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تم إلغاء الرحلة بنجاح'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (mounted) {
                final error = ref.read(myRidesProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'فشل في إلغاء الرحلة'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء الرحلة'),
          ),
        ],
      ),
    );
  }

  void _completeRide(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('إكمال الرحلة'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إكمال هذه الرحلة؟ سيتم إشعار الركاب بانتهاء الرحلة.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا، لم تكتمل بعد'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('جاري إكمال الرحلة...'),
                    ],
                  ),
                ),
              );
              
              final success = await ref.read(myRidesProvider.notifier).completeRide(ride.id);
              
              // Dismiss loading
              if (mounted) Navigator.of(context).pop();
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تم إكمال الرحلة بنجاح'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (mounted) {
                final error = ref.read(myRidesProvider).error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'فشل في إكمال الرحلة'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، الرحلة مكتملة'),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Navigate to CreateRideScreen using MaterialPageRoute
  void _createNewRide() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateRideScreen(),
      ),
    ).then((result) {
      // Refresh rides if a ride was created
      if (result == true) {
        ref.read(myRidesProvider.notifier).loadMyRides(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
