import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/database/db_helper.dart';

part 'badges_provider.g.dart';

class RiderStats {
  final int totalPackages;
  final int successPackages;
  final double totalTips;
  final int uniqueBarangays;
  final int uniqueCities;
  final double totalCollections;
  final int totalRides;
  final int totalAttempts;
  final int rejectedPackages;
  final int rescheduledPackages;
  final int earlyMorning;
  final int night;
  final int multiAttempt;
  final int receiverArchivesCount;

  RiderStats({
    required this.totalPackages,
    required this.successPackages,
    required this.totalTips,
    required this.uniqueBarangays,
    required this.uniqueCities,
    required this.totalCollections,
    required this.totalRides,
    required this.totalAttempts,
    required this.rejectedPackages,
    required this.rescheduledPackages,
    required this.earlyMorning,
    required this.night,
    required this.multiAttempt,
    required this.receiverArchivesCount,
  });

  factory RiderStats.fromMap(Map<String, dynamic> map) {
    return RiderStats(
      totalPackages: map['totalPackages'] as int? ?? 0,
      successPackages: map['successPackages'] as int? ?? 0,
      totalTips: map['totalTips'] as double? ?? 0.0,
      uniqueBarangays: map['uniqueBarangays'] as int? ?? 0,
      uniqueCities: map['uniqueCities'] as int? ?? 0,
      totalCollections: map['totalCollections'] as double? ?? 0.0,
      totalRides: map['totalRides'] as int? ?? 0,
      totalAttempts: map['totalAttempts'] as int? ?? 0,
      rejectedPackages: map['rejectedPackages'] as int? ?? 0,
      rescheduledPackages: map['rescheduledPackages'] as int? ?? 0,
      earlyMorning: map['earlyMorning'] as int? ?? 0,
      night: map['night'] as int? ?? 0,
      multiAttempt: map['multiAttempt'] as int? ?? 0,
      receiverArchivesCount: map['receiverArchivesCount'] as int? ?? 0,
    );
  }
}

class RiderBadge {
  final String id;
  final String title;
  final String description;
  final String requirement;
  final String category;
  final double targetValue;
  final double currentValue;
  final IconData icon;

  RiderBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.icon,
  });

  bool get unlocked => currentValue >= targetValue;
  double get progress => targetValue == 0 ? 1.0 : (currentValue / targetValue).clamp(0.0, 1.0);
}

@riverpod
class BadgesNotifier extends _$BadgesNotifier {
  @override
  Future<List<RiderBadge>> build() async {
    final dbHelper = DbHelper.instance;
    final statsMap = await dbHelper.getHistoricalStats();
    final stats = RiderStats.fromMap(statsMap);
    
    return _generateBadges(stats);
  }

  List<RiderBadge> _generateBadges(RiderStats stats) {
    final List<RiderBadge> list = [];
    
    // Category 1: Volume (Delivery Count)
    // 22 badges
    final volumes = [
      _BadgeSpec(1, "First Drop", "Successfully delivered your very first package! Welcome to the road.", "Deliver 1 package", Icons.local_shipping_outlined),
      _BadgeSpec(5, "High Five", "Delivered five packages. You are getting the hang of this!", "Deliver 5 packages", Icons.handshake_outlined),
      _BadgeSpec(10, "Perfect Ten", "Double digits! 10 successful deliveries completed.", "Deliver 10 packages", Icons.emoji_events_outlined),
      _BadgeSpec(20, "Score!", "A full score of deliveries done. Keep rolling!", "Deliver 20 packages", Icons.looks_two_rounded),
      _BadgeSpec(30, "Thirtysomething", "30 successful deliveries logged. Excellent work!", "Deliver 30 packages", Icons.directions_bike_rounded),
      _BadgeSpec(40, "Life Begins at 40", "40 parcels dropped. You're becoming a neighborhood fixture.", "Deliver 40 packages", Icons.navigation_rounded),
      _BadgeSpec(50, "Nifty Fifty", "50 deliveries! A fantastic half-century milestone.", "Deliver 50 packages", Icons.stars_rounded),
      _BadgeSpec(60, "Sizzling Sixty", "60 packages delivered successfully.", "Deliver 60 packages", Icons.flash_on_rounded),
      _BadgeSpec(70, "Lucky Seventy", "70 parcels down. May luck follow you on every route.", "Deliver 70 packages", Icons.looks_one),
      _BadgeSpec(80, "Crazy Eighty", "80 deliveries. Your dedication is inspiring!", "Deliver 80 packages", Icons.speed_rounded),
      _BadgeSpec(90, "Ninety Not Out", "90 successful drops. Almost at the big one hundred!", "Deliver 90 packages", Icons.trending_up_rounded),
      _BadgeSpec(100, "Centurion", "100 successful deliveries! A legendary milestone for any rider.", "Deliver 100 packages", Icons.workspace_premium_rounded),
      _BadgeSpec(150, "Century & Half", "150 deliveries. Pushing limits and delivering smiles.", "Deliver 150 packages", Icons.flag_rounded),
      _BadgeSpec(200, "Double Century", "200 packages delivered! Incredible endurance on the road.", "Deliver 200 packages", Icons.military_tech_rounded),
      _BadgeSpec(250, "Quarter K", "250 deliveries logged. A true milestone master.", "Deliver 250 packages", Icons.album_rounded),
      _BadgeSpec(300, "Triple Century", "300 packages delivered. The road is your second home.", "Deliver 300 packages", Icons.auto_awesome_rounded),
      _BadgeSpec(400, "Quad Squad", "400 packages delivered. Elite logistics professional.", "Deliver 400 packages", Icons.badge_rounded),
      _BadgeSpec(500, "Half Grand", "500 packages! Half a thousand parcels safely in the hands of recipients.", "Deliver 500 packages", Icons.diamond_rounded),
      _BadgeSpec(750, "Silver Century", "750 deliveries. Sterling performance day in, day out.", "Deliver 750 packages", Icons.shield_rounded),
      _BadgeSpec(1000, "Grand Master", "1000 successful deliveries! You are the absolute king of the last mile.", "Deliver 1000 packages", Icons.emoji_events_rounded),
      _BadgeSpec(1500, "Super Rider", "1500 deliveries. Your tires have seen some serious miles.", "Deliver 1500 packages", Icons.rocket_launch_rounded),
      _BadgeSpec(2000, "Legendary Deliverer", "2000 successful deliveries. You are a cornerstone of the logistics network.", "Deliver 2000 packages", Icons.electric_bolt_rounded),
    ];
    for (var i = 0; i < volumes.length; i++) {
      final spec = volumes[i];
      list.add(RiderBadge(
        id: "vol_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Volume",
        targetValue: spec.val.toDouble(),
        currentValue: stats.successPackages.toDouble(),
        icon: spec.icon,
      ));
    }

    // Category 2: Tips (Gratuity)
    // 15 badges
    final tips = [
      _BadgeSpec(50, "Tip Beginner", "Earned 50 PHP in tips. A token of appreciation from customers.", "Earn 50 PHP in tips", Icons.savings_outlined),
      _BadgeSpec(100, "Coffee Money", "100 PHP in tips. Enough to power your next ride!", "Earn 100 PHP in tips", Icons.coffee_rounded),
      _BadgeSpec(150, "Snack Fund", "150 PHP in tips. Treats on the road!", "Earn 150 PHP in tips", Icons.fastfood_rounded),
      _BadgeSpec(200, "Generosity", "200 PHP in tips. Excellent customer service paying off.", "Earn 200 PHP in tips", Icons.favorite_outline_rounded),
      _BadgeSpec(250, "Gratuity Master", "250 PHP in tips. Customers love your work!", "Earn 250 PHP in tips", Icons.volunteer_activism_rounded),
      _BadgeSpec(300, "Bonus Hunter", "300 PHP in tips. Your efforts are recognized.", "Earn 300 PHP in tips", Icons.card_giftcard_rounded),
      _BadgeSpec(400, "Tip King", "400 PHP in tips. Outstanding courtesy rewards.", "Earn 400 PHP in tips", Icons.thumb_up_alt_outlined),
      _BadgeSpec(500, "Tip Vault", "500 PHP in tips! A massive milestone of appreciation.", "Earn 500 PHP in tips", Icons.lock_outline),
      _BadgeSpec(750, "Tip Champion", "750 PHP in tips. Keep going and stay friendly!", "Earn 750 PHP in tips", Icons.military_tech_outlined),
      _BadgeSpec(1000, "Gold Gratuity", "1000 PHP in tips! Pure gold standard service.", "Earn 1000 PHP in tips", Icons.workspace_premium_outlined),
      _BadgeSpec(1500, "Elite Tips", "1500 PHP in tips. You are in the top echelon of friendly couriers.", "Earn 1500 PHP in tips", Icons.stars_outlined),
      _BadgeSpec(2000, "Diamond Tip", "2000 PHP in tips. Ultimate customer care rewards.", "Earn 2000 PHP in tips", Icons.diamond_outlined),
      _BadgeSpec(3000, "Tip Legend", "3000 PHP in tips. Legendary level of service.", "Earn 3000 PHP in tips", Icons.emoji_events_outlined),
      _BadgeSpec(5000, "Tip Emperor", "5000 PHP in tips. Absolute king of gratuity.", "Earn 5000 PHP in tips", Icons.auto_awesome),
      _BadgeSpec(10000, "Infinite Tips", "10000 PHP in tips. Lifetime of appreciation.", "Earn 10000 PHP in tips", Icons.all_inclusive_rounded),
    ];
    for (var i = 0; i < tips.length; i++) {
      final spec = tips[i];
      list.add(RiderBadge(
        id: "tips_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Tips",
        targetValue: spec.val.toDouble(),
        currentValue: stats.totalTips,
        icon: spec.icon,
      ));
    }

    // Category 3: Collections (COD Cash/Digital Collections)
    // 14 badges
    final collections = [
      _BadgeSpec(1000, "Cash Handler", "Collected 1,000 PHP COD. First financial drops.", "Collect 1,000 PHP COD", Icons.payments_outlined),
      _BadgeSpec(5000, "Finance Starter", "Collected 5,000 PHP COD. Safe and secure.", "Collect 5,000 PHP COD", Icons.account_balance_wallet_outlined),
      _BadgeSpec(10000, "Safe Keeper", "Collected 10,000 PHP COD. Handling funds like a pro.", "Collect 10,000 PHP COD", Icons.security_rounded),
      _BadgeSpec(20000, "Collector Pro", "Collected 20,000 PHP COD. Moving cargo, settling accounts.", "Collect 20,000 PHP COD", Icons.monetization_on_outlined),
      _BadgeSpec(30000, "Money Bag", "Collected 30,000 PHP COD. Heavy lifting of finances.", "Collect 30,000 PHP COD", Icons.local_mall_outlined),
      _BadgeSpec(40000, "Vault Keeper", "Collected 40,000 PHP COD. Trustworthy handler.", "Collect 40,000 PHP COD", Icons.vpn_key_outlined),
      _BadgeSpec(50000, "Treasurer", "Collected 50,000 PHP COD. Solid financial deliveries.", "Collect 50,000 PHP COD", Icons.attach_money_rounded),
      _BadgeSpec(75000, "Half-Lakh Master", "Collected 75,000 PHP COD.", "Collect 75,000 PHP COD", Icons.account_balance_outlined),
      _BadgeSpec(100000, "Lakh Elite", "Collected 100,000 PHP COD! Six digits of total transactions.", "Collect 100,000 PHP COD", Icons.store_mall_directory_outlined),
      _BadgeSpec(150000, "Cash Emperor", "Collected 150,000 PHP COD. Exceptional financial flow.", "Collect 150,000 PHP COD", Icons.domain_rounded),
      _BadgeSpec(200000, "Quarter Million", "Collected 200,000 PHP COD. Incredible scale of logistics.", "Collect 200,000 PHP COD", Icons.business_center_rounded),
      _BadgeSpec(250000, "Vault Master", "Collected 250,000 PHP COD. Extreme financial operations.", "Collect 250,000 PHP COD", Icons.cases_outlined),
      _BadgeSpec(500000, "Half Millionaire", "Collected 500,000 PHP COD. Stellar achievements.", "Collect 500,000 PHP COD", Icons.diamond),
      _BadgeSpec(1000000, "Millionaire Rider", "Collected 1,000,000 PHP COD! Millions in delivery transactions safely settled.", "Collect 1,000,000 PHP COD", Icons.currency_ruble_rounded),
    ];
    for (var i = 0; i < collections.length; i++) {
      final spec = collections[i];
      list.add(RiderBadge(
        id: "col_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Collections",
        targetValue: spec.val.toDouble(),
        currentValue: stats.totalCollections,
        icon: spec.icon,
      ));
    }

    // Category 4: Barangay (Exploration)
    // 17 badges
    final barangays = [
      _BadgeSpec(1, "Local Scout", "Delivered to 1 unique barangay. Map scouting started.", "Deliver to 1 unique barangay", Icons.pin_drop_outlined),
      _BadgeSpec(2, "Neighborhood Friend", "Delivered to 2 unique barangays. Friendly traveler.", "Deliver to 2 unique barangays", Icons.people_outline_rounded),
      _BadgeSpec(3, "Zone Explorer", "Delivered to 3 unique barangays. Expanding coverage.", "Deliver to 3 unique barangays", Icons.explore_outlined),
      _BadgeSpec(4, "Grid Traveler", "Delivered to 4 unique barangays. Road navigation pro.", "Deliver to 4 unique barangays", Icons.map_outlined),
      _BadgeSpec(5, "Path Finder", "Delivered to 5 unique barangays. Spotting paths easily.", "Deliver to 5 unique barangays", Icons.my_location_rounded),
      _BadgeSpec(6, "Territory Owner", "Delivered to 6 unique barangays. Know your turf.", "Deliver to 6 unique barangays", Icons.flag_circle_rounded),
      _BadgeSpec(7, "Barangay Veteran", "Delivered to 7 unique barangays. True veteran rider.", "Deliver to 7 unique barangays", Icons.badge_outlined),
      _BadgeSpec(8, "Navigator", "Delivered to 8 unique barangays. Route mastery.", "Deliver to 8 unique barangays", Icons.directions_run_rounded),
      _BadgeSpec(9, "Map Specialist", "Delivered to 9 unique barangays. GPS not needed!", "Deliver to 9 unique barangays", Icons.location_searching_rounded),
      _BadgeSpec(10, "Cartographer", "Delivered to 10 unique barangays. Mapping the region.", "Deliver to 10 unique barangays", Icons.layers_outlined),
      _BadgeSpec(12, "Sub-District Hero", "Delivered to 12 unique barangays. Landmark master.", "Deliver to 12 unique barangays", Icons.home_work_outlined),
      _BadgeSpec(15, "Wayfarer", "Delivered to 15 unique barangays. Endless wandering.", "Deliver to 15 unique barangays", Icons.signpost_outlined),
      _BadgeSpec(20, "Global Local", "Delivered to 20 unique barangays. Knows all the shortcuts.", "Deliver to 20 unique barangays", Icons.public_rounded),
      _BadgeSpec(25, "Master Explorer", "Delivered to 25 unique barangays. Uncharted territory conquered.", "Deliver to 25 unique barangays", Icons.terrain_rounded),
      _BadgeSpec(30, "Region Champion", "Delivered to 30 unique barangays. Local authority.", "Deliver to 30 unique barangays", Icons.emoji_events_rounded),
      _BadgeSpec(40, "Barangay Monarch", "Delivered to 40 unique barangays. Crowned master.", "Deliver to 40 unique barangays", Icons.king_bed_outlined),
      _BadgeSpec(50, "Map Overlord", "Delivered to 50 unique barangays. You have mapped the entire territory.", "Deliver to 50 unique barangays", Icons.view_headline_rounded),
    ];
    for (var i = 0; i < barangays.length; i++) {
      final spec = barangays[i];
      list.add(RiderBadge(
        id: "brgy_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Barangay",
        targetValue: spec.val.toDouble(),
        currentValue: stats.uniqueBarangays.toDouble(),
        icon: spec.icon,
      ));
    }

    // Category 5: City (Exploration)
    // 10 badges
    final cities = [
      _BadgeSpec(1, "City Citizen", "Delivered to your first city.", "Deliver to 1 city", Icons.location_city_outlined),
      _BadgeSpec(2, "Intercity Commuter", "Delivered packages across 2 different cities.", "Deliver to 2 cities", Icons.traffic_outlined),
      _BadgeSpec(3, "Metro Scout", "Delivered packages across 3 different cities.", "Deliver to 3 cities", Icons.commute_outlined),
      _BadgeSpec(4, "City Hopper", "Delivered packages across 4 different cities.", "Deliver to 4 cities", Icons.alt_route_outlined),
      _BadgeSpec(5, "Cross-City Runner", "Delivered packages across 5 different cities.", "Deliver to 5 cities", Icons.directions_bike_outlined),
      _BadgeSpec(6, "City Veteran", "Delivered packages across 6 different cities.", "Deliver to 6 cities", Icons.apartment_rounded),
      _BadgeSpec(7, "Metropolitan Hero", "Delivered packages across 7 different cities.", "Deliver to 7 cities", Icons.castle_outlined),
      _BadgeSpec(8, "Municipal Monarch", "Delivered packages across 8 different cities.", "Deliver to 8 cities", Icons.storefront_outlined),
      _BadgeSpec(9, "Province Nomad", "Delivered packages across 9 different cities.", "Deliver to 9 cities", Icons.train_rounded),
      _BadgeSpec(10, "State Navigator", "Delivered packages across 10 different cities. Ultimate geographical coverage.", "Deliver to 10 cities", Icons.language_rounded),
    ];
    for (var i = 0; i < cities.length; i++) {
      final spec = cities[i];
      list.add(RiderBadge(
        id: "city_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "City",
        targetValue: spec.val.toDouble(),
        currentValue: stats.uniqueCities.toDouble(),
        icon: spec.icon,
      ));
    }

    // Category 6: Rides (Rides & Journeys)
    // 14 badges
    final rides = [
      _BadgeSpec(1, "First Ride", "Completed your first active delivery ride.", "Complete 1 ride", Icons.directions_run_outlined),
      _BadgeSpec(5, "Five Pack", "Completed 5 delivery rides. Mileage rising.", "Complete 5 rides", Icons.route_outlined),
      _BadgeSpec(10, "Active Commuter", "Completed 10 delivery rides. Consistency builder.", "Complete 10 rides", Icons.run_circle_outlined),
      _BadgeSpec(15, "Route Rider", "Completed 15 delivery rides. Familiar asphalt.", "Complete 15 rides", Icons.polyline_outlined),
      _BadgeSpec(20, "Road Warrior", "Completed 20 delivery rides. Nothing stops you.", "Complete 20 rides", Icons.motorcycle_rounded),
      _BadgeSpec(25, "Asphalt King", "Completed 25 delivery rides. Ruler of the tarmac.", "Complete 25 rides", Icons.roller_skating_outlined),
      _BadgeSpec(30, "Daily Commuter", "Completed 30 delivery rides. Professional routine.", "Complete 30 rides", Icons.calendar_today_outlined),
      _BadgeSpec(40, "Milestone Commuter", "Completed 40 delivery rides. High level experience.", "Complete 40 rides", Icons.timeline_rounded),
      _BadgeSpec(50, "Century Rider", "Completed 50 delivery rides. An amazing half-century journeys.", "Complete 50 rides", Icons.celebration_outlined),
      _BadgeSpec(75, "Veteran Roadie", "Completed 75 delivery rides. Experienced cruiser.", "Complete 75 rides", Icons.star_border_purple500_rounded),
      _BadgeSpec(100, "Highway Hero", "Completed 100 delivery rides. Incredible century-scale milestone.", "Complete 100 rides", Icons.rocket_outlined),
      _BadgeSpec(150, "Elite Commuter", "Completed 150 delivery rides. Absolute logistics legend.", "Complete 150 rides", Icons.auto_mode_rounded),
      _BadgeSpec(200, "Unstoppable Wheels", "Completed 200 delivery rides. Tire wear master.", "Complete 200 rides", Icons.loop_rounded),
      _BadgeSpec(250, "Infinite Rider", "Completed 250 delivery rides. The asphalt is your home.", "Complete 250 rides", Icons.all_inclusive_rounded),
    ];
    for (var i = 0; i < rides.length; i++) {
      final spec = rides[i];
      list.add(RiderBadge(
        id: "rides_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Rides",
        targetValue: spec.val.toDouble(),
        currentValue: stats.totalRides.toDouble(),
        icon: spec.icon,
      ));
    }

    // Category 7: Consistency (Time of Day & Habits)
    // 10 badges
    final consistency = [
      _BadgeSpec(1, "Sunrise Drop", "Delivered 1 package during early morning (before 8 AM). Early bird catches the worm!", "Deliver 1 package before 8 AM", Icons.wb_twilight_rounded),
      _BadgeSpec(5, "Early Bird", "Delivered 5 packages early in the morning.", "Deliver 5 packages before 8 AM", Icons.wb_sunny_outlined),
      _BadgeSpec(10, "Morning Rooster", "Delivered 10 packages early in the morning.", "Deliver 10 packages before 8 AM", Icons.alarm_on_rounded),
      _BadgeSpec(25, "Dawn Patrol", "Delivered 25 packages early in the morning.", "Deliver 25 packages before 8 AM", Icons.brightness_5_rounded),
      _BadgeSpec(50, "Breakfast Club", "Delivered 50 packages early in the morning. Dedication starts at dawn.", "Deliver 50 packages before 8 AM", Icons.breakfast_dining_outlined),
      _BadgeSpec(1, "Moonlight Drop", "Delivered 1 package during evening hours (after 6 PM). The night shift begins.", "Deliver 1 package after 6 PM", Icons.nightlight_round),
      _BadgeSpec(5, "Night Owl", "Delivered 5 packages after 6 PM. Courier of the dark.", "Deliver 5 packages after 6 PM", Icons.dark_mode_outlined),
      _BadgeSpec(10, "Midnight Courier", "Delivered 10 packages after 6 PM. Shimmering headlights.", "Deliver 10 packages after 6 PM", Icons.nights_stay_outlined),
      _BadgeSpec(25, "After Hours", "Delivered 25 packages after 6 PM.", "Deliver 25 packages after 6 PM", Icons.star_rounded),
      _BadgeSpec(50, "Dark Knight", "Delivered 50 packages after 6 PM. Master of night deliveries.", "Deliver 50 packages after 6 PM", Icons.shield_moon_outlined),
    ];
    for (var i = 0; i < consistency.length; i++) {
      final spec = consistency[i];
      final isEarly = spec.req.contains("before 8 AM");
      list.add(RiderBadge(
        id: "const_${isEarly ? 'early' : 'night'}_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Consistency",
        targetValue: spec.val.toDouble(),
        currentValue: isEarly ? stats.earlyMorning.toDouble() : stats.night.toDouble(),
        icon: spec.icon,
      ));
    }

    // Category 8: Persistence & Rapport (Quality Metrics)
    // 6 badges
    final quality = [
      _BadgeSpec(1, "Determined Runner", "Successfully delivered a package on a second or third attempt.", "Deliver 1 package requiring multiple attempts", Icons.redo_rounded),
      _BadgeSpec(5, "Tenacious Deliverer", "Successfully delivered 5 packages requiring multiple attempts.", "Deliver 5 packages requiring multiple attempts", Icons.auto_graph_rounded),
      _BadgeSpec(10, "Never Back Down", "Successfully delivered 10 packages requiring multiple attempts. Persistence paying off.", "Deliver 10 packages requiring multiple attempts", Icons.handshake_rounded),
      _BadgeSpec(1, "Rapport Builder", "Created your first contact archive for a customer.", "Build 1 receiver archive card", Icons.contact_mail_outlined),
      _BadgeSpec(5, "Networker", "Created 5 contact archives for customers.", "Build 5 receiver archive cards", Icons.contacts_outlined),
      _BadgeSpec(10, "Community Rolodex", "Created 10 contact archives for customers. You know the whole town!", "Build 10 receiver archive cards", Icons.supervised_user_circle_outlined),
    ];
    for (var i = 0; i < quality.length; i++) {
      final spec = quality[i];
      final isQuality = spec.req.contains("multiple attempts");
      list.add(RiderBadge(
        id: "qual_${isQuality ? 'attempt' : 'archive'}_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Quality",
        targetValue: spec.val.toDouble(),
        currentValue: isQuality ? stats.multiAttempt.toDouble() : stats.receiverArchivesCount.toDouble(),
        icon: spec.icon,
      ));
    }
    
    return list;
  }
}

class _BadgeSpec {
  final int val;
  final String title;
  final String desc;
  final String req;
  final IconData icon;

  _BadgeSpec(this.val, this.title, this.desc, this.req, this.icon);
}
