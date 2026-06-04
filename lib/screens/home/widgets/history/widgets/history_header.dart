import 'package:flutter/material.dart';
import '../history_filter_type.dart';
import 'history_filter_tab.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class HistoryHeader extends StatelessWidget {
  final AppTranslations t;
  final int total;
  final int allCount;
  final int successfulCount;
  final int unsuccessfulCount;

  final HistoryFilterType filter;
  final ValueChanged<HistoryFilterType> onFilterChanged;

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const HistoryHeader({
    super.key,
    required this.t,
    required this.total,
    required this.allCount,
    required this.successfulCount,
    required this.unsuccessfulCount,
    required this.filter,
    required this.onFilterChanged,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface.withValues(alpha: 0.7),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.historyTitle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$total ${t.historySubtitle}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              HistoryFilterTab(
                type: HistoryFilterType.all,
                selectedFilter: filter,
                label: t.all,
                count: allCount,
                activeColor: AppColors.muted,
                onTap: onFilterChanged,
              ),
              const SizedBox(width: 8),
              HistoryFilterTab(
                type: HistoryFilterType.successful,
                selectedFilter: filter,
                label: t.successful,
                count: successfulCount,
                activeColor: AppColors.accent,
                onTap: onFilterChanged,
              ),
              const SizedBox(width: 8),
              HistoryFilterTab(
                type: HistoryFilterType.unsuccessful,
                selectedFilter: filter,
                label: t.unsuccessful,
                count: unsuccessfulCount,
                activeColor: AppColors.red,
                onTap: onFilterChanged,
              ),
            ],
          ),

          const SizedBox(height: 8),

          TextField(
            controller: searchController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: t.searchPlaceholder,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.muted,
                size: 18,
              ),
              suffixIcon: search.isNotEmpty
                  ? IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.muted,
                  size: 16,
                ),
                onPressed: onClearSearch,
              )
                  : null,
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}