import 'package:flutter/material.dart';

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
    final splitAmount = totalBill / (friends.isEmpty ? 1 : friends.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(friend['avatar'] ?? ''),
                backgroundColor: Colors.grey.shade200,
              ),
              title: Text(
                friend['name'] ?? 'No Name',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              trailing: Text(
                '\$${splitAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFC81B22),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
