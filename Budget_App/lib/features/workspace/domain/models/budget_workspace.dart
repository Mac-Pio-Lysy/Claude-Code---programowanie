import 'package:equatable/equatable.dart';

import 'workspace_tag.dart';

/// One budget a user owns or is a member of (AB-3/AB-4 multi-workspace
/// support) — e.g. "Budżet Domowy 2026", "Wesele", "Wakacje".
class BudgetWorkspace extends Equatable {
  const BudgetWorkspace({
    required this.id,
    required this.title,
    required this.tag,
    required this.isShared,
    required this.isOnline,
    required this.ownerId,
    required this.createdAt,
    this.description,
    this.sharedUserEmails = const [],
    this.currency = 'PLN',
  });

  final String id;
  final String title;
  final String? description;
  final WorkspaceTag tag;

  /// Whether this budget is shared with other people, vs. single-owner.
  final bool isShared;

  /// Cloud sync status.
  final bool isOnline;
  final String ownerId;
  final List<String> sharedUserEmails;
  final String currency;
  final DateTime createdAt;

  static const _unset = Object();

  BudgetWorkspace copyWith({
    String? title,
    Object? description = _unset,
    WorkspaceTag? tag,
    bool? isShared,
    bool? isOnline,
    List<String>? sharedUserEmails,
    String? currency,
  }) {
    return BudgetWorkspace(
      id: id,
      title: title ?? this.title,
      description: identical(description, _unset) ? this.description : description as String?,
      tag: tag ?? this.tag,
      isShared: isShared ?? this.isShared,
      isOnline: isOnline ?? this.isOnline,
      ownerId: ownerId,
      sharedUserEmails: sharedUserEmails ?? this.sharedUserEmails,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        tag,
        isShared,
        isOnline,
        ownerId,
        sharedUserEmails,
        currency,
        createdAt,
      ];
}
