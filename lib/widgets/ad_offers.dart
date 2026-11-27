import 'package:flutter/material.dart' hide Text;
import '../l10n/tr_text.dart';
import '../services/ad_service.dart';
import '../services/usage_service.dart';

/// Offers extra assistant questions in exchange for a rewarded ad, when the
/// daily questions are used up. Returns true when the user earned them, so
/// the caller can carry on with the question; false when there is no offer
/// (no ad ready, daily ad limit reached) or the user said no.
Future<bool> offerQuestionBonus(BuildContext context) async {
  if (!AdService.supported ||
      !AdService.rewardedReady.value ||
      !await UsageService.canWatchRewarded()) {
    return false;
  }
  if (!context.mounted) return false;
  final watch = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Daily questions used'),
      content: Text(
          'Watch a short ad to get ${UsageService.questionBonusSize} more questions today.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not now')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Watch ad')),
      ],
    ),
  );
  if (watch != true) return false;
  final earned = await AdService.showRewarded();
  if (!earned) return false;
  await UsageService.recordRewarded();
  await UsageService.addQuestionBonus();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'You earned ${UsageService.questionBonusSize} more questions today.'),
        behavior: SnackBarBehavior.floating));
  }
  return true;
}
