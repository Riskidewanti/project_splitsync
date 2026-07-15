import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class FriendsListCard extends StatelessWidget {
  final List<dynamic> friends;
  final double totalBill;

  const FriendsListCard({
    super.key,
    required this.friends,
    required this.totalBill,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final splitAmount = totalBill / (friends.isEmpty ? 1 : friends.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: friends.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade100,
          height: 1,
          indent: 72,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final friend = friends[index];
          return ListTile(
            minVerticalPadding: AppSpacing.xs,
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(friend['avatar'] ?? ''),
              backgroundColor: Colors.grey.shade200,
            ),
            title: Text(
              friend['name'] ?? 'No Name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(color: Colors.black87),
            ),
            trailing: Text(
              '\$${splitAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: textTheme.titleSmall?.copyWith(
                color: const Color(0xFFC81B22),
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }
}
