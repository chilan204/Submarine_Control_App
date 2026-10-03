import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/user_session_record.dart';
import '../../../../providers/app_provider.dart';
import '../../../../theme.dart';
import 'history_filter_type.dart';
import 'widgets/history_header.dart';
import 'widgets/history_empty.dart';
import 'widgets/history_footer.dart';
import 'widgets/history_command_row.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilterType  _filter = HistoryFilterType .all;
  String _search = '';
  String? _expandedId;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchUserSessions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;

    List<UserSessionRecord> all = List.from(provider.userSessions);
    all.sort((a, b) => (b.createdDate ?? DateTime.now()).compareTo(a.createdDate ?? DateTime.now()));

    final filtered = all.where((cmd) {
      final transcript = cmd.transcript ?? '';
      final action = cmd.action ?? '';
      
      final matchSearch = _search.isEmpty ||
        transcript.toLowerCase().contains(_search.toLowerCase()) ||
        action.toLowerCase().contains(_search.toLowerCase());
      final matchFilter =
        _filter == HistoryFilterType.all ||
          (_filter == HistoryFilterType.successful &&
            cmd.commandStatus == 'EXECUTED') ||
          (_filter == HistoryFilterType.unconfirmed &&
            cmd.commandStatus == 'SENT_UNCONFIRMED') ||
          (_filter == HistoryFilterType.unsuccessful &&
            cmd.commandStatus != 'EXECUTED' &&
            cmd.commandStatus != 'SENT_UNCONFIRMED');
      return matchSearch && matchFilter;
    }).toList();

    final counts = (
      all: all.length,
      successful: all.where((cmd) => cmd.commandStatus == 'EXECUTED').length,
      unconfirmed: all.where((cmd) => cmd.commandStatus == 'SENT_UNCONFIRMED').length,
      unsuccessful: all.where((cmd) => cmd.commandStatus != 'EXECUTED' && cmd.commandStatus != 'SENT_UNCONFIRMED').length,
    );

    return Column(
      children: [
        HistoryHeader(
          t: t,
          total: all.length,
          allCount: counts.all,
          successfulCount: counts.successful,
          unconfirmedCount: counts.unconfirmed,
          unsuccessfulCount: counts.unsuccessful,
          filter: _filter,
          onFilterChanged: (v) => setState(() => _filter = v),
          searchController: _searchCtrl,
          search: _search,
          onSearchChanged: (v) => setState(() => _search = v),
          onClearSearch: () {
            _searchCtrl.clear();
            setState(() => _search = '');
          },
        ),

        Expanded(
          child: provider.isLoadingSessions
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : provider.sessionsError != null
              ? Center(
                child: Text(
                  'Error: ${provider.sessionsError}',
                  style: const TextStyle(color: AppColors.red, fontSize: 13),
                ),
              )
              : filtered.isEmpty
                ? HistoryEmpty(t: t)
                : RefreshIndicator(
                  onRefresh: () => provider.fetchUserSessions(),
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => HistoryCommandRow(
                      cmd: filtered[i],
                      t: t,
                      isExpanded: _expandedId == filtered[i].id.toString(),
                      onTap: () => setState(() {
                        _expandedId =
                        _expandedId == filtered[i].id.toString()
                            ? null
                            : filtered[i].id.toString();
                      }),
                    ),
                  ),
                ),
        ),

        HistoryFooter(
          t: t,
          shown: filtered.length,
          total: all.length,
        ),
      ],
    );
  }
}
