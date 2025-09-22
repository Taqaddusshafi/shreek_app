import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/loading_widget.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myBookingsProvider.notifier).loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'حجوزاتي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'النشطة'),
                Tab(text: 'المكتملة'),
                Tab(text: 'الملغاة'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab('active'),
          _buildBookingsTab('completed'),
          _buildBookingsTab('cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(String status) {
    return Consumer(
      builder: (context, ref, child) {
        final bookingsState = ref.watch(myBookingsProvider);
        
        if (bookingsState.isLoading) {
          return const LoadingWidget(message: 'جاري تحميل الحجوزات...');
        }
        
        if (bookingsState.error != null) {
          return _buildErrorState(bookingsState.error!);
        }
        
        // ✅ FIXED: Use the exact status helper methods from Booking model
        final filteredBookings = bookingsState.bookings.where((booking) {
          switch (status) {
            case 'active':
              return booking.isPending || booking.isConfirmed;
            case 'completed':
              return booking.isCompleted;
            case 'cancelled':
              return booking.isCancelled;
            default:
              return false;
          }
        }).toList();
        
        if (filteredBookings.isEmpty) {
          return _buildEmptyState(status);
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(myBookingsProvider.notifier).loadMyBookings();
          },
          color: AppColors.primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onBookingTap(booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status & Booking Code
                Row(
                  children: [
                    _buildStatusChip(booking),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.bookingCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // ✅ FIXED: Journey Details using actual Booking properties
                _buildJourneySection(booking),
                
                const SizedBox(height: 20),
                
                // ✅ FIXED: Price & Seats Info using actual properties
                _buildPriceSeatsSection(booking),
                
                const SizedBox(height: 16),
                
                // ✅ FIXED: Date & Time using booking.createdAt
                _buildDateTimeSection(booking),
                
                const SizedBox(height: 16),
                
                // ✅ FIXED: Special Requests using booking.specialRequests
                if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                  _buildSpecialRequestsSection(booking.specialRequests!),
                  const SizedBox(height: 16),
                ],

                // ✅ FIXED: Notes section using booking.notes
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  _buildNotesSection(booking.notes!),
                  const SizedBox(height: 16),
                ],

                // ✅ FIXED: Cancellation info if cancelled
                if (booking.isCancelled && booking.cancelledAt != null) ...[
                  _buildCancellationSection(booking),
                  const SizedBox(height: 16),
                ],
                
                // ✅ FIXED: Action Buttons using status helper methods
                if (_shouldShowActionButtons(booking))
                  _buildActionButtons(booking),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Status chip using booking model methods
  Widget _buildStatusChip(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(booking.status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(booking.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            booking.statusDisplayText, // ✅ Use built-in statusDisplayText
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(booking.status),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Journey section using actual booking properties
  Widget _buildJourneySection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Pickup Location
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نقطة الانطلاق',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.pickupLocation, // ✅ Use actual pickupLocation
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Journey Line
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 2,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, AppColors.primaryColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Ride Info (since we don't have destination in booking)
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرحلة رقم',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${booking.rideId}', // ✅ Use actual rideId
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ NEW: Show passenger ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'راكب #${booking.passengerId}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Price and seats using actual booking properties
  Widget _buildPriceSeatsSection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السعر الإجمالي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.totalPrice.toStringAsFixed(0)} ريال', // ✅ Use actual totalPrice
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عدد المقاعد',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.seatsBooked} ${booking.seatsBooked == 1 ? 'مقعد' : 'مقاعد'}', // ✅ Use actual seatsBooked
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
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

  // ✅ FIXED: Date time using booking.createdAt
  Widget _buildDateTimeSection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'تاريخ الحجز: ${_formatDate(booking.createdAt)}', // ✅ Use actual createdAt
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          if (booking.updatedAt != booking.createdAt) ...[
            const SizedBox(width: 12),
            Text(
              '• آخر تحديث: ${_formatDate(booking.updatedAt)}', // ✅ Show updatedAt if different
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ FIXED: Special requests using booking.specialRequests
  Widget _buildSpecialRequestsSection(String specialRequests) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 18,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبات خاصة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialRequests,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Notes section using booking.notes
  Widget _buildNotesSection(String notes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 18,
            color: Colors.purple.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notes,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Cancellation section for cancelled bookings
  Widget _buildCancellationSection(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 18,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'تم الإلغاء في: ${_formatDate(booking.cancelledAt!)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'سبب الإلغاء: ${booking.cancellationReason!}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ FIXED: Action buttons using status helper methods
  Widget _buildActionButtons(Booking booking) {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 12),
        Row(
          children: [
            if (booking.isConfirmed) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _chatWithDriver(booking),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('محادثة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(booking),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('إلغاء الحجز'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade600),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(myBookingsProvider.notifier).loadMyBookings();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(status),
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyStateMessage(status),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubMessage(status),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(myBookingsProvider.notifier).loadMyBookings();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(color: AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return AppColors.primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmptyStateIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.bookmark_outline;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.bookmark_outline;
    }
  }

  String _getEmptyStateMessage(String status) {
    switch (status) {
      case 'active':
        return 'لا توجد حجوزات نشطة';
      case 'completed':
        return 'لا توجد حجوزات مكتملة';
      case 'cancelled':
        return 'لا توجد حجوزات ملغاة';
      default:
        return 'لا توجد حجوزات';
    }
  }

  String _getEmptyStateSubMessage(String status) {
    switch (status) {
      case 'active':
        return 'عندما تقوم بحجز رحلة ستظهر هنا';
      case 'completed':
        return 'الرحلات المكتملة ستظهر هنا';
      case 'cancelled':
        return 'الحجوزات الملغاة ستظهر هنا';
      default:
        return '';
    }
  }

  bool _shouldShowActionButtons(Booking booking) {
    return booking.isPending || booking.isConfirmed; // ✅ Use helper methods
  }

  String _formatDate(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Action Methods
  void _onBookingTap(Booking booking) {
    // TODO: Navigate to booking details
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => BookingDetailsScreen(booking: booking),
    // ));
  }

  void _chatWithDriver(Booking booking) {
    // TODO: Navigate to chat screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => ChatScreen(rideId: booking.rideId),
    // ));
  }

  void _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'إلغاء الحجز',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟\n'
          'قد تطبق رسوم إلغاء وفقاً لسياسة الإلغاء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'تراجع',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ref.read(myBookingsProvider.notifier)
            .cancelBooking(booking.id);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم إلغاء الحجز بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          ref.read(myBookingsProvider.notifier).loadMyBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في إلغاء الحجز: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}