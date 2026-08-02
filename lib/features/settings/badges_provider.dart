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
  final DateTime? latestDeliveredAt;

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
    this.latestDeliveredAt,
  });

  factory RiderStats.fromMap(Map<String, dynamic> map) {
    final latestStr = map['latestDeliveredAt'] as String?;
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
      latestDeliveredAt: latestStr != null ? DateTime.tryParse(latestStr) : null,
    );
  }
}

// CHANGED: Added points and unlockedAt to RiderBadge to support detailed achievement views
class RiderBadge {
  final String id;
  final String title;
  final String description;
  final String requirement;
  final String category;
  final double targetValue;
  final double currentValue;
  final IconData icon;
  final int points;
  final DateTime? unlockedAt;

  RiderBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.icon,
    this.points = 10,
    this.unlockedAt,
  });

  bool get unlocked => currentValue >= targetValue;
  double get progress => targetValue == 0 ? 1.0 : (currentValue / targetValue).clamp(0.0, 1.0);
}

class BadgesState {
  final RiderStats stats;
  final List<RiderBadge> badges;

  BadgesState({
    required this.stats,
    required this.badges,
  });
}

@riverpod
class BadgesNotifier extends _$BadgesNotifier {
  @override
  Future<BadgesState> build() async {
    final dbHelper = DbHelper.instance;
    final statsMap = await dbHelper.getHistoricalStats();
    final stats = RiderStats.fromMap(statsMap);
    
    return BadgesState(
      stats: stats,
      badges: _generateBadges(stats),
    );
  }

  List<RiderBadge> _generateBadges(RiderStats stats) {
    final List<RiderBadge> list = [];
    
    // CHANGED: Expanded Volume badges with 15 new high-tier milestone achievements (total 37)
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
      _BadgeSpec(2500, "Parcel Vanguard", "2500 deliveries logged. Pushing logistics excellence.", "Deliver 2500 packages", Icons.verified_user_rounded, 50),
      _BadgeSpec(3000, "Delivery Overlord", "3000 packages safely dropped.", "Deliver 3000 packages", Icons.workspace_premium_outlined, 50),
      _BadgeSpec(3500, "Route Commander", "3500 deliveries completed with distinction.", "Deliver 3500 packages", Icons.military_tech, 50),
      _BadgeSpec(4000, "Logistics Sovereign", "4000 packages delivered across the network.", "Deliver 4000 packages", Icons.star_half_rounded, 50),
      _BadgeSpec(4500, "Iron Courier", "4500 deliveries. An indestructible pillar of service.", "Deliver 4500 packages", Icons.hardware_rounded, 50),
      _BadgeSpec(5000, "Five Millenniums", "5000 deliveries! Five thousand parcels placed in customer hands.", "Deliver 5000 packages", Icons.stars, 50),
      _BadgeSpec(6000, "Asphalt Titan", "6000 deliveries. Mastering every street and alley.", "Deliver 6000 packages", Icons.terrain_outlined, 50),
      _BadgeSpec(7000, "Fleet Paragon", "7000 deliveries logged.", "Deliver 7000 packages", Icons.local_post_office_rounded, 50),
      _BadgeSpec(8000, "Apex Courier", "8000 deliveries. Top-tier courier prowess.", "Deliver 8000 packages", Icons.speed, 50),
      _BadgeSpec(9000, "Infinity Express", "9000 deliveries. Approaching unmatched logistics history.", "Deliver 9000 packages", Icons.all_inclusive, 50),
      _BadgeSpec(10000, "Ten K Legend", "10000 packages delivered! An immortal last-mile legend.", "Deliver 10000 packages", Icons.workspace_premium, 50),
      _BadgeSpec(12500, "Consortium Master", "12500 deliveries safely completed.", "Deliver 12500 packages", Icons.domain, 50),
      _BadgeSpec(15000, "Logistics Emperor", "15000 deliveries logged.", "Deliver 15000 packages", Icons.king_bed, 50),
      _BadgeSpec(20000, "Supreme Deliverer", "20000 packages delivered!", "Deliver 20000 packages", Icons.auto_awesome_rounded, 50),
      _BadgeSpec(25000, "Ultimate Courier God", "25000 packages delivered! The absolute peak of delivery performance.", "Deliver 25000 packages", Icons.military_tech_rounded, 50),
    ];
    for (var i = 0; i < volumes.length; i++) {
      final spec = volumes[i];
      final target = spec.val.toDouble();
      final current = stats.successPackages.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "vol_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Volume",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Tips badges with 15 new high-tier gratuity achievements (total 30)
    final tips = [
      _BadgeSpec(50, "Tip Beginner", "Earned 50 PHP in tips. A token of appreciation from customers.", "Earn 50 PHP in tips", Icons.savings_outlined, 10),
      _BadgeSpec(100, "Coffee Money", "100 PHP in tips. Enough to power your next ride!", "Earn 100 PHP in tips", Icons.coffee_rounded, 15),
      _BadgeSpec(150, "Snack Fund", "150 PHP in tips. Treats on the road!", "Earn 150 PHP in tips", Icons.fastfood_rounded, 15),
      _BadgeSpec(200, "Generosity", "200 PHP in tips. Excellent customer service paying off.", "Earn 200 PHP in tips", Icons.favorite_outline_rounded, 20),
      _BadgeSpec(250, "Gratuity Master", "250 PHP in tips. Customers love your work!", "Earn 250 PHP in tips", Icons.volunteer_activism_rounded, 20),
      _BadgeSpec(300, "Bonus Hunter", "300 PHP in tips. Your efforts are recognized.", "Earn 300 PHP in tips", Icons.card_giftcard_rounded, 25),
      _BadgeSpec(400, "Tip King", "400 PHP in tips. Outstanding courtesy rewards.", "Earn 400 PHP in tips", Icons.thumb_up_alt_outlined, 25),
      _BadgeSpec(500, "Tip Vault", "500 PHP in tips! A massive milestone of appreciation.", "Earn 500 PHP in tips", Icons.lock_outline, 30),
      _BadgeSpec(750, "Tip Champion", "750 PHP in tips. Keep going and stay friendly!", "Earn 750 PHP in tips", Icons.military_tech_outlined, 35),
      _BadgeSpec(1000, "Gold Gratuity", "1000 PHP in tips! Pure gold standard service.", "Earn 1000 PHP in tips", Icons.workspace_premium_outlined, 40),
      _BadgeSpec(1500, "Elite Tips", "1500 PHP in tips. You are in the top echelon of friendly couriers.", "Earn 1500 PHP in tips", Icons.stars_outlined, 45),
      _BadgeSpec(2000, "Diamond Tip", "2000 PHP in tips. Ultimate customer care rewards.", "Earn 2000 PHP in tips", Icons.diamond_outlined, 50),
      _BadgeSpec(3000, "Tip Legend", "3000 PHP in tips. Legendary level of service.", "Earn 3000 PHP in tips", Icons.emoji_events_outlined, 50),
      _BadgeSpec(5000, "Tip Emperor", "5000 PHP in tips. Absolute king of gratuity.", "Earn 5000 PHP in tips", Icons.auto_awesome, 50),
      _BadgeSpec(10000, "Infinite Tips", "10000 PHP in tips. Lifetime of appreciation.", "Earn 10000 PHP in tips", Icons.all_inclusive_rounded, 50),
      _BadgeSpec(12500, "Gratuity Vanguard", "12500 PHP in tips. Outstanding hospitality and friendliness.", "Earn 12500 PHP in tips", Icons.volunteer_activism, 50),
      _BadgeSpec(15000, "Customer Choice", "15000 PHP in tips. Recognized as a customer favorite.", "Earn 15000 PHP in tips", Icons.thumb_up_rounded, 50),
      _BadgeSpec(20000, "Golden Smile", "20000 PHP in tips. Friendly demeanor that always pays off.", "Earn 20000 PHP in tips", Icons.sentiment_very_satisfied, 50),
      _BadgeSpec(25000, "Tip Sovereign", "25000 PHP in tips. A legend in recipient relations.", "Earn 25000 PHP in tips", Icons.card_membership, 50),
      _BadgeSpec(30000, "Generosity Magnet", "30000 PHP in tips.", "Earn 30000 PHP in tips", Icons.attractions_rounded, 50),
      _BadgeSpec(35000, "Tip Titan", "35000 PHP in tips. Remarkable level of customer generosity.", "Earn 35000 PHP in tips", Icons.workspace_premium_rounded, 50),
      _BadgeSpec(40000, "Gratuity Monarch", "40000 PHP in tips. Exceptional service standard.", "Earn 40000 PHP in tips", Icons.military_tech_rounded, 50),
      _BadgeSpec(45000, "Tip Overlord", "45000 PHP in tips. Unmatched customer satisfaction.", "Earn 45000 PHP in tips", Icons.shield, 50),
      _BadgeSpec(50000, "Half-Lakh Tips", "50000 PHP in tips! 50k in total customer tips.", "Earn 50000 PHP in tips", Icons.monetization_on, 50),
      _BadgeSpec(60000, "Tip Paragon", "60000 PHP in tips.", "Earn 60000 PHP in tips", Icons.stars_rounded, 50),
      _BadgeSpec(70000, "Gratuity Apex", "70000 PHP in tips.", "Earn 70000 PHP in tips", Icons.diamond_rounded, 50),
      _BadgeSpec(80000, "Tip Mastermind", "80000 PHP in tips.", "Earn 80000 PHP in tips", Icons.psychology_rounded, 50),
      _BadgeSpec(90000, "Gratuity Supreme", "90000 PHP in tips.", "Earn 90000 PHP in tips", Icons.auto_awesome_rounded, 50),
      _BadgeSpec(100000, "Six-Figure Tips", "100000 PHP in tips! A historic six-figure tip milestone.", "Earn 100000 PHP in tips", Icons.emoji_events, 50),
      _BadgeSpec(150000, "Tip Immortal", "150000 PHP in tips! Ultimate master of gratuity.", "Earn 150000 PHP in tips", Icons.all_inclusive, 50),
    ];
    for (var i = 0; i < tips.length; i++) {
      final spec = tips[i];
      final target = spec.val.toDouble();
      final current = stats.totalTips;
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "tips_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Tips",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Collections badges with 15 new high-tier financial achievements (total 29)
    final collections = [
      _BadgeSpec(1000, "Cash Handler", "Collected 1,000 PHP COD. First financial drops.", "Collect 1,000 PHP COD", Icons.payments_outlined, 10),
      _BadgeSpec(5000, "Finance Starter", "Collected 5,000 PHP COD. Safe and secure.", "Collect 5,000 PHP COD", Icons.account_balance_wallet_outlined, 15),
      _BadgeSpec(10000, "Safe Keeper", "Collected 10,000 PHP COD. Handling funds like a pro.", "Collect 10,000 PHP COD", Icons.security_rounded, 15),
      _BadgeSpec(20000, "Collector Pro", "Collected 20,000 PHP COD. Moving cargo, settling accounts.", "Collect 20,000 PHP COD", Icons.monetization_on_outlined, 20),
      _BadgeSpec(30000, "Money Bag", "Collected 30,000 PHP COD. Heavy lifting of finances.", "Collect 30,000 PHP COD", Icons.local_mall_outlined, 20),
      _BadgeSpec(40000, "Vault Keeper", "Collected 40,000 PHP COD. Trustworthy handler.", "Collect 40,000 PHP COD", Icons.vpn_key_outlined, 25),
      _BadgeSpec(50000, "Treasurer", "Collected 50,000 PHP COD. Solid financial deliveries.", "Collect 50,000 PHP COD", Icons.attach_money_rounded, 25),
      _BadgeSpec(75000, "Half-Lakh Master", "Collected 75,000 PHP COD.", "Collect 75,000 PHP COD", Icons.account_balance_outlined, 30),
      _BadgeSpec(100000, "Lakh Elite", "Collected 100,000 PHP COD! Six digits of total transactions.", "Collect 100,000 PHP COD", Icons.store_mall_directory_outlined, 35),
      _BadgeSpec(150000, "Cash Emperor", "Collected 150,000 PHP COD. Exceptional financial flow.", "Collect 150,000 PHP COD", Icons.domain_rounded, 40),
      _BadgeSpec(200000, "Quarter Million", "Collected 200,000 PHP COD. Incredible scale of logistics.", "Collect 200,000 PHP COD", Icons.business_center_rounded, 45),
      _BadgeSpec(250000, "Vault Master", "Collected 250,000 PHP COD. Extreme financial operations.", "Collect 250,000 PHP COD", Icons.cases_outlined, 50),
      _BadgeSpec(500000, "Half Millionaire", "Collected 500,000 PHP COD. Stellar achievements.", "Collect 500,000 PHP COD", Icons.diamond, 50),
      _BadgeSpec(1000000, "Millionaire Rider", "Collected 1,000,000 PHP COD! Millions in delivery transactions safely settled.", "Collect 1,000,000 PHP COD", Icons.currency_ruble_rounded, 50),
      _BadgeSpec(1500000, "Multi-Million Collector", "Collected 1,500,000 PHP COD.", "Collect 1,500,000 PHP COD", Icons.payments, 50),
      _BadgeSpec(2000000, "Double Millionaire", "Collected 2,000,000 PHP COD! Trusted with major funds.", "Collect 2,000,000 PHP COD", Icons.savings, 50),
      _BadgeSpec(2500000, "Financial Fortress", "Collected 2,500,000 PHP COD.", "Collect 2,500,000 PHP COD", Icons.account_balance, 50),
      _BadgeSpec(3000000, "Triple Millionaire", "Collected 3,000,000 PHP COD.", "Collect 3,000,000 PHP COD", Icons.store, 50),
      _BadgeSpec(3500000, "Vault Sovereign", "Collected 3,500,000 PHP COD.", "Collect 3,500,000 PHP COD", Icons.security, 50),
      _BadgeSpec(4000000, "Quadruple Millionaire", "Collected 4,000,000 PHP COD.", "Collect 4,000,000 PHP COD", Icons.business, 50),
      _BadgeSpec(4500000, "Treasury Titan", "Collected 4,500,000 PHP COD.", "Collect 4,500,000 PHP COD", Icons.monetization_on_rounded, 50),
      _BadgeSpec(5000000, "Five Million Legend", "Collected 5,000,000 PHP COD! Five million in transactions handled safely.", "Collect 5,000,000 PHP COD", Icons.stars, 50),
      _BadgeSpec(6000000, "Capital Custodian", "Collected 6,000,000 PHP COD.", "Collect 6,000,000 PHP COD", Icons.domain_outlined, 50),
      _BadgeSpec(7000000, "Seven Million Master", "Collected 7,000,000 PHP COD.", "Collect 7,000,000 PHP COD", Icons.workspace_premium, 50),
      _BadgeSpec(8000000, "Financial Apex", "Collected 8,000,000 PHP COD.", "Collect 8,000,000 PHP COD", Icons.military_tech, 50),
      _BadgeSpec(9000000, "Treasury Overlord", "Collected 9,000,000 PHP COD.", "Collect 9,000,000 PHP COD", Icons.diamond_outlined, 50),
      _BadgeSpec(10000000, "Ten Millionaire Courier", "Collected 10,000,000 PHP COD! Iconic financial achievement.", "Collect 10,000,000 PHP COD", Icons.emoji_events, 50),
      _BadgeSpec(15000000, "Consortium Titan", "Collected 15,000,000 PHP COD.", "Collect 15,000,000 PHP COD", Icons.corporate_fare, 50),
      _BadgeSpec(20000000, "Ultimate Financial Legend", "Collected 20,000,000 PHP COD! Unsurpassed cash handling record.", "Collect 20,000,000 PHP COD", Icons.all_inclusive, 50),
    ];
    for (var i = 0; i < collections.length; i++) {
      final spec = collections[i];
      final target = spec.val.toDouble();
      final current = stats.totalCollections;
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "col_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Collections",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Barangay badges with 15 new exploration achievements (total 32)
    final barangays = [
      _BadgeSpec(1, "Local Scout", "Delivered to 1 unique barangay. Map scouting started.", "Deliver to 1 unique barangay", Icons.pin_drop_outlined, 10),
      _BadgeSpec(2, "Neighborhood Friend", "Delivered to 2 unique barangays. Friendly traveler.", "Deliver to 2 unique barangays", Icons.people_outline_rounded, 10),
      _BadgeSpec(3, "Zone Explorer", "Delivered to 3 unique barangays. Expanding coverage.", "Deliver to 3 unique barangays", Icons.explore_outlined, 15),
      _BadgeSpec(4, "Grid Traveler", "Delivered to 4 unique barangays. Road navigation pro.", "Deliver to 4 unique barangays", Icons.map_outlined, 15),
      _BadgeSpec(5, "Path Finder", "Delivered to 5 unique barangays. Spotting paths easily.", "Deliver to 5 unique barangays", Icons.my_location_rounded, 20),
      _BadgeSpec(6, "Territory Owner", "Delivered to 6 unique barangays. Know your turf.", "Deliver to 6 unique barangays", Icons.flag_circle_rounded, 20),
      _BadgeSpec(7, "Barangay Veteran", "Delivered to 7 unique barangays. True veteran rider.", "Deliver to 7 unique barangays", Icons.badge_outlined, 25),
      _BadgeSpec(8, "Navigator", "Delivered to 8 unique barangays. Route mastery.", "Deliver to 8 unique barangays", Icons.directions_run_rounded, 25),
      _BadgeSpec(9, "Map Specialist", "Delivered to 9 unique barangays. GPS not needed!", "Deliver to 9 unique barangays", Icons.location_searching_rounded, 30),
      _BadgeSpec(10, "Cartographer", "Delivered to 10 unique barangays. Mapping the region.", "Deliver to 10 unique barangays", Icons.layers_outlined, 30),
      _BadgeSpec(12, "Sub-District Hero", "Delivered to 12 unique barangays. Landmark master.", "Deliver to 12 unique barangays", Icons.home_work_outlined, 35),
      _BadgeSpec(15, "Wayfarer", "Delivered to 15 unique barangays. Endless wandering.", "Deliver to 15 unique barangays", Icons.signpost_outlined, 40),
      _BadgeSpec(20, "Global Local", "Delivered to 20 unique barangays. Knows all the shortcuts.", "Deliver to 20 unique barangays", Icons.public_rounded, 45),
      _BadgeSpec(25, "Master Explorer", "Delivered to 25 unique barangays. Uncharted territory conquered.", "Deliver to 25 unique barangays", Icons.terrain_rounded, 50),
      _BadgeSpec(30, "Region Champion", "Delivered to 30 unique barangays. Local authority.", "Deliver to 30 unique barangays", Icons.emoji_events_rounded, 50),
      _BadgeSpec(40, "Barangay Monarch", "Delivered to 40 unique barangays. Crowned master.", "Deliver to 40 unique barangays", Icons.king_bed_outlined, 50),
      _BadgeSpec(50, "Map Overlord", "Delivered to 50 unique barangays. You have mapped the entire territory.", "Deliver to 50 unique barangays", Icons.view_headline_rounded, 50),
      _BadgeSpec(60, "District Pioneer", "Delivered to 60 unique barangays.", "Deliver to 60 unique barangays", Icons.flag_rounded, 50),
      _BadgeSpec(70, "Sector Specialist", "Delivered to 70 unique barangays.", "Deliver to 70 unique barangays", Icons.navigation_rounded, 50),
      _BadgeSpec(80, "Zone Master", "Delivered to 80 unique barangays.", "Deliver to 80 unique barangays", Icons.alt_route_rounded, 50),
      _BadgeSpec(90, "Territory Titan", "Delivered to 90 unique barangays.", "Deliver to 90 unique barangays", Icons.map_rounded, 50),
      _BadgeSpec(100, "Century Explorer", "Delivered to 100 unique barangays! Unparalleled local map knowledge.", "Deliver to 100 unique barangays", Icons.workspace_premium, 50),
      _BadgeSpec(120, "Grid Mastermind", "Delivered to 120 unique barangays.", "Deliver to 120 unique barangays", Icons.explore_rounded, 50),
      _BadgeSpec(140, "Boundary Crosser", "Delivered to 140 unique barangays.", "Deliver to 140 unique barangays", Icons.signpost_rounded, 50),
      _BadgeSpec(160, "Barangay Sovereign", "Delivered to 160 unique barangays.", "Deliver to 160 unique barangays", Icons.military_tech_rounded, 50),
      _BadgeSpec(180, "Regional Cartographer", "Delivered to 180 unique barangays.", "Deliver to 180 unique barangays", Icons.layers_rounded, 50),
      _BadgeSpec(200, "Double Century Scout", "Delivered to 200 unique barangays!", "Deliver to 200 unique barangays", Icons.emoji_events_rounded, 50),
      _BadgeSpec(250, "Territory Sovereign", "Delivered to 250 unique barangays.", "Deliver to 250 unique barangays", Icons.shield_rounded, 50),
      _BadgeSpec(300, "Provincial Scout", "Delivered to 300 unique barangays.", "Deliver to 300 unique barangays", Icons.public, 50),
      _BadgeSpec(350, "Map Sovereign", "Delivered to 350 unique barangays.", "Deliver to 350 unique barangays", Icons.diamond_rounded, 50),
      _BadgeSpec(400, "Archipelago Explorer", "Delivered to 400 unique barangays.", "Deliver to 400 unique barangays", Icons.travel_explore, 50),
      _BadgeSpec(500, "Master of all Zones", "Delivered to 500 unique barangays! Complete territorial dominance.", "Deliver to 500 unique barangays", Icons.all_inclusive, 50),
    ];
    for (var i = 0; i < barangays.length; i++) {
      final spec = barangays[i];
      final target = spec.val.toDouble();
      final current = stats.uniqueBarangays.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "brgy_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Barangay",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded City badges with 15 new geographical achievements (total 25)
    final cities = [
      _BadgeSpec(1, "City Citizen", "Delivered to your first city.", "Deliver to 1 city", Icons.location_city_outlined, 10),
      _BadgeSpec(2, "Intercity Commuter", "Delivered packages across 2 different cities.", "Deliver to 2 cities", Icons.traffic_outlined, 15),
      _BadgeSpec(3, "Metro Scout", "Delivered packages across 3 different cities.", "Deliver to 3 cities", Icons.commute_outlined, 20),
      _BadgeSpec(4, "City Hopper", "Delivered packages across 4 different cities.", "Deliver to 4 cities", Icons.alt_route_outlined, 25),
      _BadgeSpec(5, "Cross-City Runner", "Delivered packages across 5 different cities.", "Deliver to 5 cities", Icons.directions_bike_outlined, 30),
      _BadgeSpec(6, "City Veteran", "Delivered packages across 6 different cities.", "Deliver to 6 cities", Icons.apartment_rounded, 35),
      _BadgeSpec(7, "Metropolitan Hero", "Delivered packages across 7 different cities.", "Deliver to 7 cities", Icons.castle_outlined, 40),
      _BadgeSpec(8, "Municipal Monarch", "Delivered packages across 8 different cities.", "Deliver to 8 cities", Icons.storefront_outlined, 45),
      _BadgeSpec(9, "Province Nomad", "Delivered packages across 9 different cities.", "Deliver to 9 cities", Icons.train_rounded, 50),
      _BadgeSpec(10, "State Navigator", "Delivered packages across 10 different cities. Ultimate geographical coverage.", "Deliver to 10 cities", Icons.language_rounded, 50),
      _BadgeSpec(12, "Urban Voyager", "Delivered across 12 different cities.", "Deliver to 12 cities", Icons.domain_rounded, 50),
      _BadgeSpec(15, "Metropolis Master", "Delivered across 15 different cities.", "Deliver to 15 cities", Icons.location_city, 50),
      _BadgeSpec(18, "Capital Cruiser", "Delivered across 18 different cities.", "Deliver to 18 cities", Icons.directions_car_rounded, 50),
      _BadgeSpec(20, "State Explorer", "Delivered across 20 different cities.", "Deliver to 20 cities", Icons.map, 50),
      _BadgeSpec(25, "Interstate Legend", "Delivered across 25 different cities.", "Deliver to 25 cities", Icons.public_rounded, 50),
      _BadgeSpec(30, "Nationwide Courier", "Delivered across 30 different cities.", "Deliver to 30 cities", Icons.flag_rounded, 50),
      _BadgeSpec(35, "Provincial Titan", "Delivered across 35 different cities.", "Deliver to 35 cities", Icons.explore_rounded, 50),
      _BadgeSpec(40, "Countrywide Specialist", "Delivered across 40 different cities.", "Deliver to 40 cities", Icons.travel_explore_rounded, 50),
      _BadgeSpec(45, "Urban Monarch", "Delivered across 45 different cities.", "Deliver to 45 cities", Icons.king_bed_rounded, 50),
      _BadgeSpec(50, "Fifty City Master", "Delivered across 50 different cities! Incredible nationwide reach.", "Deliver to 50 cities", Icons.workspace_premium_rounded, 50),
      _BadgeSpec(60, "Metropolitan Sovereign", "Delivered across 60 cities.", "Deliver to 60 cities", Icons.shield_rounded, 50),
      _BadgeSpec(70, "Geographic Giant", "Delivered across 70 cities.", "Deliver to 70 cities", Icons.terrain_rounded, 50),
      _BadgeSpec(80, "Global Urbanite", "Delivered across 80 cities.", "Deliver to 80 cities", Icons.language_outlined, 50),
      _BadgeSpec(90, "Continental Courier", "Delivered across 90 cities.", "Deliver to 90 cities", Icons.military_tech_outlined, 50),
      _BadgeSpec(100, "Century City Legend", "Delivered across 100 cities! Unmatched national coverage.", "Deliver to 100 cities", Icons.all_inclusive_rounded, 50),
    ];
    for (var i = 0; i < cities.length; i++) {
      final spec = cities[i];
      final target = spec.val.toDouble();
      final current = stats.uniqueCities.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "city_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "City",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Rides badges with 15 new journey achievements (total 29)
    final rides = [
      _BadgeSpec(1, "First Ride", "Completed your first active delivery ride.", "Complete 1 ride", Icons.directions_run_outlined, 10),
      _BadgeSpec(5, "Five Pack", "Completed 5 delivery rides. Mileage rising.", "Complete 5 rides", Icons.route_outlined, 10),
      _BadgeSpec(10, "Active Commuter", "Completed 10 delivery rides. Consistency builder.", "Complete 10 rides", Icons.run_circle_outlined, 15),
      _BadgeSpec(15, "Route Rider", "Completed 15 delivery rides. Familiar asphalt.", "Complete 15 rides", Icons.polyline_outlined, 15),
      _BadgeSpec(20, "Road Warrior", "Completed 20 delivery rides. Nothing stops you.", "Complete 20 rides", Icons.motorcycle_rounded, 20),
      _BadgeSpec(25, "Asphalt King", "Completed 25 delivery rides. Ruler of the tarmac.", "Complete 25 rides", Icons.roller_skating_outlined, 25),
      _BadgeSpec(30, "Daily Commuter", "Completed 30 delivery rides. Professional routine.", "Complete 30 rides", Icons.calendar_today_outlined, 25),
      _BadgeSpec(40, "Milestone Commuter", "Completed 40 delivery rides. High level experience.", "Complete 40 rides", Icons.timeline_rounded, 30),
      _BadgeSpec(50, "Century Rider", "Completed 50 delivery rides. An amazing half-century journeys.", "Complete 50 rides", Icons.celebration_outlined, 35),
      _BadgeSpec(75, "Veteran Roadie", "Completed 75 delivery rides. Experienced cruiser.", "Complete 75 rides", Icons.star_border_purple500_rounded, 40),
      _BadgeSpec(100, "Highway Hero", "Completed 100 delivery rides. Incredible century-scale milestone.", "Complete 100 rides", Icons.rocket_outlined, 45),
      _BadgeSpec(150, "Elite Commuter", "Completed 150 delivery rides. Absolute logistics legend.", "Complete 150 rides", Icons.auto_mode_rounded, 50),
      _BadgeSpec(200, "Unstoppable Wheels", "Completed 200 delivery rides. Tire wear master.", "Complete 200 rides", Icons.loop_rounded, 50),
      _BadgeSpec(250, "Infinite Rider", "Completed 250 delivery rides. The asphalt is your home.", "Complete 250 rides", Icons.all_inclusive_rounded, 50),
      _BadgeSpec(300, "Triple Century Rides", "Completed 300 active delivery rides.", "Complete 300 rides", Icons.electric_bike_rounded, 50),
      _BadgeSpec(350, "Distance Dynamo", "Completed 350 active delivery rides.", "Complete 350 rides", Icons.speed_rounded, 50),
      _BadgeSpec(400, "Quad Squad Rider", "Completed 400 active delivery rides.", "Complete 400 rides", Icons.moped_rounded, 50),
      _BadgeSpec(450, "Iron Odometer", "Completed 450 active delivery rides.", "Complete 450 rides", Icons.two_wheeler_rounded, 50),
      _BadgeSpec(500, "Half-K Journeys", "Completed 500 active delivery rides!", "Complete 500 rides", Icons.military_tech_rounded, 50),
      _BadgeSpec(600, "Asphalt Veteran", "Completed 600 active delivery rides.", "Complete 600 rides", Icons.timeline, 50),
      _BadgeSpec(700, "Road Sovereign", "Completed 700 active delivery rides.", "Complete 700 rides", Icons.star_rounded, 50),
      _BadgeSpec(800, "Highway Titan", "Completed 800 active delivery rides.", "Complete 800 rides", Icons.workspace_premium_rounded, 50),
      _BadgeSpec(900, "Endless Mileage", "Completed 900 active delivery rides.", "Complete 900 rides", Icons.alt_route_rounded, 50),
      _BadgeSpec(1000, "One K Rider Legend", "Completed 1000 active delivery rides! A thousand journeys on the road.", "Complete 1000 rides", Icons.emoji_events_rounded, 50),
      _BadgeSpec(1250, "Grand Voyager", "Completed 1250 active delivery rides.", "Complete 1250 rides", Icons.travel_explore_rounded, 50),
      _BadgeSpec(1500, "Super Commuter", "Completed 1500 active delivery rides.", "Complete 1500 rides", Icons.rocket_launch, 50),
      _BadgeSpec(1750, "Hyper Rider", "Completed 1750 active delivery rides.", "Complete 1750 rides", Icons.flash_on, 50),
      _BadgeSpec(2000, "Double Grand Rider", "Completed 2000 active delivery rides.", "Complete 2000 rides", Icons.shield, 50),
      _BadgeSpec(2500, "Immortal Wheels", "Completed 2500 active delivery rides! Infinite journey champion.", "Complete 2500 rides", Icons.all_inclusive, 50),
    ];
    for (var i = 0; i < rides.length; i++) {
      final spec = rides[i];
      final target = spec.val.toDouble();
      final current = stats.totalRides.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "rides_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Rides",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Consistency badges with 12 new morning/evening shift achievements (total 22)
    final consistency = [
      _BadgeSpec(1, "Sunrise Drop", "Delivered 1 package during early morning (before 8 AM). Early bird catches the worm!", "Deliver 1 package before 8 AM", Icons.wb_twilight_rounded, 10),
      _BadgeSpec(5, "Early Bird", "Delivered 5 packages early in the morning.", "Deliver 5 packages before 8 AM", Icons.wb_sunny_outlined, 15),
      _BadgeSpec(10, "Morning Rooster", "Delivered 10 packages early in the morning.", "Deliver 10 packages before 8 AM", Icons.alarm_on_rounded, 20),
      _BadgeSpec(25, "Dawn Patrol", "Delivered 25 packages early in the morning.", "Deliver 25 packages before 8 AM", Icons.brightness_5_rounded, 30),
      _BadgeSpec(50, "Breakfast Club", "Delivered 50 packages early in the morning. Dedication starts at dawn.", "Deliver 50 packages before 8 AM", Icons.breakfast_dining_outlined, 40),
      _BadgeSpec(75, "Dawn Vanguard", "Delivered 75 packages early in the morning.", "Deliver 75 packages before 8 AM", Icons.wb_sunny_rounded, 45),
      _BadgeSpec(100, "Morning Legend", "Delivered 100 packages early in the morning.", "Deliver 100 packages before 8 AM", Icons.alarm_rounded, 50),
      _BadgeSpec(150, "Aurora Master", "Delivered 150 packages early in the morning.", "Deliver 150 packages before 8 AM", Icons.brightness_7_rounded, 50),
      _BadgeSpec(200, "Sunrise Monarch", "Delivered 200 packages early in the morning.", "Deliver 200 packages before 8 AM", Icons.wb_twilight, 50),
      _BadgeSpec(300, "Dawn Titan", "Delivered 300 packages early in the morning.", "Deliver 300 packages before 8 AM", Icons.stars_rounded, 50),
      _BadgeSpec(500, "Early Bird Supreme", "Delivered 500 packages before 8 AM! Undisputed dawn master.", "Deliver 500 packages before 8 AM", Icons.workspace_premium_rounded, 50),
      _BadgeSpec(1, "Moonlight Drop", "Delivered 1 package during evening hours (after 6 PM). The night shift begins.", "Deliver 1 package after 6 PM", Icons.nightlight_round, 10),
      _BadgeSpec(5, "Night Owl", "Delivered 5 packages after 6 PM. Courier of the dark.", "Deliver 5 packages after 6 PM", Icons.dark_mode_outlined, 15),
      _BadgeSpec(10, "Midnight Courier", "Delivered 10 packages after 6 PM. Shimmering headlights.", "Deliver 10 packages after 6 PM", Icons.nights_stay_outlined, 20),
      _BadgeSpec(25, "After Hours", "Delivered 25 packages after 6 PM.", "Deliver 25 packages after 6 PM", Icons.star_rounded, 30),
      _BadgeSpec(50, "Dark Knight", "Delivered 50 packages after 6 PM. Master of night deliveries.", "Deliver 50 packages after 6 PM", Icons.shield_moon_outlined, 40),
      _BadgeSpec(75, "Night Vanguard", "Delivered 75 packages after 6 PM.", "Deliver 75 packages after 6 PM", Icons.nights_stay_rounded, 45),
      _BadgeSpec(100, "Midnight Legend", "Delivered 100 packages after 6 PM.", "Deliver 100 packages after 6 PM", Icons.dark_mode_rounded, 50),
      _BadgeSpec(150, "Starlight Master", "Delivered 150 packages after 6 PM.", "Deliver 150 packages after 6 PM", Icons.star_border_purple500_rounded, 50),
      _BadgeSpec(200, "Nocturnal Monarch", "Delivered 200 packages after 6 PM.", "Deliver 200 packages after 6 PM", Icons.brightness_3_rounded, 50),
      _BadgeSpec(300, "Shadow Titan", "Delivered 300 packages after 6 PM.", "Deliver 300 packages after 6 PM", Icons.nightlight_outlined, 50),
      _BadgeSpec(500, "Dark Knight Supreme", "Delivered 500 packages after 6 PM! Legend of the night shift.", "Deliver 500 packages after 6 PM", Icons.emoji_events_rounded, 50),
    ];
    for (var i = 0; i < consistency.length; i++) {
      final spec = consistency[i];
      final isEarly = spec.req.contains("before 8 AM");
      final target = spec.val.toDouble();
      final current = isEarly ? stats.earlyMorning.toDouble() : stats.night.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "const_${isEarly ? 'early' : 'night'}_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Consistency",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
      ));
    }

    // CHANGED: Expanded Quality badges with 10 new persistence & rapport achievements (total 16)
    final quality = [
      _BadgeSpec(1, "Determined Runner", "Successfully delivered a package on a second or third attempt.", "Deliver 1 package requiring multiple attempts", Icons.redo_rounded, 10),
      _BadgeSpec(5, "Tenacious Deliverer", "Successfully delivered 5 packages requiring multiple attempts.", "Deliver 5 packages requiring multiple attempts", Icons.auto_graph_rounded, 20),
      _BadgeSpec(10, "Never Back Down", "Successfully delivered 10 packages requiring multiple attempts. Persistence paying off.", "Deliver 10 packages requiring multiple attempts", Icons.handshake_rounded, 30),
      _BadgeSpec(15, "Persistence Pro", "Delivered 15 packages requiring multiple attempts.", "Deliver 15 packages requiring multiple attempts", Icons.trending_up_rounded, 35),
      _BadgeSpec(20, "Unshakable Courier", "Delivered 20 packages requiring multiple attempts.", "Deliver 20 packages requiring multiple attempts", Icons.shield_rounded, 40),
      _BadgeSpec(30, "Iron Will", "Delivered 30 packages requiring multiple attempts.", "Deliver 30 packages requiring multiple attempts", Icons.fitness_center_rounded, 45),
      _BadgeSpec(50, "Master Persister", "Delivered 50 packages requiring multiple attempts.", "Deliver 50 packages requiring multiple attempts", Icons.star_rounded, 50),
      _BadgeSpec(100, "Persistence God", "Delivered 100 packages requiring multiple attempts! Never gives up on a package.", "Deliver 100 packages requiring multiple attempts", Icons.military_tech_rounded, 50),
      _BadgeSpec(1, "Rapport Builder", "Created your first contact archive for a customer.", "Build 1 receiver archive card", Icons.contact_mail_outlined, 10),
      _BadgeSpec(5, "Networker", "Created 5 contact archives for customers.", "Build 5 receiver archive cards", Icons.contacts_outlined, 20),
      _BadgeSpec(10, "Community Rolodex", "Created 10 contact archives for customers. You know the whole town!", "Build 10 receiver archive cards", Icons.supervised_user_circle_outlined, 30),
      _BadgeSpec(15, "Social Connector", "Created 15 contact archives for customers.", "Build 15 receiver archive cards", Icons.person_search_rounded, 35),
      _BadgeSpec(20, "Directory Master", "Created 20 contact archives for customers.", "Build 20 receiver archive cards", Icons.badge_rounded, 40),
      _BadgeSpec(30, "Town Ambassador", "Created 30 contact archives for customers.", "Build 30 receiver archive cards", Icons.location_history_rounded, 45),
      _BadgeSpec(50, "Network Sovereign", "Created 50 contact archives for customers.", "Build 50 receiver archive cards", Icons.groups_rounded, 50),
      _BadgeSpec(100, "Rolodex Legend", "Created 100 contact archives for customers! Ultimate neighborhood connector.", "Build 100 receiver archive cards", Icons.workspace_premium_rounded, 50),
    ];
    for (var i = 0; i < quality.length; i++) {
      final spec = quality[i];
      final isQuality = spec.req.contains("multiple attempts");
      final target = spec.val.toDouble();
      final current = isQuality ? stats.multiAttempt.toDouble() : stats.receiverArchivesCount.toDouble();
      final isUnlocked = target > 0 && current >= target;
      list.add(RiderBadge(
        id: "qual_${isQuality ? 'attempt' : 'archive'}_${spec.val}",
        title: spec.title,
        description: spec.desc,
        requirement: spec.req,
        category: "Quality",
        targetValue: target,
        currentValue: current,
        icon: spec.icon,
        points: spec.points,
        unlockedAt: isUnlocked ? (stats.latestDeliveredAt ?? DateTime.now()) : null,
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
  final int points;

  _BadgeSpec(this.val, this.title, this.desc, this.req, this.icon, [this.points = 10]);
}
