import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';
import '../rides/rides_screen.dart';
import '../bookings/bookings_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import 'home_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const RidesScreen(),
      const BookingsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final unreadChatCount = ref.watch(unreadChatCountProvider);
    
    return PopScope( // ✅ Updated from deprecated WillPopScope
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.cardColor,
          elevation: 8,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions_car_outlined),
              activeIcon: const Icon(Icons.directions_car),
              label: authState.isDriver ? 'رحلاتي' : 'البحث',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'الحجوزات',
            ),
            BottomNavigationBarItem(
              icon: Consumer(
                builder: (context, ref, child) {
                  final unreadChatCount = ref.watch(unreadChatCountProvider);
                  return unreadChatCount > 0
                      ? Badge(
                          label: Text(
                            unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                            style: const TextStyle(fontSize: 9),
                          ),
                          backgroundColor: AppColors.errorColor,
                          textColor: Colors.white,
                          child: const Icon(Icons.chat_bubble_outline),
                        )
                      : const Icon(Icons.chat_bubble_outline);
                },
              ),
              activeIcon: Consumer(
                builder: (context, ref, child) {
                  final unreadChatCount = ref.watch(unreadChatCountProvider);
                  return unreadChatCount > 0
                      ? Badge(
                          label: Text(
                            unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                            style: const TextStyle(fontSize: 9),
                          ),
                          backgroundColor: AppColors.errorColor,
                          textColor: Colors.white,
                          child: const Icon(Icons.chat_bubble),
                        )
                      : const Icon(Icons.chat_bubble);
                },
              ),
              label: 'المحادثات',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final authState = ref.watch(authProvider);
    
    // Show different FABs based on current tab and user role
    switch (_selectedIndex) {
      case 0: // Home
        return FloatingActionButton(
          onPressed: () => _navigateToNotifications(),
          backgroundColor: AppColors.primaryColor,
          child: Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadCountProvider);
              return Stack(
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      
      case 1: // Rides
        if (authState.isDriver) {
          return FloatingActionButton(
            onPressed: () => _createNewRide(),
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }
        return null;
        
      case 2: // Bookings
        return FloatingActionButton.extended(
          onPressed: () => _searchRides(),
          backgroundColor: AppColors.accentColor,
          icon: const Icon(Icons.search, color: Colors.white),
          label: const Text(
            'بحث عن رحلة',
            style: TextStyle(color: Colors.white),
          ),
        );
        
      default:
        return null;
    }
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _createNewRide() {
    // Navigate to create ride screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCreateRideBottomSheet(),
    );
  }

  Widget _buildCreateRideBottomSheet() { // ✅ Fixed method name
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              alignment: Alignment.center,
            ),
            const Text(
              'إنشاء رحلة جديدة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to create ride form
              },
              icon: const Icon(Icons.add_road),
              label: const Text('إنشاء رحلة سريعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to ride template
              },
              icon: const Icon(Icons.schedule),
              label: const Text('جدولة رحلة متكررة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ); // ✅ Fixed missing closing bracket
  }

  void _searchRides() {
    // Switch to rides tab for searching
    setState(() {
      _selectedIndex = 1;
    });
  }
}
