import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../models/chat_model.dart';
import '../chat/chat_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isDriverMode = false; // ✅ NEW: Track current view mode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(myBookingsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDriver = currentUser?.isDriver ?? false;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isSearching ? 'البحث في الحجوزات' : 'حجوزاتي'),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _refreshData();
                }
              });
            },
          ),
          // ✅ IMPROVED: Better driver interface
          if (isDriver)
            PopupMenuButton<String>(
              icon: const Icon(Icons.drive_eta),
              tooltip: 'خيارات السائق',
              onSelected: (value) {
                switch (value) {
                  case 'driver_bookings':
                    _showDriverBookingsDialog();
                    break;
                  case 'switch_mode':
                    _switchViewMode();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'driver_bookings',
                  child: Row(
                    children: [
                      Icon(Icons.drive_eta, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('حجوزات رحلاتي'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'switch_mode',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('تبديل العرض'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        // ✅ IMPROVED: Better bottom section with mode indicator
        bottom: _isSearching 
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث في الحجوزات...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _refreshData();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
              )
            : PreferredSize(
                preferredSize: Size.fromHeight(isDriver ? 100 : 50),
                child: Column(
                  children: [
                    // ✅ NEW: Mode indicator for drivers
                    if (isDriver)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: _isDriverMode ? Colors.blue.shade50 : Colors.green.shade50,
                        child: Row(
                          children: [
                            Icon(
                              _isDriverMode ? Icons.drive_eta : Icons.person,
                              size: 16,
                              color: _isDriverMode ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isDriverMode ? 'عرض السائق' : 'عرض الراكب',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDriverMode ? Colors.blue : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _switchViewMode,
                              icon: const Icon(Icons.swap_horiz, size: 14),
                              label: const Text(
                                'تبديل',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ✅ IMPROVED: Better tab labels with counts
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('الكل'),
                              if (bookingState.myBookings.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${bookingState.myBookings.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('معلقة'),
                              if (bookingState.pendingBookings.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${bookingState.pendingBookings.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('مؤكدة'),
                              if (bookingState.confirmedBookings.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${bookingState.confirmedBookings.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('مكتملة'),
                              if (bookingState.completedBookings.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${bookingState.completedBookings.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      onTap: (index) {
                        _loadBookingsByTab(index);
                      },
                    ),
                  ],
                ),
              ),
      ),
      body: Column(
        children: [
          // ✅ Enhanced Stats Card
          if (!_isSearching) _buildStatsCard(bookingState),
          
          // ✅ Enhanced Content with mode switching
          Expanded(
            child: _isSearching 
                ? _buildSearchResults(bookingState)
                : _isDriverMode && isDriver
                    ? _buildDriverBookingsView(bookingState)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingsList(bookingState.myBookings, 'جميع الحجوزات'),
                          _buildBookingsList(bookingState.pendingBookings, 'الحجوزات المعلقة'),
                          _buildBookingsList(bookingState.confirmedBookings, 'الحجوزات المؤكدة'),
                          _buildBookingsList(bookingState.completedBookings, 'الحجوزات المكتملة'),
                        ],
                      ),
          ),
        ],
      ),
      // ✅ IMPROVED: Context-aware FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isDriverMode && isDriver ? _loadDriverBookings : _refreshData,
        backgroundColor: AppColors.primaryColor,
        icon: Icon(
          _isDriverMode ? Icons.drive_eta : Icons.refresh, 
          color: Colors.white,
        ),
        label: Text(
          _isDriverMode ? 'تحديث رحلاتي' : 'تحديث',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ✅ NEW: Switch between driver and passenger view
  void _switchViewMode() {
    setState(() {
      _isDriverMode = !_isDriverMode;
    });
    
    // Load appropriate data
    if (_isDriverMode) {
      _loadDriverBookings();
    } else {
      _refreshData();
    }
  }

  // ✅ NEW: Load driver bookings method
  Future<void> _loadDriverBookings() async {
    await ref.read(myBookingsProvider.notifier).loadDriverBookings(refresh: true);
  }

  // ✅ NEW: Driver bookings view (replaces TabBarView in driver mode)
  Widget _buildDriverBookingsView(BookingState bookingState) {
    final driverBookings = bookingState.driverBookings;
    
    if (bookingState.isLoading && driverBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل حجوزات رحلاتك...'),
          ],
        ),
      );
    }

    if (driverBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drive_eta_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حجوزات على رحلاتك',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض حجوزات الركاب هنا',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDriverBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: driverBookings.length,
        itemBuilder: (context, index) {
          final booking = driverBookings[index];
          return _buildDriverBookingCard(booking);
        },
      ),
    );
  }

  // ✅ Enhanced Stats Card
  Widget _buildStatsCard(BookingState bookingState) {
    final stats = bookingState.stats ?? {};
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'إجمالي الحجوزات',
              '${stats['total'] ?? bookingState.totalBookings}',
              Icons.book_online,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'حجوزات معلقة',
              '${stats['pending'] ?? bookingState.pendingBookings.length}',
              Icons.pending,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'حجوزات مؤكدة',
              '${stats['confirmed'] ?? bookingState.confirmedBookings.length}',
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Enhanced Bookings List
  Widget _buildBookingsList(List<Booking> bookings, String emptyMessage) {
    final bookingState = ref.watch(myBookingsProvider);

    if (bookingState.isLoading && bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل الحجوزات...'),
          ],
        ),
      );
    }

    if (bookingState.hasError && bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              bookingState.error!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حجوزات',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length + (bookingState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= bookings.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final booking = bookings[index];
          return _buildEnhancedBookingCard(booking);
        },
      ),
    );
  }

  // Enhanced Booking Card
  Widget _buildEnhancedBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'حجز #${booking.id}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Booking Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route Information
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.route,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${booking.ride?.fromCity ?? 'غير محدد'} ← ${booking.ride?.toCity ?? 'غير محدد'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (booking.pickupLocation?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'نقطة الالتقاء: ${booking.pickupLocation}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Booking Info Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.event_seat,
                        label: 'المقاعد',
                        value: '${booking.seatsBooked}',
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.attach_money,
                        label: 'المبلغ',
                        value: '${booking.totalPrice ?? 0} ر.س',
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.access_time,
                        label: 'التاريخ',
                        value: _formatBookingDate(booking.createdAt),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                // Special Requests
                if (booking.specialRequests?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note_alt, color: Colors.amber.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'طلبات خاصة:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.specialRequests!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (booking.isPending || booking.isConfirmed) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelConfirmation(booking),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('إلغاء الحجز'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openChat(booking),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('محادثة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Search Results
  Widget _buildSearchResults(BookingState bookingState) {
    return _buildBookingsList(bookingState.bookings, 'لم يتم العثور على نتائج');
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'معلق';
      case 'confirmed':
        return 'مؤكد';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  // Safe date formatting without Arabic locale dependency
  String _formatBookingDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  // Action Methods
  Future<void> _refreshData() async {
    await ref.read(myBookingsProvider.notifier).refreshAll();
  }

  void _loadBookingsByTab(int index) {
    final notifier = ref.read(myBookingsProvider.notifier);
    
    switch (index) {
      case 0:
        notifier.loadMyBookings(refresh: true);
        break;
      case 1:
        notifier.loadBookingsByStatus('pending', refresh: true);
        break;
      case 2:
        notifier.loadBookingsByStatus('confirmed', refresh: true);
        break;
      case 3:
        notifier.loadBookingsByStatus('completed', refresh: true);
        break;
    }
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      ref.read(myBookingsProvider.notifier).searchBookings(query: query);
    }
  }

  void _showCancelConfirmation(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إلغاء الحجز'),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(myBookingsProvider.notifier)
                  .cancelBooking(booking.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إلغاء الحجز بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  // Chat opening method
  Future<void> _openChat(Booking booking) async {
    if (booking.ride?.driverId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح المحادثة - معلومات السائق غير متوفرة'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final chatId = await ref.read(chatProvider.notifier)
          .getOrCreateChatForBooking(booking.id);

      if (mounted) Navigator.of(context).pop();

      if (chatId != null) {
        final chatInfo = ref.read(chatProvider.notifier).getChatById(chatId);
        
        if (chatInfo != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatInfo: chatInfo,
              ),
            ),
          );
        } else {
          final tempChatInfo = ChatInfo(
          id: chatId,
          rideId: booking.rideId,
          participant1Id: booking.passengerId,
          participant2Id: booking.ride!.driverId!,
          participant1Name: booking.passengerName,
          participant2Name: booking.ride?.driverName,
          bookingId: booking.id,
          rideFromCity: booking.ride?.fromCity,
          rideToCity: booking.ride?.toCity,
          rideDepartureDate: booking.ride?.departureDate,
          isActive: true,
          unreadCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatInfo: tempChatInfo,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إنشاء المحادثة. حاول مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في فتح المحادثة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Driver Bookings Dialog (Keep original functionality)
  void _showDriverBookingsDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myBookingsProvider.notifier).loadDriverBookings(refresh: true);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drive_eta, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'حجوزات رحلاتي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ref.read(myBookingsProvider.notifier).loadDriverBookings(refresh: true);
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final bookingState = ref.watch(myBookingsProvider);
                    final driverBookings = bookingState.driverBookings;
                    
                    if (bookingState.isLoading && driverBookings.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('جاري تحميل حجوزات السائق...'),
                          ],
                        ),
                      );
                    }

                    if (driverBookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drive_eta_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد حجوزات على رحلاتك',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سيتم عرض حجوزات الركاب هنا',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(myBookingsProvider.notifier).loadDriverBookings(refresh: true);
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: driverBookings.length,
                        itemBuilder: (context, index) {
                          final booking = driverBookings[index];
                          return _buildDriverBookingCard(booking);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Driver Booking Card
  Widget _buildDriverBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Text(
                    booking.passengerName?.substring(0, 1).toUpperCase() ?? 'ر',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.passengerName ?? 'راكب غير محدد',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'حجز #${booking.id} • ${_formatBookingDate(booking.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDriverBookingInfo(
                      icon: Icons.event_seat,
                      label: 'المقاعد',
                      value: '${booking.seatsBooked}',
                      color: Colors.blue,
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildDriverBookingInfo(
                      icon: Icons.attach_money,
                      label: 'المبلغ',
                      value: '${booking.totalPrice ?? 0} ر.س',
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildDriverBookingInfo(
                      icon: Icons.location_on,
                      label: 'التقاء',
                      value: booking.pickupLocation ?? 'غير محدد',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            if (booking.specialRequests?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note_alt, color: Colors.amber.shade700, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'طلبات خاصة: ${booking.specialRequests}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (booking.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectBooking(booking),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('رفض', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptBooking(booking),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('قبول', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverBookingInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _acceptBooking(Booking booking) async {
    final success = await ref
        .read(myBookingsProvider.notifier)
        .acceptBooking(booking.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الحجز بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    final success = await ref
        .read(myBookingsProvider.notifier)
        .rejectBooking(booking.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض الحجز'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
