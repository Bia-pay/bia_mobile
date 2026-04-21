import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../app/utils/custom_loader.dart';
import '../../../app/utils/router/route_constant.dart';
import '../../../core/__core.dart';
import 'package:intl/intl.dart';
import '../dashboardcontroller/provider.dart';
import '../model/recent_transaction.dart';
import '../widgets/transaction_tile.dart';

class TransactionHistory extends ConsumerStatefulWidget {
  const TransactionHistory({super.key});

  @override
  ConsumerState<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends ConsumerState<TransactionHistory> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Credit', 'Debit', 'Pending'];
  DateTimeRange? _selectedDateRange;
  String? _selectedDatePreset;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Disabled for discrete pagination
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case 'Today':
          _selectedDateRange = DateTimeRange(start: today, end: today);
          break;
        case 'Yesterday':
          final yesterday = today.subtract(const Duration(days: 1));
          _selectedDateRange = DateTimeRange(start: yesterday, end: yesterday);
          break;
        case 'Last 7 Days':
          _selectedDateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 6)),
            end: today,
          );
          break;
        case 'Last 30 Days':
          _selectedDateRange = DateTimeRange(
            start: today.subtract(const Duration(days: 29)),
            end: today,
          );
          break;
        case 'Custom Range':
          _selectedDatePreset = null; // Will be set by the picker result if we want
          _selectDateRange(context);
          break;
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime? tempStart = _selectedDateRange?.start;
    DateTime? tempEnd = _selectedDateRange?.end;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    
                    // Start Date Button
                    _buildDateSelector(
                      context,
                      label: 'Start Date',
                      date: tempStart,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStart ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: tempEnd ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempStart = picked);
                        }
                      },
                    ),
                    SizedBox(height: 12.h),
                    
                    // End Date Button
                    _buildDateSelector(
                      context,
                      label: 'End Date',
                      date: tempEnd,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEnd ?? DateTime.now(),
                          firstDate: tempStart ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempEnd = picked);
                        }
                      },
                    ),
                    SizedBox(height: 24.h),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (tempStart != null && tempEnd != null)
                                ? () {
                                    setState(() {
                                      _selectedDateRange = DateTimeRange(start: tempStart!, end: tempEnd!);
                                      _selectedDatePreset = null; // Mark as custom
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, {required String label, required DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10.sp, color: const Color(0xFF94A3B8))),
                SizedBox(height: 2.h),
                Text(
                  date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Choose date',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: date != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today_rounded, size: 16.sp, color: const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final userId = ref.read(userIdProvider);
    await ref.read(allTransactionsProvider(userId).notifier).refresh();
  }

  List<TransactionItem> _applyFilter(List<TransactionItem> txs) {
    List<TransactionItem> filtered = txs;

    // Apply category filter
    switch (_selectedFilter) {
      case 'Credit':
        filtered = filtered.where((t) => t.isCredit).toList();
        break;
      case 'Debit':
        filtered = filtered.where((t) => !t.isCredit).toList();
        break;
      case 'Pending':
        filtered = filtered.where((t) => t.status?.toUpperCase() == 'PENDING').toList();
        break;
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((t) {
        if (t.createdAt == null) return false;
        // Normalize to date only for comparison if needed, but here we just check range
        // Add 1 day to end to include the entire end day
        return (t.createdAt!.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
                t.createdAt!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive column count
    final int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);
    final isTablet = screenWidth > 600;
    
    final userId = ref.watch(userIdProvider);
    final asyncTx = ref.watch(allTransactionsProvider(userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200.w),
            child: RefreshIndicator(
          color: primaryColor,
          onRefresh: _handleRefresh,
          child: asyncTx.when(
            loading: () => const Center(child: CustomLoader()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (allTransactions) {
              final transactions = _applyFilter(allTransactions);

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header + Filters ──────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transactions',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.sp,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${transactions.length} results',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (_selectedDateRange != null)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedDateRange = null;
                                        _selectedDatePreset = null;
                                      }),
                                      child: Container(
                                        padding: EdgeInsets.all(6.w),
                                        margin: EdgeInsets.only(right: 8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16.sp,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: _applyDatePreset,
                                    itemBuilder: (context) => [
                                      'Today',
                                      'Yesterday',
                                      'Last 7 Days',
                                      'Last 30 Days',
                                      'Custom Range',
                                    ].map((String choice) {
                                      return PopupMenuItem<String>(
                                        value: choice,
                                        child: Text(
                                          choice,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: _selectedDateRange != null 
                                            ? primaryColor.withOpacity(0.1) 
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: _selectedDateRange != null 
                                              ? primaryColor 
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.calendar_month_rounded,
                                        size: 20.sp,
                                        color: _selectedDateRange != null 
                                            ? primaryColor 
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // ── Filter Chips ──
                          SizedBox(
                            height: 32.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filters.length,
                              separatorBuilder: (_, __) => SizedBox(width: 8.w),
                              itemBuilder: (context, i) {
                                final filter = _filters[i];
                                final isSelected = _selectedFilter == filter;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedFilter = filter),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : Colors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_selectedDateRange != null)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14.sp,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Showing: ${_selectedDatePreset ?? "${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}" }',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ),

                  // ── Transaction List ───────────────────────────
                  if (transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 44.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              _selectedFilter == 'All'
                                  ? 'No transactions yet'
                                  : 'No $_selectedFilter transactions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Your activity will appear here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24.w : 16.w, 
                        8.h, 
                        isTablet ? 24.w : 16.w, 
                        20.h
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 70.h,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 0, 
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = transactions[index];
                            return TransactionTile(
                              tx: tx,
                              onTap: () => context.pushNamed(
                                RouteList.transactionDetailsScreen,
                                extra: tx,
                              ),
                            );
                          },
                          childCount: transactions.length,
                        ),
                      ),
                    ),
                  
                  
                  // ── Pagination Bar ──
                  if (transactions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 30.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPaginationButton(
                              label: 'Previous',
                              icon: Icons.chevron_left_rounded,
                              onPressed: ref.read(allTransactionsProvider(userId).notifier).hasPreviousPage
                                  ? () {
                                      ref.read(allTransactionsProvider(userId).notifier).previousPage();
                                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                    }
                                  : null,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: lightBorderColor),
                              ),
                              child: Text(
                                'Page ${ref.watch(allTransactionsProvider(userId).notifier).currentPage}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: lightSecondaryText,
                                ),
                              ),
                            ),
                            _buildPaginationButton(
                              label: 'Next',
                              icon: Icons.chevron_right_rounded,
                              isRight: true,
                              onPressed: ref.read(allTransactionsProvider(userId).notifier).hasNextPage
                                  ? () {
                                      ref.read(allTransactionsProvider(userId).notifier).nextPage();
                                      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildPaginationButton({
    required String label,
    required IconData icon,
    bool isRight = false,
    VoidCallback? onPressed,
  }) {
    final bool isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDisabled ? const Color(0xFFE2E8F0).withOpacity(0.5) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) Icon(icon, size: 18.sp, color: isDisabled ? const Color(0xFF94A3B8) : primaryColor),
            if (!isRight) SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isDisabled ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
              ),
            ),
            if (isRight) SizedBox(width: 4.w),
            if (isRight) Icon(icon, size: 18.sp, color: isDisabled ? const Color(0xFF94A3B8) : primaryColor),
          ],
        ),
      ),
    );
  }
}
