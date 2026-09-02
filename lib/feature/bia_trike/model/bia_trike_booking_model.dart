class BiaTrikeRideBooking {
  final String pickupLocation;
  final String destinationLocation;
  final String rideType; // 'Standard', 'Shared', 'Express'
  final double estimatedFare;
  final String language; // 'english', 'hausa', 'pidgin'
  final DateTime bookedAt;
  final String status; // 'SEARCHING_DRIVER', 'DRIVER_ASSIGNED', 'ARRIVED', 'COMPLETED'

  BiaTrikeRideBooking({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.rideType,
    required this.estimatedFare,
    required this.language,
    required this.bookedAt,
    this.status = 'SEARCHING_DRIVER',
  });
}
