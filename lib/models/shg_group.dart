enum CollectionStatus { pending, collected, partial }

class SHGGroup {
  final String name;
  final String village;
  final int membersCount;
  final double totalSavings;
  final double totalLoan;
  final double collectionDue;
  final CollectionStatus status;
  final String time;

  const SHGGroup({
    required this.name,
    required this.village,
    required this.membersCount,
    required this.totalSavings,
    required this.totalLoan,
    required this.collectionDue,
    required this.status,
    required this.time,
  });
}

class Member {
  final String name;
  final String id;
  final double savingsDue;
  final double emiDue;
  final bool paid;

  const Member({
    required this.name,
    required this.id,
    required this.savingsDue,
    required this.emiDue,
    required this.paid,
  });
}
