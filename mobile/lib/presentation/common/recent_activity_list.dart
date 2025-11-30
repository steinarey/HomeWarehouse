import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/inventory_action.dart';

class RecentActivityList extends StatelessWidget {
  final List<InventoryAction> actions;

  const RecentActivityList({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Center(child: Text('No recent activity'));
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final isConsume = action.actionType == 'consume';
        final color = isConsume ? Colors.orange : Colors.green;
        final icon = isConsume
            ? Icons.remove_circle_outline
            : Icons.add_circle_outline;

        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            action.productName ?? action.categoryName ?? 'Unknown Item',
          ),
          subtitle: Text(
            '${DateFormat.yMMMd().add_jm().format(action.createdAt)} • ${action.userName ?? 'Unknown User'}',
          ),
          trailing: Text(
            '${isConsume ? '-' : '+'}${action.quantityDelta}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
