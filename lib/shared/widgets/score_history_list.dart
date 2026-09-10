import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';

class ScoreHistoryEntry {
  const ScoreHistoryEntry({
    required this.id,
    required this.title,
    required this.details,
    this.onEdit,
    this.onDelete,
  });

  final String id;
  final String title;
  final String details;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

class ScoreHistoryList extends StatelessWidget {
  const ScoreHistoryList({
    super.key,
    required this.entries,
    this.emptyTitle,
    this.emptyMessage,
  });

  final List<ScoreHistoryEntry> entries;
  final String? emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 36,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle ?? l10n.t('score.historyEmptyTitle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                emptyMessage ?? l10n.t('score.historyEmptyMessage'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text('${entries.length - index}'),
            ),
            title: Text(entry.title),
            subtitle: Text(entry.details),
            trailing: entry.onEdit == null && entry.onDelete == null
                ? null
                : Wrap(
                    children: [
                      if (entry.onEdit != null)
                        IconButton(
                          tooltip: l10n.t('common.edit'),
                          onPressed: entry.onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      if (entry.onDelete != null)
                        IconButton(
                          tooltip: l10n.t('common.delete'),
                          onPressed: entry.onDelete,
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
