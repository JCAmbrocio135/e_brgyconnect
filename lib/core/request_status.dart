/// Standard status names used by the app.
const kStatusPending = 'Pending';
const kStatusProcessing = 'Processing';
const kStatusReady = 'Ready for Pickup';
const kStatusReleased = 'Released';
const kStatusRejected = 'Rejected';
const kStatusCancelled = 'Cancelled';

/// Converts a status written by the web dashboard (or an older version of the
/// app) into one of the standard names above. Unknown values are kept as-is.
String normalizeStatus(Object? raw) {
  final original = (raw as String?)?.trim() ?? '';
  if (original.isEmpty) return kStatusPending;

  final s = original.toLowerCase().replaceAll(RegExp(r'[_\-]+'), ' ');

  switch (s) {
    case 'pending':
    case 'submitted':
    case 'new':
      return kStatusPending;

    case 'processing':
    case 'in progress':
    case 'in process':
    case 'under review':
      return kStatusProcessing;

    case 'ready for pickup':
    case 'ready to pickup':
    case 'ready for pick up':
    case 'ready to pick up':
    case 'ready':
      return kStatusReady;

    case 'released':
    case 'completed':
    case 'claimed':
    case 'picked up':
      return kStatusReleased;

    case 'rejected':
    case 'declined':
    case 'denied':
      return kStatusRejected;

    case 'cancelled':
    case 'canceled':
      return kStatusCancelled;

    default:
      return original;
  }
}